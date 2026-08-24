package message

import (
	"context"
	"database/sql"
	"errors"
	"time"

	"github.com/google/uuid"
)

type Repository struct {
	DB *sql.DB
}

func NewRepository(db *sql.DB) *Repository {
	return &Repository{DB: db}
}

// messageColumns is the fixed SELECT/RETURNING column list shared by every read/write query
// below, kept in one place so scanMessage/scanMessages always match it.
const messageColumns = `id, trip_id, user_id, body, created_at, mentions_dive_center, kind, offer_id, buddy_request_id,
	attachment_url, attachment_type, attachment_filename, attachment_size_bytes, reply_to_id, deleted_at`

func scanMessage(row interface{ Scan(...any) error }, m *Message) error {
	return row.Scan(&m.ID, &m.TripID, &m.UserID, &m.Body, &m.CreatedAt, &m.MentionsDiveCenter, &m.Kind, &m.OfferID, &m.BuddyRequestID,
		&m.AttachmentURL, &m.AttachmentType, &m.AttachmentFilename, &m.AttachmentSizeBytes, &m.ReplyToID, &m.DeletedAt)
}

// Create inserts a user-authored message. scope is the zero value for the trip's main chat,
// or set for a car offer's or buddy group's own chat — trip_id is always populated either way
// (see migrations 000046/000048). attachment may be nil (text-only message). replyToID may be
// the zero uuid.NullUUID (not a reply).
func (r *Repository) Create(ctx context.Context, tripID, userID uuid.UUID, scope Scope, body string, mentionsDiveCenter bool, attachment *Attachment, replyToID uuid.NullUUID) (Message, error) {
	var attURL, attType, attFilename sql.NullString
	var attSize sql.NullInt64
	if attachment != nil {
		attURL = sql.NullString{String: attachment.URL, Valid: true}
		attType = sql.NullString{String: attachment.Type, Valid: true}
		attFilename = sql.NullString{String: attachment.Filename, Valid: attachment.Filename != ""}
		attSize = sql.NullInt64{Int64: attachment.SizeBytes, Valid: attachment.SizeBytes > 0}
	}
	var m Message
	err := scanMessage(r.DB.QueryRowContext(ctx, `
		INSERT INTO chat_messages (trip_id, user_id, offer_id, buddy_request_id, body, mentions_dive_center,
			attachment_url, attachment_type, attachment_filename, attachment_size_bytes, reply_to_id)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
		RETURNING `+messageColumns+`
	`, tripID, userID, scope.OfferID, scope.BuddyRequestID, body, mentionsDiveCenter,
		attURL, attType, attFilename, attSize, replyToID), &m)
	return m, err
}

// SoftDelete marks a message deleted — author-only, idempotent-safe (deleting an
// already-deleted message just reports ErrNotFound rather than double-processing). The row
// itself is kept (not removed) so any reply pointing at it via reply_to_id still resolves;
// callers are responsible for blanking Body/Attachment* before this reaches a response (see
// routes_message.go's toMessageResponse) — the row in the DB still holds the real content.
func (r *Repository) SoftDelete(ctx context.Context, messageID, callerUserID uuid.UUID) (Message, error) {
	var m Message
	err := scanMessage(r.DB.QueryRowContext(ctx, `
		UPDATE chat_messages SET deleted_at = now()
		WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL
		RETURNING `+messageColumns, messageID, callerUserID), &m)
	if errors.Is(err, sql.ErrNoRows) {
		return Message{}, ErrNotFound
	}
	return m, err
}

// CreateSystem inserts a message sent by SystemUserID with the given kind (never KindUser).
// System messages never carry an attachment.
func (r *Repository) CreateSystem(ctx context.Context, tripID uuid.UUID, scope Scope, kind, body string) (Message, error) {
	var m Message
	err := scanMessage(r.DB.QueryRowContext(ctx, `
		INSERT INTO chat_messages (trip_id, user_id, offer_id, buddy_request_id, body, kind)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING `+messageColumns+`
	`, tripID, SystemUserID, scope.OfferID, scope.BuddyRequestID, body, kind), &m)
	return m, err
}

// ExistsByTripAndKind reports whether a message of the given kind has already been sent for
// this trip — used to keep the periodic feedback-prompt scan idempotent.
func (r *Repository) ExistsByTripAndKind(ctx context.Context, tripID uuid.UUID, kind string) (bool, error) {
	var exists bool
	err := r.DB.QueryRowContext(ctx, `
		SELECT EXISTS(SELECT 1 FROM chat_messages WHERE trip_id = $1 AND kind = $2)
	`, tripID, kind).Scan(&exists)
	return exists, err
}

