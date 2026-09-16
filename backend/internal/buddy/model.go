package buddy

import (
	"time"

	"github.com/google/uuid"
)

// MaxMembers is the whole group's size cap including the creator, fixed rather than per-request like transport's per-offer seats; real trips have produced groups of 3.
const MaxMembers = 3

type Request struct {
	ID          uuid.UUID
	TripID      uuid.UUID
	UserID      uuid.UUID // creator
	CreatedAt   time.Time
	JoinedCount int  // joiners only, excludes the creator — see Join's capacity check
	Joined      bool // whether the calling user has joined this request (not counting being creator)
	// HasUnreadMessages is true when this group's chat has an unseen message, distinct from an alert (which fires only when a joined group dissolves).
	HasUnreadMessages bool
}
