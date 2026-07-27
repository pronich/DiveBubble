-- Scopes a message to a single buddy group's own chat, same shape as offer_id for car chat.
ALTER TABLE chat_messages ADD COLUMN buddy_request_id UUID REFERENCES trip_buddy_requests (id) ON DELETE CASCADE;

ALTER TABLE chat_messages DROP CONSTRAINT chat_messages_kind_check;
ALTER TABLE chat_messages ADD CONSTRAINT chat_messages_kind_check
    CHECK (kind IN ('user', 'feedback_prompt', 'car_joined', 'buddy_joined'));

-- A message belongs to at most one non-main-chat scope — cheap integrity guard now that
-- there are two parallel nullable scope columns instead of one.
ALTER TABLE chat_messages ADD CONSTRAINT chat_messages_single_scope_check
    CHECK (offer_id IS NULL OR buddy_request_id IS NULL);

CREATE INDEX idx_chat_messages_buddy_created ON chat_messages (buddy_request_id, created_at) WHERE buddy_request_id IS NOT NULL;
