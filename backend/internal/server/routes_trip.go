package server

import (
	"database/sql"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"time"

	"divebubble_be/internal/auth"
	"divebubble_be/internal/transport"
	"divebubble_be/internal/trip"

	"github.com/google/uuid"
)

func registerTripRoutes(mux *http.ServeMux, svc *trip.Service, transportSvc *transport.Service, authIssuer *auth.TokenIssuer) {
	mux.HandleFunc("POST /trips", withAuth(authIssuer, handleCreateTrip(svc)))
	mux.HandleFunc("GET /trips", handleListTrips(svc))
	mux.HandleFunc("GET /trips/mine", withAuth(authIssuer, handleListMyTrips(svc)))
	// Detail stays browsable without an account — "joined" is just false for anonymous viewers.
	mux.HandleFunc("GET /trips/{id}", optionalAuth(authIssuer, handleGetTrip(svc)))
	mux.HandleFunc("POST /trips/{id}/join", withAuth(authIssuer, handleJoinTrip(svc)))
	mux.HandleFunc("POST /trips/{id}/leave", withAuth(authIssuer, handleLeaveTrip(svc, transportSvc)))
	mux.HandleFunc("GET /trips/{id}/participants", withAuth(authIssuer, handleListParticipants(svc)))
	mux.HandleFunc("POST /trips/{id}/read", withAuth(authIssuer, handleMarkRead(svc)))
}

type tripResponse struct {
	ID               uuid.UUID  `json:"id"`
	Title            string     `json:"title"`
	Location         string     `json:"location"`
	StartTime        time.Time  `json:"startTime"`
	CreatedAt        time.Time  `json:"createdAt"`
	Joined           bool       `json:"joined"`
	CreatorUserID    *uuid.UUID `json:"creatorUserId,omitempty"`
	ParticipantCount int        `json:"participantCount"`
	UnreadCount      int        `json:"unreadCount"`

	EndDate          *time.Time `json:"endDate,omitempty"`
	Description      *string    `json:"description,omitempty"`
	MeetingPoint     *string    `json:"meetingPoint,omitempty"`
	DiveCountMin     *int       `json:"diveCountMin,omitempty"`
	DiveCountMax     *int       `json:"diveCountMax,omitempty"`
	DepthMinM        *int       `json:"depthMinM,omitempty"`
	DepthMaxM        *int       `json:"depthMaxM,omitempty"`
	MinCertification *string    `json:"minCertification,omitempty"`
	BookingCode      *string    `json:"bookingCode,omitempty"`
	MaxParticipants  *int       `json:"maxParticipants,omitempty"`
	BookingStatus    string     `json:"bookingStatus"`
	PhotoURL         *string    `json:"photoUrl,omitempty"`
}

func nullStringPtr(v sql.NullString) *string {
	if !v.Valid {
		return nil
	}
	return &v.String
}

func nullInt32Ptr(v sql.NullInt32) *int {
	if !v.Valid {
		return nil
	}
	i := int(v.Int32)
	return &i
}

func nullTimePtr(v sql.NullTime) *time.Time {
	if !v.Valid {
		return nil
	}
	return &v.Time
}

func toTripResponse(t trip.Trip, joined bool, participantCount int) tripResponse {
	resp := tripResponse{
		ID:               t.ID,
		Title:            t.Title,
		Location:         t.Location,
		StartTime:        t.StartTime,
		CreatedAt:        t.CreatedAt,
		Joined:           joined,
		ParticipantCount: participantCount,
		UnreadCount:      t.UnreadCount,
		EndDate:          nullTimePtr(t.EndDate),
		Description:      nullStringPtr(t.Description),
		MeetingPoint:     nullStringPtr(t.MeetingPoint),
		DiveCountMin:     nullInt32Ptr(t.DiveCountMin),
		DiveCountMax:     nullInt32Ptr(t.DiveCountMax),
		DepthMinM:        nullInt32Ptr(t.DepthMinM),
		DepthMaxM:        nullInt32Ptr(t.DepthMaxM),
		MinCertification: nullStringPtr(t.MinCertification),
		BookingCode:      nullStringPtr(t.BookingCode),
		MaxParticipants:  nullInt32Ptr(t.MaxParticipants),
		BookingStatus:    t.BookingStatus,
		PhotoURL:         nullStringPtr(t.PhotoURL),
	}
	if t.CreatorUserID.Valid {
		resp.CreatorUserID = &t.CreatorUserID.UUID
	}
	return resp
}

type createTripRequest struct {
	Title     string    `json:"title"`
	Location  string    `json:"location"`
	StartTime time.Time `json:"startTime"`

	EndDate          *time.Time `json:"endDate"`
	Description      *string    `json:"description"`
	MeetingPoint     *string    `json:"meetingPoint"`
	DiveCountMin     *int       `json:"diveCountMin"`
	DiveCountMax     *int       `json:"diveCountMax"`
	DepthMinM        *int       `json:"depthMinM"`
	DepthMaxM        *int       `json:"depthMaxM"`
	MinCertification *string    `json:"minCertification"`
	BookingCode      *string    `json:"bookingCode"`
	MaxParticipants  *int       `json:"maxParticipants"`
}

