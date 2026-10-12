# Classora Builds Directory

This directory stores generated release APKs for the Classora Flutter application.

## Rules
- All `*.apk` files in this directory are ignored by Git (per `.gitignore`).
- Only this `README.md` is committed and tracked.
- Each build produces a universal release APK: `Classora-<yyyyMMdd-HHmm>.apk`.

## Latest Release Build Information

- **Build File:** `Classora-20261011-1447.apk` (and `Classora-Latest.apk` in project root)
- **Build Date:** 2026-10-11 14:47 IST
- **App Version:** `2.0.0+1`
- **File Size:** 94,778,427 bytes (90.4 MB)
- **SHA-256 Checksum:** `A0F7240A3B0F3C35773193A29F495F8C1C2E9F4B46A771A284C06B33BA3484C8`
- **Design System:** Reference UI (Light-first, Sky-blue app bar, Plus Jakarta Sans font, 4-tab bottom navigation, Drawer, Coloured Quick Access tiles, Schedule Day Strip, Study Material with Filter Sheet, Settings)

### Client Experience & Zero-Configuration Architecture
- **100% Zero URL Configuration:** Clients and users never have to paste, type, or configure any server URL.
- **Server Settings Gear Hidden:** The ⚙️ settings icon is hidden in release mode so clients see a completely clean, professional login screen.
- **Secret Developer Access:** Developers and QA can tap the Classora "C" logo 5 times to reveal the server diagnostics modal if needed.
- **Dynamic Cloud Sync:** On startup, the app automatically checks `server_config.json` for live endpoint updates without requiring APK re-installs.
- **Primary Backend URL (Active):** `https://nelson-consist-feels-applicable.trycloudflare.com/api`
- **Video Stream SFU:** LiveKit Cloud via server-issued signed JWT tokens.
- **Runtime Database:** Local SQLite (`dev.db`).
