package transport

import (
	"context"
	"errors"
	"strings"

	"github.com/google/uuid"
)

var ErrInvalidArgument = errors.New("invalid argument")
var ErrFull = errors.New("no seats left")
var ErrAlreadyBooked = errors.New("already joined a transport offer on this trip")

type Service struct {
	Repo *Repository
}

func NewService(repo *Repository) *Service {
	return &Service{Repo: repo}
}

func (s *Service) Create(ctx context.Context, tripID, userID uuid.UUID, offerType OfferType, seats *int, details *string) (Offer, error) {
	if !offerType.Valid() {
		return Offer{}, ErrInvalidArgument
	}
	if seats != nil && *seats <= 0 {
		return Offer{}, ErrInvalidArgument
	}
	if details != nil {
		trimmed := strings.TrimSpace(*details)
		if trimmed == "" {
			details = nil
		} else {
			details = &trimmed
		}
	}
	return s.Repo.Create(ctx, CreateParams{TripID: tripID, UserID: userID, Type: offerType, Seats: seats, Details: details})
}

func (s *Service) List(ctx context.Context, tripID, callerUserID uuid.UUID) ([]Offer, error) {
	return s.Repo.ListByTrip(ctx, tripID, callerUserID)
}

func (s *Service) Join(ctx context.Context, offerID, userID uuid.UUID) error {
	offer, err := s.Repo.GetByID(ctx, offerID)
	if err != nil {
		return err
	}

	alreadyJoined, err := s.Repo.IsJoined(ctx, offerID, userID)
	if err != nil {
		return err
	}
	if alreadyJoined {
		return nil
	}

	// One booking per trip — a diver only needs one ride, regardless of how many offers exist.
	hasOtherBooking, err := s.Repo.HasAnyJoinInTrip(ctx, offer.TripID, userID)
	if err != nil {
		return err
	}
	if hasOtherBooking {
		return ErrAlreadyBooked
	}

	if offer.Seats.Valid {
		count, err := s.Repo.CountJoins(ctx, offerID)
		if err != nil {
			return err
		}
		if count >= int(offer.Seats.Int32) {
			return ErrFull
		}
	}
	return s.Repo.Join(ctx, offerID, userID)
}

func (s *Service) ListJoins(ctx context.Context, offerID uuid.UUID) ([]uuid.UUID, error) {
	return s.Repo.ListJoins(ctx, offerID)
}
