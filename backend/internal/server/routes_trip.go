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
	mux.HandleFunc("POST /trips/{id}/feedback", withAuth(authIssuer, handleSubmitFeedback(svc)))
	// Same "browsable without an account" posture as GET /trips/{id} — the gallery is part
	// of the trip's own public detail, not gated behind participation. Adding a photo (POST)
	// is a multipart upload, so it's registered in routes_upload.go alongside the others.
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
	ID                uuid.UUID  `json:"id"`
	Title             string     `json:"title"`
	Location          string     `json:"location"`
	StartTime         time.Time  `json:"startTime"`
	CreatedAt         time.Time  `json:"createdAt"`
	Joined            bool       `json:"joined"`
	CreatorUserID     *uuid.UUID `json:"creatorUserId,omitempty"`
	ParticipantCount  int        `json:"participantCount"`
	UnreadCount       int        `json:"unreadCount"`
	HasTransportAlert bool       `json:"hasTransportAlert"`
	HasUnreadMention  bool       `json:"hasUnreadMention"`
	HasBuddyAlert     bool       `json:"hasBuddyAlert"`

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
		ID:                t.ID,
		Title:             t.Title,
		Location:          t.Location,
		StartTime:         t.StartTime,
		CreatedAt:         t.CreatedAt,
		Joined:            joined,
		ParticipantCount:  participantCount,
		UnreadCount:       t.UnreadCount,
		HasTransportAlert: t.HasTransportAlert,
		HasUnreadMention:  t.HasUnreadMention,
		HasBuddyAlert:     t.HasBuddyAlert,
		EndDate:           nullTimePtr(t.EndDate),
		Description:       nullStringPtr(t.Description),
		MeetingPoint:      nullStringPtr(t.MeetingPoint),
		DiveCountMin:      nullInt32Ptr(t.DiveCountMin),
		DiveCountMax:      nullInt32Ptr(t.DiveCountMax),
		DepthMinM:         nullInt32Ptr(t.DepthMinM),
		DepthMaxM:         nullInt32Ptr(t.DepthMaxM),
		MinCertification:  nullStringPtr(t.MinCertification),
		BookingCode:       nullStringPtr(t.BookingCode),
		MaxParticipants:   nullInt32Ptr(t.MaxParticipants),
		BookingStatus:     t.BookingStatus,
		PhotoURL:          nullStringPtr(t.PhotoURL),
		PriceMinor:        nullInt32Ptr(t.PriceMinor),
		Currency:          t.Currency,
		BookingURL:        nullStringPtr(t.BookingURL),
		Latitude:          nullFloat64Ptr(t.Latitude),
		Longitude:         nullFloat64Ptr(t.Longitude),
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

	// DiveCenterID set means this is a business trip — the caller must be a member of that
	// dive center (checked in trip.Service.CreateTrip), and the creator doesn't get
	// auto-joined the way an individual organizer does (see CreateTrip's own comment).
	// BookingCode above is ignored for business trips either way — trip.Service.CreateTrip
	// always overwrites it with a fresh server-generated code (see booking_code.go).
	DiveCenterID *uuid.UUID `json:"diveCenterId"`
	PriceMinor   *int       `json:"priceMinor"`
	BookingURL   *string    `json:"bookingUrl"`

	// Best-effort client-side forward-geocode of Location/MeetingPoint — see model.go.
	Latitude  *float64 `json:"latitude"`
	Longitude *float64 `json:"longitude"`
}

func handleCreateTrip(svc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		var req createTripRequest
		dec := json.NewDecoder(io.LimitReader(r.Body, 1<<20))
		if err := dec.Decode(&req); err != nil {
			writeError(w, http.StatusBadRequest, "invalid JSON body")
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
		})
		if err != nil {
			if errors.Is(err, trip.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, "title, location and startTime are required")
				return
			}
			if errors.Is(err, trip.ErrEndDateBeforeStart) {
				writeError(w, http.StatusBadRequest, "end date is before the start date")
				return
			}
			if errors.Is(err, trip.ErrNotDiveCenterMember) {
				writeError(w, http.StatusForbidden, "not a member of that dive center")
				return
			}
			if errors.Is(err, trip.ErrBusinessTripRequiresPriceAndURL) {
				writeError(w, http.StatusBadRequest, "business trips require a price and a booking URL")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not create trip")
			return
		}

		// A business trip has no trip_participants row for its creator (see CreateTrip),
		// so `joined` here would be misleading either way — the client doesn't currently
		// branch on it for the just-created-trip response, only true participantCount matters.
		writeJSON(w, http.StatusCreated, toTripResponse(t, req.DiveCenterID == nil, 1))
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

