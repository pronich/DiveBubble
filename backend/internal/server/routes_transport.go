package server

import (
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"time"

	"divebubble_be/internal/auth"
	"divebubble_be/internal/divecenter"
	"divebubble_be/internal/profile"
	"divebubble_be/internal/push"
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
) {
	mux.HandleFunc("GET /trips/{id}/transport", withAuth(authIssuer, handleListTransportOffers(svc, tripSvc, diveCenterSvc)))
	mux.HandleFunc("POST /trips/{id}/transport", withAuth(authIssuer, handleCreateTransportOffer(svc, tripSvc, diveCenterSvc)))
	mux.HandleFunc("POST /trips/{id}/transport/{offerId}/join", withAuth(authIssuer, handleJoinTransportOffer(svc, tripSvc, profileSvc, pushSvc)))
	mux.HandleFunc("GET /trips/{id}/transport/{offerId}/joins", withAuth(authIssuer, handleListTransportOfferJoins(svc, tripSvc)))
	mux.HandleFunc("GET /trips/{id}/transport/alert", withAuth(authIssuer, handleGetTransportAlert(svc, tripSvc)))
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
			writeError(w, http.StatusInternalServerError, "could not list transport offers")
			return
		}

		offers, err := svc.List(r.Context(), tripID, userID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not list transport offers")
			return
		}

		// diveCenterStaffChecker is defined in routes_message.go — same "who wrote this"
		// attribution concern as chat, reused as-is rather than duplicated.
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
				writeError(w, http.StatusConflict, "trip has been cancelled")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not create transport offer")
			return
		}

		t, err := tripSvc.GetTrip(r.Context(), tripID.String())
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not create transport offer")
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

func handleJoinTransportOffer(svc *transport.Service, tripSvc *trip.Service, profileSvc *profile.Service, pushSvc *push.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		tripID, ok := requireParticipant(w, r, tripSvc, r.PathValue("id"), userID)
		if !ok {
			return
		}
		// Joining an existing offer is blocked too, not just creating new ones — the trip
		// is dead, so committing to a ride toward it doesn't make sense either.
		if err := tripSvc.EnsureNotCancelled(r.Context(), tripID); err != nil {
			if errors.Is(err, trip.ErrTripCancelled) {
				writeError(w, http.StatusConflict, "trip has been cancelled")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not join transport offer")
			return
		}

		offerID, err := uuid.Parse(r.PathValue("offerId"))
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid offer id")
			return
		}

		offer, err := svc.Join(r.Context(), offerID, userID)
		if err != nil {
			if errors.Is(err, transport.ErrNotFound) {
				writeError(w, http.StatusNotFound, "transport offer not found")
				return
			}
			if errors.Is(err, transport.ErrFull) {
				writeError(w, http.StatusConflict, "no seats left")
				return
			}
			if errors.Is(err, transport.ErrAlreadyBooked) {
				writeError(w, http.StatusConflict, "already joined a transport offer on this trip")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not join transport offer")
			return
		}

		if offer.UserID != userID {
			if t, err := tripSvc.GetTrip(r.Context(), tripID.String()); err == nil {
				joinerName := "Someone"
				if joiner, err := profileSvc.Get(r.Context(), userID); err == nil && joiner.DisplayName.Valid && joiner.DisplayName.String != "" {
					joinerName = joiner.DisplayName.String
				}
				pushSvc.SendToUsers(r.Context(), []uuid.UUID{offer.UserID}, push.Notification{
					Title: t.Title,
					Body:  joinerName + " joined your ride.",
					Data:  map[string]string{"tripId": t.ID.String(), "type": "transport_joined"},
				})
			}
		}

		writeJSON(w, http.StatusOK, map[string]bool{"joined": true})
	}
}

type joinedUserResponse struct {
	UserID uuid.UUID `json:"userId"`
}

// handleGetTransportAlert both reads and clears — viewing the Transport tab is what
// acknowledges the "something changed" ping (transport_alerts), same as opening a chat
// marks it read. No separate ack endpoint needed for this stopgap.
func handleGetTransportAlert(svc *transport.Service, tripSvc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		tripID, ok := requireParticipant(w, r, tripSvc, r.PathValue("id"), userID)
		if !ok {
			return
		}

		hasAlert, err := svc.HasAlert(r.Context(), tripID, userID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not check transport alert")
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
			writeError(w, http.StatusBadRequest, "invalid offer id")
			return
		}

		userIDs, err := svc.ListJoins(r.Context(), offerID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not list transport offer joins")
			return
		}

		out := make([]joinedUserResponse, 0, len(userIDs))
		for _, id := range userIDs {
			out = append(out, joinedUserResponse{UserID: id})
		}
		writeJSON(w, http.StatusOK, out)
	}
}
