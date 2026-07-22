package message

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

func (r *Repository) Create(ctx context.Context, tripID, userID uuid.UUID, body string, mentionsDiveCenter bool) (Message, error) {
	var m Message
	err := r.DB.QueryRowContext(ctx, `
		INSERT INTO chat_messages (trip_id, user_id, body, mentions_dive_center)
		VALUES ($1, $2, $3, $4)
		RETURNING id, trip_id, user_id, body, created_at, mentions_dive_center
	`, tripID, userID, body, mentionsDiveCenter).Scan(&m.ID, &m.TripID, &m.UserID, &m.Body, &m.CreatedAt, &m.MentionsDiveCenter)
	return m, err
}

func (r *Repository) GetByID(ctx context.Context, id uuid.UUID) (Message, error) {
	var m Message
	err := r.DB.QueryRowContext(ctx, `
		SELECT id, trip_id, user_id, body, created_at, mentions_dive_center
		FROM chat_messages
		WHERE id = $1
	`, id).Scan(&m.ID, &m.TripID, &m.UserID, &m.Body, &m.CreatedAt, &m.MentionsDiveCenter)
	return m, err
}

func (r *Repository) ListByTrip(ctx context.Context, tripID uuid.UUID) ([]Message, error) {
	rows, err := r.DB.QueryContext(ctx, `
		SELECT id, trip_id, user_id, body, created_at, mentions_dive_center
		FROM chat_messages
		WHERE trip_id = $1
		ORDER BY created_at ASC
	`, tripID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	messages := []Message{}
	for rows.Next() {
		var m Message
		if err := rows.Scan(&m.ID, &m.TripID, &m.UserID, &m.Body, &m.CreatedAt, &m.MentionsDiveCenter); err != nil {
			return nil, err
		}
		messages = append(messages, m)
	}
	return messages, rows.Err()
}
