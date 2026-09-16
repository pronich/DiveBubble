package auth

import (
	"context"
	"database/sql"
	"errors"

	"github.com/google/uuid"
)

var ErrIdentityNotFound = errors.New("no account found for that email")
var ErrIdentityAmbiguous = errors.New("more than one account matches that email — type more of it")

type IdentityRepository struct {
	DB *sql.DB
}

func NewIdentityRepository(db *sql.DB) *IdentityRepository {
	return &IdentityRepository{DB: db}
}

// FindUserIDByEmail backs the dive-center "add staff by email" flow with a deliberately narrow prefix match (not substring or name search) so it can't work as a general user directory, and treats a multi-match as ambiguous rather than guessing.
func (r *IdentityRepository) FindUserIDByEmail(ctx context.Context, email string) (uuid.UUID, error) {
	rows, err := r.DB.QueryContext(ctx, `
		SELECT user_id FROM auth_identities WHERE provider_email ILIKE $1 || '%' LIMIT 2
	`, email)
	if err != nil {
		return uuid.Nil, err
	}
	defer rows.Close()

	var ids []uuid.UUID
	for rows.Next() {
		var id uuid.UUID
		if err := rows.Scan(&id); err != nil {
			return uuid.Nil, err
		}
		ids = append(ids, id)
	}
	if err := rows.Err(); err != nil {
		return uuid.Nil, err
	}

	switch len(ids) {
	case 0:
		return uuid.Nil, ErrIdentityNotFound
	case 1:
		return ids[0], nil
	default:
		return uuid.Nil, ErrIdentityAmbiguous
	}
}

// LoginOrRegister resolves the internal user id for a (provider, providerUserID) identity, creating both the user and the identity link (seeding displayName/avatarURL only on that first creation, never overwriting later) on first sign-in, and links onto an existing account under a different provider sharing this email rather than creating a disconnected new one; isNewUser tells the caller whether to send a brand-new user to Edit Profile.
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

	// Apple only returns an email on the diver's first-ever authorization; a repeat sign-in with no email doesn't need linking since it already matched the provider+providerUserID check above.
	if email != "" {
		var existingUserID uuid.UUID
		err = tx.QueryRowContext(ctx, `
			SELECT user_id FROM auth_identities WHERE provider_email = $1 LIMIT 1
		`, email).Scan(&existingUserID)
		switch {
		case err == nil:
			if _, err := tx.ExecContext(ctx, `
				INSERT INTO auth_identities (user_id, provider, provider_user_id, provider_email)
				VALUES ($1, $2, $3, $4)
			`, existingUserID, provider, providerUserID, email); err != nil {
				return uuid.Nil, false, err
			}
			if err := tx.Commit(); err != nil {
				return uuid.Nil, false, err
			}
			return existingUserID, false, nil
		case !errors.Is(err, sql.ErrNoRows):
			return uuid.Nil, false, err
		}
	}

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

// GetAppleRefreshToken returns the Apple refresh token stored for this user's "apple" identity, used at account-deletion time to revoke it; ok is false if there's no "apple" identity or none was ever captured.
func (r *IdentityRepository) GetAppleRefreshToken(ctx context.Context, userID uuid.UUID) (token string, ok bool, err error) {
	var raw sql.NullString
	err = r.DB.QueryRowContext(ctx, `
		SELECT apple_refresh_token FROM auth_identities WHERE user_id = $1 AND provider = 'apple'
	`, userID).Scan(&raw)
	if errors.Is(err, sql.ErrNoRows) {
		return "", false, nil
	}
	if err != nil {
		return "", false, err
	}
	if !raw.Valid || raw.String == "" {
		return "", false, nil
	}
	return raw.String, true, nil
}

// SetAppleRefreshToken overwrites the stored Apple refresh token on every sign-in, since Apple issues a fresh one each time and an earlier one may have been invalidated; a no-op if the user has no "apple" identity row.
func (r *IdentityRepository) SetAppleRefreshToken(ctx context.Context, userID uuid.UUID, refreshToken string) error {
	_, err := r.DB.ExecContext(ctx, `
		UPDATE auth_identities SET apple_refresh_token = $1 WHERE user_id = $2 AND provider = 'apple'
	`, refreshToken, userID)
	return err
}

// LoginOrRegisterByEmail mirrors LoginOrRegister for the passwordless "email" provider: it checks for an existing "email" identity first, then links onto any other provider's identity sharing this provider_email so a diver who separately verifies a code for an address they already signed up with elsewhere lands on the same account, and only creates a new account if neither matches.
func (r *IdentityRepository) LoginOrRegisterByEmail(ctx context.Context, normalizedEmail string) (userID uuid.UUID, isNewUser bool, err error) {
	err = r.DB.QueryRowContext(ctx, `
		SELECT user_id FROM auth_identities WHERE provider = 'email' AND provider_user_id = $1
	`, normalizedEmail).Scan(&userID)
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

	var existingUserID uuid.UUID
	err = tx.QueryRowContext(ctx, `
		SELECT user_id FROM auth_identities WHERE provider_email = $1 LIMIT 1
	`, normalizedEmail).Scan(&existingUserID)
	switch {
	case err == nil:
		if _, err := tx.ExecContext(ctx, `
			INSERT INTO auth_identities (user_id, provider, provider_user_id, provider_email)
			VALUES ($1, 'email', $2, $2)
		`, existingUserID, normalizedEmail); err != nil {
			return uuid.Nil, false, err
		}
		if err := tx.Commit(); err != nil {
			return uuid.Nil, false, err
		}
		return existingUserID, false, nil
	case errors.Is(err, sql.ErrNoRows):
		newUserID := uuid.New()
		if _, err := tx.ExecContext(ctx, `INSERT INTO users (id) VALUES ($1)`, newUserID); err != nil {
			return uuid.Nil, false, err
		}
		if _, err := tx.ExecContext(ctx, `
			INSERT INTO auth_identities (user_id, provider, provider_user_id, provider_email)
			VALUES ($1, 'email', $2, $2)
		`, newUserID, normalizedEmail); err != nil {
			return uuid.Nil, false, err
		}
		if err := tx.Commit(); err != nil {
			return uuid.Nil, false, err
		}
		return newUserID, true, nil
	default:
		return uuid.Nil, false, err
	}
}
