package auth

import (
	"context"
	"crypto/ecdsa"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

const (
	appleTokenURL  = "https://appleid.apple.com/auth/token"
	appleRevokeURL = "https://appleid.apple.com/auth/revoke"
)

// AppleTokenClient talks to Apple's OAuth token/revoke endpoints to exchange a Sign in with Apple authorizationCode for a refresh token at login and revoke it on account deletion (App Store Guideline 5.1.1(v)); key == nil makes every method a safe no-op.
type AppleTokenClient struct {
	key        *ecdsa.PrivateKey
	teamID     string
	keyID      string
	clientID   string
	httpClient *http.Client
}

// NewAppleTokenClient disables Apple token exchange/revocation entirely if teamID, keyID and privateKeyPEM are all empty, but treats any other partial combination as a misconfiguration error.
func NewAppleTokenClient(teamID, keyID, privateKeyPEM, clientID string) (*AppleTokenClient, error) {
	if teamID == "" && keyID == "" && privateKeyPEM == "" {
		log.Print("auth: APPLE_TEAM_ID/APPLE_KEY_ID/APPLE_PRIVATE_KEY not set, Apple token revocation disabled")
		return &AppleTokenClient{clientID: clientID}, nil
	}
	if teamID == "" || keyID == "" || privateKeyPEM == "" {
		return nil, errors.New("auth: APPLE_TEAM_ID, APPLE_KEY_ID and APPLE_PRIVATE_KEY must all be set together, or none at all")
	}

	key, err := jwt.ParseECPrivateKeyFromPEM([]byte(privateKeyPEM))
	if err != nil {
		return nil, fmt.Errorf("auth: invalid APPLE_PRIVATE_KEY: %w", err)
	}

	return &AppleTokenClient{
		key:        key,
		teamID:     teamID,
		keyID:      keyID,
		clientID:   clientID,
		httpClient: &http.Client{Timeout: 10 * time.Second},
	}, nil
}

// buildClientSecret mints a short-lived (5 min) ES256 client_secret JWT, which Apple requires in place of a static client secret.
func (c *AppleTokenClient) buildClientSecret() (string, error) {
	now := time.Now().UTC()
	token := jwt.NewWithClaims(jwt.SigningMethodES256, jwt.MapClaims{
		"iss": c.teamID,
		"iat": now.Unix(),
		"exp": now.Add(5 * time.Minute).Unix(),
		"aud": appleIssuer,
		"sub": c.clientID,
	})
	token.Header["kid"] = c.keyID
	return token.SignedString(c.key)
}

// Exchange trades a single-use Sign in with Apple authorizationCode for the refresh token Revoke later needs, and is a no-op when disabled.
func (c *AppleTokenClient) Exchange(ctx context.Context, authorizationCode string) (string, error) {
	if c.key == nil {
		return "", nil
	}

	clientSecret, err := c.buildClientSecret()
	if err != nil {
		return "", fmt.Errorf("auth: apple client secret: %w", err)
	}

	form := url.Values{
		"grant_type":    {"authorization_code"},
		"code":          {authorizationCode},
		"client_id":     {c.clientID},
		"client_secret": {clientSecret},
	}

	var res struct {
		RefreshToken string `json:"refresh_token"`
	}
	if err := c.post(ctx, appleTokenURL, form, &res); err != nil {
		return "", err
	}
	if res.RefreshToken == "" {
		return "", errors.New("auth: apple token exchange returned no refresh_token")
	}
	return res.RefreshToken, nil
}

// Revoke calls Apple's revocation endpoint for a previously-exchanged refresh token (App Store Guideline 5.1.1(v)) and is a safe no-op when disabled so account.Service can call it unconditionally.
func (c *AppleTokenClient) Revoke(ctx context.Context, refreshToken string) error {
	if c.key == nil {
		return nil
	}

	clientSecret, err := c.buildClientSecret()
	if err != nil {
		return fmt.Errorf("auth: apple client secret: %w", err)
	}

	form := url.Values{
		"token":           {refreshToken},
		"token_type_hint": {"refresh_token"},
		"client_id":       {c.clientID},
		"client_secret":   {clientSecret},
	}
	return c.post(ctx, appleRevokeURL, form, nil)
}

// post submits a form-encoded request to an Apple OAuth endpoint and decodes the JSON response into out, skipping decode when out is nil (Revoke's empty-body response).
func (c *AppleTokenClient) post(ctx context.Context, endpoint string, form url.Values, out any) error {
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint, strings.NewReader(form.Encode()))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	res, err := c.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer res.Body.Close()

	body, err := io.ReadAll(io.LimitReader(res.Body, 1<<20))
	if err != nil {
		return err
	}
	if res.StatusCode != http.StatusOK {
		return fmt.Errorf("apple %s: unexpected status %d: %s", endpoint, res.StatusCode, string(body))
	}
	if out == nil || len(body) == 0 {
		return nil
	}
	return json.Unmarshal(body, out)
}
