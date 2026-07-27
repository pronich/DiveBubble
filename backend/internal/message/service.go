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

// SendSystem creates a system message of the given kind for the trip, unless one has already
// been sent — sent is false when it was skipped, so callers know not to publish/notify again.
func (s *Service) SendSystem(ctx context.Context, tripID uuid.UUID, kind, body string) (msg Message, sent bool, err error) {
	exists, err := s.Repo.ExistsByTripAndKind(ctx, tripID, kind)
	if err != nil {
		return Message{}, false, err
	}
	if exists {
		return Message{}, false, nil
	}
	msg, err = s.Repo.CreateSystem(ctx, tripID, kind, body)
	if err != nil {
		return Message{}, false, err
	}
	return msg, true, nil
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
