package server

import (
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"time"

	"divebuddy_be/internal/transport"
	"divebuddy_be/internal/trip"
	"divebuddy_be/internal/user"

	"github.com/google/uuid"
)

func registerTransportRoutes(mux *http.ServeMux, svc *transport.Service, tripSvc *trip.Service, userSvc *user.Service) {
	mux.HandleFunc("GET /trips/{id}/transport", withUser(userSvc, handleListTransportOffers(svc, tripSvc)))
	mux.HandleFunc("POST /trips/{id}/transport", withUser(userSvc, handleCreateTransportOffer(svc, tripSvc)))
}

type transportOfferResponse struct {
	ID        uuid.UUID `json:"id"`
	TripID    uuid.UUID `json:"tripId"`
	UserID    uuid.UUID `json:"userId"`
	Type      string    `json:"type"`
	Seats     *int      `json:"seats,omitempty"`
	Details   *string   `json:"details,omitempty"`
	CreatedAt time.Time `json:"createdAt"`
}

func toTransportOfferResponse(o transport.Offer) transportOfferResponse {
	return transportOfferResponse{
		ID:        o.ID,
		TripID:    o.TripID,
		UserID:    o.UserID,
		Type:      string(o.Type),
		Seats:     nullInt32Ptr(o.Seats),
		Details:   nullStringPtr(o.Details),
		CreatedAt: o.CreatedAt,
	}
}

func handleListTransportOffers(svc *transport.Service, tripSvc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		tripID, ok := requireParticipant(w, r, tripSvc, r.PathValue("id"), userID)
		if !ok {
			return
		}

		offers, err := svc.List(r.Context(), tripID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not list transport offers")
			return
		}

		out := make([]transportOfferResponse, 0, len(offers))
		for _, o := range offers {
			out = append(out, toTransportOfferResponse(o))
		}
		writeJSON(w, http.StatusOK, out)
	}
}

type createTransportOfferRequest struct {
	Type    string  `json:"type"`
	Seats   *int    `json:"seats"`
	Details *string `json:"details"`
}

func handleCreateTransportOffer(svc *transport.Service, tripSvc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		tripID, ok := requireParticipant(w, r, tripSvc, r.PathValue("id"), userID)
		if !ok {
			return
		}

		var req createTransportOfferRequest
		dec := json.NewDecoder(io.LimitReader(r.Body, 1<<20))
		if err := dec.Decode(&req); err != nil {
			writeError(w, http.StatusBadRequest, "invalid JSON body")
			return
		}

		o, err := svc.Create(r.Context(), tripID, userID, transport.OfferType(req.Type), req.Seats, req.Details)
		if err != nil {
			if errors.Is(err, transport.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, "invalid type or seats")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not create transport offer")
			return
		}

		writeJSON(w, http.StatusCreated, toTransportOfferResponse(o))
	}
}
