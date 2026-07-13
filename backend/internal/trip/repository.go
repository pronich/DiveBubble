package trip

import (
	"context"
	"database/sql"
	"errors"
	"time"

	"github.com/google/uuid"
)

var ErrNotFound = errors.New("trip not found")

type Repository struct {
	DB *sql.DB
}

func NewRepository(db *sql.DB) *Repository {
	return &Repository{DB: db}
}

func (r *Repository) GetByID(ctx context.Context, id uuid.UUID) (Trip, error) {
	var t Trip
	err := r.DB.QueryRowContext(ctx, `
		SELECT id, title, location, start_time, created_at
		FROM trips
		WHERE id = $1
	`, id).Scan(&t.ID, &t.Title, &t.Location, &t.StartTime, &t.CreatedAt)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return Trip{}, ErrNotFound
		}
		return Trip{}, err
	}
	return t, nil
}

func (r *Repository) Create(ctx context.Context, title, location string, startTime time.Time) (Trip, error) {
	var t Trip
	err := r.DB.QueryRowContext(ctx, `
		INSERT INTO trips (title, location, start_time)
		VALUES ($1, $2, $3)
		RETURNING id, title, location, start_time, created_at
	`, title, location, startTime).Scan(
		&t.ID,
		&t.Title,
		&t.Location,
		&t.StartTime,
		&t.CreatedAt,
	)
	return t, err
}

func (r *Repository) List(ctx context.Context) ([]Trip, error) {
	rows, err := r.DB.QueryContext(ctx, `
		SELECT id, title, location, start_time, created_at
		FROM trips
		ORDER BY start_time ASC
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	trips := []Trip{}
	for rows.Next() {
		var t Trip
		if err := rows.Scan(&t.ID, &t.Title, &t.Location, &t.StartTime, &t.CreatedAt); err != nil {
			return nil, err
		}
		trips = append(trips, t)
	}
	return trips, rows.Err()
}

// Join is idempotent — re-joining an already-joined trip is a no-op.
func (r *Repository) Join(ctx context.Context, tripID, userID uuid.UUID) error {
	_, err := r.DB.ExecContext(ctx, `
		INSERT INTO trip_participants (trip_id, user_id)
		VALUES ($1, $2)
		ON CONFLICT (trip_id, user_id) DO NOTHING
	`, tripID, userID)
	return err
}

func (r *Repository) IsJoined(ctx context.Context, tripID, userID uuid.UUID) (bool, error) {
	var exists bool
	err := r.DB.QueryRowContext(ctx, `
		SELECT EXISTS(SELECT 1 FROM trip_participants WHERE trip_id = $1 AND user_id = $2)
	`, tripID, userID).Scan(&exists)
	return exists, err
}
