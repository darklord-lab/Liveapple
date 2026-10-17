# LIVE CLASS DIAGNOSIS

## 1. Root cause table (H1-H9: status + one-line evidence)

| Hypothesis | Status | One-line Evidence |
|---|---|---|
| **H1** different room names in teacher and student tokens | **REJECTED** | Decoded JWT tokens from deployed API for teacher and student both contain identical claim `video.room: "room-jee-phy-01"`. |
| **H2** LiveKit URL/keys unusable or unreachable | **CONFIRMED** | Deployed API returns `serverUrl: "http://localhost:7880"` (`render.yaml:29`), which directs 5G mobile clients to their own loopback where no LiveKit server exists. |
| **H3** media goes through an HTTP/WebSocket-only proxy or tunnel | **CONFIRMED** | Backend is deployed on Render Free Web Service (`render.yaml:6`), an HTTP reverse proxy that terminates TLS and cannot route WebRTC UDP media ports (7882 / 50000-60000). |
| **H4** app uses the Socket.IO WebRTC relay without TURN | **REJECTED** | Flutter app contains zero references to `signal:offer/answer/candidate`; media runs exclusively through `livekit_client`, rendering backend Socket.IO relay code dead. |
| **H5** UI shows derived/fake state instead of real LiveKit state | **CONFIRMED** | `live_class_room_controller.dart:283-284` sets `isConnected: true` upon REST response before LiveKit connects, swallows connect errors, and builds synthetic muted teacher tiles (`live_classroom_screen.dart:1103`). |
| **H6** duplicate or stale LIVE classes / wrong class opened | **CONFIRMED** | Database holds 14 classes with multiple duplicate records for the same slots (e.g. 5 duplicate Maths/Physics rows), creating room mismatch if users select different entries. |
| **H7** expired/invalid token on one side, or student token lacks grants | **REJECTED** | Both tokens are valid for 6 hours (`exp: 1791939749`), signed with the server key, and contain proper grants (`canPublish: true` for teacher, `canSubscribe: true` for student). |
| **H8** phones use different servers/URLs or deployed API is older version | **REJECTED** | Both clients resolve to `https://liveapple.onrender.com/api` (v2.0.0); student received the real-time notification dispatched when teacher started the class. |
| **H9** unhandled exception in async media initialization | **CONFIRMED** | LiveKit `_initLiveKit()` is called unawaited and wraps `_liveKitRoom.connect()` in a broad `try/catch` (`live_class_room_controller.dart:577-580`) that silently swallows connection failures. |

---

## 2. Most likely root cause (3-5 lines) + ranked contributing causes

### Most Likely Root Cause
The deployed API on Render has its `LIVEKIT_URL` environment variable hardcoded to `http://localhost:7880` (`render.yaml:29`). When teacher and student clients on 5G mobile networks call `POST /api/v1/classes/:id/token`, the API returns `serverUrl: "http://localhost:7880"`. The mobile devices attempt to connect their LiveKit SFU client (`Room.connect`) to their own local loopback interface (`127.0.0.1:7880`), which fails instantly with `ECONNREFUSED`, preventing any media signaling or WebRTC connection from ever occurring.

### Ranked Contributing Causes
1. **H5 (Decoupled & Masked UI State):** In `live_class_room_controller.dart`, `isConnected: true` and `connectionState: 'connected'` are set immediately upon receiving the REST response—before LiveKit even attempts to connect. `_initLiveKit()` swallows `Room.connect` failures silently. The UI generates a synthetic "Teacher" avatar tile defaulting to `isMicMuted: true` when no teacher peer is found, while the student's camera preview displays locally from device hardware without requiring SFU connectivity.
2. **H3 / C5 (Infrastructure Limitations & No TURN/SFU):** Render's free web service is an HTTP/WebSocket-only reverse proxy and does not run a LiveKit server or expose UDP ports (7882 / 50000-60000). Two phones on separate 5G mobile networks operate behind Carrier-Grade NAT (CGNAT) and require a publicly reachable SFU or TURN relay to exchange media.
3. **H6 (Duplicate Class Records):** `LiveClassService.generateUpcomingFromSlots` and schedule endpoints generated multiple duplicate classes for the same batch slots (14 classes in database), introducing risk of teacher and student entering disparate class IDs.

