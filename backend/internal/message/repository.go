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
// (see migrations 000046/000048). attachments may be empty (text-only message); every send
// with attachments goes through chat_message_attachments now, never the legacy scalar columns
// (those stay write-only-in-the-past, read for old rows — see toMessageResponse). replyToID may
// be the zero uuid.NullUUID (not a reply).
func (r *Repository) Create(ctx context.Context, tripID, userID uuid.UUID, scope Scope, body string, mentionsDiveCenter bool, attachments []Attachment, replyToID uuid.NullUUID) (Message, error) {
	tx, err := r.DB.BeginTx(ctx, nil)
	if err != nil {
		return Message{}, err
	}
	defer func() { _ = tx.Rollback() }()

	var m Message
	if err := scanMessage(tx.QueryRowContext(ctx, `
		INSERT INTO chat_messages (trip_id, user_id, offer_id, buddy_request_id, body, mentions_dive_center, reply_to_id)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING `+messageColumns+`
	`, tripID, userID, scope.OfferID, scope.BuddyRequestID, body, mentionsDiveCenter, replyToID), &m); err != nil {
		return Message{}, err
	}

	for i, a := range attachments {
		var filename sql.NullString
		if a.Filename != "" {
			filename = sql.NullString{String: a.Filename, Valid: true}
		}
		var size sql.NullInt64
		if a.SizeBytes > 0 {
			size = sql.NullInt64{Int64: a.SizeBytes, Valid: true}
		}
		if _, err := tx.ExecContext(ctx, `
			INSERT INTO chat_message_attachments (message_id, position, url, type, filename, size_bytes, duration_seconds)
			VALUES ($1, $2, $3, $4, $5, $6, $7)
		`, m.ID, i, a.URL, a.Type, filename, size, a.DurationSeconds); err != nil {
			return Message{}, err
		}
	}
	m.Attachments = attachments

	if err := tx.Commit(); err != nil {
		return Message{}, err
	}
	return m, nil
}

// attachmentColumns/scanAttachmentRow back the batched per-message attachment fetch below —
// kept separate from messageColumns/scanMessage since chat_message_attachments is its own table.
const attachmentColumns = `message_id, url, type, filename, size_bytes, duration_seconds`

func scanAttachmentRow(rows *sql.Rows) (uuid.UUID, Attachment, error) {
	var messageID uuid.UUID
	var a Attachment
	var filename sql.NullString
	var size sql.NullInt64
	err := rows.Scan(&messageID, &a.URL, &a.Type, &filename, &size, &a.DurationSeconds)
	a.Filename = filename.String
	a.SizeBytes = size.Int64
	return messageID, a, err
}

// ListAttachmentsByMessageIDs batch-fetches chat_message_attachments rows for a set of
// messages, grouped by message and ordered by position — used to populate Message.Attachments
// after ListByTrip/ListByOffer/ListByBuddyRequest/GetByID, same batch-not-N+1 shape as
// routes_message.go's diveCenterStaffChecker. Messages with no rows here (text-only, or an old
// message still on the legacy scalar columns) simply have no entry in the returned map.
func (r *Repository) ListAttachmentsByMessageIDs(ctx context.Context, messageIDs []uuid.UUID) (map[uuid.UUID][]Attachment, error) {
	out := map[uuid.UUID][]Attachment{}
	if len(messageIDs) == 0 {
		return out, nil
	}
	rows, err := r.DB.QueryContext(ctx, `
		SELECT `+attachmentColumns+`
		FROM chat_message_attachments
		WHERE message_id = ANY($1)
		ORDER BY message_id, position
	`, messageIDs)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		messageID, a, err := scanAttachmentRow(rows)
		if err != nil {
			return nil, err
		}
		out[messageID] = append(out[messageID], a)
	}
	return out, rows.Err()
}

// UpsertReaction sets the caller's reaction on a message, replacing any previous one they had
// (one reaction per user per message, Messenger semantics — see migration 000055's PRIMARY KEY).
func (r *Repository) UpsertReaction(ctx context.Context, messageID, userID uuid.UUID, emoji string) error {
	_, err := r.DB.ExecContext(ctx, `
		INSERT INTO chat_message_reactions (message_id, user_id, emoji)
		VALUES ($1, $2, $3)
		ON CONFLICT (message_id, user_id) DO UPDATE SET emoji = excluded.emoji, created_at = now()
	`, messageID, userID, emoji)
	return err
}

