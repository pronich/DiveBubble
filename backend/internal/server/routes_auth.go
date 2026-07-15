package server

import (
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"strings"
	"time"

	"divebubble_be/internal/auth"
	"divebubble_be/internal/config"

	"github.com/google/uuid"
)

func registerAuthRoutes(mux *http.ServeMux, cfg config.Config, identities *auth.IdentityRepository, sessions *auth.SessionRepository, issuer *auth.TokenIssuer) {
	mux.HandleFunc("POST /auth/google", handleAuthGoogle(cfg, identities, sessions, issuer))
	mux.HandleFunc("POST /auth/refresh", handleAuthRefresh(cfg, sessions, issuer))
	mux.Handle("POST /auth/logout", bearerAuth(issuer, handleAuthLogout(sessions)))
}

type googleAuthRequest struct {
	IDToken string `json:"idToken"`
}

type authLoginResponse struct {
	AccessToken          string    `json:"accessToken"`
	AccessTokenExpiresAt time.Time `json:"accessTokenExpiresAt"`
	RefreshToken         string    `json:"refreshToken"`
	UserID               uuid.UUID `json:"userId"`
	IsNewUser            bool      `json:"isNewUser"`
}

type refreshRequest struct {
	RefreshToken string `json:"refreshToken"`
}

type refreshResponse struct {
	AccessToken          string    `json:"accessToken"`
	AccessTokenExpiresAt time.Time `json:"accessTokenExpiresAt"`
	RefreshToken         string    `json:"refreshToken"`
}

func handleAuthGoogle(cfg config.Config, identities *auth.IdentityRepository, sessions *auth.SessionRepository, issuer *auth.TokenIssuer) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		body, err := io.ReadAll(io.LimitReader(r.Body, 1<<20))
		if err != nil {
			writeError(w, http.StatusBadRequest, "could not read body")
			return
		}
		var req googleAuthRequest
		if err := json.Unmarshal(body, &req); err != nil {
			writeError(w, http.StatusBadRequest, "invalid JSON body")
			return
		}
		if strings.TrimSpace(req.IDToken) == "" {
			writeError(w, http.StatusBadRequest, "idToken is required")
			return
		}

		identity, err := auth.VerifyGoogleIDToken(r.Context(), req.IDToken, cfg.GoogleServerClientID)
		if err != nil {
			writeError(w, http.StatusUnauthorized, "Google ID token verification failed")
			return
		}

		userID, isNewUser, err := identities.LoginOrRegister(r.Context(), "google", identity.Sub, identity.Email, identity.Name, identity.Picture)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not resolve user")
			return
		}

		rawRefresh, refreshHash, err := auth.GenerateRefreshToken()
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not create session")
			return
		}
		now := time.Now().UTC()
		sessionID, err := sessions.InsertSession(r.Context(), userID, "google", refreshHash, now.Add(cfg.RefreshSessionTTL))
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not create session")
			return
		}

		access, accessExp, err := issuer.IssueAccessToken(userID, sessionID)
		if err != nil {
			_ = sessions.DeleteSession(r.Context(), sessionID)
			writeError(w, http.StatusInternalServerError, "could not issue access token")
			return
		}

		writeJSON(w, http.StatusOK, authLoginResponse{
			AccessToken:          access,
			AccessTokenExpiresAt: accessExp,
			RefreshToken:         rawRefresh,
			UserID:               userID,
			IsNewUser:            isNewUser,
		})
	}
}

func handleAuthRefresh(cfg config.Config, sessions *auth.SessionRepository, issuer *auth.TokenIssuer) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		body, err := io.ReadAll(io.LimitReader(r.Body, 1<<20))
		if err != nil {
			writeError(w, http.StatusBadRequest, "could not read body")
			return
		}
		var req refreshRequest
		if err := json.Unmarshal(body, &req); err != nil {
			writeError(w, http.StatusBadRequest, "invalid JSON body")
			return
		}
		if strings.TrimSpace(req.RefreshToken) == "" {
			writeError(w, http.StatusBadRequest, "refreshToken is required")
			return
		}

		result, err := sessions.RotateRefreshToken(r.Context(), strings.TrimSpace(req.RefreshToken), cfg.RefreshSessionTTL)
		if err != nil {
			status, msg := refreshErrorResponse(err)
			writeError(w, status, msg)
			return
		}

		access, accessExp, err := issuer.IssueAccessToken(result.UserID, result.SessionID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not issue access token")
			return
		}

		writeJSON(w, http.StatusOK, refreshResponse{
			AccessToken:          access,
			AccessTokenExpiresAt: accessExp,
			RefreshToken:         result.RefreshToken,
		})
	}
}

func refreshErrorResponse(err error) (int, string) {
	switch {
	case errors.Is(err, auth.ErrRefreshInvalid):
		return http.StatusUnauthorized, "invalid refresh token"
	case errors.Is(err, auth.ErrRefreshExpired):
		return http.StatusUnauthorized, "refresh session has expired"
	case errors.Is(err, auth.ErrRefreshRevoked):
		return http.StatusUnauthorized, "refresh session is no longer valid"
	case errors.Is(err, auth.ErrRefreshReused):
		return http.StatusUnauthorized, "refresh token was already rotated; sign in again"
	default:
		return http.StatusInternalServerError, "could not refresh session"
	}
}

func handleAuthLogout(sessions *auth.SessionRepository) func(http.ResponseWriter, *http.Request, uuid.UUID, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID, sessionID uuid.UUID) {
		if err := sessions.RevokeSession(r.Context(), userID, sessionID); err != nil {
			writeError(w, http.StatusInternalServerError, "could not log out")
			return
		}
		w.WriteHeader(http.StatusOK)
	}
}

// bearerAuth validates the Authorization: Bearer <access token> header and passes the
// authenticated user id + session id through to next.
func bearerAuth(issuer *auth.TokenIssuer, next func(http.ResponseWriter, *http.Request, uuid.UUID, uuid.UUID)) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		raw, ok := parseBearer(r.Header.Get("Authorization"))
		if !ok {
			writeError(w, http.StatusUnauthorized, "missing or invalid bearer token")
			return
		}
		userID, sessionID, err := issuer.ParseAccessToken(raw)
		if err != nil {
			writeError(w, http.StatusUnauthorized, "invalid or expired token")
			return
		}
		next(w, r, userID, sessionID)
	}
}
