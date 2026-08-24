package server

import (
	"context"
	"encoding/json"
	"fmt"

	"errors"
	"io"
	"log"
	"net/http"
	"regexp"
	"strconv"
	"strings"
	"time"

	"divebubble_be/internal/auth"
	"divebubble_be/internal/divecenter"
	"divebubble_be/internal/message"
	"divebubble_be/internal/moderation"
	"divebubble_be/internal/profile"
	"divebubble_be/internal/push"
	"divebubble_be/internal/realtime"
	"divebubble_be/internal/trip"

	"github.com/google/uuid"
)

func registerMessageRoutes(
	mux *http.ServeMux,
	svc *message.Service,
	tripSvc *trip.Service,
	diveCenterSvc *divecenter.Service,
	profileSvc *profile.Service,
	authIssuer *auth.TokenIssuer,
	publisher *realtime.Publisher,
	pushSvc *push.Service,
	moderationSvc *moderation.Service,
) {
	mux.HandleFunc("GET /trips/{id}/messages", withAuth(authIssuer, handleListMessages(svc, tripSvc, diveCenterSvc, moderationSvc)))
	mux.HandleFunc("POST /trips/{id}/messages", withAuth(authIssuer, handleSendMessage(svc, tripSvc, diveCenterSvc, profileSvc, publisher, pushSvc)))
	mux.HandleFunc("DELETE /trips/{id}/messages/{messageId}", withAuth(authIssuer, handleDeleteMessage(svc, publisher)))
	mux.HandleFunc("PUT /trips/{id}/messages/{messageId}/reaction", withAuth(authIssuer, handleSetReaction(svc, tripSvc, publisher)))
	mux.HandleFunc("DELETE /trips/{id}/messages/{messageId}/reaction", withAuth(authIssuer, handleRemoveReaction(svc, tripSvc, publisher)))
	mux.HandleFunc("GET /trips/{id}/messages/attachments", withAuth(authIssuer, handleListMessageAttachments(svc, tripSvc)))
	mux.HandleFunc("GET /trips/{id}/messages/links", withAuth(authIssuer, handleListMessageLinks(svc, tripSvc)))
}

type messageResponse struct {
	ID                 uuid.UUID `json:"id"`
	TripID             uuid.UUID `json:"tripId"`
	UserID             uuid.UUID `json:"userId"`
	Body               string    `json:"body"`
	CreatedAt          time.Time `json:"createdAt"`
	IsDiveCenterStaff  bool      `json:"isDiveCenterStaff"`
	MentionsDiveCenter bool      `json:"mentionsDiveCenter"`
	Kind               string    `json:"kind"`
	// FeedbackProvided is per-viewer (has the requesting user submitted trip feedback yet) —
	// only meaningful when Kind is message.KindFeedbackPrompt, false/ignored otherwise.
	FeedbackProvided bool                               `json:"feedbackProvided"`
	Attachments      []attachmentResponse               `json:"attachments"`
	ReplyToID        *string                            `json:"replyToId,omitempty"`
	DeletedAt        *time.Time                         `json:"deletedAt,omitempty"`
	Reactions        map[string]reactionSummaryResponse `json:"reactions"`
}

type reactionSummaryResponse struct {
	Count       int  `json:"count"`
	ReactedByMe bool `json:"reactedByMe"`
}

func toReactionResponses(reactions map[string]message.ReactionSummary) map[string]reactionSummaryResponse {
	out := make(map[string]reactionSummaryResponse, len(reactions))
	for emoji, r := range reactions {
		out[emoji] = reactionSummaryResponse{Count: r.Count, ReactedByMe: r.ReactedByMe}
	}
	return out
}

type attachmentResponse struct {
	URL             string `json:"url"`
	Type            string `json:"type"`
	Filename        string `json:"filename,omitempty"`
	SizeBytes       int64  `json:"sizeBytes,omitempty"`
	DurationSeconds *int   `json:"durationSeconds,omitempty"`
}

