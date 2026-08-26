package server

import (
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"time"

	"divebubble_be/internal/auth"
	"divebubble_be/internal/divelog"

	"github.com/google/uuid"
)

// maxImportFileSize caps the raw upload (UDDF/CSV text, or a Diving Log 6 SQLite export) — a
// dive log export, even with hundreds of dives and full depth/temperature profiles, is a few
// MB at most; this just guards against an absurd or malformed upload rather than reflecting
// any real file size for these formats.
const maxImportFileSize = 10 << 20

func registerDiveLogRoutes(mux *http.ServeMux, svc *divelog.Service, authIssuer *auth.TokenIssuer) {
	mux.HandleFunc("GET /divelog", withAuth(authIssuer, handleListDiveLog(svc)))
	mux.HandleFunc("POST /divelog", withAuth(authIssuer, handleCreateDiveLogEntry(svc)))
	mux.HandleFunc("POST /divelog/import", withAuth(authIssuer, handleImportDiveLog(svc)))
	mux.HandleFunc("PUT /divelog/{id}", withAuth(authIssuer, handleUpdateDiveLogEntry(svc)))
	mux.HandleFunc("DELETE /divelog/{id}", withAuth(authIssuer, handleDeleteDiveLogEntry(svc)))
}

type profileSampleResponse struct {
	OffsetSeconds int      `json:"offsetSeconds"`
	DepthM        float64  `json:"depthM"`
	TemperatureC  *float64 `json:"temperatureC,omitempty"`
}

type diveLogEntryResponse struct {
	ID              uuid.UUID               `json:"id"`
	TripID          *uuid.UUID              `json:"tripId,omitempty"`
	Source          string                  `json:"source"`
	DivedAt         time.Time               `json:"divedAt"`
	MaxDepthM       *float64                `json:"maxDepthM,omitempty"`
	AvgDepthM       *float64                `json:"avgDepthM,omitempty"`
	DurationMinutes *int                    `json:"durationMinutes,omitempty"`
	MinTemperatureC *float64                `json:"minTemperatureC,omitempty"`
	Country         *string                 `json:"country,omitempty"`
	SiteName        *string                 `json:"siteName,omitempty"`
	Latitude        *float64                `json:"latitude,omitempty"`
	Longitude       *float64                `json:"longitude,omitempty"`
	Notes           *string                 `json:"notes,omitempty"`
	ProfileSamples  []profileSampleResponse `json:"profileSamples,omitempty"`
	CreatedAt       time.Time               `json:"createdAt"`
}

func toDiveLogEntryResponse(e divelog.Entry) diveLogEntryResponse {
	var tripID *uuid.UUID
	if e.TripID.Valid {
		tripID = &e.TripID.UUID
	}
	samples := make([]profileSampleResponse, len(e.ProfileSamples))
	for i, s := range e.ProfileSamples {
		samples[i] = profileSampleResponse{OffsetSeconds: s.OffsetSeconds, DepthM: s.DepthM, TemperatureC: s.TemperatureC}
	}
	return diveLogEntryResponse{
		ID: e.ID, TripID: tripID, Source: string(e.Source), DivedAt: e.DivedAt,
		MaxDepthM: e.MaxDepthM, AvgDepthM: e.AvgDepthM, DurationMinutes: e.DurationMinutes, MinTemperatureC: e.MinTemperatureC,
		Country: e.Country, SiteName: e.SiteName, Latitude: e.Latitude, Longitude: e.Longitude, Notes: e.Notes,
		ProfileSamples: samples, CreatedAt: e.CreatedAt,
	}
}

func handleListDiveLog(svc *divelog.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		entries, err := svc.ListByUser(r.Context(), userID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not list dive log")
			return
		}
		out := make([]diveLogEntryResponse, len(entries))
		for i, e := range entries {
			out[i] = toDiveLogEntryResponse(e)
		}
		writeJSON(w, http.StatusOK, out)
	}
}

type createDiveLogEntryRequest struct {
	DivedAt         time.Time `json:"divedAt"`
	MaxDepthM       *float64  `json:"maxDepthM"`
	DurationMinutes *int      `json:"durationMinutes"`
	MinTemperatureC *float64  `json:"minTemperatureC"`
	Country         *string   `json:"country"`
	SiteName        *string   `json:"siteName"`
	Notes           *string   `json:"notes"`
}

