package trip

import (
	"database/sql"
	"time"

	"github.com/google/uuid"
)

type Trip struct {
	ID                uuid.UUID
	Title             string
	Location          string
	StartTime         time.Time
	CreatedAt         time.Time
	CreatorUserID     uuid.NullUUID
	ParticipantCount  int
	UnreadCount       int  // only populated by ListJoinedByUser
	HasTransportAlert bool // only populated by ListJoinedByUser — see transport_alerts
	// True when an unread message on this trip has mentions_dive_center set — only ever
	// true for a business trip (see message.Service.Send's own gate). Only populated by
	// ListJoinedByUser; backs the Bubbles-sidebar mention dot in admin/.
	HasUnreadMention bool

	// Enrichment fields — all optional except BookingStatus, which always has a value.
	EndDate          sql.NullTime
	Description      sql.NullString
	MeetingPoint     sql.NullString
	DiveCountMin     sql.NullInt32
	DiveCountMax     sql.NullInt32
	DepthMinM        sql.NullInt32
	DepthMaxM        sql.NullInt32
	MinCertification sql.NullString
	BookingCode      sql.NullString
	MaxParticipants  sql.NullInt32
	BookingStatus    string

	// PhotoURL is derived, not stored — the first photo in trip_photos (position 0), via a
	// subquery in every SELECT that populates it. See Photo below for the full ordered list.
	PhotoURL sql.NullString

	// Business fields — nil/DKK for every individual-organizer trip. See divecenter package.
	DiveCenterID uuid.NullUUID
	PriceMinor   sql.NullInt32 // minor currency units (øre) — nil means price not set/shown
	Currency     string

	// BookingURL is the trip's own external checkout page (distinct from the dive center's
	// general website) — see CLAUDE.md's Booking Code flow section for why the two aren't
	// the same field.
	BookingURL sql.NullString

	// Latitude/Longitude are a best-effort client-side forward-geocode of the trip's
	// location/meeting_point at creation time — nullable, powers Explore's "Nearest" sort
	// (distance computed client-side, not in SQL).
	Latitude  sql.NullFloat64
	Longitude sql.NullFloat64
}

// Photo is one entry in a trip's ordered gallery (trip_photos) — Position is upload order,
// dense from 0, no gaps or manual reordering in this round (see AddPhoto/RemovePhoto).
type Photo struct {
	ID        uuid.UUID
	TripID    uuid.UUID
	URL       string
	Position  int
	CreatedAt time.Time
}

// MaxPhotosPerTrip caps a trip's gallery — enforced in Service.AddPhoto, not the database
// (Postgres has no clean "max N rows per group" constraint), so it's the one source of truth
// both AddPhoto and any client-side "disable the + button" logic should reference.
const MaxPhotosPerTrip = 10
