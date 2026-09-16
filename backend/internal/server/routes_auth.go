package server

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"strings"
	"time"

	"divebubble_be/internal/auth"
	"divebubble_be/internal/config"
	"divebubble_be/internal/divecenter"
	"divebubble_be/internal/email"

	"github.com/google/uuid"
)

func registerAuthRoutes(
	mux *http.ServeMux,
	cfg config.Config,
	identities *auth.IdentityRepository,
	sessions *auth.SessionRepository,
	issuer *auth.TokenIssuer,
	appleKeys *auth.AppleKeySet,
	appleTokens *auth.AppleTokenClient,
	emailCodes *auth.EmailCodeRepository,
	emailSvc *email.Service,
	diveCenterSvc *divecenter.Service,
) {
	mux.HandleFunc("POST /auth/google", handleAuthGoogle(cfg, identities, sessions, issuer, emailSvc, diveCenterSvc))
	mux.HandleFunc("POST /auth/apple", handleAuthApple(cfg, identities, sessions, issuer, appleKeys, appleTokens, emailSvc, diveCenterSvc))
	mux.HandleFunc("POST /auth/email/start", handleAuthEmailStart(cfg, emailCodes, emailSvc))
	mux.HandleFunc("POST /auth/email/verify", handleAuthEmailVerify(cfg, identities, sessions, issuer, emailCodes, emailSvc, diveCenterSvc))
	mux.HandleFunc("POST /auth/refresh", handleAuthRefresh(cfg, sessions, issuer))
	mux.Handle("POST /auth/logout", bearerAuth(issuer, handleAuthLogout(sessions)))
}

type googleAuthRequest struct {
	IDToken string `json:"idToken"`
}

