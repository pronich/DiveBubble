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
	PhotoURL         sql.NullString // unused until real photo upload/storage exists — always null for now
}
