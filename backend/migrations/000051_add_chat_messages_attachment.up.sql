-- Lets a chat message carry an uploaded file (photo or PDF) alongside/instead of body text.
-- All four columns are set together or not at all (see the consistency check below).
ALTER TABLE chat_messages ADD COLUMN attachment_url text;
ALTER TABLE chat_messages ADD COLUMN attachment_type text;         -- 'image' | 'pdf'
ALTER TABLE chat_messages ADD COLUMN attachment_filename text;
ALTER TABLE chat_messages ADD COLUMN attachment_size_bytes integer;

ALTER TABLE chat_messages ADD CONSTRAINT chat_messages_attachment_type_check
    CHECK (attachment_type IS NULL OR attachment_type IN ('image', 'pdf'));

ALTER TABLE chat_messages ADD CONSTRAINT chat_messages_attachment_consistency_check
    CHECK ((attachment_url IS NULL) = (attachment_type IS NULL));

-- A message must carry a caption or an attachment (or both) — never neither.
ALTER TABLE chat_messages ADD CONSTRAINT chat_messages_body_or_attachment_check
    CHECK (btrim(body) <> '' OR attachment_url IS NOT NULL);

-- Backs the Media/Files tabs (main trip chat only, filtered by type).
CREATE INDEX idx_chat_messages_trip_attachment ON chat_messages (trip_id, attachment_type, created_at)
    WHERE offer_id IS NULL AND buddy_request_id IS NULL AND attachment_type IS NOT NULL;
