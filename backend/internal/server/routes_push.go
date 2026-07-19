package server

import (
	"encoding/json"
	"io"
	"net/http"
	"strings"

	"divebubble_be/internal/auth"
	"divebubble_be/internal/push"

	"github.com/google/uuid"
)

func registerPushRoutes(mux *http.ServeMux, svc *push.Service, authIssuer *auth.TokenIssuer) {
	mux.HandleFunc("POST /me/push-token", withAuth(authIssuer, handleRegisterPushToken(svc)))
}

type registerPushTokenRequest struct {
	Token    string `json:"token"`
	Platform string `json:"platform"`
}

func handleRegisterPushToken(svc *push.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		var req registerPushTokenRequest
		dec := json.NewDecoder(io.LimitReader(r.Body, 1<<16))
		if err := dec.Decode(&req); err != nil {
			writeError(w, http.StatusBadRequest, "invalid JSON body")
			return
		}

		req.Token = strings.TrimSpace(req.Token)
		if req.Token == "" {
			writeError(w, http.StatusBadRequest, "token is required")
			return
		}
		if req.Platform != "android" && req.Platform != "web" {
			// Defaults to ios rather than erroring — the only platform this project ships
			// against a real device today (see CLAUDE.md's Stack table).
			req.Platform = "ios"
		}

		if err := svc.RegisterToken(r.Context(), userID, req.Platform, req.Token); err != nil {
			writeError(w, http.StatusInternalServerError, "could not register push token")
			return
		}
		w.WriteHeader(http.StatusNoContent)
	}
}
