package server

import (
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"time"

	"divebubble_be/internal/auth"
	"divebubble_be/internal/gear"

	"github.com/google/uuid"
)

func registerGearRoutes(mux *http.ServeMux, svc *gear.Service, authIssuer *auth.TokenIssuer) {
	mux.HandleFunc("GET /me/gear", withAuth(authIssuer, handleListGear(svc)))
	mux.HandleFunc("PUT /me/gear/{itemKey}", withAuth(authIssuer, handleSetGearStatus(svc)))
	mux.HandleFunc("DELETE /me/gear/{itemKey}", withAuth(authIssuer, handleRemoveGear(svc)))
}

type gearOwnershipResponse struct {
	ItemKey   string    `json:"itemKey"`
	Status    string    `json:"status"`
	UpdatedAt time.Time `json:"updatedAt"`
}

func toGearOwnershipResponse(o gear.Ownership) gearOwnershipResponse {
	return gearOwnershipResponse{ItemKey: o.ItemKey, Status: o.Status, UpdatedAt: o.UpdatedAt}
}

// handleListGear only returns rows the user has actually set — items with no row are
// treated as "missing" by the client against its fixed gear catalog dictionary.
func handleListGear(svc *gear.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		items, err := svc.List(r.Context(), userID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not list gear")
			return
		}
		out := make([]gearOwnershipResponse, 0, len(items))
		for _, o := range items {
			out = append(out, toGearOwnershipResponse(o))
		}
		writeJSON(w, http.StatusOK, out)
	}
}

type setGearStatusRequest struct {
	Status string `json:"status"`
}

func handleSetGearStatus(svc *gear.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		itemKey := r.PathValue("itemKey")

		var req setGearStatusRequest
		dec := json.NewDecoder(io.LimitReader(r.Body, 1<<20))
		if err := dec.Decode(&req); err != nil {
			writeError(w, http.StatusBadRequest, "invalid JSON body")
			return
		}

		o, err := svc.SetStatus(r.Context(), userID, itemKey, req.Status)
		if err != nil {
			if errors.Is(err, gear.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, "itemKey and status are required")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not update gear status")
			return
		}
		writeJSON(w, http.StatusOK, toGearOwnershipResponse(o))
	}
}

func handleRemoveGear(svc *gear.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		found, err := svc.Remove(r.Context(), userID, r.PathValue("itemKey"))
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not remove gear item")
			return
		}
		if !found {
			writeError(w, http.StatusNotFound, "gear item not found")
			return
		}
		w.WriteHeader(http.StatusNoContent)
	}
}
