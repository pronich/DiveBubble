# DiveBubble

Marketplace for dive trips (short and long), organized by dive centers or by local divers. Single monorepo for app + backend.

Renamed from "DiveBuddy" (name was taken) — app display name, splash screen, and the Trips tab (now "Bubbles") all reflect the new brand. The repo folder, Dart package (`divebubble`), Go module (`divebubble_be`), and local Postgres dev credentials were also renamed to match. The Google Cloud project itself was left as-is (renaming a live GCP project is out of scope here) — only the iOS/Android bundle id changed (see Auth section) since Google Sign-In ties directly to it.

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

- **Auth & onboarding**: animated first-run intro + login sheet (done). Google Sign-In is done end-to-end and every route is cut over to bearer auth (backend JWT access + refresh-token sessions, ForeignReader-style — see Auth section — plus the Flutter `google_sign_in`/secure-storage wiring, login-gated actions, and stay-fresh-on-resume/auth-change handling); Apple button is still a disabled stub, blocked on an App Store Connect app registration. "Dive in"/"Dive out" is the app's login/logout terminology everywhere (not "Login"/"Log out").
- **Discovery card fields**: photo (or placeholder), date, location, title — filtered by proximity to user.
- **Trip Page → Overview**: `Trip` now carries `endDate`, `description`, `meetingPoint`, `diveCountMin/Max`, `depthMinM/MaxM`, `minCertification`, `bookingCode`, `maxParticipants`, `bookingStatus` (see Backend enrichment section) — all displayed on Trip Page. Still missing: what's included, required equipment list, useful links (not requested for this round).
- **Chat**: participants list with avatars, pinned messages (tbd if needed). Tapping the header opens **Trip Page**: participants, organizer, rules (tbd), shared media (tbd), leave group, report — most of this still tbd, only participants/organizer exist today.
- ~~**Transport board**~~ (done — see Transport section under App below): Offer a ride / Find a ride / Share a rental / I'll get there myself.
- **Trip Page → Dives** (deferred): per-trip dive log, shareable with other participants.
- **Trips tab**: also covers past trips (history), not just upcoming — current build only handles joined+active.
- **Logbook** (deferred, separate from per-trip Dives): personal dive log across all trips.
- **Splitwise-style expense splitting** (deferred, new idea): per-trip shared expenses — flagged as possibly generalizing beyond diving trips later, not diving-specific.
- **Share trip** (deferred): share sheet so a trip can be sent to friends outside the app — deliberately not doing real deep-linking yet (no domain/routing infra until deploy), so this waits.
- ~~**Profile tab**~~ (Overview done — see Profile section under App below): display name, location, bio, dive count, certification level, languages, member since; Notifications/About/Legal/Dive out as Airbnb-style rows. Still deferred: structured certifications (issuing agency/date per cert, not just a single level string), gear locker, dive statistics beyond a manual count, connected services, real photo upload (avatar is a pasted URL for now).
- **Actions**: ~~create trip~~ (done, individual organizers only), join trip, join a pre-booked trip via code (e.g. a dive center's own booking system like Drive&Dive), ~~create transport offer~~ (done), ~~update profile~~ (done), add certificates, add gear.
- **Web**: diver-facing web is the same Flutter codebase (already builds to web). Dive-center admin is a separate panel for centers to publish their own trips manually; CMS integration is a later idea so centers don't have to enter trips by hand.

## Navigation / IA

Bottom nav (v1): **Explore — Bubbles — Profile** (the middle tab was labeled "Trips" pre-rebrand; code/files still say `MyTripsView`/`MyTripsViewModel` etc. — only the user-facing label and icon changed, see Design system). Key decision: **a joined trip *is* its chat** — no separate chat entity. "Explore" is the discovery list (all open trips); "Bubbles" lists only trips the current user has joined, ordered by conversation activity, and each row opens directly into `TripConversationPage`. Tapping the header there opens Trip Page (the general-info screen — location, meeting point, level/depth/dives/duration, organizer, participants) — one shared screen/route, not a separate "joined trip" view, so the marketplace framing (a trip is always a trip, joined or not) doesn't get buried under a messaging mental model.

**Priority ordering within a trip (decided)**: Chat is most important, Transport is second, everything else (trip description, future photos, shared dive log, future splitwise-style expense splitting — the last explicitly flagged as possibly generalizing beyond diving trips later) is lower-priority. This is why Chat/Transport are tabs one tap away from "Trips", while Trip Page (the lower-priority stuff) stays a level deeper, opened only by tapping the header — same pattern Telegram uses for a group's primary conversation vs. its "Group Info" screen. Trip Page itself doesn't need secondary tabs yet since there's nothing to tab between today (description is still just shown inline) — add them there only once Photos/Dive log/Splitwise actually exist, not preemptively.

Build order being followed: Discovery list (done) → Trip Page detail (done) → stub auth + join (done) → Trips tab (= chats) + chat screen (done) → realtime via Centrifugo (done) → Create Trip flow (done, individual organizers only) → Chat/Transport tabs (done) → Empty states (done) → onboarding intro/login UI (done) → real Google auth backend + full route cutover + login-gated actions (done) → Profile fields → richer Discovery/profile fields. Logbook, Dives sub-tab, Share trip, and the dive-center web admin (incl. its multi-user-per-account model) are explicitly deferred past all of this — dive centers need a meaningfully different auth shape (several staff acting on behalf of one account), so the individual flow is being finished completely first rather than half-building both at once.

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
DiveBubble/
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

### Auth (Google Sign-In, done end-to-end, all routes cut over)

`X-User-Id`/`withUser`/`internal/user` (the stub-auth era) are gone — deleted entirely once nothing referenced them anymore, rather than left around unused. Every route except `GET /trips` and `GET /health` now requires a real bearer access token; `GET /trips/{id}` is the one exception that takes either (see below).

`internal/auth/` — ForeignReader-pattern JWT access token + rotating refresh-token session, adapted down to DiveBubble's single-mobile-client shape (no ForeignReader's `source: app/web` split, since there's no separate web cabinet yet).

- **Tables**: `auth_identities` (`user_id`, `provider`, `provider_user_id`, `provider_email`, unique on `(provider, provider_user_id)`) and `auth_sessions` (`user_id`, `provider`, `refresh_token_hash`, `expires_at`, `revoked_at`/`revoke_reason`/`replaced_by_session_id` for rotation tracking) — migrations `000013`/`000014`. Kept separate from `users` (not a column on it) so Apple can be added later without another migration.
- **Tokens**: access token is an HS256 JWT (`auth.TokenIssuer`, `sub`=user id, `sid`=session id), default TTL 8h (`ACCESS_TOKEN_TTL` env, `time.ParseDuration` syntax). Refresh token is an opaque random value (`auth.GenerateRefreshToken`) — only its SHA-256 hash is stored, default session TTL 180 days (`REFRESH_SESSION_TTL`). `auth.SessionRepository.RotateRefreshToken` rotates atomically on every refresh (old session marked `revoked_at`/`replaced_by_session_id`, new row inserted) and treats reusing an already-rotated token as `ErrRefreshReused` — a signal the token was stolen, not just an expired session.
- **Google verification**: `auth.VerifyGoogleIDToken` uses `google.golang.org/api/idtoken` against `GOOGLE_SERVER_CLIENT_ID` — this must be the **Web** OAuth client id, not the iOS one, since the client requests the ID token with `serverClientId` set to it (the iOS client id only identifies the app to Google, it isn't the JWT audience).
- **Endpoints** (`registerAuthRoutes` in `internal/server/routes_auth.go`): `POST /auth/google` (body `{"idToken"}`, creates the user+identity on first sight via `auth.IdentityRepository.LoginOrRegister`, returns access+refresh), `POST /auth/refresh` (body `{"refreshToken"}`, rotates), `POST /auth/logout` (bearer-authed, revokes the calling session).
- **Middleware** (`internal/server/middleware_auth.go`): `withAuth` (requires a valid bearer token, 401 otherwise) wraps every route except `GET /trips`/`GET /health`. `GET /trips/{id}` uses `optionalAuth` instead — resolves the caller's id if a valid token is present, or passes `uuid.Nil` for anonymous callers, so trip detail stays browsable without an account (`joined` just reads false for `uuid.Nil`, no special-casing needed in the handler); a *present but invalid* token still 401s there too, so a stale token doesn't silently degrade to anonymous.
- **Google Cloud Console setup** (done): one Web OAuth client (`GOOGLE_SERVER_CLIENT_ID`, no client secret needed for this flow) + one iOS OAuth client — bundle id updated to `io.divebubble.app` in Console after the DiveBubble rebrand (was `io.divebuddy.divebuddy`; the client id itself didn't change, only the Bundle ID field on that existing credential). Both ids are hardcoded as consts in `main.dart` (`_googleIosClientId`/`_googleServerClientId`) — fine for now since they're not secrets (a client id is public by design), unlike `JWT_SECRET`/`GOOGLE_SERVER_CLIENT_ID`-the-backend-env-var which stay in `.env`. Apple Sign-In is blocked on registering the app in App Store Connect first, so Google shipped first.
- **Flutter client (done)**: `data/services/auth_api_service.dart` (calls `/auth/google`/`/auth/refresh`/`/auth/logout`), `data/services/token_storage_service.dart` (`flutter_secure_storage`, not `shared_preferences` — these are real credentials), `data/repositories/auth_repository.dart` (wraps `google_sign_in` v7's `GoogleSignIn.instance.initialize()`/`.authenticate()` API, exchanges the ID token with the backend, persists the result via `getValidAccessToken()` which transparently refreshes when the access token is within 60s of expiry). `AuthRepository extends ChangeNotifier`, notifying on both sign-in and on a failed-refresh sign-out, so screens that mounted before login can react (see below). iOS needs `CFBundleURLTypes` with the reversed iOS client id in `Info.plist` (`google_sign_in_ios`'s hard requirement regardless of where the client ids themselves are configured) — clientId/serverClientId are passed via `initialize()` in Dart rather than `Info.plist`'s `GIDClientID` key, so no Firebase project or `GoogleService-Info.plist` needed. **Verified end-to-end** against a real Google account: row appeared in `users`, `auth_identities` (real `google_sub` + email), and `auth_sessions` (refresh expiring ~180 days out).
- **Every existing route cut over (done)**: `TripApiService`/`ChatApiService`/`TransportApiService` all take a `getAccessToken: AccessTokenProvider` (typedef for `Future<String?> Function()`, `data/services/access_token_provider.dart`) instead of the old `userId` string, and send `Authorization: Bearer` instead of `X-User-Id`. Hard-gated endpoints throw `AuthRequiredException` (`data/services/auth_required_exception.dart`) if `getAccessToken()` returns null, rather than making the request and getting a 401 back — lets calling code distinguish "please sign in" from a generic network/server failure. `TripApiService.fetchTrip`/`fetchTrips` are the exception: they attach a token if present but never throw, matching `optionalAuth` server-side. The old anonymous `UserIdentityService`/stub uuid is deleted — `currentUserId` (used for "is this me" UI comparisons: organizer badges, "You" in joined-divers lists, chat bubble alignment) is now resolved fresh from the real signed-in user id (`AuthRepository.currentUserId()`) whenever the app enters its main phase (`AppEntryGate._enterApp()`), defaulting to `''` (never matches a real id) while anonymous.
- **New-account handling (done)**: `auth.IdentityRepository.LoginOrRegister` takes the Google identity's `name`/`picture` and seeds `users.display_name`/`avatar_url` with them **only on the row's creation** — later logins never overwrite whatever the user has since set themselves via Edit Profile. It also returns `isNewUser`, threaded through `/auth/google`'s response → `AuthRepository.signInWithGoogle()` → `SignInResult.isNewUser`. `LoginSheet` checks this after a successful sign-in and, if true, pushes `EditProfilePage` before closing — a brand-new account goes straight into filling out its profile instead of landing on an empty screen. Since `LoginSheet` needed a `ProfileRepository` for this, every `ensureSignedIn`/`LoginSheet.show` call site threads one through alongside `authRepository`.
- **Login-gated actions (done)**: `ui/core/auth/ensure_signed_in.dart`'s `ensureSignedIn(context, authRepository, profileRepository)` is the shared gate — checks for a valid token, and if none, opens `LoginSheet` and awaits the result; returns the (possibly freshly-signed-in) user id, or null if the user declined. Used before: Create trip (`TripsListView._openCreateTrip`), joining a trip (`TripPage`'s Join button), joining a transport offer (`_TransportOfferDetailSheetState._join`) — each uses the *fresh* id this returns for whatever gets constructed next, not a possibly-stale `currentUserId` captured before login happened.
- **Keeping screens fresh (done)**: `TripsListView`, `MyTripsView`, and `ProfileView` all: (a) listen to `authRepository` (a `ChangeNotifier`) and reload/re-check when sign-in state changes anywhere else in the app — e.g. logging in via the Create-trip gate must also unstick the Trips tab, which may have already loaded (and cached "needs sign in") before that happened; (b) use Flutter's built-in `AppLifecycleListener(onResume: ...)` to refetch when the app returns to the foreground, since data can go stale while backgrounded. A true cold start already gets fresh data for free (new widget tree, `initState` re-runs) — no special handling needed there. `MyTripsViewModel` tracks a distinct `needsSignIn` flag (checking for `AuthRequiredException` specifically) so that case renders a "Sign in to see your trips" prompt instead of a raw error.

**Access model (done)**: anonymous/no-account access is search-only — browsing Discovery (`GET /trips` and now also `GET /trips/{id}`) stays open, but creating a trip, joining (trip or transport), and viewing your Trips list all require real sign-in — gated via `ensureSignedIn` client-side and `withAuth` server-side. Trips carry a nullable `creator_user_id` (nullable because pre-existing dev rows have none — every trip created from here on always has one). `users` has an `account_type` (`individual` | `dive_center`, default `individual`, no UI to set it yet) ahead of dive centers being onboarded, so that onboarding won't need a breaking migration.

**Deliberate priority call**: finish the individual (peer-to-peer) organizer flow completely before touching dive centers. Dive centers need a real multi-user-per-account model (several staff accounts acting on behalf of one center), which is a meaningfully different auth shape than anything built so far — better to build it once, later, than bolt it on halfway through.

Endpoints so far: `POST /trips` (auth required), `GET /trips` (open), `GET /trips/{id}` (includes `joined`, `creatorUserId`, `participantCount` for the caller), `GET /trips/mine` (joined trips, ordered by `joined_at` until real "last message" ordering exists), `POST /trips/{id}/join` (idempotent), `GET/POST /trips/{id}/messages` (403 if not a participant), `GET/POST /trips/{id}/transport` (403 if not a participant — same `requireParticipant` guard as messages), `POST /trips/{id}/transport/{offerId}/join` (idempotent, see Transport offers below), `GET /realtime/token` (mints a Centrifugo connection JWT for the caller).

### Profile (Overview done)

- **Backend** (`internal/profile/`, migrations `000015`/`000016`): self-reported fields live directly on `users` — `display_name`, `avatar_url`, `location`, `bio`, `dive_count` (int, default 0), `certification_level`, `languages` (comma-separated TEXT, e.g. `"English, Russian"` — deliberately not a real Postgres array so no array-scanning support was needed in `database/sql`). `GET /me`/`PATCH /me` (both `withAuth`) — `PATCH` uses `COALESCE($n, column)` per field so a nil pointer in `profile.UpdateParams` leaves that column untouched rather than clearing it. `memberSince` in the API response is just `users.created_at`, not a stored field.
- **Flutter data layer (done)**: `domain/entities/profile.dart` (freezed), `data/models/profile_api_model.dart` (freezed + json_serializable — remember to re-run `build_runner` after editing), `data/services/profile_api_service.dart`/`data/repositories/profile_repository.dart` following the same shape as Trip/Transport. `ui/features/profile/view_models/profile_view_model.dart` has `load()` (sets `needsSignIn` on `AuthRequiredException`, same pattern as `MyTripsViewModel`) and `submit(...)` for edits.
- **Canonical dictionaries (done)**: free text for certification level and languages couldn't be compared/filtered on later ("AOW" vs "Advanced Open Water" vs "advanced open water"), so both are now fixed lists: `domain/certification_level.dart`'s `kCertificationLevels` (used by both `CreateTripPage`'s "Required level" dropdown and `EditProfilePage`'s "Certification / level" dropdown) and `domain/languages.dart`'s `kLanguages` (used by `LanguagePickerPage`, a search + multi-select page opened from Edit Profile's Languages field — replaced free-text entry entirely). **Gotcha hit once**: `DropdownButtonFormField`'s `initialValue` asserts if it isn't exactly one of `items` — any profile saved before the dictionary existed (or via direct API testing) can have a value outside `kCertificationLevels`, so `EditProfilePage` guards with `kCertificationLevels.contains(...) ? value : null` rather than passing the stored value straight through. Also set an explicit `style:` on these dropdowns — left unset, the selected item rendered in a much larger/bolder default style that visually didn't match the `TextField`s around it.
- **Display name vs. real identity (done)**: the "Display name" field (labeled that way in Edit Profile, with helper text "Shown to other divers instead of your real name") is the *only* name field — there's no separate private/real-name field. It's prefilled from Google at first sign-in (see New-account handling above under Auth) but fully user-editable afterwards, so a diver can swap in a nickname for privacy without losing the convenience of a sensible default.
- **Guest profile (done)**: `ProfileView` shows a full placeholder profile when signed out, not just a bare button — avatar placeholder, "Guest" name, a best-effort "city, country" from `data/services/location_service.dart` (wraps `geolocator` + `geocoding`; requires `NSLocationWhenInUseUsageDescription` in `Info.plist` and `ACCESS_COARSE_LOCATION`/`ACCESS_FINE_LOCATION` in `AndroidManifest.xml`), a "Dive in" button, then the same About/Legal rows signed-in users get. Any failure (permission denied, services off, geocoding failure) just omits the location line — this is a cosmetic nicety, not something worth erroring over.
- **Settings-as-rows, not a separate Settings screen (done)**: after iterating past both a separate gear-icon Settings page and inline cards, the final layout is Airbnb-style: a thick `Divider` marks a clear break below the profile card, then plain tappable `ListTile` rows (`Notifications`, `About`, `Legal`, each pushing its own page — `notifications_settings_page.dart`/`about_page.dart`/`legal_page.dart`) and, after another divider, "Dive out" as the last row — deliberately unobtrusive (plain `onSurfaceVariant`-colored text, no red/destructive styling, no chevron), since signing out isn't a destructive action the way deleting something is. `AboutPage` shows the app icon/name/tagline/version (`package_info_plus`); `LegalPage`'s Terms/Privacy are "Coming soon" stubs — no hosted documents exist yet, so they're not dead links pointing nowhere.
- **Still deferred**: structured certifications (agency/date per cert, not one string — see Certifications & Gear section below for the in-progress design), gear locker, dive statistics beyond the manual count, connected services, real photo upload (avatar is a pasted URL for now, no upload endpoint).
- **Photo upload (deferred, cross-cutting — noted 2026-07-15)**: avatar, trip `photo_url` (see Trip data fields), and certification card images (see Certifications & Gear) all currently take either no image or a pasted URL, and all need the same underlying plumbing — an upload endpoint backed by DigitalOcean Spaces (matching the deploy target, per Create Trip section). Worth building once as shared infra rather than three separate upload flows, but deliberately not yet — noted here so the certifications work below doesn't quietly reinvent it as a one-off.

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
| `server` | HTTP router, route registration, handlers, `withAuth`/`optionalAuth` bearer middleware (see Auth section) |
| `config` | Env-var loading (`.env` via godotenv) |
| `db` | Database connection pool (pgx) |
| `trip` | Trip domain: model, repository, service (create/list/get/join/isJoined/listJoinedByUser/countParticipants) |
| `auth` | Google Sign-In verification, JWT access tokens, refresh-session rotation, identity/user creation (see Auth section) — replaced the old stub-auth `user` package entirely |
| `profile` | Self-reported diver profile fields on `users` (see Profile section): model, repository (`Get`/`Update`), service |
| `message` | Chat messages: model, repository, service (send/list per trip) |
| `transport` | Transport offers: model (`OfferType` enum: offer_ride/share_rental — `find_ride` and `self_arranged` both removed, see Transport offers section below), repository, service (create/list/join/listJoins per trip) |
| `realtime` | `Publisher` (POST to Centrifugo `/api/publish`), `TokenIssuer` (mints connection JWTs, HS256) |

### App (`app/`)

```bash
cd app && flutter run                          # pick a device/simulator interactively, or -d <id>
dart run build_runner build --delete-conflicting-outputs   # regenerate freezed/json_serializable code after editing models/entities
```

Runs independently of the backend — no shared tooling with the `backend/` Makefile above. Points at `http://localhost:8080` (hardcoded `_apiBaseUrl` in `main.dart` for now — works on iOS simulator/web since they share the host's localhost; Android emulator will need `10.0.2.2` once that's exercised). `org` is `io.divebubble` (bundle id `io.divebubble.app` post-rebrand).

Entry point: `main.dart`'s `MaterialApp.home` is `AppEntryGate` (`ui/features/onboarding/views/app_entry_gate.dart`), not `RootShell` directly — it gates on `OnboardingStateService`'s persisted `has_completed_intro` flag (`shared_preferences`) and shows: first-ever launch → `IntroView` (animated bubble intro); returning users → `StaticSplashView` (quick static "B", no animation) → then either way `RootShell` via `rootShellBuilder(context, currentUserId)`. This flag intentionally still means "has seen the intro once", not "is authenticated" — browsing doesn't require an account, so a user who skips can go straight to `RootShell` on every later cold start too; `currentUserId` is resolved fresh from `AuthRepository` at that point regardless (real signed-in id, or `''` if anonymous).

Top-level shell: `ui/core/navigation/root_shell.dart` — `RootShell` holds the Explore/Trips/Profile `NavigationBar` + an `IndexedStack`. **Gotcha already hit once**: construct each tab's ViewModel exactly once (as a `late final` field on `_RootShellState`, e.g. via `initState` or field initializer) — building them inline inside `build()` hands the tab a fresh, unloaded ViewModel on every rebuild (any `setState`, including switching tabs), silently wiping already-loaded data. `TripsListView`/`MyTripsView` etc. don't re-run `initState` on rebuild, so a swapped-out `widget.viewModel` is never reloaded.

Features: `ui/features/trips/` (Explore list, Trip Page detail + join, Create Trip), `ui/features/chats/` (Trips tab = joined-trips list, `TripConversationPage` tab shell, `ChatView`), `ui/features/transport/` (`TransportView`, its own feature folder rather than living under `chats/` since it isn't messaging), `ui/features/profile/` (placeholder), `ui/features/onboarding/` (`AppEntryGate`, `IntroView`, `StaticSplashView`, `LoginSheet` — see Design system section for the bubble-logo animation).

### App layers (`app/lib/`)

| Layer | Path | Contents |
|---|---|---|
| Domain | `domain/entities/` | `Trip` (incl. nullable `creatorUserId`, `participantCount`), `ChatMessage`, `TransportOffer` (freezed) |
| Data | `data/models/` | `TripApiModel`, `ChatMessageApiModel`, `TransportOfferApiModel` (freezed + json_serializable) |
| Data | `data/mappers/` | `*ApiMapper.toDomain()` extensions |
| Data | `data/services/` | `TripApiService`, `ChatApiService`, `TransportApiService`, `ProfileApiService` (attach `Authorization: Bearer` via an injected `AccessTokenProvider`), `AuthApiService`/`TokenStorageService` (Google Sign-In token exchange + secure storage — see Auth section), `LocationService` (best-effort geolocation for the guest profile — see Profile section), `RealtimeService` (wraps a single shared `centrifuge.Client`, `subscribe`/`unsubscribe` per channel) |
| Data | `data/repositories/` | `TripRepository`, `ChatRepository` (incl. `getRealtimeToken()`), `TransportRepository` |
| UI | `ui/features/trips/view_models/` `/views/` | `TripsListViewModel`/`TripsListView` (Explore), `TripViewModel`/`TripPage` (detail + join — `TripViewModel` carries `currentUserId` too, same pattern as `ChatViewModel`, so the view can tell "you organized this" without a separate prop), `CreateTripViewModel`/`CreateTripPage` |
| UI | `ui/features/chats/view_models/` `/views/` | `MyTripsViewModel`/`MyTripsView` (Trips tab), `ChatViewModel`/`ChatView` — `ChatView` is body-only now (no `Scaffold`/`AppBar` of its own), embedded as a tab inside `TripConversationPage`; subscribes to `trip:$tripId` on `load()`, dedupes incoming publications by message id (own sent messages already arrive via the post-send REST reload), unsubscribes in `dispose()` (called explicitly from `ChatView.dispose()`, ChangeNotifier's `dispose` isn't auto-invoked by Flutter). `TripConversationPage` owns the shared `AppBar` (title tap → Trip Page) + `TabBar`/`TabBarView` wrapping `ChatView` and `TransportView`. |
| UI | `ui/features/transport/view_models/` `/views/` | `TransportViewModel` (carries `currentUserId` too, same pattern as `TripViewModel`/`ChatViewModel`)/`TransportView` — list of tiles (tap → detail bottom sheet, no button on the tile itself) + a FAB opening the add-offer sheet (type via `ChoiceChip`s, optional seats/details). The detail sheet has the Organizer row, the "Joined divers" list, and the Join/"Joined" chip/"Full" chip button. |
| UI | `ui/features/profile/views/` | `ProfileView` (guest placeholder or signed-in Overview + Airbnb-style settings rows — see Profile section), `EditProfilePage`, `LanguagePickerPage`, `NotificationsSettingsPage`, `AboutPage`, `LegalPage` |

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
- **Onboarding intro (done)**: `ui/core/branding/` holds the brand "B" logo mark as data, not an image asset — `logo_bubbles.dart` has the 24 circle centers/radii plus the 2 light-blue highlight arc paths, hand-transcribed from the brand SVG (`Logo.png`/`logo.svg`, 1024x1024 viewBox, background gradient identical to `AppGradients.brand`) so bubbles can be individually animated rather than drawn as a flattened image. `bubble_logo_painter.dart`'s `BubbleLogoPainter` draws a list of `RenderedBubble` (center/radius/opacity) plus the highlights (own minimal absolute-only M/C/Z SVG path parser — the two highlight paths don't use any other command type, so a full path grammar wasn't needed); `logo_layout.dart` has `fitLogoBox()` (centers/sizes the logo box on any screen) and `restingBubbles()` (the assembled, at-rest state, shared by the animated intro's final frame and the static splash). `IntroView`: a 2.6s bubble-rise/assemble phase (`AnimationController`) + 0.4s content fade-in (separate controller, starts on the first one's completion) — deliberately **not** shorter, since the "wall of bubbles rising past while ~24 peel off to assemble the letter" effect needs the room; a fast version only reads as a "collapse". Each of the 24 letter-bubbles gets random per-instance timing (`_TargetBubbleParams`: `tStart` 0.30–0.55, `assembleDuration` 0.35 — stays part of the general rising wall for a while before easing sideways into its exact target) so they don't all snap into place in lockstep; ~22 extra decorative bubbles (`_DecoBubbleParams`) never target anything, they just rise the full height of the screen (distance computed from actual `Size` at resolve-time so it scales across devices, not a fixed constant) and fade out only once comfortably above the top edge. Tap anywhere to skip straight to the assembled end state (`_bubbleController.animateTo(1)`). Content styling (`_IntroContent`) is deliberately **white/inverted**, not the app's default dark-on-light theme — text/buttons sitting on the dark `AppGradients.brand` backdrop read as near-invisible with the normal theme colors (this was an actual bug caught via simulator screenshot, not a hypothetical). `LoginSheet` (Google + Apple buttons) is a UI-only stub — Google shows "Coming soon", Apple is visible but disabled ("coming soon") pending App Store Connect registration; **Skip for now** is currently the only way past this screen into the app.
- **Still to redesign**: Profile's Certifications/Gear sub-screens (Overview is done — see Profile section above).

Only a light theme exists — Figma's Colors page doesn't specify a dark variant, so one hasn't been invented; add it if/when Figma defines one rather than guessing.

`ColorScheme` role mapping worth remembering if extending: `primary` = buttons/primary, `secondary` = text/secondary (used for `onSurfaceVariant` too, which is why `ListTile` subtitles pick up the muted tone automatically), `tertiary` = text/accent (same hex as semantic `info`), `surface` = surface/primary (white, cards), `scaffoldBackgroundColor` = bg/base (page background — deliberately distinct from `surface`), `scrim` = surface/overlay.

## Git workflow

- Final branch: **develop**
- New work happens on a feature branch off `develop`, not directly on `develop`.
- Merge the feature branch into `develop` locally (no PR), then push `develop`.
- Commit messages: short, e.g. "Added design system" — not multi-paragraph bodies.
- Code comments: one line max — what it is and why, not a paragraph.
