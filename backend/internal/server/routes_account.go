package server

import (
	"log"
	"net/http"

	"divebubble_be/internal/account"
	"divebubble_be/internal/auth"

	"github.com/google/uuid"
)

func registerAccountRoutes(mux *http.ServeMux, svc *account.Service, authIssuer *auth.TokenIssuer) {
	mux.HandleFunc("DELETE /me", withAuth(authIssuer, handleDeleteAccount(svc)))
}

// handleDeleteAccount never swallows the error — the client only clears its local session
// (tokens, native Google session) once this genuinely succeeds, so a 500 here must reach it.
func handleDeleteAccount(svc *account.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		if err := svc.DeleteAccount(r.Context(), userID); err != nil {
			log.Printf("delete account failed for %s: %v", userID, err)
			writeError(w, http.StatusInternalServerError, "could not delete account")
			return
		}
		w.WriteHeader(http.StatusOK)
	}
}
