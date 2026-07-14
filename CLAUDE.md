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
- **Trip Page → Overview**: `Trip` now carries `endDate`, `description`, `meetingPoint`, `diveCountMin/Max`, `depthMinM/MaxM`, `minCertification`, `bookingCode`, `maxParticipants`, `bookingStatus` (see Backend enrichment section) — all displayed on Trip Page. Still missing: what's included, required equipment list, useful links (not requested for this round).
- **Chat**: participants list with avatars, pinned messages (tbd if needed). Tapping the header opens **Trip Page**: participants, organizer, rules (tbd), shared media (tbd), leave group, report — most of this still tbd, only participants/organizer exist today.
- ~~**Transport board**~~ (done — see Transport section under App below): Offer a ride / Find a ride / Share a rental / I'll get there myself.
- **Trip Page → Dives** (deferred): per-trip dive log, shareable with other participants.
- **Trips tab**: also covers past trips (history), not just upcoming — current build only handles joined+active.
- **Logbook** (deferred, separate from per-trip Dives): personal dive log across all trips.
- **Splitwise-style expense splitting** (deferred, new idea): per-trip shared expenses — flagged as possibly generalizing beyond diving trips later, not diving-specific.
- **Share trip** (deferred): share sheet so a trip can be sent to friends outside the app — deliberately not doing real deep-linking yet (no domain/routing infra until deploy), so this waits.
- **Profile tab**: diver profile (photo, display name, city, languages, short bio, dive count), certifications, gear locker, dive statistics, connected services, settings.
- **Actions**: ~~create trip~~ (done, individual organizers only), join trip, join a pre-booked trip via code (e.g. a dive center's own booking system like Drive&Dive), ~~create transport offer~~ (done), update profile, add certificates, add gear.
- **Web**: diver-facing web is the same Flutter codebase (already builds to web). Dive-center admin is a separate panel for centers to publish their own trips manually; CMS integration is a later idea so centers don't have to enter trips by hand.

## Navigation / IA

Bottom nav (v1): **Explore — Trips — Profile**. Key decision: **a joined trip *is* its chat** — no separate chat entity. "Explore" is the discovery list (all open trips); "Trips" lists only trips the current user has joined, ordered by conversation activity, and each row opens directly into `TripConversationPage`. Tapping the header there opens Trip Page (the general-info screen — location, meeting point, level/depth/dives/duration, organizer, participants) — one shared screen/route, not a separate "joined trip" view, so the marketplace framing (a trip is always a trip, joined or not) doesn't get buried under a messaging mental model.

**Priority ordering within a trip (decided)**: Chat is most important, Transport is second, everything else (trip description, future photos, shared dive log, future splitwise-style expense splitting — the last explicitly flagged as possibly generalizing beyond diving trips later) is lower-priority. This is why Chat/Transport are tabs one tap away from "Trips", while Trip Page (the lower-priority stuff) stays a level deeper, opened only by tapping the header — same pattern Telegram uses for a group's primary conversation vs. its "Group Info" screen. Trip Page itself doesn't need secondary tabs yet since there's nothing to tab between today (description is still just shown inline) — add them there only once Photos/Dive log/Splitwise actually exist, not preemptively.

Build order being followed: Discovery list (done) → Trip Page detail (done) → stub auth + join (done) → Trips tab (= chats) + chat screen (done) → realtime via Centrifugo (done) → Create Trip flow (done, individual organizers only) → Chat/Transport tabs (done) → real Apple/Google auth + Profile → richer Discovery/profile fields. Logbook, Dives sub-tab, Share trip, and the dive-center web admin (incl. its multi-user-per-account model) are explicitly deferred past all of this — dive centers need a meaningfully different auth shape (several staff acting on behalf of one account), so the individual flow is being finished completely first rather than half-building both at once.

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

**Deliberate priority call**: finish the individual (peer-to-peer) organizer flow completely before touching dive centers. Dive centers need a real multi-user-per-account model (several staff accounts acting on behalf of one center), which is a meaningfully different auth shape than anything built so far — better to build it once, later, than bolt it on halfway through.

Endpoints so far: `POST /trips` (auth required), `GET /trips` (open), `GET /trips/{id}` (includes `joined`, `creatorUserId`, `participantCount` for the caller), `GET /trips/mine` (joined trips, ordered by `joined_at` until real "last message" ordering exists), `POST /trips/{id}/join` (idempotent), `GET/POST /trips/{id}/messages` (403 if not a participant), `GET/POST /trips/{id}/transport` (403 if not a participant — same `requireParticipant` guard as messages), `POST /trips/{id}/transport/{offerId}/join` (idempotent, see Transport offers below), `GET /realtime/token` (mints a Centrifugo connection JWT for the caller).

### Transport offers

`trip_transport_offers`: `type` (`offer_ride` | `share_rental` — that's the full set now), `seats` (nullable int, seats available *for others* — the creator isn't counted as occupying one), `details` (nullable free text — time + pickup point combined, not separate structured fields). A sibling table `transport_offer_joins` (`offer_id`, `user_id`, composite PK) tracks who's claimed a seat.

**Two types were tried and removed, not just one**: `find_ride` (migration `000011`) once joining a seat on a real offer directly made a passive "looking for a ride" post pointless, and `self_arranged` (migration `000012`, rows deleted outright — no useful data to preserve, unlike `find_ride`'s convert-don't-drop treatment) once it became clear the whole point of this tab is "someone offers transport, others join it" — an announcement with nothing to join wasn't earning its place. Both remaining types (`offer_ride`, `share_rental`) are always joinable now, so `OfferType.Joinable()` and the corresponding "not joinable" 400 path were deleted too rather than left as dead code for a case that can no longer occur.

`Service.Join` order of checks: offer exists → already joined is a no-op success (checked *before* the seat-count check, so re-joining a now-full offer you're already in doesn't spuriously fail) → **one booking per trip**: `Repository.HasAnyJoinInTrip` checks across every offer on the trip (`JOIN trip_transport_offers` on `transport_offer_joins`), not just this one — a diver only needs one ride, so joining a second, different offer on the same trip returns `ErrAlreadyBooked` (409) — → seat count against `seats` if set (else `ErrFull`, 409). `Repository.ListByTrip` computes `joinedCount` and the caller's `joined` flag for every offer in one query (`LEFT JOIN` aggregate + `EXISTS` subquery) rather than N+1 per-offer lookups, since the whole list needs this data rendered at once (unlike trips, where only the single-trip `GetTrip` call needs `participantCount`). `GET /trips/{id}/transport/{offerId}/joins` returns the raw list of joined user IDs (no names — `users` has none yet) for the offer detail view.

**Transport offer detail**: tapping a list tile (not a Join button — that button was pulled off the tile entirely) opens a bottom sheet showing the type/details, an Organizer row (same avatar-placeholder-plus-"(You)" treatment as Trip Page, since there's still no display name), a "Joined divers" list (fetched on open via the joins endpoint, each row just "You" or "Diver" — same naming limitation), and the Join/Joined/Full button at the bottom. Moving the button off the tile and into the detail was a deliberate trade — it's what makes room to actually show who's inside. The list tile itself shows a Full/Joined status pill (same `_StatusPill` widget as the detail sheet) as a `Positioned` overlay in the top-right corner rather than inline in the `Row`, so the chevron can be centered vertically against the tile's full height (`Stack` + `Positioned.fill`/`Align.centerRight`) instead of top-aligned next to the title. `TransportViewModel.join()` returns `Future<String?>` (null = success) rather than throwing into the shared `error` field — a rejected join (full, or already booked elsewhere on the trip) is scoped to a `SnackBar` on that one button, not a whole-list error state, since `load()`'s `_error` is meant for "the list itself failed to fetch," a different failure mode. `TransportApiService` unwraps the backend's `{"error": "..."}` body so that message reaches the SnackBar directly instead of a raw HTTP dump.

### Trip data fields (enrichment)

`trips` has one required field beyond the original title/location/start_time: `booking_status` (`open` | `full` | `cancelled`, default `open`, **set manually by the organizer** — not derived from participant count, since dive-center trips may track real capacity outside our system entirely). Everything else added is optional (nullable), matching what a real dive trip listing needs (cross-checked against KingFish's own trip pages):

| Field | Type | Notes |
|---|---|---|
| `end_date` | DATE, nullable | Null = single-day trip (same day as `start_time`). Organizer can edit it directly (this is why it's a real end date, not a derived duration). |
| `description` | TEXT | Free text, "About this dive". |
| `meeting_point` | TEXT | Falls back to `location` in the UI when absent — `location` is the general area, this is the exact spot. |
| `dive_count_min` / `dive_count_max` | INT, INT | Either can be null alone (e.g. "up to 8" = min null, max 8); both null = not shown. |
| `depth_min_m` / `depth_max_m` | INT, INT | Same min/max-either-nullable shape as dive count. |
| `min_certification` | TEXT, free text | Not an enum — PADI/SSI/etc. name levels differently, a fixed list would be wrong for some organizers. UI falls back to "Open to all" when null. |
| `booking_code` | TEXT | For the future join-by-code flow (e.g. redeeming a KingFish Drive&Dive booking) — field exists now, redemption logic doesn't yet. |
| `max_participants` | INT, nullable | Only meaningful for individually-organized trips, where joining our marketplace *is* taking a seat (e.g. a car with 4 spots) — `participant_count` already equals occupancy. Dive-center trips leave this null since their real capacity isn't tracked through us. |
| `photo_url` | TEXT, nullable | Unused — no upload flow yet. Added ahead of time so real photo storage is just plumbing later, not a new migration. |

SQL `CHECK` constraints enforce `dive_count_max >= dive_count_min`, `depth_max_m >= depth_min_m`, and `max_participants > 0` at the DB level (all nullable-safe).

Trip Page layout, top to bottom: title, location, date (`formatDateRange`, date only — no time here), a **Meeting point** section (own block, not a grid tile, since the address text can be long: shows meeting *time* + `meetingPoint` falling back to `location`), then an info grid — **LEVEL / DEPTH / DIVES / DURATION** (DEPTH and DIVES tiles omitted entirely when their fields are null rather than shown empty; DURATION is computed client-side from `startTime`/`endDate`, always shown; the grid is a manually-built `Row`/`Column`, not `GridView.count`, after a shrinkWrap sizing bug left a phantom empty row above the tiles) — then "About this dive", the Organizer card, a participants line ("`N` people out of `M` joined" when `maxParticipants` is set, else "`N` people joined"), and a Join button that becomes a disabled "Trip full"/"Trip cancelled" chip when `bookingStatus` isn't `open`. Seats/capacity deliberately isn't a grid tile — it lives in that participants line instead, per product decision.

Each of the 4 info tiles has a small leading icon: LEVEL → `Icons.badge_outlined` (cert card), DEPTH → `Icons.waves` (wave stripes — Material has no "arrow through a wave" glyph; this was given as an acceptable fallback for that), DIVES → `Icons.scuba_diving_outlined`, DURATION → `Icons.schedule`. The same 4 icons + compact abbreviated values (e.g. "15–30m", "3d", "2–5") appear on the Explore card too, below location — same icon set intentionally reused across both screens for visual consistency (see Explore's own entry in the Design system section for why the card's badge layout is two fixed rows rather than a free-flowing wrap).

### Create Trip (`ui/features/trips/views/create_trip_page.dart`)

Individual-organizer trip creation, reachable via the "Create trip" quick-action button in Explore's header (see Explore's own entry in the Design system section — deliberately a real visible button, not an icon-only affordance or a FAB, since a FAB read as too easy to miss scrolled behind card content). `CreateTripViewModel` takes the raw field values on `submit()` and calls `TripRepository.createTrip(...)` → `POST /trips`; on success `TripsListView` reloads the Explore list and navigates straight to the new Trip Page.

Every enriched field from the backend section above is in the form except `bookingCode`/`bookingStatus` (dive-center-flavored, not relevant to an individual creating their own trip yet). Date/time fields (`Date`, `Meeting time`, `End date`) use a Cupertino wheel picker (`CupertinoDatePicker` in a modal bottom sheet) instead of Material's `showDatePicker`/`showTimePicker` dialogs — chosen after those read as an ugly, overlay-style interaction; the field itself still renders as a standard Material `InputDecorator` (floating label inside the filled box), which was tried once as an external-caption layout and reverted — turns out that's a familiar, common pattern once compared against other apps.

`Trip`/`TripApiModel` also carry `photoUrl` (nullable, added ahead of need) — no upload UI exists yet, this is scaffolding for when real photo storage (DigitalOcean Spaces, matching the deploy target) gets built post-launch. Every card/page still renders the same placeholder image regardless of what's in this field.

### Packages (`backend/internal/`)

| Package | Responsibility |
|---|---|
| `server` | HTTP router, route registration, handlers, `withUser` stub-auth middleware |
| `config` | Env-var loading (`.env` via godotenv) |
| `db` | Database connection pool (pgx) |
| `trip` | Trip domain: model, repository, service (create/list/get/join/isJoined/listJoinedByUser/countParticipants) |
| `user` | Stub identity: `GetOrCreate` upserts by client-supplied `X-User-Id`; also carries `account_type` |
| `message` | Chat messages: model, repository, service (send/list per trip) |
| `transport` | Transport offers: model (`OfferType` enum: offer_ride/share_rental — `find_ride` and `self_arranged` both removed, see Transport offers section below), repository, service (create/list/join/listJoins per trip) |
| `realtime` | `Publisher` (POST to Centrifugo `/api/publish`), `TokenIssuer` (mints connection JWTs, HS256) |

### App (`app/`)

```bash
cd app && flutter run                          # pick a device/simulator interactively, or -d <id>
dart run build_runner build --delete-conflicting-outputs   # regenerate freezed/json_serializable code after editing models/entities
```

Runs independently of the backend — no shared tooling with the `backend/` Makefile above. Points at `http://localhost:8080` (hardcoded `_apiBaseUrl` in `main.dart` for now — works on iOS simulator/web since they share the host's localhost; Android emulator will need `10.0.2.2` once that's exercised). `org` is `io.divebuddy`.

Top-level shell: `ui/core/navigation/root_shell.dart` — `RootShell` holds the Explore/Trips/Profile `NavigationBar` + an `IndexedStack`. **Gotcha already hit once**: construct each tab's ViewModel exactly once (as a `late final` field on `_RootShellState`, e.g. via `initState` or field initializer) — building them inline inside `build()` hands the tab a fresh, unloaded ViewModel on every rebuild (any `setState`, including switching tabs), silently wiping already-loaded data. `TripsListView`/`MyTripsView` etc. don't re-run `initState` on rebuild, so a swapped-out `widget.viewModel` is never reloaded.

Features: `ui/features/trips/` (Explore list, Trip Page detail + join, Create Trip), `ui/features/chats/` (Trips tab = joined-trips list, `TripConversationPage` tab shell, `ChatView`), `ui/features/transport/` (`TransportView`, its own feature folder rather than living under `chats/` since it isn't messaging), `ui/features/profile/` (placeholder).

### App layers (`app/lib/`)

| Layer | Path | Contents |
|---|---|---|
| Domain | `domain/entities/` | `Trip` (incl. nullable `creatorUserId`, `participantCount`), `ChatMessage`, `TransportOffer` (freezed) |
| Data | `data/models/` | `TripApiModel`, `ChatMessageApiModel`, `TransportOfferApiModel` (freezed + json_serializable) |
| Data | `data/mappers/` | `*ApiMapper.toDomain()` extensions |
| Data | `data/services/` | `TripApiService`, `ChatApiService`, `TransportApiService` (attach `X-User-Id` header), `UserIdentityService` (persists a client-generated uuid via `shared_preferences`), `RealtimeService` (wraps a single shared `centrifuge.Client`, `subscribe`/`unsubscribe` per channel) |
| Data | `data/repositories/` | `TripRepository`, `ChatRepository` (incl. `getRealtimeToken()`), `TransportRepository` |
| UI | `ui/features/trips/view_models/` `/views/` | `TripsListViewModel`/`TripsListView` (Explore), `TripViewModel`/`TripPage` (detail + join — `TripViewModel` carries `currentUserId` too, same pattern as `ChatViewModel`, so the view can tell "you organized this" without a separate prop), `CreateTripViewModel`/`CreateTripPage` |
| UI | `ui/features/chats/view_models/` `/views/` | `MyTripsViewModel`/`MyTripsView` (Trips tab), `ChatViewModel`/`ChatView` — `ChatView` is body-only now (no `Scaffold`/`AppBar` of its own), embedded as a tab inside `TripConversationPage`; subscribes to `trip:$tripId` on `load()`, dedupes incoming publications by message id (own sent messages already arrive via the post-send REST reload), unsubscribes in `dispose()` (called explicitly from `ChatView.dispose()`, ChangeNotifier's `dispose` isn't auto-invoked by Flutter). `TripConversationPage` owns the shared `AppBar` (title tap → Trip Page) + `TabBar`/`TabBarView` wrapping `ChatView` and `TransportView`. |
| UI | `ui/features/transport/view_models/` `/views/` | `TransportViewModel` (carries `currentUserId` too, same pattern as `TripViewModel`/`ChatViewModel`)/`TransportView` — list of tiles (tap → detail bottom sheet, no button on the tile itself) + a FAB opening the add-offer sheet (type via `ChoiceChip`s, optional seats/details). The detail sheet has the Organizer row, the "Joined divers" list, and the Join/"Joined" chip/"Full" chip button. |
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
| `app_theme.dart` | `AppTheme.light` — assembles `ThemeData`: `ColorScheme` derived field-by-field from `AppColors` (not `ColorScheme.fromSeed`), plus button/card/input component themes mapped to the Figma "Buttons" swatch (primary → `ElevatedButton`, secondary → `FilledButton`, outlined/ghost → `OutlinedButton`/`TextButton`). `AppButtonStyles.destructive`/`.ghost` cover styles with no dedicated Material widget. **Gotcha already hit once**: `appBarTheme` pins `surfaceTintColor: Colors.transparent` — Material 3's default tints any `AppBar` with `ColorScheme.primary` once content scrolls under it (via `scrolledUnderElevation`), which read as the header's background color visibly changing on scroll even though `backgroundColor` never changed. |

Other `ui/core/` helpers used when building screens: `assets/app_assets.dart` (`AppAssets.tripPlaceholder` — every trip card uses the same placeholder photo until real trip photos exist, no per-trip image data yet), `formatting/date_format.dart` (`formatShortDate()` — "Sat, Jul 18" style, hand-rolled instead of pulling in `intl` for one label).

Screens are being redesigned incrementally against Lovable-generated references (visual direction only, not copied 1:1) plus real KingFish trip pages as a check on what fields a real dive listing needs.

- **Explore (done)**: no `AppBar`/title at all anymore — the screen is `Scaffold(body: SafeArea(Column([_ExploreHeader, Expanded(grid)])))`. `_ExploreHeader` is an Airbnb-style header: a **mock search field** (`Icons.search` + "Search trips", no query/filter logic wired up yet — see Discovery friction in Product context) above two compact quick-action pills, **"Create trip"** and **"Join trip"** (both `FilledButton`, i.e. the calm light-fill secondary treatment, deliberately *not* the bold primary `ElevatedButton` style — most divers are expected to ignore both and just browse, the same way Airbnb's category chips stay quiet under its search bar; "Join trip" is a UI-only stub for now, tapping either the search field or Join trip shows a "Coming soon" `SnackBar`, since neither search nor the `booking_code` redemption flow exists yet). The header shows a real `BoxShadow` (not Material elevation — that read as invisible against a flat background) that's hidden at scroll-top and fades in via `AnimatedContainer` once the grid scrolls (tracked with `NotificationListener<ScrollNotification>` on the grid, toggling a bool in `_TripsListViewState` — deliberately not tied to a `ScrollController` since `NotificationListener` needs no lifecycle disposal). Card: 2-column grid, **4:3 landscape** photo (not square — an Airbnb-style crop reads less cramped) + gradient scrim + date pill, serif title (**1 line, ellipsis** — was 2 lines, wrapping made cards taller than needed), location, then exactly **two fixed badge rows**: row 1 is always Level alone (`minCertification ?? 'Open to all'`, same fallback as Trip Page — anchors row 1 since it's the only one of the four guaranteed to always have a value), row 2 is Depth/Duration/Dives (each individually omitted if its field is null, but never wraps — it's a `Row`, not a flexible `Wrap`). Deliberately still **omits seats/price/type tags**, since capacity-as-a-cap and trip type aren't modeled yet and the platform isn't pricing trips (see Monetization above).

  **Why two fixed rows, not one `Wrap` of up to 4 badges**: `GridView`'s `childAspectRatio` is one shared value for every cell, sized to fit the *tallest* possible content — so with a flexible `Wrap`, sparsely-filled trips (most of them, since depth/dives/level are optional) ended up with visibly empty space at the bottom while fully-filled trips looked right. Locking the badge area to exactly two rows always (never one, never three) makes every card's content height identical regardless of how many optional fields a trip actually has, which is what the fixed-aspect-ratio grid model needs to look correct. `Icons.waves` is DEPTH's icon — Material has no "arrow through a wave" glyph, and this was explicitly given as an acceptable fallback.
- **Trips tab (done)**: single chat list, no Chats/Upcoming tabs (keeps the trip==chat decision). Each row: cropped trip-photo thumbnail, title + date on one line (title `Expanded` + ellipsis so a long title truncates instead of pushing the date off, date vertically centered against the title not top-aligned), location, then an Active/Past status pill computed from `startTime` (no backend field). Unread-message indicator is intentionally not built yet — needs the backend to track last-read-message per user/trip first; the row layout doesn't reserve dedicated space for it since it'll likely sit next to the date once that data exists.
- **Trip Page (done)**: see the Trip data fields section above for the full current layout (Meeting point block, LEVEL/DEPTH/DIVES/DURATION info grid with icons, participants line, booking-status-aware Join button) — this bullet used to describe an earlier, pre-enrichment version and was out of date.
- **Still to redesign**: Profile (deferred until real profile fields exist).

Only a light theme exists — Figma's Colors page doesn't specify a dark variant, so one hasn't been invented; add it if/when Figma defines one rather than guessing.

`ColorScheme` role mapping worth remembering if extending: `primary` = buttons/primary, `secondary` = text/secondary (used for `onSurfaceVariant` too, which is why `ListTile` subtitles pick up the muted tone automatically), `tertiary` = text/accent (same hex as semantic `info`), `surface` = surface/primary (white, cards), `scaffoldBackgroundColor` = bg/base (page background — deliberately distinct from `surface`), `scrim` = surface/overlay.

## Git workflow

- Final branch: **develop**
- New work happens on a feature branch off `develop`, not directly on `develop`.
- Merge the feature branch into `develop` locally (no PR), then push `develop`.
- Commit messages: short, e.g. "Added design system" — not multi-paragraph bodies.
- Code comments: one line max — what it is and why, not a paragraph.
