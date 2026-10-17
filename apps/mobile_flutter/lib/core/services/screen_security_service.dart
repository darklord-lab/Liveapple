import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service managing screen protection (preventing screenshots & screen recordings)
/// on security-sensitive screens such as CBT examinations and proprietary live classrooms.
class ScreenSecurityService {
  static const MethodChannel _channel = MethodChannel('com.classora.app/security');

  static bool _isSecure = false;

  /// Whether secure screen mode is currently active
  static bool get isSecure => _isSecure;

  /// Enable FLAG_SECURE protection (blocks screenshots and screen recordings)
  static Future<void> enableSecureScreen() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('setSecure', {'enabled': true});
      _isSecure = true;
      debugPrint('[ScreenSecurity] FLAG_SECURE enabled successfully');
    } catch (e) {
      debugPrint('[ScreenSecurity] Note: Screen security not supported or failed: $e');
    }
  }

  /// Disable FLAG_SECURE protection (normal screenshot behavior restored)
  static Future<void> disableSecureScreen() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('setSecure', {'enabled': false});
      _isSecure = false;
      debugPrint('[ScreenSecurity] FLAG_SECURE disabled');
    } catch (e) {
      debugPrint('[ScreenSecurity] Error clearing FLAG_SECURE: $e');
    }
  }
}
