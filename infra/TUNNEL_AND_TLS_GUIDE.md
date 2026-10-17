# Cloudflare Named Tunnel & Direct TLS Architecture Guide — Classora 2.0

This guide covers deployment topologies for production traffic routing, TLS termination, and WebRTC streaming for Classora 2.0.

---

## 1. Cloudflare Named Tunnel Setup (Recommended for Web/API)

Cloudflare Named Tunnels allow hosting Classora backend services on private infrastructure (bare metal, home server, private VPC) with **zero inbound ports open** on firewalls.

### Step 1: Install `cloudflared`
```bash
# Debian / Ubuntu
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /etc/apt/trusted.gpg.d/cloudflare.gpg >/dev/null
echo 'deb https://pkg.cloudflare.com/cloudflared bullseye main' | sudo tee /etc/apt/sources.list.d/cloudflared.list
sudo apt-get update && sudo apt-get install cloudflared

# macOS
brew install cloudflare/cloudflare/cloudflared
```

### Step 2: Authenticate and Create Tunnel
```bash
cloudflared tunnel login
cloudflared tunnel create classora-prod-tunnel
```
This generates credentials in `~/.cloudflared/<tunnel-id>.json`.

### Step 3: Route DNS Records
```bash
cloudflared tunnel route dns classora-prod-tunnel api.classora.com
cloudflared tunnel route dns classora-prod-tunnel admin.classora.com
cloudflared tunnel route dns classora-prod-tunnel livekit.classora.com
```

### Step 4: Run Tunnel
```bash
cloudflared tunnel --config infra/tunnel.yml run
```
To run as a system daemon:
```bash
sudo cloudflared service install --config /path/to/infra/tunnel.yml
sudo systemctl start cloudflared
```

---

## 2. Direct TLS Alternative (Caddy or Nginx)

When running on a public VPS (e.g. AWS EC2, DigitalOcean, Hetzner) where you manage automated Let's Encrypt certificates directly:

### Option A: Caddy Server (Automated HTTPS + WebSocket)
Install Caddy: `sudo apt install caddy`.
Create `/etc/caddy/Caddyfile`:
```caddy
api.classora.com {
    reverse_proxy localhost:4000
}

livekit.classora.com {
    reverse_proxy localhost:7880
}
```
Reload Caddy: `sudo systemctl reload caddy`. Caddy automatically handles ACME TLS certificates and automatic renewals.

### Option B: Nginx Reverse Proxy with Certbot
```nginx
server {
    server_name api.classora.com;

    location / {
        proxy_pass http://127.0.0.1:4000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```
Run `certbot --nginx -d api.classora.com`.

---

## 3. WebRTC Port Forwarding & Firewall Architecture

> [!IMPORTANT]
> WebRTC media (audio/video UDP packets) requires direct peer-to-SFU latency and CANNOT be proxied through standard HTTP reverse proxies or basic Cloudflare HTTP tunnels without Cloudflare Spectrum.

### Required Inbound Firewall Openings for LiveKit SFU:
| Port | Protocol | Purpose |
|---|---|---|
| `7880` | TCP | LiveKit HTTP/WebSocket signaling (can be proxied via TLS) |
| `7881` | TCP | LiveKit WebRTC TCP fallback |
| `7882` | UDP | LiveKit WebRTC Primary UDP media |
| `50000 - 60000` | UDP | WebRTC ICE candidate dynamic port range |

### Firewall Rule (UFW on Ubuntu):
```bash
sudo ufw allow 7880/tcp
sudo ufw allow 7881/tcp
sudo ufw allow 7882/udp
sudo ufw allow 50000:60000/udp
sudo ufw reload
```
