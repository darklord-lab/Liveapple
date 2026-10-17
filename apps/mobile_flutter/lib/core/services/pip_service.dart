import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service managing native Android and cross-platform Picture-in-Picture (PiP) capabilities.
class PipService {
  static const MethodChannel _channel = MethodChannel('com.classora.app/pip');

  final ValueNotifier<bool> _isPipActiveNotifier = ValueNotifier<bool>(false);
  bool _initialized = false;

  PipService() {
    _initChannelHandler();
  }

  /// ValueNotifier exposing whether the app is currently in PiP mode.
  ValueNotifier<bool> get isPipActiveNotifier => _isPipActiveNotifier;

  /// Whether PiP is currently active.
  bool get isPipActive => _isPipActiveNotifier.value;

  void _initChannelHandler() {
    if (_initialized) return;
    _initialized = true;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onPipModeChanged') {
        final active = call.arguments as bool? ?? false;
        _isPipActiveNotifier.value = active;
      }
    });
  }

  /// Checks if the current device/OS supports Picture-in-Picture.
  Future<bool> isPipSupported() async {
    try {
      final supported = await _channel.invokeMethod<bool>('isPipSupported');
      return supported ?? false;
    } catch (_) {
      // In desktop, test, or unsupported environments, return false gracefully
      return false;
    }
  }

  /// Requests the OS to transition the active activity into Picture-in-Picture mode.
  /// [width] and [height] define the aspect ratio (e.g. 16:9 for landscape, 9:16 for portrait).
  Future<bool> enterPip({int width = 16, int height = 9}) async {
    try {
      final success = await _channel.invokeMethod<bool>('enterPip', {
        'width': width,
        'height': height,
      });
      if (success == true) {
        _isPipActiveNotifier.value = true;
      }
      return success ?? false;
    } catch (e) {
      debugPrint('[PipService] enterPip error: $e');
      return false;
    }
  }

  /// Queries native side whether PiP mode is currently active.
  Future<bool> queryIsPipActive() async {
    try {
      final active = await _channel.invokeMethod<bool>('isPipActive');
      final val = active ?? false;
      _isPipActiveNotifier.value = val;
      return val;
    } catch (_) {
      return _isPipActiveNotifier.value;
    }
  }

  /// Manually update PiP state (for test environments or in-app mock toggles)
  @visibleForTesting
  void setPipActiveForTesting(bool active) {
    _isPipActiveNotifier.value = active;
  }
}

/// Provider for the singleton PipService.
final pipServiceProvider = Provider<PipService>((ref) {
  return PipService();
});

/// StateNotifier to track PiP state reactively in Riverpod.
class PipStateNotifier extends StateNotifier<bool> {
  final PipService _service;
  late final VoidCallback _listener;

  PipStateNotifier(this._service) : super(_service.isPipActive) {
    _listener = () {
      if (state != _service.isPipActive) {
        state = _service.isPipActive;
      }
    };
    _service.isPipActiveNotifier.addListener(_listener);
  }

  @override
  void dispose() {
    _service.isPipActiveNotifier.removeListener(_listener);
    super.dispose();
  }
}

/// Reactive provider for PiP active status.
final isPipActiveProvider = StateNotifierProvider<PipStateNotifier, bool>((ref) {
  final service = ref.watch(pipServiceProvider);
  return PipStateNotifier(service);
});
