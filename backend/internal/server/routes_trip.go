package server

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"io"
	"log"
	"net/http"
	"strings"
	"time"

	"divebubble_be/internal/account"
	"divebubble_be/internal/auth"
	"divebubble_be/internal/buddy"
	"divebubble_be/internal/divecenter"
	"divebubble_be/internal/message"
	"divebubble_be/internal/profile"
	"divebubble_be/internal/push"
	"divebubble_be/internal/realtime"
	"divebubble_be/internal/transport"
	"divebubble_be/internal/trip"

	"github.com/google/uuid"
)

func registerTripRoutes(
	mux *http.ServeMux,
	svc *trip.Service,
	transportSvc *transport.Service,
	buddySvc *buddy.Service,
	diveCenterSvc *divecenter.Service,
	profileSvc *profile.Service,
	authIssuer *auth.TokenIssuer,
	pushSvc *push.Service,
	accountSvc *account.Service,
	messageSvc *message.Service,
	publisher *realtime.Publisher,
) {
	mux.HandleFunc("POST /trips", withAuth(authIssuer, handleCreateTrip(svc)))
	mux.HandleFunc("GET /trips", optionalAuth(authIssuer, handleListTrips(svc, accountSvc)))
	mux.HandleFunc("GET /trips/mine", withAuth(authIssuer, handleListMyTrips(svc)))
	// Detail stays browsable without an account — "joined" is just false for anonymous viewers.
	mux.HandleFunc("GET /trips/{id}", optionalAuth(authIssuer, handleGetTrip(svc)))
	// Deliberately outside the /trips/ namespace: Go's ServeMux treats a same-length /trips/{literal}/{wildcard} pattern as ambiguous with existing /trips/{id}/... routes and panics at startup.
	mux.HandleFunc("GET /invite/{code}", optionalAuth(authIssuer, handleResolveTripByCode(svc)))
	mux.HandleFunc("POST /trips/{id}/join", withAuth(authIssuer, handleJoinTrip(svc, diveCenterSvc, profileSvc, pushSvc, messageSvc, publisher)))
	mux.HandleFunc("POST /trips/join-by-code", withAuth(authIssuer, handleJoinTripByCode(svc, diveCenterSvc, profileSvc, pushSvc, messageSvc, publisher)))
	mux.HandleFunc("POST /trips/{id}/leave", withAuth(authIssuer, handleLeaveTrip(svc, transportSvc, buddySvc, pushSvc)))
	mux.HandleFunc("POST /trips/{id}/cancel", withAuth(authIssuer, handleCancelTrip(svc, diveCenterSvc, pushSvc)))
	mux.HandleFunc("PATCH /trips/{id}", withAuth(authIssuer, handleUpdateTrip(svc, diveCenterSvc, pushSvc)))
	mux.HandleFunc("GET /trips/{id}/participants", withAuth(authIssuer, handleListParticipants(svc)))
	mux.HandleFunc("POST /trips/{id}/read", withAuth(authIssuer, handleMarkRead(svc)))
	mux.HandleFunc("GET /trips/{id}/mute", withAuth(authIssuer, handleGetTripMute(svc)))
	mux.HandleFunc("POST /trips/{id}/mute", withAuth(authIssuer, handleMuteTrip(svc)))
	mux.HandleFunc("DELETE /trips/{id}/mute", withAuth(authIssuer, handleUnmuteTrip(svc)))
	mux.HandleFunc("GET /trips/{id}/archive", withAuth(authIssuer, handleGetTripArchive(svc)))
	mux.HandleFunc("POST /trips/{id}/archive", withAuth(authIssuer, handleArchiveTrip(svc)))
	mux.HandleFunc("DELETE /trips/{id}/archive", withAuth(authIssuer, handleUnarchiveTrip(svc)))
	mux.HandleFunc("POST /trips/{id}/feedback", withAuth(authIssuer, handleSubmitFeedback(svc)))
	// Adding a photo (POST) is a multipart upload, so it's registered in routes_upload.go instead.
	mux.HandleFunc("GET /trips/{id}/photos", optionalAuth(authIssuer, handleListTripPhotos(svc)))
	mux.HandleFunc("DELETE /trips/{id}/photos/{photoId}", withAuth(authIssuer, handleDeleteTripPhoto(svc)))
}