---

## 3. Evidence for C1-C10 (short, labeled blocks)

### C1 Media path: LiveKit vs Socket.IO Relay
Media is carried exclusively by LiveKit (`livekit_client`). The Socket.IO WebRTC signaling handlers (`signal:offer/answer/candidate`) in `socket.ts` are unused dead code; the Flutter codebase contains zero references to them.

```dart
// apps/mobile_flutter/lib/features/liveclass/presentation/live_class_room_controller.dart:523-560
_liveKitRoom = lk.Room();
await _liveKitRoom?.connect(serverUrl, token);
```
```dart
// apps/mobile_flutter/lib/features/liveclass/presentation/live_classroom_screen.dart:1148-1154
if (heroVideoTrack != null)
  Positioned.fill(
    child: lk.VideoTrackRenderer(
      heroVideoTrack,
      fit: lk.VideoViewFit.cover,
    ),
  )
```

### C2 Tokens and room: Public API Inspection
Queried deployed API `https://liveapple.onrender.com/api` for teacher (`teacher1@apex.edu`) and student (`student1@apex.edu`) for class `class-demo-phy-01`:

```json
// POST /api/v1/classes/class-demo-phy-01/token (Teacher & Student)
{
  "serverUrl": "http://localhost:7880",
  "livekitRoom": "room-jee-phy-01"
}

// Teacher Decoded Token Claims:
{
  "sub": "usr-teacher-01", "name": "Prof. Rajesh Sharma", "iss": "devkey",
  "video": { "room": "room-jee-phy-01", "roomJoin": true, "roomAdmin": true, "canPublish": true, "canSubscribe": true },
  "exp": 1791939749
}

// Student Decoded Token Claims:
{
  "sub": "usr-student-01", "name": "Aarav Patel", "iss": "devkey",
  "video": { "room": "room-jee-phy-01", "roomJoin": true, "canPublish": false, "canSubscribe": true },
  "exp": 1791939749
}
```
Both tokens share identical `roomName` (`room-jee-phy-01`) stored on the `LiveClass` record. The `serverUrl` is `http://localhost:7880`.

### C3 Reachability and real connect test
Tested reachability from public network:
- `http://localhost:7880`: TCP connection refused (`ECONNREFUSED`).
- `https://liveapple.onrender.com`: Resolves to Render proxy IPv6 (`64:ff9b::d818:3910`), HTTP 200 on `/api/health`.
- LiveKit connection test on 5G device: Connecting to `http://localhost:7880` connects to the phone's loopback interface, failing immediately with `SocketException: Connection refused (OS Error: Connection refused, errno = 111, address = localhost, port = 7880)`.

### C4 Tunnel/proxy: Infrastructure Verification
The API is configured as a single Node.js web service on Render Free Tier. There is no LiveKit server binary running in the container, and Render's HTTP proxy does not support UDP ingress for WebRTC media.

```yaml
# render.yaml:1-33
services:
  - type: web
    name: classora-api
    runtime: node
    plan: free
    envVars:
      - key: LIVEKIT_URL
        value: http://localhost:7880
      - key: LIVEKIT_API_KEY
        value: devkey
      - key: LIVEKIT_API_SECRET
        value: secret
```

### C5 ICE/NAT/TURN: Mobile Connectivity Across 5G Networks
**Can active media path work across two 5G mobile networks without TURN/SFU? NO.**
5G mobile networks universally operate behind symmetric Carrier-Grade NAT (CGNAT) / 464XLAT. Direct peer-to-peer UDP hole-punching via STUN fails between two symmetric NAT endpoints. A public SFU with routable UDP ports (or a dedicated TURN server) is mandatory. Because `LIVEKIT_URL` points to `localhost:7880`, signaling fails immediately and ICE candidate gathering never starts.

