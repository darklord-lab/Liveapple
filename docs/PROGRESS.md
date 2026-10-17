# Classora Live Classroom Fix — PROGRESS

## Stage 0 (Diagnosis)
- [x] 0.1 Root cause: student token canPublish:false (livekit.service.ts:51)
- [x] 0.2 Root cause report written (see FINAL REPORT at end)
- [ ] 0.3 Deploy poll after final push
- [ ] 0.4 Smoke test gate

## Stage 1 (Core live class)
- [ ] 1.1 Fix student canPublish + canPublishSources; loudspeaker ON; real tiles; mute/lock/unlock
- [ ] 1.2 Stage sync (VIDEO|SCREEN|BOARD|SLIDES) via socket
- [ ] 1.3 Whiteboard stroke sync to students via socket; board:toggle propagation
- [ ] 1.4 Controls bar: 320dp fit, snackbar above bar, hide Record, student Raise Hand

## Stage 2 (Present + laptop)
- [ ] 2.1 Screen share (Android MediaProjection + teacher-only)
- [ ] 2.2 PDF slides presenter
- [ ] 2.3 Flutter Web build + SPA serve + CSP
- [ ] 2.4 One device per user takeover

## Stage 3 (Hardening)
- [ ] 3.1 FORCE_DEMO_RESET guard, student home header, class uniqueness
- [ ] 3.2 Tests (compact)
- [ ] 3.3 Build web + APK, push only if passing
