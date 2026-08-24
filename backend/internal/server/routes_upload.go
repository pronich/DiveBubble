package server

import (
	"errors"
	"mime/multipart"
	"net/http"

	"divebubble_be/internal/auth"
	"divebubble_be/internal/certification"
	"divebubble_be/internal/divecenter"
	"divebubble_be/internal/message"
	"divebubble_be/internal/profile"
	"divebubble_be/internal/trip"
	"divebubble_be/internal/upload"

	"github.com/google/uuid"
)

func registerUploadRoutes(
	mux *http.ServeMux,
	uploadSvc *upload.Service,
	profileSvc *profile.Service,
	tripSvc *trip.Service,
	certificationSvc *certification.Service,
	diveCenterSvc *divecenter.Service,
	authIssuer *auth.TokenIssuer,
) {
	mux.HandleFunc("POST /me/avatar", withAuth(authIssuer, handleUploadAvatar(uploadSvc, profileSvc)))
	mux.HandleFunc("DELETE /me/avatar", withAuth(authIssuer, handleDeleteAvatar(profileSvc)))
	mux.HandleFunc("POST /me/certification-photo", withAuth(authIssuer, handleUploadCertificationPhoto(uploadSvc, profileSvc)))
	mux.HandleFunc("POST /me/specialties/{id}/photo", withAuth(authIssuer, handleUploadSpecialtyPhoto(uploadSvc, certificationSvc)))
	mux.HandleFunc("POST /trips/{id}/photos", withAuth(authIssuer, handleUploadTripPhoto(uploadSvc, tripSvc)))
	mux.HandleFunc("POST /dive-centers/{id}/logo", withAuth(authIssuer, handleUploadDiveCenterLogo(uploadSvc, diveCenterSvc)))
	mux.HandleFunc("POST /trips/{id}/messages/attachment", withAuth(authIssuer, handleUploadMessageAttachment(uploadSvc, tripSvc)))
}

// parseUploadFile expects a single multipart field named "file". The size cap here is
// upload.MaxFileSize plus headroom for the rest of the multipart form (field boundaries,
// other parts) — upload.Service.Save enforces the real per-file limit.
func parseUploadFile(r *http.Request) (multipart.File, *multipart.FileHeader, error) {
	if err := r.ParseMultipartForm(upload.MaxFileSize + 1<<20); err != nil {
		return nil, nil, err
	}
	return r.FormFile("file")
}

func writeUploadError(w http.ResponseWriter, err error) {
	if errors.Is(err, upload.ErrInvalidImage) || errors.Is(err, upload.ErrTooLarge) {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	writeError(w, http.StatusInternalServerError, "could not save file")
}

func handleUploadAvatar(uploadSvc *upload.Service, profileSvc *profile.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		file, header, err := parseUploadFile(r)
		if err != nil {
			writeError(w, http.StatusBadRequest, "could not read uploaded file")
			return
		}
		defer file.Close()

		url, err := uploadSvc.Save("avatars", file, header)
		if err != nil {
			writeUploadError(w, err)
			return
		}

		p, err := profileSvc.Update(r.Context(), userID, profile.UpdateParams{AvatarURL: &url})
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not update profile")
			return
		}
		writeJSON(w, http.StatusOK, toProfileResponse(p))
	}
}

func handleDeleteAvatar(profileSvc *profile.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		p, err := profileSvc.ClearAvatar(r.Context(), userID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not remove avatar")
			return
		}
		writeJSON(w, http.StatusOK, toProfileResponse(p))
	}
}

// handleUploadCertificationPhoto is for the Level card's single photo (users.
// certification_photo_url) — distinct from a specialty's own photo (see
// handleUploadSpecialtyPhoto), since Level is a singleton the diver updates in place.
func handleUploadCertificationPhoto(uploadSvc *upload.Service, profileSvc *profile.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		file, header, err := parseUploadFile(r)
		if err != nil {
			writeError(w, http.StatusBadRequest, "could not read uploaded file")
			return
		}
		defer file.Close()

		url, err := uploadSvc.Save("certifications", file, header)
		if err != nil {
			writeUploadError(w, err)
			return
		}

		p, err := profileSvc.Update(r.Context(), userID, profile.UpdateParams{CertificationPhotoURL: &url})
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not update profile")
			return
		}
		writeJSON(w, http.StatusOK, toProfileResponse(p))
	}
}

func handleUploadSpecialtyPhoto(uploadSvc *upload.Service, certificationSvc *certification.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		id, err := uuid.Parse(r.PathValue("id"))
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid specialty id")
			return
		}

		file, header, err := parseUploadFile(r)
		if err != nil {
			writeError(w, http.StatusBadRequest, "could not read uploaded file")
			return
		}
		defer file.Close()

		url, err := uploadSvc.Save("specialties", file, header)
		if err != nil {
			writeUploadError(w, err)
			return
		}

		found, err := certificationSvc.SetSpecialtyPhoto(r.Context(), userID, id, url)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not update specialty photo")
			return
		}
		if !found {
			writeError(w, http.StatusNotFound, "specialty not found")
			return
		}
		writeJSON(w, http.StatusOK, map[string]string{"photoUrl": url})
	}
}

