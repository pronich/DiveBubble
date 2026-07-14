ALTER TABLE users ADD COLUMN display_name TEXT;
ALTER TABLE users ADD COLUMN avatar_url TEXT;
ALTER TABLE users ADD COLUMN location TEXT;
ALTER TABLE users ADD COLUMN dive_count INT NOT NULL DEFAULT 0;
ALTER TABLE users ADD COLUMN certification_level TEXT;
-- Comma-separated rather than a real Postgres array — avoids needing array-scanning support
-- in the database/sql driver for what's just a short, freeform list ("English, Russian").
ALTER TABLE users ADD COLUMN languages TEXT NOT NULL DEFAULT '';
