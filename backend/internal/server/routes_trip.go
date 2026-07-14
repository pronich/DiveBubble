package server

import (
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"time"

	"divebuddy_be/internal/trip"
	"divebuddy_be/internal/user"

	"github.com/google/uuid"
)

func registerTripRoutes(mux *http.ServeMux, svc *trip.Service, userSvc *user.Service) {
	mux.HandleFunc("POST /trips", withUser(userSvc, handleCreateTrip(svc)))
	mux.HandleFunc("GET /trips", handleListTrips(svc))
	mux.HandleFunc("GET /trips/mine", withUser(userSvc, handleListMyTrips(svc)))
	mux.HandleFunc("GET /trips/{id}", withUser(userSvc, handleGetTrip(svc)))
	mux.HandleFunc("POST /trips/{id}/join", withUser(userSvc, handleJoinTrip(svc)))
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
}

func handleCreateTrip(svc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		var req createTripRequest
		dec := json.NewDecoder(io.LimitReader(r.Body, 1<<20))
		if err := dec.Decode(&req); err != nil {
			writeError(w, http.StatusBadRequest, "invalid JSON body")
			return
		}

		t, err := svc.CreateTrip(r.Context(), req.Title, req.Location, req.StartTime, userID)
		if err != nil {
			if errors.Is(err, trip.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, "title, location and startTime are required")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not create trip")
			return
		}

		writeJSON(w, http.StatusCreated, toTripResponse(t, false, 0))
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
