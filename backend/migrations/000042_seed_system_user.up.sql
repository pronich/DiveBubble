-- Sentinel account used as the sender of system-generated chat messages (e.g. the post-trip
-- feedback prompt). A real users row keeps every chat_messages FK valid and unread-count SQL
-- (which keys off user_id != viewer) working with no special-casing.
INSERT INTO users (id, display_name) VALUES
    ('00000000-0000-0000-0000-000000000001', 'DiveBubble')
ON CONFLICT (id) DO NOTHING;
