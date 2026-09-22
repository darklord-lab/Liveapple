# Classora — Virtual Classroom + Institute Management SaaS
> **Tagline:** Teach. Stream. Write. Learn.  
> **Theme:** Pure Light Theme (Crisp, modern, high-contrast UI)  
> **Version:** 2.0 (Single Source of Truth)

This repository contains the complete implementation of the Classora platform — from the real-time collaborative digital board and virtual classroom to institute LMS, fee tracking, and administration.

---

## 1. Product Summary
Classora is a B2B SaaS platform for schools, coaching institutes, and individual educators.
**Core Value Chain:**
`Teacher → Live Class → Digital Board → Students → Recording → Assignment → Test → Attendance → Fees → Analytics`

### Platform Applications
- **classora.com** — Marketing/sales landing website
- **app.classora.com** — Student web application
- **teacher.classora.com** — Teacher dashboard + live classroom console
- **admin.classora.com** — Institute admin panel (owner / administrator)
- **Mobile Experience** — Responsive mobile views for Students and Teachers

*Design Directive:* Pure Light Theme everywhere (`#FFFFFF` backgrounds, light slate `#F8FAFC`, crisp borders `#E2E8F0`, slate typography `#0F172A`, and royal indigo `#4F46E5` brand accents).

---

## 2. Tech Stack
- **Web Frontend**: React 18, Vite, TypeScript, Tailwind CSS, Lucide Icons, Canvas API
- **Backend API**: Node.js / Express (TypeScript), Socket.IO for real-time signaling & whiteboard synchronization
- **Real-Time Board Engine**: Canvas rendering + Yjs-compatible CRDT drawing events over WebSockets
- **Live Classroom**: WebRTC live streaming architecture with Picture-in-Picture teacher camera, floating toolbars, live chat, interactive polls, and doubt management

---

## 3. System Architecture
```
CLASSORA
│
├── Student Web │ Teacher Web │ Admin Web │ Marketing Web
└── API Gateway / REST & Real-time Socket Server
    ├── Multi-Tenant Database (Institute Scoped)
    ├── Live Classroom Service (WebRTC Signaling + Whiteboard Sync)
    ├── LMS Engine (Courses, Batches, Assignments, Tests)
    └── Fee & Billing Service
```

---

## 4. Multi-Tenant Data Model
Every table and record carries an `institute_id`. Every query is strictly isolated to the authenticated user's institute context:
```
institutes
├── users (owner | admin | teacher | student | parent)
├── batches
├── courses → subjects → chapters
├── live_classes → class_participants
├── recordings
├── board_sessions → board_pages
├── assignments → assignment_submissions
├── tests → questions → attempts
├── attendance
├── fee_plans → fee_transactions
└── notifications
```

---

## 5. Running the Project
```bash
# Install dependencies
npm install

# Start both API and Web frontend
npm run dev
```

Visit the running app to switch smoothly between:
1. **Marketing Landing** (`classora.com`)
2. **Institute Admin Panel** (`admin.classora.com`)
3. **Teacher Live Console** (`teacher.classora.com`)
4. **Student Portal** (`app.classora.com`)
