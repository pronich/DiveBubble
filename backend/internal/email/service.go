// Package email sends transactional email via Resend's HTTP API directly (no SDK), always through a Resend Template referenced by alias (see templates.go) since Resend rejects mixing `template` with `html`/`text`/`react`.
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

// New builds a Service; apiKey == "" disables real sending so SendTemplate logs the template+variables instead, letting local dev complete a passwordless login via the server logs without a real Resend account.
func New(apiKey, from string) *Service {
	if apiKey == "" {
		log.Print("email: RESEND_API_KEY not set, emails will be logged instead of sent")
	}
	return &Service{apiKey: apiKey, from: from, client: &http.Client{}}
}

// SendTemplate sends a Resend dashboard template (which owns its own subject/body) by supplying only from/to/variables; templateAlias is the human-readable alias set at template-creation time, not the auto-generated template id.
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
