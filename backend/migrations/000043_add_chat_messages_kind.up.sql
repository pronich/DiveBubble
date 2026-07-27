-- Discriminates real user messages from system-generated ones (e.g. post-trip feedback
-- prompt). New kinds get added here as more system messages ship (car/buddy join, etc).
ALTER TABLE chat_messages ADD COLUMN kind TEXT NOT NULL DEFAULT 'user'
    CHECK (kind IN ('user', 'feedback_prompt'));
