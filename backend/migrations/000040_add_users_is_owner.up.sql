-- Platform-level flag (distinct from dive_center_members.role, which is scoped to a single
-- center) for accounts that should see test/demo content hidden from regular users.
ALTER TABLE users ADD COLUMN is_owner BOOLEAN NOT NULL DEFAULT false;
