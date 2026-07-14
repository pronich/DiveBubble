package transport

import (
	"database/sql"
	"time"

	"github.com/google/uuid"
)

type OfferType string

const (
	OfferRide    OfferType = "offer_ride"
	ShareRental  OfferType = "share_rental"
	SelfArranged OfferType = "self_arranged"
)

func (t OfferType) Valid() bool {
	switch t {
	case OfferRide, ShareRental, SelfArranged:
		return true
	default:
		return false
	}
}

// Joinable offers reserve seats for other participants — self_arranged is just an announcement.
func (t OfferType) Joinable() bool {
	return t == OfferRide || t == ShareRental
}

type Offer struct {
	ID          uuid.UUID
	TripID      uuid.UUID
	UserID      uuid.UUID
	Type        OfferType
	Seats       sql.NullInt32
	Details     sql.NullString
	CreatedAt   time.Time
	JoinedCount int
	Joined      bool // whether the calling user has joined this offer
}
