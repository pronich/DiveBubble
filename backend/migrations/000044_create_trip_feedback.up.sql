-- One submission per participant per trip, prompted by the post-trip feedback system message.
-- No edit/resubmit support: submitting again is a silent no-op (see trip.Repository.SubmitFeedback).
CREATE TABLE trip_feedback (
    trip_id UUID NOT NULL REFERENCES trips (id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    rating SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (trip_id, user_id)
);
