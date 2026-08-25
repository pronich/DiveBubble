-- The date the expense actually happened, distinct from created_at (when the record was
-- entered) — lets a diver log a purchase from a day or two ago without it looking like it
-- happened "now". Defaults to today so existing rows and quick-adds both get a sane value.
ALTER TABLE trip_expenses ADD COLUMN occurred_at DATE NOT NULL DEFAULT CURRENT_DATE;
