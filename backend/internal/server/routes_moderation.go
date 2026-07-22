package server

import (
	"encoding/json"
	"errors"
	"io"
	"log"
	"net/http"

	"divebubble_be/internal/auth"
	"divebubble_be/internal/message"
	"divebubble_be/internal/moderation"
	"divebubble_be/internal/trip"

	"github.com/google/uuid"
)

func registerModerationRoutes(mux *http.ServeMux, svc *moderation.Service, messageSvc *message.Service, tripSvc *trip.Service, authIssuer *auth.TokenIssuer) {
	mux.HandleFunc("POST /trips/{id}/messages/{messageId}/report", withAuth(authIssuer, handleReportMessage(svc, messageSvc, tripSvc)))
	mux.HandleFunc("POST /users/{id}/block", withAuth(authIssuer, handleBlockUser(svc)))
	mux.HandleFunc("DELETE /users/{id}/block", withAuth(authIssuer, handleUnblockUser(svc)))
	mux.HandleFunc("GET /users/blocked", withAuth(authIssuer, handleListBlockedUsers(svc)))
}

type reportMessageRequest struct {
	Reason  string `json:"reason"`
	Details string `json:"details"`
}

func handleReportMessage(svc *moderation.Service, messageSvc *message.Service, tripSvc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
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

		msg, err := messageSvc.GetByID(r.Context(), messageID)
		if err != nil {
			if errors.Is(err, message.ErrNotFound) {
				writeError(w, http.StatusNotFound, "message not found")
				return
			}
			log.Printf("report message: could not load message %s: %v", messageID, err)
			writeError(w, http.StatusInternalServerError, "could not report message")
			return
		}
		if msg.TripID != tripID {
			writeError(w, http.StatusNotFound, "message not found")
			return
		}

		var req reportMessageRequest
		dec := json.NewDecoder(io.LimitReader(r.Body, 1<<20))
		if err := dec.Decode(&req); err != nil {
			writeError(w, http.StatusBadRequest, "invalid JSON body")
			return
		}

		report, err := svc.ReportMessage(r.Context(), userID, messageID, tripID, req.Reason, req.Details)
		if err != nil {
			if errors.Is(err, moderation.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, "reason is required")
				return
			}
			log.Printf("report message: could not create report: %v", err)
			writeError(w, http.StatusInternalServerError, "could not report message")
			return
		}

		// No admin review UI yet — this log line is the review mechanism while the user base
		// is small (`docker compose logs api | grep moderation:`), see internal/moderation.
		log.Printf("moderation: message %s reported by %s (trip %s): reason=%q", messageID, userID, tripID, report.Reason)

		writeJSON(w, http.StatusCreated, map[string]string{"id": report.ID.String()})
	}
}

func handleBlockUser(svc *moderation.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		targetID, err := uuid.Parse(r.PathValue("id"))
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid user id")
			return
		}
		if err := svc.BlockUser(r.Context(), userID, targetID); err != nil {
			if errors.Is(err, moderation.ErrCannotBlockSelf) {
				writeError(w, http.StatusBadRequest, "cannot block yourself")
				return
			}
			log.Printf("block user: could not block %s for %s: %v", targetID, userID, err)
			writeError(w, http.StatusInternalServerError, "could not block user")
			return
		}
		w.WriteHeader(http.StatusNoContent)
	}
}

func handleUnblockUser(svc *moderation.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		targetID, err := uuid.Parse(r.PathValue("id"))
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid user id")
			return
		}
		if err := svc.UnblockUser(r.Context(), userID, targetID); err != nil {
			log.Printf("unblock user: could not unblock %s for %s: %v", targetID, userID, err)
			writeError(w, http.StatusInternalServerError, "could not unblock user")
			return
		}
		w.WriteHeader(http.StatusNoContent)
	}
}

func handleListBlockedUsers(svc *moderation.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		ids, err := svc.ListBlockedUserIDs(r.Context(), userID)
		if err != nil {
			log.Printf("list blocked users: could not list for %s: %v", userID, err)
			writeError(w, http.StatusInternalServerError, "could not list blocked users")
			return
		}
		out := make([]string, 0, len(ids))
		for _, id := range ids {
			out = append(out, id.String())
		}
		writeJSON(w, http.StatusOK, out)
	}
}
