ALTER TABLE auth_sessions DROP CONSTRAINT auth_sessions_provider_check;
ALTER TABLE auth_sessions ADD CONSTRAINT auth_sessions_provider_check
    CHECK (provider = ANY (ARRAY['google'::text, 'apple'::text]));

ALTER TABLE auth_identities DROP CONSTRAINT auth_identities_provider_check;
ALTER TABLE auth_identities ADD CONSTRAINT auth_identities_provider_check
    CHECK (provider = ANY (ARRAY['google'::text, 'apple'::text]));
