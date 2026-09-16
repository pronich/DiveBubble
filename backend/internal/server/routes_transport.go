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
	"divebubble_be/internal/moderation"
	"divebubble_be/internal/profile"
	"divebubble_be/internal/push"
	"divebubble_be/internal/realtime"
	"divebubble_be/internal/transport"
	"divebubble_be/internal/trip"

	"github.com/google/uuid"
)

func registerTransportRoutes(
	mux *http.ServeMux,
	svc *transport.Service,
	tripSvc *trip.Service,
	diveCenterSvc *divecenter.Service,
	profileSvc *profile.Service,
	authIssuer *auth.TokenIssuer,
	pushSvc *push.Service,
	messageSvc *message.Service,
	moderationSvc *moderation.Service,
	publisher *realtime.Publisher,
) {
	mux.HandleFunc("GET /trips/{id}/transport", withAuth(authIssuer, handleListTransportOffers(svc, tripSvc, diveCenterSvc)))
	mux.HandleFunc("POST /trips/{id}/transport", withAuth(authIssuer, handleCreateTransportOffer(svc, tripSvc, diveCenterSvc)))
	mux.HandleFunc("POST /trips/{id}/transport/{offerId}/join", withAuth(authIssuer, handleJoinTransportOffer(svc, tripSvc, profileSvc, pushSvc, messageSvc, publisher)))
	mux.HandleFunc("GET /trips/{id}/transport/{offerId}/joins", withAuth(authIssuer, handleListTransportOfferJoins(svc, tripSvc)))
	mux.HandleFunc("GET /trips/{id}/transport/alert", withAuth(authIssuer, handleGetTransportAlert(svc, tripSvc)))
	mux.HandleFunc("GET /trips/{id}/transport/{offerId}/messages", withAuth(authIssuer, handleListOfferMessages(svc, tripSvc, diveCenterSvc, moderationSvc, messageSvc)))
	mux.HandleFunc("POST /trips/{id}/transport/{offerId}/messages", withAuth(authIssuer, handleSendOfferMessage(svc, tripSvc, diveCenterSvc, profileSvc, pushSvc, messageSvc, publisher)))
	mux.HandleFunc("POST /trips/{id}/transport/{offerId}/leave", withAuth(authIssuer, handleLeaveTransportOffer(svc, tripSvc)))
	mux.HandleFunc("POST /trips/{id}/transport/{offerId}/dissolve", withAuth(authIssuer, handleDissolveTransportOffer(svc, tripSvc, publisher)))
	mux.HandleFunc("POST /trips/{id}/transport/{offerId}/read", withAuth(authIssuer, handleMarkTransportOfferRead(svc, tripSvc)))
}

// requireOfferAccess is requireParticipant plus an offer-level check: only the creator or someone who's joined may read/post/manage it.
func requireOfferAccess(w http.ResponseWriter, r *http.Request, transportSvc *transport.Service, tripSvc *trip.Service, tripIDStr, offerIDStr string, userID uuid.UUID) (transport.Offer, bool) {
	tripID, ok := requireParticipant(w, r, tripSvc, tripIDStr, userID)
	if !ok {
		return transport.Offer{}, false
	}

	offerID, err := uuid.Parse(offerIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, ErrCodeGeneric)
		return transport.Offer{}, false
	}

	offer, err := transportSvc.Repo.GetByID(r.Context(), offerID)
	if err != nil {
		if errors.Is(err, transport.ErrNotFound) {
			writeError(w, http.StatusNotFound, ErrCodeTransportOfferNotFound)
			return transport.Offer{}, false
		}
		writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
		return transport.Offer{}, false
	}
	if offer.TripID != tripID {
		writeError(w, http.StatusNotFound, ErrCodeTransportOfferNotFound)
		return transport.Offer{}, false
	}
	if offer.UserID == userID {
		return offer, true
	}

	isJoined, err := transportSvc.Repo.IsJoined(r.Context(), offerID, userID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
		return transport.Offer{}, false
	}
	if !isJoined {
		writeError(w, http.StatusForbidden, ErrCodeNotPartOfCar)
		return transport.Offer{}, false
	}
	return offer, true
}

type transportOfferResponse struct {
	ID                uuid.UUID `json:"id"`
	TripID            uuid.UUID `json:"tripId"`
	UserID            uuid.UUID `json:"userId"`
	Type              string    `json:"type"`
	Seats             *int      `json:"seats,omitempty"`
	Details           *string   `json:"details,omitempty"`
	CreatedAt         time.Time `json:"createdAt"`
	JoinedCount       int       `json:"joinedCount"`
	Joined            bool      `json:"joined"`
	IsDiveCenterStaff bool      `json:"isDiveCenterStaff"`
	HasUnreadMessages bool      `json:"hasUnreadMessages"`
}

