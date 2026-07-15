package server

import (
	"encoding/json"
	"io"
	"net/http"
	"strings"
	"time"

	"divebubble_be/internal/auth"
	"divebubble_be/internal/profile"

	"github.com/google/uuid"
)

func registerProfileRoutes(mux *http.ServeMux, svc *profile.Service, authIssuer *auth.TokenIssuer) {
	mux.HandleFunc("GET /me", withAuth(authIssuer, handleGetProfile(svc)))
	mux.HandleFunc("PATCH /me", withAuth(authIssuer, handleUpdateProfile(svc)))
	mux.HandleFunc("GET /users/{id}", withAuth(authIssuer, handleGetPublicProfile(svc)))
}

type profileResponse struct {
	ID                    uuid.UUID `json:"id"`
	DisplayName           *string   `json:"displayName,omitempty"`
	AvatarURL             *string   `json:"avatarUrl,omitempty"`
	Location              *string   `json:"location,omitempty"`
	Bio                   *string   `json:"bio,omitempty"`
	DiveCount             int       `json:"diveCount"`
	CertificationLevel    *string   `json:"certificationLevel,omitempty"`
	CertificationAgency   *string   `json:"certificationAgency,omitempty"`
	CertificationNumber   *string   `json:"certificationNumber,omitempty"`
	CertificationPhotoURL *string   `json:"certificationPhotoUrl,omitempty"`
	CertificationVerified bool      `json:"certificationVerified"`
	Languages             string    `json:"languages"`
	MemberSince           time.Time `json:"memberSince"`
}

func toProfileResponse(p profile.Profile) profileResponse {
	return profileResponse{
		ID:                    p.UserID,
		DisplayName:           nullStringPtr(p.DisplayName),
		AvatarURL:             nullStringPtr(p.AvatarURL),
		Location:              nullStringPtr(p.Location),
		Bio:                   nullStringPtr(p.Bio),
		DiveCount:             p.DiveCount,
		CertificationLevel:    nullStringPtr(p.CertificationLevel),
		CertificationAgency:   nullStringPtr(p.CertificationAgency),
		CertificationNumber:   nullStringPtr(p.CertificationNumber),
		CertificationPhotoURL: nullStringPtr(p.CertificationPhotoURL),
		CertificationVerified: p.CertificationVerified,
		Languages:             p.Languages,
		MemberSince:           p.MemberSince,
	}
}

func handleGetProfile(svc *profile.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		p, err := svc.Get(r.Context(), userID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not load profile")
			return
		}
		writeJSON(w, http.StatusOK, toProfileResponse(p))
	}
}

// publicProfileResponse is a trimmed projection of profileResponse — no certification
// agency/number/photo/verified (private, only the diver themselves sees those) and no
// specialties/gear at all. Signed in required (see registerProfileRoutes) — viewing another
// diver's profile is an in-app interaction (organizer/participant taps), not open browsing.
type publicProfileResponse struct {
	ID                 uuid.UUID `json:"id"`
	DisplayName        *string   `json:"displayName,omitempty"`
	AvatarURL          *string   `json:"avatarUrl,omitempty"`
	Location           *string   `json:"location,omitempty"`
	Bio                *string   `json:"bio,omitempty"`
	DiveCount          int       `json:"diveCount"`
	CertificationLevel *string   `json:"certificationLevel,omitempty"`
	Languages          string    `json:"languages"`
	MemberSince        time.Time `json:"memberSince"`
}

func toPublicProfileResponse(p profile.Profile) publicProfileResponse {
	return publicProfileResponse{
		ID:                 p.UserID,
		DisplayName:        nullStringPtr(p.DisplayName),
		AvatarURL:          nullStringPtr(p.AvatarURL),
		Location:           nullStringPtr(p.Location),
		Bio:                nullStringPtr(p.Bio),
		DiveCount:          p.DiveCount,
		CertificationLevel: nullStringPtr(p.CertificationLevel),
		Languages:          p.Languages,
		MemberSince:        p.MemberSince,
	}
}

func handleGetPublicProfile(svc *profile.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, _ uuid.UUID) {
		targetID, err := uuid.Parse(r.PathValue("id"))
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid user id")
			return
		}
		p, err := svc.Get(r.Context(), targetID)
		if err != nil {
			writeError(w, http.StatusNotFound, "user not found")
			return
		}
		writeJSON(w, http.StatusOK, toPublicProfileResponse(p))
	}
}

type updateProfileRequest struct {
	DisplayName           *string `json:"displayName"`
	AvatarURL             *string `json:"avatarUrl"`
	Location              *string `json:"location"`
	Bio                   *string `json:"bio"`
	DiveCount             *int    `json:"diveCount"`
	CertificationLevel    *string `json:"certificationLevel"`
	CertificationAgency   *string `json:"certificationAgency"`
	CertificationNumber   *string `json:"certificationNumber"`
	CertificationPhotoURL *string `json:"certificationPhotoUrl"`
	CertificationVerified *bool   `json:"certificationVerified"`
	Languages             *string `json:"languages"`
}

func handleUpdateProfile(svc *profile.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		body, err := io.ReadAll(io.LimitReader(r.Body, 1<<20))
		if err != nil {
			writeError(w, http.StatusBadRequest, "could not read body")
			return
		}
		var req updateProfileRequest
		if err := json.Unmarshal(body, &req); err != nil {
			writeError(w, http.StatusBadRequest, "invalid JSON body")
			return
		}

		if req.DisplayName != nil {
			trimmed := strings.TrimSpace(*req.DisplayName)
			req.DisplayName = &trimmed
		}
		if req.Location != nil {
			trimmed := strings.TrimSpace(*req.Location)
			req.Location = &trimmed
		}
		if req.Bio != nil {
			trimmed := strings.TrimSpace(*req.Bio)
			req.Bio = &trimmed
		}

		p, err := svc.Update(r.Context(), userID, profile.UpdateParams{
			DisplayName:           req.DisplayName,
			AvatarURL:             req.AvatarURL,
			Location:              req.Location,
			Bio:                   req.Bio,
			DiveCount:             req.DiveCount,
			CertificationLevel:    req.CertificationLevel,
			CertificationAgency:   req.CertificationAgency,
			CertificationNumber:   req.CertificationNumber,
			CertificationPhotoURL: req.CertificationPhotoURL,
			CertificationVerified: req.CertificationVerified,
			Languages:             req.Languages,
		})
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not update profile")
			return
		}
		writeJSON(w, http.StatusOK, toProfileResponse(p))
	}
}
