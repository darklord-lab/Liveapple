# ARCHITECTURE — Classora 2.0

## 1. High-level
```
Flutter App (Android/iOS)
   │  REST (JWT)           │ Socket.IO (events)        │ WebRTC (LiveKit SDK)
   ▼                       ▼                           ▼
Express API  ◄────────►  Realtime Gateway          LiveKit SFU server
(Prisma + SQLite)        (board, chat, polls)      (video/audio/screenshare)
   │
   ├── FCM (push notifications)
   ├── Object storage (recordings, PDFs) — local disk now, S3 later
   └── Scheduler (reminders)  e.g. node-cron / BullMQ later
```

## 2. Important Decision: Video Engine
Abhi ka custom WebRTC signaling **mesh** style hota hai — 4-6 users ke baad phone/network crash karta hai. Zoom/Meet jaisa chahiye to **SFU** zaroori hai.
**Choice: LiveKit** (open-source, self-hostable, Flutter SDK `livekit_client`).
- Backend sirf **short-lived signed access token** deta hai (room = classId, identity = userId, permissions by role).
- Teacher: `canPublish`, `canPublishScreen`, `roomAdmin`. Student: subscribe-only by default; teacher "allow mic" de to publish.
- Screen share, simulcast, adaptive bitrate, reconnect → LiveKit handle karta hai.
- Recording: LiveKit Egress.

## 3. Monorepo Layout
```
Liveapple/
├── apps/
│   ├── api/              # Express + TS + Prisma + Socket.IO
│   ├── mobile_flutter/   # MAIN app
│   └── admin-web/        # optional web admin (existing React)
├── docs/                 # ye md files
└── infra/                # docker-compose: api + livekit
```

## 4. Flutter App Structure (feature-first)
```
lib/
├── core/        # theme, router (go_router), dio client, secure_storage, errors
├── features/
│   ├── auth/ admin/ teacher/ student/
│   ├── timetable/ live_class/ whiteboard/ chat/ notifications/
│   └── each: data/ (repo, dto) · domain/ (models) · presentation/ (screens, widgets, providers)
└── main.dart
```
State management: **Riverpod**. Navigation: **go_router**. HTTP: **dio** + interceptor (auto refresh token). Models: **freezed + json_serializable**.

## 5. Data Model (Prisma, SQLite)
Har table me `instituteId` (tenant key).
- `Institute(id, name, slug, plan)`
- `User(id, instituteId, role[ADMIN|TEACHER|STUDENT], name, email, phone, passwordHash, status, fcmToken?)`
- `Invite(id, instituteId, email/phone, role, codeHash, expiresAt, usedAt)`
- `Batch(id, instituteId, teacherId, name, subject, joinCode)`
- `Enrollment(id, batchId, studentId, status[PENDING|ACTIVE|REMOVED])`
- `TimetableSlot(id, instituteId, teacherId, batchId, dayOfWeek, startMin, endMin, recurring)`
- `LiveClass(id, instituteId, batchId, teacherId, title, scheduledAt, status[SCHEDULED|LIVE|ENDED|CANCELLED], livekitRoom, recordingUrl)`
- `Attendance(id, liveClassId, studentId, joinedAt, leftAt)`
- `Notification(id, userId, type, payload, readAt)`
- `RefreshToken(id, userId, tokenHash, expiresAt, revokedAt, deviceId)`
- `AuditLog(id, instituteId, actorId, action, entity, meta, at)`
- later: Assignment, Submission, Test, Question, Attempt, FeePlan, Payment

SQLite notes: `PRAGMA journal_mode=WAL`, foreign keys ON, indexes on `(instituteId, ...)`. Prisma se Postgres migration provider badalkar ho jayegi.

## 6. API Surface (v1)
```
POST /auth/login | /auth/refresh | /auth/logout | /auth/accept-invite
POST /admin/teachers            (single)     POST /admin/teachers/bulk (CSV)
GET  /admin/teachers            PATCH /admin/teachers/:id/status
POST /batches                   POST /batches/:id/enroll | /batches/join (code)
GET/POST/PATCH/DELETE /timetable
POST /live-classes              POST /live-classes/:id/start   (→ notify)
POST /live-classes/:id/token    (LiveKit token)    POST /live-classes/:id/end
POST /devices/fcm-token
GET  /notifications
```

## 7. "Teacher goes live" Sequence
1. Teacher → `POST /live-classes/:id/start`
2. API: auth + ownership check → status=LIVE → create LiveKit room
3. API: fetch active enrolled students → **FCM multicast** + Socket.IO `class:live` + Notification rows
4. Student taps notification → deep link `/live/:id` → `POST /live-classes/:id/token` (enrollment verified) → joins LiveKit room
5. Whiteboard/chat/polls Socket.IO room `class:<id>` (same auth, joined only after token check)

## 8. Security Architecture (summary)
Access JWT (15 min) + rotating refresh token (hashed in DB, device-bound), argon2id passwords, Zod validation, helmet, rate-limit, CORS allowlist, tenant guard middleware, per-event Socket.IO auth, signed LiveKit tokens (TTL ~10 min), secure storage on device, TLS everywhere. Details in RULES.md.

## 9. Deployment (dev → prod)
Dev: `docker compose up` (api + livekit). Prod: VPS + Caddy/Nginx TLS, LiveKit with TURN, Postgres, S3 storage.
