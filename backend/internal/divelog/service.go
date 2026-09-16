package divelog

import (
	"context"
	"errors"
	"regexp"
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
	Country         *string
	SiteName        *string
	Notes           *string
}

// cleanText trims whitespace and turns an empty result into nil, shared by Country/SiteName across create/update so an all-whitespace input is stored as "not set" rather than an empty string.
func cleanText(s *string) *string {
	if s == nil {
		return nil
	}
	trimmed := strings.TrimSpace(*s)
	if trimmed == "" {
		return nil
	}
	if looksLikeInternalID(trimmed) {
		return nil
	}
	return &trimmed
}

// Some dive computer export tools (Oceanic+ among them) write their own internal site record key into UDDF's site name field instead of the diver-facing name (e.g. "site_6a8ade1b7070f27" or a bare UUID), so treat anything matching that shape as no site name at all.
var internalIDPattern = regexp.MustCompile(`(?i)^[a-z]*_?[0-9a-f]{10,}$`)
var uuidPattern = regexp.MustCompile(`(?i)^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$`)

func looksLikeInternalID(s string) bool {
	return internalIDPattern.MatchString(s) || uuidPattern.MatchString(s)
}

// CreateManual is the "no file, just numbers" add path with no profile_samples ever (gated by Source, see Entry.ProfileSamples), and a colliding re-typed timestamp surfaces as a genuine error (onConflictSkip=false) rather than silently vanishing like an import's dedup.
func (s *Service) CreateManual(ctx context.Context, userID uuid.UUID, input CreateManualInput) (Entry, error) {
	if input.DivedAt.IsZero() {
		return Entry{}, ErrInvalidArgument
	}
	e := Entry{
		UserID:          userID,
		Source:          SourceManual,
		DivedAt:         input.DivedAt,
		MaxDepthM:       input.MaxDepthM,
		DurationMinutes: input.DurationMinutes,
		MinTemperatureC: input.MinTemperatureC,
		Country:         cleanText(input.Country),
		SiteName:        cleanText(input.SiteName),
		Notes:           input.Notes,
	}
	created, _, err := s.Repo.Create(ctx, e, false)
	return created, err
}

// ImportResult reports what an UDDF import did, letting the app surface "N new, M already logged" rather than assuming every dive in the file was fresh.
type ImportResult struct {
	Imported int
	Skipped  int
}

// Import sniffs the file's actual content (not its filename/extension, since Diving Log 6's SQLite export is literally named ".sql") to pick a parser, then silently skips any dive whose dived_at exactly matches one this diver already has so re-exporting "everything" doesn't create duplicates.
func (s *Service) Import(ctx context.Context, userID uuid.UUID, data []byte) (ImportResult, error) {
	entries, err := parseImportFile(data)
	if err != nil {
		return ImportResult{}, err
	}

	var result ImportResult
	for _, e := range entries {
		e.UserID = userID
		e.Source = SourceImported
		e.SiteName = cleanText(e.SiteName)
		e.Country = cleanText(e.Country)
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

// UpdateInput mirrors CreateManualInput; the app always sends the full set of editable fields on update, including for an imported entry where only SiteName/Notes are actually exposed as editable in the UI.
type UpdateInput struct {
	DivedAt         time.Time
	MaxDepthM       *float64
	DurationMinutes *int
	MinTemperatureC *float64
	Country         *string
	SiteName        *string
	Notes           *string
}

// Update is owner-only like Delete, touching only Repository.Update's fixed column set and never Source or ProfileSamples.
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
	existing.DivedAt = input.DivedAt
	existing.MaxDepthM = input.MaxDepthM
	existing.DurationMinutes = input.DurationMinutes
	existing.MinTemperatureC = input.MinTemperatureC
	existing.Country = cleanText(input.Country)
	existing.SiteName = cleanText(input.SiteName)
	existing.Notes = input.Notes
	return s.Repo.Update(ctx, id, existing)
}

// Delete is owner-only, since a dive log is personal with no "any participant" concept to extend it to, unlike a trip expense.
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
