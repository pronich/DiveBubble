package trip

import (
	"context"
	"database/sql"
	"time"
)

type Repository struct {
	DB *sql.DB
}

func NewRepository(db *sql.DB) *Repository {
	return &Repository{DB: db}
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