type tripPhotoResponse struct {
	ID       uuid.UUID `json:"id"`
	URL      string    `json:"url"`
	Position int       `json:"position"`
}

func toTripPhotoResponse(p trip.Photo) tripPhotoResponse {
	return tripPhotoResponse{ID: p.ID, URL: p.URL, Position: p.Position}
}

type tripResponse struct {
	ID                         uuid.UUID  `json:"id"`
	Title                      string     `json:"title"`
	Location                   string     `json:"location"`
	StartTime                  time.Time  `json:"startTime"`
	CreatedAt                  time.Time  `json:"createdAt"`
	Joined                     bool       `json:"joined"`
	CreatorUserID              *uuid.UUID `json:"creatorUserId,omitempty"`
	ParticipantCount           int        `json:"participantCount"`
	UnreadCount                int        `json:"unreadCount"`
	HasTransportAlert          bool       `json:"hasTransportAlert"`
	HasUnreadMention           bool       `json:"hasUnreadMention"`
	HasBuddyAlert              bool       `json:"hasBuddyAlert"`
	HasUnreadTransportMessages bool       `json:"hasUnreadTransportMessages"`
	HasUnreadBuddyMessages     bool       `json:"hasUnreadBuddyMessages"`

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
	IsPrivate        bool       `json:"isPrivate"`
	PhotoURL         *string    `json:"photoUrl,omitempty"`

	DiveCenterID *uuid.UUID `json:"diveCenterId,omitempty"`
	PriceMinor   *int       `json:"priceMinor,omitempty"`
	Currency     string     `json:"currency"`
	BookingURL   *string    `json:"bookingUrl,omitempty"`

	Latitude  *float64 `json:"latitude,omitempty"`
	Longitude *float64 `json:"longitude,omitempty"`
}

func nullFloat64Ptr(v sql.NullFloat64) *float64 {
	if !v.Valid {
		return nil
	}
	f := v.Float64
	return &f
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
		ID:                         t.ID,
		Title:                      t.Title,
		Location:                   t.Location,
		StartTime:                  t.StartTime,
		CreatedAt:                  t.CreatedAt,
		Joined:                     joined,
		ParticipantCount:           participantCount,
		UnreadCount:                t.UnreadCount,
		HasTransportAlert:          t.HasTransportAlert,
		HasUnreadMention:           t.HasUnreadMention,
		HasBuddyAlert:              t.HasBuddyAlert,
		HasUnreadTransportMessages: t.HasUnreadTransportMessages,
		HasUnreadBuddyMessages:     t.HasUnreadBuddyMessages,
		EndDate:                    nullTimePtr(t.EndDate),
		Description:                nullStringPtr(t.Description),
		MeetingPoint:               nullStringPtr(t.MeetingPoint),
		DiveCountMin:               nullInt32Ptr(t.DiveCountMin),
		DiveCountMax:               nullInt32Ptr(t.DiveCountMax),
		DepthMinM:                  nullInt32Ptr(t.DepthMinM),
		DepthMaxM:                  nullInt32Ptr(t.DepthMaxM),
		MinCertification:           nullStringPtr(t.MinCertification),
		BookingCode:                nullStringPtr(t.BookingCode),
		MaxParticipants:            nullInt32Ptr(t.MaxParticipants),
		BookingStatus:              t.BookingStatus,
		IsPrivate:                  t.IsPrivate,
		PhotoURL:                   nullStringPtr(t.PhotoURL),
		PriceMinor:                 nullInt32Ptr(t.PriceMinor),
		Currency:                   t.Currency,
		BookingURL:                 nullStringPtr(t.BookingURL),
		Latitude:                   nullFloat64Ptr(t.Latitude),
		Longitude:                  nullFloat64Ptr(t.Longitude),
	}
	if t.CreatorUserID.Valid {
		resp.CreatorUserID = &t.CreatorUserID.UUID
	}
	if t.DiveCenterID.Valid {
		resp.DiveCenterID = &t.DiveCenterID.UUID
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

	// DiveCenterID set means a business trip: the creator isn't auto-joined, and BookingCode above is always overwritten with a fresh server-generated code regardless of what's sent.
	DiveCenterID *uuid.UUID `json:"diveCenterId"`
	PriceMinor   *int       `json:"priceMinor"`
	BookingURL   *string    `json:"bookingUrl"`

	// Best-effort client-side forward-geocode of Location/MeetingPoint — see model.go.
	Latitude  *float64 `json:"latitude"`
	Longitude *float64 `json:"longitude"`

	// Individual trips only: fixed at creation with no edit path, and forced false for business trips.
	IsPrivate bool `json:"isPrivate"`
}

