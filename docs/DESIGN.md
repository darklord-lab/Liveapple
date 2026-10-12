# DESIGN — Classora UI/UX

## Principles
Clean, fast, class-ke-dauran distraction-free. Teacher ke liye controls ek tap me; student ke liye "Join" sabse prominent.

## Design Tokens
| Token | Value |
|---|---|
| Primary | Indigo `#4F46E5` |
| Primary Dark | `#3730A3` |
| Accent / Live | Red `#DC2626` (LIVE badge) |
| Success | `#16A34A` |
| Warning | `#D97706` |
| Surface (light) | `#FFFFFF`, bg `#F8FAFC` |
| Surface (dark) | `#0F172A`, card `#1E293B` |
| Text | `#0F172A` / `#94A3B8` |
| Radius | 12 (cards), 999 (chips/buttons-pill) |
| Spacing | 4 · 8 · 12 · 16 · 24 · 32 |
| Font | Inter (Poppins headings optional) |

Material 3, light + dark theme dono; live class screen default dark.

## Navigation
- **Student** bottom tabs: Home · Timetable · Recordings · Homework · Profile
- **Teacher** bottom tabs: Dashboard · Timetable · Batches · Go Live · Profile
- **Admin** bottom tabs: Overview · Teachers · Batches · Fees · Settings

## Key Screens
1. **Splash / Login / Accept Invite** — email/phone + password, "invite code daalo".
2. **Admin → Teachers**: list + search, FAB "Add Teacher" (single / CSV bulk), status chip (Invited, Active, Suspended).
3. **Teacher → Timetable**: week strip + day agenda, tap slot → edit; "+ Add slot" bottom sheet (batch, subject, days, time, repeat).
4. **Teacher → Batch**: students list, share **invite code / QR**, pending approvals.
5. **Student Home**: pulsing red **LIVE NOW** card (Join button), today's classes, upcoming.
6. **Pre-join sheet**: camera preview, mic level, toggle mic/cam, "Join".
7. **Live Class**
   - Main stage: teacher video / shared screen / whiteboard (switchable)
   - Teacher PiP draggable
   - Bottom bar: Mic · Camera · Share Screen · Whiteboard · Chat · Raise Hand · Participants · Leave/End
   - Side sheet: Chat · Participants · Doubts · Polls
   - Network quality indicator, recording dot, timer
   - Host (teacher) menu: mute all, mute/remove student, allow mic, lock room
8. **Notifications**: list + deep link.

## Notifications Copy
- "🔴 Physics Live ho gaya hai — Prof. Sharma. Abhi join karo"
- "⏰ 15 min me Chemistry class start hogi"

## Interaction Rules
- Join ≤ 2 taps from notification.
- Bahut saare students: grid pagination (max 9 tiles/page), active speaker highlight.
- Landscape support on live screen; whiteboard me stylus/palm rejection.
- Accessibility: min touch 48dp, contrast AA, captions later.
