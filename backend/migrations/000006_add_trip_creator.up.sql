ALTER TABLE trips ADD COLUMN creator_user_id UUID REFERENCES users (id);