func handleCreateTrip(svc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		var req createTripRequest
		dec := json.NewDecoder(io.LimitReader(r.Body, 1<<20))
		if err := dec.Decode(&req); err != nil {
			writeError(w, http.StatusBadRequest, ErrCodeGeneric)
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
			DiveCenterID:     req.DiveCenterID,
			PriceMinor:       req.PriceMinor,
			BookingURL:       req.BookingURL,
			Latitude:         req.Latitude,
			Longitude:        req.Longitude,
			IsPrivate:        req.IsPrivate,
		})
		if err != nil {
			if errors.Is(err, trip.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, ErrCodeTripFieldsRequired)
				return
			}
			if errors.Is(err, trip.ErrEndDateBeforeStart) {
				writeError(w, http.StatusBadRequest, ErrCodeEndDateBeforeStart)
				return
			}
			if errors.Is(err, trip.ErrNotDiveCenterMember) {
				writeError(w, http.StatusForbidden, ErrCodeNotDiveCenterMember)
				return
			}
			if errors.Is(err, trip.ErrBusinessTripRequiresPriceAndURL) {
				writeError(w, http.StatusBadRequest, ErrCodeBusinessTripRequiresPricing)
				return
			}
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		// A business trip has no trip_participants row for its creator, so `joined` here would be misleading either way.
		writeJSON(w, http.StatusCreated, toTripResponse(t, req.DiveCenterID == nil, 1))
	}
}

func handleGetTrip(svc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		id := r.PathValue("id")
		t, err := svc.GetTrip(r.Context(), id)
		if err != nil {
			if errors.Is(err, trip.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, ErrCodeGeneric)
				return
			}
			if errors.Is(err, trip.ErrNotFound) {
				writeError(w, http.StatusNotFound, ErrCodeTripNotFound)
				return
			}
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		joined, err := svc.IsJoined(r.Context(), id, userID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		participantCount, err := svc.CountParticipants(r.Context(), t.ID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		writeJSON(w, http.StatusOK, toTripResponse(t, joined, participantCount))
	}
}

// handleResolveTripByCode is the read-only half of an invite link; it never joins, see handleJoinTripByCode for that.
func handleResolveTripByCode(svc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		code := r.PathValue("code")
		t, err := svc.ResolveByCode(r.Context(), code)
		if err != nil {
			if errors.Is(err, trip.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, ErrCodeGeneric)
				return
			}
			if errors.Is(err, trip.ErrInvalidBookingCode) {
				writeError(w, http.StatusNotFound, ErrCodeInvalidBookingCode)
				return
			}
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		joined, err := svc.IsJoined(r.Context(), t.ID.String(), userID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		participantCount, err := svc.CountParticipants(r.Context(), t.ID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		writeJSON(w, http.StatusOK, toTripResponse(t, joined, participantCount))
	}
}

func handleJoinTrip(svc *trip.Service, diveCenterSvc *divecenter.Service, profileSvc *profile.Service, pushSvc *push.Service, messageSvc *message.Service, publisher *realtime.Publisher) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		id := r.PathValue("id")
		if err := svc.Join(r.Context(), id, userID); err != nil {
			if errors.Is(err, trip.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, ErrCodeGeneric)
				return
			}
			if errors.Is(err, trip.ErrNotFound) {
				writeError(w, http.StatusNotFound, ErrCodeTripNotFound)
				return
			}
			if errors.Is(err, trip.ErrTripNotOpen) {
				writeError(w, http.StatusConflict, ErrCodeTripNotOpenToJoin)
				return
			}
			if errors.Is(err, trip.ErrRequiresBookingCode) {
				writeError(w, http.StatusConflict, ErrCodeTripRequiresBookingCode)
				return
			}
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		if t, err := svc.GetTrip(r.Context(), id); err == nil {
			notifyOrganizerOfNewParticipant(r.Context(), pushSvc, profileSvc, t, userID)
			notifyIfObserverJoined(r.Context(), messageSvc, publisher, profileSvc, t.ID, userID)
		}

		writeJSON(w, http.StatusOK, map[string]bool{"joined": true})
	}
}

