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

// HandleUserLeavingTrip is called when a diver leaves a trip entirely (see trip.Service —
// this is transport's side of that): drops their own joins (frees seats they held), and
// dissolves any offer *they* created on this trip — an offer with its creator gone no
// longer makes sense, so it's deleted (cascading its joins) rather than left stale. Everyone
// who'd joined a dissolved offer gets a transport_alerts row — a real notification doesn't
// exist yet, this is the "something changed, go check" stopgap surfaced as a dot in the UI.
func (s *Service) HandleUserLeavingTrip(ctx context.Context, tripID, userID uuid.UUID) error {
	if err := s.Repo.RemoveUserJoinsInTrip(ctx, tripID, userID); err != nil {
		return err
	}

	offers, err := s.Repo.ListCreatedByUserInTrip(ctx, tripID, userID)
	if err != nil {
		return err
	}

	for _, offer := range offers {
		joinedUserIDs, err := s.Repo.ListJoins(ctx, offer.ID)
		if err != nil {
			return err
		}
		if err := s.Repo.DeleteOffer(ctx, offer.ID); err != nil {
			return err
		}
		if len(joinedUserIDs) > 0 {
			if err := s.Repo.CreateAlerts(ctx, tripID, joinedUserIDs); err != nil {
				return err
			}
		}
	}
	return nil
}

func (s *Service) HasAlert(ctx context.Context, tripID, userID uuid.UUID) (bool, error) {
	return s.Repo.HasAlert(ctx, tripID, userID)
}

func (s *Service) ClearAlert(ctx context.Context, tripID, userID uuid.UUID) error {
	return s.Repo.ClearAlert(ctx, tripID, userID)
}
