package message

import (
	"context"
	"database/sql"
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
)

var ErrInvalidArgument = errors.New("invalid argument")
var ErrNotFound = errors.New("message not found")

type Service struct {
	Repo *Repository
}

func NewService(repo *Repository) *Service {
	return &Service{Repo: repo}
}

// Send persists a user-authored message. scope is the zero value for the trip's main chat,
// or set for a car offer's or buddy group's own chat. attachment may be nil (text-only
// message); body may be empty only when attachment is set (an attachment's caption). replyToID
// is the zero uuid.NullUUID for "not a reply" — when set, the target must exist and belong to
// the same trip (a client could otherwise reference a message from an unrelated trip's chat;
// the reply_to_id foreign key alone doesn't catch that, since it only checks the row exists).
func (s *Service) Send(ctx context.Context, tripID, userID uuid.UUID, scope Scope, body string, mentionsDiveCenter bool, attachment *Attachment, replyToID uuid.NullUUID) (Message, error) {
	body = strings.TrimSpace(body)
	if body == "" && attachment == nil {
		return Message{}, ErrInvalidArgument
	}
	if replyToID.Valid {
		target, err := s.GetByID(ctx, replyToID.UUID)
		if err != nil {
			return Message{}, ErrInvalidArgument
		}
		if target.TripID != tripID {
			return Message{}, ErrInvalidArgument
		}
	}
	return s.Repo.Create(ctx, tripID, userID, scope, body, mentionsDiveCenter, attachment, replyToID)
}

// Delete soft-deletes a message — author-only (ErrNotFound covers both "not the author" and
// "already deleted", see Repository.SoftDelete).
func (s *Service) Delete(ctx context.Context, messageID, callerUserID uuid.UUID) (Message, error) {
	return s.Repo.SoftDelete(ctx, messageID, callerUserID)
}

// SendSystem creates a system message of the given kind for the trip's main chat, unless one
// has already been sent — sent is false when it was skipped, so callers know not to
// publish/notify again. Only fits a "once per trip" system kind (e.g. the feedback prompt);
// see PostSystemEvent for kinds that repeat (e.g. one per car-offer join).
func (s *Service) SendSystem(ctx context.Context, tripID uuid.UUID, kind, body string) (msg Message, sent bool, err error) {
	exists, err := s.Repo.ExistsByTripAndKind(ctx, tripID, kind)
	if err != nil {
		return Message{}, false, err
	}
	if exists {
		return Message{}, false, nil
	}
	msg, err = s.Repo.CreateSystem(ctx, tripID, Scope{}, kind, body)
	if err != nil {
		return Message{}, false, err
	}
	return msg, true, nil
}

// PostSystemEvent always inserts a system message — unlike SendSystem, it has no "only once
// per trip" idempotency check, since events like a car-offer/buddy-group join are expected
// to repeat.
func (s *Service) PostSystemEvent(ctx context.Context, tripID uuid.UUID, scope Scope, kind, body string) (Message, error) {
	return s.Repo.CreateSystem(ctx, tripID, scope, kind, body)
}

func (s *Service) List(ctx context.Context, tripID uuid.UUID) ([]Message, error) {
	return s.Repo.ListByTrip(ctx, tripID)
}

func (s *Service) ListByOffer(ctx context.Context, offerID uuid.UUID) ([]Message, error) {
	return s.Repo.ListByOffer(ctx, offerID)
}

func (s *Service) ListByBuddyRequest(ctx context.Context, requestID uuid.UUID) ([]Message, error) {
	return s.Repo.ListByBuddyRequest(ctx, requestID)
}

// ListAttachments backs the Media/Files tabs — attachmentType must be AttachmentTypeImage or
// AttachmentTypePDF. before nil starts from the most recent page.
func (s *Service) ListAttachments(ctx context.Context, tripID uuid.UUID, attachmentType string, before *time.Time, limit int) ([]Message, error) {
	return s.Repo.ListAttachmentsByTrip(ctx, tripID, attachmentType, before, limit)
}

// ListLinks backs the Links tab. before nil starts from the most recent page.
func (s *Service) ListLinks(ctx context.Context, tripID uuid.UUID, before *time.Time, limit int) ([]LinkSourceMessage, error) {
	return s.Repo.ListLinksByTrip(ctx, tripID, before, limit)
}

func (s *Service) GetByID(ctx context.Context, id uuid.UUID) (Message, error) {
	m, err := s.Repo.GetByID(ctx, id)
	if errors.Is(err, sql.ErrNoRows) {
		return Message{}, ErrNotFound
	}
	return m, err
}
