-- Best-effort geocoded coordinates (client-side forward-geocode of location/meeting_point at
-- Create Trip time) — nullable, since geocoding can fail or a trip's location text may not
-- resolve to a real address. Powers client-side distance sorting in Explore's "Nearest" sort.
ALTER TABLE trips ADD COLUMN latitude DOUBLE PRECISION;
ALTER TABLE trips ADD COLUMN longitude DOUBLE PRECISION;
