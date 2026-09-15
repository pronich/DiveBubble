package server

// Error codes returned as the "error" field in an error response body
// ({"error": "<code>"}), replacing free-text English prose so the client can show a
// localized message instead of whatever string happened to be written here. Added
// incrementally, one backend area at a time — see CLAUDE.md's translations section for the
// running list of which areas are done.
//
// ErrCodeGeneric covers everything that isn't meaningful for a user to see distinctly: a
// malformed request body, an unexpected internal failure, or any other "something broke, try
// again" case (a Sentry/log line already carries the real reason — this string never needs
// to). The client can safely fall back to ErrCodeGeneric's own message for any code it
// doesn't recognize, so an area that hasn't been converted to codes yet just degrades to
// this instead of erroring on unknown input.
const ErrCodeGeneric = "generic_error"

// Auth (routes_auth.go)
const (
	ErrCodeGoogleTokenInvalid    = "google_token_invalid"
	ErrCodeAppleTokenInvalid     = "apple_token_invalid"
	ErrCodeInvalidEmail          = "invalid_email"
	ErrCodeEmailCodeCooldown     = "email_code_cooldown"
	ErrCodeEmailAndCodeRequired  = "email_and_code_required"
	ErrCodeEmailCodeInvalid      = "email_code_invalid"
	ErrCodeEmailCodeTooManyTries = "email_code_too_many_tries"
	ErrCodeRefreshTokenInvalid   = "refresh_token_invalid"
	ErrCodeRefreshTokenExpired   = "refresh_token_expired"
	ErrCodeRefreshTokenRevoked   = "refresh_token_revoked"
	ErrCodeRefreshTokenReused    = "refresh_token_reused"
	// ErrCodeUnauthenticated covers both "no/malformed bearer token" and "token invalid or
	// expired" — the client's reaction is identical either way (treat as signed out), so
	// there's no meaningful distinction to preserve for the user.
	ErrCodeUnauthenticated = "unauthenticated"
)
