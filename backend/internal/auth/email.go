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

// emailPattern is a lightweight (not full RFC 5322) check, just enough to reject an obvious typo before generating and emailing a code.
var emailPattern = regexp.MustCompile(`^[^@\s]+@[^@\s]+\.[^@\s]+$`)

// IsValidEmail is exported for routes_auth.go's handler-level check.
func IsValidEmail(email string) bool {
	return emailPattern.MatchString(strings.TrimSpace(email))
}

// EmailCodeKind distinguishes the two passwordless flows sharing this table, magic-link (admin/'s web login) and OTP (app/'s mobile login), which VerifyCode treats identically since both are just a one-time secret proving inbox control.
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

// GenerateAndStore invalidates any prior unconsumed code for (email, kind) before creating a new one, so an older still-unexpired code sitting in an inbox can't be used after a newer one was requested.
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

// LastSentAt returns when the most recent code of either kind was requested for this email, backing StartLogin's cooldown against hammering the send endpoint; zero time if none exists.
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

// VerifyCode looks up the code scoped by email (not just its hash, since OTP's 6-digit space isn't globally unique) and increments attempts on every active code for that email on a wrong guess, so repeated guessing burns down to ErrEmailCodeTooManyTries.
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

// NormalizeEmail lowercases and trims the address, which LoginOrRegister also uses as the "email" provider's stable identifier, so "Bob@x.com" and "bob@x.com" never resolve to two accounts.
func NormalizeEmail(email string) string {
	return strings.ToLower(strings.TrimSpace(email))
}
