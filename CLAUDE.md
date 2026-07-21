# DiveBubble

Platform for dive trips — organized by dive centers or by local divers. A joined trip is its
own chat ("Bubble") for coordinating the dive, transport, and logistics. "Trip" is the plain
noun used while browsing/creating; "Bubble" is what a trip becomes once you've joined it (chat
+ transport) — a deliberate two-tier naming split, not an inconsistency to unify.

Monetization: free at launch, no pricing UI yet (see Deferred).

## Git Rules

- Final branch: **`develop`**
- New work on a feature branch off `develop`; merge locally into `develop` (no PR), then push
  `develop`.
- Commit messages: short (e.g. "Added design system"), no multi-paragraph bodies.
- Code comments: one line max.

## Stack

| Layer | Tech |
|---|---|
| App (mobile + web) | Flutter — single codebase, `app/` |
| Admin (dive centers, web-only) | Flutter, `admin/` — separate project, no shared code with `app/` yet |
| Backend | Go + PostgreSQL, `backend/` |
| Chat | REST for persistence; realtime via self-hosted **Centrifugo v5** |
| Public site | Next.js (App Router) + TypeScript + Tailwind, `public/` |
| Deploy | Backend: DigitalOcean droplet, Docker Compose, shared nginx (`api.divebubble.io`). Admin + public: Vercel (`admin.divebubble.io`, `divebubble.io`) |

## Repo structure

```
app/        # Flutter app — Explore/Bubbles/Profile bottom nav
admin/      # Flutter web admin panel for dive centers
backend/    # Go API — trips, chat, transport, auth, push (Postgres-backed)
public/     # Next.js marketing site
```

## Build & Development

### Backend (`backend/`)

```bash
make dev              # go run .
make dev-build         # compile to ./bin/app
make dev-run           # build + run in background, logs to ./bin/app.log
make dev-stop
make compose-up        # postgres + migrate + centrifugo (docker compose)
make migrate-up         # apply migrations (requires golang-migrate CLI)
```

Local server: `http://localhost:8080`. Requires `.env` (copy `.env.example`) — `DATABASE_URL`
at minimum; everything else optional with dev-safe defaults.

**Production deploy**: SSH to the droplet, `git pull`, then
`docker compose -f docker-compose.prod.yml --env-file .env up -d --build`. `.env` on the
droplet holds every prod secret (`${VAR:?...}` in `docker-compose.prod.yml` fails loudly if
one's missing). See `backend/SECRETS_ROTATION.md` (gitignored) if rotating credentials.

### App / Admin (`app/`, `admin/`)

```bash
flutter run                                                  # local dev, defaults to localhost:8080
flutter run --dart-define=API_BASE_URL=http://<lan-ip>:8080  # physical device on same Wi-Fi
dart run build_runner build --delete-conflicting-outputs      # after editing @freezed/fromJson models
```

A `--release` build (App Store archive, or admin's Vercel build) defaults to the real
production API instead of localhost — see `_apiBaseUrl`/`_centrifugoWsUrl` in `main.dart`
(`kReleaseMode`-gated). Generated `*.freezed.dart`/`*.g.dart` files are committed, not
gitignored.

### Public site (`public/`)

```bash
npm run dev     # localhost:3000, fully static, no backend dependency
```

## Backend packages (`backend/internal/`)

| Package | Responsibility |
|---|---|
| `server` | HTTP router, handlers, `withAuth`/`optionalAuth` bearer middleware |
| `auth` | Google/Apple/email sign-in, JWT access tokens, refresh-session rotation |
| `account` | Account deletion (anonymize) — see Implemented |
| `trip` | Trip CRUD, join/leave/cancel, organizer/access checks (incl. dive-center staff) |
| `message` | Chat messages |
| `transport` | Transport offers (offer_ride / share_rental) |
| `profile` | Self-reported diver profile fields |
| `certification` | Specialty certifications |
| `gear` | Gear locker |
| `divecenter` | Dive centers + membership (owner/staff) |
| `realtime` | Centrifugo publisher + connection-token issuer |
| `push` | FCM push notifications |
| `upload` | Image storage (local disk dev, DigitalOcean Spaces prod) |
| `waitlist` | Public-site "notify me" signups |

## App layers (`app/lib/`, mirrored in `admin/lib/`)

MVVM: `domain/entities/` → `data/models/` (freezed + json_serializable) → `data/mappers/` →
`data/services/` (HTTP, `Authorization: Bearer` via injected token provider) →
`data/repositories/` → `ui/features/*/view_models/` (ChangeNotifier) + `ui/features/*/views/`.
DI is manual, wired in `main.dart`. Follows the `flutter-mvvm-architecture` skill.

## Design system (`app/lib/ui/core/theme/`)

Material 3, tokens transcribed from Figma (`app_colors.dart`, `app_gradients.dart`,
`semantic_colors.dart`, `app_text_theme.dart` → assembled in `app_theme.dart`). Fraunces
(serif, display/headline) + Inter (grotesk, body/label). Light theme only — no dark variant
until Figma defines one.

## Implemented

- **Auth**: Google, Apple (incl. token revocation on account deletion — App Store Guideline
  5.1.1(v)), and passwordless email (OTP in `app/`, magic link in `admin/`) — all three link
  onto one account when they share an email. JWT access + rotating refresh sessions. Welcome
  email on first-ever sign-in, any provider.
- **Account deletion**: anonymizes the user (not a hard delete — other participants keep
  seeing "Deleted user" in shared history), cancels their individual trips, hard-deletes
  private data (specialties, gear, dive-center memberships, sessions).
- **Discovery**: Explore list, search/create/join quick actions, trip cards.
- **Trip lifecycle**: create (individual + business), edit, join, leave, cancel; multi-photo
  gallery (add/remove, no reorder yet).
- **Bubbles**: per-trip chat (Centrifugo realtime, clustering, unread badges, read state),
  transport offers (join, one-booking-per-trip, dissolve alerts), read-only mode on cancelled
  trips.
- **Profile**: overview, certifications (level + specialties), gear locker, photo uploads,
  public profile view / diver ID card.
- **Notifications**: in-app unread/mention badges, @mention-the-dive-center (staff push
  gating), push notifications (new message, trip cancelled/changed, transport events).
- **Dive centers**: entity + membership (owner/staff), business trip creation, staff
  management (add by exact email, remove), booking-code flow (dive centers aren't joined
  directly — a code proves an external booking), dive-center card for divers.
- **Admin panel** (`admin/`): shell (Trips/Users/Bubbles/Company), Google Sign-In (web-specific
  flow), realtime Bubbles with Chat/Transport tabs, company profile editing.
- **Public site** (`public/`): individual + business landing pages, FAQ, privacy/terms
  (externally drafted, GDPR-aware), waitlist signup.
- **Deploy**: backend on a DigitalOcean droplet (Docker Compose, shared nginx), admin + public
  on Vercel, migrations run automatically on deploy.

## Deferred

- Logbook (personal dive log across trips), per-trip Dives sub-tab
- Splitwise-style expense splitting
- Share trip (deep linking — no domain/routing infra for it yet beyond what exists)
- Drag-to-reorder trip photos
- Per-Bubble mute, notification category toggles
- Realtime for transport offers (currently reload-on-tab-switch)
- Recurring-trip data model
- Commission/markup on top of `price_minor`
- Dive-center ownership transfer / archive
- Email invitation for staff without an existing account (current flow requires one)
- Personal profile editing in `admin/` (stub)
- Last-message preview in Bubbles inbox
- Dark theme
- Android emulator base URL (`10.0.2.2`) — untested, not yet needed
