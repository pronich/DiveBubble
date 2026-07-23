-- Test dive centers stay usable end-to-end (admin panel, staff, trips) for whoever created
-- them, but their trips are excluded from the public Explore feed for everyone except
-- users.is_owner accounts — see trip.Repository.List.
ALTER TABLE dive_centers ADD COLUMN is_test BOOLEAN NOT NULL DEFAULT false;
