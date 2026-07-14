package trip

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

func (s *Service) CreateTrip(ctx context.Context, p CreateParams) (Trip, error) {
	p.Title = strings.TrimSpace(p.Title)
	p.Location = strings.TrimSpace(p.Location)
	if p.Title == "" || p.Location == "" || p.StartTime.IsZero() {
		return Trip{}, ErrInvalidArgument
	}
	if p.EndDate != nil && p.EndDate.Before(p.StartTime) {
		return Trip{}, ErrInvalidArgument
	}
	return s.Repo.Create(ctx, p)
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

func (s *Service) ListJoinedByUser(ctx context.Context, userID uuid.UUID) ([]Trip, error) {
	return s.Repo.ListJoinedByUser(ctx, userID)
}

func (s *Service) CountParticipants(ctx context.Context, tripID uuid.UUID) (int, error) {
	return s.Repo.CountParticipants(ctx, tripID)
}