// notifyIfObserverJoined posts a one-time system message for is_product_observer accounts; SendSystem is idempotent per trip+kind, so a leave-then-rejoin never re-announces.
func notifyIfObserverJoined(ctx context.Context, messageSvc *message.Service, publisher *realtime.Publisher, profileSvc *profile.Service, tripID, joinedUserID uuid.UUID) {
	p, err := profileSvc.Get(ctx, joinedUserID)
	if err != nil || !p.IsProductObserver {
		return
	}
	msg, sent, err := messageSvc.SendSystem(ctx, tripID, message.KindObserverJoined,
		"Hi all — Nikolai here, founder of DiveBubble. Just here to see how the app works on a real trip, not diving today. Enjoy the trip!")
	if err != nil {
		log.Printf("observer join message: could not send for trip:%s: %v", tripID, err)
		return
	}
	if !sent {
		return
	}
	// Field names kept in sync with messageResponse in routes_message.go.
	payload := map[string]any{
		"id":                 msg.ID,
		"tripId":             msg.TripID,
		"userId":             msg.UserID,
		"body":               msg.Body,
		"createdAt":          msg.CreatedAt,
		"isDiveCenterStaff":  false,
		"mentionsDiveCenter": false,
		"kind":               msg.Kind,
		"feedbackProvided":   false,
	}
	if pubErr := publisher.Publish(ctx, "trip:"+tripID.String(), payload); pubErr != nil {
		log.Printf("observer join message: realtime publish failed for trip:%s: %v", tripID, pubErr)
	}
}

// notifyOrganizerOfNewParticipant covers the individual-trip case only; a business trip's roster notification lives in notifyStaffOfBookingCodeJoin instead.
func notifyOrganizerOfNewParticipant(ctx context.Context, pushSvc *push.Service, profileSvc *profile.Service, t trip.Trip, joinedUserID uuid.UUID) {
	if !t.CreatorUserID.Valid || t.CreatorUserID.UUID == joinedUserID {
		return
	}
	joinerName := "Someone"
	if joiner, err := profileSvc.Get(ctx, joinedUserID); err == nil && joiner.DisplayName.Valid && joiner.DisplayName.String != "" {
		joinerName = joiner.DisplayName.String
	}
	pushSvc.SendToUsers(ctx, []uuid.UUID{t.CreatorUserID.UUID}, push.Notification{
		Title: t.Title,
		Body:  joinerName + " joined your trip.",
		Data:  map[string]string{"tripId": t.ID.String(), "type": "participant_joined"},
	})
}

type joinByCodeRequest struct {
	Code string `json:"code"`
}

// handleJoinTripByCode takes no trip id in the URL, since the code alone is what the diver has after paying on the dive center's own site.
func handleJoinTripByCode(svc *trip.Service, diveCenterSvc *divecenter.Service, profileSvc *profile.Service, pushSvc *push.Service, messageSvc *message.Service, publisher *realtime.Publisher) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		var req joinByCodeRequest
		dec := json.NewDecoder(io.LimitReader(r.Body, 1<<20))
		if err := dec.Decode(&req); err != nil {
			writeError(w, http.StatusBadRequest, ErrCodeGeneric)
			return
		}

		t, err := svc.JoinByCode(r.Context(), req.Code, userID)
		if err != nil {
			if errors.Is(err, trip.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, ErrCodeBookingCodeRequired)
				return
			}
			if errors.Is(err, trip.ErrInvalidBookingCode) {
				writeError(w, http.StatusNotFound, ErrCodeInvalidBookingCode)
				return
			}
			if errors.Is(err, trip.ErrTripNotOpen) {
				writeError(w, http.StatusConflict, ErrCodeTripNotOpenToJoin)
				return
			}
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		notifyStaffOfBookingCodeJoin(r.Context(), pushSvc, profileSvc, diveCenterSvc, t, userID)
		notifyIfObserverJoined(r.Context(), messageSvc, publisher, profileSvc, t.ID, userID)

		participantCount, err := svc.CountParticipants(r.Context(), t.ID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}
		writeJSON(w, http.StatusOK, toTripResponse(t, true, participantCount))
	}
}

