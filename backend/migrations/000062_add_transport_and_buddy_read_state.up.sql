-- Per-user read tracking for a car offer's or buddy group's own chat — mirrors
-- trip_read_state, but scoped narrower since these chats only exist once you've
-- created or joined one.
CREATE TABLE transport_offer_read_state (
    offer_id UUID NOT NULL REFERENCES trip_transport_offers (id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    last_read_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (offer_id, user_id)
);

CREATE TABLE buddy_request_read_state (
    request_id UUID NOT NULL REFERENCES trip_buddy_requests (id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    last_read_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (request_id, user_id)
);
