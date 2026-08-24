-- A message can now carry several attachments (up to 9, mixed photo/video) instead of the one
-- the chat_messages.attachment_* columns support. Those columns stay untouched (old messages
-- keep rendering from them); new multi-attachment sends populate this table instead — see
-- toMessageResponse for how the two are normalized into one list for the API response.
CREATE TABLE chat_message_attachments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID NOT NULL REFERENCES chat_messages (id) ON DELETE CASCADE,
    position smallint NOT NULL,
    url text NOT NULL,
    type text NOT NULL CHECK (type IN ('image', 'video', 'pdf')),
    filename text,
    size_bytes integer,
    duration_seconds integer, -- video only
    UNIQUE (message_id, position)
);

CREATE INDEX idx_chat_message_attachments_message ON chat_message_attachments (message_id);

-- New sends with attachments now go through chat_message_attachments instead of the legacy
-- chat_messages.attachment_url column, so this CHECK (body or that one column) would wrongly
-- reject a valid attachment-only multi-attachment message — a CHECK can't reference another
-- table, so this moves to application-level validation instead (message.Service.Send).
ALTER TABLE chat_messages DROP CONSTRAINT chat_messages_body_or_attachment_check;
