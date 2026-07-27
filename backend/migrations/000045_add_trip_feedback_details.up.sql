-- helped_with: comma-separated free labels from a fixed client-side checklist (same
-- "avoid array-scanning" convention as users.languages) — e.g. "Trip information, Finding
-- transport". contact_ok: diver opted in to be contacted about their feedback.
ALTER TABLE trip_feedback ADD COLUMN helped_with TEXT NOT NULL DEFAULT '';
ALTER TABLE trip_feedback ADD COLUMN contact_ok BOOLEAN NOT NULL DEFAULT false;
