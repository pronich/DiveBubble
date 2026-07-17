package profile

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

func (s *Service) Get(ctx context.Context, userID uuid.UUID) (Profile, error) {
	return s.Repo.Get(ctx, userID)
}

func (s *Service) Update(ctx context.Context, userID uuid.UUID, params UpdateParams) (Profile, error) {
	return s.Repo.Update(ctx, userID, params)
}

func (s *Service) ClearAvatar(ctx context.Context, userID uuid.UUID) (Profile, error) {
	return s.Repo.ClearAvatar(ctx, userID)
}
