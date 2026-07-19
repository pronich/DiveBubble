-- Per-user, per-trip mute for the "new message" push only — trip cancelled/updated and
-- transport-alert pushes stay unmutable (see notify.go), same as a muted chat app still
-- surfacing an actually-important system alert.
CREATE TABLE trip_mutes (
    trip_id UUID NOT NULL REFERENCES trips (id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (trip_id, user_id)
);
