package message

import (
	"context"
	"database/sql"
	"errors"
	"strings"

	"github.com/google/uuid"
)

var ErrInvalidArgument = errors.New("invalid argument")
var ErrNotFound = errors.New("message not found")

type Service struct {
	Repo *Repository
}

func NewService(repo *Repository) *Service {
	return &Service{Repo: repo}
}

func (s *Service) Send(ctx context.Context, tripID, userID uuid.UUID, body string, mentionsDiveCenter bool) (Message, error) {
	body = strings.TrimSpace(body)
	if body == "" {
		return Message{}, ErrInvalidArgument
	}
	return s.Repo.Create(ctx, tripID, userID, body, mentionsDiveCenter)
}

func (s *Service) List(ctx context.Context, tripID uuid.UUID) ([]Message, error) {
	return s.Repo.ListByTrip(ctx, tripID)
}

func (s *Service) GetByID(ctx context.Context, id uuid.UUID) (Message, error) {
	m, err := s.Repo.GetByID(ctx, id)
	if errors.Is(err, sql.ErrNoRows) {
		return Message{}, ErrNotFound
	}
	return m, err
}
