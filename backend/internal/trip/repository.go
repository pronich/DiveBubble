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
var ErrPhotoNotFound = errors.New("photo not found")

var tripColumnNames = []string{
	"id", "title", "location", "start_time", "created_at", "creator_user_id",
	"end_date", "description", "meeting_point",
	"dive_count_min", "dive_count_max", "depth_min_m", "depth_max_m",
	"min_certification", "booking_code", "max_participants", "booking_status",
	"dive_center_id", "price_minor", "currency", "booking_url",
	"latitude", "longitude", "is_private",
}

// coverPhotoExpr is the trip's first photo, derived at read time since photo_url isn't a real trips column anymore; appended as the last column rather than threaded through every column-order computation.
func coverPhotoExpr(alias string) string {
	return "(SELECT tp.url FROM trip_photos tp WHERE tp.trip_id = " + alias + ".id ORDER BY tp.position LIMIT 1)"
}

var tripColumns = strings.Join(tripColumnNames, ", ") + ", " + coverPhotoExpr("trips")

// tripColumnsPrefixed qualifies each column with a table alias, for queries that join other tables.
func tripColumnsPrefixed(alias string) string {
	prefixed := make([]string, len(tripColumnNames))
	for i, c := range tripColumnNames {
		prefixed[i] = alias + "." + c
	}
	return strings.Join(prefixed, ", ") + ", " + coverPhotoExpr(alias)
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
		&t.DiveCenterID, &t.PriceMinor, &t.Currency, &t.BookingURL,
		&t.Latitude, &t.Longitude, &t.IsPrivate,
		&t.PhotoURL,
	)
	return t, err
}

func (r *Repository) GetByBookingCode(ctx context.Context, code string) (Trip, error) {
	t, err := scanTrip(r.DB.QueryRowContext(ctx, `SELECT `+tripColumns+` FROM trips WHERE booking_code = $1`, code))
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return Trip{}, ErrNotFound
		}
		return Trip{}, err
	}
	return t, nil
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

	// Business fields — nil DiveCenterID means an individual-organizer trip; BookingCode is always server-generated for business trips, never client-set.
	DiveCenterID *uuid.UUID
	PriceMinor   *int
	BookingURL   *string

	// Latitude/Longitude — see model.go's own doc comment. Best-effort, client-geocoded.
	Latitude  *float64
	Longitude *float64

	// IsPrivate is individual-trips-only; a business trip is always a public marketplace listing.
	IsPrivate bool
}

func (r *Repository) Create(ctx context.Context, p CreateParams) (Trip, error) {
	return scanTrip(r.DB.QueryRowContext(ctx, `
		INSERT INTO trips (
			title, location, start_time, creator_user_id,
			end_date, description, meeting_point,
			dive_count_min, dive_count_max, depth_min_m, depth_max_m,
			min_certification, booking_code, max_participants,
			dive_center_id, price_minor, booking_url,
			latitude, longitude, is_private
		)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20)
		RETURNING `+tripColumns,
		p.Title, p.Location, p.StartTime, p.CreatorUserID,
		p.EndDate, p.Description, p.MeetingPoint,
		p.DiveCountMin, p.DiveCountMax, p.DepthMinM, p.DepthMaxM,
		p.MinCertification, p.BookingCode, p.MaxParticipants,
		p.DiveCenterID, p.PriceMinor, p.BookingURL,
		p.Latitude, p.Longitude, p.IsPrivate,
	))
}

// UpdateParams uses pointers so a nil field is left unchanged rather than cleared, and deliberately excludes booking_status, dive_center_id/creator_user_id, and currency, none of which change via an edit.
type UpdateParams struct {
	Title            *string
	Location         *string
	StartTime        *time.Time
	EndDate          *time.Time
	Description      *string
	MeetingPoint     *string
	DiveCountMin     *int
	DiveCountMax     *int
	DepthMinM        *int
	DepthMaxM        *int
	MinCertification *string
	MaxParticipants  *int
	PriceMinor       *int
	BookingURL       *string

	// Latitude/Longitude nil means "location text didn't change"; the app resends both together whenever location is edited.
	Latitude  *float64
	Longitude *float64
}