func handleJoinTrip(svc *trip.Service, diveCenterSvc *divecenter.Service, profileSvc *profile.Service, pushSvc *push.Service, messageSvc *message.Service, publisher *realtime.Publisher) func(http.ResponseWriter, *http.Request, uuid.UUID) {
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
			if errors.Is(err, trip.ErrTripNotOpen) {
				writeError(w, http.StatusConflict, "trip is not open to join")
				return
			}
			if errors.Is(err, trip.ErrRequiresBookingCode) {
				writeError(w, http.StatusConflict, "this trip requires a booking code — use join-by-code instead")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not join trip")
			return
		}

		if t, err := svc.GetTrip(r.Context(), id); err == nil {
			notifyOrganizerOfNewParticipant(r.Context(), pushSvc, profileSvc, t, userID)
			notifyIfObserverJoined(r.Context(), messageSvc, publisher, profileSvc, t.ID, userID)
		}

		writeJSON(w, http.StatusOK, map[string]bool{"joined": true})
	}
}

// notifyIfObserverJoined posts the one-time "Product Observer" system message when the
// joining account is flagged is_product_observer — see users.is_product_observer (migration
// 000049). SendSystem is idempotent per trip+kind, so a leave-then-rejoin never re-announces.
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
	// Field names kept in sync with messageResponse in routes_message.go, same as the
	// feedback-prompt scan's payload in main.go.
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

// notifyOrganizerOfNewParticipant covers the individual-trip case only — Join (above) is the
// individual-organizer join path; a business trip's roster notification lives in
// notifyStaffOfBookingCodeJoin instead, since staff means everyone in the dive center,
// not one organizer.
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

// handleJoinTripByCode is the marketplace redemption path for business trips (see
// trip.Service.JoinByCode) — no trip id in the URL, since the code alone is what the diver
// actually has after paying on the dive center's own site.
func handleJoinTripByCode(svc *trip.Service, diveCenterSvc *divecenter.Service, profileSvc *profile.Service, pushSvc *push.Service, messageSvc *message.Service, publisher *realtime.Publisher) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		var req joinByCodeRequest
		dec := json.NewDecoder(io.LimitReader(r.Body, 1<<20))
		if err := dec.Decode(&req); err != nil {
			writeError(w, http.StatusBadRequest, "invalid JSON body")
			return
		}

		t, err := svc.JoinByCode(r.Context(), req.Code, userID)
		if err != nil {
			if errors.Is(err, trip.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, "code is required")
				return
			}
			if errors.Is(err, trip.ErrInvalidBookingCode) {
				writeError(w, http.StatusNotFound, "invalid booking code")
				return
			}
			if errors.Is(err, trip.ErrTripNotOpen) {
				writeError(w, http.StatusConflict, "trip is not open to join")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not join trip")
			return
		}

		notifyStaffOfBookingCodeJoin(r.Context(), pushSvc, profileSvc, diveCenterSvc, t, userID)
		notifyIfObserverJoined(r.Context(), messageSvc, publisher, profileSvc, t.ID, userID)

		participantCount, err := svc.CountParticipants(r.Context(), t.ID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not join trip")
			return
		}
		writeJSON(w, http.StatusOK, toTripResponse(t, true, participantCount))
	}
}

// notifyStaffOfBookingCodeJoin is the business-trip roster-change notification — every
// staff member of the dive center, not just whoever created the trip (see CLAUDE.md's
// Business/dive-center section: the organization is the organizer, not one employee).
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

