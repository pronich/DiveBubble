# DiveBubble

Marketplace for dive trips — short and long, organized by dive centers or by local divers.

## MVP scope

- List of open trips
- Trip detail + join flow
- Trip chat (transport coordination included)
- Diver profile with self-reported certifications (no verification yet)

## Stack

- **App**: Flutter (iOS, Android, Web — mobile-first design, single codebase)
- **Backend**: Go + PostgreSQL
- **Deploy**: DigitalOcean
- **Chat**: managed WebSocket library (no custom chat infra)

See `CLAUDE.md` for workspace conventions and architecture notes.
