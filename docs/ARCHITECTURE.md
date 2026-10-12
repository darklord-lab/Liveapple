# ARCHITECTURE — Classora 2.0 (v2)

## 1. Overview
```
Flutter App (Android/iOS)
  │ REST (JWT)        │ Socket.IO (events)       │ WebRTC (livekit_client)
  ▼                   ▼                          ▼
Cloudflare Tunnel (https/wss)                 LiveKit Cloud (SFU)
  ▼
Express API (Prisma + SQLite) + Socket.IO gateway
  ├─ Storage adapter (local disk now -> Cloudflare R2/S3 later)
  ├─ FCM (push; disabled until credentials added)
  ├─ Scheduler (reminders)  └─ LiveKit webhooks (attendance, room end)
```
- **DB**: local SQLite (Prisma, WAL, FK on) is the runtime DB. Cloudflare D1 is NOT used.
- **Cloudflare**: Tunnel only (API + WebSocket). No video through Cloudflare.
- **Video**: LiveKit Cloud; server signs short-lived tokens; URL comes from env and token response.

## 2. Repo Layout
```
Liveapple/
├── apps/api/ · apps/mobile_flutter/
├── shared/ (DigitalBoard.tsx if still referenced) · infra/ · docs/ · builds/ · _archive/
```

## 3. Flutter Structure (feature-first, Riverpod, go_router, dio, freezed)
```
lib/
├── core/ theme/ widgets/ network/ router/ utils/ permissions/
└── features/
    ├── auth/ institute_code/ settings/ profile/ help/
    ├── student/ teacher/ admin/
    ├── timetable/ batches/ live_class/ whiteboard/ notifications/
    ├── study_material/ recordings/ assignments/ tests/ attendance/ fees/
    └── store/ (P2)     (each: data/ domain/ presentation/)
```
No Chats feature module (chat lives inside live_class).

## 4. Data Model (every row has instituteId)
Existing: Institute, User, Invite, Batch, Enrollment, TimetableSlot, LiveClass, Attendance, Recording, Assignment, Submission, Test, Question, TestAttempt, FeePlan, Payment, Notification, RefreshToken, AuditLog, ChatMessage (in-class).

New:
- `Institute`: + `code` (unique, short), `logoUrl`, `brandColor`, `appShareUrl`
- `User`: + `photoUrl`
- `InstituteLink(id, instituteId, type[YOUTUBE|TELEGRAM|WHATSAPP|WEBSITE|OTHER], label, url, sortOrder)`
- `Testimonial(id, instituteId, name, text, photoUrl?, isVisible)`
- `MaterialFolder(id, instituteId, batchId, parentId?, name)`
- `StudyMaterial(id, instituteId, batchId, folderId?, title, kind[PDF|DOC|IMAGE|VIDEO_LINK|LINK], fileKey?, url?, sizeBytes?, isFree, uploadedBy, createdAt)`
- `NotificationPref(userId, liveClass, reminders, homework, tests)`
- Store (P2): `Offering(id, instituteId, batchId, price, mrp, isFeatured, isPublished)`, `Coupon(id, instituteId, code, percent|amount, validTill, maxUses)`, `Purchase(id, offeringId, studentId, paymentId, status)`
- **Removed**: any TestSeries / series pack table or API.

## 5. API Additions (v1)
```
GET  /institute/by-code/:code            (public, rate-limited, minimal fields)
GET/POST/DELETE /institute/links          (admin)
GET/POST/PATCH/DELETE /testimonials       (admin; GET for students)
GET/POST /batches/:id/folders             POST /batches/:id/materials (multipart)
GET  /batches/:id/materials?folder=&q=&sort=   GET /materials/:id/download (signed)
PATCH /me/profile    POST /me/photo       GET/PATCH /me/notification-prefs
Store (P2): GET /store/offerings?filter&sort  POST /store/checkout  POST /store/coupons/validate  GET /store/purchases
```

## 6. File Storage
Adapter interface `StorageService` (put/get/signedUrl/delete). Local disk implementation now, R2/S3 later. Rules: allowlist of MIME types, max size (e.g. 25 MB), random keys, no path from user input, tenant + batch authorization on every download, antivirus hook optional.

## 7. Live Class Sequence
Teacher `POST /classes/:id/start` -> auth + ownership -> LIVE -> LiveKit room -> emit `class:live` to `user:<id>` rooms + FCM (if configured) + Notification rows -> student taps Join -> `POST /classes/:id/token` (enrollment checked) -> joins LiveKit. Whiteboard/chat/polls/doubts via Socket.IO room `class:<id>` (membership checked per event). Attendance derived from LiveKit webhooks.

## 8. Security Summary
15-min access JWT + rotating refresh with reuse detection, argon2id, Zod on every route, tenant guard, RBAC, per-event socket auth, signed LiveKit tokens, secure storage on device, rate limits + account lockout, strict upload rules, no secrets in repo, test-only demo passwords. Tunnel is public: stop it when not testing.

## 9. Environments
Dev: `npm run start:all` (API + tunnel + health check). Test: separate `test.db`. Prod later: VPS, Postgres, R2/S3, named tunnel or direct TLS.
