package trip

import (
	"context"
	"database/sql"
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
)

var ErrNotFound = errors.New("trip not found")

var tripColumnNames = []string{
	"id", "title", "location", "start_time", "created_at", "creator_user_id",
	"end_date", "description", "meeting_point",
	"dive_count_min", "dive_count_max", "depth_min_m", "depth_max_m",
	"min_certification", "booking_code", "max_participants", "booking_status",
}

var tripColumns = strings.Join(tripColumnNames, ", ")

// tripColumnsPrefixed qualifies each column with a table alias, for queries that join other tables.
func tripColumnsPrefixed(alias string) string {
	prefixed := make([]string, len(tripColumnNames))
	for i, c := range tripColumnNames {
		prefixed[i] = alias + "." + c
	}
	return strings.Join(prefixed, ", ")
}

type Repository struct {
	DB *sql.DB
}

func NewRepository(db *sql.DB) *Repository {
	return &Repository{DB: db}
}

func scanTrip(row interface{ Scan(...any) error }) (Trip, error) {
	var t Trip
	err := row.Scan(
		&t.ID, &t.Title, &t.Location, &t.StartTime, &t.CreatedAt, &t.CreatorUserID,
		&t.EndDate, &t.Description, &t.MeetingPoint,
		&t.DiveCountMin, &t.DiveCountMax, &t.DepthMinM, &t.DepthMaxM,
		&t.MinCertification, &t.BookingCode, &t.MaxParticipants, &t.BookingStatus,
	)
	return t, err
}

func (r *Repository) GetByID(ctx context.Context, id uuid.UUID) (Trip, error) {
	t, err := scanTrip(r.DB.QueryRowContext(ctx, `SELECT `+tripColumns+` FROM trips WHERE id = $1`, id))
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return Trip{}, ErrNotFound
		}
		return Trip{}, err
	}
	return t, nil
}

// CreateParams — optional fields are nil pointers when not provided.
type CreateParams struct {
	Title            string
	Location         string
	StartTime        time.Time
	CreatorUserID    uuid.UUID
	EndDate          *time.Time
	Description      *string
	MeetingPoint     *string
	DiveCountMin     *int
	DiveCountMax     *int
	DepthMinM        *int
	DepthMaxM        *int
	MinCertification *string
	BookingCode      *string
	MaxParticipants  *int
}

func (r *Repository) Create(ctx context.Context, p CreateParams) (Trip, error) {
	return scanTrip(r.DB.QueryRowContext(ctx, `
		INSERT INTO trips (
			title, location, start_time, creator_user_id,
			end_date, description, meeting_point,
			dive_count_min, dive_count_max, depth_min_m, depth_max_m,
			min_certification, booking_code, max_participants
		)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
		RETURNING `+tripColumns,
		p.Title, p.Location, p.StartTime, p.CreatorUserID,
		p.EndDate, p.Description, p.MeetingPoint,
		p.DiveCountMin, p.DiveCountMax, p.DepthMinM, p.DepthMaxM,
		p.MinCertification, p.BookingCode, p.MaxParticipants,
	))
}

func (r *Repository) List(ctx context.Context) ([]Trip, error) {
	rows, err := r.DB.QueryContext(ctx, `SELECT `+tripColumns+` FROM trips ORDER BY start_time ASC`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	trips := []Trip{}
	for rows.Next() {
		t, err := scanTrip(rows)
		if err != nil {
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

// ListJoinedByUser orders by joined_at until real "last message" ordering exists.
func (r *Repository) ListJoinedByUser(ctx context.Context, userID uuid.UUID) ([]Trip, error) {
	rows, err := r.DB.QueryContext(ctx, `
		SELECT `+tripColumnsPrefixed("t")+`
		FROM trips t
		JOIN trip_participants tp ON tp.trip_id = t.id
		WHERE tp.user_id = $1
		ORDER BY tp.joined_at DESC
	`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	trips := []Trip{}
	for rows.Next() {
		t, err := scanTrip(rows)
		if err != nil {
			return nil, err
		}
		trips = append(trips, t)
	}
	return trips, rows.Err()
}

func (r *Repository) CountParticipants(ctx context.Context, tripID uuid.UUID) (int, error) {
	var count int
	err := r.DB.QueryRowContext(ctx, `
		SELECT COUNT(*) FROM trip_participants WHERE trip_id = $1
	`, tripID).Scan(&count)
	return count, err
}
