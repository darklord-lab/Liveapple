# satyam2 — Classora Fix + Redesign + Cleanup Spec

Owner: Satyam. Read this file fully before touching code. Also read /docs (RULES.md, DESIGN.md, ARCHITECTURE.md, MEMORY.md, TASKS.md).

## 0. Ground rules
1. Main client is **Flutter** (apps/mobile_flutter). Backend: Express + Prisma + Socket.IO, **local SQLite stays the runtime DB**. Do NOT migrate to Cloudflare D1 and do NOT run wrangler/D1 commands in this pass.
2. Cloudflare is used only as a **Tunnel** for the API/Socket.IO (https URL). Video goes through **LiveKit Cloud** (wss URL from env). Nothing may be hardcoded to localhost / 10.0.2.2 / LAN IPs. App uses one configurable base URL (Server Settings) for REST + Socket.IO, and the LiveKit URL returned by the token endpoint.
3. Do NOT touch the whiteboard engine internals (Flutter `digital_board.dart`, web `DigitalBoard.tsx`). Only change where and for whom it is shown.
4. Label every result: WORKING (you ran it, paste output) / PARTIAL / STUB / BROKEN / MISSING / NOT VERIFIED. Never write WORKING for something you did not run. UI text such as "LiveKit SFU Stream Active" must never be a hardcoded string; it must reflect real state.
5. No new product features beyond this file. Ask before adding any package; log reason in docs/MEMORY.md.
6. Work in the phase order below. After each phase run `flutter analyze`, `flutter test`, `npm test` and fix regressions before moving on.

---

## PHASE A — Safe cleanup (do this first)

Goal: a lean repo where Flutter + API + docs are the main things.

A1. Produce `docs/CLEANUP_REPORT.md` listing every file/folder removed or moved, with a one-line reason and grep evidence (nothing imports it).

A2. Delete (verified unused only):
- `apps/api/src/mockData.ts` and any other orphaned mock/prototype files (prove with grep).
- Old APKs in repo root (`Classora.apk`, `Classora-Flutter.apk`) and any build outputs, `.dart_tool`, `build/`, logs, `*.log`, `.DS_Store`, temp/scratch scripts.
- Duplicate or stale docs that contradict /docs.
- Leftover audit/e2e scripts that write junk into the dev database (keep them only if moved under `apps/api/src/scripts/` and pointed at a test DB, see Phase B).

A3. Move (do NOT delete) to `_archive/` using `git mv`: the old React portals (apps/admin, apps/teacher, apps/student, apps/marketing, apps/web) if they are not needed by the Flutter app or the API. Keep `shared/DigitalBoard.tsx` where it is. Update root `package.json` scripts and workspaces so `npm install` and `npm run dev:api` still work.

A4. Never delete: prisma migrations/schema/seed, /docs, whiteboard files, `infra/`, `builds/README.md`, `.env.example`.

