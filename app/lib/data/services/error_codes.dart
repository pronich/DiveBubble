// Maps a backend error code (see backend/internal/server/errcodes.go) to a message to show
// the diver. The backend is being converted to codes one area at a time — an unrecognized
// code (an area not converted yet, or old-style prose slipping through) is returned as-is
// rather than treated as an error, so client and backend never need a hard synchronized
// cutover; each area can ship independently.
//
// Not yet localized (see the translations plan) — these are the English strings that will
// become the base .arb entries once that infrastructure lands.
String describeErrorCode(String code) => _messages[code] ?? code;

const _messages = <String, String>{
  'generic_error': 'Something went wrong. Please try again.',

  // Auth (backend/internal/server/routes_auth.go)
  'google_token_invalid': 'Google sign-in failed. Please try again.',
  'apple_token_invalid': 'Apple sign-in failed. Please try again.',
  'invalid_email': 'Enter a valid email address.',
  'email_code_cooldown': 'A code was already sent — check your inbox.',
  'email_and_code_required': 'Enter your email and the code you received.',
  'email_code_invalid': 'That code is invalid or has expired.',
  'email_code_too_many_tries': 'Too many incorrect attempts — request a new code.',
  'refresh_token_invalid': 'Your session is no longer valid. Please sign in again.',
  'refresh_token_expired': 'Your session has expired. Please sign in again.',
  'refresh_token_revoked': 'Your session is no longer valid. Please sign in again.',
  'refresh_token_reused': 'Your session was already refreshed elsewhere. Please sign in again.',
  'unauthenticated': 'Please sign in again.',

  // Trip (backend/internal/server/routes_trip.go)
  'trip_fields_required': 'Title, location, and date are required.',
  'end_date_before_start': "End date can't be before the start date.",
  'not_dive_center_member': 'You are not a member of that dive center.',
  'business_trip_requires_pricing': 'Business trips require a price and a booking URL.',
  'trip_not_found': 'This trip could not be found.',
  'invalid_booking_code': 'That booking code is invalid.',
  'trip_not_open_to_join': 'This trip is not open to join.',
  'trip_requires_booking_code': 'This trip requires a booking code — use join by code instead.',
  'booking_code_required': 'Enter a booking code.',
  'only_organizer_can_cancel_trip': 'Only the organizer can cancel this trip.',
  'only_organizer_can_edit_trip': 'Only the organizer can edit this trip.',
  'organizer_cannot_leave_trip': 'As the organizer, cancel the trip instead of leaving it.',
  'rating_out_of_range': 'Rating must be between 1 and 5.',
  'photo_not_found': 'This photo could not be found.',

  // Shared between Transport and Buddy
  'trip_cancelled': 'This trip has been cancelled.',
  'body_or_attachment_required': 'Write a message or attach something first.',

  // Transport (backend/internal/server/routes_transport.go)
  'transport_offer_not_found': 'This ride could not be found.',
  'not_part_of_car': "You're not part of this car.",
  'invalid_offer_type_or_seats': 'Check the ride type and number of seats.',
  'no_seats_left': 'No seats left in this car.',
  'already_joined_transport_offer': "You've already joined a ride on this trip.",
  'creator_cannot_leave_car': 'Dissolve this car instead of leaving it — you created it.',
  'only_creator_can_dissolve_car': 'Only the creator can dissolve this car.',

  // Buddy (backend/internal/server/routes_buddy.go)
  'buddy_request_not_found': 'This buddy group could not be found.',
  'not_part_of_buddy_group': "You're not part of this buddy group.",
  'buddy_group_full': 'This buddy group is full.',
  'already_in_buddy_group': "You've already joined a buddy group on this trip.",
  'creator_cannot_leave_buddy_group': 'Dissolve this group instead of leaving it — you created it.',
  'only_creator_can_dissolve_buddy_group': 'Only the creator can dissolve this buddy group.',

  // Message/Chat (backend/internal/server/routes_message.go)
  'not_participant': "You're not a participant of this trip.",
  'message_body_or_attachment_required': 'Write a message or attach a file first.',
  'message_not_found_or_not_yours': "This message can't be deleted.",
  'invalid_reaction_emoji': "That reaction isn't supported.",
  'message_not_found': 'This message could not be found.',
  'invalid_attachment_type': 'That file type is not supported here.',

  // Profile (backend/internal/server/routes_profile.go)
  'user_not_found': 'This diver could not be found.',

  // DiveCenter (backend/internal/server/routes_divecenter.go) — only the codes app/ can
  // actually see (it only views a dive center, never manages one — see
  // DiveCenterApiService's own doc comment). The rest are admin/-only for now; admin/ isn't
  // in scope for translated messages yet, so those codes have no entry here.
  'dive_center_not_found': 'This dive center could not be found.',

  // Gear (backend/internal/server/routes_gear.go)
  'gear_item_not_found': 'This gear item could not be found.',

  // Certification/Specialty (backend/internal/server/routes_certification.go)
  'specialty_required': 'Choose a specialty.',
  'specialty_not_found': 'This specialty could not be found.',
};