// toMessageResponse blanks Body/Attachments whenever the message is soft-deleted — the DB row
// still holds the real content (see message.Repository.SoftDelete's own comment), but nothing
// downstream of this function should ever see it, so every response path (list, send, delete's
// own realtime republish) is guaranteed redacted rather than relying on each caller to remember.
// Normalizes both attachment eras into one list: m.Attachments (chat_message_attachments, see
// migration 000054) if populated, else a single-item list synthesized from the legacy
// AttachmentURL/Type/Filename/SizeBytes scalar columns for a message sent before that migration.
func toMessageResponse(m message.Message, isDiveCenterStaff, feedbackProvided bool, reactions map[string]message.ReactionSummary) messageResponse {
	body := m.Body
	attachments := toAttachmentResponses(m)
	reactionResp := toReactionResponses(reactions)
	var deletedAt *time.Time
	if m.DeletedAt.Valid {
		body = ""
		attachments = nil
		reactionResp = map[string]reactionSummaryResponse{}
		deletedAt = &m.DeletedAt.Time
	}
	var replyToID *string
	if m.ReplyToID.Valid {
		s := m.ReplyToID.UUID.String()
		replyToID = &s
	}
	return messageResponse{
		ID:                 m.ID,
		TripID:             m.TripID,
		UserID:             m.UserID,
		Body:               body,
		CreatedAt:          m.CreatedAt,
		IsDiveCenterStaff:  isDiveCenterStaff,
		MentionsDiveCenter: m.MentionsDiveCenter,
		Kind:               m.Kind,
		FeedbackProvided:   feedbackProvided,
		Attachments:        attachments,
		ReplyToID:          replyToID,
		DeletedAt:          deletedAt,
		Reactions:          reactionResp,
	}
}

func toAttachmentResponses(m message.Message) []attachmentResponse {
	if len(m.Attachments) > 0 {
		out := make([]attachmentResponse, len(m.Attachments))
		for i, a := range m.Attachments {
			out[i] = attachmentResponse{
				URL: a.URL, Type: a.Type, Filename: a.Filename, SizeBytes: a.SizeBytes, DurationSeconds: a.DurationSeconds,
			}
		}
		return out
	}
	if m.AttachmentURL.Valid {
		return []attachmentResponse{{
			URL:       m.AttachmentURL.String,
			Type:      m.AttachmentType.String,
			Filename:  m.AttachmentFilename.String,
			SizeBytes: m.AttachmentSizeBytes.Int64,
		}}
	}
	return []attachmentResponse{}
}

// attachmentRequest is one item in sendMessageRequest.Attachments (and the offer/buddy chat
// send requests) — the client uploads each file via POST .../messages/attachment first (see
// handleUploadMessageAttachment), then passes the returned fields back here unchanged.
type attachmentRequest struct {
	URL             string `json:"url"`
	Type            string `json:"type"`
	Filename        string `json:"filename,omitempty"`
	SizeBytes       int64  `json:"sizeBytes,omitempty"`
	DurationSeconds *int   `json:"durationSeconds,omitempty"`
}

func toAttachments(reqs []attachmentRequest) []message.Attachment {
	if len(reqs) == 0 {
		return nil
	}
	out := make([]message.Attachment, len(reqs))
	for i, a := range reqs {
		out[i] = message.Attachment{URL: a.URL, Type: a.Type, Filename: a.Filename, SizeBytes: a.SizeBytes, DurationSeconds: a.DurationSeconds}
	}
	return out
}

// toAttachments (method form) returns nil when no URL was sent (a plain text message) — used
// by the offer/buddy chat send paths, which only ever accept the one attachment embedded
// directly in their request type (unlike main chat's Attachments list on sendMessageRequest).
func (a attachmentRequest) toAttachments() []message.Attachment {
	if a.URL == "" {
		return nil
	}
	return []message.Attachment{{URL: a.URL, Type: a.Type, Filename: a.Filename, SizeBytes: a.SizeBytes, DurationSeconds: a.DurationSeconds}}
}

// requireParticipant is shared by message/transport/participants handlers — access means
// either joined normally (trip_participants) or being the trip's organizer (HasAccess also
// covers dive-center staff, who never get a trip_participants row for their own center's trips).
func requireParticipant(w http.ResponseWriter, r *http.Request, tripSvc *trip.Service, tripID string, userID uuid.UUID) (uuid.UUID, bool) {
	parsed, hasAccess, err := tripSvc.HasAccess(r.Context(), tripID, userID)
	if err != nil {
		if errors.Is(err, trip.ErrInvalidArgument) {
			writeError(w, http.StatusBadRequest, "invalid trip id")
			return uuid.Nil, false
		}
		writeError(w, http.StatusInternalServerError, "could not verify trip membership")
		return uuid.Nil, false
	}
	if !hasAccess {
		writeError(w, http.StatusForbidden, "not a participant of this trip")
		return uuid.Nil, false
	}
	return parsed, true
}

