package divecenter

import (
	"context"
	"errors"
	"strings"

	"github.com/google/uuid"
)

var ErrInvalidArgument = errors.New("invalid argument")
var ErrOnlyOwnerCanManageMembers = errors.New("only an owner can manage members")
var ErrCannotRemoveLastOwner = errors.New("cannot remove the last owner")
var ErrNotAMember = errors.New("not a member of this dive center")

type Service struct {
	Repo *Repository
}

func NewService(repo *Repository) *Service {
	return &Service{Repo: repo}
}

func (s *Service) Create(ctx context.Context, name string, ownerUserID uuid.UUID) (DiveCenter, error) {
	name = strings.TrimSpace(name)
	if name == "" {
		return DiveCenter{}, ErrInvalidArgument
	}
	return s.Repo.Create(ctx, name, ownerUserID)
}

func (s *Service) Get(ctx context.Context, id uuid.UUID) (DiveCenter, error) {
	return s.Repo.GetByID(ctx, id)
}

func (s *Service) ListMine(ctx context.Context, userID uuid.UUID) ([]MembershipView, error) {
	return s.Repo.ListByUser(ctx, userID)
}

func (s *Service) IsMember(ctx context.Context, diveCenterID, userID uuid.UUID) (bool, error) {
	return s.Repo.IsMember(ctx, diveCenterID, userID)
}

func (s *Service) IsOwner(ctx context.Context, diveCenterID, userID uuid.UUID) (bool, error) {
	return s.Repo.IsOwner(ctx, diveCenterID, userID)
}

// ListMembers is member-gated (any role) — staff can see their own roster, not just owners.
func (s *Service) ListMembers(ctx context.Context, diveCenterID, callerID uuid.UUID) ([]Member, error) {
	isMember, err := s.Repo.IsMember(ctx, diveCenterID, callerID)
	if err != nil {
		return nil, err
	}
	if !isMember {
		return nil, ErrNotAMember
	}
	return s.Repo.ListMembers(ctx, diveCenterID)
}

// AddMember is owner-only. role is forced to "staff" unless explicitly "owner" — anything
// else invalid silently downgrades rather than erroring, since the DB CHECK constraint
// would reject bad values anyway and this is a friendlier failure mode for the common case.
func (s *Service) AddMember(ctx context.Context, diveCenterID, callerID, targetUserID uuid.UUID, role string) (Member, error) {
	isOwner, err := s.Repo.IsOwner(ctx, diveCenterID, callerID)
	if err != nil {
		return Member{}, err
	}
	if !isOwner {
		return Member{}, ErrOnlyOwnerCanManageMembers
	}
	if role != "owner" {
		role = "staff"
	}
	return s.Repo.AddMember(ctx, diveCenterID, targetUserID, role)
}

// RemoveMember is owner-only, and refuses to remove the last remaining owner — a dive
// center with zero owners would have no one left who could add another.
func (s *Service) RemoveMember(ctx context.Context, diveCenterID, callerID, targetUserID uuid.UUID) error {
	isOwner, err := s.Repo.IsOwner(ctx, diveCenterID, callerID)
	if err != nil {
		return err
	}
	if !isOwner {
		return ErrOnlyOwnerCanManageMembers
	}

	targetIsOwner, err := s.Repo.IsOwner(ctx, diveCenterID, targetUserID)
	if err != nil {
		return err
	}
	if targetIsOwner {
		count, err := s.Repo.CountOwners(ctx, diveCenterID)
		if err != nil {
			return err
		}
		if count <= 1 {
			return ErrCannotRemoveLastOwner
		}
	}

	found, err := s.Repo.RemoveMember(ctx, diveCenterID, targetUserID)
	if err != nil {
		return err
	}
	if !found {
		return ErrNotAMember
	}
	return nil
}
