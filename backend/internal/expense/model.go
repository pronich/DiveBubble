package expense

import (
	"time"

	"github.com/google/uuid"
)

type SplitType string

const (
	SplitEqual  SplitType = "equal"
	SplitShares SplitType = "shares"
	SplitExact  SplitType = "exact"
)

func (t SplitType) Valid() bool {
	switch t {
	case SplitEqual, SplitShares, SplitExact:
		return true
	default:
		return false
	}
}

// Share is one participant's slice of an expense. Shares is only meaningful for
// SplitShares (kept alongside AmountMinor so re-opening an expense for edit can show the
// diver's original 1/2/3 counts rather than a derived amount) — AmountMinor is always
// populated regardless of SplitType.
type Share struct {
	UserID      uuid.UUID
	Shares      *int
	AmountMinor int64
}

type Expense struct {
	ID          uuid.UUID
	TripID      uuid.UUID
	PayerUserID uuid.UUID
	CreatedBy   uuid.UUID
	Title       string
	AmountMinor int64
	SplitType   SplitType
	OccurredAt  time.Time
	CreatedAt   time.Time
	UpdatedAt   time.Time
	Shares      []Share
}

type Settlement struct {
	ID          uuid.UUID
	TripID      uuid.UUID
	FromUserID  uuid.UUID
	ToUserID    uuid.UUID
	AmountMinor int64
	CreatedAt   time.Time
}

// Balance is one participant's net position on a trip — positive means the trip owes them,
// negative means they owe the trip.
type Balance struct {
	UserID      uuid.UUID
	AmountMinor int64
}

// SettlementSuggestion is one leg of the simplified "who pays whom" graph computed from a
// set of Balances — see Simplify.
type SettlementSuggestion struct {
	FromUserID  uuid.UUID
	ToUserID    uuid.UUID
	AmountMinor int64
}
