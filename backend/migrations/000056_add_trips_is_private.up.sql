-- Private trips reuse the booking_code join gate (see trip.Service.Join/CreateTrip) instead
-- of a separate visibility system — this flag just controls Explore listing.
ALTER TABLE trips ADD COLUMN is_private boolean NOT NULL DEFAULT false;
