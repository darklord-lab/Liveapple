import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:classora_mobile/features/auth/domain/user_model.dart';
import 'package:classora_mobile/features/auth/presentation/edit_profile_screen.dart';

void main() {
  group('Phase 4.2 — UserModel Profile & Settings Model Suite', () {
    test('UserModel parses avatarUrl and notificationPrefs JSON', () {
      final json = {
        'id': 'user-123',
        'instituteId': 'inst-apex',
        'role': 'STUDENT',
        'name': 'Aarav Sharma',
        'email': 'aarav@apex.edu',
        'phone': '+91 9876543210',
        'avatarUrl': '/api/v1/auth/avatar/avatar-abc.png',
        'notificationPrefs': '{"reminders":false,"liveAlerts":true,"homework":false,"testAlerts":true}',
        'status': 'ACTIVE',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 'user-123');
      expect(user.name, 'Aarav Sharma');
      expect(user.email, 'aarav@apex.edu');
      expect(user.phone, '+91 9876543210');
      expect(user.avatarUrl, '/api/v1/auth/avatar/avatar-abc.png');
      expect(user.remindersEnabled, false);
      expect(user.liveAlertsEnabled, true);
      expect(user.homeworkEnabled, false);
    });

    test('UserModel default notification preferences when null', () {
      final json = {
        'id': 'user-456',
        'instituteId': 'inst-apex',
        'role': 'TEACHER',
        'name': 'Prof. Rajesh',
        'email': 'rajesh@apex.edu',
        'status': 'ACTIVE',
      };

      final user = UserModel.fromJson(json);

      expect(user.avatarUrl, isNull);
      expect(user.notificationPrefs, isNull);
      // Defaults should be true
      expect(user.remindersEnabled, true);
      expect(user.liveAlertsEnabled, true);
      expect(user.homeworkEnabled, true);
    });

    test('UserModel copyWith updates fields correctly', () {
      const original = UserModel(
        id: 'user-789',
        instituteId: 'inst-apex',
        role: 'STUDENT',
        name: 'Original Name',
        email: 'orig@apex.edu',
        status: 'ACTIVE',
      );

      final updated = original.copyWith(
        name: 'New Name',
        phone: '+91 9123456780',
        avatarUrl: '/api/v1/auth/avatar/new.png',
        notificationPrefs: '{"reminders":true,"liveAlerts":false,"homework":true}',
      );

      expect(updated.name, 'New Name');
      expect(updated.phone, '+91 9123456780');
      expect(updated.avatarUrl, '/api/v1/auth/avatar/new.png');
      expect(updated.liveAlertsEnabled, false);
      expect(updated.remindersEnabled, true);
      // Unmodified fields stay unchanged
      expect(updated.id, 'user-789');
      expect(updated.email, 'orig@apex.edu');
      expect(updated.status, 'ACTIVE');
    });
  });

  group('Phase 4.2 — EditProfileScreen Widget Tests', () {
    testWidgets('EditProfileScreen renders user details and locked email field', (tester) async {
      const testUser = UserModel(
        id: 'u-1',
        instituteId: 'inst-apex',
        role: 'STUDENT',
        name: 'Priya Patel',
        email: 'priya@apex.edu',
        phone: '+91 9988776655',
        status: 'ACTIVE',
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: EditProfileScreen(user: testUser),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header title
      expect(find.text('Edit Profile'), findsOneWidget);

      // Name text field
      expect(find.widgetWithText(TextFormField, 'Priya Patel'), findsOneWidget);

      // Phone text field
      expect(find.widgetWithText(TextFormField, '+91 9988776655'), findsOneWidget);

      // Locked Email field
      expect(find.widgetWithText(TextFormField, 'priya@apex.edu'), findsOneWidget);

      // Save button
      expect(find.text('Save Changes'), findsOneWidget);

      // Avatar initial
      expect(find.text('P'), findsOneWidget);
    });

    testWidgets('EditProfileScreen validates minimum name length', (tester) async {
      const testUser = UserModel(
        id: 'u-1',
        instituteId: 'inst-apex',
        role: 'STUDENT',
        name: 'Priya Patel',
        email: 'priya@apex.edu',
        status: 'ACTIVE',
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: EditProfileScreen(user: testUser),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Clear the name field to 1 char
      final nameField = find.widgetWithText(TextFormField, 'Priya Patel');
      await tester.enterText(nameField, 'A');
      await tester.pump();

      // Tap Save Changes after scrolling it into view
      final saveButton = find.text('Save Changes');
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Expect validation error message
      expect(find.text('Name must be at least 2 characters'), findsOneWidget);
    });
  });
}