func handleCreateDiveLogEntry(svc *divelog.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		var req createDiveLogEntryRequest
		dec := json.NewDecoder(io.LimitReader(r.Body, 1<<20))
		if err := dec.Decode(&req); err != nil {
			writeError(w, http.StatusBadRequest, "invalid JSON body")
			return
		}

		e, err := svc.CreateManual(r.Context(), userID, divelog.CreateManualInput{
			DivedAt: req.DivedAt, MaxDepthM: req.MaxDepthM, DurationMinutes: req.DurationMinutes,
			MinTemperatureC: req.MinTemperatureC, Country: req.Country, SiteName: req.SiteName, Notes: req.Notes,
		})
		if err != nil {
			if errors.Is(err, divelog.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, "a dive date/time is required")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not save dive log entry")
			return
		}
		writeJSON(w, http.StatusCreated, toDiveLogEntryResponse(e))
	}
}

func handleUpdateDiveLogEntry(svc *divelog.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		id, err := uuid.Parse(r.PathValue("id"))
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid id")
			return
		}

		var req createDiveLogEntryRequest
		dec := json.NewDecoder(io.LimitReader(r.Body, 1<<20))
		if err := dec.Decode(&req); err != nil {
			writeError(w, http.StatusBadRequest, "invalid JSON body")
			return
		}

		e, err := svc.Update(r.Context(), id, userID, divelog.UpdateInput{
			DivedAt: req.DivedAt, MaxDepthM: req.MaxDepthM, DurationMinutes: req.DurationMinutes,
			MinTemperatureC: req.MinTemperatureC, Country: req.Country, SiteName: req.SiteName, Notes: req.Notes,
		})
		if err != nil {
			if errors.Is(err, divelog.ErrNotFound) {
				writeError(w, http.StatusNotFound, "dive log entry not found")
				return
			}
			if errors.Is(err, divelog.ErrForbidden) {
				writeError(w, http.StatusForbidden, "not your dive log entry")
				return
			}
			if errors.Is(err, divelog.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, "a dive date/time is required")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not update dive log entry")
			return
		}
		writeJSON(w, http.StatusOK, toDiveLogEntryResponse(e))
	}
}

type importDiveLogResponse struct {
	Imported int `json:"imported"`
	Skipped  int `json:"skipped"`
}

func handleImportDiveLog(svc *divelog.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		if err := r.ParseMultipartForm(maxImportFileSize + 1<<20); err != nil {
			writeError(w, http.StatusBadRequest, "invalid upload")
			return
		}
		file, _, err := r.FormFile("file")
		if err != nil {
			writeError(w, http.StatusBadRequest, "missing file")
			return
		}
		defer file.Close()

		data, err := io.ReadAll(io.LimitReader(file, maxImportFileSize))
		if err != nil {
			writeError(w, http.StatusBadRequest, "could not read file")
			return
		}

		result, err := svc.Import(r.Context(), userID, data)
		if err != nil {
			switch {
			case errors.Is(err, divelog.ErrInvalidUDDF):
				writeError(w, http.StatusBadRequest, "this doesn't look like a valid UDDF dive log file")
			case errors.Is(err, divelog.ErrInvalidCSV):
				writeError(w, http.StatusBadRequest, "could not parse this CSV file — check the column headers")
			case errors.Is(err, divelog.ErrInvalidSQLite):
				writeError(w, http.StatusBadRequest, "could not read this file as a Diving Log 6 export")
			case errors.Is(err, divelog.ErrUnrecognizedFormat):
				writeError(w, http.StatusBadRequest, "unrecognized file format — expected UDDF, CSV, or a Diving Log 6 export")
			default:
				writeError(w, http.StatusInternalServerError, "could not import dive log")
			}
			return
		}
		writeJSON(w, http.StatusOK, importDiveLogResponse{Imported: result.Imported, Skipped: result.Skipped})
	}
}

func handleDeleteDiveLogEntry(svc *divelog.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		id, err := uuid.Parse(r.PathValue("id"))
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid id")
			return
		}
		if err := svc.Delete(r.Context(), id, userID); err != nil {
			if errors.Is(err, divelog.ErrNotFound) {
				writeError(w, http.StatusNotFound, "dive log entry not found")
				return
			}
			if errors.Is(err, divelog.ErrForbidden) {
				writeError(w, http.StatusForbidden, "not your dive log entry")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not delete dive log entry")
			return
		}
		w.WriteHeader(http.StatusNoContent)
	}
}
