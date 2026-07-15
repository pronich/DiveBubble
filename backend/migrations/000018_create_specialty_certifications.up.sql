CREATE TABLE specialty_certifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    specialty TEXT NOT NULL,
    custom_label TEXT,
    agency TEXT,
    cert_number TEXT,
    photo_url TEXT,
    verified BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_specialty_certifications_user_id ON specialty_certifications (user_id);
