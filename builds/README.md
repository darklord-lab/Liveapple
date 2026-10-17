# Classora Builds Directory

This directory stores generated release APKs for the Classora Flutter application.

## Rules
- All `*.apk` files in this directory are ignored by Git (per `.gitignore`).
- Only this `README.md` is committed and tracked.
- Each build produces a universal release APK: `Classora-<yyyyMMdd-HHmm>.apk`.

## Latest Release Build Information

- **Build File:** `Classora-20261017-2130.apk` (and `Classora-Latest.apk` in builds directory)
- **Build Date:** 2026-10-17 21:30 IST
- **App Version:** `2.0.0+1`
- **File Size:** 114,110,870 bytes (108.8 MB)
- **SHA-256 Checksum:** `C6F6A385A86BFF3FFDA1693FB6E3DA6B984A605873718649BACED53C2CBFCC4B`
- **Design System:** Reference UI (Light-first, Sky-blue app bar, Plus Jakarta Sans font, 4-tab bottom navigation, Live Class with bidirectional LiveKit Cloud publishing, Stage sync, Digital Whiteboard, Screen Share, Lecture Docs, 7-button uncluttered bottom bar, floating non-blocking toasts, Loudspeaker hardware routing)

### Client Experience & Zero-Configuration Architecture
- **100% Zero URL Configuration:** Clients and users never have to paste, type, or configure any server URL.
- **Server Settings Gear Hidden:** The ⚙️ settings icon is hidden in release mode so clients see a completely clean, professional login screen.
- **Secret Developer Access:** Developers and QA can tap the Classora "C" logo 5 times to reveal the server diagnostics modal if needed.
- **Dynamic Cloud Sync:** On startup, the app automatically checks `server_config.json` for live endpoint updates without requiring APK re-installs.
- **Primary Backend URL (Active):** `https://nelson-consist-feels-applicable.trycloudflare.com/api`
- **Video Stream SFU:** LiveKit Cloud via server-issued signed JWT tokens.
- **Runtime Database:** Local SQLite (`dev.db`).
