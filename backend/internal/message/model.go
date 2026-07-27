package message

import (
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
}

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
)

// SystemUserID is the sentinel sender for system-generated messages, seeded by migration
// 000042_seed_system_user.
var SystemUserID = uuid.MustParse("00000000-0000-0000-0000-000000000001")
