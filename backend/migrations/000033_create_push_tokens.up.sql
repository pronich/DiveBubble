-- One row per device install. Primary key on the token itself (not user_id, token) so
-- re-registering an already-known token (e.g. a different account signing into the same
-- device) reassigns it via ON CONFLICT rather than leaving a stale row pointed at the old user.
CREATE TABLE push_tokens (
    token TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    platform TEXT NOT NULL DEFAULT 'ios' CHECK (platform IN ('ios', 'android', 'web')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_push_tokens_user_id ON push_tokens (user_id);
