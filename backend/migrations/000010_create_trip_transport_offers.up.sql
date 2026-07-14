CREATE TABLE trip_transport_offers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id UUID NOT NULL REFERENCES trips (id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('offer_ride', 'find_ride', 'share_rental', 'self_arranged')),
    seats INT CHECK (seats IS NULL OR seats > 0),
    details TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_trip_transport_offers_trip ON trip_transport_offers (trip_id, created_at);
