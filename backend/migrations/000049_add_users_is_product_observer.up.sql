-- Platform-level flag for the founder's account when observing real trips as a transparent,
-- non-diving, non-dive-center-affiliated guest (distinct from is_owner's test/demo visibility).
ALTER TABLE users ADD COLUMN is_product_observer BOOLEAN NOT NULL DEFAULT false;