// appleAuthRequest holds Email/FullName as one-time hints from ASAuthorizationAppleIDCredential, present only on the very first authorization ever.
type appleAuthRequest struct {
	IdentityToken string `json:"identityToken"`
	// Nonce is the raw nonce the client generated; the client sends Apple the SHA-256 hex digest of it instead.
	Nonce    string `json:"nonce"`
	Email    string `json:"email"`
	FullName string `json:"fullName"`
	// AuthorizationCode is exchanged best-effort for an Apple refresh token so DeleteAccount can revoke it later; sign-in never depends on it.
	AuthorizationCode string `json:"authorizationCode"`
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

// sendWelcomeEmail fires TemplateWelcome for a brand-new account, best-effort: a failed send must never fail sign-in itself.
func sendWelcomeEmail(ctx context.Context, emailSvc *email.Service, userID uuid.UUID, to string) {
	if to == "" {
		return
	}
	if err := emailSvc.SendTemplate(ctx, to, email.TemplateWelcome, nil); err != nil {
		log.Printf("auth: welcome email failed for user %s: %v", userID, err)
	}
}

// acceptDiveCenterInvitations auto-joins userID to any dive center that invited this email, best-effort: a failure here must never block sign-in itself.
func acceptDiveCenterInvitations(ctx context.Context, diveCenterSvc *divecenter.Service, userID uuid.UUID, email string) {
	if err := diveCenterSvc.AcceptInvitations(ctx, userID, email); err != nil {
		log.Printf("auth: accepting dive-center invitations failed for user %s: %v", userID, err)
	}
}

func handleAuthGoogle(cfg config.Config, identities *auth.IdentityRepository, sessions *auth.SessionRepository, issuer *auth.TokenIssuer, emailSvc *email.Service, diveCenterSvc *divecenter.Service) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		body, err := io.ReadAll(io.LimitReader(r.Body, 1<<20))
		if err != nil {
			writeError(w, http.StatusBadRequest, ErrCodeGeneric)
			return
		}
		var req googleAuthRequest
		if err := json.Unmarshal(body, &req); err != nil {
			writeError(w, http.StatusBadRequest, ErrCodeGeneric)
			return
		}
		if strings.TrimSpace(req.IDToken) == "" {
			writeError(w, http.StatusBadRequest, ErrCodeGeneric)
			return
		}

		identity, err := auth.VerifyGoogleIDToken(r.Context(), req.IDToken, cfg.GoogleServerClientIDs)
		if err != nil {
			writeError(w, http.StatusUnauthorized, ErrCodeGoogleTokenInvalid)
			return
		}

		userID, isNewUser, err := identities.LoginOrRegister(r.Context(), "google", identity.Sub, identity.Email, identity.Name, identity.Picture)
		if err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}
		if isNewUser {
			sendWelcomeEmail(r.Context(), emailSvc, userID, identity.Email)
		}
		acceptDiveCenterInvitations(r.Context(), diveCenterSvc, userID, identity.Email)

		rawRefresh, refreshHash, err := auth.GenerateRefreshToken()
		if err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}
		now := time.Now().UTC()
		sessionID, err := sessions.InsertSession(r.Context(), userID, "google", refreshHash, now.Add(cfg.RefreshSessionTTL))
		if err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		access, accessExp, err := issuer.IssueAccessToken(userID, sessionID)
		if err != nil {
			_ = sessions.DeleteSession(r.Context(), sessionID)
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
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

func handleAuthApple(cfg config.Config, identities *auth.IdentityRepository, sessions *auth.SessionRepository, issuer *auth.TokenIssuer, appleKeys *auth.AppleKeySet, appleTokens *auth.AppleTokenClient, emailSvc *email.Service, diveCenterSvc *divecenter.Service) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		body, err := io.ReadAll(io.LimitReader(r.Body, 1<<20))
		if err != nil {
			writeError(w, http.StatusBadRequest, ErrCodeGeneric)
			return
		}
		var req appleAuthRequest
		if err := json.Unmarshal(body, &req); err != nil {
			writeError(w, http.StatusBadRequest, ErrCodeGeneric)
			return
		}
		if strings.TrimSpace(req.IdentityToken) == "" {
			writeError(w, http.StatusBadRequest, ErrCodeGeneric)
			return
		}

		identity, err := appleKeys.VerifyAppleIdentityToken(r.Context(), req.IdentityToken, cfg.AppleAudience, req.Nonce)
		if err != nil {
			writeError(w, http.StatusUnauthorized, ErrCodeAppleTokenInvalid)
			return
		}

		// Prefer the token's own email over the credential hint, since the token is the verified source.
		email := identity.Email
		if email == "" {
			email = req.Email
		}

		userID, isNewUser, err := identities.LoginOrRegister(r.Context(), "apple", identity.Sub, email, req.FullName, "")
		if err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}
		if isNewUser {
			sendWelcomeEmail(r.Context(), emailSvc, userID, email)
		}
		acceptDiveCenterInvitations(r.Context(), diveCenterSvc, userID, email)

		// Best-effort: a failure exchanging the code must never block signing in.
		if req.AuthorizationCode != "" {
			if refreshToken, err := appleTokens.Exchange(r.Context(), req.AuthorizationCode); err != nil {
				log.Printf("auth: apple token exchange failed for user %s: %v", userID, err)
			} else if refreshToken != "" {
				if err := identities.SetAppleRefreshToken(r.Context(), userID, refreshToken); err != nil {
					log.Printf("auth: could not store apple refresh token for user %s: %v", userID, err)
				}
			}
		}

		rawRefresh, refreshHash, err := auth.GenerateRefreshToken()
		if err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}
		now := time.Now().UTC()
		sessionID, err := sessions.InsertSession(r.Context(), userID, "apple", refreshHash, now.Add(cfg.RefreshSessionTTL))
		if err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		access, accessExp, err := issuer.IssueAccessToken(userID, sessionID)
		if err != nil {
			_ = sessions.DeleteSession(r.Context(), sessionID)
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
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

type emailStartRequest struct {
	Email string `json:"email"`
	Kind  string `json:"kind"` // "magic_link" (admin/) or "otp" (app/)
}

type emailVerifyRequest struct {
	Email string `json:"email"`
	Code  string `json:"code"`
}

// handleAuthEmailStart always 200s on a well-formed email, since accounts are created transparently on first verify, so there's no enumeration risk to protect against.
func handleAuthEmailStart(cfg config.Config, emailCodes *auth.EmailCodeRepository, emailSvc *email.Service) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		body, err := io.ReadAll(io.LimitReader(r.Body, 1<<20))
		if err != nil {
			writeError(w, http.StatusBadRequest, ErrCodeGeneric)
			return
		}
		var req emailStartRequest
		if err := json.Unmarshal(body, &req); err != nil {
			writeError(w, http.StatusBadRequest, ErrCodeGeneric)
			return
		}
		if !auth.IsValidEmail(req.Email) {
			writeError(w, http.StatusBadRequest, ErrCodeInvalidEmail)
			return
		}

		var kind auth.EmailCodeKind
		switch req.Kind {
		case string(auth.EmailCodeKindMagicLink):
			kind = auth.EmailCodeKindMagicLink
		case string(auth.EmailCodeKindOTP):
			kind = auth.EmailCodeKindOTP
		default:
			writeError(w, http.StatusBadRequest, ErrCodeGeneric)
			return
		}

		lastSent, err := emailCodes.LastSentAt(r.Context(), req.Email)
		if err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}
		if !lastSent.IsZero() && time.Now().UTC().Before(lastSent.Add(cfg.EmailCodeCooldown)) {
			writeError(w, http.StatusTooManyRequests, ErrCodeEmailCodeCooldown)
			return
		}

		ttl := cfg.EmailOTPTTL
		if kind == auth.EmailCodeKindMagicLink {
			ttl = cfg.EmailMagicLinkTTL
		}
		rawCode, err := emailCodes.GenerateAndStore(r.Context(), req.Email, kind, ttl)
		if err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		normalizedEmail := auth.NormalizeEmail(req.Email)
		var sendErr error
		if kind == auth.EmailCodeKindMagicLink {
			link := fmt.Sprintf("%s/?token=%s&email=%s", cfg.AdminBaseURL, url.QueryEscape(rawCode), url.QueryEscape(normalizedEmail))
			sendErr = emailSvc.SendTemplate(r.Context(), normalizedEmail, email.TemplateMagicLink, map[string]string{email.VarMagicLink: link})
		} else {
			sendErr = emailSvc.SendTemplate(r.Context(), normalizedEmail, email.TemplateOTP, map[string]string{email.VarOTPCode: rawCode})
		}
		if sendErr != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		w.WriteHeader(http.StatusOK)
	}
}

