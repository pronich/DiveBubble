package divelog

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"time"

	"github.com/google/uuid"
)

var ErrNotFound = errors.New("dive log entry not found")

type Repository struct {
	DB *sql.DB
}

func NewRepository(db *sql.DB) *Repository {
	return &Repository{DB: db}
}

const entryColumns = `id, user_id, trip_id, source, dived_at, max_depth_m, avg_depth_m, duration_minutes,
	min_temperature_c, country, site_name, latitude, longitude, notes, profile_samples, created_at`

func scanEntry(row interface{ Scan(...any) error }, e *Entry) error {
	var samplesJSON []byte
	if err := row.Scan(
		&e.ID, &e.UserID, &e.TripID, &e.Source, &e.DivedAt, &e.MaxDepthM, &e.AvgDepthM, &e.DurationMinutes,
		&e.MinTemperatureC, &e.Country, &e.SiteName, &e.Latitude, &e.Longitude, &e.Notes, &samplesJSON, &e.CreatedAt,
	); err != nil {
		return err
	}
	if len(samplesJSON) > 0 {
		if err := json.Unmarshal(samplesJSON, &e.ProfileSamples); err != nil {
			return err
		}
	}
	return nil
}

// Create inserts one entry; onConflictSkip=false lets a manual duplicate timestamp surface as a genuine error, while true (imports) silently skips a dive already logged at that dived_at rather than erroring the whole batch.
func (r *Repository) Create(ctx context.Context, e Entry, onConflictSkip bool) (Entry, bool, error) {
	samplesJSON, err := json.Marshal(e.ProfileSamples)
	if err != nil {
		return Entry{}, false, err
	}
	if len(e.ProfileSamples) == 0 {
		samplesJSON = nil
	}

	conflictClause := ""
	if onConflictSkip {
		conflictClause = "ON CONFLICT (user_id, dived_at) DO NOTHING"
	}

	var out Entry
	row := r.DB.QueryRowContext(ctx, `
		INSERT INTO dive_log_entries (user_id, trip_id, source, dived_at, max_depth_m, avg_depth_m, duration_minutes,
			min_temperature_c, country, site_name, latitude, longitude, notes, profile_samples)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
		`+conflictClause+`
		RETURNING `+entryColumns+`
	`, e.UserID, e.TripID, e.Source, e.DivedAt, e.MaxDepthM, e.AvgDepthM, e.DurationMinutes,
		e.MinTemperatureC, e.Country, e.SiteName, e.Latitude, e.Longitude, e.Notes, samplesJSON)

	if err := scanEntry(row, &out); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			// Only reachable when onConflictSkip suppressed the insert; a real duplicate on a non-deduped manual add instead surfaces as a unique-constraint error.
			return Entry{}, false, nil
		}
		return Entry{}, false, err
	}
	return out, true, nil
}

// ExistsNear reports whether this diver already has an entry within tolerance of divedAt — a re-export of the same dive from a different tool (or a different precision, e.g. CSV's minute-only vs UDDF's seconds+offset) rarely lands on the exact same timestamp, so the exact (user_id, dived_at) unique index alone misses these as duplicates.
func (r *Repository) ExistsNear(ctx context.Context, userID uuid.UUID, divedAt time.Time, tolerance time.Duration) (bool, error) {
	var exists bool
	err := r.DB.QueryRowContext(ctx, `
		SELECT EXISTS(
			SELECT 1 FROM dive_log_entries
			WHERE user_id = $1 AND dived_at BETWEEN $2 AND $3
		)
	`, userID, divedAt.Add(-tolerance), divedAt.Add(tolerance)).Scan(&exists)
	return exists, err
}

// Update replaces every editable field but never source, avg_depth_m, or profile_samples, which are fixed at creation since avg_depth_m is only ever known by an importer with no manual-entry UI for it.
func (r *Repository) Update(ctx context.Context, id uuid.UUID, e Entry) (Entry, error) {
	var out Entry
	if err := scanEntry(r.DB.QueryRowContext(ctx, `
		UPDATE dive_log_entries
		SET dived_at = $2, max_depth_m = $3, duration_minutes = $4, min_temperature_c = $5,
			country = $6, site_name = $7, notes = $8
		WHERE id = $1
		RETURNING `+entryColumns+`
	`, id, e.DivedAt, e.MaxDepthM, e.DurationMinutes, e.MinTemperatureC, e.Country, e.SiteName, e.Notes), &out); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return Entry{}, ErrNotFound
		}
		return Entry{}, err
	}
	return out, nil
}

func (r *Repository) ListByUser(ctx context.Context, userID uuid.UUID) ([]Entry, error) {
	rows, err := r.DB.QueryContext(ctx, `
		SELECT `+entryColumns+` FROM dive_log_entries WHERE user_id = $1 ORDER BY dived_at DESC
	`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	entries := []Entry{}
	for rows.Next() {
		var e Entry
		if err := scanEntry(rows, &e); err != nil {
			return nil, err
		}
		entries = append(entries, e)
	}
	return entries, rows.Err()
}

func (r *Repository) GetByID(ctx context.Context, id uuid.UUID) (Entry, error) {
	var e Entry
	if err := scanEntry(r.DB.QueryRowContext(ctx, `
		SELECT `+entryColumns+` FROM dive_log_entries WHERE id = $1
	`, id), &e); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return Entry{}, ErrNotFound
		}
		return Entry{}, err
	}
	return e, nil
}

func (r *Repository) Delete(ctx context.Context, id uuid.UUID) error {
	_, err := r.DB.ExecContext(ctx, `DELETE FROM dive_log_entries WHERE id = $1`, id)
	return err
}