A5. Make sure `.gitignore` covers: .env, *.apk, builds/*.apk, build/, .dart_tool/, node_modules/, *.db, *.db-journal, *.log, .wrangler/.

A6. Final repo structure should look like:
```
Liveapple/
├── apps/
│   ├── api/
│   └── mobile_flutter/
├── shared/            (DigitalBoard.tsx only if still referenced)
├── infra/
├── docs/
├── builds/            (README.md tracked, apks ignored)
├── _archive/          (old web portals, moved not deleted)
└── satyam2.md
```

---

## PHASE B — Data hygiene (root cause of junk names)

Problem: batch names like "Math Champions 1791561500597", "P5-Quantum Mechanics...", "Live Test Batch 17915..." are leftovers from automated tests and the audit runner writing into the dev database.

B1. Tests and audit scripts must use a **separate SQLite file** (e.g. `DATABASE_URL=file:./test.db` created fresh per run, deleted after). They must never touch `dev.db`.
B2. Add `npm run db:reset-demo` that wipes the dev DB and seeds a clean, realistic demo set (idempotent):
- Institute: Apex IIT-JEE & Medical Academy
- Admin: Dr. S. N. Roy; Teachers: Prof. Rajesh Sharma (Physics), Prof. Anita Verma (Maths)
- Students: Aarav Patel, Priya Sharma, Rohan Verma, Neha Singh, Karan Mehta, Isha Gupta (real names, not "Student 1/2/3")
- Batches with clean names: "Class 12 JEE — Physics", "Class 12 JEE — Maths", "Class 11 NEET — Chemistry"
- All six students enrolled in the right batches (at least two students in BOTH Physics and Maths batches), timetable slots for Mon-Fri, and a few classes scheduled for today in the correct timezone.
- Strong demo passwords printed once at the end of the script, marked TEST ONLY, not stored in docs.
B3. Timezone rule: store UTC, display in Asia/Kolkata (configurable). Test across midnight.
B4. Add a `DEMO_MODE` guard: reset script refuses to run if `NODE_ENV=production`.

---

## PHASE C — Bug fixes (each needs a regression test where possible)

### C1. Batch dropdown overflows in "Add Timetable Slot"
Symptom: long batch name runs past the field edge.
Fix: `DropdownButtonFormField` with `isExpanded: true`, item `Text` with `maxLines: 1` + `TextOverflow.ellipsis`, selected-item builder also ellipsized. Show batch name + subject on two lines in the open menu. Same fix everywhere a batch/subject name is shown in a constrained row (cards, headers, chips, notifications). Add a widget test that renders a 90-character batch name at 320dp width with no overflow exception.

### C2. "Open Live Teaching Canvas" card is unwanted
- Remove that card from the Teacher "Live Classes" tab and from any Student screen.
- The whiteboard is available **only inside a live class**, and only the **teacher (host)** gets drawing tools. Students get **view-only** whiteboard (synced), no tools, unless the teacher explicitly grants a student permission (grant/revoke from the participants sheet; enforce on the server in the socket handler, not just in the UI).
- Remove the "Whiteboard" button for students from the student bottom bar; for students it becomes an auto-shown "Board" view when the teacher opens it.
- Offline/solo whiteboard for teachers is out of scope; remove the entry point.

### C3. Participant count and list mismatch
Symptom: dashboard says 4 participants (3 students + teacher), the participants sheet shows 3, and the grid shows different people.
Root cause to verify: three different sources (socket room state, LiveKit room state, UI tiles).
Fix: **single source of truth = LiveKit participants** (room.remoteParticipants + local), keyed by identity (userId). De-duplicate if the same user joins from two devices (show one tile, mark "2 devices" or keep the newest). Count badge, participants sheet and grid must all read from the same provider. Show real names from token metadata (name, role), not "Student 1". Sort: host first, then raised hands, then alphabetical. Add a test for join/leave/duplicate identity.
Also decide and implement the "who can see whom" rule: students see the teacher + active speaker + a paginated grid (max 9 tiles/page); teacher sees all.

### C4. Camera/mic shown ON while actually OFF (and no real video visible)
Symptoms: tile shows green mic and "Stop Video" although camera/mic are off; the stage shows an avatar and the string "LiveKit SFU Stream Active".
Fix:
- Derive UI state ONLY from LiveKit track state: `participant.isMicrophoneEnabled()`, `isCameraEnabled()`, `TrackPublication.muted`, `isSpeaking`. No local boolean toggles that can drift.
- Render real video with `VideoTrackRenderer` when a camera/screen track is subscribed and not muted; otherwise avatar with initials. Mic icon: red-slash when muted, animated ring when speaking.
- Remove the hardcoded "LiveKit SFU Stream Active" text; replace by a connection badge that reflects `room.connectionState` (Connecting / Connected / Reconnecting / Disconnected) and network quality.
- Students join with mic/cam OFF by default and `canPublish` false (publish allowed only after teacher grants "allow mic/cam").
- Teacher mute-all must update every tile within ~1 second (event driven).
- Verify the app is truly connected to LiveKit Cloud: log `room.connectionState`, the wss URL host, and participant count at join. If it is not connected (mock/stub), say STUB and wire it for real.
- Requires physical devices: you cannot verify camera/mic yourself; mark those NOT VERIFIED and rely on unit/widget tests with a fake room.

### C5. Chat messages not readable / not delivered
Symptom: teacher sent "hii"; the bubble shows white text on a light background (invisible). A fake "System Gateway" welcome message is shown.
Fix:
- Proper bubble theming: own messages right aligned in primary color with white text; others left aligned on surface color with onSurface text. Contrast must be AA in both light/dark. Show sender name + role badge + time.
- Remove the fake "System Gateway ... LiveKit SFU media path connected" message. System messages allowed only for real events (X joined/left, class ended) in muted italic style.
- Verify delivery end to end: teacher -> student and student -> teacher through the socket room for that class. Persist messages in `ChatMessage` and load the last 50 on join. Unread badge on the Chat button. Add a socket integration test (two clients).
- Chat should be a bottom sheet / side panel that does not push the video off screen; keyboard-safe.

### C6. Student schedule missing classes
Symptom: Monday has 3 classes (2 Maths, 1 Physics) but the student sees only Physics; a newly scheduled live class does not appear for the student.
Root causes to check and fix (report which were true):
1. Student not enrolled in the Maths batches or enrollment status is not ACTIVE (check seeds and the enrollment filter).
2. Schedule query filters by wrong field (batch vs teacher), missing `OR` over multiple batches, pagination limit, or a date window that excludes today.
3. Timezone: slot minutes vs LiveClass `scheduledAt` UTC converted incorrectly, causing the class to fall on a different day.
4. Student "Live & Upcoming" tab only polls once. Add realtime update via the `user:<id>` socket room when a class is scheduled/started/cancelled, plus pull-to-refresh and a 10 s fallback poll.
Acceptance: seed a student enrolled in 2 batches; a teacher creates a class for each; the student sees both under the correct day/time, and a class created while the student's app is open appears within 10 s. Add API tests (schedule endpoint) and a Flutter provider test.

### C7. Other issues seen in the screenshots
- Teacher day tabs show "Tue (0)" while the schedule has entries elsewhere: counts must match the API.
- Scheduled classes list shows past/stale test classes (9 Oct ...). Hide ended/past-unstarted classes from the default view; add a "Past" filter.
- Titles truncated ("P5-Quantum Mechan...") — use two-line titles on cards with the batch on the second line.
- A LIVE class stays "LIVE" if the teacher disconnects: add an auto-end/timeout rule (e.g. no host for 10 min -> ended) and an "Enter Room" rejoin.

---

## PHASE D — UI redesign (Flutter)

The current UI is cluttered and inconsistent. Rebuild the presentation layer cleanly while keeping the working API/providers.

### D1. Architecture (feature-first, Riverpod, go_router)
```
lib/
├── core/
│   ├── theme/        (tokens, light+dark ThemeData, text styles)
│   ├── widgets/      (AppCard, PrimaryButton, SecondaryButton, StatusChip, EmptyState,
│   │                  ErrorState, LoadingSkeleton, SectionHeader, UserAvatar, AppScaffold)
│   ├── network/      (dio, interceptor, base URL from settings)
│   ├── router/       (go_router, role guards, deep links)
│   └── utils/        (time/timezone, formatters)
├── features/
│   ├── auth/ settings/(server URL)  admin/  teacher/  student/
│   ├── timetable/  batches/  live_class/  chat/  notifications/
│   └── each: data/ domain/ presentation/
└── main.dart
```
No business logic in widgets. Every list has loading / empty / error states. No duplicate screens or dead files (run `dart fix` and remove unused code).

### D2. Design tokens (from docs/DESIGN.md)
Primary Indigo #4F46E5, Live red #DC2626, success #16A34A, warning #D97706, bg dark #0F172A / card #1E293B, bg light #F8FAFC. Font Inter. Radius 12 cards, 999 pills. Spacing 4/8/12/16/24. Minimum touch target 48dp. Light and dark themes; the live class screen is always dark. Remove excess glassmorphism, glows and heavy borders; use flat cards with subtle elevation.

### D3. Navigation and screens
- **Student** bottom nav: Home · Schedule · Batches · Learn (recordings, homework, tests) · Profile.
  - Home: big "LIVE NOW" card with Join if any, else "Next class" card; today's classes list; quick tiles for homework/test due.
  - Schedule: week strip + day agenda (all enrolled batches).
  - No whiteboard entry anywhere.
- **Teacher** bottom nav: Home · Timetable · Batches · Students · Profile.
  - Home: Today's classes with **Go Live**/**Enter Room**; stats (students, classes this week). Learning modules (Assignments, CBT Tests, Recordings) as a compact grid, not a banner.
  - Timetable: week strip, add slot bottom sheet (fixed overflow), conflict message inline.
  - Batches: list, join code + QR share, student list, pending approvals.