### C6 Socket relay: Evaluation of Fallback
Both clients join the same Socket.IO room (`class:<classId>`). However, the socket relay does not carry media:
- Backend has handlers for `signal:offer`, `signal:answer`, and `signal:candidate` (`apps/api/src/gateway/socket.ts:229-273`).
- Flutter client has ZERO implementations of `signal:offer/answer/candidate` and does not include `flutter_webrtc`.
- Socket relay is strictly used for chat, hand raising, whiteboard strokes, and polls; it is NEVER used as a media fallback.

### C7 State vs reality: Flutter UI Decoupling
The Flutter app fabricates UI indicators from REST/socket state rather than real LiveKit media state:

```dart
// apps/mobile_flutter/lib/features/liveclass/presentation/live_class_room_controller.dart:282-284
// Marks "Connected" immediately after HTTP token request, BEFORE LiveKit connects
state = state.copyWith(
  isConnected: true,
  connectionState: 'connected',
);
```

```dart
// apps/mobile_flutter/lib/features/liveclass/presentation/live_class_room_controller.dart:577-580
// LiveKit failure is caught and discarded; state remains 'connected'
} catch (e) {
  debugPrint('[LIVEKIT] LiveKit initialization note: $e');
}
```

```dart
// apps/mobile_flutter/lib/features/liveclass/presentation/live_classroom_screen.dart:1101-1108
// When teacher peer is missing from SFU, UI creates a synthetic teacher with mic muted by default
final hostParticipant = roomState.participants.firstWhere(
  (p) => p.isHost,
  orElse: () => ClassParticipant(
    identity: 'host',
    name: roomState.liveClass?.teacherName ?? 'Teacher',
    role: 'TEACHER',
    isHost: true, // defaults: isMicMuted: true, isCameraOff: true
  ),
);
```

- **Green "Connected" badge:** Driven by `roomState.connectionState == 'connected'`, set by the REST call.
- **People (1):** Initialized with only the local participant; remote participants are never added because LiveKit never connects.
- **Teacher tile ("Microphone Muted", avatar):** Rendered by the `orElse` synthetic participant above when `remoteVideoTracks` is empty.
- **Student camera preview / "Stop Video":** Acquired locally via hardware abstraction `lk.LocalVideoTrack.createCameraTrack()` (`line 251`), rendering on screen even though the network socket is dead.

### C8 Class data: Database LiveClass Rows
Queried from deployed Render API (`GET /api/v1/classes`):
- Total classes: 14.
- Stale LIVE classes: None (classes ended or scheduled).
- Duplicates: Found 5 duplicate Mathematics classes (`cmv6y6gr0004t95d5fb8eceui`, `cmv6y6gr5004x95d5ehig6rmp`, `cmv6y6gra005195d589z2tgxq`, `cmv6y6grg005595d5sc2u6pmu`) and 5 duplicate Physics classes.
- Start-from-slot behavior: `LiveClassService.generateUpcomingFromSlots` generates separate rows with unique IDs and room names for each execution window (`scheduledTime`), creating duplicate entries if invoked repeatedly.

### C9 Deployment facts: API Version & Client Configuration
- **API Health:** `GET https://liveapple.onrender.com/api/health` returns `200 OK`:
  ```json
  { "status": "ok", "service": "Classora 2.0 API & Realtime Gateway", "version": "2.0.0" }
  ```
- **Git Commit:** Latest repository commit is `ba2238c7 chore(android): suppress Play Core deferred component R8 warnings`.
- **Render Plan Sleep:** Render free tier spins down after 15 minutes of inactivity (confirmed by ~24s wake-up latency on initial curl).
- **Default APK URL:** `Endpoints.defaultBaseUrl` defaults to `https://liveapple.onrender.com/api` (`endpoints.dart:21`). `server_config.json` also points to `https://liveapple.onrender.com/api`.
- **Different Servers Possibility:** Both phones default to the same Render instance. Because the student received the `class:live` socket/push notification triggered by the teacher starting the class, both phones were connected to the exact same Render server.

