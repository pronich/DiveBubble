package account

import (
	"context"

	"github.com/google/uuid"
)

type Service struct {
	Repo *Repository
}

func NewService(repo *Repository) *Service {
	return &Service{Repo: repo}
}

func (s *Service) DeleteAccount(ctx context.Context, userID uuid.UUID) error {
	return s.Repo.DeleteAccount(ctx, userID)
}
