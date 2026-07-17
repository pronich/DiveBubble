-- Business sign-up on admin/ is deliberately not open yet (per go-to-market sequencing —
-- see CLAUDE.md's Product context: individual app launches first). The public marketing
-- site's "Dive in" button collects an optional email here instead of linking straight to
-- admin's login.
CREATE TABLE waitlist_signups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
