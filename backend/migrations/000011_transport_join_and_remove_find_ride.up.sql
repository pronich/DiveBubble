-- find_ride is redundant once you can join a seat on an offer_ride/share_rental directly.
UPDATE trip_transport_offers SET type = 'self_arranged' WHERE type = 'find_ride';

ALTER TABLE trip_transport_offers DROP CONSTRAINT trip_transport_offers_type_check;
ALTER TABLE trip_transport_offers ADD CONSTRAINT trip_transport_offers_type_check
    CHECK (type IN ('offer_ride', 'share_rental', 'self_arranged'));

CREATE TABLE transport_offer_joins (
    offer_id UUID NOT NULL REFERENCES trip_transport_offers (id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (offer_id, user_id)
);
