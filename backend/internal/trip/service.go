package trip

import (
	"context"
	"errors"
	"strings"

	"divebubble_be/internal/divecenter"

	"github.com/google/uuid"
)

var ErrInvalidArgument = errors.New("invalid argument")
var ErrOrganizerCannotLeave = errors.New("organizer cannot leave their own trip")
var ErrOnlyOrganizerCanCancel = errors.New("only the organizer can cancel this trip")
var ErrOnlyOrganizerCanEditTrip = errors.New("only the organizer can edit this trip")
var ErrTripNotOpen = errors.New("trip is not open")
var ErrTripCancelled = errors.New("trip has been cancelled")
var ErrNotDiveCenterMember = errors.New("not a member of that dive center")

type Service struct {
	Repo          *Repository
	DiveCenterSvc *divecenter.Service
}

func NewService(repo *Repository, diveCenterSvc *divecenter.Service) *Service {
	return &Service{Repo: repo, DiveCenterSvc: diveCenterSvc}
}

// isOrganizer reports whether userID can act as this trip's organizer — either they
// created it personally, or the trip is run by a dive center they're a member of (any
// member, not just the staff member who happened to create it — the organization is the
// organizer, not one specific employee; see CLAUDE.md's Business/dive-center section).
func (s *Service) isOrganizer(ctx context.Context, t Trip, userID uuid.UUID) (bool, error) {
	if t.CreatorUserID.Valid && t.CreatorUserID.UUID == userID {
		return true, nil
	}
	if t.DiveCenterID.Valid && s.DiveCenterSvc != nil {
		return s.DiveCenterSvc.IsMember(ctx, t.DiveCenterID.UUID, userID)
	}
	return false, nil
}

// HasAccess is the general "can this user read/write inside this trip" check — either
// they've joined normally (a trip_participants row) or they're the trip's organizer.
// Dive-center staff never get a trip_participants row for the center's own trips (see
// CreateTrip below), so without the organizer branch here they'd be locked out of their
// own business's chat/transport.
func (s *Service) HasAccess(ctx context.Context, id string, userID uuid.UUID) (uuid.UUID, bool, error) {
	tripID, err := uuid.Parse(id)
	if err != nil {
		return uuid.Nil, false, ErrInvalidArgument
	}
	joined, err := s.Repo.IsJoined(ctx, tripID, userID)
	if err != nil {
		return uuid.Nil, false, err
	}
	if joined {
		return tripID, true, nil
	}
	t, err := s.Repo.GetByID(ctx, tripID)
	if err != nil {
		return uuid.Nil, false, err
	}
	isOrg, err := s.isOrganizer(ctx, t, userID)
	return tripID, isOrg, err
}

func (s *Service) CreateTrip(ctx context.Context, p CreateParams) (Trip, error) {
	p.Title = strings.TrimSpace(p.Title)
	p.Location = strings.TrimSpace(p.Location)
	if p.Title == "" || p.Location == "" || p.StartTime.IsZero() {
		return Trip{}, ErrInvalidArgument
	}
	if p.EndDate != nil && p.EndDate.Before(p.StartTime) {
		return Trip{}, ErrInvalidArgument
	}
	if p.DiveCenterID != nil {
		if s.DiveCenterSvc == nil {
			return Trip{}, ErrInvalidArgument
		}
		isMember, err := s.DiveCenterSvc.IsMember(ctx, *p.DiveCenterID, p.CreatorUserID)
		if err != nil {
			return Trip{}, err
		}
		if !isMember {
			return Trip{}, ErrNotDiveCenterMember
		}
	}
	t, err := s.Repo.Create(ctx, p)
	if err != nil {
		return Trip{}, err
	}
	// Individual trips auto-join their creator (no separate Join step — it's what makes
	// the trip show up in their own Bubbles tab immediately). Business trips skip this
	// deliberately: staff reach the trip via dive-center membership (see HasAccess/
	// isOrganizer above and ListJoinedByUser's dive_center_members branch), the same way
	// regardless of which specific staff member created it — a trip_participants row for
	// just the creator would be redundant and would need to be kept in sync with staffing
	// changes for no benefit.
	if p.DiveCenterID == nil {
		if err := s.Repo.Join(ctx, t.ID, p.CreatorUserID); err != nil {
			return Trip{}, err
		}
	}
	return t, nil
}

func (s *Service) ListTrips(ctx context.Context) ([]Trip, error) {
	return s.Repo.List(ctx)
}

func (s *Service) GetTrip(ctx context.Context, id string) (Trip, error) {
	tripID, err := uuid.Parse(id)
	if err != nil {
		return Trip{}, ErrInvalidArgument
	}
	return s.Repo.GetByID(ctx, tripID)
}

