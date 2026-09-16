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
	// FeedbackProvided is per-viewer and only meaningful when Kind is message.KindFeedbackPrompt.
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

// toMessageResponse blanks Body/Attachments for a soft-deleted message (the DB row still holds the real content) and normalizes both attachment eras into one list.
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

// attachmentRequest carries back the fields the client got from uploading the file via POST .../messages/attachment first.
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

// toAttachments (method form) returns nil when no URL was sent, since the offer/buddy chat paths only ever accept one embedded attachment, unlike main chat's Attachments list.
func (a attachmentRequest) toAttachments() []message.Attachment {
	if a.URL == "" {
		return nil
	}
	return []message.Attachment{{URL: a.URL, Type: a.Type, Filename: a.Filename, SizeBytes: a.SizeBytes, DurationSeconds: a.DurationSeconds}}
}

// requireParticipant treats access as joined normally, being the organizer, or dive-center staff, none of whom get a trip_participants row for their own center's trips.
func requireParticipant(w http.ResponseWriter, r *http.Request, tripSvc *trip.Service, tripID string, userID uuid.UUID) (uuid.UUID, bool) {
	parsed, hasAccess, err := tripSvc.HasAccess(r.Context(), tripID, userID)
	if err != nil {
		if errors.Is(err, trip.ErrInvalidArgument) {
			writeError(w, http.StatusBadRequest, ErrCodeGeneric)
			return uuid.Nil, false
		}
		writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
		return uuid.Nil, false
	}
	if !hasAccess {
		writeError(w, http.StatusForbidden, ErrCodeNotParticipant)
		return uuid.Nil, false
	}
	return parsed, true
}

// diveCenterStaffChecker memoizes IsMember lookups so a history list with many senders doesn't re-check the same user id repeatedly.
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
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		messages, err := svc.List(r.Context(), tripID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		// Best-effort: a lookup failure falls back to "nothing blocked" rather than failing the whole chat load.
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

		// One per-trip fact for the viewer, not per-message, computed once regardless of how many feedback_prompt rows exist.
		hasFeedback, err := tripSvc.HasFeedback(r.Context(), tripID.String(), userID)
		if err != nil {
			log.Printf("list messages: could not check feedback state for trip:%s: %v", tripID, err)
			hasFeedback = false
		}

		ids := make([]uuid.UUID, len(messages))
		for i, m := range messages {
			ids[i] = m.ID
		}
		// Best-effort, same reasoning as the blocked-users lookup above: fall back to no reaction pills rather than failing the load.
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

// replyToID treats an unparsable value the same as "not a reply"; Service.Send does the actual existence/same-trip validation.
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
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}
		// Cancelled trips are read-only: input is closed server-side too, not just in the UI.
		if err := tripSvc.EnsureNotCancelled(r.Context(), tripID); err != nil {
			if errors.Is(err, trip.ErrTripCancelled) {
				writeError(w, http.StatusConflict, ErrCodeTripCancelled)
				return
			}
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		var req sendMessageRequest
		dec := json.NewDecoder(io.LimitReader(r.Body, 1<<20))
		if err := dec.Decode(&req); err != nil {
			writeError(w, http.StatusBadRequest, ErrCodeGeneric)
			return
		}

		// A mention only means something on a business trip, so the flag is silently dropped rather than erroring on an individual one.
		mentionsDiveCenter := req.MentionsDiveCenter && t.DiveCenterID.Valid
		m, err := svc.Send(r.Context(), tripID, userID, message.Scope{}, req.Body, mentionsDiveCenter, toAttachments(req.Attachments), req.replyToID())
		if err != nil {
			if errors.Is(err, message.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, ErrCodeMessageBodyOrAttachment)
				return
			}
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
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
		// Best-effort: sending implies you've read up to now, keeping your own message out of your own unread count.
		_ = tripSvc.MarkRead(r.Context(), tripID.String(), userID)
		// Best-effort — REST already persisted the message, realtime push is not required for correctness.
		if pubErr := publisher.Publish(r.Context(), "trip:"+tripID.String(), resp); pubErr != nil {
			log.Printf("realtime publish failed for trip:%s: %v", tripID, pubErr)
		}

		notifyNewMessage(r.Context(), pushSvc, profileSvc, tripSvc, diveCenterSvc, t, m, userID)

		writeJSON(w, http.StatusCreated, resp)
	}
}

// handleDeleteMessage needs no separate requireParticipant, since being the author (Service.Delete's own check) already implies past trip access.
func handleDeleteMessage(svc *message.Service, publisher *realtime.Publisher) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		messageID, err := uuid.Parse(r.PathValue("messageId"))
		if err != nil {
			writeError(w, http.StatusBadRequest, ErrCodeGeneric)
			return
		}

		m, err := svc.Delete(r.Context(), messageID, userID)
		if err != nil {
			if errors.Is(err, message.ErrNotFound) {
				writeError(w, http.StatusNotFound, ErrCodeMessageNotFoundOrNotYours)
				return
			}
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		resp := toMessageResponse(m, false, false, nil)
		// Best-effort: the delete already succeeded above, so a failed publish just delays the redaction to the next list refresh.
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

// handleSetReaction upserts one reaction per user per message, from any of the three chat scopes, since the URL only ever carries the trip id regardless of which chat the message belongs to.
func handleSetReaction(svc *message.Service, tripSvc *trip.Service, publisher *realtime.Publisher) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		tripID, ok := requireParticipant(w, r, tripSvc, r.PathValue("id"), userID)
		if !ok {
			return
		}
		messageID, err := uuid.Parse(r.PathValue("messageId"))
		if err != nil {
			writeError(w, http.StatusBadRequest, ErrCodeGeneric)
			return
		}

		var req reactionRequest
		dec := json.NewDecoder(io.LimitReader(r.Body, 1<<10))
		if err := dec.Decode(&req); err != nil {
			writeError(w, http.StatusBadRequest, ErrCodeGeneric)
			return
		}

		m, reactions, err := svc.SetReaction(r.Context(), tripID, messageID, userID, req.Emoji)
		if err != nil {
			if errors.Is(err, message.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, ErrCodeInvalidReactionEmoji)
				return
			}
			if errors.Is(err, message.ErrNotFound) {
				writeError(w, http.StatusNotFound, ErrCodeMessageNotFound)
				return
			}
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}
		publishReactionUpdate(r.Context(), publisher, m, reactions)
		writeJSON(w, http.StatusOK, reactionResponse{MessageID: messageID, Reactions: toReactionResponses(reactions)})
	}
}

