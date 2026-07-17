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
	"divebubble_be/internal/divecenter"
	"divebubble_be/internal/message"
	"divebubble_be/internal/realtime"
	"divebubble_be/internal/trip"

	"github.com/google/uuid"
)

func registerMessageRoutes(
	mux *http.ServeMux,
	svc *message.Service,
	tripSvc *trip.Service,
	diveCenterSvc *divecenter.Service,
	authIssuer *auth.TokenIssuer,
	publisher *realtime.Publisher,
) {
	mux.HandleFunc("GET /trips/{id}/messages", withAuth(authIssuer, handleListMessages(svc, tripSvc, diveCenterSvc)))
	mux.HandleFunc("POST /trips/{id}/messages", withAuth(authIssuer, handleSendMessage(svc, tripSvc, diveCenterSvc, publisher)))
}

type messageResponse struct {
	ID                 uuid.UUID `json:"id"`
	TripID             uuid.UUID `json:"tripId"`
	UserID             uuid.UUID `json:"userId"`
	Body               string    `json:"body"`
	CreatedAt          time.Time `json:"createdAt"`
	IsDiveCenterStaff  bool      `json:"isDiveCenterStaff"`
	MentionsDiveCenter bool      `json:"mentionsDiveCenter"`
}

func toMessageResponse(m message.Message, isDiveCenterStaff bool) messageResponse {
	return messageResponse{
		ID:                 m.ID,
		TripID:             m.TripID,
		UserID:             m.UserID,
		Body:               m.Body,
		CreatedAt:          m.CreatedAt,
		IsDiveCenterStaff:  isDiveCenterStaff,
		MentionsDiveCenter: m.MentionsDiveCenter,
	}
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

func handleListMessages(svc *message.Service, tripSvc *trip.Service, diveCenterSvc *divecenter.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
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

		checker := newDiveCenterStaffChecker(diveCenterSvc, t.DiveCenterID)
		out := make([]messageResponse, 0, len(messages))
		for _, m := range messages {
			out = append(out, toMessageResponse(m, checker.isStaff(r.Context(), m.UserID)))
		}
		writeJSON(w, http.StatusOK, out)
	}
}

type sendMessageRequest struct {
	Body               string `json:"body"`
	MentionsDiveCenter bool   `json:"mentionsDiveCenter"`
}

func handleSendMessage(svc *message.Service, tripSvc *trip.Service, diveCenterSvc *divecenter.Service, publisher *realtime.Publisher) func(http.ResponseWriter, *http.Request, uuid.UUID) {
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
		m, err := svc.Send(r.Context(), tripID, userID, req.Body, mentionsDiveCenter)
		if err != nil {
			if errors.Is(err, message.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, "body is required")
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
		resp := toMessageResponse(m, isDiveCenterStaff)
		// Best-effort — sending implies you've read up to now, so this keeps your own
		// message from ever showing up in your own unread count.
		_ = tripSvc.MarkRead(r.Context(), tripID.String(), userID)
		// Best-effort — REST already persisted the message, realtime push is not required for correctness.
		if pubErr := publisher.Publish(r.Context(), "trip:"+tripID.String(), resp); pubErr != nil {
			log.Printf("realtime publish failed for trip:%s: %v", tripID, pubErr)
		}

		writeJSON(w, http.StatusCreated, resp)
	}
}
