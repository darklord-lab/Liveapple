# DESIGN — Classora UI/UX (v2, light-first)

Reference: a clean coaching-app style (sky-blue app bar, white background, colored home tiles, left drawer, 4-tab bottom nav, bottom-sheet filters, simple empty states). Use layout/patterns only; Classora has its own name, logo and assets. See `ui_reference_student.png` and `ui_reference_teacher_admin.png`.

## 1. Tokens
| Token | Value |
|---|---|
| Primary (app bar, buttons, active nav) | Sky blue `#0A9BE8` |
| Accent / logo | Indigo `#4F46E5` |
| Live | Red `#DC2626` |
| Success / Warning | `#16A34A` / `#D97706` |
| Tile colors | Brown `#8B5E3C`, Blue `#2F6FD6`, Green `#2FA37A`, Orange `#F28A30` |
| Light bg / card | `#F4F6F8` / `#FFFFFF` (radius 12, soft shadow) |
| Dark bg / card | `#0F172A` / `#1E293B` (live class always dark) |
| Text | `#0F172A` / secondary `#64748B` |
| Spacing | 4 · 8 · 12 · 16 · 24 |
| Font | Inter; min touch 48 dp |

## 2. Shared Components
AppScaffold (blue app bar, hamburger or back, institute name + logo, bell with badge), AppBottomNav (4 tabs), AppDrawer, ColorTile, SectionHeader, InfoChip, StatusPill (LIVE / UPCOMING / ENDED), PrimaryButton, OutlinedPillButton, SearchField, FilterSheet (sections, range slider, sort radios, CLEAR + APPLY), EmptyState, ErrorState, LoadingSkeleton, UserAvatar, ConfirmDialog, PermissionRationaleDialog.

## 3. Student (bottom nav: Home · Schedule · Learn · Profile)
- **Home**: LIVE NOW card (Join), 2x2 ColorTiles (**Live Schedule, Study Material, Recordings, My Batches**), Next classes carousel, Homework & tests due, Testimonials, Connect With Us (only if links set).
- **Schedule**: week strip with counts + day agenda (all enrolled batches).
- **Learn**: tabs **STUDY MATERIAL · RECORDINGS · ASSIGNMENTS · TESTS**, search, sort, filter by batch/subject.
- **Profile**: avatar, institute code, Edit Profile, Attendance, Fees, Settings.
- **Drawer**: avatar, name, Institute Code, Study Material, Assignments, Tests, Recordings, Attendance, Fees & Receipts, Edit Profile, Settings, Help / How to use, Privacy Policy, Share app.
- **Store (P2)**: Featured offerings, list with price/MRP/discount, filter sheet (Discount/Offers, Previously purchased, price range, sort), Get this batch.
- **No Test Series, no Chats tab, no Offline Downloads.**

## 4. Teacher (bottom nav: Home · Timetable · Batches · Profile)
- **Home**: Today's classes with **Go Live / Enter Room**, 2x3 ColorTiles (**Batches, Timetable, Live Classes, Study Material, Assignments & Tests, Recordings**), stats (students, classes this week), pending submissions.
- **Timetable**: week strip, Add Slot sheet (batch dropdown with ellipsis, day, start/end, recurring), conflict message inline.
- **Batch detail**: join code + QR + share, students list, pending approvals, Study Material tab (folders, upload PDF/doc/link, free toggle).
- **Live Classes**: scheduled/live/past filters, Generate from slots.
- **Drawer/Settings/Profile** same as student (role-specific items).
- No standalone whiteboard card; whiteboard only inside a live class (teacher tools).

## 5. Admin (bottom nav: Overview · Teachers · Batches · More)
- **Overview**: stat cards (students, teachers, revenue, attendance), recent activity.
- **Teachers**: search, status filter sheet, Add single / Bulk CSV, invite code copy/share, suspend.
- **Batches**, **Fees** (collected / pending / receipts), **Branding** (institute name, logo, code, color), **Links** (YouTube/Telegram/WhatsApp), **Testimonials**, **Store** (P2), **Settings**.

## 6. Live Classroom (dark, Meet-like)
Top bar: title (ellipsis) · LIVE pill · timer · connection/network badge · End class (teacher). Stage: teacher video / screen share / whiteboard. Participant strip/grid (max 9 per page). Bottom bar: Mic · Camera · Share screen (teacher) · Board (teacher draws, students view) · Chat · People · More (raise hand, polls, doubts, mute all, lock room) · Leave. People sheet shows real names, mic/cam state, hand-raised first, teacher actions (mute, allow mic/cam/board, remove). Reconnect banner, PiP, keep screen awake.

## 7. States & Copy
Empty: "No recordings yet", "No study material yet". Errors say what to do ("Server tak nahi pahunch pa raha. URL check karo"). Notifications: "🔴 Physics live ho gaya hai - abhi join karo", "⏰ 15 min me Maths class".

## 8. Quality
No overflow at 320/360 dp, AA contrast, semantics labels, text scale 1.3, widget tests for long text.
