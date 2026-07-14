ALTER TABLE trip_transport_offers DROP CONSTRAINT trip_transport_offers_type_check;
ALTER TABLE trip_transport_offers ADD CONSTRAINT trip_transport_offers_type_check
    CHECK (type IN ('offer_ride', 'share_rental', 'self_arranged'));
