package trip

import (
	"context"
	"database/sql"
	"errors"
	"strings"
	"time"

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
var ErrBusinessTripRequiresPriceAndURL = errors.New("business trips require a price and a booking URL")
var ErrEndDateBeforeStart = errors.New("end date is before the start date")

const maxBookingCodeAttempts = 5

type Service struct {
	Repo          *Repository
	DiveCenterSvc *divecenter.Service
}

func NewService(repo *Repository, diveCenterSvc *divecenter.Service) *Service {
	return &Service{Repo: repo, DiveCenterSvc: diveCenterSvc}
}

// isOrganizer treats any member of the trip's dive center as the organizer, not just whichever staff member happened to create it.
func (s *Service) isOrganizer(ctx context.Context, t Trip, userID uuid.UUID) (bool, error) {
	if t.CreatorUserID.Valid && t.CreatorUserID.UUID == userID {
		return true, nil
	}
	if t.DiveCenterID.Valid && s.DiveCenterSvc != nil {
		return s.DiveCenterSvc.IsMember(ctx, t.DiveCenterID.UUID, userID)
	}
	return false, nil
}

// HasAccess needs the organizer branch since dive-center staff never get a trip_participants row for their own business's trips.
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
	// Compares calendar dates, not exact instants, since EndDate is always midnight UTC and a raw .Before() would wrongly reject a same-day trip.
	if p.EndDate != nil {
		endDate := time.Date(p.EndDate.Year(), p.EndDate.Month(), p.EndDate.Day(), 0, 0, 0, 0, time.UTC)
		startDate := time.Date(p.StartTime.Year(), p.StartTime.Month(), p.StartTime.Day(), 0, 0, 0, 0, time.UTC)
		if endDate.Before(startDate) {
			return Trip{}, ErrEndDateBeforeStart
		}
	}
	if p.DiveCenterID != nil {
		// A business trip is always a public marketplace listing; is_private only means anything for an individual trip.
		p.IsPrivate = false
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
		// A diver books externally on the dive center's own site, so without a price and a link the listing has nothing for a diver to act on.
		if p.PriceMinor == nil {
			return Trip{}, ErrBusinessTripRequiresPriceAndURL
		}
		if p.BookingURL != nil {
			trimmed := strings.TrimSpace(*p.BookingURL)
			p.BookingURL = &trimmed
		}
		if p.BookingURL == nil || *p.BookingURL == "" {
			return Trip{}, ErrBusinessTripRequiresPriceAndURL
		}
	}
	// Every trip gets a server-generated code, retried on collision, backing the invite link that's the only way into a business or private trip.
	var t Trip
	var err error
	for attempt := 0; attempt < maxBookingCodeAttempts; attempt++ {
		code := generateBookingCode()
		p.BookingCode = &code
		t, err = s.Repo.Create(ctx, p)
		if err == nil || !uniqueViolation(err) {
			break
		}
	}
	if err != nil {
		return Trip{}, err
	}
	// Business trips skip auto-joining their creator, since staff reach the trip via dive-center membership instead, and a creator-only row would need syncing with staffing changes for no benefit.
	if p.DiveCenterID == nil {
		if err := s.Repo.Join(ctx, t.ID, p.CreatorUserID); err != nil {
			return Trip{}, err
		}
	}
	return t, nil
}

func (s *Service) ListTrips(ctx context.Context, query string, viewerIsOwner bool) ([]Trip, error) {
	return s.Repo.List(ctx, strings.TrimSpace(query), viewerIsOwner)
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
	// Closes server-side what was previously only a client-side convention (hiding the Join button).
	if t.BookingStatus != "open" {
		return ErrTripNotOpen
	}
	// Business trips require paying externally and returning with a code (see JoinByCode); private trips reuse the same code gate since they're excluded from Explore.
	if t.DiveCenterID.Valid || t.IsPrivate {
		return ErrRequiresBookingCode
	}
	return s.Repo.Join(ctx, tripID, userID)
}

// ResolveByCode deliberately doesn't check BookingStatus, since a cancelled/full trip should still preview with its real status rather than 404, and Join/JoinByCode re-check status before actually joining.
func (s *Service) ResolveByCode(ctx context.Context, code string) (Trip, error) {
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
	return t, nil
}

// JoinByCode needs no trip id, since the code alone is what a diver has in hand after paying externally.
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

// Leave rejects the trip's organizer, whose way out is cancelling the trip, not quietly disappearing from it.
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

// Cancel is final with no reopen path; an organizer who cancelled by mistake creates a new trip instead.
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

// ListPhotos has no organizer gate, same posture as GetTrip; only adding/removing is restricted.
func (s *Service) ListPhotos(ctx context.Context, id string) ([]Photo, error) {
	tripID, err := uuid.Parse(id)
	if err != nil {
		return nil, ErrInvalidArgument
	}
	return s.Repo.ListPhotos(ctx, tripID)
}

