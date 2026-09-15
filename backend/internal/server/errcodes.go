package server

// Error codes returned as the "error" field in an error response body
// ({"error": "<code>"}), replacing free-text English prose so the client can show a
// localized message instead of whatever string happened to be written here. Added
// incrementally, one backend area at a time — see CLAUDE.md's translations section for the
// running list of which areas are done.
//
// ErrCodeGeneric covers everything that isn't meaningful for a user to see distinctly: a
// malformed request body, an unexpected internal failure, or any other "something broke, try
// again" case (a Sentry/log line already carries the real reason — this string never needs
// to). The client can safely fall back to ErrCodeGeneric's own message for any code it
// doesn't recognize, so an area that hasn't been converted to codes yet just degrades to
// this instead of erroring on unknown input.
const ErrCodeGeneric = "generic_error"

// Auth (routes_auth.go)
const (
	ErrCodeGoogleTokenInvalid    = "google_token_invalid"
	ErrCodeAppleTokenInvalid     = "apple_token_invalid"
	ErrCodeInvalidEmail          = "invalid_email"
	ErrCodeEmailCodeCooldown     = "email_code_cooldown"
	ErrCodeEmailAndCodeRequired  = "email_and_code_required"
	ErrCodeEmailCodeInvalid      = "email_code_invalid"
	ErrCodeEmailCodeTooManyTries = "email_code_too_many_tries"
	ErrCodeRefreshTokenInvalid   = "refresh_token_invalid"
	ErrCodeRefreshTokenExpired   = "refresh_token_expired"
	ErrCodeRefreshTokenRevoked   = "refresh_token_revoked"
	ErrCodeRefreshTokenReused    = "refresh_token_reused"
	// ErrCodeUnauthenticated covers both "no/malformed bearer token" and "token invalid or
	// expired" — the client's reaction is identical either way (treat as signed out), so
	// there's no meaningful distinction to preserve for the user.
	ErrCodeUnauthenticated = "unauthenticated"
)

// Trip (routes_trip.go)
const (
	ErrCodeTripFieldsRequired          = "trip_fields_required"
	ErrCodeEndDateBeforeStart          = "end_date_before_start"
	ErrCodeNotDiveCenterMember         = "not_dive_center_member"
	ErrCodeBusinessTripRequiresPricing = "business_trip_requires_pricing"
	ErrCodeTripNotFound                = "trip_not_found"
	ErrCodeInvalidBookingCode          = "invalid_booking_code"
	ErrCodeTripNotOpenToJoin           = "trip_not_open_to_join"
	ErrCodeTripRequiresBookingCode     = "trip_requires_booking_code"
	ErrCodeBookingCodeRequired         = "booking_code_required"
	ErrCodeOnlyOrganizerCanCancelTrip  = "only_organizer_can_cancel_trip"
	ErrCodeOnlyOrganizerCanEditTrip    = "only_organizer_can_edit_trip"
	ErrCodeOrganizerCannotLeaveTrip    = "organizer_cannot_leave_trip"
	ErrCodeRatingOutOfRange            = "rating_out_of_range"
	ErrCodePhotoNotFound               = "photo_not_found"
)

// Shared between transport (routes_transport.go) and buddy (routes_buddy.go) — same
// underlying concept, no reason for the diver to see two different strings for it depending
// on which tab they were in.
const (
	ErrCodeTripCancelled            = "trip_cancelled"
	ErrCodeBodyOrAttachmentRequired = "body_or_attachment_required"
)

// Transport (routes_transport.go)
const (
	ErrCodeTransportOfferNotFound    = "transport_offer_not_found"
	ErrCodeNotPartOfCar              = "not_part_of_car"
	ErrCodeInvalidOfferTypeOrSeats   = "invalid_offer_type_or_seats"
	ErrCodeNoSeatsLeft               = "no_seats_left"
	ErrCodeAlreadyJoinedOffer        = "already_joined_transport_offer"
	ErrCodeCreatorCannotLeaveCar     = "creator_cannot_leave_car"
	ErrCodeOnlyCreatorCanDissolveCar = "only_creator_can_dissolve_car"
)

// Buddy (routes_buddy.go)
const (
	ErrCodeBuddyRequestNotFound             = "buddy_request_not_found"
	ErrCodeNotPartOfBuddyGroup              = "not_part_of_buddy_group"
	ErrCodeBuddyGroupFull                   = "buddy_group_full"
	ErrCodeAlreadyInBuddyGroup              = "already_in_buddy_group"
	ErrCodeCreatorCannotLeaveBuddyGroup     = "creator_cannot_leave_buddy_group"
	ErrCodeOnlyCreatorCanDissolveBuddyGroup = "only_creator_can_dissolve_buddy_group"
)