func (r *Repository) GetByID(ctx context.Context, id uuid.UUID) (Message, error) {
	var m Message
	err := scanMessage(r.DB.QueryRowContext(ctx, `
		SELECT `+messageColumns+`
		FROM chat_messages
		WHERE id = $1
	`, id), &m)
	return m, err
}

// ListByTrip returns only the trip's main-chat messages — excludes every car offer's and
// buddy group's own chat, which live under ListByOffer/ListByBuddyRequest instead.
func (r *Repository) ListByTrip(ctx context.Context, tripID uuid.UUID) ([]Message, error) {
	rows, err := r.DB.QueryContext(ctx, `
		SELECT `+messageColumns+`
		FROM chat_messages
		WHERE trip_id = $1 AND offer_id IS NULL AND buddy_request_id IS NULL
		ORDER BY created_at ASC
	`, tripID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanMessages(rows)
}

// ListByOffer returns a single car offer's own chat history.
func (r *Repository) ListByOffer(ctx context.Context, offerID uuid.UUID) ([]Message, error) {
	rows, err := r.DB.QueryContext(ctx, `
		SELECT `+messageColumns+`
		FROM chat_messages
		WHERE offer_id = $1
		ORDER BY created_at ASC
	`, offerID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanMessages(rows)
}

// ListByBuddyRequest returns a single buddy group's own chat history.
func (r *Repository) ListByBuddyRequest(ctx context.Context, requestID uuid.UUID) ([]Message, error) {
	rows, err := r.DB.QueryContext(ctx, `
		SELECT `+messageColumns+`
		FROM chat_messages
		WHERE buddy_request_id = $1
		ORDER BY created_at ASC
	`, requestID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanMessages(rows)
}

// ListAttachmentsByTrip backs the Media ("image") and Files ("pdf") tabs — main trip chat
// only (v1 scope), newest first, cursor-paginated on created_at. before nil means "from the
// start" (most recent page). Served by idx_chat_messages_trip_attachment (migration 000051).
func (r *Repository) ListAttachmentsByTrip(ctx context.Context, tripID uuid.UUID, attachmentType string, before *time.Time, limit int) ([]Message, error) {
	rows, err := r.DB.QueryContext(ctx, `
		SELECT `+messageColumns+`
		FROM chat_messages
		WHERE trip_id = $1 AND offer_id IS NULL AND buddy_request_id IS NULL AND attachment_type = $2
			AND ($3::timestamptz IS NULL OR created_at < $3)
		ORDER BY created_at DESC
		LIMIT $4
	`, tripID, attachmentType, before, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanMessages(rows)
}

// LinkSourceMessage is the minimal shape ListLinksByTrip reads — the handler regex-extracts
// URLs from Body, so the full Message scan (attachment columns etc.) isn't needed here.
type LinkSourceMessage struct {
	ID        uuid.UUID
	UserID    uuid.UUID
	Body      string
	CreatedAt time.Time
}

// ListLinksByTrip returns main-chat user messages whose body contains at least one URL, newest
// first, cursor-paginated on created_at. The handler extracts individual links from Body — limit
// bounds the number of *messages* scanned, not the number of links returned (acceptable, trip
// chats aren't link-dense).
func (r *Repository) ListLinksByTrip(ctx context.Context, tripID uuid.UUID, before *time.Time, limit int) ([]LinkSourceMessage, error) {
	rows, err := r.DB.QueryContext(ctx, `
		SELECT id, user_id, body, created_at
		FROM chat_messages
		WHERE trip_id = $1 AND offer_id IS NULL AND buddy_request_id IS NULL AND kind = $2
			AND body ~* 'https?://\S+'
			AND ($3::timestamptz IS NULL OR created_at < $3)
		ORDER BY created_at DESC
		LIMIT $4
	`, tripID, KindUser, before, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []LinkSourceMessage{}
	for rows.Next() {
		var m LinkSourceMessage
		if err := rows.Scan(&m.ID, &m.UserID, &m.Body, &m.CreatedAt); err != nil {
			return nil, err
		}
		out = append(out, m)
	}
	return out, rows.Err()
}

func scanMessages(rows *sql.Rows) ([]Message, error) {
	messages := []Message{}
	for rows.Next() {
		var m Message
		if err := scanMessage(rows, &m); err != nil {
			return nil, err
		}
		messages = append(messages, m)
	}
	return messages, rows.Err()
}
