package auth

import (
	"context"
	"database/sql"
	"errors"
	"time"

	"github.com/google/uuid"
)

type SessionRepository struct {
	DB *sql.DB
}

func NewSessionRepository(db *sql.DB) *SessionRepository {
	return &SessionRepository{DB: db}
}

const (
	revokeReasonRotated = "rotated"
	revokeReasonLogout  = "logout"
)

var (
	ErrRefreshInvalid = errors.New("invalid refresh token")
	ErrRefreshExpired = errors.New("refresh session expired")
	ErrRefreshRevoked = errors.New("refresh session revoked")
	ErrRefreshReused  = errors.New("refresh token reused after rotation")
)

// InsertSession stores a new refresh session; the raw refresh token is never persisted, only its hash.
func (r *SessionRepository) InsertSession(ctx context.Context, userID uuid.UUID, provider, refreshTokenHash string, expiresAt time.Time) (uuid.UUID, error) {
	var id uuid.UUID
	err := r.DB.QueryRowContext(ctx, `
		INSERT INTO auth_sessions (user_id, provider, refresh_token_hash, expires_at)
		VALUES ($1, $2, $3, $4)
		RETURNING id
	`, userID, provider, refreshTokenHash, expiresAt.UTC()).Scan(&id)
	return id, err
}

// DeleteSession removes a session row (e.g. rollback after a failed access-token issue).
func (r *SessionRepository) DeleteSession(ctx context.Context, id uuid.UUID) error {
	_, err := r.DB.ExecContext(ctx, `DELETE FROM auth_sessions WHERE id = $1`, id)
	return err
}

// RotationResult is returned after a successful refresh.
type RotationResult struct {
	UserID       uuid.UUID
	Provider     string
	SessionID    uuid.UUID
	RefreshToken string
}

// RotateRefreshToken validates the incoming refresh token and atomically replaces it with a new one.
// Reusing an already-rotated token (a sign the token was stolen) revokes the whole chain via ErrRefreshReused.
func (r *SessionRepository) RotateRefreshToken(ctx context.Context, incomingRawToken string, refreshSessionTTL time.Duration) (*RotationResult, error) {
	incomingHash := HashRefreshToken(incomingRawToken)

	tx, err := r.DB.BeginTx(ctx, nil)
	if err != nil {
		return nil, err
	}
	defer func() { _ = tx.Rollback() }()

	row := tx.QueryRowContext(ctx, `
		SELECT id, user_id, provider, expires_at, revoked_at, replaced_by_session_id
		FROM auth_sessions
		WHERE refresh_token_hash = $1
		FOR UPDATE
	`, incomingHash)

	var (
		id, userID uuid.UUID
		provider   string
		expiresAt  time.Time
		revokedAt  sql.NullTime
		replacedBy sql.NullString
	)
	if err := row.Scan(&id, &userID, &provider, &expiresAt, &revokedAt, &replacedBy); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, ErrRefreshInvalid
		}
		return nil, err
	}

	now := time.Now().UTC()
	if revokedAt.Valid {
		if replacedBy.Valid && replacedBy.String != "" {
			return nil, ErrRefreshReused
		}
		return nil, ErrRefreshRevoked
	}
	if !expiresAt.After(now) {
		return nil, ErrRefreshExpired
	}

	newRaw, newHash, err := GenerateRefreshToken()
	if err != nil {
		return nil, err
	}
	newExpires := now.Add(refreshSessionTTL)

	var newID uuid.UUID
	err = tx.QueryRowContext(ctx, `
		INSERT INTO auth_sessions (user_id, provider, refresh_token_hash, expires_at)
		VALUES ($1, $2, $3, $4)
		RETURNING id
	`, userID, provider, newHash, newExpires).Scan(&newID)
	if err != nil {
		return nil, err
	}

	_, err = tx.ExecContext(ctx, `
		UPDATE auth_sessions SET revoked_at = $2, revoke_reason = $3, replaced_by_session_id = $4
		WHERE id = $1
	`, id, now, revokeReasonRotated, newID)
	if err != nil {
		return nil, err
	}

	if err := tx.Commit(); err != nil {
		return nil, err
	}
	return &RotationResult{UserID: userID, Provider: provider, SessionID: newID, RefreshToken: newRaw}, nil
}

// RevokeSession marks a session revoked (logout). Missing/already-revoked/wrong-user rows are a no-op.
func (r *SessionRepository) RevokeSession(ctx context.Context, userID, sessionID uuid.UUID) error {
	_, err := r.DB.ExecContext(ctx, `
		UPDATE auth_sessions SET revoked_at = now(), revoke_reason = $3
		WHERE id = $1 AND user_id = $2 AND revoked_at IS NULL
	`, sessionID, userID, revokeReasonLogout)
	return err
}
