# DiveBuddy

Marketplace for dive trips (short and long), organized by dive centers or by local divers. Single monorepo for app + backend.

## Product context

Core problems being solved (independent, not sequential):
1. **Local coordination** — ad-hoc trips (e.g. evening dives with a dive center) need a way to split transport costs / offer rides among participants.
2. **Local search when traveling** — dive centers abroad run rigid schedules; a self-organized trip with local divers is often the only way to dive off-schedule.
3. **Discovery friction** — checking every dive center's site/schedule individually is slow; trips from dive centers and individuals should be searchable in one place, filterable by location and time.

MVP scope (deliberately small — logbook and dive-center self-service publishing are later phases, not v1):
- List of open trips
- Trip detail + join flow
- Trip chat (transport coordination lives here, not a separate feature)
- Diver profile with self-reported certifications (no verification API yet — planned for later)

Go-to-market: start by running trips personally (partnering with dive center **KingFish** for promotion) rather than waiting for a two-sided marketplace to bootstrap itself. Once there's an active user base, invite KingFish (then other dive centers) to publish their own trips directly.

**Monetization**: free for everyone at launch — deliberately not pricing anything yet, positioning as a platform, not a marketplace taking a cut. Later phase: dive centers add a price to their trips so divers see cost upfront; further out, an Airbnb-style ~10% markup on top of the dive center's price. No pricing UI/fields until this is revisited.

## Feature backlog (full scope, not yet built)

Everything below is the full feature breakdown discussed for later phases — MVP intentionally implements a subset (see Product context above), enriched incrementally. Keep this section in sync if scope discussions change it; don't infer it from code, since none of it exists yet.