func (s *Service) Join(ctx context.Context, id string, userID uuid.UUID) error {
	tripID, err := uuid.Parse(id)
	if err != nil {
		return ErrInvalidArgument
	}
	t, err := s.Repo.GetByID(ctx, tripID)
	if err != nil {
		return err
	}
	// The client already hides the Join button once bookingStatus isn't "open" (full or
	// cancelled) — this closes the same gap server-side, since that was previously only a
	// client-side convention with no backend enforcement behind it.
	if t.BookingStatus != "open" {
		return ErrTripNotOpen
	}
	return s.Repo.Join(ctx, tripID, userID)
}

// Leave rejects the trip's organizer — other participants are relying on them, so their
// way out is cancelling the trip (booking_status), not quietly disappearing from it.
func (s *Service) Leave(ctx context.Context, id string, userID uuid.UUID) error {
	tripID, err := uuid.Parse(id)
	if err != nil {
		return ErrInvalidArgument
	}
	t, err := s.Repo.GetByID(ctx, tripID)
	if err != nil {
		return err
	}
	if t.CreatorUserID.Valid && t.CreatorUserID.UUID == userID {
		return ErrOrganizerCannotLeave
	}
	return s.Repo.Leave(ctx, tripID, userID)
}

// Cancel is organizer-only and, once set, final — there's no reopen path (an organizer
// who cancelled by mistake creates a new trip rather than walking back a public
// cancellation). Idempotent: cancelling an already-cancelled trip is a no-op success.
func (s *Service) Cancel(ctx context.Context, id string, userID uuid.UUID) error {
	tripID, err := uuid.Parse(id)
	if err != nil {
		return ErrInvalidArgument
	}
	t, err := s.Repo.GetByID(ctx, tripID)
	if err != nil {
		return err
	}
	ok, err := s.isOrganizer(ctx, t, userID)
	if err != nil {
		return err
	}
	if !ok {
		return ErrOnlyOrganizerCanCancel
	}
	if t.BookingStatus == "cancelled" {
		return nil
	}
	return s.Repo.SetBookingStatus(ctx, tripID, "cancelled")
}

// SetPhotoURL is organizer-only — matches Cancel's ownership check, since nothing about a
// trip other than its photo is editable yet either.
func (s *Service) SetPhotoURL(ctx context.Context, id string, userID uuid.UUID, url string) error {
	tripID, err := uuid.Parse(id)
	if err != nil {
		return ErrInvalidArgument
	}
	t, err := s.Repo.GetByID(ctx, tripID)
	if err != nil {
		return err
	}
	ok, err := s.isOrganizer(ctx, t, userID)
	if err != nil {
		return err
	}
	if !ok {
		return ErrOnlyOrganizerCanEditTrip
	}
	return s.Repo.SetPhotoURL(ctx, tripID, url)
}

// EnsureNotCancelled is the shared guard for actions that freeze once a trip is
// cancelled — sending a message, creating or joining a transport offer — while everything
// read-only (message history, transport list, participants) stays reachable.
func (s *Service) EnsureNotCancelled(ctx context.Context, tripID uuid.UUID) error {
	t, err := s.Repo.GetByID(ctx, tripID)
	if err != nil {
		return err
	}
	if t.BookingStatus == "cancelled" {
		return ErrTripCancelled
	}
	return nil
}

func (s *Service) ListParticipantUserIDs(ctx context.Context, id string) ([]uuid.UUID, error) {
	tripID, err := uuid.Parse(id)
	if err != nil {
		return nil, ErrInvalidArgument
	}
	return s.Repo.ListParticipantUserIDs(ctx, tripID)
}

func (s *Service) IsJoined(ctx context.Context, id string, userID uuid.UUID) (bool, error) {
	tripID, err := uuid.Parse(id)
	if err != nil {
		return false, ErrInvalidArgument
	}
	return s.Repo.IsJoined(ctx, tripID, userID)
}

func (s *Service) ListJoinedByUser(ctx context.Context, userID uuid.UUID) ([]Trip, error) {
	return s.Repo.ListJoinedByUser(ctx, userID)
}

func (s *Service) CountParticipants(ctx context.Context, tripID uuid.UUID) (int, error) {
	return s.Repo.CountParticipants(ctx, tripID)
}

func (s *Service) MarkRead(ctx context.Context, id string, userID uuid.UUID) error {
	tripID, err := uuid.Parse(id)
	if err != nil {
		return ErrInvalidArgument
	}
	return s.Repo.MarkRead(ctx, tripID, userID)
}
