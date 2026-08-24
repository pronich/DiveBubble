package message

import (
	"database/sql"
	"time"

	"github.com/google/uuid"
)

type Message struct {
	ID                 uuid.UUID
	TripID             uuid.UUID
	UserID             uuid.UUID
	Body               string
	CreatedAt          time.Time
	MentionsDiveCenter bool
	Kind               string
	// OfferID/BuddyRequestID are set when this message belongs to a car offer's or buddy
	// group's own chat instead of the trip's main chat — TripID stays populated either way
	// (see migrations 000046/000048). At most one of the two is ever set (DB CHECK).
	OfferID        uuid.NullUUID
	BuddyRequestID uuid.NullUUID
	// Attachment* are set together or not at all (see migration 000051's consistency check).
	AttachmentURL       sql.NullString
	AttachmentType      sql.NullString // "image" | "pdf"
	AttachmentFilename  sql.NullString
	AttachmentSizeBytes sql.NullInt64
	// ReplyToID — the message this one replies to, if any (see migration 000052). Nulled out
	// (not cascade-deleted) if the original is later soft-deleted, since DeletedAt is a flag
	// on the row, not a row removal.
	ReplyToID uuid.NullUUID
	// DeletedAt — soft-delete timestamp (migration 000053). When set, Body/Attachment* are
	// blanked server-side before the row ever leaves the repository layer bound for a
	// response (see routes_message.go's toMessageResponse) — never rely on a client to hide
	// deleted content.
	DeletedAt sql.NullTime
}

// Attachment is the caller-facing shape for sending a message with a file — Message uses
// sql.Null* directly since it also represents rows read back from the DB.
type Attachment struct {
	URL       string
	Type      string // "image" | "pdf"
	Filename  string
	SizeBytes int64
}

const (
	AttachmentTypeImage = "image"
	AttachmentTypePDF   = "pdf"
)

// Scope selects which chat a message belongs to — the zero value is the trip's main chat.
type Scope struct {
	OfferID        uuid.NullUUID
	BuddyRequestID uuid.NullUUID
}

const (
	KindUser           = "user"
	KindFeedbackPrompt = "feedback_prompt"
	KindCarJoined      = "car_joined"
	KindBuddyJoined    = "buddy_joined"
	KindObserverJoined = "observer_joined"
)

// SystemUserID is the sentinel sender for system-generated messages, seeded by migration
// 000042_seed_system_user.
var SystemUserID = uuid.MustParse("00000000-0000-0000-0000-000000000001")