// diveCenterStaffChecker memoizes IsMember lookups across a batch of messages so a
// history list with many senders doesn't re-check the same user id repeatedly.
type diveCenterStaffChecker struct {
	diveCenterSvc *divecenter.Service
	diveCenterID  uuid.NullUUID
	cache         map[uuid.UUID]bool
}

func newDiveCenterStaffChecker(diveCenterSvc *divecenter.Service, diveCenterID uuid.NullUUID) *diveCenterStaffChecker {
	return &diveCenterStaffChecker{diveCenterSvc: diveCenterSvc, diveCenterID: diveCenterID, cache: map[uuid.UUID]bool{}}
}

func (c *diveCenterStaffChecker) isStaff(ctx context.Context, userID uuid.UUID) bool {
	if !c.diveCenterID.Valid {
		return false
	}
	if v, ok := c.cache[userID]; ok {
		return v
	}
	isMember, err := c.diveCenterSvc.IsMember(ctx, c.diveCenterID.UUID, userID)
	if err != nil {
		isMember = false
	}
	c.cache[userID] = isMember
	return isMember
}

func handleListMessages(svc *message.Service, tripSvc *trip.Service, diveCenterSvc *divecenter.Service, moderationSvc *moderation.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		tripID, ok := requireParticipant(w, r, tripSvc, r.PathValue("id"), userID)
		if !ok {
			return
		}

		t, err := tripSvc.GetTrip(r.Context(), tripID.String())
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not list messages")
			return
		}

		messages, err := svc.List(r.Context(), tripID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not list messages")
			return
		}

		// Best-effort — a lookup failure here must not break the whole chat load, so on error
		// this just falls back to "nothing blocked" rather than failing the request.
		blocked, err := moderationSvc.ListBlockedUserIDs(r.Context(), userID)
		if err != nil {
			log.Printf("list messages: could not load blocked users for %s: %v", userID, err)
			blocked = nil
		}
		if len(blocked) > 0 {
			blockedSet := make(map[uuid.UUID]bool, len(blocked))
			for _, id := range blocked {
				blockedSet[id] = true
			}
			filtered := messages[:0]
			for _, m := range messages {
				if !blockedSet[m.UserID] {
					filtered = append(filtered, m)
				}
			}
			messages = filtered
		}

		// One per-trip fact for the viewer, not per-message — computed once regardless of how
		// many feedback_prompt rows exist (normally at most one).
		hasFeedback, err := tripSvc.HasFeedback(r.Context(), tripID.String(), userID)
		if err != nil {
			log.Printf("list messages: could not check feedback state for trip:%s: %v", tripID, err)
			hasFeedback = false
		}

		ids := make([]uuid.UUID, len(messages))
		for i, m := range messages {
			ids[i] = m.ID
		}
		// Best-effort — same reasoning as the blocked-users lookup above: a reactions fetch
		// failing shouldn't break the whole chat load, just show messages with no reaction
		// pills until the next successful list.
		reactionsByMessage, err := svc.ListReactionsForMessages(r.Context(), ids, userID)
		if err != nil {
			log.Printf("list messages: could not load reactions for trip:%s: %v", tripID, err)
			reactionsByMessage = nil
		}

		checker := newDiveCenterStaffChecker(diveCenterSvc, t.DiveCenterID)
		out := make([]messageResponse, 0, len(messages))
		for _, m := range messages {
			feedbackProvided := m.Kind == message.KindFeedbackPrompt && hasFeedback
			out = append(out, toMessageResponse(m, checker.isStaff(r.Context(), m.UserID), feedbackProvided, reactionsByMessage[m.ID]))
		}
		writeJSON(w, http.StatusOK, out)
	}
}

type sendMessageRequest struct {
	Body               string              `json:"body"`
	MentionsDiveCenter bool                `json:"mentionsDiveCenter"`
	ReplyToID          *string             `json:"replyToId,omitempty"`
	Attachments        []attachmentRequest `json:"attachments,omitempty"`
}