// AddPhoto caps the gallery at MaxPhotosPerTrip here, not in the repository, so the check-then-insert reads as one clear business rule.
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

// Update trims/validates Title and Location itself, since an empty (non-nil) *string would otherwise slip through Repository.Update's nil-is-untouched COALESCE semantics and blank the field.
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
	if t.DiveCenterID.Valid {
		if p.BookingURL != nil {
			trimmed := strings.TrimSpace(*p.BookingURL)
			p.BookingURL = &trimmed
		}
		// Checks the effective value after this update (incoming if touched, else the existing row), since a business trip must end up with both fields set either way.
		hasPrice := p.PriceMinor != nil || t.PriceMinor.Valid
		hasBookingURL := (p.BookingURL != nil && *p.BookingURL != "") || (t.BookingURL.Valid && t.BookingURL.String != "")
		if !hasPrice || !hasBookingURL {
			return Trip{}, ErrBusinessTripRequiresPriceAndURL
		}
	}
	return s.Repo.Update(ctx, tripID, p)
}

// EnsureNotCancelled is the shared guard for actions that freeze once a trip is cancelled, while everything read-only stays reachable.
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

func (s *Service) ListJoinedByUser(ctx context.Context, userID uuid.UUID, archived bool) ([]Trip, error) {
	return s.Repo.ListJoinedByUser(ctx, userID, archived)
}

func (s *Service) Archive(ctx context.Context, id string, userID uuid.UUID) error {
	tripID, err := uuid.Parse(id)
	if err != nil {
		return ErrInvalidArgument
	}
	return s.Repo.Archive(ctx, tripID, userID)
}

func (s *Service) Unarchive(ctx context.Context, id string, userID uuid.UUID) error {
	tripID, err := uuid.Parse(id)
	if err != nil {
		return ErrInvalidArgument
	}
	return s.Repo.Unarchive(ctx, tripID, userID)
}

func (s *Service) IsArchived(ctx context.Context, id string, userID uuid.UUID) (bool, error) {
	tripID, err := uuid.Parse(id)
	if err != nil {
		return false, ErrInvalidArgument
	}
	return s.Repo.IsArchived(ctx, tripID, userID)
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

func (s *Service) Mute(ctx context.Context, id string, userID uuid.UUID) error {
	tripID, err := uuid.Parse(id)
	if err != nil {
		return ErrInvalidArgument
	}
	return s.Repo.Mute(ctx, tripID, userID)
}

func (s *Service) Unmute(ctx context.Context, id string, userID uuid.UUID) error {
	tripID, err := uuid.Parse(id)
	if err != nil {
		return ErrInvalidArgument
	}
	return s.Repo.Unmute(ctx, tripID, userID)
}

func (s *Service) IsMuted(ctx context.Context, id string, userID uuid.UUID) (bool, error) {
	tripID, err := uuid.Parse(id)
	if err != nil {
		return false, ErrInvalidArgument
	}
	return s.Repo.IsMuted(ctx, tripID, userID)
}

// ListMutedUserIDs is un-gated (no callerID): for internal/system callers like push fan-out, not an HTTP-exposed listing.
func (s *Service) ListMutedUserIDs(ctx context.Context, tripID uuid.UUID) ([]uuid.UUID, error) {
	return s.Repo.ListMutedUserIDs(ctx, tripID)
}

// ListArchivedUserIDs — same un-gated, push-fan-out-only posture as ListMutedUserIDs.
func (s *Service) ListArchivedUserIDs(ctx context.Context, tripID uuid.UUID) ([]uuid.UUID, error) {
	return s.Repo.ListArchivedUserIDs(ctx, tripID)
}

func (s *Service) SubmitFeedback(ctx context.Context, id string, userID uuid.UUID, rating int, helpedWith string, comment sql.NullString, contactOk bool) error {
	tripID, err := uuid.Parse(id)
	if err != nil {
		return ErrInvalidArgument
	}
	if rating < 1 || rating > 5 {
		return ErrInvalidArgument
	}
	return s.Repo.SubmitFeedback(ctx, tripID, userID, rating, helpedWith, comment, contactOk)
}

func (s *Service) HasFeedback(ctx context.Context, id string, userID uuid.UUID) (bool, error) {
	tripID, err := uuid.Parse(id)
	if err != nil {
		return false, ErrInvalidArgument
	}
	return s.Repo.HasFeedback(ctx, tripID, userID)
}

// ListTripIDsAwaitingFeedbackPrompt is un-gated — for the internal periodic scan job only.
func (s *Service) ListTripIDsAwaitingFeedbackPrompt(ctx context.Context) ([]uuid.UUID, error) {
	return s.Repo.ListTripIDsAwaitingFeedbackPrompt(ctx)
}
