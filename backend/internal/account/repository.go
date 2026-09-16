package account

import (
	"context"
	"database/sql"
	"errors"

	"github.com/google/uuid"
)

type Repository struct {
	DB *sql.DB
}

func NewRepository(db *sql.DB) *Repository {
	return &Repository{DB: db}
}

// IsOwner reports the platform-level owner flag (distinct from dive_center_members.role) that lets owner accounts see test/demo content hidden from everyone else in Explore.
func (r *Repository) IsOwner(ctx context.Context, userID uuid.UUID) (bool, error) {
	var isOwner bool
	err := r.DB.QueryRowContext(ctx, `SELECT is_owner FROM users WHERE id = $1`, userID).Scan(&isOwner)
	if errors.Is(err, sql.ErrNoRows) {
		return false, nil
	}
	return isOwner, err
}

// DeleteAccount anonymizes the user instead of deleting the row so every FK referencing them stays valid, hard-deletes only auth and private data, cancels their individual trips, and runs it all in one transaction; it knowingly leaves a dive center ownerless if this removes the user's last owner row, since there's no ownership-transfer flow yet.
func (r *Repository) DeleteAccount(ctx context.Context, userID uuid.UUID) error {
	tx, err := r.DB.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback() }()

	if _, err := tx.ExecContext(ctx, `
		UPDATE users SET
			display_name = 'Deleted user',
			avatar_url = NULL,
			location = NULL,
			bio = NULL,
			dive_count = 0,
			certification_level = NULL,
			certification_agency = NULL,
			certification_number = NULL,
			certification_photo_url = NULL,
			certification_verified = false,
			languages = '',
			deleted_at = now()
		WHERE id = $1
	`, userID); err != nil {
		return err
	}

	if _, err := tx.ExecContext(ctx, `DELETE FROM specialty_certifications WHERE user_id = $1`, userID); err != nil {
		return err
	}

	if _, err := tx.ExecContext(ctx, `DELETE FROM gear_ownership WHERE user_id = $1`, userID); err != nil {
		return err
	}

	if _, err := tx.ExecContext(ctx, `DELETE FROM dive_center_members WHERE user_id = $1`, userID); err != nil {
		return err
	}

	if _, err := tx.ExecContext(ctx, `
		UPDATE trips SET booking_status = 'cancelled'
		WHERE creator_user_id = $1 AND dive_center_id IS NULL AND booking_status != 'cancelled'
	`, userID); err != nil {
		return err
	}

	if _, err := tx.ExecContext(ctx, `DELETE FROM auth_sessions WHERE user_id = $1`, userID); err != nil {
		return err
	}

	if _, err := tx.ExecContext(ctx, `DELETE FROM auth_identities WHERE user_id = $1`, userID); err != nil {
		return err
	}

	return tx.Commit()
}