// handleCancelTrip is organizer-only (enforced inside svc.Cancel) and final — booking_status
// flips to "cancelled", which is what everything downstream keys off: Explore's List query
// excludes it, the Join handler above rejects new joins, and message/transport handlers call
// EnsureNotCancelled to freeze new activity while read access (history, participants,
// existing transport) stays untouched.
func handleCancelTrip(svc *trip.Service, diveCenterSvc *divecenter.Service, pushSvc *push.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		id := r.PathValue("id")
		if err := svc.Cancel(r.Context(), id, userID); err != nil {
			if errors.Is(err, trip.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, "invalid trip id")
				return
			}
			if errors.Is(err, trip.ErrNotFound) {
				writeError(w, http.StatusNotFound, "trip not found")
				return
			}
			if errors.Is(err, trip.ErrOnlyOrganizerCanCancel) {
				writeError(w, http.StatusForbidden, "only the organizer can cancel this trip")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not cancel trip")
			return
		}

		// Best-effort — the cancellation itself already succeeded above; a failed re-fetch
		// here just means this notification is skipped, not that cancellation failed.
		if t, err := svc.GetTrip(r.Context(), id); err == nil {
			recipients := excludeUser(tripRecipientIDs(r.Context(), svc, diveCenterSvc, t), userID)
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
}

// handleUpdateTrip is organizer-only (enforced inside svc.Update, same isOrganizer check as
// Cancel/SetPhotoURL). Every field is optional — a nil pointer leaves that column untouched
// (see trip.UpdateParams), so callers only send the fields they actually changed.
func handleUpdateTrip(svc *trip.Service, diveCenterSvc *divecenter.Service, pushSvc *push.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		id := r.PathValue("id")
		var req updateTripRequest
		dec := json.NewDecoder(io.LimitReader(r.Body, 1<<20))
		if err := dec.Decode(&req); err != nil {
			writeError(w, http.StatusBadRequest, "invalid JSON body")
			return
		}

		// Snapshotted before the update — the client (admin/'s edit form) resends every
		// field on every save, not just what actually changed, so the only reliable way to
		// tell "did the time or meeting point actually change" is to diff before vs after.
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
		})
		if err != nil {
			if errors.Is(err, trip.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, "invalid trip id or field value")
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
			if errors.Is(err, trip.ErrBusinessTripRequiresPriceAndURL) {
				writeError(w, http.StatusBadRequest, "business trips require a price and a booking URL")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not update trip")
			return
		}

		if beforeErr == nil {
			detailsChanged := !before.StartTime.Equal(t.StartTime) || before.MeetingPoint != t.MeetingPoint
			if detailsChanged {
				recipients := excludeUser(tripRecipientIDs(r.Context(), svc, diveCenterSvc, t), userID)
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
			writeError(w, http.StatusInternalServerError, "could not update trip")
			return
		}
		participantCount, err := svc.CountParticipants(r.Context(), t.ID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not update trip")
			return
		}
		writeJSON(w, http.StatusOK, toTripResponse(t, joined, participantCount))
	}
}

// handleLeaveTrip orchestrates across both trip and transport: dropping trip.Leave's
// business rule (organizer can't leave) plus transport's cascade (their own joins freed,
// any offer *they* created dissolved with an alert for whoever had joined it — see
// transport.Service.HandleUserLeavingTrip).
func handleLeaveTrip(svc *trip.Service, transportSvc *transport.Service, buddySvc *buddy.Service, pushSvc *push.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		id := r.PathValue("id")
		tripID, err := uuid.Parse(id)
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid trip id")
			return
		}

		// Organizer check (inside svc.Leave) runs first and blocks entirely on failure —
		// the transport cascade below must never fire for a rejected leave attempt.
		if err := svc.Leave(r.Context(), id, userID); err != nil {
			if errors.Is(err, trip.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, "invalid trip id")
				return
			}
			if errors.Is(err, trip.ErrNotFound) {
				writeError(w, http.StatusNotFound, "trip not found")
				return
			}
			if errors.Is(err, trip.ErrOrganizerCannotLeave) {
				writeError(w, http.StatusForbidden, "organizer cannot leave their own trip — cancel it instead")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not leave trip")
			return
		}

		alertedUserIDs, err := transportSvc.HandleUserLeavingTrip(r.Context(), tripID, userID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not clean up transport offers")
			return
		}
		buddyAlertedUserIDs, err := buddySvc.HandleUserLeavingTrip(r.Context(), tripID, userID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not clean up buddy requests")
			return
		}
		if len(alertedUserIDs) > 0 || len(buddyAlertedUserIDs) > 0 {
			// Best-effort — the leave itself already succeeded; a failed re-fetch here just
			// means this notification is skipped.
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

// Gated to participants only (requireParticipant, same guard as messages/transport) — who
// joined a trip isn't public information, just like the trip's chat isn't.
func handleListParticipants(svc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		tripIDStr := r.PathValue("id")
		if _, ok := requireParticipant(w, r, svc, tripIDStr, userID); !ok {
			return
		}
		ids, err := svc.ListParticipantUserIDs(r.Context(), tripIDStr)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not list participants")
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
				writeError(w, http.StatusBadRequest, "invalid trip id")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not mark trip read")
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
				writeError(w, http.StatusBadRequest, "invalid trip id")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not get mute state")
			return
		}
		writeJSON(w, http.StatusOK, map[string]bool{"muted": muted})
	}
}

