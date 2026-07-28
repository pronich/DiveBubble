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

// VerifyGoogleIDToken validates the token's signature against Google's public keys and checks
// its audience against every id in validAudiences (plural to allow a brief window where both an
// old and new Web OAuth client id are accepted mid-migration — see GoogleServerClientIDs), then
// extracts the claims we persist. Web OAuth client ids, not iOS ones — google_sign_in on the
// client requests the ID token with serverClientId set to one of these.
func VerifyGoogleIDToken(ctx context.Context, idTokenString string, validAudiences []string) (GoogleIdentity, error) {
	// Empty audience disables idtoken's own aud check — done manually below instead, against
	// the whole list, since it only accepts a single audience per call.
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