func (r *Repository) Update(ctx context.Context, id uuid.UUID, p UpdateParams) (Trip, error) {
	return scanTrip(r.DB.QueryRowContext(ctx, `
		UPDATE trips SET
			title = COALESCE($2, title),
			location = COALESCE($3, location),
			start_time = COALESCE($4, start_time),
			end_date = COALESCE($5, end_date),
			description = COALESCE($6, description),
			meeting_point = COALESCE($7, meeting_point),
			dive_count_min = COALESCE($8, dive_count_min),
			dive_count_max = COALESCE($9, dive_count_max),
			depth_min_m = COALESCE($10, depth_min_m),
			depth_max_m = COALESCE($11, depth_max_m),
			min_certification = COALESCE($12, min_certification),
			max_participants = COALESCE($13, max_participants),
			price_minor = COALESCE($14, price_minor),
			booking_url = COALESCE($15, booking_url),
			latitude = COALESCE($16, latitude),
			longitude = COALESCE($17, longitude)
		WHERE id = $1
		RETURNING `+tripColumns,
		id, p.Title, p.Location, p.StartTime, p.EndDate, p.Description, p.MeetingPoint,
		p.DiveCountMin, p.DiveCountMax, p.DepthMinM, p.DepthMaxM,
		p.MinCertification, p.MaxParticipants, p.PriceMinor, p.BookingURL,
		p.Latitude, p.Longitude,
	))
}

