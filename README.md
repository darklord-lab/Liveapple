# Liveapple — Next-Gen Virtual Classroom & Institute Management Platform

> **Live Production Backend:** [https://liveapple.onrender.com/api](https://liveapple.onrender.com/api)  
> **Admin Web Console:** [https://liveapple.onrender.com/admin/](https://liveapple.onrender.com/admin/)  
> **Mobile Release APK:** `Liveapple-latest.apk` / `Liveapple-Release.apk` (98.4 MB)  
> **Architecture:** Flutter (Android/iOS) + Node.js TypeScript API + Socket.IO WebRTC Gateway + Prisma Multi-Tenant ORM

---

## 📑 Table of Contents
1. [Tech Stack & Dependencies](#1-tech-stack--libraries-used)
2. [System Architecture](#2-system-architecture)
3. [Implemented Core Features](#3-implemented-core-features)
4. [Test Credentials](#4-test-credentials)
5. [Local Development & Build Instructions](#5-local-development--build-instructions)
6. [API Endpoints Reference](#6-api-endpoints-reference)

---

## 1. Tech Stack & Libraries Used

### 📱 A. Mobile Client (`apps/mobile_flutter`)
* **Framework:** Flutter 3.x (Dart 3.x)
* **State Management:** `flutter_riverpod` (v2.6) — Reactive providers for auth, timetable, live classroom, and chat.
* **Routing & Navigation:** `go_router` — Declarative, URL-aware routing with redirect guards for RBAC.
* **Live Streaming & WebRTC:**
  * `livekit_client` — Low-latency WebRTC SFU engine for video, audio, and screenshare.
  * `socket_io_client` — WebRTC peer signaling relay fallback, classroom real-time chat, and whiteboard sync.
* **Media & Video Playback:**
  * `video_player` — Custom in-app video engine for locally stored or uploaded lecture recordings.
  * `webview_flutter` — Sandboxed, locked-down player for unlisted YouTube lectures (controls, share, and downloads strictly disabled).
* **Storage & Device Integration:**
  * `path_provider` — Native OS storage path resolver used to save class recording files locally on the device (`.../LiveappleRecordings/`).
  * `file_picker` — Native OS file picker for uploading videos (`mp4`, `webm`, `mkv`) and study material documents (`pdf`, `doc`, etc.).
  * `flutter_secure_storage` — Encrypted keychain storage for JWT access & refresh tokens.
* **UI & Aesthetics:**
  * `google_fonts` (Inter, Roboto)
  * Custom Dark/Light theme token system (`AppColors.dart`).

---

### 🖥️ B. Backend API & Real-Time Gateway (`apps/api`)
* **Runtime & Language:** Node.js (v20+) with TypeScript (ESModules).
* **HTTP Framework:** Express.js 4.x.
* **Database & ORM:** Prisma ORM with SQLite (dev) / PostgreSQL (production) multi-tenant schema.
* **Authentication & Security:**
  * `jsonwebtoken` (JWT) — Access Token (15 min) + Refresh Token (30 days) rotation flow.
  * `bcryptjs` — Salted password hashing.
  * `helmet` — Secure HTTP headers.
  * `cors` — Cross-origin resource sharing whitelist.
  * `express-rate-limit` — Rate limiting engine protecting against brute-force attacks.
* **Real-Time Services:**
  * `socket.io` (v4.x) — Event-driven server handling:
    * **WebRTC Signaling Relay:** `signal:offer`, `signal:answer`, `signal:candidate`.
    * **Digital Whiteboard Sync:** Vector stroke drawing broadcasting between teacher and students.
    * **In-Class Live Chat:** Threaded messaging with unread counter.
  * `livekit-server-sdk` — Cryptographic room token generation with host/subscriber permission grants.

---

### 🌐 C. Institute Admin Console (`_archive/admin` & `apps/api/admin-dist`)
* **Framework:** React 18, Vite, TypeScript.
* **Styling:** Tailwind CSS, Lucide Icons.
* **Hosting:** Directly bundled and served as static single-page application at `/admin/` by Express.

---

## 2. System Architecture

```
                                    ┌──────────────────────────────────┐
                                    │    Liveapple Flutter App         │
                                    │  (Android APK / iOS / Web)       │
                                    └───────────────┬──────────────────┘
                                                    │
                           HTTPS REST API Requests  │  Socket.IO & WebRTC Signaling
                                                    │
                                                    ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                        Render.com Cloud Gateway (Port 4000)                            │
│                                                                                        │
│  ┌──────────────────────┐   ┌──────────────────────────┐   ┌────────────────────────┐  │
│  │   Express REST API   │   │  Socket.IO Gateway       │   │   Admin Web Console    │  │
│  │   /api/v1/auth       │   │  • WebRTC P2P Relays     │   │   Served at /admin/    │  │
│  │   /api/v1/classes    │   │  • Collaborative Board   │   │   Teacher Onboarding   │  │
│  │   /api/v1/timetable  │   │  • Live Room Chat        │   │   Batch Oversight      │  │
│  │   /api/v1/material   │   └──────────────────────────┘   └────────────────────────┘  │
│  └──────────┬───────────┘                                                              │
│             │                                                                          │
│             ▼                                                                          │
│  ┌──────────────────────────────────────────────────────────────────────────────────┐  │
│  │                     Prisma Multi-Tenant ORM Engine                               │  │
│  │  Institutes │ Users │ Batches │ TimetableSlots │ LiveClasses │ Material │ Fees   │  │
│  └──────────────────────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Implemented Core Features

### 1. 📅 Timetable & Schedule Auto-Sync
* Recurring timetable slots for the current day automatically sync to the Teacher Home screen under **"Scheduled Classes"**.
* Features a 1-tap **"Start"** button to instantly spin up the class and open the Live Classroom.

### 2. 🔴 Live Classroom & Device Recording
* **Interactive Hero Stage:** Host teacher video prominently featured with automatic remote track fallback.
* **Digital Interactive Whiteboard:** Multi-color pen, highlighter, eraser, and clearing tools synchronized over sockets.
* **Presentation Mode:** In-class PPT and PDF presenter.
* **In-App Device Recording (Teacher & Student):**
  * Top-bar live timer pill: `REC 00:01:23`.
  * On stop, exports session metadata to device internal storage:  
    `[AppDocumentsDirectory]/LiveappleRecordings/LiveClass_<id>_<timestamp>.mp4`
  * Dialog displays the exact local file path on the user's phone.

### 3. 📚 Study Material & Notes
* Renamed everywhere to **"Study Material & Notes"** (removing deprecated CBT chip from faculty modules).
* Tapping any card opens a detailed sheet with description, guidelines, and an **"Open / View Document"** action.
* File attachments are **strictly optional** (teachers can post text guidelines without mandatory files).

### 4. 🎬 Recorded Lectures & Custom Secure Player
* **Upload:** Upload local video files (`.mp4`, `.webm`, `.mkv`) from device storage OR submit unlisted YouTube links.
* **Strict Secure Player:**
  * 🚫 No download button.
  * 🚫 No share link.
  * ⏯️ Play / Pause controls.
  * ⏩ Playback speed multiplier (0.75x, 1.0x, 1.25x, 1.5x, 2.0x).
  * 🔄 Portrait & Fullscreen Landscape toggle.

---

## 4. Test Credentials

| Role | Name | Email | Password | Enrolled Batches |
| :--- | :--- | :--- | :--- | :--- |
| **Admin** | Director Apex | `admin@apex.edu` | `Password@123` | Institute Administrator |
| **Teacher 1** | Prof. Rajesh Sharma | `teacher1@apex.edu` | `Password@123` | Class 12 - Physics, Class 12 - Maths |
| **Teacher 2** | Prof. Anita Verma | `teacher2@apex.edu` | `Password@123` | Class 11 - Chemistry |
| **Student 1** | Aarav Patel | `student1@apex.edu` | `Password@123` | Class 12 - Physics, Class 12 - Maths |
| **Student 2** | Priya Sharma | `student2@apex.edu` | `Password@123` | Class 12 - Physics, Class 12 - Maths |

---

## 5. Local Development & Build Instructions

### A. Run Backend API Locally
```bash
cd apps/api
npm install
npx prisma generate
npx prisma db push
npm run db:reset-demo
npm run dev
# Server starts at http://localhost:4000
# Admin Console available at http://localhost:4000/admin/
```

### B. Run API Unit & Sanity Tests
```bash
cd apps/api
npm test
# Runs 72 automated test cases across 12 test suites (100% passing)
```

### C. Build Android Release APK
```bash
cd apps/mobile_flutter
flutter pub get
flutter analyze
flutter build apk --release --no-tree-shake-icons
# Output located at apps/mobile_flutter/build/app/outputs/flutter-apk/app-release.apk
```

---

## 6. API Endpoints Reference

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `POST` | `/api/v1/auth/login` | Email/password login returning access & refresh tokens |
| `POST` | `/api/v1/auth/refresh` | Rotates refresh token and returns fresh access token |
| `GET` | `/api/v1/auth/me` | Fetches authenticated user profile and institute data |
| `GET` | `/api/v1/batches` | Lists batches for user's institute/role |
| `POST` | `/api/v1/timetable` | Creates a recurring timetable slot with conflict check |
| `GET` | `/api/v1/timetable` | Retrieves timetable slots filtered by enrolled batch |
| `POST` | `/api/v1/classes` | Creates a scheduled live class |
| `POST` | `/api/v1/classes/:id/start` | Starts live class (status -> `LIVE`) |
| `POST` | `/api/v1/classes/:id/token` | Generates LiveKit signed room access token |
| `POST` | `/api/v1/classes/:id/end` | Ends live class (status -> `ENDED`) |
| `GET` | `/api/v1/assignments` | Fetches study material and assignments |
| `POST` | `/api/v1/assignments` | Creates study material (document upload is optional) |
| `GET` | `/api/v1/recordings` | Lists recorded lectures for batch |
| `POST` | `/api/v1/recordings` | Registers a recorded lecture URL or local session |
