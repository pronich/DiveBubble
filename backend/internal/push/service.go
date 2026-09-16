// Package push sends FCM notifications via the raw v1 HTTP API instead of firebase.google.com/go/v4, whose transitive deps were too heavy for this droplet's Docker build.
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
	// httpClient is nil when no credentials are configured, making every send a silent no-op instead of an error.
	httpClient *http.Client
	projectID  string
}

// New builds a Service; an empty credentialsJSON disables push without erroring, since push infra shouldn't block the rest of the API from starting.
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

// RegisterToken associates a device's FCM token with the signed-in user, called on login or token refresh.
func (s *Service) RegisterToken(ctx context.Context, userID uuid.UUID, platform, token string) error {
	return s.repo.Upsert(ctx, userID, platform, token)
}

// UnregisterToken removes the token row, since push_tokens has no separate "enabled" flag to flip.
func (s *Service) UnregisterToken(ctx context.Context, userID uuid.UUID, token string) error {
	return s.repo.DeleteTokenForUser(ctx, userID, token)
}

type Notification struct {
	Title string
	// Subtitle is a real separate line only on iOS (via the APNs override in sendOne); Android has no equivalent field so it gets folded into the title.
	Subtitle string
	Body     string
	// Data lets the client deep-link (e.g. into the right Bubble) when the user taps the notification.
	Data map[string]string
}

// SendToUsers fans a notification out to every device registered to the given users, best-effort: errors are only logged since a failed push must never fail the triggering request.
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
	APNS         *fcmApnsConfig    `json:"apns,omitempty"`
}

type fcmNotification struct {
	Title string `json:"title"`
	Body  string `json:"body"`
}

// fcmApnsConfig overrides the alert shown on iOS, needed only because Subtitle has no equivalent field in fcmNotification.
type fcmApnsConfig struct {
	Payload fcmApnsPayload `json:"payload"`
}

type fcmApnsPayload struct {
	Aps fcmApnsAps `json:"aps"`
}

type fcmApnsAps struct {
	Alert fcmApnsAlert `json:"alert"`
}

type fcmApnsAlert struct {
	Title    string `json:"title"`
	Subtitle string `json:"subtitle,omitempty"`
	Body     string `json:"body"`
}

type fcmErrorResponse struct {
	Error struct {
		Status string `json:"status"`
	} `json:"error"`
}

// sendOne posts a single message and reports whether the token is dead so the caller can prune it; other errors (e.g. transient quota issues) don't imply the token itself is bad.
func (s *Service) sendOne(ctx context.Context, token string, n Notification) (dead bool, err error) {
	// Android has no subtitle field, so it's folded into the title rather than dropped.
	androidTitle := n.Title
	if n.Subtitle != "" {
		androidTitle = n.Title + " · " + n.Subtitle
	}

	msg := fcmMessage{
		Token:        token,
		Notification: &fcmNotification{Title: androidTitle, Body: n.Body},
		Data:         n.Data,
	}
	if n.Subtitle != "" {
		// Overrides the alert for iOS only; the shared Notification block above still covers Android.
		msg.APNS = &fcmApnsConfig{Payload: fcmApnsPayload{Aps: fcmApnsAps{
			Alert: fcmApnsAlert{Title: n.Title, Subtitle: n.Subtitle, Body: n.Body},
		}}}
	}

	body, err := json.Marshal(fcmSendRequest{Message: msg})
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
