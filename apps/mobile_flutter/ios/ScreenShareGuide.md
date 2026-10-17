# iOS Screen-Sharing Broadcast Extension Setup Guide — Classora 2.0

LiveKit WebRTC screen sharing on iOS requires an Apple **Broadcast Upload Extension** (using ReplayKit) and an **App Group** to transfer video frames from the extension process to the Classora Flutter app.

---

## 1. Prerequisites in Apple Developer Portal & Xcode

1. Open `ios/Runner.xcworkspace` in Xcode.
2. In **Signing & Capabilities**:
   - Add capability: **App Groups**.
   - Create App Group: `group.com.classora.classoraMobile`.

---

## 2. Add Broadcast Upload Extension Target in Xcode

1. In Xcode: File -> New -> Target...
2. Select **Broadcast Upload Extension** (iOS).
3. Name: `ClassoraBroadcastExtension`.
4. Language: **Swift**.
5. Do NOT include UI extension.
6. For the new target, add capability: **App Groups** and check `group.com.classora.classoraMobile`.

---

## 3. Extension Implementation (`SampleHandler.swift`)

Replace the generated `SampleHandler.swift` with:

```swift
import ReplayKit
import LiveKit

class SampleHandler: RPBroadcastSampleHandler {
    private var client: BroadcastUploadExtensionClient?

    override func broadcastStarted(setupInfo: [String : NSObject]?) {
        // Connect to the shared App Group buffer
        client = BroadcastUploadExtensionClient(appGroup: "group.com.classora.classoraMobile")
    }

    override func broadcastPaused() {}

    override func broadcastResumed() {}

    override func broadcastFinished() {
        client = nil
    }

    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case .video:
            // Send video frames to the Classora LiveKit WebRTC client
            client?.process(sampleBuffer)
        case .audioApp, .audioMic:
            break
        @unknown default:
            break
        }
    }
}
```

---

## 4. Podfile Configuration for Extension

In `ios/Podfile`:

```ruby
target 'ClassoraBroadcastExtension' do
  use_frameworks!
  pod 'LiveKitClient'
end
```

Run:
```bash
cd ios
pod install
```

---

## 5. Triggering Screen Share in Flutter

To present the iOS native system broadcast picker in Flutter:
```dart
import 'package:flutter_webrtc/flutter_webrtc.dart';

// Launches native iOS ReplayKit broadcast picker
Helper.showIOSBackgroundRecordDialog();
```
