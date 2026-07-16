-- A public contact email distinct from the owner's own login email — the login email is
-- personal and tied to whichever staff member happens to be the owner; this is the address
-- divers see on the company profile (matches phone/website's same public-contact purpose).
ALTER TABLE dive_centers ADD COLUMN email TEXT;
