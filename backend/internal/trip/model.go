package trip

import (
	"database/sql"
	"time"

	"github.com/google/uuid"
)

type Trip struct {
	ID               uuid.UUID
	Title            string
	Location         string
	StartTime        time.Time
	CreatedAt        time.Time
	CreatorUserID    uuid.NullUUID
	ParticipantCount int
	UnreadCount      int // only populated by ListJoinedByUser

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
	PhotoURL         sql.NullString

	// Business fields — nil/DKK for every individual-organizer trip. See divecenter package.
	DiveCenterID uuid.NullUUID
	PriceMinor   sql.NullInt32 // minor currency units (øre) — nil means price not set/shown
	Currency     string

	// BookingURL is the trip's own external checkout page (distinct from the dive center's
	// general website) — see CLAUDE.md's Booking Code flow section for why the two aren't
	// the same field.
	BookingURL sql.NullString
}