// List excludes cancelled, private, and already-past trips from Explore; full trips stay listed since only Join itself is blocked, and includeTestCenters lets is_owner accounts see test dive centers' trips too.
func (r *Repository) List(ctx context.Context, query string, includeTestCenters bool) ([]Trip, error) {
	rows, err := r.DB.QueryContext(ctx, `
		SELECT `+tripColumnsPrefixed("t")+`
		FROM trips t
		LEFT JOIN users creator ON creator.id = t.creator_user_id
		LEFT JOIN dive_centers dc ON dc.id = t.dive_center_id
		WHERE t.booking_status != 'cancelled'
		  AND t.start_time > now()
		  AND NOT t.is_private
		  AND ($1 = '' OR t.title ILIKE '%' || $1 || '%' OR t.location ILIKE '%' || $1 || '%'
		       OR creator.display_name ILIKE '%' || $1 || '%' OR dc.name ILIKE '%' || $1 || '%')
		  AND (dc.is_test IS NOT TRUE OR $2)
		ORDER BY t.start_time ASC
	`, query, includeTestCenters)
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

// Leave is idempotent — leaving a trip you're not in is a no-op, not an error.
func (r *Repository) Leave(ctx context.Context, tripID, userID uuid.UUID) error {
	_, err := r.DB.ExecContext(ctx, `
		DELETE FROM trip_participants WHERE trip_id = $1 AND user_id = $2
	`, tripID, userID)
	return err
}

func (r *Repository) SetBookingStatus(ctx context.Context, tripID uuid.UUID, status string) error {
	_, err := r.DB.ExecContext(ctx, `UPDATE trips SET booking_status = $1 WHERE id = $2`, status, tripID)
	return err
}

func (r *Repository) CountPhotos(ctx context.Context, tripID uuid.UUID) (int, error) {
	var count int
	err := r.DB.QueryRowContext(ctx, `SELECT COUNT(*) FROM trip_photos WHERE trip_id = $1`, tripID).Scan(&count)
	return count, err
}

func (r *Repository) ListPhotos(ctx context.Context, tripID uuid.UUID) ([]Photo, error) {
	rows, err := r.DB.QueryContext(ctx, `
		SELECT id, trip_id, url, position, created_at FROM trip_photos WHERE trip_id = $1 ORDER BY position ASC
	`, tripID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	photos := []Photo{}
	for rows.Next() {
		var p Photo
		if err := rows.Scan(&p.ID, &p.TripID, &p.URL, &p.Position, &p.CreatedAt); err != nil {
			return nil, err
		}
		photos = append(photos, p)
	}
	return photos, rows.Err()
}

// AddPhoto appends at the end (position = current count); the max-10 cap is enforced by Service.AddPhoto, not here.
func (r *Repository) AddPhoto(ctx context.Context, tripID uuid.UUID, url string) (Photo, error) {
	var p Photo
	err := r.DB.QueryRowContext(ctx, `
		INSERT INTO trip_photos (trip_id, url, position)
		VALUES ($1, $2, (SELECT COUNT(*) FROM trip_photos WHERE trip_id = $1))
		RETURNING id, trip_id, url, position, created_at
	`, tripID, url).Scan(&p.ID, &p.TripID, &p.URL, &p.Position, &p.CreatedAt)
	return p, err
}

// RemovePhoto also closes the position gap it leaves, since AddPhoto's "next position = current count" relies on positions staying dense from 0.
func (r *Repository) RemovePhoto(ctx context.Context, tripID, photoID uuid.UUID) error {
	tx, err := r.DB.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback() }()

	var position int
	err = tx.QueryRowContext(ctx, `
		DELETE FROM trip_photos WHERE id = $1 AND trip_id = $2 RETURNING position
	`, photoID, tripID).Scan(&position)
	if errors.Is(err, sql.ErrNoRows) {
		return ErrPhotoNotFound
	}
	if err != nil {
		return err
	}

	if _, err := tx.ExecContext(ctx, `
		UPDATE trip_photos SET position = position - 1 WHERE trip_id = $1 AND position > $2
	`, tripID, position); err != nil {
		return err
	}

	return tx.Commit()
}

func (r *Repository) ListParticipantUserIDs(ctx context.Context, tripID uuid.UUID) ([]uuid.UUID, error) {
	rows, err := r.DB.QueryContext(ctx, `
		SELECT user_id FROM trip_participants WHERE trip_id = $1 ORDER BY joined_at ASC
	`, tripID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	ids := []uuid.UUID{}
	for rows.Next() {
		var id uuid.UUID
		if err := rows.Scan(&id); err != nil {
			return nil, err
		}
		ids = append(ids, id)
	}
	return ids, rows.Err()
}

func (r *Repository) IsJoined(ctx context.Context, tripID, userID uuid.UUID) (bool, error) {
	var exists bool
	err := r.DB.QueryRowContext(ctx, `
		SELECT EXISTS(SELECT 1 FROM trip_participants WHERE trip_id = $1 AND user_id = $2)
	`, tripID, userID).Scan(&exists)
	return exists, err
}

// ListJoinedByUser orders by most-recent chat activity like WhatsApp/Telegram, and also includes trips via dive-center staff membership (no trip_participants row), falling back to trip_read_state for their read marker; archived just flips which side of the same "is there an archive row" check matches.
func (r *Repository) ListJoinedByUser(ctx context.Context, userID uuid.UUID, archived bool) ([]Trip, error) {
	rows, err := r.DB.QueryContext(ctx, `
		SELECT `+tripColumnsPrefixed("t")+`,
			(SELECT COUNT(*) FROM chat_messages cm
			 WHERE cm.trip_id = t.id AND cm.user_id != $1
			   AND cm.created_at > COALESCE(tp.last_read_at, trs.last_read_at, '-infinity'::timestamptz)),
			(SELECT COUNT(*) FROM trip_participants tp2 WHERE tp2.trip_id = t.id),
			(SELECT EXISTS(SELECT 1 FROM transport_alerts ta WHERE ta.trip_id = t.id AND ta.user_id = $1)),
			(SELECT EXISTS(SELECT 1 FROM chat_messages cm
			 WHERE cm.trip_id = t.id AND cm.user_id != $1 AND cm.mentions_dive_center
			   AND cm.created_at > COALESCE(tp.last_read_at, trs.last_read_at, '-infinity'::timestamptz))),
			(SELECT EXISTS(SELECT 1 FROM buddy_alerts ba WHERE ba.trip_id = t.id AND ba.user_id = $1)),
			(SELECT EXISTS(
				SELECT 1 FROM trip_transport_offers o
				LEFT JOIN transport_offer_read_state tors ON tors.offer_id = o.id AND tors.user_id = $1
				WHERE o.trip_id = t.id
				  AND (o.user_id = $1 OR EXISTS(SELECT 1 FROM transport_offer_joins WHERE offer_id = o.id AND user_id = $1))
				  AND EXISTS(SELECT 1 FROM chat_messages cm WHERE cm.offer_id = o.id AND cm.user_id != $1
				             AND cm.created_at > COALESCE(tors.last_read_at, '-infinity'::timestamptz))
			)),
			(SELECT EXISTS(
				SELECT 1 FROM trip_buddy_requests b
				LEFT JOIN buddy_request_read_state brrs ON brrs.request_id = b.id AND brrs.user_id = $1
				WHERE b.trip_id = t.id
				  AND (b.user_id = $1 OR EXISTS(SELECT 1 FROM buddy_request_joins WHERE request_id = b.id AND user_id = $1))
				  AND EXISTS(SELECT 1 FROM chat_messages cm WHERE cm.buddy_request_id = b.id AND cm.user_id != $1
				             AND cm.created_at > COALESCE(brrs.last_read_at, '-infinity'::timestamptz))
			))
		FROM trips t
		LEFT JOIN trip_participants tp ON tp.trip_id = t.id AND tp.user_id = $1
		LEFT JOIN trip_read_state trs ON trs.trip_id = t.id AND trs.user_id = $1
		LEFT JOIN trip_archives ta2 ON ta2.trip_id = t.id AND ta2.user_id = $1
		WHERE (tp.user_id = $1
		   OR EXISTS (
		       SELECT 1 FROM dive_center_members dcm
		       WHERE dcm.dive_center_id = t.dive_center_id AND dcm.user_id = $1
		   ))
		   AND (ta2.user_id IS NOT NULL) = $2
		ORDER BY COALESCE((SELECT MAX(created_at) FROM chat_messages WHERE trip_id = t.id), tp.joined_at, t.created_at) DESC
	`, userID, archived)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	trips := []Trip{}
	for rows.Next() {
		var t Trip
		err := rows.Scan(
			&t.ID, &t.Title, &t.Location, &t.StartTime, &t.CreatedAt, &t.CreatorUserID,
			&t.EndDate, &t.Description, &t.MeetingPoint,
			&t.DiveCountMin, &t.DiveCountMax, &t.DepthMinM, &t.DepthMaxM,
			&t.MinCertification, &t.BookingCode, &t.MaxParticipants, &t.BookingStatus,
			&t.DiveCenterID, &t.PriceMinor, &t.Currency, &t.BookingURL,
			&t.Latitude, &t.Longitude, &t.IsPrivate,
			&t.PhotoURL,
			&t.UnreadCount, &t.ParticipantCount, &t.HasTransportAlert, &t.HasUnreadMention, &t.HasBuddyAlert,
			&t.HasUnreadTransportMessages, &t.HasUnreadBuddyMessages,
		)
		if err != nil {
			return nil, err
		}
		trips = append(trips, t)
	}
	return trips, rows.Err()
}

// MarkRead writes to both trip_participants and trip_read_state rather than checking which one applies first, since a redundant write to the unused one is harmless.
func (r *Repository) MarkRead(ctx context.Context, tripID, userID uuid.UUID) error {
	if _, err := r.DB.ExecContext(ctx, `
		UPDATE trip_participants SET last_read_at = now() WHERE trip_id = $1 AND user_id = $2
	`, tripID, userID); err != nil {
		return err
	}
	_, err := r.DB.ExecContext(ctx, `
		INSERT INTO trip_read_state (trip_id, user_id, last_read_at)
		VALUES ($1, $2, now())
		ON CONFLICT (trip_id, user_id) DO UPDATE SET last_read_at = now()
	`, tripID, userID)
	return err
}

func (r *Repository) Mute(ctx context.Context, tripID, userID uuid.UUID) error {
	_, err := r.DB.ExecContext(ctx, `
		INSERT INTO trip_mutes (trip_id, user_id) VALUES ($1, $2)
		ON CONFLICT (trip_id, user_id) DO NOTHING
	`, tripID, userID)
	return err
}

func (r *Repository) Unmute(ctx context.Context, tripID, userID uuid.UUID) error {
	_, err := r.DB.ExecContext(ctx, `DELETE FROM trip_mutes WHERE trip_id = $1 AND user_id = $2`, tripID, userID)
	return err
}

func (r *Repository) IsMuted(ctx context.Context, tripID, userID uuid.UUID) (bool, error) {
	var exists bool
	err := r.DB.QueryRowContext(ctx, `
		SELECT EXISTS(SELECT 1 FROM trip_mutes WHERE trip_id = $1 AND user_id = $2)
	`, tripID, userID).Scan(&exists)
	return exists, err
}

// ListMutedUserIDs returns everyone who's muted this trip, regardless of how they have access to it.
func (r *Repository) ListMutedUserIDs(ctx context.Context, tripID uuid.UUID) ([]uuid.UUID, error) {
	rows, err := r.DB.QueryContext(ctx, `SELECT user_id FROM trip_mutes WHERE trip_id = $1`, tripID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var ids []uuid.UUID
	for rows.Next() {
		var id uuid.UUID
		if err := rows.Scan(&id); err != nil {
			return nil, err
		}
		ids = append(ids, id)
	}
	return ids, rows.Err()
}

func (r *Repository) Archive(ctx context.Context, tripID, userID uuid.UUID) error {
	_, err := r.DB.ExecContext(ctx, `
		INSERT INTO trip_archives (trip_id, user_id) VALUES ($1, $2)
		ON CONFLICT (trip_id, user_id) DO NOTHING
	`, tripID, userID)
	return err
}

func (r *Repository) Unarchive(ctx context.Context, tripID, userID uuid.UUID) error {
	_, err := r.DB.ExecContext(ctx, `DELETE FROM trip_archives WHERE trip_id = $1 AND user_id = $2`, tripID, userID)
	return err
}

func (r *Repository) IsArchived(ctx context.Context, tripID, userID uuid.UUID) (bool, error) {
	var exists bool
	err := r.DB.QueryRowContext(ctx, `
		SELECT EXISTS(SELECT 1 FROM trip_archives WHERE trip_id = $1 AND user_id = $2)
	`, tripID, userID).Scan(&exists)
	return exists, err
}

// ListArchivedUserIDs backs notifyNewMessage's archive filter: an archived trip still counts unread messages but never pushes, same posture as a muted trip.
func (r *Repository) ListArchivedUserIDs(ctx context.Context, tripID uuid.UUID) ([]uuid.UUID, error) {
	rows, err := r.DB.QueryContext(ctx, `SELECT user_id FROM trip_archives WHERE trip_id = $1`, tripID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var ids []uuid.UUID
	for rows.Next() {
		var id uuid.UUID
		if err := rows.Scan(&id); err != nil {
			return nil, err
		}
		ids = append(ids, id)
	}
	return ids, rows.Err()
}

func (r *Repository) CountParticipants(ctx context.Context, tripID uuid.UUID) (int, error) {
	var count int
	err := r.DB.QueryRowContext(ctx, `
		SELECT COUNT(*) FROM trip_participants WHERE trip_id = $1
	`, tripID).Scan(&count)
	return count, err
}

// SubmitFeedback silently no-ops on resubmission: there's no edit flow, first submission wins.
func (r *Repository) SubmitFeedback(ctx context.Context, tripID, userID uuid.UUID, rating int, helpedWith string, comment sql.NullString, contactOk bool) error {
	_, err := r.DB.ExecContext(ctx, `
		INSERT INTO trip_feedback (trip_id, user_id, rating, helped_with, comment, contact_ok)
		VALUES ($1, $2, $3, $4, $5, $6)
		ON CONFLICT (trip_id, user_id) DO NOTHING
	`, tripID, userID, rating, helpedWith, comment, contactOk)
	return err
}

func (r *Repository) HasFeedback(ctx context.Context, tripID, userID uuid.UUID) (bool, error) {
	var exists bool
	err := r.DB.QueryRowContext(ctx, `
		SELECT EXISTS(SELECT 1 FROM trip_feedback WHERE trip_id = $1 AND user_id = $2)
	`, tripID, userID).Scan(&exists)
	return exists, err
}

// ListTripIDsAwaitingFeedbackPrompt backs the periodic scan job: trips whose last day has fully ended, weren't cancelled, and haven't had a feedback-prompt message sent yet.
func (r *Repository) ListTripIDsAwaitingFeedbackPrompt(ctx context.Context) ([]uuid.UUID, error) {
	rows, err := r.DB.QueryContext(ctx, `
		SELECT t.id FROM trips t
		WHERE COALESCE(t.end_date::date, t.start_time::date) < CURRENT_DATE
		  AND t.booking_status != 'cancelled'
		  AND NOT EXISTS (
		      SELECT 1 FROM chat_messages cm WHERE cm.trip_id = t.id AND cm.kind = 'feedback_prompt'
		  )
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var ids []uuid.UUID
	for rows.Next() {
		var id uuid.UUID
		if err := rows.Scan(&id); err != nil {
			return nil, err
		}
		ids = append(ids, id)
	}
	return ids, rows.Err()
}
