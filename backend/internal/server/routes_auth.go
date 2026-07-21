package server

import (
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
) {
	mux.HandleFunc("POST /auth/google", handleAuthGoogle(cfg, identities, sessions, issuer))
	mux.HandleFunc("POST /auth/apple", handleAuthApple(cfg, identities, sessions, issuer, appleKeys, appleTokens))
	mux.HandleFunc("POST /auth/email/start", handleAuthEmailStart(cfg, emailCodes, emailSvc))
	mux.HandleFunc("POST /auth/email/verify", handleAuthEmailVerify(cfg, identities, sessions, issuer, emailCodes))
	mux.HandleFunc("POST /auth/refresh", handleAuthRefresh(cfg, sessions, issuer))
	mux.Handle("POST /auth/logout", bearerAuth(issuer, handleAuthLogout(sessions)))
}

type googleAuthRequest struct {
	IDToken string `json:"idToken"`
}

// appleAuthRequest — Email/FullName are out-of-band hints from the native
// ASAuthorizationAppleIDCredential, present only on the very first authorization ever (Apple
// doesn't repeat them on later sign-ins, and never puts them in the identity token itself).
// Nonce is the *raw* nonce the client generated — the client sends Apple the SHA-256 hex
// digest of it instead (see AppleKeySet.VerifyAppleIdentityToken's own nonce comment).
type appleAuthRequest struct {
	IdentityToken string `json:"identityToken"`
	Nonce         string `json:"nonce"`
	Email         string `json:"email"`
	FullName      string `json:"fullName"`
	// AuthorizationCode is the native ASAuthorizationAppleIDCredential's one-time code —
	// exchanged (best-effort, see handleAuthApple) for an Apple refresh token so DeleteAccount
	// has something to revoke later. Optional: omitted, empty, or a failed exchange just means
	// account deletion won't have an Apple token to revoke for this diver — sign-in itself
	// never depends on it.
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

func handleAuthApple(cfg config.Config, identities *auth.IdentityRepository, sessions *auth.SessionRepository, issuer *auth.TokenIssuer, appleKeys *auth.AppleKeySet, appleTokens *auth.AppleTokenClient) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		body, err := io.ReadAll(io.LimitReader(r.Body, 1<<20))
		if err != nil {
			writeError(w, http.StatusBadRequest, "could not read body")
			return
		}
		var req appleAuthRequest
		if err := json.Unmarshal(body, &req); err != nil {
			writeError(w, http.StatusBadRequest, "invalid JSON body")
			return
		}
		if strings.TrimSpace(req.IdentityToken) == "" {
			writeError(w, http.StatusBadRequest, "identityToken is required")
			return
		}

		identity, err := appleKeys.VerifyAppleIdentityToken(r.Context(), req.IdentityToken, cfg.AppleAudience, req.Nonce)
		if err != nil {
			writeError(w, http.StatusUnauthorized, "Apple ID token verification failed")
			return
		}

		// Prefer the token's own email over the credential hint if both are present — the
		// token is the verified source; the hint is only ever useful when the token omits it.
		email := identity.Email
		if email == "" {
			email = req.Email
		}

		userID, isNewUser, err := identities.LoginOrRegister(r.Context(), "apple", identity.Sub, email, req.FullName, "")
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not resolve user")
			return
		}

		// Best-effort: an Apple refresh token is only needed later, for DeleteAccount to
		// revoke — a failure here (disabled client, network hiccup, Apple outage) must never
		// block signing in.
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
			writeError(w, http.StatusInternalServerError, "could not create session")
			return
		}
		now := time.Now().UTC()
		sessionID, err := sessions.InsertSession(r.Context(), userID, "apple", refreshHash, now.Add(cfg.RefreshSessionTTL))
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

type emailStartRequest struct {
	Email string `json:"email"`
	Kind  string `json:"kind"` // "magic_link" (admin/) or "otp" (app/)
}

type emailVerifyRequest struct {
	Email string `json:"email"`
	Code  string `json:"code"`
}

