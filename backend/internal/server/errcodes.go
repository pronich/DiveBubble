package server

// ErrCodeGeneric is the fallback for any error with no user-meaningful distinction, and is also what the client falls back to for any code it doesn't recognize.
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
	// ErrCodeUnauthenticated covers both missing/malformed and invalid/expired tokens, since the client treats both identically as signed out.
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

// Shared between transport and buddy — same underlying concept, so the diver shouldn't see different strings depending on which tab they were in.
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

// Message/Chat (routes_message.go)
const (
	ErrCodeNotParticipant            = "not_participant"
	ErrCodeMessageBodyOrAttachment   = "message_body_or_attachment_required"
	ErrCodeMessageNotFoundOrNotYours = "message_not_found_or_not_yours"
	ErrCodeInvalidReactionEmoji      = "invalid_reaction_emoji"
	ErrCodeMessageNotFound           = "message_not_found"
	ErrCodeInvalidAttachmentType     = "invalid_attachment_type"
)

// Profile (routes_profile.go)
const ErrCodeUserNotFound = "user_not_found"

// DiveCenter (routes_divecenter.go) — admin/ isn't in scope for translations yet, so only ErrCodeDiveCenterNotFound has a client-side message today; the rest exist for contract consistency.
const (
	ErrCodeDiveCenterNotFound        = "dive_center_not_found"
	ErrCodeNameRequired              = "name_required"
	ErrCodeOnlyOwnerCanEditCompany   = "only_owner_can_edit_company"
	ErrCodeNotMemberOfDiveCenter     = "not_member_of_dive_center"
	ErrCodeOnlyOwnerCanSearchMembers = "only_owner_can_search_members"
	ErrCodeEmailRequired             = "email_required"
	ErrCodeNoAccountForEmail         = "no_account_for_email"
	ErrCodeAmbiguousEmailMatch       = "ambiguous_email_match"
	ErrCodeOnlyOwnerCanAddMembers    = "only_owner_can_add_members"
	ErrCodeOnlyOwnerCanRemoveMembers = "only_owner_can_remove_members"
	ErrCodeCannotRemoveLastOwner     = "cannot_remove_last_owner"
	ErrCodeMemberNotFound            = "member_not_found"
	ErrCodeOnlyOwnerCanInviteMembers = "only_owner_can_invite_members"
)

// Gear (routes_gear.go)
const ErrCodeGearItemNotFound = "gear_item_not_found"

// Certification/Specialty (routes_certification.go)
const (
	ErrCodeSpecialtyRequired = "specialty_required"
	ErrCodeSpecialtyNotFound = "specialty_not_found"
)

// Expense (routes_expense.go)
const (
	ErrCodeExpenseNotFound             = "expense_not_found"
	ErrCodeSplitAmountsMismatch        = "split_amounts_mismatch"
	ErrCodeOnlyCreatorCanDeleteExpense = "only_creator_can_delete_expense"
	ErrCodeInvalidSettlement           = "invalid_settlement"
)

// DiveLog (routes_divelog.go)
const (
	ErrCodeDiveDateTimeRequired      = "dive_date_time_required"
	ErrCodeDiveLogEntryNotFound      = "dive_log_entry_not_found"
	ErrCodeNotYourDiveLogEntry       = "not_your_dive_log_entry"
	ErrCodeInvalidUDDFFile           = "invalid_uddf_file"
	ErrCodeInvalidCSVFile            = "invalid_csv_file"
	ErrCodeInvalidDivingLog6File     = "invalid_divinglog6_file"
	ErrCodeUnrecognizedDiveLogFormat = "unrecognized_dive_log_format"
)

// Upload (routes_upload.go)
const (
	ErrCodeTripPhotoLimitReached = "trip_photo_limit_reached"
	ErrCodeInvalidImage          = "invalid_image"
	ErrCodeFileTooLarge          = "file_too_large"
	ErrCodeInvalidAttachmentFile = "invalid_attachment_file"
)

// Moderation (routes_moderation.go)
const (
	ErrCodeReasonRequired      = "reason_required"
	ErrCodeCannotBlockYourself = "cannot_block_yourself"
)
