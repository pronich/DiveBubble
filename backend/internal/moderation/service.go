package moderation

import (
	"context"
	"errors"
	"strings"

	"github.com/google/uuid"
)

var ErrInvalidArgument = errors.New("invalid argument")
var ErrCannotBlockSelf = errors.New("cannot block yourself")

type Service struct {
	Repo *Repository
}

func NewService(repo *Repository) *Service {
	return &Service{Repo: repo}
}

func (s *Service) ReportMessage(ctx context.Context, reporterID, messageID, tripID uuid.UUID, reason, details string) (Report, error) {
	reason = strings.TrimSpace(reason)
	if reason == "" {
		return Report{}, ErrInvalidArgument
	}
	return s.Repo.CreateReport(ctx, reporterID, messageID, tripID, reason, strings.TrimSpace(details))
}

func (s *Service) BlockUser(ctx context.Context, blockerID, blockedID uuid.UUID) error {
	if blockerID == blockedID {
		return ErrCannotBlockSelf
	}
	return s.Repo.CreateBlock(ctx, blockerID, blockedID)
}

func (s *Service) UnblockUser(ctx context.Context, blockerID, blockedID uuid.UUID) error {
	return s.Repo.DeleteBlock(ctx, blockerID, blockedID)
}

func (s *Service) ListBlockedUserIDs(ctx context.Context, blockerID uuid.UUID) ([]uuid.UUID, error) {
	return s.Repo.ListBlockedUserIDs(ctx, blockerID)
}