func handleCreateTrip(svc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		var req createTripRequest
		dec := json.NewDecoder(io.LimitReader(r.Body, 1<<20))
		if err := dec.Decode(&req); err != nil {
			writeError(w, http.StatusBadRequest, "invalid JSON body")
			return
		}

		t, err := svc.CreateTrip(r.Context(), trip.CreateParams{
			Title:            req.Title,
			Location:         req.Location,
			StartTime:        req.StartTime,
			CreatorUserID:    userID,
			EndDate:          req.EndDate,
			Description:      req.Description,
			MeetingPoint:     req.MeetingPoint,
			DiveCountMin:     req.DiveCountMin,
			DiveCountMax:     req.DiveCountMax,
			DepthMinM:        req.DepthMinM,
			DepthMaxM:        req.DepthMaxM,
			MinCertification: req.MinCertification,
			BookingCode:      req.BookingCode,
			MaxParticipants:  req.MaxParticipants,
		})
		if err != nil {
			if errors.Is(err, trip.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, "title, location and startTime are required")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not create trip")
			return
		}

		writeJSON(w, http.StatusCreated, toTripResponse(t, true, 1))
	}
}

func handleGetTrip(svc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		id := r.PathValue("id")
		t, err := svc.GetTrip(r.Context(), id)
		if err != nil {
			if errors.Is(err, trip.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, "invalid trip id")
				return
			}
			if errors.Is(err, trip.ErrNotFound) {
				writeError(w, http.StatusNotFound, "trip not found")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not get trip")
			return
		}

		joined, err := svc.IsJoined(r.Context(), id, userID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not get trip")
			return
		}

		participantCount, err := svc.CountParticipants(r.Context(), t.ID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not get trip")
			return
		}

		writeJSON(w, http.StatusOK, toTripResponse(t, joined, participantCount))
	}
}

func handleJoinTrip(svc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		id := r.PathValue("id")
		if err := svc.Join(r.Context(), id, userID); err != nil {
			if errors.Is(err, trip.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, "invalid trip id")
				return
			}
			if errors.Is(err, trip.ErrNotFound) {
				writeError(w, http.StatusNotFound, "trip not found")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not join trip")
			return
		}

		writeJSON(w, http.StatusOK, map[string]bool{"joined": true})
	}
}

// handleLeaveTrip orchestrates across both trip and transport: dropping trip.Leave's
// business rule (organizer can't leave) plus transport's cascade (their own joins freed,
// any offer *they* created dissolved with an alert for whoever had joined it — see
// transport.Service.HandleUserLeavingTrip).
func handleLeaveTrip(svc *trip.Service, transportSvc *transport.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		id := r.PathValue("id")
		tripID, err := uuid.Parse(id)
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid trip id")
			return
		}

		// Organizer check (inside svc.Leave) runs first and blocks entirely on failure —
		// the transport cascade below must never fire for a rejected leave attempt.
		if err := svc.Leave(r.Context(), id, userID); err != nil {
			if errors.Is(err, trip.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, "invalid trip id")
				return
			}
			if errors.Is(err, trip.ErrNotFound) {
				writeError(w, http.StatusNotFound, "trip not found")
				return
			}
			if errors.Is(err, trip.ErrOrganizerCannotLeave) {
				writeError(w, http.StatusForbidden, "organizer cannot leave their own trip — cancel it instead")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not leave trip")
			return
		}

		if err := transportSvc.HandleUserLeavingTrip(r.Context(), tripID, userID); err != nil {
			writeError(w, http.StatusInternalServerError, "could not clean up transport offers")
			return
		}

		w.WriteHeader(http.StatusNoContent)
	}
}

// Gated to participants only (requireParticipant, same guard as messages/transport) — who
// joined a trip isn't public information, just like the trip's chat isn't.
func handleListParticipants(svc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		tripIDStr := r.PathValue("id")
		if _, ok := requireParticipant(w, r, svc, tripIDStr, userID); !ok {
			return
		}
		ids, err := svc.ListParticipantUserIDs(r.Context(), tripIDStr)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not list participants")
			return
		}
		writeJSON(w, http.StatusOK, ids)
	}
}

func handleMarkRead(svc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		id := r.PathValue("id")
		if err := svc.MarkRead(r.Context(), id, userID); err != nil {
			if errors.Is(err, trip.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, "invalid trip id")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not mark trip read")
			return
		}
		w.WriteHeader(http.StatusNoContent)
	}
}

func handleListMyTrips(svc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		trips, err := svc.ListJoinedByUser(r.Context(), userID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not list trips")
			return
		}

		out := make([]tripResponse, 0, len(trips))
		for _, t := range trips {
			out = append(out, toTripResponse(t, true, 0))
		}
		writeJSON(w, http.StatusOK, out)
	}
}

func handleListTrips(svc *trip.Service) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		trips, err := svc.ListTrips(r.Context())
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not list trips")
			return
		}

		out := make([]tripResponse, 0, len(trips))
		for _, t := range trips {
			out = append(out, toTripResponse(t, false, 0))
		}
		writeJSON(w, http.StatusOK, out)
	}
}
