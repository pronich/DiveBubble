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

// maxAttachmentsPerMessage mirrors the app's composer cap (see chat_view.dart's _pendingAttachments), enforced here too since the server must never trust the client alone.
const maxAttachmentsPerMessage = 9

// Send persists a user-authored message with body allowed empty only when an attachment is set, and validates a set replyToID actually belongs to the same trip since the FK alone would let a client reference a message from an unrelated trip's chat.
func (s *Service) Send(ctx context.Context, tripID, userID uuid.UUID, scope Scope, body string, mentionsDiveCenter bool, attachments []Attachment, replyToID uuid.NullUUID) (Message, error) {
	body = strings.TrimSpace(body)
	if body == "" && len(attachments) == 0 {
		return Message{}, ErrInvalidArgument
	}
	if len(attachments) > maxAttachmentsPerMessage {
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
	return s.Repo.Create(ctx, tripID, userID, scope, body, mentionsDiveCenter, attachments, replyToID)
}

// Delete soft-deletes a message, author-only; ErrNotFound covers both "not the author" and "already deleted" (see Repository.SoftDelete).
func (s *Service) Delete(ctx context.Context, messageID, callerUserID uuid.UUID) (Message, error) {
	return s.Repo.SoftDelete(ctx, messageID, callerUserID)
}

// SetReaction upserts the caller's reaction, returning the target message (so the caller knows which chat scope to republish on, see handleSetReaction) plus its fresh per-emoji summary; ErrNotFound covers a missing, wrong-trip, or soft-deleted message alike.
func (s *Service) SetReaction(ctx context.Context, tripID, messageID, userID uuid.UUID, emoji string) (Message, map[string]ReactionSummary, error) {
	if !IsValidReactionEmoji(emoji) {
		return Message{}, nil, ErrInvalidArgument
	}
	m, err := s.reactableMessage(ctx, tripID, messageID)
	if err != nil {
		return Message{}, nil, err
	}
	if err := s.Repo.UpsertReaction(ctx, messageID, userID, emoji); err != nil {
		return Message{}, nil, err
	}
	reactions, err := s.reactionsForViewer(ctx, messageID, userID)
	return m, reactions, err
}

// RemoveReaction removes the caller's reaction if any and returns the target message plus its fresh per-emoji summary from the caller's point of view.
func (s *Service) RemoveReaction(ctx context.Context, tripID, messageID, userID uuid.UUID) (Message, map[string]ReactionSummary, error) {
	m, err := s.reactableMessage(ctx, tripID, messageID)
	if err != nil {
		return Message{}, nil, err
	}
	if err := s.Repo.RemoveReaction(ctx, messageID, userID); err != nil {
		return Message{}, nil, err
	}
	reactions, err := s.reactionsForViewer(ctx, messageID, userID)
	return m, reactions, err
}

// reactableMessage guards against reacting to a message from a different trip (same concern Send's replyToID check covers, since a participant could otherwise reference any guessed/observed message id) or one that's been deleted.
func (s *Service) reactableMessage(ctx context.Context, tripID, messageID uuid.UUID) (Message, error) {
	m, err := s.GetByID(ctx, messageID)
	if err != nil {
		return Message{}, err
	}
	if m.TripID != tripID || m.DeletedAt.Valid {
		return Message{}, ErrNotFound
	}
	return m, nil
}

func (s *Service) reactionsForViewer(ctx context.Context, messageID, userID uuid.UUID) (map[string]ReactionSummary, error) {
	byMessage, err := s.Repo.ListReactionsByMessageIDs(ctx, []uuid.UUID{messageID}, userID)
	if err != nil {
		return nil, err
	}
	return byMessage[messageID], nil
}

// ListReactionsForMessages batch-fetches reaction summaries for a page of messages from a specific viewer's point of view (see handleListMessages), same batch-not-N+1 shape as withAttachments.
func (s *Service) ListReactionsForMessages(ctx context.Context, messageIDs []uuid.UUID, viewerID uuid.UUID) (map[uuid.UUID]map[string]ReactionSummary, error) {
	return s.Repo.ListReactionsByMessageIDs(ctx, messageIDs, viewerID)
}

// SendSystem creates a system message of the given kind unless one was already sent, returning sent=false so callers skip republishing; only for "once per trip" kinds like the feedback prompt (see PostSystemEvent for repeating kinds).
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

// PostSystemEvent always inserts a system message with no "only once per trip" check, unlike SendSystem, since events like a car-offer/buddy-group join are expected to repeat.
func (s *Service) PostSystemEvent(ctx context.Context, tripID uuid.UUID, scope Scope, kind, body string) (Message, error) {
	return s.Repo.CreateSystem(ctx, tripID, scope, kind, body)
}

func (s *Service) List(ctx context.Context, tripID uuid.UUID) ([]Message, error) {
	messages, err := s.Repo.ListByTrip(ctx, tripID)
	if err != nil {
		return nil, err
	}
	return s.withAttachments(ctx, messages)
}

func (s *Service) ListByOffer(ctx context.Context, offerID uuid.UUID) ([]Message, error) {
	messages, err := s.Repo.ListByOffer(ctx, offerID)
	if err != nil {
		return nil, err
	}
	return s.withAttachments(ctx, messages)
}

func (s *Service) ListByBuddyRequest(ctx context.Context, requestID uuid.UUID) ([]Message, error) {
	messages, err := s.Repo.ListByBuddyRequest(ctx, requestID)
	if err != nil {
		return nil, err
	}
	return s.withAttachments(ctx, messages)
}

// withAttachments batch-fetches and merges in chat_message_attachments rows, leaving messages that only ever used the legacy scalar columns (or have none) with an empty Attachments slice, since those columns stay readable straight off each Message.
func (s *Service) withAttachments(ctx context.Context, messages []Message) ([]Message, error) {
	ids := make([]uuid.UUID, len(messages))
	for i, m := range messages {
		ids[i] = m.ID
	}
	byMessage, err := s.Repo.ListAttachmentsByMessageIDs(ctx, ids)
	if err != nil {
		return nil, err
	}
	for i := range messages {
		messages[i].Attachments = byMessage[messages[i].ID]
	}
	return messages, nil
}

// ListAttachments backs the Media (image/video) and Files (pdf) tabs; before nil starts from the most recent page.
func (s *Service) ListAttachments(ctx context.Context, tripID uuid.UUID, attachmentTypes []string, before *time.Time, limit int) ([]MediaItem, error) {
	return s.Repo.ListAttachmentsByTrip(ctx, tripID, attachmentTypes, before, limit)
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
	if err != nil {
		return Message{}, err
	}
	attachments, err := s.Repo.ListAttachmentsByMessageIDs(ctx, []uuid.UUID{m.ID})
	if err != nil {
		return Message{}, err
	}
	m.Attachments = attachments[m.ID]
	return m, nil
}
