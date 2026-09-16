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
var ErrForbidden = errors.New("only the creator can do that")

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

// Join returns the offer so callers can notify its creator (offer.UserID) without a second fetch.
func (s *Service) Join(ctx context.Context, offerID, userID uuid.UUID) (Offer, error) {
	offer, err := s.Repo.GetByID(ctx, offerID)
	if err != nil {
		return Offer{}, err
	}

	alreadyJoined, err := s.Repo.IsJoined(ctx, offerID, userID)
	if err != nil {
		return Offer{}, err
	}
	if alreadyJoined {
		return offer, nil
	}

	// One booking per trip — a diver only needs one ride, regardless of how many offers exist.
	hasOtherBooking, err := s.Repo.HasAnyJoinInTrip(ctx, offer.TripID, userID)
	if err != nil {
		return Offer{}, err
	}
	if hasOtherBooking {
		return Offer{}, ErrAlreadyBooked
	}

	if offer.Seats.Valid {
		count, err := s.Repo.CountJoins(ctx, offerID)
		if err != nil {
			return Offer{}, err
		}
		if count >= int(offer.Seats.Int32) {
			return Offer{}, ErrFull
		}
	}
	if err := s.Repo.Join(ctx, offerID, userID); err != nil {
		return Offer{}, err
	}
	return offer, nil
}

func (s *Service) ListJoins(ctx context.Context, offerID uuid.UUID) ([]uuid.UUID, error) {
	return s.Repo.ListJoins(ctx, offerID)
}

// Leave lets a joined diver step out of a single car; the offer and its chat carry on for whoever's left.
func (s *Service) Leave(ctx context.Context, offerID, userID uuid.UUID) error {
	return s.Repo.Leave(ctx, offerID, userID)
}

// Dissolve deletes the offer, cascading its joins and chat history; anyone but the creator gets ErrForbidden.
func (s *Service) Dissolve(ctx context.Context, offerID, userID uuid.UUID) error {
	offer, err := s.Repo.GetByID(ctx, offerID)
	if err != nil {
		return err
	}
	if offer.UserID != userID {
		return ErrForbidden
	}
	return s.Repo.DeleteOffer(ctx, offerID)
}

// HandleUserLeavingTrip frees the user's own seats and dissolves any offer they created, returning everyone who got a fresh transport_alerts row so callers can push-notify them.
func (s *Service) HandleUserLeavingTrip(ctx context.Context, tripID, userID uuid.UUID) ([]uuid.UUID, error) {
	if err := s.Repo.RemoveUserJoinsInTrip(ctx, tripID, userID); err != nil {
		return nil, err
	}

	offers, err := s.Repo.ListCreatedByUserInTrip(ctx, tripID, userID)
	if err != nil {
		return nil, err
	}

	var alerted []uuid.UUID
	for _, offer := range offers {
		joinedUserIDs, err := s.Repo.ListJoins(ctx, offer.ID)
		if err != nil {
			return nil, err
		}
		if err := s.Repo.DeleteOffer(ctx, offer.ID); err != nil {
			return nil, err
		}
		if len(joinedUserIDs) > 0 {
			if err := s.Repo.CreateAlerts(ctx, tripID, joinedUserIDs); err != nil {
				return nil, err
			}
			alerted = append(alerted, joinedUserIDs...)
		}
	}
	return alerted, nil
}

func (s *Service) HasAlert(ctx context.Context, tripID, userID uuid.UUID) (bool, error) {
	return s.Repo.HasAlert(ctx, tripID, userID)
}

func (s *Service) ClearAlert(ctx context.Context, tripID, userID uuid.UUID) error {
	return s.Repo.ClearAlert(ctx, tripID, userID)
}

func (s *Service) MarkRead(ctx context.Context, offerID, userID uuid.UUID) error {
	return s.Repo.MarkRead(ctx, offerID, userID)
}
