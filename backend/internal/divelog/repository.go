package divelog

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"

	"github.com/google/uuid"
)

var ErrNotFound = errors.New("dive log entry not found")

type Repository struct {
	DB *sql.DB
}

func NewRepository(db *sql.DB) *Repository {
	return &Repository{DB: db}
}

const entryColumns = `id, user_id, trip_id, source, dived_at, max_depth_m, duration_minutes,
	min_temperature_c, site_name, latitude, longitude, notes, profile_samples, created_at`

func scanEntry(row interface{ Scan(...any) error }, e *Entry) error {
	var samplesJSON []byte
	if err := row.Scan(
		&e.ID, &e.UserID, &e.TripID, &e.Source, &e.DivedAt, &e.MaxDepthM, &e.DurationMinutes,
		&e.MinTemperatureC, &e.SiteName, &e.Latitude, &e.Longitude, &e.Notes, &samplesJSON, &e.CreatedAt,
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

// Create inserts one entry. onConflictSkip controls the import-vs-manual-add dedup behavior:
// a manual add should always insert (or surface a genuine conflict as an error — a diver
// manually re-entering the exact same timestamp twice is presumably a mistake worth seeing),
// while an import silently skips a dive already logged at that exact dived_at (see the
// migration's unique index) rather than erroring the whole batch out.
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
		INSERT INTO dive_log_entries (user_id, trip_id, source, dived_at, max_depth_m, duration_minutes,
			min_temperature_c, site_name, latitude, longitude, notes, profile_samples)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
		`+conflictClause+`
		RETURNING `+entryColumns+`
	`, e.UserID, e.TripID, e.Source, e.DivedAt, e.MaxDepthM, e.DurationMinutes,
		e.MinTemperatureC, e.SiteName, e.Latitude, e.Longitude, e.Notes, samplesJSON)

	if err := scanEntry(row, &out); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			// Only reachable when onConflictSkip suppressed the insert — a real duplicate on
			// a non-deduped manual add would instead surface as a unique-constraint error.
			return Entry{}, false, nil
		}
		return Entry{}, false, err
	}
	return out, true, nil
}

// Update replaces every editable field (never source or profile_samples, which are fixed at
// creation) — the app only ever sends siteName/notes changes for an imported entry, and the
// full set for a manual one, but this doesn't itself distinguish the two.
func (r *Repository) Update(ctx context.Context, id uuid.UUID, e Entry) (Entry, error) {
	var out Entry
	if err := scanEntry(r.DB.QueryRowContext(ctx, `
		UPDATE dive_log_entries
		SET dived_at = $2, max_depth_m = $3, duration_minutes = $4, min_temperature_c = $5,
			site_name = $6, notes = $7
		WHERE id = $1
		RETURNING `+entryColumns+`
	`, id, e.DivedAt, e.MaxDepthM, e.DurationMinutes, e.MinTemperatureC, e.SiteName, e.Notes), &out); err != nil {
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
