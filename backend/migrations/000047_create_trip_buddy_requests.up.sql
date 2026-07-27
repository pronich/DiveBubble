-- Dead-simple buddy request: no type/seats/details, just "I want a buddy" — capacity (3
-- total including the creator) is enforced in Go, not the schema.
CREATE TABLE trip_buddy_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id UUID NOT NULL REFERENCES trips (id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_trip_buddy_requests_trip ON trip_buddy_requests (trip_id, created_at);

CREATE TABLE buddy_request_joins (
    request_id UUID NOT NULL REFERENCES trip_buddy_requests (id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (request_id, user_id)
);

-- Mirrors transport_alerts — "something changed in Buddy, go check" dot for the tab, since
-- the offers/requests list itself has no realtime (only an individual group's chat does).
CREATE TABLE buddy_alerts (
    trip_id UUID NOT NULL REFERENCES trips (id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (trip_id, user_id)
);
