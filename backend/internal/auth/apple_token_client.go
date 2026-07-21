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

// AppleTokenClient talks to Apple's OAuth token/revoke endpoints — used to exchange a native
// Sign in with Apple authorizationCode for a refresh token at login (so we have something to
// revoke later) and to revoke that refresh token when a diver deletes their account (App Store
// Review Guideline 5.1.1(v)). key == nil means disabled: every method becomes a safe no-op,
// same "empty disables" convention as internal/push.Service's nil httpClient.
type AppleTokenClient struct {
	key        *ecdsa.PrivateKey
	teamID     string
	keyID      string
	clientID   string
	httpClient *http.Client
}

// NewAppleTokenClient builds a client from a Sign in with Apple key (Team ID + Key ID + the
// .p8 private key's PEM content). All three empty disables Apple token exchange/revocation
// entirely — sign-in and account deletion still work, just without this side effect. Any
// other partial combination is treated as a real misconfiguration and returns an error.
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

// buildClientSecret mints a fresh ES256 client_secret JWT, as Apple's token/revoke endpoints
// require in place of a static client secret. Short-lived (5 min) since it's only ever used
// immediately after being built, never cached or reused across calls.
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

// Exchange trades a native Sign in with Apple authorizationCode for Apple's own refresh
// token, which is what Revoke later needs — the authorizationCode itself is single-use and
// already spent by the time this returns. A no-op (empty result, nil error) when disabled.
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

// Revoke calls Apple's revocation endpoint for a previously-exchanged refresh token — the
// account-deletion side effect Guideline 5.1.1(v) requires. A no-op when disabled, which is
// what makes it safe for account.Service to call unconditionally.
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

// post submits a form-encoded request to one of Apple's OAuth endpoints and decodes the JSON
// response into out (skipped if out is nil, e.g. Revoke's empty-body response).
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
