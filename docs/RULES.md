# RULES — Coding & Security Rules (AI aur humans dono ke liye)

## General
1. Pehle `docs/` padho (PRD → ARCHITECTURE → TASKS → MEMORY) phir code likho.
2. Ek time par **ek task** (TASKS.md se). Task khatam → checkbox tick + MEMORY.md update.
3. Chhote, reviewable changes. Kuch bhi bada rewrite bina puche nahi.
4. Koi naya package add karne se pehle reason likho (MEMORY.md decisions me).

## Backend (TypeScript)
- `strict: true`. `any` allowed nahi.
- Har endpoint par: **authenticate → authorize(role) → tenant check → Zod validate**.
- **Har DB query me `instituteId` filter** (use a Prisma helper/extension so bhoolna impossible ho).
- Controllers patle, logic `services/` me. Errors ek standard format me: `{ code, message }`.
- Passwords: **argon2id**. Kabhi plain/log nahi.
- Secrets sirf `.env` (git-ignored). `.env.example` commit karo.
- Pagination mandatory for list APIs.

## Auth & Session
- Access JWT 15 min; refresh token 30 din, **rotation + reuse detection** (reuse = poore device family revoke).
- Refresh tokens DB me hashed store.
- Login/invite endpoints par rate-limit + lockout.
- Invite codes: random 128-bit, hashed, one-time, expiry 48h.

## Realtime & Live Class
- Socket.IO connect par JWT verify; har event par role + room membership check.
- Student ko sirf apne enrolled batch ke class room me entry.
- LiveKit token: server-side sign, TTL chhota, identity=userId, permissions role se.
- Teacher-only actions (mute all, remove, end class, share screen allow) server par enforce — client trust nahi.
- Payload size limit on board strokes; flood control per socket.

## Flutter
- Riverpod + go_router + freezed. Feature-first folders.
- Tokens sirf `flutter_secure_storage` me. SharedPreferences me kabhi nahi.
- Release build: obfuscation (`--obfuscate --split-debug-info`), root/jailbreak warning optional.
- Camera/mic/notification permissions context ke saath maango (rationale screen).
- Android `FLAG_SECURE` on sensitive screens (fees, test) screenshot rokne ke liye.
- UI me business logic nahi; providers/repos me.
- Har screen par loading / empty / error state.

## Testing
- Backend: service-level tests (auth, tenant isolation, enrollment).
- Flutter: widget tests critical flows (login, join live).
- Bug fix = pehle failing test.

## Git
- Branch: `feat/<name>`, `fix/<name>`. Commit: conventional (`feat: add timetable slots`).
- Secrets ya `.apk` commit mat karo (Releases ya CI artifacts use karo).

## Never
- Client se `instituteId`/`role` trust karna.
- `SELECT` bina tenant filter.
- Logs me token/password/PII.
- Hardcoded API keys.
