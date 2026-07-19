package push

import (
	"context"
	"database/sql"
	"fmt"
	"strings"

	"github.com/google/uuid"
)

type Repository struct {
	db *sql.DB
}

func NewRepository(db *sql.DB) *Repository {
	return &Repository{db: db}
}

// Upsert associates a device token with a user. Re-registering an already-known token
// (e.g. a different account signing into the same device) reassigns it rather than
// leaving a stale row pointed at the old user.
func (r *Repository) Upsert(ctx context.Context, userID uuid.UUID, platform, token string) error {
	_, err := r.db.ExecContext(ctx, `
		INSERT INTO push_tokens (token, user_id, platform)
		VALUES ($1, $2, $3)
		ON CONFLICT (token) DO UPDATE SET user_id = $2, platform = $3, updated_at = now()
	`, token, userID, platform)
	return err
}

// ListTokensForUsers returns every registered device token across the given users — a
// user with multiple devices signed in gets a push to each. Empty input is a no-op.
func (r *Repository) ListTokensForUsers(ctx context.Context, userIDs []uuid.UUID) ([]string, error) {
	if len(userIDs) == 0 {
		return nil, nil
	}
	placeholders := make([]string, len(userIDs))
	args := make([]any, len(userIDs))
	for i, id := range userIDs {
		placeholders[i] = fmt.Sprintf("$%d", i+1)
		args[i] = id
	}
	query := "SELECT token FROM push_tokens WHERE user_id IN (" + strings.Join(placeholders, ", ") + ")"

	rows, err := r.db.QueryContext(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var tokens []string
	for rows.Next() {
		var token string
		if err := rows.Scan(&token); err != nil {
			return nil, err
		}
		tokens = append(tokens, token)
	}
	return tokens, rows.Err()
}

// DeleteTokens removes tokens FCM reports as no longer registered (app uninstalled, token
// rotated) — called best-effort after every send so the table doesn't accumulate dead rows.
func (r *Repository) DeleteTokens(ctx context.Context, tokens []string) error {
	if len(tokens) == 0 {
		return nil
	}
	placeholders := make([]string, len(tokens))
	args := make([]any, len(tokens))
	for i, t := range tokens {
		placeholders[i] = fmt.Sprintf("$%d", i+1)
		args[i] = t
	}
	query := "DELETE FROM push_tokens WHERE token IN (" + strings.Join(placeholders, ", ") + ")"
	_, err := r.db.ExecContext(ctx, query, args...)
	return err
}
