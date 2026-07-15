package server

import (
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"time"

	"divebubble_be/internal/auth"
	"divebubble_be/internal/certification"

	"github.com/google/uuid"
)

func registerCertificationRoutes(mux *http.ServeMux, svc *certification.Service, authIssuer *auth.TokenIssuer) {
	mux.HandleFunc("GET /me/specialties", withAuth(authIssuer, handleListSpecialties(svc)))
	mux.HandleFunc("POST /me/specialties", withAuth(authIssuer, handleAddSpecialty(svc)))
	mux.HandleFunc("DELETE /me/specialties/{id}", withAuth(authIssuer, handleRemoveSpecialty(svc)))
}

type specialtyResponse struct {
	ID          uuid.UUID `json:"id"`
	Specialty   string    `json:"specialty"`
	CustomLabel *string   `json:"customLabel,omitempty"`
	Agency      *string   `json:"agency,omitempty"`
	CertNumber  *string   `json:"certNumber,omitempty"`
	PhotoURL    *string   `json:"photoUrl,omitempty"`
	Verified    bool      `json:"verified"`
	CreatedAt   time.Time `json:"createdAt"`
}

func toSpecialtyResponse(s certification.Specialty) specialtyResponse {
	return specialtyResponse{
		ID:          s.ID,
		Specialty:   s.Specialty,
		CustomLabel: nullStringPtr(s.CustomLabel),
		Agency:      nullStringPtr(s.Agency),
		CertNumber:  nullStringPtr(s.CertNumber),
		PhotoURL:    nullStringPtr(s.PhotoURL),
		Verified:    s.Verified,
		CreatedAt:   s.CreatedAt,
	}
}

func handleListSpecialties(svc *certification.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		specialties, err := svc.ListSpecialties(r.Context(), userID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not list specialties")
			return
		}
		out := make([]specialtyResponse, 0, len(specialties))
		for _, s := range specialties {
			out = append(out, toSpecialtyResponse(s))
		}
		writeJSON(w, http.StatusOK, out)
	}
}

type addSpecialtyRequest struct {
	Specialty   string  `json:"specialty"`
	CustomLabel *string `json:"customLabel"`
	Agency      *string `json:"agency"`
	CertNumber  *string `json:"certNumber"`
}

func handleAddSpecialty(svc *certification.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		var req addSpecialtyRequest
		dec := json.NewDecoder(io.LimitReader(r.Body, 1<<20))
		if err := dec.Decode(&req); err != nil {
			writeError(w, http.StatusBadRequest, "invalid JSON body")
			return
		}

		s, err := svc.AddSpecialty(r.Context(), userID, certification.CreateParams{
			Specialty:   req.Specialty,
			CustomLabel: req.CustomLabel,
			Agency:      req.Agency,
			CertNumber:  req.CertNumber,
		})
		if err != nil {
			if errors.Is(err, certification.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, "specialty is required")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not add specialty")
			return
		}
		writeJSON(w, http.StatusCreated, toSpecialtyResponse(s))
	}
}

func handleRemoveSpecialty(svc *certification.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		id, err := uuid.Parse(r.PathValue("id"))
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid specialty id")
			return
		}
		found, err := svc.RemoveSpecialty(r.Context(), userID, id)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not remove specialty")
			return
		}
		if !found {
			writeError(w, http.StatusNotFound, "specialty not found")
			return
		}
		w.WriteHeader(http.StatusNoContent)
	}
}
