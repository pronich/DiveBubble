-- Stores the Apple-issued refresh token from AppleTokenClient.Exchange (native Sign in with
-- Apple authorizationCode exchange), so DeleteAccount has something to revoke with Apple's
-- /auth/revoke endpoint (App Store Review Guideline 5.1.1(v)). Only ever set for provider = 'apple'.
ALTER TABLE auth_identities ADD COLUMN apple_refresh_token TEXT;
