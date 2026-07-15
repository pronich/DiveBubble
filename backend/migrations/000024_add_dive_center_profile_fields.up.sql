ALTER TABLE dive_centers
    ADD COLUMN location TEXT,
    ADD COLUMN description TEXT,
    ADD COLUMN logo_url TEXT,
    -- Agency affiliation (PADI/SSI/NAUI/CMAS/Other) is the single biggest trust signal in
    -- diving, arguably more than the description — same agency+freeform-detail shape as the
    -- individual Level card ("PADI" + "5 Star Dive Center"), not a DB enum (same reasoning
    -- as certification_level: validated client-side against a canonical list, not here).
    ADD COLUMN agency TEXT,
    ADD COLUMN agency_detail TEXT,
    -- Comma-separated, matching users.languages exactly (same free-text-not-array reasoning).
    ADD COLUMN languages TEXT NOT NULL DEFAULT '',
    ADD COLUMN website TEXT,
    ADD COLUMN phone TEXT;
