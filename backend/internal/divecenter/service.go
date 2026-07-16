package divecenter

import (
	"context"
	"errors"
	"strings"

	"github.com/google/uuid"
)

var ErrInvalidArgument = errors.New("invalid argument")
var ErrOnlyOwner = errors.New("only an owner can perform this action")
var ErrCannotRemoveLastOwner = errors.New("cannot remove the last owner")
var ErrNotAMember = errors.New("not a member of this dive center")

type Service struct {
	Repo *Repository
}

func NewService(repo *Repository) *Service {
	return &Service{Repo: repo}
}

func (s *Service) Create(ctx context.Context, p CreateParams, ownerUserID uuid.UUID) (DiveCenter, error) {
	p.Name = strings.TrimSpace(p.Name)
	if p.Name == "" {
		return DiveCenter{}, ErrInvalidArgument
	}
	return s.Repo.Create(ctx, p, ownerUserID)
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

// SetLogoURL is owner-only — matches trip.Service.SetPhotoURL's ownership posture.
func (s *Service) SetLogoURL(ctx context.Context, id, callerID uuid.UUID, url string) error {
	isOwner, err := s.Repo.IsOwner(ctx, id, callerID)
	if err != nil {
		return err
	}
	if !isOwner {
		return ErrOnlyOwner
	}
	return s.Repo.SetLogoURL(ctx, id, url)
}

// Update is owner-only — same ownership posture as SetLogoURL, since both are edits to the
// business's own public profile. Name is trimmed/validated same as Create when present,
// since an empty *string* would otherwise slip through Repository.Update's
// COALESCE(nil-is-untouched) semantics and blank out a required field.
func (s *Service) Update(ctx context.Context, id, callerID uuid.UUID, p UpdateParams) (DiveCenter, error) {
	isOwner, err := s.Repo.IsOwner(ctx, id, callerID)
	if err != nil {
		return DiveCenter{}, err
	}
	if !isOwner {
		return DiveCenter{}, ErrOnlyOwner
	}
	if p.Name != nil {
		trimmed := strings.TrimSpace(*p.Name)
		if trimmed == "" {
			return DiveCenter{}, ErrInvalidArgument
		}
		p.Name = &trimmed
	}
	return s.Repo.Update(ctx, id, p)
}

// ListMembers is member-gated (any role) — staff can see their own roster, not just owners.
func (s *Service) ListMembers(ctx context.Context, diveCenterID, callerID uuid.UUID) ([]MemberView, error) {
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
		return Member{}, ErrOnlyOwner
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
		return ErrOnlyOwner
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
