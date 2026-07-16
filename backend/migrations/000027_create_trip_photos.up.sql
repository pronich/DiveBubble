CREATE TABLE trip_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    url TEXT NOT NULL,
    position INT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (trip_id, position)
);

CREATE INDEX idx_trip_photos_trip_id ON trip_photos (trip_id);

-- Every existing single-photo trip becomes a one-item gallery at position 0 — no data loss
-- moving off the old trips.photo_url column.
INSERT INTO trip_photos (trip_id, url, position)
SELECT id, photo_url, 0 FROM trips WHERE photo_url IS NOT NULL;

ALTER TABLE trips DROP COLUMN photo_url;
