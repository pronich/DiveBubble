package server

import (
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"time"

	"divebuddy_be/internal/message"
	"divebuddy_be/internal/trip"
	"divebuddy_be/internal/user"

	"github.com/google/uuid"
)

func registerMessageRoutes(mux *http.ServeMux, svc *message.Service, tripSvc *trip.Service, userSvc *user.Service) {
	mux.HandleFunc("GET /trips/{id}/messages", withUser(userSvc, handleListMessages(svc, tripSvc)))
	mux.HandleFunc("POST /trips/{id}/messages", withUser(userSvc, handleSendMessage(svc, tripSvc)))
}

type messageResponse struct {
	ID        uuid.UUID `json:"id"`
	TripID    uuid.UUID `json:"tripId"`
	UserID    uuid.UUID `json:"userId"`
	Body      string    `json:"body"`
	CreatedAt time.Time `json:"createdAt"`
}

func toMessageResponse(m message.Message) messageResponse {
	return messageResponse{
		ID:        m.ID,
		TripID:    m.TripID,
		UserID:    m.UserID,
		Body:      m.Body,
		CreatedAt: m.CreatedAt,
	}
}

// requireParticipant is shared by both message handlers — only trip participants can read/send.
func requireParticipant(w http.ResponseWriter, r *http.Request, tripSvc *trip.Service, tripID string, userID uuid.UUID) (uuid.UUID, bool) {
	parsed, err := uuid.Parse(tripID)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid trip id")
		return uuid.Nil, false
	}
	joined, err := tripSvc.IsJoined(r.Context(), tripID, userID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "could not verify trip membership")
		return uuid.Nil, false
	}
	if !joined {
		writeError(w, http.StatusForbidden, "not a participant of this trip")
		return uuid.Nil, false
	}
	return parsed, true
}

func handleListMessages(svc *message.Service, tripSvc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		tripID, ok := requireParticipant(w, r, tripSvc, r.PathValue("id"), userID)
		if !ok {
			return
		}

		messages, err := svc.List(r.Context(), tripID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not list messages")
			return
		}

		out := make([]messageResponse, 0, len(messages))
		for _, m := range messages {
			out = append(out, toMessageResponse(m))
		}
		writeJSON(w, http.StatusOK, out)
	}
}

type sendMessageRequest struct {
	Body string `json:"body"`
}

func handleSendMessage(svc *message.Service, tripSvc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		tripID, ok := requireParticipant(w, r, tripSvc, r.PathValue("id"), userID)
		if !ok {
			return
		}

		var req sendMessageRequest
		dec := json.NewDecoder(io.LimitReader(r.Body, 1<<20))
		if err := dec.Decode(&req); err != nil {
			writeError(w, http.StatusBadRequest, "invalid JSON body")
			return
		}

		m, err := svc.Send(r.Context(), tripID, userID, req.Body)
		if err != nil {
			if errors.Is(err, message.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, "body is required")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not send message")
			return
		}

		writeJSON(w, http.StatusCreated, toMessageResponse(m))
	}
}
