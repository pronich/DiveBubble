DROP INDEX idx_trips_dive_center_id;

ALTER TABLE trips
    DROP COLUMN dive_center_id,
    DROP COLUMN price_minor,
    DROP COLUMN currency;
