# DiveBubble

Platform for dive trips — organized by dive centers or by local divers. A joined trip is its
own chat ("Bubble") for coordinating the dive, transport, and logistics.

## Features

- Browse open trips, join one, or create your own
- Per-trip chat with realtime delivery, plus a transport board (offer/find a ride)
- Diver profiles: certifications, specialties, gear locker
- Dive-center admin panel: publish trips, manage staff, booking codes
- Push notifications (new messages, trip changes, transport alerts)
- Sign in with Google, Apple, or passwordless email

## Stack

- **App** (iOS/Android/Web): Flutter
- **Admin** (dive centers, web-only): Flutter
- **Backend**: Go + PostgreSQL
- **Realtime chat**: Centrifugo
- **Public site**: Next.js
- **Deploy**: DigitalOcean (backend), Vercel (admin + public site)

## Repo structure

```
app/        # Flutter app — diver-facing
admin/      # Flutter web — dive-center admin panel
backend/    # Go API
public/     # Next.js marketing site
```

## Running locally

```bash
cd backend && make compose-up && make dev-run   # API on localhost:8080
cd app && flutter run                            # or admin/, same command
cd public && npm run dev                          # localhost:3000
```

See `CLAUDE.md` for full setup, architecture, and conventions.

## Deployment

Backend runs on a DigitalOcean droplet via Docker Compose (`api.divebubble.io`). Admin and the
public site deploy to Vercel (`admin.divebubble.io`, `divebubble.io`).
