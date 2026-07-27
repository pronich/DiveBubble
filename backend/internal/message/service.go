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

// Send persists a user-authored message. offerID is the zero value (invalid) for the trip's
// main chat, or set for a car offer's own chat.
func (s *Service) Send(ctx context.Context, tripID, userID uuid.UUID, offerID uuid.NullUUID, body string, mentionsDiveCenter bool) (Message, error) {
	body = strings.TrimSpace(body)
	if body == "" {
		return Message{}, ErrInvalidArgument
	}
	return s.Repo.Create(ctx, tripID, userID, offerID, body, mentionsDiveCenter)
}

// SendSystem creates a system message of the given kind for the trip's main chat, unless one
// has already been sent — sent is false when it was skipped, so callers know not to
// publish/notify again. Only fits a "once per trip" system kind (e.g. the feedback prompt);
// see PostSystemEvent for kinds that repeat (e.g. one per car-offer join).
func (s *Service) SendSystem(ctx context.Context, tripID uuid.UUID, kind, body string) (msg Message, sent bool, err error) {
	exists, err := s.Repo.ExistsByTripAndKind(ctx, tripID, kind)
	if err != nil {
		return Message{}, false, err
	}
	if exists {
		return Message{}, false, nil
	}
	msg, err = s.Repo.CreateSystem(ctx, tripID, uuid.NullUUID{}, kind, body)
	if err != nil {
		return Message{}, false, err
	}
	return msg, true, nil
}

// PostSystemEvent always inserts a system message — unlike SendSystem, it has no "only once
// per trip" idempotency check, since events like a car-offer join are expected to repeat.
func (s *Service) PostSystemEvent(ctx context.Context, tripID uuid.UUID, offerID uuid.NullUUID, kind, body string) (Message, error) {
	return s.Repo.CreateSystem(ctx, tripID, offerID, kind, body)
}

func (s *Service) List(ctx context.Context, tripID uuid.UUID) ([]Message, error) {
	return s.Repo.ListByTrip(ctx, tripID)
}

func (s *Service) ListByOffer(ctx context.Context, offerID uuid.UUID) ([]Message, error) {
	return s.Repo.ListByOffer(ctx, offerID)
}

func (s *Service) GetByID(ctx context.Context, id uuid.UUID) (Message, error) {
	m, err := s.Repo.GetByID(ctx, id)
	if errors.Is(err, sql.ErrNoRows) {
		return Message{}, ErrNotFound
	}
	return m, err
}
