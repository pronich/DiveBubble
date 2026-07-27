DROP INDEX IF EXISTS idx_chat_messages_offer_created;

ALTER TABLE chat_messages DROP CONSTRAINT chat_messages_kind_check;
ALTER TABLE chat_messages ADD CONSTRAINT chat_messages_kind_check
    CHECK (kind IN ('user', 'feedback_prompt'));

ALTER TABLE chat_messages DROP COLUMN offer_id;
