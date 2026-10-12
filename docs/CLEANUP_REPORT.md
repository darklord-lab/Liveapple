# CLEANUP REPORT — Classora 2.0 (Phase A)

**Generated:** 2026-10-10  
**Authority:** `satyam2.md` Phase A (Safe Cleanup)

---

## 1. Files & Directories Removed

| Path | Action | Reason | Evidence / Grep Verification |
| :--- | :--- | :--- | :--- |
| `apps/api/src/mockData.ts` | Deleted | Orphaned prototype/mock file; not part of active backend. | `grep_search` across `apps/api` returned 0 imports. (Only referenced by legacy archived web dashboards). |
| `Classora.apk` | Deleted | Stale APK build output in repository root. | Binaries must not reside in root; `.gitignore` covers `*.apk`. |
| `Classora-Flutter.apk` | Deleted | Stale APK build output in repository root. | Binaries must not reside in root; `.gitignore` covers `*.apk`. |
| `Classora-v2-Updated.apk` | Deleted | Stale APK build output in repository root. | Replaced by `builds/` target in Phase E. |
| `ARCHITECTURE.md` (root) | Deleted | Duplicate of `docs/ARCHITECTURE.md`. | Verified byte-parity with `docs/ARCHITECTURE.md` before removal. |
| `DESIGN.md` (root) | Deleted | Duplicate of `docs/DESIGN.md`. | Verified byte-parity with `docs/DESIGN.md` before removal. |
| `PRD.md` (root) | Deleted | Duplicate of `docs/PRD.md`. | Verified byte-parity with `docs/PRD.md` before removal. |
| `RULES.md` (root) | Deleted | Duplicate of `docs/RULES.md`. | Verified byte-parity with `docs/RULES.md` before removal. |
| `TASKS.md` (root) | Deleted | Duplicate of `docs/TASKS.md`. | Synced latest updates into `docs/TASKS.md` before removal. |
| `MEMORY.md` (root) | Deleted | Duplicate of `docs/MEMORY.md`. | Synced latest updates into `docs/MEMORY.md` before removal. |

---

## 2. Directories Moved to `_archive/` via `git mv`

Per `satyam2.md` item A3, legacy React web portals were preserved under `_archive/` rather than deleted, keeping `shared/DigitalBoard.tsx` intact:

| Source Path | Destination Path | Reason |
| :--- | :--- | :--- |
| `apps/admin/` | `_archive/admin/` | Old React Admin portal; Flutter app is the primary client. |
| `apps/teacher/` | `_archive/teacher/` | Old React Teacher portal; Flutter app is the primary client. |
| `apps/student/` | `_archive/student/` | Old React Student portal; Flutter app is the primary client. |
| `apps/marketing/` | `_archive/marketing/` | Old React Marketing portal; separated from core mobile app & API. |
| `apps/web/` | `_archive/web/` | Old unified React portal; archived. |

---

## 3. Preserved Core Assets (Item A4)

- `apps/api/prisma/schema.prisma` & migrations & seeds: **Intact**
- `docs/`: **Intact** (Single source of truth)
- `shared/DigitalBoard.tsx`: **Intact**
- `infra/docker-compose.yml`: **Intact**
- `builds/README.md`: **Created and tracked**
- `.env.example`: **Intact**

---

## 4. Final Clean Repository Structure (Item A6)

```
Liveapple/
├── apps/
│   ├── api/              (Express + Prisma + Socket.IO + SQLite)
│   └── mobile_flutter/   (Flutter Client: Android & iOS)
├── shared/               (DigitalBoard.tsx)
├── infra/                (Docker compose for API & LiveKit)
├── docs/                 (PRD, ARCHITECTURE, RULES, DESIGN, TASKS, MEMORY, CLEANUP_REPORT)
├── builds/               (README.md tracked, apks ignored)
├── _archive/             (Archived React web portals: admin, teacher, student, marketing, web)
└── satyam2.md            (Active specification)
```
