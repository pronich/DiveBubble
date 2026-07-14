ALTER TABLE users ADD COLUMN account_type TEXT NOT NULL DEFAULT 'individual'
    CHECK (account_type IN ('individual', 'dive_center'));
