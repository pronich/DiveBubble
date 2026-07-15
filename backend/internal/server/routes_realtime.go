package server

import (
	"net/http"

	"divebubble_be/internal/auth"
	"divebubble_be/internal/realtime"

	"github.com/google/uuid"
)

func registerRealtimeRoutes(mux *http.ServeMux, realtimeIssuer *realtime.TokenIssuer, authIssuer *auth.TokenIssuer) {
	mux.HandleFunc("GET /realtime/token", withAuth(authIssuer, handleRealtimeToken(realtimeIssuer)))
}

func handleRealtimeToken(realtimeIssuer *realtime.TokenIssuer) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		token, err := realtimeIssuer.ConnectionToken(userID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not issue token")
			return
		}
		writeJSON(w, http.StatusOK, map[string]string{"token": token})
	}
}
