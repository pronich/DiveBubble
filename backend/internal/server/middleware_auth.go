package server

import (
	"net/http"
	"strings"

	"divebuddy_be/internal/auth"

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
			writeError(w, http.StatusUnauthorized, "missing or invalid bearer token")
			return
		}
		userID, _, err := issuer.ParseAccessToken(raw)
		if err != nil {
			writeError(w, http.StatusUnauthorized, "invalid or expired token")
			return
		}
		next(w, r, userID)
	}
}

// optionalAuth resolves the caller's user id if a valid bearer token is present, or passes
// uuid.Nil for anonymous callers (no Authorization header at all) — for routes that stay
// browsable without an account but personalize the response (e.g. "joined") when logged in.
// A *present but invalid* token still 401s, so a stale/garbled token doesn't silently degrade
// to anonymous instead of surfacing the problem.
func optionalAuth(issuer *auth.TokenIssuer, next func(http.ResponseWriter, *http.Request, uuid.UUID)) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		header := r.Header.Get("Authorization")
		if strings.TrimSpace(header) == "" {
			next(w, r, uuid.Nil)
			return
		}
		raw, ok := parseBearer(header)
		if !ok {
			writeError(w, http.StatusUnauthorized, "invalid bearer token")
			return
		}
		userID, _, err := issuer.ParseAccessToken(raw)
		if err != nil {
			writeError(w, http.StatusUnauthorized, "invalid or expired token")
			return
		}
		next(w, r, userID)
	}
}
