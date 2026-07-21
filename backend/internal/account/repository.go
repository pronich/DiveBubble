package account

import (
	"context"
	"database/sql"

	"github.com/google/uuid"
)

type Repository struct {
	DB *sql.DB
}

func NewRepository(db *sql.DB) *Repository {
	return &Repository{DB: db}
}

// DeleteAccount anonymizes a user rather than deleting the row — every existing FK
// (trip_participants.user_id, chat_messages.user_id, trips.creator_user_id, etc.) stays
// valid with zero cascade complexity, and other participants keep seeing "Deleted user" in
// their trip/chat history instead of a broken reference. Only auth records (identities,
// sessions) and genuinely private data (specialties, gear, dive-center memberships) are hard
// deleted — those have no other participant relying on them. Individual trips this user
// organized are cancelled, since there's no one left to act as their organizer; dive-center
// trips are untouched (other staff remain valid organizers). Everything runs in one
// transaction — a partial anonymization would be worse than none.
//
// Known accepted gap: if step 4 removes this user's last dive_center_members "owner" row,
// nothing here prevents or repairs the resulting ownerless center — there's no
// ownership-transfer flow yet. Not blocking deletion over it for v1.
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
