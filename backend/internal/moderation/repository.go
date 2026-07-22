package moderation

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

func (r *Repository) CreateReport(ctx context.Context, reporterID, messageID, tripID uuid.UUID, reason, details string) (Report, error) {
	var rep Report
	err := r.DB.QueryRowContext(ctx, `
		INSERT INTO content_reports (reporter_user_id, message_id, trip_id, reason, details)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id, reporter_user_id, message_id, trip_id, reason, COALESCE(details, ''), created_at
	`, reporterID, messageID, tripID, reason, details).
		Scan(&rep.ID, &rep.ReporterUserID, &rep.MessageID, &rep.TripID, &rep.Reason, &rep.Details, &rep.CreatedAt)
	return rep, err
}

func (r *Repository) CreateBlock(ctx context.Context, blockerID, blockedID uuid.UUID) error {
	_, err := r.DB.ExecContext(ctx, `
		INSERT INTO user_blocks (blocker_user_id, blocked_user_id)
		VALUES ($1, $2)
		ON CONFLICT (blocker_user_id, blocked_user_id) DO NOTHING
	`, blockerID, blockedID)
	return err
}

func (r *Repository) DeleteBlock(ctx context.Context, blockerID, blockedID uuid.UUID) error {
	_, err := r.DB.ExecContext(ctx, `
		DELETE FROM user_blocks WHERE blocker_user_id = $1 AND blocked_user_id = $2
	`, blockerID, blockedID)
	return err
}

func (r *Repository) ListBlockedUserIDs(ctx context.Context, blockerID uuid.UUID) ([]uuid.UUID, error) {
	rows, err := r.DB.QueryContext(ctx, `
		SELECT blocked_user_id FROM user_blocks WHERE blocker_user_id = $1
	`, blockerID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	ids := []uuid.UUID{}
	for rows.Next() {
		var id uuid.UUID
		if err := rows.Scan(&id); err != nil {
			return nil, err
		}
		ids = append(ids, id)
	}
	return ids, rows.Err()
}
