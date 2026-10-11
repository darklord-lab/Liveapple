# Classora Builds Directory

This directory stores generated release APKs for the Classora Flutter application.

## Rules
- All `*.apk` files in this directory are ignored by Git (per `.gitignore`).
- Only this `README.md` is committed and tracked.
- Each build produces a universal release APK: `Classora-<yyyyMMdd-HHmm>.apk`.

## Latest Release Build Information

- **Build File:** `Classora-20261011-1249.apk` (and `Classora-Latest.apk` in project root)
- **Build Date:** 2026-10-11 12:49 IST
- **App Version:** `2.0.0+1`
- **File Size:** 93,794,039 bytes (89.4 MB)
- **SHA-256 Checksum:** `DEEB9D56A684816CE25DFBB3CD4222105370B90555DC181E86E2AD7AA0AF0C93`

### Client Experience & Zero-Configuration Architecture
- **100% Zero URL Configuration:** Clients and users never have to paste, type, or configure any server URL.
- **Server Settings Gear Hidden:** The ⚙️ settings icon is hidden in release mode so clients see a completely clean, professional login screen.
- **Secret Developer Access:** Developers and QA can tap the Classora "C" logo 5 times to reveal the server diagnostics modal if needed.
- **Dynamic Cloud Sync:** On startup, the app automatically checks `server_config.json` for live endpoint updates without requiring APK re-installs.
- **Primary Backend URL (Active):** `https://nelson-consist-feels-applicable.trycloudflare.com/api`
- **Video Stream SFU:** LiveKit Cloud via server-issued signed JWT tokens.
- **Runtime Database:** Local SQLite (`dev.db`).