// handleRemoveReaction is idempotent, same "no error either way" shape as this package's other delete-ish endpoints.
func handleRemoveReaction(svc *message.Service, tripSvc *trip.Service, publisher *realtime.Publisher) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		tripID, ok := requireParticipant(w, r, tripSvc, r.PathValue("id"), userID)
		if !ok {
			return
		}
		messageID, err := uuid.Parse(r.PathValue("messageId"))
		if err != nil {
			writeError(w, http.StatusBadRequest, ErrCodeGeneric)
			return
		}

		m, reactions, err := svc.RemoveReaction(r.Context(), tripID, messageID, userID)
		if err != nil {
			if errors.Is(err, message.ErrNotFound) {
				writeError(w, http.StatusNotFound, ErrCodeMessageNotFound)
				return
			}
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}
		publishReactionUpdate(r.Context(), publisher, m, reactions)
		writeJSON(w, http.StatusOK, reactionResponse{MessageID: messageID, Reactions: toReactionResponses(reactions)})
	}
}

// publishReactionUpdate broadcasts only per-emoji counts, never the per-viewer ReactedByMe, and on whichever channel matches the message's own chat scope, since the reaction endpoints' URL only ever carries a trip id.
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

// notifyNewMessage includes a business trip's dive center staff only when the message explicitly mentions the dive center, so not every diver message pushes every staff member.
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
	// Archived stays fully functional (unread count still climbs) but never pushes, same posture as muted via a separate, independent flag.
	if archivedIDs, err := tripSvc.ListArchivedUserIDs(ctx, t.ID); err != nil {
		log.Printf("push: could not list archived users for trip:%s: %v", t.ID, err)
	} else {
		recipients = excludeUsers(recipients, archivedIDs)
	}
	if len(recipients) == 0 {
		return
	}

	senderName := "New message"
	if sender, err := profileSvc.Get(ctx, senderID); err == nil && sender.DisplayName.Valid && sender.DisplayName.String != "" {
		senderName = sender.DisplayName.String
	}

	// Same three-tier Title/Subtitle/Body shape as notifyNewOfferMessage/notifyNewBuddyMessage, so a diver can tell at a glance which of a trip's chats a push is about.
	pushSvc.SendToUsers(ctx, recipients, push.Notification{
		Title:    t.Title,
		Subtitle: "Chat",
		Body:     senderName + ": " + pushBodyFor(m),
		Data:     map[string]string{"tripId": t.ID.String(), "type": "message", "chatScope": "chat"},
	})
}

// pushBodyFor falls back to a label when the message is attachment-only, since an empty push notification body would otherwise look broken.
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

// mediaItemResponse is one grid entry for the Media/Files tab, one per attachment rather than per message, deliberately slimmer than messageResponse.
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

// attachmentTypesForQuery keeps accepting the older bare "image"/"video" values in case an older client build is still in the wild.
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

// handleListMessageAttachments backs the Media/Files tabs, main trip chat only (v1 scope), newest first, cursor-paginated via ?before=<RFC3339>.
func handleListMessageAttachments(svc *message.Service, tripSvc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		tripID, ok := requireParticipant(w, r, tripSvc, r.PathValue("id"), userID)
		if !ok {
			return
		}

		attachmentTypes, ok := attachmentTypesForQuery(r.URL.Query().Get("type"))
		if !ok {
			writeError(w, http.StatusBadRequest, ErrCodeInvalidAttachmentType)
			return
		}
		before, err := parseBeforeParam(r)
		if err != nil {
			writeError(w, http.StatusBadRequest, ErrCodeGeneric)
			return
		}
		limit := parseLimitParam(r, 50, 100)

		items, err := svc.ListAttachments(r.Context(), tripID, attachmentTypes, before, limit)
		if err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
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

// urlPattern mirrors the Postgres prefilter in ListLinksByTrip; trailingPunctuation strips characters that commonly follow a URL in prose (e.g. "see https://x.com/plan.").
var urlPattern = regexp.MustCompile(`https?://\S+`)
var trailingPunctuation = ".,)]!?\"'"

// handleListMessageLinks backs the Links tab: every URL mentioned in main-chat message text (not uploaded files), newest first, cursor-paginated via ?before=<RFC3339>.
func handleListMessageLinks(svc *message.Service, tripSvc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		tripID, ok := requireParticipant(w, r, tripSvc, r.PathValue("id"), userID)
		if !ok {
			return
		}

		before, err := parseBeforeParam(r)
		if err != nil {
			writeError(w, http.StatusBadRequest, ErrCodeGeneric)
			return
		}
		limit := parseLimitParam(r, 50, 100)

		rows, err := svc.ListLinks(r.Context(), tripID, before, limit)
		if err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
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

// truncateForPush cuts on a rune boundary since message bodies aren't guaranteed ASCII.
func truncateForPush(body string) string {
	const maxRunes = 150
	runes := []rune(body)
	if len(runes) <= maxRunes {
		return body
	}
	return string(runes[:maxRunes]) + "…"
}
