package server

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"log"
	"net/http"
	"time"

	"divebubble_be/internal/auth"
	"divebubble_be/internal/buddy"
	"divebubble_be/internal/divecenter"
	"divebubble_be/internal/message"
	"divebubble_be/internal/moderation"
	"divebubble_be/internal/profile"
	"divebubble_be/internal/push"
	"divebubble_be/internal/realtime"
	"divebubble_be/internal/trip"

	"github.com/google/uuid"
)

func registerBuddyRoutes(
	mux *http.ServeMux,
	svc *buddy.Service,
	tripSvc *trip.Service,
	diveCenterSvc *divecenter.Service,
	profileSvc *profile.Service,
	authIssuer *auth.TokenIssuer,
	pushSvc *push.Service,
	messageSvc *message.Service,
	moderationSvc *moderation.Service,
	publisher *realtime.Publisher,
) {
	mux.HandleFunc("GET /trips/{id}/buddy", withAuth(authIssuer, handleListBuddyRequests(svc, tripSvc, profileSvc)))
	mux.HandleFunc("POST /trips/{id}/buddy", withAuth(authIssuer, handleCreateBuddyRequest(svc, tripSvc, profileSvc)))
	mux.HandleFunc("POST /trips/{id}/buddy/{requestId}/join", withAuth(authIssuer, handleJoinBuddyRequest(svc, tripSvc, profileSvc, pushSvc, messageSvc, publisher)))
	mux.HandleFunc("GET /trips/{id}/buddy/{requestId}/joins", withAuth(authIssuer, handleListBuddyRequestJoins(svc, tripSvc)))
	mux.HandleFunc("GET /trips/{id}/buddy/alert", withAuth(authIssuer, handleGetBuddyAlert(svc, tripSvc)))
	mux.HandleFunc("GET /trips/{id}/buddy/{requestId}/messages", withAuth(authIssuer, handleListBuddyMessages(svc, tripSvc, diveCenterSvc, moderationSvc, messageSvc)))
	mux.HandleFunc("POST /trips/{id}/buddy/{requestId}/messages", withAuth(authIssuer, handleSendBuddyMessage(svc, tripSvc, diveCenterSvc, profileSvc, pushSvc, messageSvc, publisher)))
	mux.HandleFunc("POST /trips/{id}/buddy/{requestId}/leave", withAuth(authIssuer, handleLeaveBuddyRequest(svc, tripSvc)))
	mux.HandleFunc("POST /trips/{id}/buddy/{requestId}/dissolve", withAuth(authIssuer, handleDissolveBuddyRequest(svc, tripSvc, publisher)))
	mux.HandleFunc("POST /trips/{id}/buddy/{requestId}/read", withAuth(authIssuer, handleMarkBuddyRequestRead(svc, tripSvc)))
}

// requireBuddyRequestAccess is requireParticipant plus a request-level check: only the creator or someone who's joined may read/post/manage it.
func requireBuddyRequestAccess(w http.ResponseWriter, r *http.Request, buddySvc *buddy.Service, tripSvc *trip.Service, tripIDStr, requestIDStr string, userID uuid.UUID) (buddy.Request, bool) {
	tripID, ok := requireParticipant(w, r, tripSvc, tripIDStr, userID)
	if !ok {
		return buddy.Request{}, false
	}

	requestID, err := uuid.Parse(requestIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, ErrCodeGeneric)
		return buddy.Request{}, false
	}

	req, err := buddySvc.Repo.GetByID(r.Context(), requestID)
	if err != nil {
		if errors.Is(err, buddy.ErrNotFound) {
			writeError(w, http.StatusNotFound, ErrCodeBuddyRequestNotFound)
			return buddy.Request{}, false
		}
		writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
		return buddy.Request{}, false
	}
	if req.TripID != tripID {
		writeError(w, http.StatusNotFound, ErrCodeBuddyRequestNotFound)
		return buddy.Request{}, false
	}
	if req.UserID == userID {
		return req, true
	}

	isJoined, err := buddySvc.Repo.IsJoined(r.Context(), requestID, userID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
		return buddy.Request{}, false
	}
	if !isJoined {
		writeError(w, http.StatusForbidden, ErrCodeNotPartOfBuddyGroup)
		return buddy.Request{}, false
	}
	return req, true
}

