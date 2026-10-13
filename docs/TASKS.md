# TASKS — Classora Roadmap (v2)

Legend: `[x]` done and proven · `[v]` reported done, needs verification on real phones · `[ ]` todo · `[-]` removed from scope

## Stage 0 — Already built (backend proven by 72 automated tests)
- [x] Auth (argon2id, JWT 15m, refresh rotation + reuse detection), invites, RBAC, tenant isolation
- [x] Admin: single + bulk teacher onboarding, suspend/reactivate
- [x] Batches + join code, enrollment (code / manual / CSV), timetable + conflict engine, class generation
- [x] LiveKit token signing (role permissions), host-control endpoints
- [x] Assignments, CBT tests (batch tests), recordings metadata, attendance, fees (mock gateway)
- [x] Whiteboard engine (do not touch internals)
- [v] Flutter: live classroom UI, chat over socket, schedule fixes, participants single source of truth
- [v] Real LiveKit Cloud connection, real video render, mic/camera state from tracks

## Stage 1 — Stabilise (satyam2.md)
- [ ] Verify on 2 phones: login, schedule, go live, join, camera/mic state, chat both ways, board view-only, mute all/remove
- [ ] Teacher grant flow: allow mic/camera/board (server enforced) + tests
- [ ] Close evidence gaps: socket tests for board permission, class:scheduled/class:live, host-timeout survives restart
- [ ] LiveKit webhooks -> attendance (signature verified)
- [ ] One-command start (`npm run start:all`: API + tunnel + health), env validation, docs/RUN_GUIDE.md
- [ ] Release build without DEMO_MODE; separate clearly named demo build
- [ ] Fix `npm audit` (no --force), remove `any`, account lockout, EmailProvider interface for invites

## Stage 2 — Remove unwanted
- [-] Test Series (tile, pages, API, tables, strings, tests) — remove everywhere, keep batch CBT tests
- [-] Chats tab / batch group chat / offline chat (chat only in live class)
- [-] Offline Downloads screen
- [x] Remove standalone "Open Live Canvas" entry points (whiteboard only in class)

## Stage 3 — UI redesign (design system first)  [STOP after 3.1 for approval]
- [x] 3.1 Theme, core widgets, Student Home + Drawer + Settings + permission dialogs
- [x] 3.2 Student: Schedule, Batches/Join, Learn (Study Material · Recordings · Assignments · Tests)
- [x] 3.3 Teacher: Home tiles, Timetable (overflow fixed), Batch detail, Live Classes
- [x] 3.4 Admin: Overview, Teachers, Batches, Fees
- [x] 3.5 Live classroom restyle (dark Meet-like), PiP, reconnect banner
- [x] 3.6 Login in new style, consistency pass, overflow tests 320/360 dp

## Stage 4 — New features
- [x] 4.1 Study Material: folders, upload (PDF/doc/link), free flag, student view/download, storage adapter, upload security tests
- [x] 4.2 Edit Profile (photo via camera/gallery), Settings (notification prefs, share, rate, sign out, version)
- [ ] 4.3 Help / How to use (per-role walkthrough)
- [ ] 4.4 Institute Links ("Connect With Us") + Testimonials (admin CRUD, student view)
- [ ] 4.5 Institute Code + white-label (code entry, name/logo/color in app bar)
- [ ] 4.6 Share score + app link (share card, deep link)
- [ ] 4.7 Picture-in-Picture (live class, recordings; Android first)
- [ ] 4.8 Filters + Sort sheets on lists (batch, subject, status, newest)

## Stage 5 — Notifications
- [ ] Firebase project + credentials (user adds later), FCM in Flutter + server provider, deep link to live class
- [ ] Until then: realtime in-app banner + 10 s fallback poll (already built [v])

## Stage 6 — Course Store (P2, needs real payment keys)
- [ ] Offerings (price, MRP, discount, featured, publish), coupons, filter/sort, previously purchased
- [ ] Razorpay checkout + webhook signature verification, auto-enroll after payment
- [ ] Refund/invoice basics

## Stage 7 — Hardening & Release
- [ ] Security checklist (RULES.md), upload fuzz tests, rate-limit review
- [ ] LiveKit load test (100 subscribers) with `lk load-test`
- [ ] Crashlytics, obfuscated release, Play Store/App Store builds, iOS screen-share extension
- [ ] SQLite -> PostgreSQL migration, R2/S3 storage, named tunnel or direct TLS