// notifyStaffOfBookingCodeJoin notifies every staff member of the dive center, not just whoever created the trip, since the organization is the organizer.
func notifyStaffOfBookingCodeJoin(ctx context.Context, pushSvc *push.Service, profileSvc *profile.Service, diveCenterSvc *divecenter.Service, t trip.Trip, joinedUserID uuid.UUID) {
	if !t.DiveCenterID.Valid {
		return
	}
	staffIDs, err := diveCenterSvc.ListMemberUserIDs(ctx, t.DiveCenterID.UUID)
	if err != nil {
		log.Printf("push: could not list dive center staff for trip:%s: %v", t.ID, err)
		return
	}
	// Excludes the joiner in case they're staff testing their own center's booking code.
	staffIDs = excludeUser(dedupeUsers(staffIDs), joinedUserID)
	if len(staffIDs) == 0 {
		return
	}
	joinerName := "A diver"
	if joiner, err := profileSvc.Get(ctx, joinedUserID); err == nil && joiner.DisplayName.Valid && joiner.DisplayName.String != "" {
		joinerName = joiner.DisplayName.String
	}
	pushSvc.SendToUsers(ctx, staffIDs, push.Notification{
		Title: t.Title,
		Body:  joinerName + " joined via booking code.",
		Data:  map[string]string{"tripId": t.ID.String(), "type": "participant_joined"},
	})
}

// handleCancelTrip is final: booking_status flips to "cancelled", which everything downstream (Explore's list, join, message/transport activity) keys off, while read access stays untouched.
func handleCancelTrip(svc *trip.Service, diveCenterSvc *divecenter.Service, pushSvc *push.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		id := r.PathValue("id")
		if err := svc.Cancel(r.Context(), id, userID); err != nil {
			if errors.Is(err, trip.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, ErrCodeGeneric)
				return
			}
			if errors.Is(err, trip.ErrNotFound) {
				writeError(w, http.StatusNotFound, ErrCodeTripNotFound)
				return
			}
			if errors.Is(err, trip.ErrOnlyOrganizerCanCancel) {
				writeError(w, http.StatusForbidden, ErrCodeOnlyOrganizerCanCancelTrip)
				return
			}
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		// Best-effort: the cancellation already succeeded above, so a failed re-fetch just skips this notification.
		if t, err := svc.GetTrip(r.Context(), id); err == nil {
			recipients := excludeUser(TripRecipientIDs(r.Context(), svc, diveCenterSvc, t), userID)
			if len(recipients) > 0 {
				pushSvc.SendToUsers(r.Context(), recipients, push.Notification{
					Title: t.Title,
					Body:  "This trip has been cancelled.",
					Data:  map[string]string{"tripId": t.ID.String(), "type": "trip_cancelled"},
				})
			}
		}

		w.WriteHeader(http.StatusNoContent)
	}
}

type updateTripRequest struct {
	Title            *string    `json:"title"`
	Location         *string    `json:"location"`
	StartTime        *time.Time `json:"startTime"`
	EndDate          *time.Time `json:"endDate"`
	Description      *string    `json:"description"`
	MeetingPoint     *string    `json:"meetingPoint"`
	DiveCountMin     *int       `json:"diveCountMin"`
	DiveCountMax     *int       `json:"diveCountMax"`
	DepthMinM        *int       `json:"depthMinM"`
	DepthMaxM        *int       `json:"depthMaxM"`
	MinCertification *string    `json:"minCertification"`
	MaxParticipants  *int       `json:"maxParticipants"`
	PriceMinor       *int       `json:"priceMinor"`
	BookingURL       *string    `json:"bookingUrl"`
	Latitude         *float64   `json:"latitude"`
	Longitude        *float64   `json:"longitude"`
}

