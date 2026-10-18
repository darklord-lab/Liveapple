# Classora Builds Directory

This directory stores generated release APKs for the Classora Flutter application.

## Rules
- All `*.apk` files in this directory are ignored by Git (per `.gitignore`).
- Only this `README.md` is committed and tracked.
- Each build produces a universal release APK: `Classora-<yyyyMMdd-HHmm>.apk`.

## Latest Release Build Information

- **Release Build (Screen share hidden on Android):**
  - **File:** `builds/Classora-20261018-113345.apk` (and `Classora-Latest.apk`)
  - **Date:** 2026-10-18 11:33 IST
  - **App Version:** `2.0.0+1` (Commit: `7c4fd73b`)
  - **File Size:** 114,357,750 bytes (~109.1 MB)
  - **SHA-256 Checksum:** `8A09B7D384459AC6D614C84D63DC25133343CBB3BD42B6BCC07B17F623D4F94E`

- **Screen Share Test Build (`ENABLE_ANDROID_SCREEN_SHARE=true`):**
  - **File:** `builds/Classora-SCREENSHARE-TEST-20261018-113345.apk`
  - **Date:** 2026-10-18 11:44 IST
  - **App Version:** `2.0.0+1` (Commit: `7c4fd73b`)
  - **File Size:** 114,422,278 bytes (~109.1 MB)
  - **SHA-256 Checksum:** `59A9F2EC1684E347AC5EDA252FDB7C686850571BEB51DD5EEA85D91D88C5D73F`
  - **Description:** Compiled specifically for physical phone testing with screen share enabled.

### Client Experience & Zero-Configuration Architecture
- **100% Zero URL Configuration:** Clients and users never have to paste, type, or configure any server URL.
- **Server Settings Gear Hidden:** The ⚙️ settings icon is hidden in release mode so clients see a completely clean, professional login screen.
- **Secret Developer Access:** Developers and QA can tap the Classora "C" logo 5 times to reveal the server diagnostics modal if needed.
- **Dynamic Cloud Sync:** On startup, the app automatically checks `server_config.json` for live endpoint updates without requiring APK re-installs.
- **Primary Backend URL (Active):** `https://nelson-consist-feels-applicable.trycloudflare.com/api`
- **Video Stream SFU:** LiveKit Cloud via server-issued signed JWT tokens.
- **Runtime Database:** Local SQLite (`dev.db`).