// handleMuteTrip/handleUnmuteTrip are deliberately un-gated by requireParticipant — muting
// a trip you've since left (or a business trip's staff role) is harmless either way, and
// this stays consistent with MarkRead above, which has the same posture.
func handleMuteTrip(svc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		id := r.PathValue("id")
		if err := svc.Mute(r.Context(), id, userID); err != nil {
			if errors.Is(err, trip.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, "invalid trip id")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not mute trip")
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
				writeError(w, http.StatusBadRequest, "invalid trip id")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not unmute trip")
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

// handleSubmitFeedback is gated by requireParticipant, unlike mute — feedback only makes
// sense from someone who was actually on the trip.
func handleSubmitFeedback(svc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		tripID, ok := requireParticipant(w, r, svc, r.PathValue("id"), userID)
		if !ok {
			return
		}

		var req submitFeedbackRequest
		dec := json.NewDecoder(io.LimitReader(r.Body, 1<<20))
		if err := dec.Decode(&req); err != nil {
			writeError(w, http.StatusBadRequest, "invalid JSON body")
			return
		}

		comment := sql.NullString{}
		if trimmed := strings.TrimSpace(req.Comment); trimmed != "" {
			comment = sql.NullString{String: trimmed, Valid: true}
		}
		helpedWith := strings.Join(req.HelpedWith, ", ")

		if err := svc.SubmitFeedback(r.Context(), tripID.String(), userID, req.Rating, helpedWith, comment, req.ContactOk); err != nil {
			if errors.Is(err, trip.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, "rating must be between 1 and 5")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not submit feedback")
			return
		}
		w.WriteHeader(http.StatusNoContent)
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
			out = append(out, toTripResponse(t, true, t.ParticipantCount))
		}
		writeJSON(w, http.StatusOK, out)
	}
}

// Stays browsable anonymously (optionalAuth) — userID is uuid.Nil for anonymous callers,
// which IsOwner treats the same as any non-owner account.
func handleListTrips(svc *trip.Service, accountSvc *account.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		viewerIsOwner, err := accountSvc.IsOwner(r.Context(), userID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not list trips")
			return
		}

		query := r.URL.Query().Get("q")
		trips, err := svc.ListTrips(r.Context(), query, viewerIsOwner)
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

func handleListTripPhotos(svc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, _ uuid.UUID) {
		id := r.PathValue("id")
		photos, err := svc.ListPhotos(r.Context(), id)
		if err != nil {
			if errors.Is(err, trip.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, "invalid trip id")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not list trip photos")
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
			writeError(w, http.StatusBadRequest, "invalid photo id")
			return
		}

		if err := svc.RemovePhoto(r.Context(), id, userID, photoID); err != nil {
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
			if errors.Is(err, trip.ErrPhotoNotFound) {
				writeError(w, http.StatusNotFound, "photo not found")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not remove trip photo")
			return
		}
		w.WriteHeader(http.StatusNoContent)
	}
}
