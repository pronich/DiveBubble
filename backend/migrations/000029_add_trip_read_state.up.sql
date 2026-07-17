-- Fallback read-marker for callers with no trip_participants row (dive-center staff — see
-- trip.Service.CreateTrip, staff never get one). Without this, MarkRead's UPDATE on
-- trip_participants was a silent no-op for staff, so their unreadCount always fell back to
-- '-infinity' and could never clear.
CREATE TABLE trip_read_state (
    trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    last_read_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (trip_id, user_id)
);
