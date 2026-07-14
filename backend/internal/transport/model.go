package transport

import (
	"database/sql"
	"time"

	"github.com/google/uuid"
)

type OfferType string

const (
	OfferRide   OfferType = "offer_ride"
	ShareRental OfferType = "share_rental"
)

func (t OfferType) Valid() bool {
	switch t {
	case OfferRide, ShareRental:
		return true
	default:
		return false
	}
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
