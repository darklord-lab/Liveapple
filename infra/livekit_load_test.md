# Classora 2.0 — LiveKit High-Concurrency Load Test (100 Subscribers)

This guide details how to execute realistic 100-subscriber load tests on Classora's LiveKit infrastructure using both the official LiveKit CLI (`lk load-test`) and Classora's integrated backend load benchmark.

---

## 1. Automated Backend Benchmark (`npm run test:load`)

Classora provides an integrated automated stress benchmark simulating 100 concurrent students enrolling, obtaining cryptographically signed LiveKit participant JWTs, and recording attendance in parallel.

### Run Command:
```bash
cd apps/api
npm run test:load
```

### Verified Benchmark Performance:
- **100 Concurrent Enrollees:** ~566 ms (176.7 ops/sec, P99: 563 ms)
- **100 Concurrent LiveKit JWT Signatures:** 13 ms (**7,692 tokens/sec**, P50: 5.04 ms, P99: 12.21 ms)
- **100 Concurrent Live Attendance Ingestion:** 326 ms (306.7 ops/sec, P99: 325 ms)

---

## 2. Real-Time Media Load Testing with `lk load-test`

To benchmark the WebRTC media SFU layer (video, audio, packet loss, bandwidth egress) with 100 real streaming WebRTC subscribers:

### Prerequisites:
Install the official LiveKit CLI:
```bash
# macOS
brew install livekit-cli

# Linux / WSL
curl -sSL https://get.livekit.io/cli | bash

# Windows (via Scoop or binary download)
scoop install livekit-cli
```

### Step 1: Start or Connect to LiveKit SFU
Ensure your LiveKit Server is running (Cloud or Self-Hosted):
```bash
# Example local docker runner
docker run --rm -it -p 7880:7880 -p 7881:7881 -p 7882:7882/udp livekit/livekit-server --dev
```

### Step 2: Teacher Live Stream (1 Publisher)
Launch a simulated teacher publishing 720p 30fps video and high-quality opus audio:
```bash
lk load-test \
  --url ws://localhost:7880 \
  --api-key devkey \
  --api-secret secret \
  --room class-room-benchmark-01 \
  --publishers 1 \
  --subscribers 0 \
  --video-publishing true \
  --video-resolution 720p \
  --audio-publishing true \
  --duration 10m
```

### Step 3: Simulate 100 Active Students (100 Subscribers)
In a separate terminal, launch 100 concurrent simulated student subscribers subscribing to the teacher's tracks:
```bash
lk load-test \
  --url ws://localhost:7880 \
  --api-key devkey \
  --api-secret secret \
  --room class-room-benchmark-01 \
  --publishers 0 \
  --subscribers 100 \
  --video-publishing false \
  --audio-publishing false \
  --duration 10m
```

---

## 3. Resource & Bandwidth Sizing Calculations

### Egress Bandwidth for 100 Subscribers:
- **Teacher Ingress Bitrate:**
  - 720p Video (VP8/H.264): ~1.5 Mbps
  - Opus Audio (48kHz): ~40 kbps
  - Total ingress: **~1.54 Mbps**
- **Server Egress for 100 Subscribers:**
  - 100 × 1.54 Mbps = **~154 Mbps continuous egress**
  - For 1080p stream (~3.0 Mbps): **~300 Mbps continuous egress**

### Server Sizing Recommendations:
| Concurrency | CPU Cores | RAM | Egress Bandwidth | Recommended VPS |
|---|---|---|---|---|
| **100 Students (1 Room)** | 4 vCPU | 8 GB | 250 Mbps | Hetzner CCX23 / AWS c6g.xlarge |
| **500 Students (5 Rooms)** | 8 vCPU | 16 GB | 1 Gbps | Hetzner CCX33 / AWS c6g.2xlarge |
| **2000 Students (Distributed)** | Multi-node | 32 GB | 5 Gbps | LiveKit Cloud / Multi-node Kubernetes |

### Key SFU Configuration Flags:
In `livekit.yaml`:
```yaml
rtc:
  tcp_fallback: true
  use_external_ip: true
  port_range_start: 50000
  port_range_end: 60000
limit:
  num_tracks: 5000
```
