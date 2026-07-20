// Package email sends transactional email via Resend's HTTP API directly — no SDK
// dependency, same "call the vendor's REST API, skip their client library" precedent as
// internal/push (FCM) and internal/upload's SpacesBackend (DigitalOcean). Sends always go
// through a Resend Template (configured in Resend's own dashboard, referenced here only by
// its alias — see templates.go for the aliases/variable keys each flow uses), not raw HTML
// built in Go — Resend's template API rejects a request that mixes `template` with
// `html`/`text`/`react`.
package email

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
)

const resendEndpoint = "https://api.resend.com/emails"

type Service struct {
	apiKey string
	from   string
	client *http.Client
}

// New builds a Service. apiKey == "" disables real sending — SendTemplate logs the
// template+variables to stdout instead of erroring, so local dev can complete a
// passwordless login (the OTP/magic-link is right there in the server logs) without a
// real Resend account. Same "empty credential cleanly disables, doesn't error at startup"
// convention as push.Service and upload's Spaces-vs-local backend split.
func New(apiKey, from string) *Service {
	if apiKey == "" {
		log.Print("email: RESEND_API_KEY not set, emails will be logged instead of sent")
	}
	return &Service{apiKey: apiKey, from: from, client: &http.Client{}}
}

// SendTemplate sends one of the templates configured in Resend's own dashboard — the
// template owns its subject and body (built with the alias's own {{{VARIABLE}}} syntax),
// this only ever supplies from/to/variables. templateAlias is the human-readable alias set
// in Resend at template-creation time, not the auto-generated template id.
func (s *Service) SendTemplate(ctx context.Context, to, templateAlias string, variables map[string]string) error {
	if s.apiKey == "" {
		log.Printf("email (not sent, no RESEND_API_KEY) to=%s template=%s variables=%v", to, templateAlias, variables)
		return nil
	}

	body, err := json.Marshal(map[string]any{
		"from": s.from,
		"to":   []string{to},
		"template": map[string]any{
			"id":        templateAlias,
			"variables": variables,
		},
	})
	if err != nil {
		return err
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, resendEndpoint, bytes.NewReader(body))
	if err != nil {
		return err
	}
	req.Header.Set("Authorization", "Bearer "+s.apiKey)
	req.Header.Set("Content-Type", "application/json")

	res, err := s.client.Do(req)
	if err != nil {
		return err
	}
	defer res.Body.Close()

	if res.StatusCode >= 300 {
		return fmt.Errorf("email: resend returned status %d", res.StatusCode)
	}
	return nil
}
