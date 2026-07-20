package auth

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"database/sql"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"regexp"
	"strings"
	"time"
)

// Same lightweight (not full RFC 5322) pattern as internal/waitlist's own emailPattern —
// there's no session/account to blame a malformed address on either way, this is just
// enough to reject an obvious typo before generating and emailing a code for it.
var emailPattern = regexp.MustCompile(`^[^@\s]+@[^@\s]+\.[^@\s]+$`)

// IsValidEmail is exported for routes_auth.go's handler-level check.
func IsValidEmail(email string) bool {
	return emailPattern.MatchString(strings.TrimSpace(email))
}

// EmailCodeKind distinguishes the two passwordless flows that share this table — a
// magic-link token (admin/'s web login, emailed as a clickable URL) and an OTP code
// (app/'s mobile login, emailed as digits the diver types in) are the same underlying
// concept, a one-time secret proving control of an inbox, just a different alphabet/length
// for a different UI. VerifyCode never needs to know which kind produced a given hash.
type EmailCodeKind string

const (
	EmailCodeKindMagicLink EmailCodeKind = "magic_link"
	EmailCodeKindOTP       EmailCodeKind = "otp"
)

const maxEmailCodeAttempts = 5

var (
	ErrEmailCodeInvalid      = errors.New("invalid or expired code")
	ErrEmailCodeTooManyTries = errors.New("too many incorrect attempts — request a new code")
)

type EmailCodeRepository struct {
	DB *sql.DB
}

func NewEmailCodeRepository(db *sql.DB) *EmailCodeRepository {
	return &EmailCodeRepository{DB: db}
}

// GenerateAndStore creates a new code for (email, kind), first invalidating any prior
// unconsumed code for that exact pair — only the most recently requested code for a given
// flow should ever be usable, otherwise an older still-unexpired email sitting in an inbox
// could be used after the diver asked for (and received) a newer one.
func (r *EmailCodeRepository) GenerateAndStore(ctx context.Context, email string, kind EmailCodeKind, ttl time.Duration) (rawCode string, err error) {
	email = NormalizeEmail(email)

	rawCode, codeHash, err := generateCode(kind)
	if err != nil {
		return "", err
	}

	tx, err := r.DB.BeginTx(ctx, nil)
	if err != nil {
		return "", err
	}
	defer func() { _ = tx.Rollback() }()

	if _, err := tx.ExecContext(ctx, `
		UPDATE email_login_codes SET consumed_at = now()
		WHERE email = $1 AND kind = $2 AND consumed_at IS NULL
	`, email, kind); err != nil {
		return "", err
	}

	if _, err := tx.ExecContext(ctx, `
		INSERT INTO email_login_codes (email, code_hash, kind, expires_at)
		VALUES ($1, $2, $3, $4)
	`, email, codeHash, kind, time.Now().UTC().Add(ttl)); err != nil {
		return "", err
	}

	if err := tx.Commit(); err != nil {
		return "", err
	}
	return rawCode, nil
}

// LastSentAt returns when the most recent code (of either kind) was requested for this
// email — StartLogin's cooldown check, so a diver can't hammer the send endpoint (and the
// email quota behind it). Zero time if none exists yet.
func (r *EmailCodeRepository) LastSentAt(ctx context.Context, email string) (time.Time, error) {
	var t sql.NullTime
	err := r.DB.QueryRowContext(ctx, `
		SELECT max(created_at) FROM email_login_codes WHERE email = $1
	`, NormalizeEmail(email)).Scan(&t)
	if err != nil {
		return time.Time{}, err
	}
	if !t.Valid {
		return time.Time{}, nil
	}
	return t.Time, nil
}

// VerifyCode checks a submitted code — an OTP's typed digits, or a magic link's token read
// straight off the query string, same lookup either way — and consumes it on success,
// returning the normalized email to hand to LoginOrRegister. Scoped by email (not just the
// code hash) because OTP's 6-digit space isn't large enough to treat as globally unique the
// way a magic-link token is; a wrong guess increments every one of the email's still-active
// codes rather than erroring silently, so repeated guessing burns down to
// ErrEmailCodeTooManyTries instead of being retryable forever.
func (r *EmailCodeRepository) VerifyCode(ctx context.Context, email, code string) (string, error) {
	email = NormalizeEmail(email)
	codeHash := hashCode(code)

	tx, err := r.DB.BeginTx(ctx, nil)
	if err != nil {
		return "", err
	}
	defer func() { _ = tx.Rollback() }()

	var (
		id        string
		expiresAt time.Time
		attempts  int
	)
	err = tx.QueryRowContext(ctx, `
		SELECT id, expires_at, attempts FROM email_login_codes
		WHERE email = $1 AND code_hash = $2 AND consumed_at IS NULL
		FOR UPDATE
	`, email, codeHash).Scan(&id, &expiresAt, &attempts)

	if errors.Is(err, sql.ErrNoRows) {
		if _, err := tx.ExecContext(ctx, `
			UPDATE email_login_codes SET attempts = attempts + 1
			WHERE email = $1 AND consumed_at IS NULL AND expires_at > now()
		`, email); err != nil {
			return "", err
		}
		if err := tx.Commit(); err != nil {
			return "", err
		}
		return "", ErrEmailCodeInvalid
	}
	if err != nil {
		return "", err
	}

	if attempts >= maxEmailCodeAttempts {
		return "", ErrEmailCodeTooManyTries
	}
	if !expiresAt.After(time.Now().UTC()) {
		return "", ErrEmailCodeInvalid
	}

	if _, err := tx.ExecContext(ctx, `
		UPDATE email_login_codes SET consumed_at = now() WHERE id = $1
	`, id); err != nil {
		return "", err
	}
	if err := tx.Commit(); err != nil {
		return "", err
	}
	return email, nil
}

func generateCode(kind EmailCodeKind) (raw string, hash string, err error) {
	if kind == EmailCodeKindOTP {
		raw, err = generateNumericCode(6)
		if err != nil {
			return "", "", err
		}
		return raw, hashCode(raw), nil
	}

	var b [32]byte
	if _, err := rand.Read(b[:]); err != nil {
		return "", "", err
	}
	raw = base64.RawURLEncoding.EncodeToString(b[:])
	return raw, hashCode(raw), nil
}

func generateNumericCode(digits int) (string, error) {
	const charset = "0123456789"
	b := make([]byte, digits)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	out := make([]byte, digits)
	for i, v := range b {
		out[i] = charset[int(v)%len(charset)]
	}
	return string(out), nil
}

func hashCode(raw string) string {
	sum := sha256.Sum256([]byte(strings.TrimSpace(raw)))
	return hex.EncodeToString(sum[:])
}

// NormalizeEmail is also what LoginOrRegister's providerUserID is built from for the
// "email" provider — the address itself is the stable identifier (unlike Google/Apple's
// opaque sub), lowercased so "Bob@x.com" and "bob@x.com" never resolve to two accounts.
func NormalizeEmail(email string) string {
	return strings.ToLower(strings.TrimSpace(email))
}