type buddyRequestResponse struct {
	ID                uuid.UUID `json:"id"`
	TripID            uuid.UUID `json:"tripId"`
	UserID            uuid.UUID `json:"userId"`
	CreatedAt         time.Time `json:"createdAt"`
	JoinedCount       int       `json:"joinedCount"`
	Joined            bool      `json:"joined"`
	MaxMembers        int       `json:"maxMembers"`
	CreatorName       string    `json:"creatorName"`
	CreatorLevel      *string   `json:"creatorLevel,omitempty"`
	CreatorDiveCount  int       `json:"creatorDiveCount"`
	HasUnreadMessages bool      `json:"hasUnreadMessages"`
}

func toBuddyRequestResponse(req buddy.Request, creator profile.Profile) buddyRequestResponse {
	creatorName := "Diver"
	if creator.DisplayName.Valid && creator.DisplayName.String != "" {
		creatorName = creator.DisplayName.String
	}
	return buddyRequestResponse{
		ID:                req.ID,
		TripID:            req.TripID,
		UserID:            req.UserID,
		CreatedAt:         req.CreatedAt,
		JoinedCount:       req.JoinedCount,
		Joined:            req.Joined,
		MaxMembers:        buddy.MaxMembers,
		CreatorName:       creatorName,
		CreatorLevel:      nullStringPtr(creator.CertificationLevel),
		CreatorDiveCount:  creator.DiveCount,
		HasUnreadMessages: req.HasUnreadMessages,
	}
}

// handleListBuddyRequests enriches each row with the creator's profile server-side (one Get per row, acceptable at this scale) to avoid per-row client-side fetch flicker.
func handleListBuddyRequests(svc *buddy.Service, tripSvc *trip.Service, profileSvc *profile.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		tripID, ok := requireParticipant(w, r, tripSvc, r.PathValue("id"), userID)
		if !ok {
			return
		}

		requests, err := svc.List(r.Context(), tripID, userID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		out := make([]buddyRequestResponse, 0, len(requests))
		for _, req := range requests {
			creator, err := profileSvc.Get(r.Context(), req.UserID)
			if err != nil {
				creator = profile.Profile{}
			}
			out = append(out, toBuddyRequestResponse(req, creator))
		}
		writeJSON(w, http.StatusOK, out)
	}
}