// replyToID parses the optional ReplyToID string into a uuid.NullUUID — an unparsable value
// is treated the same as "not a reply" here; Service.Send does the actual existence/same-trip
// validation and rejects a genuinely bad id with ErrInvalidArgument.
func (req sendMessageRequest) replyToID() uuid.NullUUID {
	if req.ReplyToID == nil {
		return uuid.NullUUID{}
	}
	id, err := uuid.Parse(*req.ReplyToID)
	if err != nil {
		return uuid.NullUUID{}
	}
	return uuid.NullUUID{UUID: id, Valid: true}
}

func handleSendMessage(svc *message.Service, tripSvc *trip.Service, diveCenterSvc *divecenter.Service, profileSvc *profile.Service, publisher *realtime.Publisher, pushSvc *push.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		tripID, ok := requireParticipant(w, r, tripSvc, r.PathValue("id"), userID)
		if !ok {
			return
		}

		t, err := tripSvc.GetTrip(r.Context(), tripID.String())
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not send message")
			return
		}
		// Cancelled trips are read-only — history stays visible (handleListMessages is
		// untouched), but the input is effectively closed server-side too, not just in the UI.
		if err := tripSvc.EnsureNotCancelled(r.Context(), tripID); err != nil {
			if errors.Is(err, trip.ErrTripCancelled) {
				writeError(w, http.StatusConflict, "trip has been cancelled")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not send message")
			return
		}

		var req sendMessageRequest
		dec := json.NewDecoder(io.LimitReader(r.Body, 1<<20))
		if err := dec.Decode(&req); err != nil {
			writeError(w, http.StatusBadRequest, "invalid JSON body")
			return
		}

		// A mention only means something on a business trip — there's no dive center to
		// notify on an individual one, so the flag is silently dropped rather than erroring.
		mentionsDiveCenter := req.MentionsDiveCenter && t.DiveCenterID.Valid
		m, err := svc.Send(r.Context(), tripID, userID, message.Scope{}, req.Body, mentionsDiveCenter, toAttachments(req.Attachments), req.replyToID())
		if err != nil {
			if errors.Is(err, message.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, "body or at least one attachment is required (max 9), or replyToId is invalid")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not send message")
			return
		}

		isDiveCenterStaff := false
		if t.DiveCenterID.Valid {
			isDiveCenterStaff, err = diveCenterSvc.IsMember(r.Context(), t.DiveCenterID.UUID, userID)
			if err != nil {
				isDiveCenterStaff = false
			}
		}
		resp := toMessageResponse(m, isDiveCenterStaff, false, nil)
		// Best-effort — sending implies you've read up to now, so this keeps your own
		// message from ever showing up in your own unread count.
		_ = tripSvc.MarkRead(r.Context(), tripID.String(), userID)
		// Best-effort — REST already persisted the message, realtime push is not required for correctness.
		if pubErr := publisher.Publish(r.Context(), "trip:"+tripID.String(), resp); pubErr != nil {
			log.Printf("realtime publish failed for trip:%s: %v", tripID, pubErr)
		}

		notifyNewMessage(r.Context(), pushSvc, profileSvc, tripSvc, diveCenterSvc, t, m, userID)

		writeJSON(w, http.StatusCreated, resp)
	}
}

// handleDeleteMessage soft-deletes a message — author-only (Service.Delete's own ownership
// check covers that; no separate requireParticipant needed, since being the author already
// implies past trip access, and the trip id for the realtime republish comes off the returned
// row itself rather than needing to be parsed from the URL too).
func handleDeleteMessage(svc *message.Service, publisher *realtime.Publisher) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		messageID, err := uuid.Parse(r.PathValue("messageId"))
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid message id")
			return
		}

		m, err := svc.Delete(r.Context(), messageID, userID)
		if err != nil {
			if errors.Is(err, message.ErrNotFound) {
				writeError(w, http.StatusNotFound, "message not found, already deleted, or not yours to delete")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not delete message")
			return
		}

		resp := toMessageResponse(m, false, false, nil)
		// Best-effort — the delete itself already succeeded above; a failed publish just means
		// other participants see the redacted message on their next list refresh instead of live.
		if pubErr := publisher.Publish(r.Context(), "trip:"+m.TripID.String(), resp); pubErr != nil {
			log.Printf("realtime publish failed for trip:%s: %v", m.TripID, pubErr)
		}

		writeJSON(w, http.StatusOK, resp)
	}
}

