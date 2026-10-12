# Classora 2.0 — Production Release & Hardening Guide

## 1. Flutter Mobile App Release Build (Android & iOS)

### Android App Bundle (.aab) with Code Obfuscation
Run the following command to build an optimized, obfuscated production Android App Bundle for Google Play Store:

```bash
cd apps/mobile_flutter

# 1. Clean and fetch dependencies
flutter clean
flutter pub get

# 2. Build obfuscated Android App Bundle
flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=./build/app/outputs/symbols \
  --tree-shake-icons
```

> **Note on Symbol Files**: The debug symbols are saved to `./build/app/outputs/symbols`. Upload these symbols to Google Play Console / Firebase Crashlytics to de-obfuscate crash stack traces.

---

### iOS Release Build (IPA / TestFlight)
```bash
cd apps/mobile_flutter

flutter build ipa --release \
  --obfuscate \
  --split-debug-info=./build/ios/outputs/symbols \
  --export-options-plist=ios/ExportOptions.plist
```

---

## 2. Security & Anti-Tamper Protections
- **Secure Storage**: Access tokens, refresh tokens, and tenant identifiers are stored via `flutter_secure_storage` encrypted in Android Keystore / iOS Keychain.
- **FLAG_SECURE**: Enabled for sensitive views (fees receipt, live test examination) to prevent unauthorized screenshots.
- **R8 / ProGuard**: Enabled in `android/app/build.gradle` for native bytecode shrinking, optimization, and obfuscation.

---

## 3. Backend Production Deployment (Node.js / Docker)

### Docker Deployment
```bash
# Build and run API + LiveKit SFU stack
docker-compose -f infra/docker-compose.yml up -d --build
```

### Production Environment Variables (.env)
```env
PORT=4000
NODE_ENV=production
DATABASE_URL="postgresql://user:pass@host:5432/classora_prod?schema=public"
JWT_SECRET="<generate-64-byte-secure-secret>"
LIVEKIT_API_KEY="<production-livekit-key>"
LIVEKIT_API_SECRET="<production-livekit-secret>"
LIVEKIT_HOST="wss://livekit.classora.com"
FIREBASE_PROJECT_ID="classora-2-prod"
FIREBASE_CLIENT_EMAIL="firebase-adminsdk@classora-2-prod.iam.gserviceaccount.com"
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
CORS_ORIGIN="https://app.classora.com,https://admin.classora.com"
```

---

## 4. Operational Checklist Before Launch
1. [x] Run full automated test suite: `npm test` (70/70 passing).
2. [x] Run 100-student concurrency load test: `npm run test:load`.
3. [x] Verify Flutter analyzer: `flutter analyze` (0 issues).
4. [ ] Configure production domain SSL certificates (HTTPS + WSS for LiveKit & WebSockets).
5. [ ] Upload Firebase `google-services.json` (Android) and `GoogleService-Info.plist` (iOS).
