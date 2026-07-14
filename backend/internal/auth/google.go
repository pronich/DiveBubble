package auth

import (
	"context"
	"errors"
	"strings"

	"google.golang.org/api/idtoken"
)

// GoogleIdentity is the subset of a verified Google ID token's claims we care about.
type GoogleIdentity struct {
	Sub           string
	Email         string
	EmailVerified bool
	Name          string
	Picture       string
}

// VerifyGoogleIDToken validates the token's signature and audience against Google's public keys,
// then extracts the claims we persist. audience must be the Web OAuth client id (not the iOS one) —
// google_sign_in on the client requests the ID token with serverClientId set to that same client.
func VerifyGoogleIDToken(ctx context.Context, idTokenString, audience string) (GoogleIdentity, error) {
	payload, err := idtoken.Validate(ctx, idTokenString, audience)
	if err != nil {
		return GoogleIdentity{}, err
	}

	sub := strings.TrimSpace(payload.Subject)
	if sub == "" {
		return GoogleIdentity{}, errors.New("google token missing subject")
	}

	identity := GoogleIdentity{Sub: sub}
	if v, ok := payload.Claims["email"].(string); ok {
		identity.Email = v
	}
	if v, ok := payload.Claims["email_verified"].(bool); ok {
		identity.EmailVerified = v
	}
	if v, ok := payload.Claims["name"].(string); ok {
		identity.Name = v
	}
	if v, ok := payload.Claims["picture"].(string); ok {
		identity.Picture = v
	}
	return identity, nil
}
