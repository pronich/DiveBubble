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

## Navigation / IA

Bottom nav (v1): **Explore — Trips — Profile**. Key decision: **a joined trip *is* its chat** — no separate chat entity. "Explore" is the discovery list (all open trips); "Trips" lists only trips the current user has joined, ordered by conversation activity, and each row opens directly into that trip's chat. Tapping the chat header from there opens the same Trip Page (Overview/Transport/Dives tabs) — one shared screen/route, not a separate "joined trip" view, so the marketplace framing (a trip is always a trip, joined or not) doesn't get buried under a messaging mental model. `Trips` tab and its empty state are deferred until join (step 6) exists.

Build order being followed: Discovery list (done) → Trip Page detail (done) → stub auth + join → Trips tab (= chats) + chat screen → real Apple/Google auth → transport board → richer Discovery/profile fields. Logbook, Dives sub-tab, and the dive-center web admin are explicitly deferred past all of this.

## Stack

| Layer | Tech |
|---|---|
| App (mobile + web) | Flutter — single codebase, mobile-first design, builds to iOS/Android/Web |
| Admin (future, for dive centers) | Flutter, same codebase family |
| Backend | Go, PostgreSQL |
| Chat | Managed/off-the-shelf WebSocket library — do not build chat infra from scratch |
| Deploy | DigitalOcean |

## Repo structure

```
DiveBuddy/
  app/        # Flutter app — iOS, Android, Web (Explore list + Trip Page detail, MVVM, verified on iOS simulator)
  admin/      # Flutter admin panel for dive centers (future phase)
  backend/    # Go API — GET /health, POST/GET /trips, GET /trips/{id} (Postgres-backed)
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

### Packages (`backend/internal/`)

| Package | Responsibility |
|---|---|
| `server` | HTTP router, route registration, handlers |
| `config` | Env-var loading (`.env` via godotenv) |
| `db` | Database connection pool (pgx) |
| `trip` | Trip domain: model, repository, service |

### App (`app/`)

```bash
cd app && flutter run                          # pick a device/simulator interactively, or -d <id>
dart run build_runner build --delete-conflicting-outputs   # regenerate freezed/json_serializable code after editing models/entities
```

Runs independently of the backend — no shared tooling with the `backend/` Makefile above. Points at `http://localhost:8080` (hardcoded `_apiBaseUrl` in `main.dart` for now — works on iOS simulator/web since they share the host's localhost; Android emulator will need `10.0.2.2` once that's exercised). `org` is `io.divebuddy`.

First feature: `ui/features/trips/` — Explore list (`TripsListView`, `GET /trips`) and Trip Page detail (`TripPage`, `GET /trips/{id}`), tap-to-navigate wired between them.

### App layers (`app/lib/`)

| Layer | Path | Contents |
|---|---|---|
| Domain | `domain/entities/` | `Trip` (freezed) |
| Data | `data/models/` | `TripApiModel` (freezed + json_serializable) |
| Data | `data/mappers/` | `TripApiMapper.toDomain()` |
| Data | `data/services/` | `TripApiService` (http GET /trips, GET /trips/{id}) |
| Data | `data/repositories/` | `TripRepository` |
| UI | `ui/features/trips/view_models/` | `TripsListViewModel`, `TripViewModel` (ChangeNotifier) |
| UI | `ui/features/trips/views/` | `TripsListView` (Explore), `TripPage` (detail) |

DI is manual (constructed directly in `main.dart`) — no `get_it`/`provider` yet, added only if wiring gets unwieldy across more features.

Generated `*.freezed.dart`/`*.g.dart` files are committed (not gitignored) so a fresh clone can `flutter run` without a `build_runner` step first. Re-run `dart run build_runner build --delete-conflicting-outputs` and commit the diff whenever a `@freezed`/`fromJson` model changes.

## Architecture

The Flutter app follows the **flutter-mvvm-architecture** skill (`.claude/skills/flutter-mvvm-architecture/`): MVVM in the UI layer (Views + ChangeNotifier ViewModels), Repository pattern in the data layer (Services → Mappers → Repositories → domain entities), with an optional Use Case layer for logic that doesn't belong in a ViewModel. Follow it when scaffolding new features.

## Git workflow

- Final branch: **develop**
- Push `develop` to remote directly, then open a PR manually via the GitHub UI. Do not merge locally into any branch beyond `develop`.
- Feature work branches off `develop`.
