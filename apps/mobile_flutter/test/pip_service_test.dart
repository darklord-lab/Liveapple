import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:classora_mobile/core/services/pip_service.dart';
import 'package:classora_mobile/features/learning/domain/models/learning_models.dart';
import 'package:classora_mobile/features/learning/presentation/screens/recordings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('com.classora.app/pip');

  group('Phase 4.7 — PipService Unit Tests', () {
    test('isPipSupported returns true when supported on device', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'isPipSupported') return true;
        return null;
      });

      final service = PipService();
      final supported = await service.isPipSupported();

      expect(supported, true);
    });

    test('isPipSupported returns false on error or unsupported platform', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        throw PlatformException(code: 'UNAVAILABLE');
      });

      final service = PipService();
      final supported = await service.isPipSupported();

      expect(supported, false);
    });

    test('enterPip passes width and height aspect ratio and updates active state', () async {
      Map<dynamic, dynamic>? capturedArgs;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'enterPip') {
          capturedArgs = call.arguments as Map<dynamic, dynamic>?;
          return true;
        }
        return null;
      });

      final service = PipService();
      expect(service.isPipActive, false);

      final entered = await service.enterPip(width: 16, height: 9);

      expect(entered, true);
      expect(service.isPipActive, true);
      expect(capturedArgs?['width'], 16);
      expect(capturedArgs?['height'], 9);
    });

    test('onPipModeChanged from native side updates notifier and listeners', () async {
      final service = PipService();
      bool listenerNotified = false;

      service.isPipActiveNotifier.addListener(() {
        listenerNotified = true;
      });

      // Simulate native callback to Flutter
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        'com.classora.app/pip',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('onPipModeChanged', true),
        ),
        (ByteData? data) {},
      );

      expect(service.isPipActive, true);
      expect(listenerNotified, true);

      // Simulate native callback exiting PiP
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        'com.classora.app/pip',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('onPipModeChanged', false),
        ),
        (ByteData? data) {},
      );

      expect(service.isPipActive, false);
    });
  });

  group('Phase 4.7 — SecurePlayerScreen PiP Widget Tests', () {
    final testRecording = RecordingModel(
      id: 'rec-test-1',
      title: 'Rotational Dynamics Lecture 04',
      batchName: 'Physics Droppers',
      subject: 'Physics',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      durationSec: 2700,
      fileSizeMb: 125.0,
      createdAt: DateTime.now(),
    );

    testWidgets('Renders Picture-in-Picture button in player controls toolbar', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        return true;
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SecurePlayerScreen(recording: testRecording),
          ),
        ),
      );

      // Verify title and protected badge
      expect(find.text('Rotational Dynamics Lecture 04'), findsOneWidget);
      expect(find.text('Protected'), findsWidgets);

      // Verify Picture-in-Picture button exists
      expect(find.byKey(const Key('enter_pip_recording_btn')), findsOneWidget);

      // Tap PiP button
      await tester.tap(find.byKey(const Key('enter_pip_recording_btn')));
      await tester.pumpAndSettle();
    });

    testWidgets('Entering PiP mode hides header and bottom controls', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool pipTriggered = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'enterPip') {
          pipTriggered = true;
          return true;
        }
        return true;
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SecurePlayerScreen(recording: testRecording),
          ),
        ),
      );

      // Initially, controls are visible
      expect(find.text('Rotational Dynamics Lecture 04'), findsOneWidget);
      expect(find.byKey(const Key('enter_pip_recording_btn')), findsOneWidget);

      // Tap to enter PiP
      await tester.tap(find.byKey(const Key('enter_pip_recording_btn')));
      await tester.pump();
      expect(pipTriggered, true);

      // Simulate native OS PiP mode transition
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        'com.classora.app/pip',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('onPipModeChanged', true),
        ),
        (ByteData? data) {},
      );
      await tester.pumpAndSettle();

      // In PiP mode, header bar and bottom controls toolbar are cleanly hidden
      expect(find.text('Rotational Dynamics Lecture 04'), findsNothing);
      expect(find.byKey(const Key('enter_pip_recording_btn')), findsNothing);

      // When exiting PiP mode, controls are restored
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        'com.classora.app/pip',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('onPipModeChanged', false),
        ),
        (ByteData? data) {},
      );
      await tester.pumpAndSettle();

      expect(find.text('Rotational Dynamics Lecture 04'), findsOneWidget);
      expect(find.byKey(const Key('enter_pip_recording_btn')), findsOneWidget);
    });
  });
}
