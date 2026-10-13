import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:classora_mobile/features/auth/domain/user_model.dart';
import 'package:classora_mobile/features/help/presentation/help_walkthrough_screen.dart';

void main() {
  const dummyUser = UserModel(
    id: 'user-stu-1',
    email: 'student@example.com',
    name: 'Aarav Sharma',
    role: 'STUDENT',
    status: 'ACTIVE',
    instituteId: 'inst-1',
    institute: InstituteModel(id: 'inst-1', name: 'Classora Academy', slug: 'classora'),
  );

  Widget createTestWidget({
    String initialRole = 'STUDENT',
    UserModel? user = dummyUser,
    bool openTourImmediately = false,
  }) {
    return ProviderScope(
      child: MaterialApp(
        home: HelpWalkthroughScreen(
          initialRole: initialRole,
          user: user,
          openTourImmediately: openTourImmediately,
        ),
      ),
    );
  }

  group('HelpWalkthroughScreen Widget Tests', () {
    testWidgets('renders role tabs and default student walkthrough content', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget(initialRole: 'STUDENT'));
      await tester.pumpAndSettle();

      // Top title and role tabs
      expect(find.text('Help & User Guide'), findsOneWidget);
      expect(find.text('Student'), findsOneWidget);
      expect(find.text('Teacher'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);

      // Student onboarding banner & cards
      expect(find.text('Interactive Student Tour'), findsOneWidget);
      expect(find.text('Join Live Classes with 1-Tap & Attendance'), findsOneWidget);
      expect(find.text('Weekly Schedule & 15-Minute Reminders'), findsOneWidget);
      expect(find.text('Curricular Notes, PDFs & Handouts'), findsOneWidget);

      // Scroll to Troubleshooting and Support
      await tester.scrollUntilVisible(find.text('Need personal assistance?'), 300);
      expect(find.text('Need personal assistance?'), findsOneWidget);
    });

    testWidgets('switches to Teacher tab and displays faculty guide', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget(initialRole: 'STUDENT'));
      await tester.pumpAndSettle();

      // Tap Teacher tab
      await tester.tap(find.text('Teacher'));
      await tester.pumpAndSettle();

      expect(find.text('Interactive Teacher Tour'), findsOneWidget);
      expect(find.text('Go Live & Lead Interactive Lectures'), findsOneWidget);
      expect(find.text('Interactive Digital Whiteboard'), findsOneWidget);
      expect(find.text('Smart Scheduling & Conflict Engine'), findsOneWidget);
    });

    testWidgets('switches to Admin tab and displays administrator console guide', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget(initialRole: 'STUDENT'));
      await tester.pumpAndSettle();

      // Tap Admin tab
      await tester.tap(find.text('Admin'));
      await tester.pumpAndSettle();

      expect(find.text('Interactive Admin Tour'), findsOneWidget);
      expect(find.text('Institute Overview & Real-Time Pulse'), findsOneWidget);
      expect(find.text('Teacher Directory & Bulk CSV Invites'), findsOneWidget);
      expect(find.text('Master Batches & Institute Timetable'), findsOneWidget);
    });

    testWidgets('expands FAQ tile to reveal answer', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget(initialRole: 'STUDENT'));
      await tester.pumpAndSettle();

      final faqFinder = find.text('How do I join a live lecture?');
      await tester.scrollUntilVisible(faqFinder, 300);
      expect(faqFinder, findsOneWidget);

      await tester.tap(faqFinder);
      await tester.pumpAndSettle();

      expect(find.textContaining('When your teacher begins a live class'), findsOneWidget);
    });

    testWidgets('launches interactive tour and navigates step pages', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget(initialRole: 'STUDENT'));
      await tester.pumpAndSettle();

      // Tap 'Start Interactive Walkthrough'
      final startTourBtn = find.text('Start Interactive Walkthrough');
      await tester.ensureVisible(startTourBtn);
      await tester.pumpAndSettle();
      await tester.tap(startTourBtn);
      await tester.pumpAndSettle();

      // Tour dialog is open at step 1
      expect(find.text('Student Tour (1/5)'), findsOneWidget);
      expect(find.descendant(of: find.byType(Dialog), matching: find.text('STEP 1 • LIVE LECTURES')), findsOneWidget);

      // Tap Next to step 2
      final nextBtn = find.text('Next');
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      expect(find.text('Student Tour (2/5)'), findsOneWidget);
      expect(find.descendant(of: find.byType(Dialog), matching: find.text('STEP 2 • TIMETABLE')), findsOneWidget);

      // Tap Back to step 1
      final backBtn = find.text('Back');
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      expect(find.text('Student Tour (1/5)'), findsOneWidget);

      // Dismiss tour via close icon
      final closeBtn = find.byIcon(Icons.close);
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      // Tour is dismissed, back on main screen
      expect(find.text('Student Tour (1/5)'), findsNothing);
      expect(find.text('Help & User Guide'), findsOneWidget);
    });
  });
}
