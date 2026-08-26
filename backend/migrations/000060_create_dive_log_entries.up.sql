-- Personal dive log, independent of the diver's self-reported profiles.dive_count (see
-- CLAUDE.md) — this is a supplementary feature, not a replacement, so the two numbers are
-- summed in the app rather than reconciled here.
CREATE TABLE dive_log_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    trip_id UUID REFERENCES trips (id) ON DELETE SET NULL,
    source TEXT NOT NULL, -- 'manual' | 'imported'
    dived_at TIMESTAMPTZ NOT NULL,
    max_depth_m NUMERIC,
    duration_minutes INTEGER,
    min_temperature_c NUMERIC,
    site_name TEXT,
    latitude NUMERIC,
    longitude NUMERIC,
    notes TEXT,
    -- Array of {offsetSeconds, depthM, temperatureC} samples for the depth/temperature
    -- graph — only ever populated for source = 'imported' (see the app's own gating on
    -- source, not on this being non-null, since a manual entry never has this by definition).
    profile_samples JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX dive_log_entries_user_id_dived_at_idx ON dive_log_entries (user_id, dived_at DESC);

-- Dedup key for re-imports of the same (or a superset) UDDF export — silently skips a dive
-- already logged for this diver at this exact timestamp rather than creating a duplicate.
CREATE UNIQUE INDEX dive_log_entries_user_id_dived_at_uidx ON dive_log_entries (user_id, dived_at);
