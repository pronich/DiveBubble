package divelog

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
)

var ErrInvalidArgument = errors.New("invalid argument")
var ErrForbidden = errors.New("not your dive log entry")

type Service struct {
	Repo *Repository
}

func NewService(repo *Repository) *Service {
	return &Service{Repo: repo}
}

type CreateManualInput struct {
	DivedAt         time.Time
	MaxDepthM       *float64
	DurationMinutes *int
	MinTemperatureC *float64
	SiteName        *string
	Notes           *string
}

// CreateManual is the "no file, just numbers" add path — no profile_samples, ever (see
// Entry.ProfileSamples' own doc comment on why that's gated by Source rather than a
// separate flag). A manual entry with the diver's own re-typed timestamp colliding with an
// existing one surfaces as a genuine error (onConflictSkip=false) rather than silently
// vanishing, unlike an import's dedup.
func (s *Service) CreateManual(ctx context.Context, userID uuid.UUID, input CreateManualInput) (Entry, error) {
	if input.DivedAt.IsZero() {
		return Entry{}, ErrInvalidArgument
	}
	if input.SiteName != nil {
		trimmed := strings.TrimSpace(*input.SiteName)
		if trimmed == "" {
			input.SiteName = nil
		} else {
			input.SiteName = &trimmed
		}
	}
	e := Entry{
		UserID:          userID,
		Source:          SourceManual,
		DivedAt:         input.DivedAt,
		MaxDepthM:       input.MaxDepthM,
		DurationMinutes: input.DurationMinutes,
		MinTemperatureC: input.MinTemperatureC,
		SiteName:        input.SiteName,
		Notes:           input.Notes,
	}
	created, _, err := s.Repo.Create(ctx, e, false)
	return created, err
}

// ImportResult reports what an UDDF import actually did — the app surfaces "N new, M
// already logged" from this rather than assuming every dive in the file was fresh.
type ImportResult struct {
	Imported int
	Skipped  int
}

// Import parses the file and inserts every dive it finds, silently skipping any whose
// dived_at exactly matches an entry this diver already has (see the migration's unique
// index) — a diver re-exporting "everything" after already importing once shouldn't end up
// with duplicates of dives they'd previously logged.
func (s *Service) Import(ctx context.Context, userID uuid.UUID, data []byte) (ImportResult, error) {
	dives, err := ParseUDDF(data)
	if err != nil {
		return ImportResult{}, err
	}

	var result ImportResult
	for _, d := range dives {
		e := d.ToEntry()
		e.UserID = userID
		_, inserted, err := s.Repo.Create(ctx, e, true)
		if err != nil {
			return result, err
		}
		if inserted {
			result.Imported++
		} else {
			result.Skipped++
		}
	}
	return result, nil
}

func (s *Service) ListByUser(ctx context.Context, userID uuid.UUID) ([]Entry, error) {
	return s.Repo.ListByUser(ctx, userID)
}

func (s *Service) GetByID(ctx context.Context, id uuid.UUID) (Entry, error) {
	return s.Repo.GetByID(ctx, id)
}

// UpdateInput mirrors CreateManualInput — the app sends the full set of editable fields on
// every update (unchanged fields just carry their existing value back), including for an
// imported entry, where in practice only SiteName/Notes are exposed as editable in the UI.
type UpdateInput struct {
	DivedAt         time.Time
	MaxDepthM       *float64
	DurationMinutes *int
	MinTemperatureC *float64
	SiteName        *string
	Notes           *string
}

// Update is owner-only, same as Delete — Source and ProfileSamples are never touched here,
// only Repository.Update's fixed column set.
func (s *Service) Update(ctx context.Context, id, callerUserID uuid.UUID, input UpdateInput) (Entry, error) {
	existing, err := s.Repo.GetByID(ctx, id)
	if err != nil {
		return Entry{}, err
	}
	if existing.UserID != callerUserID {
		return Entry{}, ErrForbidden
	}
	if input.DivedAt.IsZero() {
		return Entry{}, ErrInvalidArgument
	}
	if input.SiteName != nil {
		trimmed := strings.TrimSpace(*input.SiteName)
		if trimmed == "" {
			input.SiteName = nil
		} else {
			input.SiteName = &trimmed
		}
	}
	existing.DivedAt = input.DivedAt
	existing.MaxDepthM = input.MaxDepthM
	existing.DurationMinutes = input.DurationMinutes
	existing.MinTemperatureC = input.MinTemperatureC
	existing.SiteName = input.SiteName
	existing.Notes = input.Notes
	return s.Repo.Update(ctx, id, existing)
}

// Delete is owner-only — a dive log is personal, unlike a trip expense there's no "any
// participant" concept to extend it to.
func (s *Service) Delete(ctx context.Context, id, callerUserID uuid.UUID) error {
	e, err := s.Repo.GetByID(ctx, id)
	if err != nil {
		return err
	}
	if e.UserID != callerUserID {
		return ErrForbidden
	}
	return s.Repo.Delete(ctx, id)
}
