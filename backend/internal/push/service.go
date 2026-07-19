// Package push sends Firebase Cloud Messaging notifications. Deliberately minimal for now —
// one event type (new chat message), no notification categories/preferences yet (see
// CLAUDE.md's push notifications section for the fuller plan this is the first slice of).
//
// Talks to the FCM v1 HTTP API directly via an OAuth2-authenticated client, rather than
// pulling in firebase.google.com/go/v4 — that SDK drags in Firestore/Storage/Monitoring/
// OpenTelemetry-operations-go as transitive deps we never use, which is too heavy a Docker
// build for the small droplet this runs on (see CLAUDE.md's push notifications section for
// the "no space left on device" incident this replaced).
package push

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"

	"github.com/google/uuid"
	"golang.org/x/oauth2/google"
)

const fcmScope = "https://www.googleapis.com/auth/firebase.messaging"

type Service struct {
	repo *Repository
	// httpClient is nil when no credentials are configured — every send becomes a silent
	// no-op rather than an error, same pattern as upload.Service's Spaces-vs-local split.
	httpClient *http.Client
	projectID  string
}

// New builds a Service. credentialsJSON == "" disables push entirely (local dev default) —
// this is not an error, since push infra shouldn't block the rest of the API from running.
// Takes the service account JSON content directly (not a file path) so it's just another
// env var, same as every other secret in this project.
func New(ctx context.Context, repo *Repository, credentialsJSON string) (*Service, error) {
	if credentialsJSON == "" {
		log.Print("push: FIREBASE_CREDENTIALS_JSON not set, push notifications disabled")
		return &Service{repo: repo}, nil
	}

	var creds struct {
		ProjectID string `json:"project_id"`
	}
	if err := json.Unmarshal([]byte(credentialsJSON), &creds); err != nil {
		return nil, fmt.Errorf("push: invalid FIREBASE_CREDENTIALS_JSON: %w", err)
	}
	if creds.ProjectID == "" {
		return nil, fmt.Errorf("push: FIREBASE_CREDENTIALS_JSON has no project_id")
	}

	jwtConfig, err := google.JWTConfigFromJSON([]byte(credentialsJSON), fcmScope)
	if err != nil {
		return nil, fmt.Errorf("push: %w", err)
	}

	return &Service{repo: repo, httpClient: jwtConfig.Client(ctx), projectID: creds.ProjectID}, nil
}

// RegisterToken associates a device's FCM token with the signed-in user, called by the
// client on login/token refresh.
func (s *Service) RegisterToken(ctx context.Context, userID uuid.UUID, platform, token string) error {
	return s.repo.Upsert(ctx, userID, platform, token)
}

// UnregisterToken is the master-off path from NotificationsSettingsPage — removing the row
// is what actually stops sends, there's no separate "enabled" flag on push_tokens to flip.
func (s *Service) UnregisterToken(ctx context.Context, userID uuid.UUID, token string) error {
	return s.repo.DeleteTokenForUser(ctx, userID, token)
}

type Notification struct {
	Title string
	Body  string
	// Data is delivered alongside the notification for the client to act on when the user
	// taps it (e.g. tripId, to deep-link into the right Bubble) — see CLAUDE.md.
	Data map[string]string
}

// SendToUsers fans a notification out to every device registered to the given users.
// Best-effort: errors are logged, never returned, since a failed push must never fail
// the request that triggered it (matches the existing realtime.Publisher.Publish pattern
// in routes_message.go). FCM's v1 API takes one token per HTTP call (no server-side
// multicast like the legacy API) — fine at this project's scale, a trip's Bubble is a
// handful of recipients, not thousands.
func (s *Service) SendToUsers(ctx context.Context, userIDs []uuid.UUID, n Notification) {
	if s == nil || s.httpClient == nil || len(userIDs) == 0 {
		return
	}

	tokens, err := s.repo.ListTokensForUsers(ctx, userIDs)
	if err != nil {
		log.Printf("push: could not list tokens: %v", err)
		return
	}
	if len(tokens) == 0 {
		return
	}

	var deadTokens []string
	for _, token := range tokens {
		dead, err := s.sendOne(ctx, token, n)
		if err != nil {
			log.Printf("push: send failed: %v", err)
		}
		if dead {
			deadTokens = append(deadTokens, token)
		}
	}
	if err := s.repo.DeleteTokens(ctx, deadTokens); err != nil {
		log.Printf("push: could not prune dead tokens: %v", err)
	}
}

type fcmSendRequest struct {
	Message fcmMessage `json:"message"`
}

type fcmMessage struct {
	Token        string            `json:"token"`
	Notification *fcmNotification  `json:"notification,omitempty"`
	Data         map[string]string `json:"data,omitempty"`
}

type fcmNotification struct {
	Title string `json:"title"`
	Body  string `json:"body"`
}

type fcmErrorResponse struct {
	Error struct {
		Status string `json:"status"`
	} `json:"error"`
}

// sendOne posts a single message and reports whether the token is dead (unregistered /
// not found) so the caller can prune it — anything else is just logged, not pruned, since
// e.g. a transient quota or server error doesn't mean the token itself is bad.
func (s *Service) sendOne(ctx context.Context, token string, n Notification) (dead bool, err error) {
	body, err := json.Marshal(fcmSendRequest{Message: fcmMessage{
		Token:        token,
		Notification: &fcmNotification{Title: n.Title, Body: n.Body},
		Data:         n.Data,
	}})
	if err != nil {
		return false, err
	}

	url := fmt.Sprintf("https://fcm.googleapis.com/v1/projects/%s/messages:send", s.projectID)
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewReader(body))
	if err != nil {
		return false, err
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := s.httpClient.Do(req)
	if err != nil {
		return false, err
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusOK {
		return false, nil
	}

	var errResp fcmErrorResponse
	_ = json.NewDecoder(resp.Body).Decode(&errResp)
	if errResp.Error.Status == "UNREGISTERED" || errResp.Error.Status == "NOT_FOUND" {
		return true, fmt.Errorf("token unregistered")
	}
	return false, fmt.Errorf("fcm: status %d: %s", resp.StatusCode, errResp.Error.Status)
}
