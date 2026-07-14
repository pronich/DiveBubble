package transport

import (
	"context"
	"database/sql"
	"errors"

	"github.com/google/uuid"
)

var ErrNotFound = errors.New("transport offer not found")

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

// ListByTrip computes JoinedCount/Joined in one query rather than N+1 per-offer lookups.
func (r *Repository) ListByTrip(ctx context.Context, tripID, callerUserID uuid.UUID) ([]Offer, error) {
	rows, err := r.DB.QueryContext(ctx, `
		SELECT o.id, o.trip_id, o.user_id, o.type, o.seats, o.details, o.created_at,
		       COALESCE(j.joined_count, 0),
		       EXISTS(SELECT 1 FROM transport_offer_joins WHERE offer_id = o.id AND user_id = $2)
		FROM trip_transport_offers o
		LEFT JOIN (
			SELECT offer_id, COUNT(*) AS joined_count
			FROM transport_offer_joins
			GROUP BY offer_id
		) j ON j.offer_id = o.id
		WHERE o.trip_id = $1
		ORDER BY o.created_at ASC
	`, tripID, callerUserID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	offers := []Offer{}
	for rows.Next() {
		var o Offer
		if err := rows.Scan(
			&o.ID, &o.TripID, &o.UserID, &o.Type, &o.Seats, &o.Details, &o.CreatedAt,
			&o.JoinedCount, &o.Joined,
		); err != nil {
			return nil, err
		}
		offers = append(offers, o)
	}
	return offers, rows.Err()
}

func (r *Repository) GetByID(ctx context.Context, id uuid.UUID) (Offer, error) {
	var o Offer
	err := r.DB.QueryRowContext(ctx, `
		SELECT id, trip_id, user_id, type, seats, details, created_at
		FROM trip_transport_offers
		WHERE id = $1
	`, id).Scan(&o.ID, &o.TripID, &o.UserID, &o.Type, &o.Seats, &o.Details, &o.CreatedAt)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return Offer{}, ErrNotFound
		}
		return Offer{}, err
	}
	return o, nil
}

func (r *Repository) CountJoins(ctx context.Context, offerID uuid.UUID) (int, error) {
	var count int
	err := r.DB.QueryRowContext(ctx, `
		SELECT COUNT(*) FROM transport_offer_joins WHERE offer_id = $1
	`, offerID).Scan(&count)
	return count, err
}

func (r *Repository) IsJoined(ctx context.Context, offerID, userID uuid.UUID) (bool, error) {
	var exists bool
	err := r.DB.QueryRowContext(ctx, `
		SELECT EXISTS(SELECT 1 FROM transport_offer_joins WHERE offer_id = $1 AND user_id = $2)
	`, offerID, userID).Scan(&exists)
	return exists, err
}

func (r *Repository) ListJoins(ctx context.Context, offerID uuid.UUID) ([]uuid.UUID, error) {
	rows, err := r.DB.QueryContext(ctx, `
		SELECT user_id FROM transport_offer_joins WHERE offer_id = $1 ORDER BY joined_at ASC
	`, offerID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	userIDs := []uuid.UUID{}
	for rows.Next() {
		var id uuid.UUID
		if err := rows.Scan(&id); err != nil {
			return nil, err
		}
		userIDs = append(userIDs, id)
	}
	return userIDs, rows.Err()
}

// Join is idempotent — joining an already-joined offer is a no-op.
func (r *Repository) Join(ctx context.Context, offerID, userID uuid.UUID) error {
	_, err := r.DB.ExecContext(ctx, `
		INSERT INTO transport_offer_joins (offer_id, user_id)
		VALUES ($1, $2)
		ON CONFLICT (offer_id, user_id) DO NOTHING
	`, offerID, userID)
	return err
}