func toTransportOfferResponse(o transport.Offer, isDiveCenterStaff bool) transportOfferResponse {
	return transportOfferResponse{
		ID:                o.ID,
		TripID:            o.TripID,
		UserID:            o.UserID,
		Type:              string(o.Type),
		Seats:             nullInt32Ptr(o.Seats),
		Details:           nullStringPtr(o.Details),
		CreatedAt:         o.CreatedAt,
		JoinedCount:       o.JoinedCount,
		Joined:            o.Joined,
		IsDiveCenterStaff: isDiveCenterStaff,
		HasUnreadMessages: o.HasUnreadMessages,
	}
}

func handleListTransportOffers(svc *transport.Service, tripSvc *trip.Service, diveCenterSvc *divecenter.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
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

		offers, err := svc.List(r.Context(), tripID, userID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		checker := newDiveCenterStaffChecker(diveCenterSvc, t.DiveCenterID)
		out := make([]transportOfferResponse, 0, len(offers))
		for _, o := range offers {
			out = append(out, toTransportOfferResponse(o, checker.isStaff(r.Context(), o.UserID)))
		}
		writeJSON(w, http.StatusOK, out)
	}
}

type createTransportOfferRequest struct {
	Type    string  `json:"type"`
	Seats   *int    `json:"seats"`
	Details *string `json:"details"`
}

