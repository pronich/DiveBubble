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
	HasBuddyAlert     bool // only populated by ListJoinedByUser — see buddy_alerts
	// HasUnreadTransportMessages/HasUnreadBuddyMessages only clear once the diver visits the Transport/Buddy tab, since trip-level MarkRead doesn't touch their own read-state tables.
	HasUnreadTransportMessages bool
	HasUnreadBuddyMessages     bool
	// HasUnreadMention is only ever true for a business trip; backs the Bubbles-sidebar mention dot in admin/.
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
	// IsPrivate excludes the trip from Explore's List; joining reuses the business trip's booking_code gate rather than a separate visibility system.
	IsPrivate bool

	// PhotoURL is derived, not stored: the first photo in trip_photos (position 0), via a subquery in every SELECT that populates it.
	PhotoURL sql.NullString

	// Business fields — nil/DKK for every individual-organizer trip. See divecenter package.
	DiveCenterID uuid.NullUUID
	PriceMinor   sql.NullInt32 // minor currency units (øre) — nil means price not set/shown
	Currency     string

	// BookingURL is the trip's own external checkout page, distinct from the dive center's general website.
	BookingURL sql.NullString

	// Latitude/Longitude are a best-effort client-side forward-geocode at creation time, powering Explore's "Nearest" sort (distance computed client-side, not in SQL).
	Latitude  sql.NullFloat64
	Longitude sql.NullFloat64
}

// Photo is one entry in a trip's ordered gallery; Position is upload order, dense from 0, with no manual reordering in this round.
type Photo struct {
	ID        uuid.UUID
	TripID    uuid.UUID
	URL       string
	Position  int
	CreatedAt time.Time
}

// MaxPhotosPerTrip is enforced in Service.AddPhoto, not the database, since Postgres has no clean "max N rows per group" constraint.
const MaxPhotosPerTrip = 10
