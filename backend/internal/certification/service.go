package certification

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

func (s *Service) AddSpecialty(ctx context.Context, userID uuid.UUID, params CreateParams) (Specialty, error) {
	params.Specialty = strings.TrimSpace(params.Specialty)
	if params.Specialty == "" {
		return Specialty{}, ErrInvalidArgument
	}
	return s.Repo.Create(ctx, userID, params)
}

func (s *Service) ListSpecialties(ctx context.Context, userID uuid.UUID) ([]Specialty, error) {
	return s.Repo.ListByUser(ctx, userID)
}

func (s *Service) RemoveSpecialty(ctx context.Context, userID, id uuid.UUID) (bool, error) {
	return s.Repo.Delete(ctx, userID, id)
}
