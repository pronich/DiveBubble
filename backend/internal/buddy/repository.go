package buddy

import (
	"context"
	"database/sql"
	"errors"

	"github.com/google/uuid"
)

var ErrNotFound = errors.New("buddy request not found")

type Repository struct {
	DB *sql.DB
}

func NewRepository(db *sql.DB) *Repository {
	return &Repository{DB: db}
}

type CreateParams struct {
	TripID uuid.UUID
	UserID uuid.UUID
}

func (r *Repository) Create(ctx context.Context, p CreateParams) (Request, error) {
	var req Request
	err := r.DB.QueryRowContext(ctx, `
		INSERT INTO trip_buddy_requests (trip_id, user_id)
		VALUES ($1, $2)
		RETURNING id, trip_id, user_id, created_at
	`, p.TripID, p.UserID).Scan(&req.ID, &req.TripID, &req.UserID, &req.CreatedAt)
	return req, err
}

// ListByTrip computes JoinedCount/Joined in one query rather than N+1 per-request lookups.
func (r *Repository) ListByTrip(ctx context.Context, tripID, callerUserID uuid.UUID) ([]Request, error) {
	rows, err := r.DB.QueryContext(ctx, `
		SELECT b.id, b.trip_id, b.user_id, b.created_at,
		       COALESCE(j.joined_count, 0),
		       EXISTS(SELECT 1 FROM buddy_request_joins WHERE request_id = b.id AND user_id = $2)
		FROM trip_buddy_requests b
		LEFT JOIN (
			SELECT request_id, COUNT(*) AS joined_count
			FROM buddy_request_joins
			GROUP BY request_id
		) j ON j.request_id = b.id
		WHERE b.trip_id = $1
		ORDER BY b.created_at ASC
	`, tripID, callerUserID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	requests := []Request{}
	for rows.Next() {
		var req Request
		if err := rows.Scan(&req.ID, &req.TripID, &req.UserID, &req.CreatedAt, &req.JoinedCount, &req.Joined); err != nil {
			return nil, err
		}
		requests = append(requests, req)
	}
	return requests, rows.Err()
}

func (r *Repository) GetByID(ctx context.Context, id uuid.UUID) (Request, error) {
	var req Request
	err := r.DB.QueryRowContext(ctx, `
		SELECT id, trip_id, user_id, created_at
		FROM trip_buddy_requests
		WHERE id = $1
	`, id).Scan(&req.ID, &req.TripID, &req.UserID, &req.CreatedAt)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return Request{}, ErrNotFound
		}
		return Request{}, err
	}
	return req, nil
}

func (r *Repository) CountJoins(ctx context.Context, requestID uuid.UUID) (int, error) {
	var count int
	err := r.DB.QueryRowContext(ctx, `
		SELECT COUNT(*) FROM buddy_request_joins WHERE request_id = $1
	`, requestID).Scan(&count)
	return count, err
}

func (r *Repository) IsJoined(ctx context.Context, requestID, userID uuid.UUID) (bool, error) {
	var exists bool
	err := r.DB.QueryRowContext(ctx, `
		SELECT EXISTS(SELECT 1 FROM buddy_request_joins WHERE request_id = $1 AND user_id = $2)
	`, requestID, userID).Scan(&exists)
	return exists, err
}

// HasAnyJoinInTrip checks across every request on the trip, not just one — a diver only needs one buddy group.
func (r *Repository) HasAnyJoinInTrip(ctx context.Context, tripID, userID uuid.UUID) (bool, error) {
	var exists bool
	err := r.DB.QueryRowContext(ctx, `
		SELECT EXISTS(
			SELECT 1 FROM buddy_request_joins brj
			JOIN trip_buddy_requests b ON b.id = brj.request_id
			WHERE b.trip_id = $1 AND brj.user_id = $2
		)
	`, tripID, userID).Scan(&exists)
	return exists, err
}

