package server

import (
	"encoding/json"
	"errors"
	"io"
	"net/http"

	"divebubble_be/internal/waitlist"
)

// Public, unauthenticated — called from the marketing site (public/), not from app/ or
// admin/. A prospective dive-center owner has no DiveBubble account at this point.
func registerWaitlistRoutes(mux *http.ServeMux, svc *waitlist.Service) {
	mux.HandleFunc("POST /waitlist", handleWaitlistSignup(svc))
}

type waitlistSignupRequest struct {
	Email string `json:"email"`
}

func handleWaitlistSignup(svc *waitlist.Service) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var req waitlistSignupRequest
		dec := json.NewDecoder(io.LimitReader(r.Body, 1<<12))
		if err := dec.Decode(&req); err != nil {
			writeError(w, http.StatusBadRequest, "invalid JSON body")
			return
		}

		if err := svc.Signup(r.Context(), req.Email); err != nil {
			if errors.Is(err, waitlist.ErrInvalidEmail) {
				writeError(w, http.StatusBadRequest, "invalid email")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not save signup")
			return
		}

		w.WriteHeader(http.StatusNoContent)
	}
}
