import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:classora_mobile/features/auth/presentation/login_screen.dart';
import 'package:classora_mobile/features/auth/presentation/accept_invite_screen.dart';
import 'package:classora_mobile/features/auth/presentation/auth_controller.dart';
import 'package:classora_mobile/features/auth/domain/auth_state.dart';
import 'package:classora_mobile/features/auth/data/auth_repository.dart';

class MockAuthController extends AuthController {
  MockAuthController(AuthState initialState) : super(AuthRepository()) {
    state = initialState;
  }

  @override
  Future<void> checkStatus() async {
    // No-op for test to keep unauthenticated state
  }
}

void main() {
  group('Auth Screens 320dp & 360dp Overflow Tests', () {
    testWidgets('LoginScreen renders at 320dp width without overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 840);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => MockAuthController(AuthState.unauthenticated())),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Classora 2.0'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'No layout overflow exception must occur at 320dp width');
    });

    testWidgets('LoginScreen renders at 360dp width with text scale 1.3 without overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 840);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => MockAuthController(AuthState.unauthenticated())),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
              child: LoginScreen(),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Classora 2.0'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'No layout overflow exception must occur at 360dp with text scale 1.3');
    });

    testWidgets('AcceptInviteScreen renders at 320dp width without overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 840);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => MockAuthController(AuthState.unauthenticated())),
          ],
          child: const MaterialApp(
            home: AcceptInviteScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Join Your Batch'), findsOneWidget);
      expect(find.text('Join Batch & Start Learning'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'No layout overflow exception must occur at 320dp width');
    });
  });
}
