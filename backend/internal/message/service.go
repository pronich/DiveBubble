package message

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

func (s *Service) Send(ctx context.Context, tripID, userID uuid.UUID, body string) (Message, error) {
	body = strings.TrimSpace(body)
	if body == "" {
		return Message{}, ErrInvalidArgument
	}
	return s.Repo.Create(ctx, tripID, userID, body)
}

func (s *Service) List(ctx context.Context, tripID uuid.UUID) ([]Message, error) {
	return s.Repo.ListByTrip(ctx, tripID)
}