func handleUploadDiveCenterLogo(uploadSvc *upload.Service, diveCenterSvc *divecenter.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		id, err := uuid.Parse(r.PathValue("id"))
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid dive center id")
			return
		}

		file, header, err := parseUploadFile(r)
		if err != nil {
			writeError(w, http.StatusBadRequest, "could not read uploaded file")
			return
		}
		defer file.Close()

		url, err := uploadSvc.Save("dive-centers", file, header)
		if err != nil {
			writeUploadError(w, err)
			return
		}

		if err := diveCenterSvc.SetLogoURL(r.Context(), id, userID, url); err != nil {
			if errors.Is(err, divecenter.ErrOnlyOwner) {
				writeError(w, http.StatusForbidden, "only an owner can edit this dive center")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not update dive center logo")
			return
		}
		writeJSON(w, http.StatusOK, map[string]string{"logoUrl": url})
	}
}

func handleUploadTripPhoto(uploadSvc *upload.Service, tripSvc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		id := r.PathValue("id")

		file, header, err := parseUploadFile(r)
		if err != nil {
			writeError(w, http.StatusBadRequest, "could not read uploaded file")
			return
		}
		defer file.Close()

		url, err := uploadSvc.Save("trips", file, header)
		if err != nil {
			writeUploadError(w, err)
			return
		}

		photo, err := tripSvc.AddPhoto(r.Context(), id, userID, url)
		if err != nil {
			if errors.Is(err, trip.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, "invalid trip id")
				return
			}
			if errors.Is(err, trip.ErrNotFound) {
				writeError(w, http.StatusNotFound, "trip not found")
				return
			}
			if errors.Is(err, trip.ErrOnlyOrganizerCanEditTrip) {
				writeError(w, http.StatusForbidden, "only the organizer can edit this trip")
				return
			}
			if errors.Is(err, trip.ErrTooManyPhotos) {
				writeError(w, http.StatusConflict, "trip already has the maximum number of photos")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not add trip photo")
			return
		}
		// 200, not 201 — every other upload endpoint in this file (avatar, certification
		// photo, specialty photo, dive-center logo) returns 200, and both clients' shared
		// multipart-upload helpers (uploadImageFile/uploadImageBytes) hardcode checking for
		// it, so a 201 here would look like a failure to them.
		writeJSON(w, http.StatusOK, toTripPhotoResponse(photo))
	}
}

// parseUploadAttachmentFile mirrors parseUploadFile but sized for the larger chat-attachment
// cap — upload.MaxVideoAttachmentSize, the largest of the two attachment caps, since video is
// accepted through this same endpoint and SaveAttachment does the actual per-type enforcement.
func parseUploadAttachmentFile(r *http.Request) (multipart.File, *multipart.FileHeader, error) {
	if err := r.ParseMultipartForm(upload.MaxVideoAttachmentSize + 1<<20); err != nil {
		return nil, nil, err
	}
	return r.FormFile("file")
}

func writeAttachmentUploadError(w http.ResponseWriter, err error) {
	if errors.Is(err, upload.ErrInvalidAttachment) || errors.Is(err, upload.ErrAttachmentTooLarge) {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	writeError(w, http.StatusInternalServerError, "could not save file")
}

type attachmentUploadResponse struct {
	URL       string `json:"url"`
	Type      string `json:"type"`
	Filename  string `json:"filename"`
	SizeBytes int64  `json:"sizeBytes"`
}

// handleUploadMessageAttachment is scope-agnostic (main trip chat, a car offer's chat, or a
// buddy group's chat) — it only needs the caller to be a trip participant, not which chat the
// resulting message will land in. The caller uploads here first, then passes the returned
// url/type/filename/sizeBytes into whichever POST .../messages call sends the actual message
// (see internal/message.Attachment).
func handleUploadMessageAttachment(uploadSvc *upload.Service, tripSvc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		tripID, ok := requireParticipant(w, r, tripSvc, r.PathValue("id"), userID)
		if !ok {
			return
		}
		// Same read-only guard as sending a message — no point uploading a file that can
		// never be attached to a message once the trip's chat is closed.
		if err := tripSvc.EnsureNotCancelled(r.Context(), tripID); err != nil {
			if errors.Is(err, trip.ErrTripCancelled) {
				writeError(w, http.StatusConflict, "trip has been cancelled")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not upload attachment")
			return
		}

		file, header, err := parseUploadAttachmentFile(r)
		if err != nil {
			writeError(w, http.StatusBadRequest, "could not read uploaded file")
			return
		}
		defer file.Close()

		url, contentType, err := uploadSvc.SaveAttachment("chat-attachments", file, header)
		if err != nil {
			writeAttachmentUploadError(w, err)
			return
		}

		attachmentType := message.AttachmentTypeImage
		switch contentType {
		case "application/pdf":
			attachmentType = message.AttachmentTypePDF
		case "video/mp4":
			attachmentType = message.AttachmentTypeVideo
		}

		writeJSON(w, http.StatusOK, attachmentUploadResponse{
			URL:       url,
			Type:      attachmentType,
			Filename:  header.Filename,
			SizeBytes: header.Size,
		})
	}
}
