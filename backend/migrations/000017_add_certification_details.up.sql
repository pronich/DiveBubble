ALTER TABLE users
    ADD COLUMN certification_agency TEXT,
    ADD COLUMN certification_number TEXT,
    ADD COLUMN certification_photo_url TEXT,
    ADD COLUMN certification_verified BOOLEAN NOT NULL DEFAULT false;
