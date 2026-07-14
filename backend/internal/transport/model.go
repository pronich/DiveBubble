package transport

import (
	"database/sql"
	"time"

	"github.com/google/uuid"
)

type OfferType string

const (
	OfferRide    OfferType = "offer_ride"
	FindRide     OfferType = "find_ride"
	ShareRental  OfferType = "share_rental"
	SelfArranged OfferType = "self_arranged"
)

func (t OfferType) Valid() bool {
	switch t {
	case OfferRide, FindRide, ShareRental, SelfArranged:
		return true
	default:
		return false
	}
}

type Offer struct {
	ID        uuid.UUID
	TripID    uuid.UUID
	UserID    uuid.UUID
	Type      OfferType
	Seats     sql.NullInt32
	Details   sql.NullString
	CreatedAt time.Time
}
