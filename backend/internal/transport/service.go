package transport

import (
	"context"
	"errors"
	"strings"

	"github.com/google/uuid"
)

var ErrInvalidArgument = errors.New("invalid argument")

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

func (s *Service) List(ctx context.Context, tripID uuid.UUID) ([]Offer, error) {
	return s.Repo.ListByTrip(ctx, tripID)
}
