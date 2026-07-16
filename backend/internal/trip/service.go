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
var ErrRequiresBookingCode = errors.New("this trip requires a booking code to join")
var ErrInvalidBookingCode = errors.New("invalid booking code")
var ErrTooManyPhotos = errors.New("trip already has the maximum number of photos")

const maxBookingCodeAttempts = 5

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
	// Business trips get a server-generated code, retried on the rare unique-constraint
	// collision — never client-supplied, since the whole point is that only the dive
	// center (via this trip's own creation) controls who can redeem it. Individual trips
	// never get one: direct Join stays open for them (see Join below).
	var t Trip
	var err error
	if p.DiveCenterID != nil {
		for attempt := 0; attempt < maxBookingCodeAttempts; attempt++ {
			code := generateBookingCode()
			p.BookingCode = &code
			t, err = s.Repo.Create(ctx, p)
			if err == nil || !uniqueViolation(err) {
				break
			}
		}
	} else {
		t, err = s.Repo.Create(ctx, p)
	}
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
	// Business trips are a marketplace listing, not a direct join — a diver has to actually
	// pay on the dive center's own site and come back with the code it gave them (see
	// JoinByCode below). Rejecting this server-side (not just hiding the button) matters:
	// nothing stops a diver from calling this endpoint directly otherwise.
	if t.DiveCenterID.Valid {
		return ErrRequiresBookingCode
	}
	return s.Repo.Join(ctx, tripID, userID)
}

// JoinByCode resolves a trip purely from its booking code — no trip id needed, since the
// code alone is what a diver actually has in hand after paying externally (see Explore's
// "Join trip" entry point, which doesn't know which trip in advance either).
func (s *Service) JoinByCode(ctx context.Context, code string, userID uuid.UUID) (Trip, error) {
	code = strings.ToUpper(strings.TrimSpace(code))
	if code == "" {
		return Trip{}, ErrInvalidArgument
	}
	t, err := s.Repo.GetByBookingCode(ctx, code)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			return Trip{}, ErrInvalidBookingCode
		}
		return Trip{}, err
	}
	if t.BookingStatus != "open" {
		return Trip{}, ErrTripNotOpen
	}
	if err := s.Repo.Join(ctx, t.ID, userID); err != nil {
		return Trip{}, err
	}
	return t, nil
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

// ListPhotos has no organizer gate — a trip's gallery is shown to anyone viewing the trip
// (same posture as GetTrip), only adding/removing is restricted.
func (s *Service) ListPhotos(ctx context.Context, id string) ([]Photo, error) {
	tripID, err := uuid.Parse(id)
	if err != nil {
		return nil, ErrInvalidArgument
	}
	return s.Repo.ListPhotos(ctx, tripID)
}

// AddPhoto is organizer-only (same ownership check as Update below) and caps the gallery at
// MaxPhotosPerTrip — enforced here, not in the repository, so the check-then-insert reads as
// one clear business rule rather than being buried in a SQL constraint.
func (s *Service) AddPhoto(ctx context.Context, id string, userID uuid.UUID, url string) (Photo, error) {
	tripID, err := uuid.Parse(id)
	if err != nil {
		return Photo{}, ErrInvalidArgument
	}
	t, err := s.Repo.GetByID(ctx, tripID)
	if err != nil {
		return Photo{}, err
	}
	ok, err := s.isOrganizer(ctx, t, userID)
	if err != nil {
		return Photo{}, err
	}
	if !ok {
		return Photo{}, ErrOnlyOrganizerCanEditTrip
	}
	count, err := s.Repo.CountPhotos(ctx, tripID)
	if err != nil {
		return Photo{}, err
	}
	if count >= MaxPhotosPerTrip {
		return Photo{}, ErrTooManyPhotos
	}
	return s.Repo.AddPhoto(ctx, tripID, url)
}

// RemovePhoto is organizer-only — same ownership check as AddPhoto.
func (s *Service) RemovePhoto(ctx context.Context, id string, userID uuid.UUID, photoID uuid.UUID) error {
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
	return s.Repo.RemovePhoto(ctx, tripID, photoID)
}

// Update is organizer-only (same isOrganizer check as Cancel/SetPhotoURL — any dive-center
// member, not just the trip's literal creator). Trims/validates Title and Location the
// same way CreateTrip does, since a blank one would slip through Repository.Update's
// COALESCE(nil-is-untouched) semantics if not caught here first — an empty *string* isn't
// nil, so it would overwrite the field with blank rather than leaving it alone.
func (s *Service) Update(ctx context.Context, id string, userID uuid.UUID, p UpdateParams) (Trip, error) {
	tripID, err := uuid.Parse(id)
	if err != nil {
		return Trip{}, ErrInvalidArgument
	}
	t, err := s.Repo.GetByID(ctx, tripID)
	if err != nil {
		return Trip{}, err
	}
	ok, err := s.isOrganizer(ctx, t, userID)
	if err != nil {
		return Trip{}, err
	}
	if !ok {
		return Trip{}, ErrOnlyOrganizerCanEditTrip
	}
	if p.Title != nil {
		trimmed := strings.TrimSpace(*p.Title)
		if trimmed == "" {
			return Trip{}, ErrInvalidArgument
		}
		p.Title = &trimmed
	}
	if p.Location != nil {
		trimmed := strings.TrimSpace(*p.Location)
		if trimmed == "" {
			return Trip{}, ErrInvalidArgument
		}
		p.Location = &trimmed
	}
	return s.Repo.Update(ctx, tripID, p)
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
