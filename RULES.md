# RULES — Coding, Security & Agent Honesty Rules (v2)

## A. Agent working rules
1. Read /docs (PRD -> ARCHITECTURE -> DESIGN -> TASKS -> MEMORY) before coding. Docs are the source of truth.
2. One phase at a time. **STOP at the end of each phase** and wait for approval.
3. Report with labels only: WORKING (you ran it, paste output) / PARTIAL / STUB / BROKEN / MISSING / NOT VERIFIED. Never mark WORKING without output. Camera, mic, screen share, push need real devices = NOT VERIFIED.
4. No feature that is not in PRD.md. No package without a reason logged in MEMORY.md.
5. Do not modify whiteboard internals. Do not use Cloudflare D1 or wrangler. Do not ask for or print secrets.
6. Never claim a root cause without evidence; explain what was actually wrong.

## B. Product rules
- **No dead UI**: every visible button/tab/toggle must work. If a feature is not built, hide it.
- **No fake data / hardcoded text** pretending to be live state (e.g. "Stream Active", "Student 1").
- **Test Series does not exist** in Classora. Do not add it.
- **Chat only inside the live class.** No chat tab, no group chat, no offline chat.
- No Offline Downloads screen (not in scope now).
- Payments/Store: do not show a real "Pay" flow until real Razorpay keys + webhook signature verification work. Demo flows must say TEST MODE.
- Whiteboard: teacher draws; students view-only unless teacher grants (server-enforced).

## C. Backend (TypeScript)
- `strict: true`, no `any`. Controllers thin, logic in services.
- Every endpoint: authenticate -> authorize(role) -> tenant check -> Zod validate.
- **Every DB query filtered by instituteId** (Prisma helper). Never trust role/instituteId from the client.
- Passwords argon2id. Tokens/invite codes stored hashed. Pagination on lists.
- Standard errors `{ code, message }`. Secrets only in `.env` (git-ignored), `.env.example` committed.
- Env is validated at startup; production refuses default secrets.
- Tests use a separate SQLite file; never write test data into dev DB.

## D. Auth & Sessions
Access JWT 15 min; refresh 30 days with rotation + reuse detection (family revoke). Login rate limit + account lockout. Invite codes random, hashed, one-time, 48 h.

## E. Realtime / Live class
- Socket auth on connect; membership check on every event; flood + payload limits.
- LiveKit token server-signed, short TTL, permissions by role; students join muted, publish only after a teacher grant.
- UI state for mic/camera/participants comes ONLY from LiveKit state (single source of truth).
- Attendance from LiveKit webhooks, not from the client alone.

## F. File uploads (Study Material, profile photo)
MIME allowlist, size cap, random storage keys, no user-controlled paths, tenant + batch authorization on download (signed URLs), never serve uploads as executable. Strip metadata from images.

## G. Flutter
- Riverpod + go_router + freezed, feature-first. No business logic in widgets.
- Tokens only in flutter_secure_storage. Server URL is a user setting (shared_preferences OK for non-secrets).
- One configurable base URL for REST + Socket.IO; LiveKit URL comes from the token response. No localhost/LAN hardcoding.
- Every list: loading / empty / error states, ellipsis for long text, no overflow at 320 dp, text scale 1.3 OK.
- Permission rationale dialog before camera/mic/notification/photo prompts.
- Android release: obfuscation; FLAG_SECURE on sensitive screens; cleartext only in debug/demo.
- Firebase optional: app must start normally without credentials.

## H. Testing & Git
Service tests (auth, tenant isolation, enrollment, schedule), socket integration tests, widget tests for overflow and key screens. Bug fix = failing test first. Conventional commits. No APKs or `.env` in git.

## I. Never
Trust client role/tenant; query without tenant filter; log tokens/passwords/PII; commit secrets; ship demo passwords or demo chips in a real release; leave a tunnel running unattended.