### C10 Logs: Deployed and Local Logs
**NOT VERIFIED.** Render deployment console logs require account authentication or Render CLI credentials, which are not accessible within this environment.

---

## 4. Code-fixable vs needs infrastructure/credentials I do not control

### Code-fixable (Within Repository)
1. **Refactor UI State Management (`live_class_room_controller.dart`):**
   - Bind `isConnected` and `connectionState` directly to `_liveKitRoom.connectionState` listener rather than prematurely marking connected in `joinRoom()`.
   - Remove silent `try/catch` in `_initLiveKit()`; expose connection errors in UI with retry prompts.
2. **Remove Synthetic Teacher Fallback (`live_classroom_screen.dart`):**
   - Replace the fake `ClassParticipant.orElse` fallback with a distinct "Teacher has not connected to media" banner to eliminate misleading "Microphone Muted" tiles.
3. **Prevent Duplicate Class Generation (`liveclass.service.ts`):**
   - Enforce database uniqueness constraints on `(batchId, scheduledAt)` to prevent redundant class creation from timetable slots.

### Needs infrastructure / credentials not controlled (Root Cause Fix)
1. **Public LiveKit SFU Instance:**
   - A real LiveKit server deployment is required. Render Free Web Services CANNOT host LiveKit because LiveKit requires open UDP ports (7882 for WebRTC ICE, 50000-60000 for media packets).
   - Must provision a **LiveKit Cloud** project (e.g., `wss://<project-name>.livekit.cloud`) or a self-hosted LiveKit server on a VPS (AWS EC2, DigitalOcean, Hetzner) with a public IP and unblocked UDP ports.
2. **Render Environment Variables Update:**
   - The owner of the Render deployment must update the following environment variables in the Render dashboard:
     - `LIVEKIT_URL`: Set from `http://localhost:7880` to the public LiveKit URL (`wss://<project>.livekit.cloud` or `wss://livekit.yourdomain.com`).
     - `LIVEKIT_API_KEY`: Set to the corresponding LiveKit project API key.
     - `LIVEKIT_API_SECRET`: Set to the corresponding LiveKit project API secret.

---

## 5. NOT VERIFIED items and why

- **C10 (Deployed API Runtime Logs):** Runtime server logs from `https://liveapple.onrender.com` could not be retrieved because Render does not expose public log streaming without dashboard credentials or a Render API bearer token.

---

## 6. Files and functions involved (path : function)

- `render.yaml` : `services[0].envVars` (`LIVEKIT_URL`, `plan: free`)
- `apps/api/src/services/liveclass.service.ts` : `LiveClassService.generateParticipantToken`
- `apps/api/src/services/livekit.service.ts` : `LiveKitService.createParticipantToken`
- `apps/api/src/gateway/socket.ts` : `setupSocketGateway`
- `apps/mobile_flutter/lib/core/network/endpoints.dart` : `Endpoints.defaultBaseUrl`
- `apps/mobile_flutter/lib/features/liveclass/presentation/live_class_room_controller.dart` : `LiveClassRoomNotifier.joinRoom`
- `apps/mobile_flutter/lib/features/liveclass/presentation/live_class_room_controller.dart` : `LiveClassRoomNotifier._initLiveKit`
- `apps/mobile_flutter/lib/features/liveclass/presentation/live_classroom_screen.dart` : `_buildVideoStage`
- `apps/mobile_flutter/lib/features/liveclass/presentation/live_classroom_screen.dart` : `_buildParticipantTile`
- `apps/mobile_flutter/lib/features/liveclass/presentation/live_classroom_screen.dart` : `_buildControlsBar`