- **Admin** bottom nav: Overview · Teachers · Batches · Fees · Settings. Teachers: list, search, add single/bulk, invite code copy/share, suspend.
- **Login**: clean card, role-agnostic; remove the demo-account chips from release builds (show only when `DEMO_MODE` build flag is on). Server Settings (gear) with Test connection.
- Notifications screen with deep links. Profile with logout and change password.

### D4. Live classroom (Meet/Zoom-like)
- Top bar: class title (ellipsis) · LIVE badge · timer · connection/network badge · (teacher) End class.
- Stage: teacher video or shared screen or whiteboard (teacher chooses); participants strip/grid below; teacher PiP draggable when whiteboard/screen is on stage.
- Bottom control bar: Mic · Camera · Share screen (teacher) · Board (teacher only draws; students view) · Chat (unread badge) · People · More (raise hand for students; mute-all, lock room for teacher) · Leave.
- People sheet: real names, role, mic/cam state, hand-raised first; teacher actions per student: mute, allow mic/cam, allow board, remove. Count = LiveKit participants.
- Landscape support; keep screen awake; reconnect banner; permissions with rationale before join; pre-join screen with camera preview and mic toggle (students default off).
- Polls and doubts accessible from More, not cluttering the main bar.

### D5. Quality
- Widget tests: long text overflow at 320dp for every list/card/dropdown; goldens optional.
- Accessibility: semantics labels on icon buttons, contrast AA, text scale 1.3 without overflow.
- Run on a small phone size (360x640) and a tablet size.

