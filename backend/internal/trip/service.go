package trip

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
)

var ErrInvalidArgument = errors.New("invalid argument")

type Service struct {
	Repo *Repository
}

func NewService(repo *Repository) *Service {
	return &Service{Repo: repo}
}

func (s *Service) CreateTrip(ctx context.Context, title, location string, startTime time.Time) (Trip, error) {
	title = strings.TrimSpace(title)
	location = strings.TrimSpace(location)
	if title == "" || location == "" || startTime.IsZero() {
		return Trip{}, ErrInvalidArgument
	}
	return s.Repo.Create(ctx, title, location, startTime)
}

func (s *Service) ListTrips(ctx context.Context) ([]Trip, error) {
	return s.Repo.List(ctx)
}

func (s *Service) GetTrip(ctx context.Context, id string) (Trip, error) {
	tripID, err := uuid.Parse(id)
	if err != nil {
		return Trip{}, ErrInvalidArgument
	}
	return s.Repo.GetByID(ctx, tripID)
}

func (s *Service) Join(ctx context.Context, id string, userID uuid.UUID) error {
	tripID, err := uuid.Parse(id)
	if err != nil {
		return ErrInvalidArgument
	}
	if _, err := s.Repo.GetByID(ctx, tripID); err != nil {
		return err
	}
	return s.Repo.Join(ctx, tripID, userID)
}

func (s *Service) IsJoined(ctx context.Context, id string, userID uuid.UUID) (bool, error) {
	tripID, err := uuid.Parse(id)
	if err != nil {
		return false, ErrInvalidArgument
	}
	return s.Repo.IsJoined(ctx, tripID, userID)
}
