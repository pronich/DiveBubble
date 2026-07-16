-- booking_url: per-trip external checkout link (not the dive center's general website —
-- a real trip like KingFish's Drive & Dive Lysekil has its own booking page, distinct from
-- the dive center's homepage already stored on dive_centers.website).
ALTER TABLE trips ADD COLUMN booking_url TEXT;

-- Business trips get a server-generated booking_code at creation (see trip.Service
-- generateBookingCode) so a diver can only join by redeeming the code they got from
-- actually paying on the dive center's own site — this constraint is what makes
-- "resolve a trip by its code alone" (POST /trips/join-by-code) safe: multiple NULLs are
-- allowed (individual trips never set one), but any two set codes must be distinct.
ALTER TABLE trips ADD CONSTRAINT trips_booking_code_key UNIQUE (booking_code);
