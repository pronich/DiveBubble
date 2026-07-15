package gear

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

func (r *Repository) ListByUser(ctx context.Context, userID uuid.UUID) ([]Ownership, error) {
	rows, err := r.DB.QueryContext(ctx, `
		SELECT user_id, item_key, status, updated_at
		FROM gear_ownership
		WHERE user_id = $1
	`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := []Ownership{}
	for rows.Next() {
		var o Ownership
		if err := rows.Scan(&o.UserID, &o.ItemKey, &o.Status, &o.UpdatedAt); err != nil {
			return nil, err
		}
		items = append(items, o)
	}
	return items, rows.Err()
}

func (r *Repository) Upsert(ctx context.Context, userID uuid.UUID, itemKey, status string) (Ownership, error) {
	var o Ownership
	err := r.DB.QueryRowContext(ctx, `
		INSERT INTO gear_ownership (user_id, item_key, status, updated_at)
		VALUES ($1, $2, $3, now())
		ON CONFLICT (user_id, item_key) DO UPDATE SET status = $3, updated_at = now()
		RETURNING user_id, item_key, status, updated_at
	`, userID, itemKey, status).Scan(&o.UserID, &o.ItemKey, &o.Status, &o.UpdatedAt)
	return o, err
}

// Delete returns false (no error) if no row matched — either it didn't exist or belonged to another user.
func (r *Repository) Delete(ctx context.Context, userID uuid.UUID, itemKey string) (bool, error) {
	res, err := r.DB.ExecContext(ctx, `
		DELETE FROM gear_ownership WHERE user_id = $1 AND item_key = $2
	`, userID, itemKey)
	if err != nil {
		return false, err
	}
	n, err := res.RowsAffected()
	return n > 0, err
}
