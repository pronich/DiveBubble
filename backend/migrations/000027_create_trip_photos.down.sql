ALTER TABLE trips ADD COLUMN photo_url TEXT;

UPDATE trips t
SET photo_url = tp.url
FROM trip_photos tp
WHERE tp.trip_id = t.id AND tp.position = 0;

DROP TABLE trip_photos;