// handleUpdateTrip treats every field as optional; a nil pointer leaves that column untouched, so callers only send what actually changed.
func handleUpdateTrip(svc *trip.Service, diveCenterSvc *divecenter.Service, pushSvc *push.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		id := r.PathValue("id")
		var req updateTripRequest
		dec := json.NewDecoder(io.LimitReader(r.Body, 1<<20))
		if err := dec.Decode(&req); err != nil {
			writeError(w, http.StatusBadRequest, ErrCodeGeneric)
			return
		}

		// Snapshotted before the update since admin/'s edit form resends every field on every save, so diffing before vs after is the only way to tell what actually changed.
		before, beforeErr := svc.GetTrip(r.Context(), id)

		t, err := svc.Update(r.Context(), id, userID, trip.UpdateParams{
			Title:            req.Title,
			Location:         req.Location,
			StartTime:        req.StartTime,
			EndDate:          req.EndDate,
			Description:      req.Description,
			MeetingPoint:     req.MeetingPoint,
			DiveCountMin:     req.DiveCountMin,
			DiveCountMax:     req.DiveCountMax,
			DepthMinM:        req.DepthMinM,
			DepthMaxM:        req.DepthMaxM,
			MinCertification: req.MinCertification,
			MaxParticipants:  req.MaxParticipants,
			PriceMinor:       req.PriceMinor,
			BookingURL:       req.BookingURL,
			Latitude:         req.Latitude,
			Longitude:        req.Longitude,
		})
		if err != nil {
			if errors.Is(err, trip.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, ErrCodeGeneric)
				return
			}
			if errors.Is(err, trip.ErrNotFound) {
				writeError(w, http.StatusNotFound, ErrCodeTripNotFound)
				return
			}
			if errors.Is(err, trip.ErrOnlyOrganizerCanEditTrip) {
				writeError(w, http.StatusForbidden, ErrCodeOnlyOrganizerCanEditTrip)
				return
			}
			if errors.Is(err, trip.ErrBusinessTripRequiresPriceAndURL) {
				writeError(w, http.StatusBadRequest, ErrCodeBusinessTripRequiresPricing)
				return
			}
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		if beforeErr == nil {
			detailsChanged := !before.StartTime.Equal(t.StartTime) || before.MeetingPoint != t.MeetingPoint
			if detailsChanged {
				recipients := excludeUser(TripRecipientIDs(r.Context(), svc, diveCenterSvc, t), userID)
				if len(recipients) > 0 {
					pushSvc.SendToUsers(r.Context(), recipients, push.Notification{
						Title: t.Title,
						Body:  "Trip time or meeting point changed — check the details.",
						Data:  map[string]string{"tripId": t.ID.String(), "type": "trip_updated"},
					})
				}
			}
		}

		joined, err := svc.IsJoined(r.Context(), id, userID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}
		participantCount, err := svc.CountParticipants(r.Context(), t.ID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}
		writeJSON(w, http.StatusOK, toTripResponse(t, joined, participantCount))
	}
}

