// Maps a backend error code (see backend/internal/server/errcodes.go) to a message to show
// the diver. The backend is being converted to codes one area at a time — an unrecognized
// code (an area not converted yet, or old-style prose slipping through) is returned as-is
// rather than treated as an error, so client and backend never need a hard synchronized
// cutover; each area can ship independently.
//
// Not yet localized (see the translations plan) — these are the English strings that will
// become the base .arb entries once that infrastructure lands.
String describeErrorCode(String code) => _messages[code] ?? code;

const _messages = <String, String>{
  'generic_error': 'Something went wrong. Please try again.',

  // Auth (backend/internal/server/routes_auth.go)
  'google_token_invalid': 'Google sign-in failed. Please try again.',
  'apple_token_invalid': 'Apple sign-in failed. Please try again.',
  'invalid_email': 'Enter a valid email address.',
  'email_code_cooldown': 'A code was already sent — check your inbox.',
  'email_and_code_required': 'Enter your email and the code you received.',
  'email_code_invalid': 'That code is invalid or has expired.',
  'email_code_too_many_tries': 'Too many incorrect attempts — request a new code.',
  'refresh_token_invalid': 'Your session is no longer valid. Please sign in again.',
  'refresh_token_expired': 'Your session has expired. Please sign in again.',
  'refresh_token_revoked': 'Your session is no longer valid. Please sign in again.',
  'refresh_token_reused': 'Your session was already refreshed elsewhere. Please sign in again.',
  'unauthenticated': 'Please sign in again.',
};