type reactionRequest struct {
	Emoji string `json:"emoji"`
}

type reactionResponse struct {
	MessageID uuid.UUID                          `json:"messageId"`
	Reactions map[string]reactionSummaryResponse `json:"reactions"`
}

// handleSetReaction upserts the caller's reaction (one per user per message — Messenger
// semantics, see migration 000055) on a message from any of the three chat scopes (main,
// offer, buddy) — the URL only ever carries the trip id, so this works the same regardless of
// which chat the target message actually belongs to.
func handleSetReaction(svc *message.Service, tripSvc *trip.Service, publisher *realtime.Publisher) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		tripID, ok := requireParticipant(w, r, tripSvc, r.PathValue("id"), userID)
		if !ok {
			return
		}
		messageID, err := uuid.Parse(r.PathValue("messageId"))
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid message id")
			return
		}

		var req reactionRequest
		dec := json.NewDecoder(io.LimitReader(r.Body, 1<<10))
		if err := dec.Decode(&req); err != nil {
			writeError(w, http.StatusBadRequest, "invalid JSON body")
			return
		}

		m, reactions, err := svc.SetReaction(r.Context(), tripID, messageID, userID, req.Emoji)
		if err != nil {
			if errors.Is(err, message.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, "emoji must be one of the supported reactions")
				return
			}
			if errors.Is(err, message.ErrNotFound) {
				writeError(w, http.StatusNotFound, "message not found")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not set reaction")
			return
		}
		publishReactionUpdate(r.Context(), publisher, m, reactions)
		writeJSON(w, http.StatusOK, reactionResponse{MessageID: messageID, Reactions: toReactionResponses(reactions)})
	}
}

// handleRemoveReaction removes the caller's own reaction from a message, if any — idempotent,
// same "no error either way" shape as the rest of this package's delete-ish endpoints.
func handleRemoveReaction(svc *message.Service, tripSvc *trip.Service, publisher *realtime.Publisher) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		tripID, ok := requireParticipant(w, r, tripSvc, r.PathValue("id"), userID)
		if !ok {
			return
		}
		messageID, err := uuid.Parse(r.PathValue("messageId"))
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid message id")
			return
		}

		m, reactions, err := svc.RemoveReaction(r.Context(), tripID, messageID, userID)
		if err != nil {
			if errors.Is(err, message.ErrNotFound) {
				writeError(w, http.StatusNotFound, "message not found")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not remove reaction")
			return
		}
		publishReactionUpdate(r.Context(), publisher, m, reactions)
		writeJSON(w, http.StatusOK, reactionResponse{MessageID: messageID, Reactions: toReactionResponses(reactions)})
	}
}

// publishReactionUpdate broadcasts only the viewer-independent per-emoji counts — ReactedByMe
// is per-viewer and a Centrifugo publish is one shared payload for every subscriber, so it can
// only ever be correct for the one viewer it was computed for. Unlike a full message republish
// (fine for e.g. delete, where every field is viewer-independent), reactions need a distinct
// event shape the app merges in specially — see ChatViewModel's realtime handler, which keeps
// each emoji's own locally-known reactedByMe and only takes the incoming count. Published on
// whichever channel actually matches the message's own chat scope (mirrors handleSendMessage/
// handleSendOfferMessage/handleSendBuddyMessage's own three-way channel choice) — the reaction
// endpoints only take a trip id in their URL, so the message's own Offer/BuddyRequestID (from
// Service.SetReaction/RemoveReaction's returned Message) is what decides this, not the URL.
func publishReactionUpdate(ctx context.Context, publisher *realtime.Publisher, m message.Message, reactions map[string]message.ReactionSummary) {
	channel := "trip:" + m.TripID.String()
	if m.OfferID.Valid {
		channel = "transport_offer:" + m.OfferID.UUID.String()
	} else if m.BuddyRequestID.Valid {
		channel = "buddy_request:" + m.BuddyRequestID.UUID.String()
	}
	counts := make(map[string]int, len(reactions))
	for emoji, r := range reactions {
		counts[emoji] = r.Count
	}
	if pubErr := publisher.Publish(ctx, channel, map[string]any{
		"event":     "reaction_update",
		"messageId": m.ID.String(),
		"counts":    counts,
	}); pubErr != nil {
		log.Printf("realtime publish failed for %s: %v", channel, pubErr)
	}
}

