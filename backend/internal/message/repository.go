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

// Create inserts a user-authored message. offerID is nil for the trip's main chat, set for a
// car offer's own chat — trip_id is always populated either way (see migration 000046).
func (r *Repository) Create(ctx context.Context, tripID, userID uuid.UUID, offerID uuid.NullUUID, body string, mentionsDiveCenter bool) (Message, error) {
	var m Message
	err := r.DB.QueryRowContext(ctx, `
		INSERT INTO chat_messages (trip_id, user_id, offer_id, body, mentions_dive_center)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id, trip_id, user_id, body, created_at, mentions_dive_center, kind, offer_id
	`, tripID, userID, offerID, body, mentionsDiveCenter).
		Scan(&m.ID, &m.TripID, &m.UserID, &m.Body, &m.CreatedAt, &m.MentionsDiveCenter, &m.Kind, &m.OfferID)
	return m, err
}

// CreateSystem inserts a message sent by SystemUserID with the given kind (never KindUser).
func (r *Repository) CreateSystem(ctx context.Context, tripID uuid.UUID, offerID uuid.NullUUID, kind, body string) (Message, error) {
	var m Message
	err := r.DB.QueryRowContext(ctx, `
		INSERT INTO chat_messages (trip_id, user_id, offer_id, body, kind)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id, trip_id, user_id, body, created_at, mentions_dive_center, kind, offer_id
	`, tripID, SystemUserID, offerID, body, kind).
		Scan(&m.ID, &m.TripID, &m.UserID, &m.Body, &m.CreatedAt, &m.MentionsDiveCenter, &m.Kind, &m.OfferID)
	return m, err
}

// ExistsByTripAndKind reports whether a message of the given kind has already been sent for
// this trip — used to keep the periodic feedback-prompt scan idempotent.
func (r *Repository) ExistsByTripAndKind(ctx context.Context, tripID uuid.UUID, kind string) (bool, error) {
	var exists bool
	err := r.DB.QueryRowContext(ctx, `
		SELECT EXISTS(SELECT 1 FROM chat_messages WHERE trip_id = $1 AND kind = $2)
	`, tripID, kind).Scan(&exists)
	return exists, err
}

func (r *Repository) GetByID(ctx context.Context, id uuid.UUID) (Message, error) {
	var m Message
	err := r.DB.QueryRowContext(ctx, `
		SELECT id, trip_id, user_id, body, created_at, mentions_dive_center, kind, offer_id
		FROM chat_messages
		WHERE id = $1
	`, id).Scan(&m.ID, &m.TripID, &m.UserID, &m.Body, &m.CreatedAt, &m.MentionsDiveCenter, &m.Kind, &m.OfferID)
	return m, err
}

// ListByTrip returns only the trip's main-chat messages — offer_id IS NULL excludes every car
// offer's own chat, which lives under ListByOffer instead.
func (r *Repository) ListByTrip(ctx context.Context, tripID uuid.UUID) ([]Message, error) {
	rows, err := r.DB.QueryContext(ctx, `
		SELECT id, trip_id, user_id, body, created_at, mentions_dive_center, kind, offer_id
		FROM chat_messages
		WHERE trip_id = $1 AND offer_id IS NULL
		ORDER BY created_at ASC
	`, tripID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanMessages(rows)
}

// ListByOffer returns a single car offer's own chat history.
func (r *Repository) ListByOffer(ctx context.Context, offerID uuid.UUID) ([]Message, error) {
	rows, err := r.DB.QueryContext(ctx, `
		SELECT id, trip_id, user_id, body, created_at, mentions_dive_center, kind, offer_id
		FROM chat_messages
		WHERE offer_id = $1
		ORDER BY created_at ASC
	`, offerID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanMessages(rows)
}

func scanMessages(rows *sql.Rows) ([]Message, error) {
	messages := []Message{}
	for rows.Next() {
		var m Message
		if err := rows.Scan(&m.ID, &m.TripID, &m.UserID, &m.Body, &m.CreatedAt, &m.MentionsDiveCenter, &m.Kind, &m.OfferID); err != nil {
			return nil, err
		}
		messages = append(messages, m)
	}
	return messages, rows.Err()
}
