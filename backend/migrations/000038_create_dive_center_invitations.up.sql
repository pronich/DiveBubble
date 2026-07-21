-- Pending staff invitations for people who don't have a DiveBubble account yet — no
-- invite-specific token, matched purely by email against whatever the invitee's next
-- successful sign-in resolves to (see internal/divecenter.Service.AcceptInvitations).
CREATE TABLE dive_center_invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dive_center_id UUID NOT NULL REFERENCES dive_centers(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'staff' CHECK (role IN ('owner', 'staff')),
    invited_by_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    accepted_at TIMESTAMPTZ,
    CONSTRAINT uq_dive_center_invitations_center_email UNIQUE (dive_center_id, email)
);

CREATE INDEX idx_dive_center_invitations_email ON dive_center_invitations (email) WHERE accepted_at IS NULL;