// notifyNewMessage pushes the new message to everyone with access to the trip except its
// sender — trip participants always, plus a business trip's dive center staff only when the
// message explicitly mentions the dive center (see CLAUDE.md's Notifications Stage 1.5 — the
// mention flag exists specifically so every diver message doesn't push every staff member;
// staff who aren't mentioned still see it via admin/'s own in-app unread badge, just not a push).
func notifyNewMessage(ctx context.Context, pushSvc *push.Service, profileSvc *profile.Service, tripSvc *trip.Service, diveCenterSvc *divecenter.Service, t trip.Trip, m message.Message, senderID uuid.UUID) {
	recipients, err := tripSvc.ListParticipantUserIDs(ctx, t.ID.String())
	if err != nil {
		log.Printf("push: could not list participants for trip:%s: %v", t.ID, err)
		return
	}
	if t.DiveCenterID.Valid && m.MentionsDiveCenter {
		staffIDs, err := diveCenterSvc.ListMemberUserIDs(ctx, t.DiveCenterID.UUID)
		if err != nil {
			log.Printf("push: could not list dive center staff for trip:%s: %v", t.ID, err)
		} else {
			recipients = append(recipients, staffIDs...)
		}
	}
	recipients = excludeUser(dedupeUsers(recipients), senderID)
	if mutedIDs, err := tripSvc.ListMutedUserIDs(ctx, t.ID); err != nil {
		log.Printf("push: could not list muted users for trip:%s: %v", t.ID, err)
	} else {
		recipients = excludeUsers(recipients, mutedIDs)
	}
	if len(recipients) == 0 {
		return
	}

	senderName := "New message"
	if sender, err := profileSvc.Get(ctx, senderID); err == nil && sender.DisplayName.Valid && sender.DisplayName.String != "" {
		senderName = sender.DisplayName.String
	}

	pushSvc.SendToUsers(ctx, recipients, push.Notification{
		Title: senderName + " · " + t.Title,
		Body:  pushBodyFor(m),
		Data:  map[string]string{"tripId": t.ID.String(), "type": "message"},
	})
}

// pushBodyFor falls back to a label when the message is attachment-only (empty body) — an
// empty push notification body would otherwise look broken. Checks the new multi-attachment
// list first, falling back to the legacy scalar column for a pre-migration-000054 message.
func pushBodyFor(m message.Message) string {
	body := truncateForPush(m.Body)
	if body != "" {
		return body
	}
	if len(m.Attachments) > 1 {
		return fmt.Sprintf("📎 %d attachments", len(m.Attachments))
	}
	attType := m.AttachmentType.String
	if len(m.Attachments) == 1 {
		attType = m.Attachments[0].Type
	}
	switch attType {
	case message.AttachmentTypeImage:
		return "📷 Photo"
	case message.AttachmentTypeVideo:
		return "🎬 Video"
	case message.AttachmentTypePDF:
		return "📄 PDF"
	default:
		return body
	}
}

// parseBeforeParam parses the optional "before" cursor (RFC3339) — nil means "most recent page".
func parseBeforeParam(r *http.Request) (*time.Time, error) {
	raw := r.URL.Query().Get("before")
	if raw == "" {
		return nil, nil
	}
	t, err := time.Parse(time.RFC3339, raw)
	if err != nil {
		return nil, err
	}
	return &t, nil
}

// parseLimitParam clamps to [1, max]; an unparsable or missing value falls back to def.
func parseLimitParam(r *http.Request, def, max int) int {
	raw := r.URL.Query().Get("limit")
	if raw == "" {
		return def
	}
	n, err := strconv.Atoi(raw)
	if err != nil || n < 1 {
		return def
	}
	if n > max {
		return max
	}
	return n
}

// mediaItemResponse is one grid entry for the Media/Files tab — a slimmer shape than
// messageResponse (no reply/reactions/staff context, none of which the grid needs), one per
// attachment rather than per message. attachments is always exactly one item.
type mediaItemResponse struct {
	MessageID  uuid.UUID          `json:"messageId"`
	UserID     uuid.UUID          `json:"userId"`
	CreatedAt  time.Time          `json:"createdAt"`
	Attachment attachmentResponse `json:"attachment"`
}