func handleCreateTransportOffer(svc *transport.Service, tripSvc *trip.Service, diveCenterSvc *divecenter.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		tripID, ok := requireParticipant(w, r, tripSvc, r.PathValue("id"), userID)
		if !ok {
			return
		}
		// A cancelled trip is dead — no reason to keep arranging rides to it.
		if err := tripSvc.EnsureNotCancelled(r.Context(), tripID); err != nil {
			if errors.Is(err, trip.ErrTripCancelled) {
				writeError(w, http.StatusConflict, ErrCodeTripCancelled)
				return
			}
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		t, err := tripSvc.GetTrip(r.Context(), tripID.String())
		if err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		var req createTransportOfferRequest
		dec := json.NewDecoder(io.LimitReader(r.Body, 1<<20))
		if err := dec.Decode(&req); err != nil {
			writeError(w, http.StatusBadRequest, ErrCodeGeneric)
			return
		}

		o, err := svc.Create(r.Context(), tripID, userID, transport.OfferType(req.Type), req.Seats, req.Details)
		if err != nil {
			if errors.Is(err, transport.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, ErrCodeInvalidOfferTypeOrSeats)
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
		writeJSON(w, http.StatusCreated, toTransportOfferResponse(o, isDiveCenterStaff))
	}
}

func handleJoinTransportOffer(svc *transport.Service, tripSvc *trip.Service, profileSvc *profile.Service, pushSvc *push.Service, messageSvc *message.Service, publisher *realtime.Publisher) func(http.ResponseWriter, *http.Request, uuid.UUID) {
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

		offerID, err := uuid.Parse(r.PathValue("offerId"))
		if err != nil {
			writeError(w, http.StatusBadRequest, ErrCodeGeneric)
			return
		}

		offer, err := svc.Join(r.Context(), offerID, userID)
		if err != nil {
			if errors.Is(err, transport.ErrNotFound) {
				writeError(w, http.StatusNotFound, ErrCodeTransportOfferNotFound)
				return
			}
			if errors.Is(err, transport.ErrFull) {
				writeError(w, http.StatusConflict, ErrCodeNoSeatsLeft)
				return
			}
			if errors.Is(err, transport.ErrAlreadyBooked) {
				writeError(w, http.StatusConflict, ErrCodeAlreadyJoinedOffer)
				return
			}
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		if offer.UserID != userID {
			if t, err := tripSvc.GetTrip(r.Context(), tripID.String()); err == nil {
				joinerName := "Someone"
				if joiner, err := profileSvc.Get(r.Context(), userID); err == nil && joiner.DisplayName.Valid && joiner.DisplayName.String != "" {
					joinerName = joiner.DisplayName.String
				}
				pushSvc.SendToUsers(r.Context(), []uuid.UUID{offer.UserID}, push.Notification{
					Title:    t.Title,
					Subtitle: "Transport chat",
					Body:     joinerName + " joined your ride.",
					Data:     map[string]string{"tripId": t.ID.String(), "type": "transport_joined", "chatScope": "transport"},
				})

				// Not idempotent like SendSystem, since every new joiner needs their own announcement.
				msg, sysErr := messageSvc.PostSystemEvent(r.Context(), tripID, message.Scope{OfferID: uuid.NullUUID{UUID: offerID, Valid: true}}, message.KindCarJoined, joinerName+" joined your car")
				if sysErr != nil {
					log.Printf("car chat: could not post join system message for offer:%s: %v", offerID, sysErr)
				} else if pubErr := publisher.Publish(r.Context(), "transport_offer:"+offerID.String(), toMessageResponse(msg, false, false, nil)); pubErr != nil {
					log.Printf("realtime publish failed for transport_offer:%s: %v", offerID, pubErr)
				}
			}

			// Marked read explicitly because the system join message is attributed to message.SystemUserID, so the unread check can't tell it was the joiner's own action.
			if err := svc.MarkRead(r.Context(), offerID, userID); err != nil {
				log.Printf("car chat: could not mark offer read for joiner:%s offer:%s: %v", userID, offerID, err)
			}
		}

		writeJSON(w, http.StatusOK, map[string]bool{"joined": true})
	}
}

type joinedUserResponse struct {
	UserID uuid.UUID `json:"userId"`
}

// handleGetTransportAlert both reads and clears the alert, since viewing the Transport tab is what acknowledges it.
func handleGetTransportAlert(svc *transport.Service, tripSvc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
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

func handleListTransportOfferJoins(svc *transport.Service, tripSvc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		_, ok := requireParticipant(w, r, tripSvc, r.PathValue("id"), userID)
		if !ok {
			return
		}

		offerID, err := uuid.Parse(r.PathValue("offerId"))
		if err != nil {
			writeError(w, http.StatusBadRequest, ErrCodeGeneric)
			return
		}

		userIDs, err := svc.ListJoins(r.Context(), offerID)
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

func handleListOfferMessages(transportSvc *transport.Service, tripSvc *trip.Service, diveCenterSvc *divecenter.Service, moderationSvc *moderation.Service, messageSvc *message.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		offer, ok := requireOfferAccess(w, r, transportSvc, tripSvc, r.PathValue("id"), r.PathValue("offerId"), userID)
		if !ok {
			return
		}

		t, err := tripSvc.GetTrip(r.Context(), offer.TripID.String())
		if err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		messages, err := messageSvc.ListByOffer(r.Context(), offer.ID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		// Best-effort, same as the main chat: a lookup failure falls back to "nothing blocked".
		blocked, err := moderationSvc.ListBlockedUserIDs(r.Context(), userID)
		if err != nil {
			log.Printf("list offer messages: could not load blocked users for %s: %v", userID, err)
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
			log.Printf("list offer messages: could not load reactions for offer:%s: %v", offer.ID, err)
			reactionsByMessage = nil
		}

		checker := newDiveCenterStaffChecker(diveCenterSvc, t.DiveCenterID)
		out := make([]messageResponse, 0, len(messages))
		for _, m := range messages {
			// feedbackProvided is always false: an offer chat never carries a feedback_prompt message.
			out = append(out, toMessageResponse(m, checker.isStaff(r.Context(), m.UserID), false, reactionsByMessage[m.ID]))
		}
		writeJSON(w, http.StatusOK, out)
	}
}

type sendOfferMessageRequest struct {
	Body string `json:"body"`
	attachmentRequest
}

func handleSendOfferMessage(transportSvc *transport.Service, tripSvc *trip.Service, diveCenterSvc *divecenter.Service, profileSvc *profile.Service, pushSvc *push.Service, messageSvc *message.Service, publisher *realtime.Publisher) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		offer, ok := requireOfferAccess(w, r, transportSvc, tripSvc, r.PathValue("id"), r.PathValue("offerId"), userID)
		if !ok {
			return
		}
		if err := tripSvc.EnsureNotCancelled(r.Context(), offer.TripID); err != nil {
			if errors.Is(err, trip.ErrTripCancelled) {
				writeError(w, http.StatusConflict, ErrCodeTripCancelled)
				return
			}
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		var req sendOfferMessageRequest
		dec := json.NewDecoder(io.LimitReader(r.Body, 1<<20))
		if err := dec.Decode(&req); err != nil {
			writeError(w, http.StatusBadRequest, ErrCodeGeneric)
			return
		}

		m, err := messageSvc.Send(r.Context(), offer.TripID, userID, message.Scope{OfferID: uuid.NullUUID{UUID: offer.ID, Valid: true}}, req.Body, false, req.toAttachments(), uuid.NullUUID{})
		if err != nil {
			if errors.Is(err, message.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, ErrCodeBodyOrAttachmentRequired)
				return
			}
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		isDiveCenterStaff := false
		t, tErr := tripSvc.GetTrip(r.Context(), offer.TripID.String())
		if tErr == nil && t.DiveCenterID.Valid {
			isDiveCenterStaff, _ = diveCenterSvc.IsMember(r.Context(), t.DiveCenterID.UUID, userID)
		}

		resp := toMessageResponse(m, isDiveCenterStaff, false, nil)
		// Best-effort — REST already persisted the message, realtime push is not required for correctness.
		if pubErr := publisher.Publish(r.Context(), "transport_offer:"+offer.ID.String(), resp); pubErr != nil {
			log.Printf("realtime publish failed for transport_offer:%s: %v", offer.ID, pubErr)
		}
		// Also pinged on the trip channel, since the Bubbles-list badge and Transport pill dot only subscribe to trip:$id, not this specific offer's channel.
		if pubErr := publisher.Publish(r.Context(), "trip:"+offer.TripID.String(), map[string]string{
			"event": "sub_chat_activity", "scope": "transport", "userId": userID.String(),
		}); pubErr != nil {
			log.Printf("realtime publish failed for trip:%s: %v", offer.TripID, pubErr)
		}
		if tErr == nil {
			notifyNewOfferMessage(r.Context(), pushSvc, profileSvc, transportSvc, t, offer, m, userID)
		}
		writeJSON(w, http.StatusCreated, resp)
	}
}

// handleLeaveTransportOffer is for a joiner only; the creator's equivalent is handleDissolveTransportOffer.
func handleLeaveTransportOffer(svc *transport.Service, tripSvc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		offer, ok := requireOfferAccess(w, r, svc, tripSvc, r.PathValue("id"), r.PathValue("offerId"), userID)
		if !ok {
			return
		}
		if offer.UserID == userID {
			writeError(w, http.StatusBadRequest, ErrCodeCreatorCannotLeaveCar)
			return
		}
		if err := svc.Leave(r.Context(), offer.ID, userID); err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}
		w.WriteHeader(http.StatusNoContent)
	}
}

