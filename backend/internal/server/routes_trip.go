package server

import (
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"time"

	"divebuddy_be/internal/trip"

	"github.com/google/uuid"
)

func registerTripRoutes(mux *http.ServeMux, svc *trip.Service) {
	mux.HandleFunc("POST /trips", handleCreateTrip(svc))
	mux.HandleFunc("GET /trips", handleListTrips(svc))
}

type tripResponse struct {
	ID        uuid.UUID `json:"id"`
	Title     string    `json:"title"`
	Location  string    `json:"location"`
	StartTime time.Time `json:"startTime"`
	CreatedAt time.Time `json:"createdAt"`
}

func toTripResponse(t trip.Trip) tripResponse {
	return tripResponse{
		ID:        t.ID,
		Title:     t.Title,
		Location:  t.Location,
		StartTime: t.StartTime,
		CreatedAt: t.CreatedAt,
	}
}

type createTripRequest struct {
	Title     string    `json:"title"`
	Location  string    `json:"location"`
	StartTime time.Time `json:"startTime"`
}

func handleCreateTrip(svc *trip.Service) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var req createTripRequest
		dec := json.NewDecoder(io.LimitReader(r.Body, 1<<20))
		if err := dec.Decode(&req); err != nil {
			writeError(w, http.StatusBadRequest, "invalid JSON body")
			return
		}

		t, err := svc.CreateTrip(r.Context(), req.Title, req.Location, req.StartTime)
		if err != nil {
			if errors.Is(err, trip.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, "title, location and startTime are required")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not create trip")
			return
		}

		writeJSON(w, http.StatusCreated, toTripResponse(t))
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
			out = append(out, toTripResponse(t))
		}
		writeJSON(w, http.StatusOK, out)
	}
}
