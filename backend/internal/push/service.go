// Package push sends Firebase Cloud Messaging notifications. Deliberately minimal for now —
// one event type (new chat message), no notification categories/preferences yet (see
// CLAUDE.md's push notifications section for the fuller plan this is the first slice of).
package push

import (
	"context"
	"log"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"github.com/google/uuid"
	"google.golang.org/api/option"
)

type Service struct {
	repo *Repository
	// client is nil when no credentials file is configured — every send becomes a silent
	// no-op rather than an error, same pattern as upload.Service's Spaces-vs-local split.
	client *messaging.Client
}

// New builds a Service. credentialsJSON == "" disables push entirely (local dev default) —
// this is not an error, since push infra shouldn't block the rest of the API from running.
// Takes the service account JSON content directly (not a file path) so it's just another
// env var, same as every other secret in this project — no Docker volume mount needed in
// docker-compose.prod.yml.
func New(ctx context.Context, repo *Repository, credentialsJSON string) (*Service, error) {
	if credentialsJSON == "" {
		log.Print("push: FIREBASE_CREDENTIALS_JSON not set, push notifications disabled")
		return &Service{repo: repo}, nil
	}

	app, err := firebase.NewApp(ctx, nil, option.WithCredentialsJSON([]byte(credentialsJSON)))
	if err != nil {
		return nil, err
	}
	client, err := app.Messaging(ctx)
	if err != nil {
		return nil, err
	}
	return &Service{repo: repo, client: client}, nil
}

// RegisterToken associates a device's FCM token with the signed-in user, called by the
// client on login/token refresh.
func (s *Service) RegisterToken(ctx context.Context, userID uuid.UUID, platform, token string) error {
	return s.repo.Upsert(ctx, userID, platform, token)
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
// in routes_message.go).
func (s *Service) SendToUsers(ctx context.Context, userIDs []uuid.UUID, n Notification) {
	if s == nil || s.client == nil || len(userIDs) == 0 {
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

	// FCM caps a single multicast at 500 tokens — plenty for a trip's Bubble, no batching needed yet.
	resp, err := s.client.SendEachForMulticast(ctx, &messaging.MulticastMessage{
		Tokens:       tokens,
		Notification: &messaging.Notification{Title: n.Title, Body: n.Body},
		Data:         n.Data,
	})
	if err != nil {
		log.Printf("push: send failed: %v", err)
		return
	}

	if resp.FailureCount == 0 {
		return
	}
	var deadTokens []string
	for i, r := range resp.Responses {
		if r.Success {
			continue
		}
		if messaging.IsUnregistered(r.Error) {
			deadTokens = append(deadTokens, tokens[i])
		} else {
			log.Printf("push: send to one token failed: %v", r.Error)
		}
	}
	if err := s.repo.DeleteTokens(ctx, deadTokens); err != nil {
		log.Printf("push: could not prune dead tokens: %v", err)
	}
}
