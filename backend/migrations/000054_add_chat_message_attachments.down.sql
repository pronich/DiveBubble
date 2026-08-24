ALTER TABLE chat_messages ADD CONSTRAINT chat_messages_body_or_attachment_check
    CHECK (btrim(body) <> '' OR attachment_url IS NOT NULL);

DROP TABLE IF EXISTS chat_message_attachments;