// handleAuthEmailStart sends a login code to the given address — always 200 on a
// well-formed email (there's no "account not found" case to hide the way a traditional
// password-reset flow would have: LoginOrRegister creates the account transparently on
// first verify, exactly like Google/Apple, so knowing "a code was just sent to X" reveals
// nothing about whether X already had a DiveBubble account).
func handleAuthEmailStart(cfg config.Config, emailCodes *auth.EmailCodeRepository, emailSvc *email.Service) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		body, err := io.ReadAll(io.LimitReader(r.Body, 1<<20))
		if err != nil {
			writeError(w, http.StatusBadRequest, "could not read body")
			return
		}
		var req emailStartRequest
		if err := json.Unmarshal(body, &req); err != nil {
			writeError(w, http.StatusBadRequest, "invalid JSON body")
			return
		}
		if !auth.IsValidEmail(req.Email) {
			writeError(w, http.StatusBadRequest, "a valid email is required")
			return
		}

		var kind auth.EmailCodeKind
		switch req.Kind {
		case string(auth.EmailCodeKindMagicLink):
			kind = auth.EmailCodeKindMagicLink
		case string(auth.EmailCodeKindOTP):
			kind = auth.EmailCodeKindOTP
		default:
			writeError(w, http.StatusBadRequest, `kind must be "magic_link" or "otp"`)
			return
		}

		lastSent, err := emailCodes.LastSentAt(r.Context(), req.Email)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not check send rate")
			return
		}
		if !lastSent.IsZero() && time.Now().UTC().Before(lastSent.Add(cfg.EmailCodeCooldown)) {
			writeError(w, http.StatusTooManyRequests, "a code was already sent — check your inbox")
			return
		}

		ttl := cfg.EmailOTPTTL
		if kind == auth.EmailCodeKindMagicLink {
			ttl = cfg.EmailMagicLinkTTL
		}
		rawCode, err := emailCodes.GenerateAndStore(r.Context(), req.Email, kind, ttl)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not create login code")
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
			writeError(w, http.StatusInternalServerError, "could not send email")
			return
		}

		w.WriteHeader(http.StatusOK)
	}
}

func handleAuthEmailVerify(cfg config.Config, identities *auth.IdentityRepository, sessions *auth.SessionRepository, issuer *auth.TokenIssuer, emailCodes *auth.EmailCodeRepository) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		body, err := io.ReadAll(io.LimitReader(r.Body, 1<<20))
		if err != nil {
			writeError(w, http.StatusBadRequest, "could not read body")
			return
		}
		var req emailVerifyRequest
		if err := json.Unmarshal(body, &req); err != nil {
			writeError(w, http.StatusBadRequest, "invalid JSON body")
			return
		}
		if strings.TrimSpace(req.Email) == "" || strings.TrimSpace(req.Code) == "" {
			writeError(w, http.StatusBadRequest, "email and code are required")
			return
		}

		normalizedEmail, err := emailCodes.VerifyCode(r.Context(), req.Email, req.Code)
		if err != nil {
			status, msg := emailCodeErrorResponse(err)
			writeError(w, status, msg)
			return
		}

		// LoginOrRegisterByEmail (not the plain LoginOrRegister every other provider uses)
		// so a diver who already has a Google/Apple account under this same address links
		// onto it instead of getting a second, disconnected account — see its own doc
		// comment in internal/auth/identity.go.
		userID, isNewUser, err := identities.LoginOrRegisterByEmail(r.Context(), normalizedEmail)
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
		sessionID, err := sessions.InsertSession(r.Context(), userID, "email", refreshHash, now.Add(cfg.RefreshSessionTTL))
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

func emailCodeErrorResponse(err error) (int, string) {
	switch {
	case errors.Is(err, auth.ErrEmailCodeInvalid):
		return http.StatusUnauthorized, "invalid or expired code"
	case errors.Is(err, auth.ErrEmailCodeTooManyTries):
		return http.StatusTooManyRequests, "too many incorrect attempts — request a new code"
	default:
		return http.StatusInternalServerError, "could not verify code"
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
