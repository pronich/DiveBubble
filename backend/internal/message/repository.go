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

// Create inserts a user-authored message. scope is the zero value for the trip's main chat,
// or set for a car offer's or buddy group's own chat — trip_id is always populated either way
// (see migrations 000046/000048).
func (r *Repository) Create(ctx context.Context, tripID, userID uuid.UUID, scope Scope, body string, mentionsDiveCenter bool) (Message, error) {
	var m Message
	err := r.DB.QueryRowContext(ctx, `
		INSERT INTO chat_messages (trip_id, user_id, offer_id, buddy_request_id, body, mentions_dive_center)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING id, trip_id, user_id, body, created_at, mentions_dive_center, kind, offer_id, buddy_request_id
	`, tripID, userID, scope.OfferID, scope.BuddyRequestID, body, mentionsDiveCenter).
		Scan(&m.ID, &m.TripID, &m.UserID, &m.Body, &m.CreatedAt, &m.MentionsDiveCenter, &m.Kind, &m.OfferID, &m.BuddyRequestID)
	return m, err
}

// CreateSystem inserts a message sent by SystemUserID with the given kind (never KindUser).
func (r *Repository) CreateSystem(ctx context.Context, tripID uuid.UUID, scope Scope, kind, body string) (Message, error) {
	var m Message
	err := r.DB.QueryRowContext(ctx, `
		INSERT INTO chat_messages (trip_id, user_id, offer_id, buddy_request_id, body, kind)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING id, trip_id, user_id, body, created_at, mentions_dive_center, kind, offer_id, buddy_request_id
	`, tripID, SystemUserID, scope.OfferID, scope.BuddyRequestID, body, kind).
		Scan(&m.ID, &m.TripID, &m.UserID, &m.Body, &m.CreatedAt, &m.MentionsDiveCenter, &m.Kind, &m.OfferID, &m.BuddyRequestID)
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
		SELECT id, trip_id, user_id, body, created_at, mentions_dive_center, kind, offer_id, buddy_request_id
		FROM chat_messages
		WHERE id = $1
	`, id).Scan(&m.ID, &m.TripID, &m.UserID, &m.Body, &m.CreatedAt, &m.MentionsDiveCenter, &m.Kind, &m.OfferID, &m.BuddyRequestID)
	return m, err
}

// ListByTrip returns only the trip's main-chat messages — excludes every car offer's and
// buddy group's own chat, which live under ListByOffer/ListByBuddyRequest instead.
func (r *Repository) ListByTrip(ctx context.Context, tripID uuid.UUID) ([]Message, error) {
	rows, err := r.DB.QueryContext(ctx, `
		SELECT id, trip_id, user_id, body, created_at, mentions_dive_center, kind, offer_id, buddy_request_id
		FROM chat_messages
		WHERE trip_id = $1 AND offer_id IS NULL AND buddy_request_id IS NULL
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
		SELECT id, trip_id, user_id, body, created_at, mentions_dive_center, kind, offer_id, buddy_request_id
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

// ListByBuddyRequest returns a single buddy group's own chat history.
func (r *Repository) ListByBuddyRequest(ctx context.Context, requestID uuid.UUID) ([]Message, error) {
	rows, err := r.DB.QueryContext(ctx, `
		SELECT id, trip_id, user_id, body, created_at, mentions_dive_center, kind, offer_id, buddy_request_id
		FROM chat_messages
		WHERE buddy_request_id = $1
		ORDER BY created_at ASC
	`, requestID)
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
		if err := rows.Scan(&m.ID, &m.TripID, &m.UserID, &m.Body, &m.CreatedAt, &m.MentionsDiveCenter, &m.Kind, &m.OfferID, &m.BuddyRequestID); err != nil {
			return nil, err
		}
		messages = append(messages, m)
	}
	return messages, rows.Err()
}
