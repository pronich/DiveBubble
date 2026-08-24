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
	// DeletedAt — soft-delete timestamp (migration 000053). When set, Body/Attachment*/
	// Attachments are blanked server-side before the row ever leaves the repository layer
	// bound for a response (see routes_message.go's toMessageResponse) — never rely on a
	// client to hide deleted content.
	DeletedAt sql.NullTime
	// Attachments — the multi-attachment path (migration 000054, chat_message_attachments),
	// populated separately from the single-attachment scalar fields above (which stay in place
	// so old rows keep rendering). Not scanned by scanMessage itself — see Repository's
	// batched attachment fetch, joined in by ListByTrip/GetByID/etc. Ordered by Position.
	Attachments []Attachment
}

// ReactionSummary is one emoji's aggregate on a message (migration 000055,
// chat_message_reactions) — Count is viewer-independent, ReactedByMe is per-viewer and only
// ever populated by a call that was given a specific viewer id (see
// Repository.ListReactionsByMessageIDs). Never broadcast ReactedByMe over realtime as-is — a
// Centrifugo publish is one shared payload for every subscriber, so it can only ever be true
// for the one viewer it was computed for (see routes_message.go's publishReactionUpdate,
// which strips it back down to just the counts before publishing).
type ReactionSummary struct {
	Count       int
	ReactedByMe bool
}

// AllowedReactionEmojis mirrors migration 000055's CHECK constraint — checked here too so a
// bad value gets a clean 400 instead of a raw constraint-violation 500.
var AllowedReactionEmojis = []string{"❤️", "😅", "😁", "🙃", "😢", "😮", "😡", "👌"}

func IsValidReactionEmoji(emoji string) bool {
	for _, e := range AllowedReactionEmojis {
		if e == emoji {
			return true
		}
	}
	return false
}

// Attachment is the caller-facing shape for one file on a message — used both for sending
// (Repository.Create takes []Attachment) and for rows read back from chat_message_attachments.
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

// SystemUserID is the sentinel sender for system-generated messages, seeded by migration
// 000042_seed_system_user.
var SystemUserID = uuid.MustParse("00000000-0000-0000-0000-000000000001")
