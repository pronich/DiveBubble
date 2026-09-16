package auth

import (
	"context"
	"errors"
	"slices"
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

// VerifyGoogleIDToken validates the token against Google's keys and checks its audience against validAudiences (plural to accept both an old and new Web OAuth client id mid-migration), which must be Web OAuth client ids since google_sign_in requests the token with serverClientId set to one.
func VerifyGoogleIDToken(ctx context.Context, idTokenString string, validAudiences []string) (GoogleIdentity, error) {
	// Empty audience disables idtoken's own aud check, done manually below against the whole list since idtoken only accepts a single audience per call.
	payload, err := idtoken.Validate(ctx, idTokenString, "")
	if err != nil {
		return GoogleIdentity{}, err
	}
	if !slices.Contains(validAudiences, payload.Audience) {
		return GoogleIdentity{}, errors.New("google token has unrecognized audience")
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
