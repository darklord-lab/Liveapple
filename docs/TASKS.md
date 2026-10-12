# TASKS — Classora Roadmap

Legend: `[ ]` todo · `[x]` done · `[~]` in progress

## Phase 0 — Foundation
- [x] Repo cleanup: ek `docs/` folder, `.env.example`, apk files git se hatao
- [x] `infra/docker-compose.yml` (api + livekit)
- [x] Prisma schema v2 (Institute, User, Invite, Batch, Enrollment, TimetableSlot, LiveClass, RefreshToken, Notification, AuditLog)
- [x] SQLite WAL + FK on, seed script
- [x] Global middleware: helmet, rate-limit, CORS, Zod, error format

## Phase 1 — Auth & Security
- [x] Login / refresh rotation / logout
- [x] argon2id password hashing
- [x] RBAC + tenant guard middleware
- [x] Invite flow (create, email/SMS later, accept, set password)
- [x] Flutter: secure storage, dio interceptor, login + accept-invite screens

## Phase 2 — Admin & Teacher Onboarding
- [x] Admin: add teacher (single)
- [x] Admin: bulk CSV onboard + result report
- [x] Admin: suspend/reactivate teacher
- [x] Flutter admin screens (Teachers list, Add, Bulk)

## Phase 3 — Timetable & Enrollment
- [x] Batch CRUD + join code/QR
- [x] Student enroll (code, manual add, CSV) + approve flow
- [x] Timetable slots CRUD + conflict check
- [x] Generate upcoming LiveClass from recurring slots
- [x] Flutter: teacher timetable UI, student timetable UI

## Phase 4 — Live Class (Zoom/Meet-like)
- [x] LiveKit server setup + token endpoint
- [x] Flutter `livekit_client`: join, publish cam/mic, subscribe
- [x] Screen share (Android foreground service + iOS broadcast extension)
- [x] Grid / speaker layout, pagination
- [x] Host controls (mute all, remove, lock)
- [x] Reconnect + network quality UI
- [x] Integrate existing whiteboard in live screen (Socket.IO room)
- [x] Chat, raise hand, polls, doubts (port from existing gateway)

## Phase 5 — Notifications
- [x] Firebase project + FCM in Flutter (Android/iOS)
- [x] Save device tokens, topic/multicast on `start`
- [x] Deep link to live screen
- [x] Scheduler: 15-min reminder

## Phase 6 — Learning Modules
- [x] Recording (LiveKit Egress) + library
- [x] Attendance auto from join/leave
- [x] Assignments + submissions
- [x] Tests (CBT) + results
- [x] Fees (Razorpay/UPI)

## Phase 7 — Hardening & Release
- [x] Security review checklist (RULES.md) (docs/SECURITY_AUDIT.md)
- [x] Load test: 100 students 1 class (apps/api/src/scripts/load_test_100_students.ts)
- [x] Crashlytics + logging (docs/RELEASE_GUIDE.md)
- [x] Play Store / App Store build, obfuscation (docs/RELEASE_GUIDE.md)
- [x] SQLite → PostgreSQL migration plan (docs/MIGRATION_POSTGRES.md)

## satyam2.md Execution Phases (Audit & Fix Protocol)
- [x] **Phase A — Safe Cleanup**:
  - Deleted orphaned `apps/api/src/mockData.ts` and root stale APKs.
  - Byte-parity verified documentation merged into `docs/` (single source of truth).
  - Legacy React portals (`apps/admin`, `apps/teacher`, `apps/student`, `apps/marketing`, `apps/web`) moved to `_archive/` via `git mv`.
  - Created `docs/CLEANUP_REPORT.md` and `builds/README.md`.
- [x] **Phase B — Data Hygiene**:
  - Isolated SQLite test database (`test.db`) created for tests and audit runner; `dev.db` protected.
  - Added `npm run db:reset-demo` with `DEMO_MODE` production guard.
  - Seeded clean demo institute (Apex IIT-JEE & Medical Academy), 2 faculty (Prof. Rajesh Sharma, Prof. Anita Verma), 6 named students, 3 clean batches, Mon-Fri slots, and today's scheduled classes.
- [x] **Phase C — Bug Fixes (C1–C7)**:
  - C1: Fixed batch dropdown overflow (`isExpanded: true`, 2-line batch items, widget test at 320dp passing).
  - C2: Removed solo whiteboard entry; restricted whiteboard to inside live classroom (teacher draws, student view-only).
  - C3: Single source of truth participant list (`ClassParticipant.deduplicateAndSort`), tested deduplication, host-first and alphabetical sorting, max 9 student grid.
  - C4: UI track states derived from participant model, students default mic/cam OFF; connection status badge reflects `connectionState`; removed fake "LiveKit SFU Stream Active".
  - C5: In-class chat wired to Socket.IO gateway with AA contrast bubble theming, unread counter, and 2-client automated test passing.
  - C6: Multi-batch student schedule fixed on backend; realtime socket listener + 10s fallback polling + pull-to-refresh on student tab.
  - C7: Day tab slot counts synced, past classes filter toggle added, 2-line class titles, and 10-minute host disconnect auto-end timeout.
- [x] **Phase D — Flutter UI Redesign**:
  - Aligned tokens to `docs/DESIGN.md` (Indigo `#4F46E5`, Live Red `#DC2626`, Dark `#0F172A`, Light `#F8FAFC`, Inter typography, radius 12/999).
  - Clean role-based navigation and cards; demo login chips guarded with `DEMO_MODE` flag; server settings with test connection.
- [x] **Phase E — Handover & Build**:
  - Verified `flutter analyze` (0 issues), `flutter test` (5/5 passing), `npm test` (72/72 passing).
  - Generated universal release APK: `builds/Classora-20261010-2330.apk`.
  - Updated `builds/README.md`, `docs/MEMORY.md`, and final audit report.
