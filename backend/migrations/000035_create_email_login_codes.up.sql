-- Backs both passwordless flows (magic link for admin/'s web login, OTP for app/'s mobile
-- login) with one table — a magic-link token and an OTP code are the same concept (a
-- one-time secret proving control of an inbox), just different alphabets/lengths, and
-- verification never needs to know which kind produced the hash it's checking against
-- (see internal/auth/email.go's VerifyCode). code_hash is a SHA-256 hex digest, same
-- "never store the raw secret" convention as auth_sessions.refresh_token_hash.
CREATE TABLE email_login_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL,
    code_hash TEXT NOT NULL,
    kind TEXT NOT NULL CHECK (kind IN ('magic_link', 'otp')),
    expires_at TIMESTAMPTZ NOT NULL,
    consumed_at TIMESTAMPTZ,
    attempts INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- StartLogin's cooldown check (has this email requested one recently) and VerifyCode's
-- lookup both filter on email first.
CREATE INDEX idx_email_login_codes_email ON email_login_codes (email);