func handleAuthEmailVerify(cfg config.Config, identities *auth.IdentityRepository, sessions *auth.SessionRepository, issuer *auth.TokenIssuer, emailCodes *auth.EmailCodeRepository, emailSvc *email.Service, diveCenterSvc *divecenter.Service) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		body, err := io.ReadAll(io.LimitReader(r.Body, 1<<20))
		if err != nil {
			writeError(w, http.StatusBadRequest, ErrCodeGeneric)
			return
		}
		var req emailVerifyRequest
		if err := json.Unmarshal(body, &req); err != nil {
			writeError(w, http.StatusBadRequest, ErrCodeGeneric)
			return
		}
		if strings.TrimSpace(req.Email) == "" || strings.TrimSpace(req.Code) == "" {
			writeError(w, http.StatusBadRequest, ErrCodeEmailAndCodeRequired)
			return
		}

		normalizedEmail, err := emailCodes.VerifyCode(r.Context(), req.Email, req.Code)
		if err != nil {
			status, msg := emailCodeErrorResponse(err)
			writeError(w, status, msg)
			return
		}

		// Uses LoginOrRegisterByEmail (not the plain LoginOrRegister every other provider uses) so a diver with an existing Google/Apple account under this address links onto it instead of getting a second account.
		userID, isNewUser, err := identities.LoginOrRegisterByEmail(r.Context(), normalizedEmail)
		if err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}
		if isNewUser {
			sendWelcomeEmail(r.Context(), emailSvc, userID, normalizedEmail)
		}
		acceptDiveCenterInvitations(r.Context(), diveCenterSvc, userID, normalizedEmail)

		rawRefresh, refreshHash, err := auth.GenerateRefreshToken()
		if err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}
		now := time.Now().UTC()
		sessionID, err := sessions.InsertSession(r.Context(), userID, "email", refreshHash, now.Add(cfg.RefreshSessionTTL))
		if err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		access, accessExp, err := issuer.IssueAccessToken(userID, sessionID)
		if err != nil {
			_ = sessions.DeleteSession(r.Context(), sessionID)
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
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

func emailCodeErrorResponse(err error) (int, string) {
	switch {
	case errors.Is(err, auth.ErrEmailCodeInvalid):
		return http.StatusUnauthorized, ErrCodeEmailCodeInvalid
	case errors.Is(err, auth.ErrEmailCodeTooManyTries):
		return http.StatusTooManyRequests, ErrCodeEmailCodeTooManyTries
	default:
		return http.StatusInternalServerError, ErrCodeGeneric
	}
}

func handleAuthRefresh(cfg config.Config, sessions *auth.SessionRepository, issuer *auth.TokenIssuer) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		body, err := io.ReadAll(io.LimitReader(r.Body, 1<<20))
		if err != nil {
			writeError(w, http.StatusBadRequest, ErrCodeGeneric)
			return
		}
		var req refreshRequest
		if err := json.Unmarshal(body, &req); err != nil {
			writeError(w, http.StatusBadRequest, ErrCodeGeneric)
			return
		}
		if strings.TrimSpace(req.RefreshToken) == "" {
			writeError(w, http.StatusBadRequest, ErrCodeGeneric)
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
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
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
		return http.StatusUnauthorized, ErrCodeRefreshTokenInvalid
	case errors.Is(err, auth.ErrRefreshExpired):
		return http.StatusUnauthorized, ErrCodeRefreshTokenExpired
	case errors.Is(err, auth.ErrRefreshRevoked):
		return http.StatusUnauthorized, ErrCodeRefreshTokenRevoked
	case errors.Is(err, auth.ErrRefreshReused):
		return http.StatusUnauthorized, ErrCodeRefreshTokenReused
	default:
		return http.StatusInternalServerError, ErrCodeGeneric
	}
}

func handleAuthLogout(sessions *auth.SessionRepository) func(http.ResponseWriter, *http.Request, uuid.UUID, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID, sessionID uuid.UUID) {
		if err := sessions.RevokeSession(r.Context(), userID, sessionID); err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}
		w.WriteHeader(http.StatusOK)
	}
}

func bearerAuth(issuer *auth.TokenIssuer, next func(http.ResponseWriter, *http.Request, uuid.UUID, uuid.UUID)) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		raw, ok := parseBearer(r.Header.Get("Authorization"))
		if !ok {
			writeError(w, http.StatusUnauthorized, ErrCodeUnauthenticated)
			return
		}
		userID, sessionID, err := issuer.ParseAccessToken(raw)
		if err != nil {
			writeError(w, http.StatusUnauthorized, ErrCodeUnauthenticated)
			return
		}
		next(w, r, userID, sessionID)
	}
}
