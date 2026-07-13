package user

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

// GetOrCreate resolves a stub identity — no real auth yet, id comes from the client.
func (r *Repository) GetOrCreate(ctx context.Context, id uuid.UUID) (User, error) {
	var u User
	err := r.DB.QueryRowContext(ctx, `
		INSERT INTO users (id) VALUES ($1)
		ON CONFLICT (id) DO UPDATE SET id = EXCLUDED.id
		RETURNING id, created_at
	`, id).Scan(&u.ID, &u.CreatedAt)
	return u, err
}
