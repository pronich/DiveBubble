package server

import (
	"net/http"

	"divebuddy_be/internal/realtime"
	"divebuddy_be/internal/user"

	"github.com/google/uuid"
)

func registerRealtimeRoutes(mux *http.ServeMux, issuer *realtime.TokenIssuer, userSvc *user.Service) {
	mux.HandleFunc("GET /realtime/token", withUser(userSvc, handleRealtimeToken(issuer)))
}

func handleRealtimeToken(issuer *realtime.TokenIssuer) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		token, err := issuer.ConnectionToken(userID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not issue token")
			return
		}
		writeJSON(w, http.StatusOK, map[string]string{"token": token})
	}
}
