package waitlist

import (
	"context"
	"database/sql"
)

type Repository struct {
	DB *sql.DB
}

func NewRepository(db *sql.DB) *Repository {
	return &Repository{DB: db}
}

// Add is idempotent — signing up twice with the same email is a no-op, not an error, since
// the caller (the public marketing site) has no account/session to tell "you already did
// this" client-side.
func (r *Repository) Add(ctx context.Context, email string) error {
	_, err := r.DB.ExecContext(ctx, `
		INSERT INTO waitlist_signups (email) VALUES ($1)
		ON CONFLICT (email) DO NOTHING
	`, email)
	return err
}
