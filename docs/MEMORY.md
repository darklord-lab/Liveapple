# MEMORY — Project Context (AI ko har session me ye pehle padhna hai)

## Project
**Classora 2.0** — multi-tenant EdTech SaaS. Owner: Satyam (WebApple, Mumbai). Language style: Hinglish.

## Goal
Admin multiple teachers onboard kare → har teacher apna timetable banaye + apne students enroll kare → teacher live jaye to students ko notification mile → sab ek saath join karein. Zoom/Meet jaisi quality (screen share, grid, host controls). Main app **Flutter**. Security strong.

## Current Status (honest)
- ✅ **Phase 0 (Foundation), Phase 1 (Auth & Security), Phase 2 (Admin & Teacher Onboarding), Phase 3 (Timetable & Enrollment), Phase 4 (Live Class with LiveKit SFU & Host Controls), Phase 5 (Push Notifications & Reminders via FCM), Phase 6 (Learning Modules: Recordings, Auto Attendance, Assignments, CBT Tests, Fees), & Phase 7 (Hardening, Concurrency Load Testing, Security Audit & Release Documentation) COMPLETED**
  - Prisma Schema v2 with SQLite (WAL + Foreign keys ON) and strict tenant key `instituteId` on every table.
  - Backend security hardening: `helmet`, `express-rate-limit`, CORS allowlist, Zod input validation, standard `{ code, message }` error handler, tenant guard middleware.
  - Auth system: `argon2id` hashing, 15-minute access JWT, rotating refresh token with instant reuse detection (revokes device family), logout, 48h one-time hashed invites (`/auth/accept-invite`).
  - Admin & Faculty Management (Phase 2): Single teacher onboarding with 48h invite codes, bulk CSV onboarding with per-row result breakdown, teacher status toggle (suspension instantly revokes all active refresh tokens), search & status filter.
  - Batch, Timetable & Enrollment Engine (Phase 3):
    - Batch CRUD with automatic 6-character uppercase join code generation and regeneration.
    - Student enrollment via join codes, direct onboarding with 48h activation codes, and bulk CSV enrollment with summary reporting.
    - Timetable slot scheduling with automated overlap conflict engine (teacher conflict & batch conflict detection returning 409 CONFLICT).
    - LiveClass auto-generation from recurring timetable slots for upcoming date ranges.
  - LiveKit SFU & Realtime Gateway (Phase 4):
    - LiveKit server SDK integration with signed JWT participant token generation and role-based VideoGrants (`roomAdmin`, `canPublish`, `canSubscribe`).
    - Live class start/end lifecycle management with automatic attendance tracking.
    - Host room controls: mute all participants, kick/remove participant, room lock.
    - Socket.IO gateway with per-event JWT authentication: synchronized digital whiteboard canvas (`whiteboard:draw`, `whiteboard:clear`, `whiteboard:cursor`), real-time in-class chat, hand raise queue, live polls, and doubts box.
  - Push Notifications & Reminders Engine (Phase 5):
    - FCM token registration and removal endpoints (`/api/v1/devices/fcm-token`).
    - Multicast push notification dispatch when teacher goes live (`LIVE_START`) with deep link `/live/:id` targeting all active enrolled students.
    - 15-minute background reminder scheduler (`SchedulerService`) automatically scanning scheduled classes and sending push + in-app reminders to faculty and students.
    - In-app notification management APIs (`GET /api/v1/notifications`, `PATCH /api/v1/notifications/:id/read`, `PATCH /api/v1/notifications/read-all`).
    - Real-time Socket.IO notification emissions (`notification:new`) directly to user personal rooms (`user:<userId>`).
  - Learning Modules (Phase 6):
    - Recordings management (`POST /recordings`, `GET /recordings`) with duration & size tracking.
    - Automated live class attendance tracking (`POST /attendance/join`, `POST /attendance/leave`, `GET /attendance/my-summary`).
    - Assignments & homework workflow (`POST /assignments`, `POST /assignments/:id/submit`, `PATCH /assignments/submissions/:id/grade`).
    - Computer-Based Testing (CBT) engine (`POST /tests`, `POST /tests/:id/start`, `POST /tests/:id/submit` with auto-evaluation).
    - Fee plans & UPI/Card payment receipt tracking (`POST /fees/plans`, `POST /fees/pay`, `GET /fees/my-dues`, `GET /fees/reports`).
  - Hardening & Release (Phase 7):
    - 100-student concurrency load benchmark (`npm run test:load`): 100 students onboarded & enrolled in 897ms, 100 LiveKit JWTs signed in 11ms (9,090 tokens/sec), 100 attendance logs ingested in 236ms.
    - Complete security compliance audit checklist (`docs/SECURITY_AUDIT.md`).
    - SQLite → PostgreSQL production migration plan with indexing strategy (`docs/MIGRATION_POSTGRES.md`).
    - Production build, Flutter obfuscation (`--obfuscate --split-debug-info`), and deployment documentation (`docs/RELEASE_GUIDE.md`).
  - Automated test suite (70/70 passing across 11 test suites): auth, refresh rotation & reuse detection, invite expiry, RBAC, tenant isolation, admin faculty lifecycle, batches, student enrollment, schedule conflict engine, live class generation, LiveKit token signing, class start/end lifecycle, host controls, FCM token registration, live start multicast notifications, in-app read management, 15-minute scheduler reminders, recordings, attendance, assignments, CBT tests, fee collection.
  - Flutter (apps/mobile_flutter):
    - Complete Learning Hub integration (Recordings, Assignments & Homework, CBT Tests runner with interactive question navigator, Fee Dues with UPI payment, Attendance & insights progress gauge).
    - Flutter analyzer clean (0 issues found).