// RemoveReaction removes the caller's reaction, if any — idempotent, no error when there wasn't
// one to remove (mirrors DELETE semantics elsewhere in this package).
func (r *Repository) RemoveReaction(ctx context.Context, messageID, userID uuid.UUID) error {
	_, err := r.DB.ExecContext(ctx, `
		DELETE FROM chat_message_reactions WHERE message_id = $1 AND user_id = $2
	`, messageID, userID)
	return err
}

// ListReactionsByMessageIDs batch-fetches per-emoji reaction summaries for a set of messages —
// one query, not N+1, same shape as ListAttachmentsByMessageIDs. viewerID decides ReactedByMe;
// Count itself is the same for every viewer. Messages with no reactions have no entry in the map.
func (r *Repository) ListReactionsByMessageIDs(ctx context.Context, messageIDs []uuid.UUID, viewerID uuid.UUID) (map[uuid.UUID]map[string]ReactionSummary, error) {
	out := map[uuid.UUID]map[string]ReactionSummary{}
	if len(messageIDs) == 0 {
		return out, nil
	}
	rows, err := r.DB.QueryContext(ctx, `
		SELECT message_id, emoji, COUNT(*), BOOL_OR(user_id = $2)
		FROM chat_message_reactions
		WHERE message_id = ANY($1)
		GROUP BY message_id, emoji
	`, messageIDs, viewerID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var messageID uuid.UUID
		var emoji string
		var summary ReactionSummary
		if err := rows.Scan(&messageID, &emoji, &summary.Count, &summary.ReactedByMe); err != nil {
			return nil, err
		}
		if out[messageID] == nil {
			out[messageID] = map[string]ReactionSummary{}
		}
		out[messageID][emoji] = summary
	}
	return out, rows.Err()
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

// MediaItem is one row for the Media/Files tab — one per *attachment*, not per message, so a
// message with several attachments (see migration 000054) contributes several grid entries
// rather than one. UNIONs the new chat_message_attachments rows with the legacy single-
// attachment scalar columns on chat_messages, so nothing sent before that migration disappears
// from the tab.
type MediaItem struct {
	MessageID uuid.UUID
	UserID    uuid.UUID
	CreatedAt time.Time
	Attachment
}

// ListAttachmentsByTrip backs the Media ("image"+"video") and Files ("pdf") tabs — main trip
// chat only (v1 scope), newest first (ties broken by position within a message), cursor-
// paginated on created_at, excludes soft-deleted messages. before nil means "from the start".
func (r *Repository) ListAttachmentsByTrip(ctx context.Context, tripID uuid.UUID, attachmentTypes []string, before *time.Time, limit int) ([]MediaItem, error) {
	rows, err := r.DB.QueryContext(ctx, `
		SELECT message_id, user_id, created_at, url, type, filename, size_bytes, duration_seconds FROM (
			SELECT cm.id AS message_id, cm.user_id, cm.created_at,
			       cma.url, cma.type, cma.filename, cma.size_bytes, cma.duration_seconds, cma.position::int AS position
			FROM chat_message_attachments cma
			JOIN chat_messages cm ON cm.id = cma.message_id
			WHERE cm.trip_id = $1 AND cm.offer_id IS NULL AND cm.buddy_request_id IS NULL
			  AND cm.deleted_at IS NULL AND cma.type = ANY($2)

			UNION ALL

			SELECT cm.id, cm.user_id, cm.created_at,
			       cm.attachment_url, cm.attachment_type, cm.attachment_filename, cm.attachment_size_bytes,
			       NULL::int, 0::int
			FROM chat_messages cm
			WHERE cm.trip_id = $1 AND cm.offer_id IS NULL AND cm.buddy_request_id IS NULL
			  AND cm.deleted_at IS NULL AND cm.attachment_type = ANY($2)
		) combined
		WHERE ($3::timestamptz IS NULL OR created_at < $3)
		ORDER BY created_at DESC, position DESC
		LIMIT $4
	`, tripID, attachmentTypes, before, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := []MediaItem{}
	for rows.Next() {
		var item MediaItem
		var filename sql.NullString
		var size sql.NullInt64
		if err := rows.Scan(&item.MessageID, &item.UserID, &item.CreatedAt,
			&item.Attachment.URL, &item.Attachment.Type, &filename, &size, &item.Attachment.DurationSeconds); err != nil {
			return nil, err
		}
		item.Attachment.Filename = filename.String
		item.Attachment.SizeBytes = size.Int64
		items = append(items, item)
	}
	return items, rows.Err()
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
