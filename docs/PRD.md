# PRD — Classora 2.0

## 1. Vision
Ek Flutter-first, multi-tenant EdTech app jisme **Institute Admin** multiple teachers onboard kare, har **Teacher** apna timetable banaye, apne students enroll kare, aur **live class** (Zoom/Meet jaisi quality) le. Class start hote hi students ko **notification** mile aur sab ek saath join kar sakein.

## 2. Roles
| Role | Kaam |
|---|---|
| Super Admin (Owner) | Institutes create/suspend karna, plans, global analytics |
| Institute Admin | Teachers onboard (single + bulk), batches, fees, branding, reports |
| Teacher | Timetable, students enroll, live class, assignments, tests, attendance |
| Student | Notifications, live class join, recordings, homework, tests, fees |

## 3. Core User Flows
1. **Teacher onboarding**: Admin teacher ka naam/email/phone daalta hai (ya CSV upload) → system invite link + one-time code bhejta hai → teacher password set karta hai → first-login par profile + timetable setup.
2. **Timetable (TT)**: Teacher weekly recurring slots banata hai (batch, subject, day, time). Calendar view + one-off/reschedule/cancel. Conflict detection (same teacher, same time).
3. **Student enrollment**: Teacher (a) invite code/QR share kare, (b) phone/email se add kare, ya (c) CSV import. Student join request → teacher approve (optional auto-approve).
4. **Go Live**: Teacher "Go Live" dabata hai → class status `LIVE` → push notification (FCM) + in-app realtime event → students ek tap me join.
5. **Reminder**: Class se 15 min pehle aur start par automatic reminder.

## 4. Feature Scope

### P0 (MVP)
- Auth (login, invite, forgot password), RBAC, tenant isolation
- Admin: teacher CRUD + bulk onboard, batch management
- Teacher: timetable, enroll students, start/end class
- Live class: video/audio, **screen share**, grid + speaker view, mute/camera toggle, chat, raise hand
- Push notification on live start + reminders
- Whiteboard (already working) integrated into live class
- SQLite via Prisma

### P1
- Host controls: mute all, remove participant, lock room, waiting room
- Recording + playback library
- Polls, doubts box, attendance auto-capture
- Assignments + tests (CBT with timer)
- Fee tracking (Razorpay/UPI)

### P2
- Breakout rooms, hand-raise queue, reactions
- Analytics dashboards, parent app
- Migrate SQLite → PostgreSQL, horizontal scaling

## 5. Non-Functional Requirements
- **Concurrency**: ek class me 100+ students (SFU based, mesh nahi)
- **Latency**: video < 400 ms typical
- **Security**: see RULES.md (JWT rotation, RBAC, tenant isolation, signed room tokens, encrypted transport)
- **Reliability**: reconnect on network drop, token refresh mid-class
- **Platforms**: Android + iOS (Flutter), web portals optional

## 6. Success Metrics
- Teacher onboarding < 5 min
- Live-start → student join median < 10 s
- Notification delivery > 95%
- Crash-free sessions > 99%

## 7. Out of Scope (abhi)
Marketplace, multi-language content authoring, AI tutoring.