func handleCreateBuddyRequest(svc *buddy.Service, tripSvc *trip.Service, profileSvc *profile.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		tripID, ok := requireParticipant(w, r, tripSvc, r.PathValue("id"), userID)
		if !ok {
			return
		}
		// A cancelled trip is dead — no reason to keep arranging buddies for it.
		if err := tripSvc.EnsureNotCancelled(r.Context(), tripID); err != nil {
			if errors.Is(err, trip.ErrTripCancelled) {
				writeError(w, http.StatusConflict, ErrCodeTripCancelled)
				return
			}
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		req, err := svc.Create(r.Context(), tripID, userID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		creator, err := profileSvc.Get(r.Context(), userID)
		if err != nil {
			creator = profile.Profile{}
		}
		writeJSON(w, http.StatusCreated, toBuddyRequestResponse(req, creator))
	}
}

func handleJoinBuddyRequest(svc *buddy.Service, tripSvc *trip.Service, profileSvc *profile.Service, pushSvc *push.Service, messageSvc *message.Service, publisher *realtime.Publisher) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		tripID, ok := requireParticipant(w, r, tripSvc, r.PathValue("id"), userID)
		if !ok {
			return
		}
		// Joining is blocked too, not just creating, since the trip is dead either way.
		if err := tripSvc.EnsureNotCancelled(r.Context(), tripID); err != nil {
			if errors.Is(err, trip.ErrTripCancelled) {
				writeError(w, http.StatusConflict, ErrCodeTripCancelled)
				return
			}
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		requestID, err := uuid.Parse(r.PathValue("requestId"))
		if err != nil {
			writeError(w, http.StatusBadRequest, ErrCodeGeneric)
			return
		}

		req, err := svc.Join(r.Context(), requestID, userID)
		if err != nil {
			if errors.Is(err, buddy.ErrNotFound) {
				writeError(w, http.StatusNotFound, ErrCodeBuddyRequestNotFound)
				return
			}
			if errors.Is(err, buddy.ErrFull) {
				writeError(w, http.StatusConflict, ErrCodeBuddyGroupFull)
				return
			}
			if errors.Is(err, buddy.ErrAlreadyBooked) {
				writeError(w, http.StatusConflict, ErrCodeAlreadyInBuddyGroup)
				return
			}
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		if req.UserID != userID {
			if t, err := tripSvc.GetTrip(r.Context(), tripID.String()); err == nil {
				joinerName := "Someone"
				if joiner, err := profileSvc.Get(r.Context(), userID); err == nil && joiner.DisplayName.Valid && joiner.DisplayName.String != "" {
					joinerName = joiner.DisplayName.String
				}
				pushSvc.SendToUsers(r.Context(), []uuid.UUID{req.UserID}, push.Notification{
					Title:    t.Title,
					Subtitle: "Buddy chat",
					Body:     joinerName + " joined your buddy group.",
					Data:     map[string]string{"tripId": t.ID.String(), "type": "buddy_joined", "chatScope": "buddy"},
				})

				// Not idempotent like SendSystem, since every new joiner needs their own announcement.
				msg, sysErr := messageSvc.PostSystemEvent(r.Context(), tripID, message.Scope{BuddyRequestID: uuid.NullUUID{UUID: requestID, Valid: true}}, message.KindBuddyJoined, joinerName+" joined your buddy group")
				if sysErr != nil {
					log.Printf("buddy chat: could not post join system message for request:%s: %v", requestID, sysErr)
				} else if pubErr := publisher.Publish(r.Context(), "buddy_request:"+requestID.String(), toMessageResponse(msg, false, false, nil)); pubErr != nil {
					log.Printf("realtime publish failed for buddy_request:%s: %v", requestID, pubErr)
				}
			}

			// Marked read explicitly because the system join message is attributed to message.SystemUserID, so the unread check can't tell it was the joiner's own action.
			if err := svc.MarkRead(r.Context(), requestID, userID); err != nil {
				log.Printf("buddy chat: could not mark request read for joiner:%s request:%s: %v", userID, requestID, err)
			}
		}

		writeJSON(w, http.StatusOK, map[string]bool{"joined": true})
	}
}

// handleGetBuddyAlert both reads and clears the alert, since viewing the Buddy tab is what acknowledges it.
func handleGetBuddyAlert(svc *buddy.Service, tripSvc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		tripID, ok := requireParticipant(w, r, tripSvc, r.PathValue("id"), userID)
		if !ok {
			return
		}

		hasAlert, err := svc.HasAlert(r.Context(), tripID, userID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}
		if hasAlert {
			_ = svc.ClearAlert(r.Context(), tripID, userID)
		}
		writeJSON(w, http.StatusOK, map[string]bool{"hasAlert": hasAlert})
	}
}

func handleListBuddyRequestJoins(svc *buddy.Service, tripSvc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		_, ok := requireParticipant(w, r, tripSvc, r.PathValue("id"), userID)
		if !ok {
			return
		}

		requestID, err := uuid.Parse(r.PathValue("requestId"))
		if err != nil {
			writeError(w, http.StatusBadRequest, ErrCodeGeneric)
			return
		}

		userIDs, err := svc.ListJoins(r.Context(), requestID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		out := make([]joinedUserResponse, 0, len(userIDs))
		for _, id := range userIDs {
			out = append(out, joinedUserResponse{UserID: id})
		}
		writeJSON(w, http.StatusOK, out)
	}
}

