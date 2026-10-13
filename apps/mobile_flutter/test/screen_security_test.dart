import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:classora_mobile/core/services/screen_security_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<MethodCall> methodCalls = [];

  setUp(() {
    methodCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.classora.app/security'),
      (MethodCall methodCall) async {
        methodCalls.add(methodCall);
        if (methodCall.method == 'setSecure') {
          return true;
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.classora.app/security'),
      null,
    );
  });

  test('ScreenSecurityService enables and disables FLAG_SECURE via method channel', () async {
    expect(ScreenSecurityService.isSecure, false);

    // 1. Enable secure screen
    await ScreenSecurityService.enableSecureScreen();
    expect(ScreenSecurityService.isSecure, true);
    expect(methodCalls.length, 1);
    expect(methodCalls.first.method, 'setSecure');
    expect(methodCalls.first.arguments, {'enabled': true});

    // 2. Disable secure screen
    await ScreenSecurityService.disableSecureScreen();
    expect(ScreenSecurityService.isSecure, false);
    expect(methodCalls.length, 2);
    expect(methodCalls.last.method, 'setSecure');
    expect(methodCalls.last.arguments, {'enabled': false});
  });
}
