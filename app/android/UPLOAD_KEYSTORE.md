# Android upload keystore

Generated 2026-07-22, self-signed, 10000-day validity.

- Keystore file: `~/divebubble-keys/divebubble-upload.jks` (outside the repo, never committed)
- Alias: `divebubble-upload`
- `android/key.properties` (gitignored) points `build.gradle.kts` at the file above and holds
  the store/key password — same value for both (PKCS12 keystores don't support separate
  store/key passwords).

**Back up `~/divebubble-keys/divebubble-upload.jks` and `android/key.properties` somewhere
durable (password manager / encrypted drive) — losing them blocks publishing app updates.**
Google Play Console can reset an upload key if truly lost (Play App Signing keeps the real
signing key separately), but that's a manual support request and a delay — avoid it by keeping
a backup.

To get the SHA-1/SHA-256 fingerprint (needed for Firebase/Google Cloud OAuth client setup):

```bash
keytool -list -v -keystore ~/divebubble-keys/divebubble-upload.jks -alias divebubble-upload
```
