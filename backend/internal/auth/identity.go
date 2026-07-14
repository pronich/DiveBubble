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
// creating both the user and the identity link on first sign-in. displayName/avatarURL (from
// the provider's profile, e.g. Google's name/picture claims) only seed the user row on that
// first creation — later logins never overwrite whatever the user has since set themselves.
// isNewUser tells the caller whether this was the account's very first sign-in, so the client
// can drop a brand-new user straight into Edit Profile instead of an empty screen.
func (r *IdentityRepository) LoginOrRegister(ctx context.Context, provider, providerUserID, email, displayName, avatarURL string) (userID uuid.UUID, isNewUser bool, err error) {
	err = r.DB.QueryRowContext(ctx, `
		SELECT user_id FROM auth_identities WHERE provider = $1 AND provider_user_id = $2
	`, provider, providerUserID).Scan(&userID)
	if err == nil {
		return userID, false, nil
	}
	if !errors.Is(err, sql.ErrNoRows) {
		return uuid.Nil, false, err
	}

	tx, err := r.DB.BeginTx(ctx, nil)
	if err != nil {
		return uuid.Nil, false, err
	}
	defer func() { _ = tx.Rollback() }()

	userID = uuid.New()
	if _, err := tx.ExecContext(ctx, `
		INSERT INTO users (id, display_name, avatar_url) VALUES ($1, NULLIF($2, ''), NULLIF($3, ''))
	`, userID, displayName, avatarURL); err != nil {
		return uuid.Nil, false, err
	}
	if _, err := tx.ExecContext(ctx, `
		INSERT INTO auth_identities (user_id, provider, provider_user_id, provider_email)
		VALUES ($1, $2, $3, NULLIF($4, ''))
	`, userID, provider, providerUserID, email); err != nil {
		return uuid.Nil, false, err
	}

	if err := tx.Commit(); err != nil {
		return uuid.Nil, false, err
	}
	return userID, true, nil
}
