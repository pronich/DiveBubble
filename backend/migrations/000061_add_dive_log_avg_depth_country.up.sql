-- avg_depth_m: only ever set by an importer that actually knows it (SQLite's own DepthAvg
-- column, or computed from UDDF waypoint depths) — never entered by hand, so there's no
-- manual-entry UI for it.
ALTER TABLE dive_log_entries ADD COLUMN avg_depth_m NUMERIC;
-- country: separate from site_name so the list can show "{country} - {site}" — editable
-- for both manual and imported entries, same as site_name.
ALTER TABLE dive_log_entries ADD COLUMN country TEXT;
