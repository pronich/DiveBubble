package server

import (
	"net/http"

	"divebuddy_be/internal/user"

	"github.com/google/uuid"
)

// withUser resolves the stub identity from X-User-Id — no real auth yet.
func withUser(svc *user.Service, next func(http.ResponseWriter, *http.Request, uuid.UUID)) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		id, err := uuid.Parse(r.Header.Get("X-User-Id"))
		if err != nil {
			writeError(w, http.StatusUnauthorized, "missing or invalid X-User-Id header")
			return
		}
		u, err := svc.GetOrCreate(r.Context(), id)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not resolve user")
			return
		}
		next(w, r, u.ID)
	}
}