func (r *Repository) ListJoins(ctx context.Context, requestID uuid.UUID) ([]uuid.UUID, error) {
	rows, err := r.DB.QueryContext(ctx, `
		SELECT user_id FROM buddy_request_joins WHERE request_id = $1 ORDER BY joined_at ASC
	`, requestID)
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

// Join is idempotent — joining an already-joined request is a no-op.
func (r *Repository) Join(ctx context.Context, requestID, userID uuid.UUID) error {
	_, err := r.DB.ExecContext(ctx, `
		INSERT INTO buddy_request_joins (request_id, user_id)
		VALUES ($1, $2)
		ON CONFLICT (request_id, user_id) DO NOTHING
	`, requestID, userID)
	return err
}

// Leave removes a single user's join on a single request — unlike RemoveUserJoinsInTrip, this
// doesn't touch any other request the user might be joined to (they can only be joined to one,
// but this stays scoped to the one request being left regardless).
func (r *Repository) Leave(ctx context.Context, requestID, userID uuid.UUID) error {
	_, err := r.DB.ExecContext(ctx, `DELETE FROM buddy_request_joins WHERE request_id = $1 AND user_id = $2`, requestID, userID)
	return err
}

// ListCreatedByUserInTrip finds requests this user made on this trip — used when they leave
// the trip, since a request with its creator gone no longer makes sense.
func (r *Repository) ListCreatedByUserInTrip(ctx context.Context, tripID, userID uuid.UUID) ([]Request, error) {
	rows, err := r.DB.QueryContext(ctx, `
		SELECT id, trip_id, user_id, created_at
		FROM trip_buddy_requests
		WHERE trip_id = $1 AND user_id = $2
	`, tripID, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	requests := []Request{}
	for rows.Next() {
		var req Request
		if err := rows.Scan(&req.ID, &req.TripID, &req.UserID, &req.CreatedAt); err != nil {
			return nil, err
		}
		requests = append(requests, req)
	}
	return requests, rows.Err()
}

// DeleteRequest cascades to buddy_request_joins and chat_messages via their FKs
// (ON DELETE CASCADE) — callers that need to notify joined users should read ListJoins first.
func (r *Repository) DeleteRequest(ctx context.Context, requestID uuid.UUID) error {
	_, err := r.DB.ExecContext(ctx, `DELETE FROM trip_buddy_requests WHERE id = $1`, requestID)
	return err
}

// RemoveUserJoinsInTrip drops this user's joins across every request on the trip — used when
// they leave the trip entirely, freeing whatever spot they held.
func (r *Repository) RemoveUserJoinsInTrip(ctx context.Context, tripID, userID uuid.UUID) error {
	_, err := r.DB.ExecContext(ctx, `
		DELETE FROM buddy_request_joins
		WHERE user_id = $2 AND request_id IN (SELECT id FROM trip_buddy_requests WHERE trip_id = $1)
	`, tripID, userID)
	return err
}

// CreateAlerts is a best-effort "something changed in Buddy" ping — ON CONFLICT DO NOTHING
// since a user only needs to see the dot once, not one per bumped request.
func (r *Repository) CreateAlerts(ctx context.Context, tripID uuid.UUID, userIDs []uuid.UUID) error {
	for _, userID := range userIDs {
		if _, err := r.DB.ExecContext(ctx, `
			INSERT INTO buddy_alerts (trip_id, user_id) VALUES ($1, $2)
			ON CONFLICT (trip_id, user_id) DO NOTHING
		`, tripID, userID); err != nil {
			return err
		}
	}
	return nil
}

func (r *Repository) HasAlert(ctx context.Context, tripID, userID uuid.UUID) (bool, error) {
	var exists bool
	err := r.DB.QueryRowContext(ctx, `
		SELECT EXISTS(SELECT 1 FROM buddy_alerts WHERE trip_id = $1 AND user_id = $2)
	`, tripID, userID).Scan(&exists)
	return exists, err
}

func (r *Repository) ClearAlert(ctx context.Context, tripID, userID uuid.UUID) error {
	_, err := r.DB.ExecContext(ctx, `DELETE FROM buddy_alerts WHERE trip_id = $1 AND user_id = $2`, tripID, userID)
	return err
}
