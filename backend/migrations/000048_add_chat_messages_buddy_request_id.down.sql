DROP INDEX IF EXISTS idx_chat_messages_buddy_created;

ALTER TABLE chat_messages DROP CONSTRAINT chat_messages_single_scope_check;

ALTER TABLE chat_messages DROP CONSTRAINT chat_messages_kind_check;
ALTER TABLE chat_messages ADD CONSTRAINT chat_messages_kind_check
    CHECK (kind IN ('user', 'feedback_prompt', 'car_joined'));

ALTER TABLE chat_messages DROP COLUMN buddy_request_id;
