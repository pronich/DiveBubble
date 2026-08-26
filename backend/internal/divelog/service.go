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

// cleanText trims whitespace and turns an empty result into nil — shared by every text
// field (Country, SiteName) across create/update so an all-whitespace input is stored as
// "not set" rather than an empty string.
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

// Some dive computer export tools (Oceanic+ among them) write their own internal site
// record key into UDDF's site name field instead of the diver-facing name — e.g.
// "site_6a8ade1b7070f27" or a bare UUID — rather than surface that as a "dive site" a
// human never actually typed, treat it the same as no site name at all.
var internalIDPattern = regexp.MustCompile(`(?i)^[a-z]*_?[0-9a-f]{10,}$`)
var uuidPattern = regexp.MustCompile(`(?i)^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$`)

func looksLikeInternalID(s string) bool {
	return internalIDPattern.MatchString(s) || uuidPattern.MatchString(s)
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

// ImportResult reports what an UDDF import actually did — the app surfaces "N new, M
// already logged" from this rather than assuming every dive in the file was fresh.
type ImportResult struct {
	Imported int
	Skipped  int
}

// Import sniffs the file's actual content (never the filename/extension, which is
// unreliable — Diving Log 6's own SQLite export is literally named "....sql" despite not
// being SQL text at all) to pick a parser, then inserts every dive it finds, silently
// skipping any whose dived_at exactly matches an entry this diver already has (see the
// migration's unique index) — a diver re-exporting "everything" after already importing
// once shouldn't end up with duplicates of dives they'd previously logged.
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

// UpdateInput mirrors CreateManualInput — the app sends the full set of editable fields on
// every update (unchanged fields just carry their existing value back), including for an
// imported entry, where in practice only SiteName/Notes are exposed as editable in the UI.
type UpdateInput struct {
	DivedAt         time.Time
	MaxDepthM       *float64
	DurationMinutes *int
	MinTemperatureC *float64
	Country         *string
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
	existing.DivedAt = input.DivedAt
	existing.MaxDepthM = input.MaxDepthM
	existing.DurationMinutes = input.DurationMinutes
	existing.MinTemperatureC = input.MinTemperatureC
	existing.Country = cleanText(input.Country)
	existing.SiteName = cleanText(input.SiteName)
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
