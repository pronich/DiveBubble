CREATE TABLE dive_centers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- One row per (dive_center, user) — a user with no row here has no relationship to that
-- center at all. 'owner' created the center (there's always at least one); 'staff' can be
-- added/removed by an owner. No per-permission granularity yet — see CLAUDE.md's
-- Business/dive-center section for why that's deliberately deferred past this foundation.
CREATE TABLE dive_center_members (
    dive_center_id UUID NOT NULL REFERENCES dive_centers (id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'staff' CHECK (role IN ('owner', 'staff')),
    joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (dive_center_id, user_id)
);

CREATE INDEX idx_dive_center_members_user_id ON dive_center_members (user_id);
