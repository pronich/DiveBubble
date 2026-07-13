package user

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

func (s *Service) GetOrCreate(ctx context.Context, id uuid.UUID) (User, error) {
	return s.Repo.GetOrCreate(ctx, id)
}