- **Auth & onboarding**: real Login via Apple + Google (replacing stub `X-User-Id`). Minimal onboarding: splash screen → login screen, skippable (browse before signing in).
- **Discovery card fields**: photo (or placeholder), date, location, title — filtered by proximity to user.
- **Trip Page → Overview** (full field set, MVP only has title/location/startTime/joined so far): creator identity (dive center name or person), where, when, requirements (optional), extra description, what's included, required equipment list, booking status, meeting point, useful links.
- **Trip Page → Chat**: participants list with avatars, pinned messages (tbd if needed). Tapping the chat header opens **Group info**: participants, organizer, rules (tbd), shared media (tbd), leave group, report.
- **Trip Page → Transport board**: Offer a ride / Find a ride / Share a rental / I'll get there myself.
- **Trip Page → Dives** (deferred): per-trip dive log, shareable with other participants.
- **Trips tab**: also covers past trips (history), not just upcoming — current build only handles joined+active.
- **Logbook** (deferred, separate from per-trip Dives): personal dive log across all trips.
- **Profile tab**: diver profile (photo, display name, city, languages, short bio, dive count), certifications, gear locker, dive statistics, connected services, settings.
- **Actions**: create trip, join trip, join a pre-booked trip via code (e.g. a dive center's own booking system like Drive&Dive), create transport offer, update profile, add certificates, add gear.
- **Web**: diver-facing web is the same Flutter codebase (already builds to web). Dive-center admin is a separate panel for centers to publish their own trips manually; CMS integration is a later idea so centers don't have to enter trips by hand.

## Navigation / IA

Bottom nav (v1): **Explore — Trips — Profile**. Key decision: **a joined trip *is* its chat** — no separate chat entity. "Explore" is the discovery list (all open trips); "Trips" lists only trips the current user has joined, ordered by conversation activity, and each row opens directly into that trip's chat. Tapping the chat header from there opens the same Trip Page (Overview/Transport/Dives tabs) — one shared screen/route, not a separate "joined trip" view, so the marketplace framing (a trip is always a trip, joined or not) doesn't get buried under a messaging mental model. `Trips` tab and its empty state are deferred until join (step 6) exists.

Build order being followed: Discovery list (done) → Trip Page detail (done) → stub auth + join (done) → Trips tab (= chats) + chat screen (done) → realtime via Centrifugo (done) → real Apple/Google auth → transport board → richer Discovery/profile fields. Logbook, Dives sub-tab, and the dive-center web admin are explicitly deferred past all of this.

## Stack

| Layer | Tech |
|---|---|
| App (mobile + web) | Flutter — single codebase, mobile-first design, builds to iOS/Android/Web |
| Admin (future, for dive centers) | Flutter, same codebase family |
| Backend | Go, PostgreSQL |
| Chat | REST for persistence; realtime delivery via **Centrifugo** (self-hosted, open-source pub/sub) |
| Deploy | DigitalOcean |

## Repo structure

```
DiveBuddy/
  app/        # Flutter app — Explore/Trips/Profile bottom nav, chat, MVVM, verified on iOS simulator
  admin/      # Flutter admin panel for dive centers (future phase)
  backend/    # Go API — trips, join, chat messages (Postgres-backed)
```

## Build & Development

### Backend (`backend/`)

```bash
make dev              # go run . — hot-reload not included, restart manually
make dev-build        # compile to ./bin/app
make dev-run          # build + run in background, logs to ./bin/app.log
make dev-stop         # stop background process
make dev-logs         # tail ./bin/app.log
```

Local server runs on `http://localhost:8080` by default (`PORT` env var overrides). Requires `DATABASE_URL` (see `.env.example` → copy to `.env`).

#### Docker Compose (Postgres + migrations)

```bash
make compose-up       # starts postgres, applies migrations automatically
make compose-down
make compose-logs
```

Postgres is exposed on `127.0.0.1:5433` for local `make dev`/`make dev-run`.

#### Database Migrations

Requires `golang-migrate` CLI (`brew install golang-migrate`). `DATABASE_URL` must be set in `.env`.

```bash
make migrate-up       # apply all pending migrations
make migrate-down     # roll back one migration
```

Migrations live in `backend/migrations/`. In compose mode, the `migrate` service runs automatically before you'd run the API.

#### Centrifugo (realtime chat)

Runs as a compose service (`centrifugo/centrifugo:v5`) on `127.0.0.1:8000`, config at `backend/centrifugo/config.json` (non-secret: just the `trip` namespace with `allow_subscribe_for_client: true`, so any authenticated connection can subscribe to any `trip:*` channel — fine since trip chat isn't sensitive across participants; tighten later with a subscribe proxy if needed). Secrets (`CENTRIFUGO_API_KEY`, `CENTRIFUGO_TOKEN_SECRET`) come from `.env`, same values the Go backend uses to publish/mint tokens.

**v5 vs v6 config gotcha (already hit once)**: most current Centrifugo docs describe v6's nested config schema (e.g. `channel.namespaces`, `http_api_key`). This project pins **v5** (`centrifugo/centrifugo:v5`), which uses a flatter schema: top-level `namespaces` array, and `api_key` (not `http_api_key`) for the HTTP API key env var. Check Centrifugo's version-tagged source (`internal/config` / `main.go` in the matching git tag) rather than trusting the latest docs if something's rejected as an "unknown key" — Centrifugo logs those at startup (`docker compose logs centrifugo`), which is how this got caught.

### Stub auth

No real auth yet — every route except `GET /trips` and `GET /health` requires an `X-User-Id: <uuid>` header (`withUser` middleware; 401 if missing/invalid). The server upserts a `users` row for that id on first sight (`user.Service.GetOrCreate`). The client generates and persists this id locally (see `UserIdentityService` below) — swap for a real JWT-derived user id once Apple/Google Sign-In lands, no schema change needed since `users.id` is already the join key everywhere.

**Access model (done)**: anonymous/no-account access is search-only — browsing Discovery (`GET /trips`) stays open, but `POST /trips` and joining both require `X-User-Id`. Trips carry a nullable `creator_user_id` (nullable because pre-existing dev rows have none — every trip created from here on always has one). `users` has an `account_type` (`individual` | `dive_center`, default `individual`, no UI to set it yet) ahead of dive centers being onboarded, so that onboarding won't need a breaking migration.

Endpoints so far: `POST /trips` (auth required), `GET /trips` (open), `GET /trips/{id}` (includes `joined`, `creatorUserId`, `participantCount` for the caller), `GET /trips/mine` (joined trips, ordered by `joined_at` until real "last message" ordering exists), `POST /trips/{id}/join` (idempotent), `GET/POST /trips/{id}/messages` (403 if not a participant), `GET /realtime/token` (mints a Centrifugo connection JWT for the caller).

### Packages (`backend/internal/`)

| Package | Responsibility |
|---|---|
| `server` | HTTP router, route registration, handlers, `withUser` stub-auth middleware |
| `config` | Env-var loading (`.env` via godotenv) |
| `db` | Database connection pool (pgx) |
| `trip` | Trip domain: model, repository, service (create/list/get/join/isJoined/listJoinedByUser/countParticipants) |
| `user` | Stub identity: `GetOrCreate` upserts by client-supplied `X-User-Id`; also carries `account_type` |
| `message` | Chat messages: model, repository, service (send/list per trip) |
| `realtime` | `Publisher` (POST to Centrifugo `/api/publish`), `TokenIssuer` (mints connection JWTs, HS256) |

### App (`app/`)

```bash
cd app && flutter run                          # pick a device/simulator interactively, or -d <id>
dart run build_runner build --delete-conflicting-outputs   # regenerate freezed/json_serializable code after editing models/entities
```

Runs independently of the backend — no shared tooling with the `backend/` Makefile above. Points at `http://localhost:8080` (hardcoded `_apiBaseUrl` in `main.dart` for now — works on iOS simulator/web since they share the host's localhost; Android emulator will need `10.0.2.2` once that's exercised). `org` is `io.divebuddy`.

Top-level shell: `ui/core/navigation/root_shell.dart` — `RootShell` holds the Explore/Trips/Profile `NavigationBar` + an `IndexedStack`. **Gotcha already hit once**: construct each tab's ViewModel exactly once (as a `late final` field on `_RootShellState`, e.g. via `initState` or field initializer) — building them inline inside `build()` hands the tab a fresh, unloaded ViewModel on every rebuild (any `setState`, including switching tabs), silently wiping already-loaded data. `TripsListView`/`MyTripsView` etc. don't re-run `initState` on rebuild, so a swapped-out `widget.viewModel` is never reloaded.

Features: `ui/features/trips/` (Explore list, Trip Page detail + join), `ui/features/chats/` (Trips tab = joined-trips list, chat screen), `ui/features/profile/` (placeholder).

### App layers (`app/lib/`)

| Layer | Path | Contents |
|---|---|---|
| Domain | `domain/entities/` | `Trip` (incl. nullable `creatorUserId`, `participantCount`), `ChatMessage` (freezed) |
| Data | `data/models/` | `TripApiModel`, `ChatMessageApiModel` (freezed + json_serializable) |
| Data | `data/mappers/` | `*ApiMapper.toDomain()` extensions |
| Data | `data/services/` | `TripApiService`, `ChatApiService` (attach `X-User-Id` header), `UserIdentityService` (persists a client-generated uuid via `shared_preferences`), `RealtimeService` (wraps a single shared `centrifuge.Client`, `subscribe`/`unsubscribe` per channel) |
| Data | `data/repositories/` | `TripRepository`, `ChatRepository` (incl. `getRealtimeToken()`) |
| UI | `ui/features/trips/view_models/` `/views/` | `TripsListViewModel`/`TripsListView` (Explore), `TripViewModel`/`TripPage` (detail + join — `TripViewModel` carries `currentUserId` too, same pattern as `ChatViewModel`, so the view can tell "you organized this" without a separate prop) |
| UI | `ui/features/chats/view_models/` `/views/` | `MyTripsViewModel`/`MyTripsView` (Trips tab), `ChatViewModel`/`ChatView` — subscribes to `trip:$tripId` on `load()`, dedupes incoming publications by message id (own sent messages already arrive via the post-send REST reload), unsubscribes in `dispose()` (called explicitly from `ChatView.dispose()`, ChangeNotifier's `dispose` isn't auto-invoked by Flutter) |
| UI | `ui/features/profile/views/` | `ProfileView` (placeholder) |

DI is manual (constructed in `main.dart` / `RootShell.initState`) — no `get_it`/`provider` yet, added only if wiring gets unwieldy across more features.

Generated `*.freezed.dart`/`*.g.dart` files are committed (not gitignored) so a fresh clone can `flutter run` without a `build_runner` step first. Re-run `dart run build_runner build --delete-conflicting-outputs` and commit the diff whenever a `@freezed`/`fromJson` model changes.

## Architecture

The Flutter app follows the **flutter-mvvm-architecture** skill (`.claude/skills/flutter-mvvm-architecture/`): MVVM in the UI layer (Views + ChangeNotifier ViewModels), Repository pattern in the data layer (Services → Mappers → Repositories → domain entities), with an optional Use Case layer for logic that doesn't belong in a ViewModel. Follow it when scaffolding new features.

## Design system (`app/lib/ui/core/theme/`)

Component library is **Material** (Material 3 widgets throughout — no custom widget kit). Colors and semantic tokens are sourced from Figma (file `jgNXK7udS3SrZJkqjcmwss`, "Colors" page, node `1:191`) — that page has no Figma Variables bound, just named color swatches, so the tokens were transcribed by hand into `app_colors.dart` and must be kept in sync manually if the Figma page changes (no live sync).

| File | Contents |
|---|---|
| `app_colors.dart` | `AppColors` — every raw token from Figma (bg/surface, buttons, text, semantic, exact hex). **Source of truth** — reach for these directly when a widget needs a token with no clean Material role. |
| `app_gradients.dart` | `AppGradients` — brand (hero/splash), compact (CTA banners), imageScrim (overlay for legibility over trip photos). |
| `semantic_colors.dart` | `SemanticColors` — a `ThemeExtension` for success/warning/info/neutral (+container/on-container), since Material 3's `ColorScheme` has no slots for these. Access via `Theme.of(context).extension<SemanticColors>()!`. |
| `app_text_theme.dart` | `AppTextTheme.build()` — **Fraunces** (serif) for display/headline (splash, trip titles, empty states — brand warmth), **Inter** (grotesk) for title/body/label (dense lists, dates, chat — legibility at small sizes). Both via `google_fonts`, no bundled font assets. |
| `app_theme.dart` | `AppTheme.light` — assembles `ThemeData`: `ColorScheme` derived field-by-field from `AppColors` (not `ColorScheme.fromSeed`), plus button/card/input component themes mapped to the Figma "Buttons" swatch (primary → `ElevatedButton`, secondary → `FilledButton`, outlined/ghost → `OutlinedButton`/`TextButton`). `AppButtonStyles.destructive`/`.ghost` cover styles with no dedicated Material widget. |

Other `ui/core/` helpers used when building screens: `assets/app_assets.dart` (`AppAssets.tripPlaceholder` — every trip card uses the same placeholder photo until real trip photos exist, no per-trip image data yet), `formatting/date_format.dart` (`formatShortDate()` — "Sat, Jul 18" style, hand-rolled instead of pulling in `intl` for one label).

Screens are being redesigned incrementally against Lovable-generated references (visual direction only, not copied 1:1) plus real KingFish trip pages as a check on what fields a real dive listing needs.

- **Explore card (done)**: 2-column grid, square photo + gradient scrim + date pill, serif title (2 lines max), location — deliberately **omits seats/price/type tags**, since capacity and trip type aren't modeled yet and the platform isn't pricing trips (see Monetization above).
- **Trips tab (done)**: single chat list, no Chats/Upcoming tabs (keeps the trip==chat decision). Each row: cropped trip-photo thumbnail, title + date on one line (title `Expanded` + ellipsis so a long title truncates instead of pushing the date off, date vertically centered against the title not top-aligned), location, then an Active/Past status pill computed from `startTime` (no backend field). Unread-message indicator is intentionally not built yet — needs the backend to track last-read-message per user/trip first; the row layout doesn't reserve dedicated space for it since it'll likely sit next to the date once that data exists.
- **Trip Page (done)**: hero photo + gradient scrim, title, location + date/time, an Organizer card (avatar placeholder, no name — `users` has no display name yet, so it only shows "(You)" when `trip.creatorUserId == currentUserId`, nothing otherwise), "N divers joined" from the real `participantCount`, then Join/Joined. No Meet/Depth/Level info grid, no description, no "I've already booked" — none of that data exists yet (see feature backlog).
- **Still to redesign**: Profile (deferred until real profile fields exist).

Only a light theme exists — Figma's Colors page doesn't specify a dark variant, so one hasn't been invented; add it if/when Figma defines one rather than guessing.

`ColorScheme` role mapping worth remembering if extending: `primary` = buttons/primary, `secondary` = text/secondary (used for `onSurfaceVariant` too, which is why `ListTile` subtitles pick up the muted tone automatically), `tertiary` = text/accent (same hex as semantic `info`), `surface` = surface/primary (white, cards), `scaffoldBackgroundColor` = bg/base (page background — deliberately distinct from `surface`), `scrim` = surface/overlay.

## Git workflow

- Final branch: **develop**
- New work happens on a feature branch off `develop`, not directly on `develop`.
- Merge the feature branch into `develop` locally (no PR), then push `develop`.
- Commit messages: short, e.g. "Added design system" — not multi-paragraph bodies.
- Code comments: one line max — what it is and why, not a paragraph.
