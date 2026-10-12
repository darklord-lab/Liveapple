# PRD — Classora 2.0 (v2)

## 1. Vision
Classora ek Flutter-first, multi-tenant EdTech app hai. **Institute Admin** multiple teachers onboard karta hai, har **Teacher** apna timetable banata hai, students enroll karta hai, study material share karta hai aur Zoom/Meet jaisi **live class** leta hai. **Student** ko class live hote hi notification milta hai aur wo ek tap me join karta hai. Har institute ka apna **Institute Code**, naam aur logo hota hai (white-label).

## 2. Roles
| Role | Kaam |
|---|---|
| Super Admin | Institutes create/suspend, plans |
| Institute Admin | Teachers onboard (single + bulk CSV), batches, fees, branding, links, testimonials, store, reports |
| Teacher | Timetable, batches, students, live class, whiteboard, study material, assignments, tests, recordings |
| Student | Join live class, schedule, study material, recordings, assignments, tests, attendance, fees, store |

## 3. Core Flows
1. **Teacher onboarding**: Admin invite (single/CSV) -> invite code -> teacher password set -> profile.
2. **Timetable**: weekly recurring slots, conflict detection, one-off classes, reschedule/cancel.
3. **Student enrollment** (3 ways): admin/teacher adds, batch join code/QR, or purchase from Store (P2).
4. **Go Live**: teacher taps Go Live -> class LIVE -> realtime event + FCM push -> students join.
5. **Study material**: teacher uploads files/links to a batch folder -> students view/download.
6. **Institute Code**: student enters institute code on first launch -> app shows that institute's name/logo/links.

## 4. Feature Scope

### Existing core (keep and stabilise)
Auth + invites + RBAC + tenant isolation, batches + join code, enrollment, timetable + conflict engine, live class on LiveKit (video, audio, screen share, host controls), whiteboard (**teacher draws, students view-only unless granted**), **in-class** chat / polls / doubts / raise hand, notifications + 15-min reminder, attendance, recordings, assignments + grading, batch CBT tests, fee dues/receipts.

### New features (this version)
| Feature | Side | Notes |
|---|---|---|
| Study Material | Teacher uploads, Student views | Folders per batch; PDF/doc/video link; "Free material" flag |
| Edit Profile | All | Name, photo (camera/gallery), phone |
| Settings | All | Notification settings, Share app, Rate us, Sign out, version |
| Help / How to use | All | Short onboarding walkthrough per role |
| Connect With Us | Admin sets, Student sees | YouTube / Telegram / WhatsApp links |
| Students Testimonials | Admin curates, Student sees | Name, text, optional photo |
| Share score + app link | Student | Share card after a test with deep link |
| Institute Code (white-label) | All | Code entry, institute name + logo in app bar |
| Picture-in-Picture | Student/Teacher | Live class and recordings (Android first) |
| Filters + Sort | All lists | Search, filter sheet, sort radios |
| Course Store (P2) | Admin sets, Student buys | Paid batches: price, MRP, discount, coupon, featured, filter/sort, "previously purchased", Razorpay |

### Explicitly REMOVED / NOT building
- **Test Series** (paid test packs, series tile, series pages) is removed everywhere. Batch-level CBT tests stay.
- **Separate Chats tab / batch group chat / offline chat**: not building. Chat exists **only inside the live class**.
- **Offline Downloads** screen: not building now.

## 5. Non-Functional
Concurrency 100+ per class (SFU), reconnect, strong security (RULES.md), Android + iOS, light + dark, runs on a single laptop via Cloudflare Tunnel + LiveKit Cloud for testing.

## 6. Success Metrics
Teacher onboarding < 5 min; live-start -> join < 10 s; crash-free > 99%; zero dead buttons.

## 7. Open Questions
- Course Store payments need real Razorpay keys (currently mocked).
- Firebase credentials pending (push disabled until then).