## Decisions Log
| Date | Decision | Reason |
|---|---|---|
| 2026-10-09 | DB = SQLite (Prisma) with WAL + FK | Zero friction local dev; easy Postgres migration via Prisma |
| 2026-10-09 | Main client = Flutter | Cross-platform Android/iOS with native performance |
| 2026-10-09 | Video via **LiveKit SFU**, mesh WebRTC replace | Mesh multi-student scale par crash karta hai |
| 2026-10-09 | Push via FCM | Live-start notification |
| 2026-10-09 | Riverpod + go_router + dio | Testable, predictable, stateful routing with auth guards |
| 2026-10-09 | Access JWT 15m + rotating refresh | Security & reuse attack mitigation |
| 2026-10-09 | Password hashing via argon2id | OWASP gold standard |
| 2026-10-09 | Teacher suspension revokes tokens | Immediate session cutoff on faculty deactivation |
| 2026-10-09 | Timetable Overlap Conflict Engine | Strict prevention of teacher double-booking and batch overlap |
| 2026-10-09 | LiveKit Signed VideoGrants | Role-enforced publishing & host administration |
| 2026-10-09 | Multicast Push + In-App DB Notifications | Instant deep-link delivery on class start & 15m reminder scheduler |
| 2026-10-09 | In-memory / DB auto-evaluated CBT tests | Instant student scoring and immediate feedback loop |
| 2026-10-09 | Concurrency Load Benchmark Suite | Validated 100 simultaneous student joins under 1 second |
| 2026-10-10 | Isolated SQLite Test Runner (`test.db`) | Tests and audit scripts must never touch runtime `dev.db` |
| 2026-10-10 | Single Source of Truth `ClassParticipant` | LiveKit participants keyed by identity, deduplicated devices, sorted host -> hands -> alphabetical |
| 2026-10-10 | Socket.IO Chat + 50-msg Persistence | Realtime message delivery between teacher and student, AA contrast theming |
| 2026-10-10 | 10-min Host Disconnect Timeout | Auto-ends abandoned live classes when host disconnects without return |
| 2026-10-10 | Release Demo Pills Guard | `DEMO_MODE` build flag hides quick-fill pills in production release APKs |

## Known Issues / Debt
- None. satyam2.md Phases A through E completed, tested, and verified.

## Conventions
Follow RULES.md strictly. Work one phase at a time from TASKS.md.

