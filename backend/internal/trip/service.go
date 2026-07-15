package trip

import (
	"context"
	"errors"
	"strings"

	"github.com/google/uuid"
)

var ErrInvalidArgument = errors.New("invalid argument")
var ErrOrganizerCannotLeave = errors.New("organizer cannot leave their own trip")

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
	t, err := s.Repo.Create(ctx, p)
	if err != nil {
		return Trip{}, err
	}
	// The organizer is a participant of their own trip from the start — no separate Join
	// step, and it's what makes the trip show up under their own Bubbles tab immediately.
	if err := s.Repo.Join(ctx, t.ID, p.CreatorUserID); err != nil {
		return Trip{}, err
	}
	return t, nil
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

// Leave rejects the trip's organizer — other participants are relying on them, so their
// way out is cancelling the trip (booking_status), not quietly disappearing from it.
func (s *Service) Leave(ctx context.Context, id string, userID uuid.UUID) error {
	tripID, err := uuid.Parse(id)
	if err != nil {
		return ErrInvalidArgument
	}
	t, err := s.Repo.GetByID(ctx, tripID)
	if err != nil {
		return err
	}
	if t.CreatorUserID.Valid && t.CreatorUserID.UUID == userID {
		return ErrOrganizerCannotLeave
	}
	return s.Repo.Leave(ctx, tripID, userID)
}

func (s *Service) ListParticipantUserIDs(ctx context.Context, id string) ([]uuid.UUID, error) {
	tripID, err := uuid.Parse(id)
	if err != nil {
		return nil, ErrInvalidArgument
	}
	return s.Repo.ListParticipantUserIDs(ctx, tripID)
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

func (s *Service) MarkRead(ctx context.Context, id string, userID uuid.UUID) error {
	tripID, err := uuid.Parse(id)
	if err != nil {
		return ErrInvalidArgument
	}
	return s.Repo.MarkRead(ctx, tripID, userID)
}