// handleLeaveTrip orchestrates trip.Leave's organizer-can't-leave rule together with transport's cascade (their joins freed, offers they created dissolved and alerted).
func handleLeaveTrip(svc *trip.Service, transportSvc *transport.Service, buddySvc *buddy.Service, pushSvc *push.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		id := r.PathValue("id")
		tripID, err := uuid.Parse(id)
		if err != nil {
			writeError(w, http.StatusBadRequest, ErrCodeGeneric)
			return
		}

		// Organizer check (inside svc.Leave) runs first, since the transport cascade below must never fire for a rejected leave attempt.
		if err := svc.Leave(r.Context(), id, userID); err != nil {
			if errors.Is(err, trip.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, ErrCodeGeneric)
				return
			}
			if errors.Is(err, trip.ErrNotFound) {
				writeError(w, http.StatusNotFound, ErrCodeTripNotFound)
				return
			}
			if errors.Is(err, trip.ErrOrganizerCannotLeave) {
				writeError(w, http.StatusForbidden, ErrCodeOrganizerCannotLeaveTrip)
				return
			}
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		alertedUserIDs, err := transportSvc.HandleUserLeavingTrip(r.Context(), tripID, userID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}
		buddyAlertedUserIDs, err := buddySvc.HandleUserLeavingTrip(r.Context(), tripID, userID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}
		if len(alertedUserIDs) > 0 || len(buddyAlertedUserIDs) > 0 {
			// Best-effort: the leave already succeeded, so a failed re-fetch just skips this notification.
			if t, err := svc.GetTrip(r.Context(), id); err == nil {
				if len(alertedUserIDs) > 0 {
					pushSvc.SendToUsers(r.Context(), dedupeUsers(alertedUserIDs), push.Notification{
						Title: t.Title,
						Body:  "A transport offer you joined was cancelled — check the Transport tab.",
						Data:  map[string]string{"tripId": t.ID.String(), "type": "transport_alert"},
					})
				}
				if len(buddyAlertedUserIDs) > 0 {
					pushSvc.SendToUsers(r.Context(), dedupeUsers(buddyAlertedUserIDs), push.Notification{
						Title: t.Title,
						Body:  "A buddy group you joined was cancelled — check the Buddy tab.",
						Data:  map[string]string{"tripId": t.ID.String(), "type": "buddy_alert"},
					})
				}
			}
		}

		w.WriteHeader(http.StatusNoContent)
	}
}

// handleListParticipants is gated to participants only, since who joined a trip isn't public information any more than the trip's chat is.
func handleListParticipants(svc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		tripIDStr := r.PathValue("id")
		if _, ok := requireParticipant(w, r, svc, tripIDStr, userID); !ok {
			return
		}
		ids, err := svc.ListParticipantUserIDs(r.Context(), tripIDStr)
		if err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
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
				writeError(w, http.StatusBadRequest, ErrCodeGeneric)
				return
			}
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}
		w.WriteHeader(http.StatusNoContent)
	}
}

func handleGetTripMute(svc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		id := r.PathValue("id")
		muted, err := svc.IsMuted(r.Context(), id, userID)
		if err != nil {
			if errors.Is(err, trip.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, ErrCodeGeneric)
				return
			}
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}
		writeJSON(w, http.StatusOK, map[string]bool{"muted": muted})
	}
}

// handleMuteTrip/handleUnmuteTrip are deliberately un-gated by requireParticipant, since muting a trip you've since left is harmless either way.
func handleMuteTrip(svc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		id := r.PathValue("id")
		if err := svc.Mute(r.Context(), id, userID); err != nil {
			if errors.Is(err, trip.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, ErrCodeGeneric)
				return
			}
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}
		w.WriteHeader(http.StatusNoContent)
	}
}

func handleUnmuteTrip(svc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		id := r.PathValue("id")
		if err := svc.Unmute(r.Context(), id, userID); err != nil {
			if errors.Is(err, trip.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, ErrCodeGeneric)
				return
			}
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}
		w.WriteHeader(http.StatusNoContent)
	}
}

func handleGetTripArchive(svc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		id := r.PathValue("id")
		archived, err := svc.IsArchived(r.Context(), id, userID)
		if err != nil {
			if errors.Is(err, trip.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, ErrCodeGeneric)
				return
			}
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}
		writeJSON(w, http.StatusOK, map[string]bool{"archived": archived})
	}
}

// handleArchiveTrip/handleUnarchiveTrip share handleMuteTrip's un-gated posture, since archiving a trip you've since left is harmless.
func handleArchiveTrip(svc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		id := r.PathValue("id")
		if err := svc.Archive(r.Context(), id, userID); err != nil {
			if errors.Is(err, trip.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, ErrCodeGeneric)
				return
			}
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}
		w.WriteHeader(http.StatusNoContent)
	}
}

func handleUnarchiveTrip(svc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		id := r.PathValue("id")
		if err := svc.Unarchive(r.Context(), id, userID); err != nil {
			if errors.Is(err, trip.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, ErrCodeGeneric)
				return
			}
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}
		w.WriteHeader(http.StatusNoContent)
	}
}

