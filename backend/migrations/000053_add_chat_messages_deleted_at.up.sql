-- Soft-delete for chat messages — the row stays (so anything replying to it via reply_to_id
-- still resolves), Body/Attachment* just get blanked server-side once this is set (see
-- message.Repository.SoftDelete / routes_message.go's toMessageResponse).
ALTER TABLE chat_messages ADD COLUMN deleted_at timestamptz;