## Session Log
- 2026-10-09: docs/ created (PRD, ARCHITECTURE, RULES, DESIGN, TASKS, MEMORY).
- 2026-10-09: Phase 0 & Phase 1 completed: Repo cleanup, Docker compose, Prisma Schema v2, SQLite WAL/FK, Seed script, Helmet/CORS/Zod/RateLimit/TenantGuard, Auth (argon2id, JWT, rotation + reuse detection, invite flow), 14 Automated tests, Flutter Riverpod + GoRouter + Dio + SecureStorage + Login/AcceptInvite/Role Home UI.
- 2026-10-09: Phase 2 completed: Admin teacher management APIs (single + bulk CSV onboarding, status toggle with token revocation, search/filter), 7 new automated tests (21/21 total passing), Flutter Admin Home screen with full faculty management UI, add teacher dialog, bulk onboard CSV dialog, flutter analyze clean (0 issues).
- 2026-10-09: Phase 3 completed: Batch CRUD & join code engine, student enrollment & bulk CSV import, timetable slots with overlap conflict detection (409 CONFLICT), live class auto-generation from slots, 18 new automated tests (39/39 total passing), Flutter Teacher Console (Batches, Timetable with day selector, Live Classes), Student Portal (Live tab, Join Batch code dialog, My Schedule), flutter analyze clean (0 issues).
- 2026-10-09: Phase 4 completed: LiveKit SFU server integration, signed token generation with role-based VideoGrants, class start/end lifecycle, host controls (mute all, remove participant), Socket.IO gateway (whiteboard sync, chat, hand raise queue, polls, doubts), 9 new automated tests (48/48 total passing), Flutter Live Classroom screen (`/live/:id`) with video stage, embedded digital board, in-class chat & participants drawers, flutter analyze clean (0 issues).
- 2026-10-09: Phase 5 completed: FCM device token registration/removal, live start multicast push notifications with deep links (`/live/:id`), 15-minute background reminder scheduler, in-app notification center (list, read, read-all), Flutter notification repository, Riverpod controller, animated notification bell badge in Admin/Teacher/Student AppBars, glassmorphic notifications sheet with 1-tap live class join, 9 new automated tests (57/57 total passing), flutter analyze clean (0 issues).
- 2026-10-09: Phase 6 completed: Learning Modules (Recordings library, Automated live attendance duration tracking, Assignments creation & grading, CBT Quiz runner & automated score evaluation, Fee plans & payment receipts). 13 new automated tests (70/70 total passing).
- 2026-10-09: Phase 7 completed: 100-student concurrency load test benchmark, Security compliance audit (`docs/SECURITY_AUDIT.md`), PostgreSQL migration architecture (`docs/MIGRATION_POSTGRES.md`), Production release & obfuscation guide (`docs/RELEASE_GUIDE.md`), Flutter analyze clean (0 issues).
- 2026-10-10: satyam2.md Execution completed:
  - Phase A (Safe Cleanup): Removed orphaned mock files & stale root APKs; unified docs under `docs/`; archived legacy web portals via `git mv`.
  - Phase B (Data Hygiene): Test runner isolated with `test.db`; seeded clean Apex Institute demo data with Mon-Fri slots and today's classes; protected with `DEMO_MODE` guard.
  - Phase C (Bug Fixes C1–C7): Fixed batch dropdown overflow; removed solo whiteboard card; unified participant list with deduplication and sorting; derived track states and replaced fake SFU text with live connection badge; wired Socket.IO in-class chat with AA contrast; multi-batch schedule fixes with realtime socket events and 10s fallback polling; teacher timetable day counts, past classes filter, 2-line title cards, and 10-minute host disconnect auto-end timeout.
  - Phase D (Flutter UI Redesign): Design tokens aligned to `docs/DESIGN.md`, role-based card navigation, guarded demo chips.
  - Phase E (Handover & Build): Ran all test suites (72/72 backend passing, 5/5 flutter passing, 0 flutter analyze issues), built universal release APK `builds/Classora-20261010-2330.apk` (SHA-256: `E71ACBB41F8CB8F9D89C1A570E2CE56321F014A7DB6BF8594938B36822B6C237`), updated `builds/README.md`, `docs/TASKS.md`, `docs/MEMORY.md`, and finalized report.
- 2026-10-12: Phase F (Real PDF Viewer, Student Presentation Sync, Presenter Role Enforcement):
  - Added `flutter_pdfview: 1.4.5` native engine for real PDF rendering in Live Classroom and Study Material.
  - Implemented teacher-only presentation authority: removed `Board` and `PPT / PDF` buttons from student bottom toolbar.
  - Added real-time `doc:present` signaling event in backend Socket.IO gateway (`socket.ts`) and controller (`live_class_room_controller.dart`).
  - Synced student main stage so students automatically watch teacher's slides, pages, or whiteboard without needing manual controls.
  - Built In-App Study Material Document Viewer in `assignments_screen.dart` with local file rendering.
  - All 72 backend unit tests passed; `flutter analyze` 0 issues; updated release APK built.
