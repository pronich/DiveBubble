ALTER TABLE trips
    ADD COLUMN end_date DATE,
    ADD COLUMN description TEXT,
    ADD COLUMN meeting_point TEXT,
    ADD COLUMN dive_count_min INT,
    ADD COLUMN dive_count_max INT,
    ADD COLUMN depth_min_m INT,
    ADD COLUMN depth_max_m INT,
    ADD COLUMN min_certification TEXT,
    ADD COLUMN booking_code TEXT,
    ADD COLUMN max_participants INT,
    ADD COLUMN booking_status TEXT NOT NULL DEFAULT 'open'
        CHECK (booking_status IN ('open', 'full', 'cancelled')),
    ADD CONSTRAINT dive_count_range CHECK (dive_count_min IS NULL OR dive_count_max IS NULL OR dive_count_max >= dive_count_min),
    ADD CONSTRAINT depth_range CHECK (depth_min_m IS NULL OR depth_max_m IS NULL OR depth_max_m >= depth_min_m),
    ADD CONSTRAINT max_participants_positive CHECK (max_participants IS NULL OR max_participants > 0);