// handleDissolveTransportOffer publishes the "dissolved" event only after the delete succeeds, so a rejected/failed attempt never falsely signals dissolution.
func handleDissolveTransportOffer(svc *transport.Service, tripSvc *trip.Service, publisher *realtime.Publisher) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		offer, ok := requireOfferAccess(w, r, svc, tripSvc, r.PathValue("id"), r.PathValue("offerId"), userID)
		if !ok {
			return
		}
		if err := svc.Dissolve(r.Context(), offer.ID, userID); err != nil {
			if errors.Is(err, transport.ErrForbidden) {
				writeError(w, http.StatusForbidden, ErrCodeOnlyCreatorCanDissolveCar)
				return
			}
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}
		if pubErr := publisher.Publish(r.Context(), "transport_offer:"+offer.ID.String(), map[string]string{"event": "dissolved"}); pubErr != nil {
			log.Printf("realtime publish failed for transport_offer:%s: %v", offer.ID, pubErr)
		}
		w.WriteHeader(http.StatusNoContent)
	}
}

// notifyNewOfferMessage notifies only the offer's own members, narrower than notifyNewMessage's whole-trip reach, since the rest of the trip can't see a car they haven't joined.
func notifyNewOfferMessage(ctx context.Context, pushSvc *push.Service, profileSvc *profile.Service, transportSvc *transport.Service, t trip.Trip, offer transport.Offer, m message.Message, senderID uuid.UUID) {
	joinedIDs, err := transportSvc.ListJoins(ctx, offer.ID)
	if err != nil {
		log.Printf("push: could not list joins for offer:%s: %v", offer.ID, err)
		return
	}
	recipients := excludeUser(dedupeUsers(append(joinedIDs, offer.UserID)), senderID)
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
		Subtitle: "Transport chat",
		Body:     senderName + ": " + pushBodyFor(m),
		Data:     map[string]string{"tripId": t.ID.String(), "type": "message", "chatScope": "transport"},
	})
}

// handleMarkTransportOfferRead marks only this one car's chat read, unlike trip.MarkRead which clears the whole Transport tab's alert dot.
func handleMarkTransportOfferRead(svc *transport.Service, tripSvc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		offer, ok := requireOfferAccess(w, r, svc, tripSvc, r.PathValue("id"), r.PathValue("offerId"), userID)
		if !ok {
			return
		}
		if err := svc.MarkRead(r.Context(), offer.ID, userID); err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}
		w.WriteHeader(http.StatusNoContent)
	}
}
