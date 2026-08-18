DROP INDEX IF EXISTS idx_chat_messages_trip_attachment;

ALTER TABLE chat_messages DROP CONSTRAINT chat_messages_body_or_attachment_check;
ALTER TABLE chat_messages DROP CONSTRAINT chat_messages_attachment_consistency_check;
ALTER TABLE chat_messages DROP CONSTRAINT chat_messages_attachment_type_check;

ALTER TABLE chat_messages DROP COLUMN attachment_size_bytes;
ALTER TABLE chat_messages DROP COLUMN attachment_filename;
ALTER TABLE chat_messages DROP COLUMN attachment_type;
ALTER TABLE chat_messages DROP COLUMN attachment_url;