func handleListBuddyMessages(buddySvc *buddy.Service, tripSvc *trip.Service, diveCenterSvc *divecenter.Service, moderationSvc *moderation.Service, messageSvc *message.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		req, ok := requireBuddyRequestAccess(w, r, buddySvc, tripSvc, r.PathValue("id"), r.PathValue("requestId"), userID)
		if !ok {
			return
		}

		t, err := tripSvc.GetTrip(r.Context(), req.TripID.String())
		if err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		messages, err := messageSvc.ListByBuddyRequest(r.Context(), req.ID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		// Same best-effort blocked-user filtering as the main chat (routes_message.go).
		blocked, err := moderationSvc.ListBlockedUserIDs(r.Context(), userID)
		if err != nil {
			log.Printf("list buddy messages: could not load blocked users for %s: %v", userID, err)
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

		ids := make([]uuid.UUID, len(messages))
		for i, m := range messages {
			ids[i] = m.ID
		}
		reactionsByMessage, err := messageSvc.ListReactionsForMessages(r.Context(), ids, userID)
		if err != nil {
			log.Printf("list buddy messages: could not load reactions for buddy_request:%s: %v", req.ID, err)
			reactionsByMessage = nil
		}

		checker := newDiveCenterStaffChecker(diveCenterSvc, t.DiveCenterID)
		out := make([]messageResponse, 0, len(messages))
		for _, m := range messages {
			// feedbackProvided is always false: a buddy chat never carries a feedback_prompt message.
			out = append(out, toMessageResponse(m, checker.isStaff(r.Context(), m.UserID), false, reactionsByMessage[m.ID]))
		}
		writeJSON(w, http.StatusOK, out)
	}
}

type sendBuddyMessageRequest struct {
	Body string `json:"body"`
	attachmentRequest
}

func handleSendBuddyMessage(buddySvc *buddy.Service, tripSvc *trip.Service, diveCenterSvc *divecenter.Service, profileSvc *profile.Service, pushSvc *push.Service, messageSvc *message.Service, publisher *realtime.Publisher) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		req, ok := requireBuddyRequestAccess(w, r, buddySvc, tripSvc, r.PathValue("id"), r.PathValue("requestId"), userID)
		if !ok {
			return
		}
		if err := tripSvc.EnsureNotCancelled(r.Context(), req.TripID); err != nil {
			if errors.Is(err, trip.ErrTripCancelled) {
				writeError(w, http.StatusConflict, ErrCodeTripCancelled)
				return
			}
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		var body sendBuddyMessageRequest
		dec := json.NewDecoder(io.LimitReader(r.Body, 1<<20))
		if err := dec.Decode(&body); err != nil {
			writeError(w, http.StatusBadRequest, ErrCodeGeneric)
			return
		}

		m, err := messageSvc.Send(r.Context(), req.TripID, userID, message.Scope{BuddyRequestID: uuid.NullUUID{UUID: req.ID, Valid: true}}, body.Body, false, body.toAttachments(), uuid.NullUUID{})
		if err != nil {
			if errors.Is(err, message.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, ErrCodeBodyOrAttachmentRequired)
				return
			}
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		isDiveCenterStaff := false
		t, tErr := tripSvc.GetTrip(r.Context(), req.TripID.String())
		if tErr == nil && t.DiveCenterID.Valid {
			isDiveCenterStaff, _ = diveCenterSvc.IsMember(r.Context(), t.DiveCenterID.UUID, userID)
		}

		resp := toMessageResponse(m, isDiveCenterStaff, false, nil)
		// Best-effort — REST already persisted the message, realtime push is not required for correctness.
		if pubErr := publisher.Publish(r.Context(), "buddy_request:"+req.ID.String(), resp); pubErr != nil {
			log.Printf("realtime publish failed for buddy_request:%s: %v", req.ID, pubErr)
		}
		// Also pinged on the trip channel so trip-level listeners see sub-chat activity (see handleSendOfferMessage).
		if pubErr := publisher.Publish(r.Context(), "trip:"+req.TripID.String(), map[string]string{
			"event": "sub_chat_activity", "scope": "buddy", "userId": userID.String(),
		}); pubErr != nil {
			log.Printf("realtime publish failed for trip:%s: %v", req.TripID, pubErr)
		}
		if tErr == nil {
			notifyNewBuddyMessage(r.Context(), pushSvc, profileSvc, buddySvc, t, req, m, userID)
		}
		writeJSON(w, http.StatusCreated, resp)
	}
}

