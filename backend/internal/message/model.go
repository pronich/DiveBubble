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
	// OfferID/BuddyRequestID are set when this message belongs to a car offer's or buddy group's chat instead of the trip's main chat (TripID stays populated either way); at most one is ever set (DB CHECK).
	OfferID        uuid.NullUUID
	BuddyRequestID uuid.NullUUID
	// Attachment* are set together or not at all (see migration 000051's consistency check).
	AttachmentURL       sql.NullString
	AttachmentType      sql.NullString // "image" | "pdf"
	AttachmentFilename  sql.NullString
	AttachmentSizeBytes sql.NullInt64
	// ReplyToID is the message this one replies to, if any, nulled out (not cascade-deleted) if the original is later soft-deleted since DeletedAt is a flag on the row, not a row removal.
	ReplyToID uuid.NullUUID
	// DeletedAt is the soft-delete timestamp; when set, Body/Attachment*/Attachments are blanked server-side before the row leaves the repository layer (see routes_message.go's toMessageResponse) — never rely on a client to hide deleted content.
	DeletedAt sql.NullTime
	// Attachments is the multi-attachment path, populated separately from the single-attachment scalar fields above (kept so old rows keep rendering); not scanned by scanMessage itself, joined in by Repository's batched attachment fetch, ordered by Position.
	Attachments []Attachment
}

// ReactionSummary is one emoji's aggregate on a message: Count is viewer-independent, ReactedByMe is per-viewer and only populated when given a specific viewer id, and must never be broadcast over realtime as-is since a Centrifugo publish is one shared payload (see routes_message.go's publishReactionUpdate, which strips it before publishing).
type ReactionSummary struct {
	Count       int
	ReactedByMe bool
}

// AllowedReactionEmojis mirrors migration 000055's CHECK constraint, checked here too so a bad value gets a clean 400 instead of a raw constraint-violation 500.
var AllowedReactionEmojis = []string{"❤️", "😅", "😁", "🙃", "😢", "😮", "😡", "👌"}

func IsValidReactionEmoji(emoji string) bool {
	for _, e := range AllowedReactionEmojis {
		if e == emoji {
			return true
		}
	}
	return false
}

// Attachment is the caller-facing shape for one file on a message, used both for sending (Repository.Create takes []Attachment) and for rows read back from chat_message_attachments.
type Attachment struct {
	URL       string
	Type      string // "image" | "video" | "pdf"
	Filename  string
	SizeBytes int64
	// DurationSeconds — video only, nil otherwise.
	DurationSeconds *int
}

const (
	AttachmentTypeImage = "image"
	AttachmentTypeVideo = "video"
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

// SystemUserID is the sentinel sender for system-generated messages, seeded by migration 000042_seed_system_user.
var SystemUserID = uuid.MustParse("00000000-0000-0000-0000-000000000001")
