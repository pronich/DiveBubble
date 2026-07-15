ALTER TABLE trips
    ADD COLUMN dive_center_id UUID REFERENCES dive_centers (id) ON DELETE SET NULL,
    -- Minor units (øre, matching DKK) to avoid float rounding — a future commission markup
    -- (see CLAUDE.md's Monetization section) will need exact arithmetic on this.
    ADD COLUMN price_minor INT CHECK (price_minor IS NULL OR price_minor >= 0),
    ADD COLUMN currency TEXT NOT NULL DEFAULT 'DKK';

CREATE INDEX idx_trips_dive_center_id ON trips (dive_center_id) WHERE dive_center_id IS NOT NULL;
