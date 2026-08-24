-- Lets a chat message reply to another one in the same trip's chat. ON DELETE SET NULL, not
-- CASCADE — a message is soft-deleted (see migration 000053), never hard-deleted, so this only
-- ever fires if a row is removed some other way; still the safer default.
ALTER TABLE chat_messages ADD COLUMN reply_to_id uuid REFERENCES chat_messages(id) ON DELETE SET NULL;

CREATE INDEX idx_chat_messages_reply_to ON chat_messages (reply_to_id) WHERE reply_to_id IS NOT NULL;
