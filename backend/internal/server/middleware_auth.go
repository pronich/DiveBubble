package server

import (
	"net/http"
	"strings"

	"divebubble_be/internal/auth"

	"github.com/google/uuid"
)

func parseBearer(header string) (token string, ok bool) {
	const prefix = "Bearer "
	h := strings.TrimSpace(header)
	if len(h) < len(prefix) || !strings.EqualFold(h[:len(prefix)], prefix) {
		return "", false
	}
	t := strings.TrimSpace(h[len(prefix):])
	if t == "" {
		return "", false
	}
	return t, true
}

// withAuth requires a valid bearer access token, resolving the caller's user id from its claims.
func withAuth(issuer *auth.TokenIssuer, next func(http.ResponseWriter, *http.Request, uuid.UUID)) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		raw, ok := parseBearer(r.Header.Get("Authorization"))
		if !ok {
			writeError(w, http.StatusUnauthorized, ErrCodeUnauthenticated)
			return
		}
		userID, _, err := issuer.ParseAccessToken(raw)
		if err != nil {
			writeError(w, http.StatusUnauthorized, ErrCodeUnauthenticated)
			return
		}
		next(w, r, userID)
	}
}

// optionalAuth resolves the caller's user id if a bearer token is present or passes uuid.Nil if absent, but still 401s on a present-but-invalid token rather than silently treating it as anonymous.
func optionalAuth(issuer *auth.TokenIssuer, next func(http.ResponseWriter, *http.Request, uuid.UUID)) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		header := r.Header.Get("Authorization")
		if strings.TrimSpace(header) == "" {
			next(w, r, uuid.Nil)
			return
		}
		raw, ok := parseBearer(header)
		if !ok {
			writeError(w, http.StatusUnauthorized, ErrCodeUnauthenticated)
			return
		}
		userID, _, err := issuer.ParseAccessToken(raw)
		if err != nil {
			writeError(w, http.StatusUnauthorized, ErrCodeUnauthenticated)
			return
		}
		next(w, r, userID)
	}
}
