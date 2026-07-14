-- self_arranged carried no useful data (no join, no seats) — dropping the rows, not migrating them.
DELETE FROM trip_transport_offers WHERE type = 'self_arranged';

ALTER TABLE trip_transport_offers DROP CONSTRAINT trip_transport_offers_type_check;
ALTER TABLE trip_transport_offers ADD CONSTRAINT trip_transport_offers_type_check
    CHECK (type IN ('offer_ride', 'share_rental'));