func toMediaItemResponse(item message.MediaItem) mediaItemResponse {
	return mediaItemResponse{
		MessageID: item.MessageID,
		UserID:    item.UserID,
		CreatedAt: item.CreatedAt,
		Attachment: attachmentResponse{
			URL: item.URL, Type: item.Type, Filename: item.Filename, SizeBytes: item.SizeBytes, DurationSeconds: item.DurationSeconds,
		},
	}
}

// attachmentTypesForQuery maps the tab's ?type= query param to the set of attachment types it
// should return — "media" (image+video, the Media tab) and "pdf" (the Files tab) are the only
// two the app ever requests; the bare "image"/"video" values from before this stage still work
// too, in case an older client build is still in the wild for a bit.
func attachmentTypesForQuery(raw string) ([]string, bool) {
	switch raw {
	case "media":
		return []string{message.AttachmentTypeImage, message.AttachmentTypeVideo}, true
	case message.AttachmentTypeImage, message.AttachmentTypeVideo, message.AttachmentTypePDF:
		return []string{raw}, true
	default:
		return nil, false
	}
}

// handleListMessageAttachments backs the Media ("type=media") and Files ("type=pdf") tabs —
// main trip chat only (v1 scope), newest first, cursor-paginated via ?before=<RFC3339>.
func handleListMessageAttachments(svc *message.Service, tripSvc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		tripID, ok := requireParticipant(w, r, tripSvc, r.PathValue("id"), userID)
		if !ok {
			return
		}

		attachmentTypes, ok := attachmentTypesForQuery(r.URL.Query().Get("type"))
		if !ok {
			writeError(w, http.StatusBadRequest, "type must be 'media' or 'pdf'")
			return
		}
		before, err := parseBeforeParam(r)
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid before cursor")
			return
		}
		limit := parseLimitParam(r, 50, 100)

		items, err := svc.ListAttachments(r.Context(), tripID, attachmentTypes, before, limit)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not list attachments")
			return
		}

		out := make([]mediaItemResponse, 0, len(items))
		for _, item := range items {
			out = append(out, toMediaItemResponse(item))
		}
		writeJSON(w, http.StatusOK, out)
	}
}

type linkResponse struct {
	MessageID uuid.UUID `json:"messageId"`
	UserID    uuid.UUID `json:"userId"`
	URL       string    `json:"url"`
	CreatedAt time.Time `json:"createdAt"`
}

// urlPattern mirrors the Postgres prefilter in ListLinksByTrip; trailingPunctuation strips
// characters a URL is unlikely to end with but that commonly follow one in prose ("see
// https://x.com/plan.", "(https://x.com/plan)").
var urlPattern = regexp.MustCompile(`https?://\S+`)
var trailingPunctuation = ".,)]!?\"'"

// handleListMessageLinks backs the Links tab — every URL mentioned in main-chat message text
// (not uploaded files), newest first, cursor-paginated via ?before=<RFC3339>.
func handleListMessageLinks(svc *message.Service, tripSvc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		tripID, ok := requireParticipant(w, r, tripSvc, r.PathValue("id"), userID)
		if !ok {
			return
		}

		before, err := parseBeforeParam(r)
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid before cursor")
			return
		}
		limit := parseLimitParam(r, 50, 100)

		rows, err := svc.ListLinks(r.Context(), tripID, before, limit)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not list links")
			return
		}

		out := []linkResponse{}
		for _, row := range rows {
			for _, match := range urlPattern.FindAllString(row.Body, -1) {
				out = append(out, linkResponse{
					MessageID: row.ID,
					UserID:    row.UserID,
					URL:       strings.TrimRight(match, trailingPunctuation),
					CreatedAt: row.CreatedAt,
				})
			}
		}
		writeJSON(w, http.StatusOK, out)
	}
}

// truncateForPush keeps push payloads small — cuts on a rune boundary since message bodies
// aren't guaranteed ASCII.
func truncateForPush(body string) string {
	const maxRunes = 150
	runes := []rune(body)
	if len(runes) <= maxRunes {
		return body
	}
	return string(runes[:maxRunes]) + "…"
}
