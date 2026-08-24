-- One reaction per user per message (Messenger semantics) — picking a new emoji replaces the
-- old one, picking the same one again removes it (both are client-side choices of which
-- endpoint to call; see routes_message.go's reaction handlers). PRIMARY KEY enforces the "one
-- per user" part directly, no separate unique index needed.
CREATE TABLE chat_message_reactions (
    message_id UUID NOT NULL REFERENCES chat_messages (id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    emoji text NOT NULL CHECK (emoji IN ('❤️', '😅', '😁', '🙃', '😢', '😮', '😡', '👌')),
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (message_id, user_id)
);
