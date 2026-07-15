package divecenter

import (
	"time"

	"github.com/google/uuid"
)

type DiveCenter struct {
	ID        uuid.UUID
	Name      string
	CreatedAt time.Time
}

type Member struct {
	DiveCenterID uuid.UUID
	UserID       uuid.UUID
	Role         string // "owner" | "staff"
	JoinedAt     time.Time
}

// MembershipView pairs a dive center with the caller's own role in it — what ListMine
// returns, since "which businesses am I part of, and as what" is always asked together.
type MembershipView struct {
	DiveCenter DiveCenter
	Role       string
}
