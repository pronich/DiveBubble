# DiveBubble Roadmap — post field-test (2026-08-24)

Source: first real-world test with actual trip participants (Aug 21–23 trip), partial
adoption but positive signal. Split into 3 independent tracks/branches so each can be built
and tested separately. Within a track, work top-down by priority — don't jump ahead.

**Process per track:** new branch off `develop` → plan (written, validated together before any
code) → implementation → testing (Nikolai on his iPhone; Claude runs the backend locally and
checks the app with `flutter analyze`) → commit → merge to `develop`.

---

## Track 1 — App: bugs & features

### Priority 1 — Bugs (done, 2026-08-24)

- [x] **Auth: mass logout (Aug 21→22)** — `getValidAccessToken()` in
      `app/lib/data/repositories/auth_repository.dart:162-185` treats *any* exception during
      token refresh (network blip, timeout, 5xx, connection reset) the same as "refresh token
      is invalid" and wipes the local session. TTLs themselves are fine (access 8h, refresh
      180d with rotation). Fix: only clear tokens on an actual 401/403 from the refresh
      endpoint; on network/5xx errors, keep the stored token and let the next call retry.
- [x] **Trip Past-status / feedback notification fires too early on multi-day trips** — both
      the client "Past" pill (`app/lib/ui/features/chats/views/my_trips_view.dart:232`) and the
      server feedback-prompt scan (`backend/internal/trip/repository.go:501`) key off
      `start_time` only, ignoring the existing nullable `end_date`. **Confirmed semantics**
      (Nikolai, 2026-08-24): no end_date → Past at end of start_date's calendar day; has
      end_date → Past at end of end_date's calendar day; feedback notification sent the
      following morning either way.
- [x] **Feedback prompt never sends a push notification** — confirmed gap. The scan job
      (`main.go:66-119`, `runFeedbackPromptScan`) inserts the system chat message and publishes
      it over Centrifugo (realtime, in-app only) but never calls `pushSvc.SendToUsers`, unlike
      regular messages (`routes_message.go:287`, `notifyNewMessage`). A tester who isn't
      actively in the Bubble at scan time never sees the prompt. Add push using the same
      pattern as `notifyNewMessage`.

### Priority 2 — Chat/trip quality-of-life

- [ ] Reply-to-message
- [ ] Long-press menu: Reply / Copy text / Block — extend the existing report/block sheet
      (`chat_view.dart:1014`), which today only fires on other people's messages
- [ ] Download/save a received photo to the phone's photo library (confirmed fully missing —
      no `gal`/`image_gallery_saver`/`share_plus` dependency)
- [ ] Edit trip from mobile (confirmed absent — `app/` has create-only; `CLAUDE.md`'s
      "Implemented" list is stale on this point, fix the doc once this ships)

### Priority 3 — Growth (incl. Private trips)

- [ ] Share trip link + join trip by link
- [ ] Private trips — reuse the existing booking-code join scheme for the link/gate mechanism
      rather than building a separate visibility system
- [ ] Native OS share-sheet integration (share photos from Photos app straight into a Bubble)

### Priority 4 — Chat richness

- [ ] @ mentions/tagging (people + dive center) — generalize the existing hardcoded
      `@DiveCenter` chip (`chat_view.dart:67-69,377-390`) into real autocomplete mentions
- [ ] Emoji reactions
- [ ] Multiple photos in one message, small grid view — note: `ChatMessage` currently has
      singular attachment fields, not a list; this is a data-model change (1:1 → 1:many), not
      just UI
- [ ] Video attachments — confirmed unsupported today (attachment type hard-typed as
      `'image' | 'pdf'`). Scope file-size limits and client-side compression before building.

### Priority 6 — New features

- [ ] Dive logs + automatic dive counts (Logbook)
- [ ] Share expenses (Splitwise-style)
- [ ] Delete/Archive old trips (bubbles)

---

## Track 2 — Small-screen adaptation

Layout issue, not a logic bug — separate branch so it can be tested independently on an
SE-class device.

- [ ] **Save button unreachable on level-select onboarding screen** — confirmed structural bug.
      `app/lib/ui/features/onboarding/views/certifications_onboarding_page.dart:48-111` has a
      fixed `Column` with no `SingleChildScrollView`/`ListView`; on a short screen with
      keyboard/safe-area insets the content overflows with nothing to scroll. Fix: wrap in
      `SingleChildScrollView`.
- [ ] **Booking code input renders oddly on small screens** — no structural bug found on static
      read (`join_by_code_dialog.dart:56-87` is a plain `AlertDialog`/`TextField`). Needs a live
      repro on an SE-class simulator before picking a fix.
- [ ] Audit other onboarding/creation screens for the same missing-scroll pattern proactively,
      since it's already shown up once — likely systemic rather than a one-off.

---

## Track 3 — Admin account

Own branch, own pass — deliberately not mixed with the App track. Bug list first; broader
feature/rework scope to be defined once these are closed (Nikolai reviewing separately).

- [ ] **Day count displays wrong** — confirmed bug, root cause found.
      `admin/lib/ui/features/trips/views/trip_detail_page.dart:421-425`:
      `end.difference(trip.startTime).inDays + 1` truncates because `startTime` carries a real
      time-of-day while `endDate` is UTC-midnight-normalized. Fix: diff calendar dates (strip
      time from `startTime` first), not raw `DateTime.difference`.
- [ ] **Time not saved on edit** — code review of `create_trip_page.dart` and
      `trip_api_service.dart` found the client wiring correct end-to-end. **Needs a precise
      repro** (which field, which screen, exact steps) before further digging — may be
      backend-side or already non-reproducible.
- [ ] **Dive saving behaves oddly** — no separate per-dive entity/screen exists in `admin/`
      today; "dive" can currently only mean the `diveCountMin`/`diveCountMax` fields, where no
      obvious bug was found. **Needs a precise repro.**
- [ ] Broader admin rework — scope TBD after the above

---

## Idea backlog (not scheduled — revisit later)

- Translate into my language — good candidate for first paid feature; start with on-demand
  per-message translate (long-press → "Translate") rather than full auto-translate, to de-risk
  quality/cost/latency. Needs a visible "translated" indicator given this is dive-trip
  coordination.
- Feature toggles at trip creation (e.g. disable Buddy module) — adds conditional-UI complexity
  everywhere; wait for an explicit demand signal before building
- Share location within a bubble — user-flagged as non-priority
