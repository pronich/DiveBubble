-- Marks when an account was anonymized via DELETE /me (internal/account). The users row
-- itself is never deleted (keeps every FK — trip_participants, chat_messages, trips.creator_user_id,
-- etc. — valid with zero cascade complexity); this column is just an audit/debug marker.
ALTER TABLE users ADD COLUMN deleted_at TIMESTAMPTZ;