type submitFeedbackRequest struct {
	Rating     int      `json:"rating"`
	HelpedWith []string `json:"helpedWith"`
	Comment    string   `json:"comment"`
	ContactOk  bool     `json:"contactOk"`
}

// handleSubmitFeedback is gated by requireParticipant, unlike mute, since feedback only makes sense from someone who was actually on the trip.
func handleSubmitFeedback(svc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		tripID, ok := requireParticipant(w, r, svc, r.PathValue("id"), userID)
		if !ok {
			return
		}

		var req submitFeedbackRequest
		dec := json.NewDecoder(io.LimitReader(r.Body, 1<<20))
		if err := dec.Decode(&req); err != nil {
			writeError(w, http.StatusBadRequest, ErrCodeGeneric)
			return
		}

		comment := sql.NullString{}
		if trimmed := strings.TrimSpace(req.Comment); trimmed != "" {
			comment = sql.NullString{String: trimmed, Valid: true}
		}
		helpedWith := strings.Join(req.HelpedWith, ", ")

		if err := svc.SubmitFeedback(r.Context(), tripID.String(), userID, req.Rating, helpedWith, comment, req.ContactOk); err != nil {
			if errors.Is(err, trip.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, ErrCodeRatingOutOfRange)
				return
			}
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}
		w.WriteHeader(http.StatusNoContent)
	}
}

func handleListMyTrips(svc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		archived := r.URL.Query().Get("archived") == "true"
		trips, err := svc.ListJoinedByUser(r.Context(), userID, archived)
		if err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		out := make([]tripResponse, 0, len(trips))
		for _, t := range trips {
			out = append(out, toTripResponse(t, true, t.ParticipantCount))
		}
		writeJSON(w, http.StatusOK, out)
	}
}

// handleListTrips stays browsable anonymously; userID is uuid.Nil for anonymous callers, which IsOwner treats the same as any non-owner account.
func handleListTrips(svc *trip.Service, accountSvc *account.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		viewerIsOwner, err := accountSvc.IsOwner(r.Context(), userID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		query := r.URL.Query().Get("q")
		trips, err := svc.ListTrips(r.Context(), query, viewerIsOwner)
		if err != nil {
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		out := make([]tripResponse, 0, len(trips))
		for _, t := range trips {
			out = append(out, toTripResponse(t, false, 0))
		}
		writeJSON(w, http.StatusOK, out)
	}
}

func handleListTripPhotos(svc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, _ uuid.UUID) {
		id := r.PathValue("id")
		photos, err := svc.ListPhotos(r.Context(), id)
		if err != nil {
			if errors.Is(err, trip.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, ErrCodeGeneric)
				return
			}
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}

		out := make([]tripPhotoResponse, 0, len(photos))
		for _, p := range photos {
			out = append(out, toTripPhotoResponse(p))
		}
		writeJSON(w, http.StatusOK, out)
	}
}

func handleDeleteTripPhoto(svc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		id := r.PathValue("id")
		photoID, err := uuid.Parse(r.PathValue("photoId"))
		if err != nil {
			writeError(w, http.StatusBadRequest, ErrCodeGeneric)
			return
		}

		if err := svc.RemovePhoto(r.Context(), id, userID, photoID); err != nil {
			if errors.Is(err, trip.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, ErrCodeGeneric)
				return
			}
			if errors.Is(err, trip.ErrNotFound) {
				writeError(w, http.StatusNotFound, ErrCodeTripNotFound)
				return
			}
			if errors.Is(err, trip.ErrOnlyOrganizerCanEditTrip) {
				writeError(w, http.StatusForbidden, ErrCodeOnlyOrganizerCanEditTrip)
				return
			}
			if errors.Is(err, trip.ErrPhotoNotFound) {
				writeError(w, http.StatusNotFound, ErrCodePhotoNotFound)
				return
			}
			writeError(w, http.StatusInternalServerError, ErrCodeGeneric)
			return
		}
		w.WriteHeader(http.StatusNoContent)
	}
}