---

## PHASE E — Build and handover
E1. `flutter analyze` (0 issues), `flutter test` (all pass), `npm test` (all pass, using the test DB).
E2. Build ONE universal release APK into `builds/Classora-<yyyyMMdd-HHmm>.apk`, update `builds/README.md` (version, commit, SHA-256, default URLs). Server URL stays editable in-app.
E3. Update `docs/TASKS.md`, `docs/MEMORY.md` (decisions, known issues, session log), write `docs/CLEANUP_REPORT.md`.
E4. Final report format:
1. Table: item | label | evidence for every item in Phases A-D (C1-C7, D1-D5).
2. Raw outputs of analyze/test runs.
3. Root cause found for C3, C4, C5, C6 (what exactly was wrong).
4. List of things NOT VERIFIED (real camera/mic, screen share, push) and why.
5. Exact commands: reset demo data, start API, start tunnel, build APK.
Then STOP.

---

## Manual test checklist for Satyam (2 phones, after the new APK)
1. Login as teacher on phone A and as student on phone B (server URL set in gear icon, Test connection passes).
2. Add timetable slot with a very long batch name: no overflow.
3. Teacher home has no "Open Live Canvas"; student has no whiteboard entry.
4. Teacher schedules 2 classes (Physics + Maths) for the same day: student sees both; a class scheduled while the student app is open appears within 10 s.
5. Teacher Go Live; student joins. Participants count equals tiles equals people list.
6. Camera/mic off on teacher: tiles show muted state correctly; turn on: real video and audio reach the student.
7. Teacher sends a chat message: readable on both phones, delivered both ways.
8. Teacher opens the board: student sees it live (view-only). Share screen on Android works.
9. Mute all / remove participant / lock room work.
10. End class; attendance shows.
