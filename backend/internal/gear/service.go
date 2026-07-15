package gear

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

func (s *Service) List(ctx context.Context, userID uuid.UUID) ([]Ownership, error) {
	return s.Repo.ListByUser(ctx, userID)
}

func (s *Service) SetStatus(ctx context.Context, userID uuid.UUID, itemKey, status string) (Ownership, error) {
	itemKey = strings.TrimSpace(itemKey)
	status = strings.TrimSpace(status)
	if itemKey == "" || status == "" {
		return Ownership{}, ErrInvalidArgument
	}
	return s.Repo.Upsert(ctx, userID, itemKey, status)
}

func (s *Service) Remove(ctx context.Context, userID uuid.UUID, itemKey string) (bool, error) {
	itemKey = strings.TrimSpace(itemKey)
	if itemKey == "" {
		return false, ErrInvalidArgument
	}
	return s.Repo.Delete(ctx, userID, itemKey)
}
