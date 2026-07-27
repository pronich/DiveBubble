-- Scopes a message to a single car offer's chat instead of the whole trip's main chat.
-- Nullable: NULL means "main trip chat" (unchanged behavior), set means "this offer's chat".
-- trip_id stays populated either way so trip-wide queries (moderation, unread) keep working.
ALTER TABLE chat_messages ADD COLUMN offer_id UUID REFERENCES trip_transport_offers (id) ON DELETE CASCADE;

ALTER TABLE chat_messages DROP CONSTRAINT chat_messages_kind_check;
ALTER TABLE chat_messages ADD CONSTRAINT chat_messages_kind_check
    CHECK (kind IN ('user', 'feedback_prompt', 'car_joined'));

CREATE INDEX idx_chat_messages_offer_created ON chat_messages (offer_id, created_at) WHERE offer_id IS NOT NULL;
