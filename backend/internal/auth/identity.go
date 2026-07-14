package auth

import (
	"context"
	"database/sql"
	"errors"

	"github.com/google/uuid"
)

type IdentityRepository struct {
	DB *sql.DB
}

func NewIdentityRepository(db *sql.DB) *IdentityRepository {
	return &IdentityRepository{DB: db}
}

// LoginOrRegister resolves the internal user id for a (provider, providerUserID) identity,
// creating both the user and the identity link on first sign-in.
func (r *IdentityRepository) LoginOrRegister(ctx context.Context, provider, providerUserID, email string) (uuid.UUID, error) {
	var userID uuid.UUID
	err := r.DB.QueryRowContext(ctx, `
		SELECT user_id FROM auth_identities WHERE provider = $1 AND provider_user_id = $2
	`, provider, providerUserID).Scan(&userID)
	if err == nil {
		return userID, nil
	}
	if !errors.Is(err, sql.ErrNoRows) {
		return uuid.Nil, err
	}

	tx, err := r.DB.BeginTx(ctx, nil)
	if err != nil {
		return uuid.Nil, err
	}
	defer func() { _ = tx.Rollback() }()

	userID = uuid.New()
	if _, err := tx.ExecContext(ctx, `INSERT INTO users (id) VALUES ($1)`, userID); err != nil {
		return uuid.Nil, err
	}
	if _, err := tx.ExecContext(ctx, `
		INSERT INTO auth_identities (user_id, provider, provider_user_id, provider_email)
		VALUES ($1, $2, $3, NULLIF($4, ''))
	`, userID, provider, providerUserID, email); err != nil {
		return uuid.Nil, err
	}

	if err := tx.Commit(); err != nil {
		return uuid.Nil, err
	}
	return userID, nil
}
