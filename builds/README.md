# Classora Builds Directory

This directory stores generated release APKs for the Classora Flutter application.

## Rules
- All `*.apk` files in this directory are ignored by Git (per `.gitignore`).
- Only this `README.md` is committed and tracked.
- Each build produces a universal release APK: `Classora-<yyyyMMdd-HHmm>.apk`.

## Latest Release Build Information

- **Build File:** `Classora-20261017-2325-21b88b59.apk` (and `Classora-Latest.apk` in builds directory)
- **Build Date:** 2026-10-17 23:25 IST
- **App Version:** `2.0.0+1` (Commit: `21b88b59`)
- **File Size:** 114,300,000 bytes (~109.0 MB)
- **SHA-256 Checksum:** `2F8A7FB4B922591456CBF2D438ECA65818BF4C2EFFE40058F3D5874CBE571BA5`
- **Design System:** Reference UI with Bug A (tile mic publication sync), Bug B (whiteboard stage sync & PiP camera), and Bug C (Android 14 MediaProjection foreground service protection).

### Client Experience & Zero-Configuration Architecture
- **100% Zero URL Configuration:** Clients and users never have to paste, type, or configure any server URL.
- **Server Settings Gear Hidden:** The ⚙️ settings icon is hidden in release mode so clients see a completely clean, professional login screen.
- **Secret Developer Access:** Developers and QA can tap the Classora "C" logo 5 times to reveal the server diagnostics modal if needed.
- **Dynamic Cloud Sync:** On startup, the app automatically checks `server_config.json` for live endpoint updates without requiring APK re-installs.
- **Primary Backend URL (Active):** `https://nelson-consist-feels-applicable.trycloudflare.com/api`
- **Video Stream SFU:** LiveKit Cloud via server-issued signed JWT tokens.
- **Runtime Database:** Local SQLite (`dev.db`).
