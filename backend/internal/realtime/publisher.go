package realtime

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
)

// Publisher pushes messages to Centrifugo so connected clients get them without polling.
type Publisher struct {
	baseURL string
	apiKey  string
	client  *http.Client
}

func NewPublisher(baseURL, apiKey string) *Publisher {
	return &Publisher{baseURL: baseURL, apiKey: apiKey, client: http.DefaultClient}
}

func (p *Publisher) Publish(ctx context.Context, channel string, data any) error {
	body, err := json.Marshal(map[string]any{"channel": channel, "data": data})
	if err != nil {
		return err
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, p.baseURL+"/api/publish", bytes.NewReader(body))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-API-Key", p.apiKey)

	res, err := p.client.Do(req)
	if err != nil {
		return err
	}
	defer res.Body.Close()

	if res.StatusCode != http.StatusOK {
		return fmt.Errorf("centrifugo publish: unexpected status %d", res.StatusCode)
	}
	return nil
}
