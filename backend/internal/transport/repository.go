package transport

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

type CreateParams struct {
	TripID  uuid.UUID
	UserID  uuid.UUID
	Type    OfferType
	Seats   *int
	Details *string
}

func (r *Repository) Create(ctx context.Context, p CreateParams) (Offer, error) {
	var o Offer
	err := r.DB.QueryRowContext(ctx, `
		INSERT INTO trip_transport_offers (trip_id, user_id, type, seats, details)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id, trip_id, user_id, type, seats, details, created_at
	`, p.TripID, p.UserID, p.Type, p.Seats, p.Details).Scan(
		&o.ID, &o.TripID, &o.UserID, &o.Type, &o.Seats, &o.Details, &o.CreatedAt,
	)
	return o, err
}

func (r *Repository) ListByTrip(ctx context.Context, tripID uuid.UUID) ([]Offer, error) {
	rows, err := r.DB.QueryContext(ctx, `
		SELECT id, trip_id, user_id, type, seats, details, created_at
		FROM trip_transport_offers
		WHERE trip_id = $1
		ORDER BY created_at ASC
	`, tripID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	offers := []Offer{}
	for rows.Next() {
		var o Offer
		if err := rows.Scan(&o.ID, &o.TripID, &o.UserID, &o.Type, &o.Seats, &o.Details, &o.CreatedAt); err != nil {
			return nil, err
		}
		offers = append(offers, o)
	}
	return offers, rows.Err()
}