// handleLeaveBuddyRequest is for a joiner only; the creator's equivalent is handleDissolveBuddyRequest.
func handleLeaveBuddyRequest(svc *buddy.Service, tripSvc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		req, ok := requireBuddyRequestAccess(w, r, svc, tripSvc, r.PathValue("id"), r.PathValue("requestId"), userID)
		if !ok {
			return
		}
		if req.UserID == userID {
			writeError(w, http.StatusBadRequest, ErrCodeCreatorCannotLeaveBuddyGroup)
			return
		}
		if err := svc.Leave(r.Context(), req.ID, userID); err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}
		w.WriteHeader(http.StatusNoContent)
	}
}

// handleDissolveBuddyRequest publishes the "dissolved" event only after the delete succeeds, so a rejected/failed attempt never falsely signals dissolution.
func handleDissolveBuddyRequest(svc *buddy.Service, tripSvc *trip.Service, publisher *realtime.Publisher) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		req, ok := requireBuddyRequestAccess(w, r, svc, tripSvc, r.PathValue("id"), r.PathValue("requestId"), userID)
		if !ok {
			return
		}
		if err := svc.Dissolve(r.Context(), req.ID, userID); err != nil {
			if errors.Is(err, buddy.ErrForbidden) {
				writeError(w, http.StatusForbidden, ErrCodeOnlyCreatorCanDissolveBuddyGroup)
				return
			}
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}
		if pubErr := publisher.Publish(r.Context(), "buddy_request:"+req.ID.String(), map[string]string{"event": "dissolved"}); pubErr != nil {
			log.Printf("realtime publish failed for buddy_request:%s: %v", req.ID, pubErr)
		}
		w.WriteHeader(http.StatusNoContent)
	}
}

// notifyNewBuddyMessage notifies only the request's own members, narrower than notifyNewMessage's whole-trip reach, since the rest of the trip can't see a buddy group they haven't joined.
func notifyNewBuddyMessage(ctx context.Context, pushSvc *push.Service, profileSvc *profile.Service, buddySvc *buddy.Service, t trip.Trip, req buddy.Request, m message.Message, senderID uuid.UUID) {
	joinedIDs, err := buddySvc.ListJoins(ctx, req.ID)
	if err != nil {
		log.Printf("push: could not list joins for buddy request:%s: %v", req.ID, err)
		return
	}
	recipients := excludeUser(dedupeUsers(append(joinedIDs, req.UserID)), senderID)
	if len(recipients) == 0 {
		return
	}

	senderName := "New message"
	if sender, err := profileSvc.Get(ctx, senderID); err == nil && sender.DisplayName.Valid && sender.DisplayName.String != "" {
		senderName = sender.DisplayName.String
	}
	// Subtitle/chatScope let the diver (and the tap handler) tell this apart from the trip's main chat.
	pushSvc.SendToUsers(ctx, recipients, push.Notification{
		Title:    t.Title,
		Subtitle: "Buddy chat",
		Body:     senderName + ": " + pushBodyFor(m),
		Data:     map[string]string{"tripId": t.ID.String(), "type": "message", "chatScope": "buddy"},
	})
}

// handleMarkBuddyRequestRead marks only this one group's chat read, unlike trip.MarkRead which clears the whole Buddy tab's alert dot.
func handleMarkBuddyRequestRead(svc *buddy.Service, tripSvc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		req, ok := requireBuddyRequestAccess(w, r, svc, tripSvc, r.PathValue("id"), r.PathValue("requestId"), userID)
		if !ok {
			return
		}
		if err := svc.MarkRead(r.Context(), req.ID, userID); err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}
		w.WriteHeader(http.StatusNoContent)
	}
}
