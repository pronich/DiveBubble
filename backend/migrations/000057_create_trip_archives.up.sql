-- Per-user, per-trip archive — same shape as trip_mutes. Purely a "hide from the default
-- Bubbles list" flag: archiving never affects other participants, and an archived trip still
-- fully works (messages, unread count) if opened directly from the Archive.
CREATE TABLE trip_archives (
    trip_id UUID NOT NULL REFERENCES trips (id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (trip_id, user_id)
);
