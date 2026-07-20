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

// FindUserIDByEmail backs the dive-center "add staff by email" flow — a deliberately narrow
// prefix-match lookup (not full substring, and no name search) so it still can't be used as
// a general user directory: the caller has to already know the start of the real email, just
// not necessarily the exact "@domain" suffix (e.g. "n.g.pronichev" matches
// "n.g.pronichev@gmail.com"). If a prefix matches more than one account, that's treated as
// ambiguous rather than guessing — the caller types more of the email instead.
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

// LoginOrRegisterByEmail is LoginOrRegister's counterpart for the passwordless "email"
// provider, which needs one extra step the others don't: Google/Apple sub claims are
// already scoped per-provider, so two different providers never collide, but a diver who
// signed up via Google and *separately* verifies a passwordless code for that same address
// must land on their existing account, not a disconnected new one. Order of checks: (1) an
// "email" identity for this address already exists → that account; (2) some *other*
// provider's identity shares this provider_email → link a new "email" identity onto that
// same user_id rather than creating a second account for the same person; (3) neither →
// create fresh, same as LoginOrRegister.
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
