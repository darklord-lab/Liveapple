import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:classora_mobile/features/learning/domain/models/learning_models.dart';
import 'package:classora_mobile/features/learning/domain/models/test_share_model.dart';
import 'package:classora_mobile/features/learning/presentation/widgets/test_score_share_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 4.6 — TestShareModel Domain Tests', () {
    test('TestShareModel.fromJson correctly parses backend response', () {
      final json = {
        'attemptId': 'att-12345',
        'testId': 'test-789',
        'testTitle': 'Physics Quantum Mechanics CBT Mock',
        'durationMin': 45,
        'batchName': 'Physics Droppers 2026',
        'subject': 'Physics',
        'studentName': 'Rahul Verma',
        'score': 85,
        'totalMarks': 100,
        'percentage': 85,
        'status': 'EVALUATED',
        'submittedAt': '2026-10-13T10:00:00.000Z',
        'institute': {
          'id': 'inst-apex-1',
          'name': 'Apex Science Academy',
          'code': 'APEX01',
          'logoUrl': 'https://example.com/logo.png',
          'primaryColor': '#0A9BE8',
          'tagline': 'Premier JEE Coaching',
        },
        'deepLink': 'classora://test-result?attemptId=att-12345&code=APEX01',
        'webLink': 'https://classora.app/test-result?attemptId=att-12345&code=APEX01',
      };

      final share = TestShareModel.fromJson(json);

      expect(share.attemptId, 'att-12345');
      expect(share.testId, 'test-789');
      expect(share.testTitle, 'Physics Quantum Mechanics CBT Mock');
      expect(share.durationMin, 45);
      expect(share.batchName, 'Physics Droppers 2026');
      expect(share.subject, 'Physics');
      expect(share.studentName, 'Rahul Verma');
      expect(share.score, 85);
      expect(share.totalMarks, 100);
      expect(share.percentage, 85);
      expect(share.status, 'EVALUATED');
      expect(share.instituteName, 'Apex Science Academy');
      expect(share.instituteCode, 'APEX01');
      expect(share.primaryColorHex, '#0A9BE8');
      expect(share.tagline, 'Premier JEE Coaching');
      expect(share.deepLink, 'classora://test-result?attemptId=att-12345&code=APEX01');
      expect(share.webLink, 'https://classora.app/test-result?attemptId=att-12345&code=APEX01');
      expect(share.primaryColor, const Color(0xFF0A9BE8));
    });

    test('Grade calculation across percentage tiers', () {
      TestShareModel makeWithPct(int pct) => TestShareModel(
            attemptId: 'att-1',
            testId: 't-1',
            testTitle: 'Test',
            durationMin: 10,
            studentName: 'Student',
            score: pct,
            totalMarks: 100,
            percentage: pct,
            status: 'EVALUATED',
            instituteName: 'Inst',
            instituteCode: 'CODE1',
            deepLink: 'link',
            webLink: 'link',
          );

      expect(makeWithPct(95).grade, 'A+ Outstanding');
      expect(makeWithPct(85).grade, 'A Excellent');
      expect(makeWithPct(72).grade, 'B+ Very Good');
      expect(makeWithPct(64).grade, 'B Good');
      expect(makeWithPct(50).grade, 'C Pass');
      expect(makeWithPct(35).grade, 'Needs Improvement');
    });

    test('formatShareText formats rich shareable message for WhatsApp/SMS', () {
      const share = TestShareModel(
        attemptId: 'att-99',
        testId: 't-99',
        testTitle: 'Thermodynamics CBT',
        durationMin: 30,
        batchName: 'Batch Alpha',
        subject: 'Physics',
        studentName: 'Priya Sharma',
        score: 92,
        totalMarks: 100,
        percentage: 92,
        status: 'EVALUATED',
        instituteName: 'Apex Academy',
        instituteCode: 'APEX99',
        deepLink: 'classora://test-result?attemptId=att-99&code=APEX99',
        webLink: 'https://classora.app/test-result?attemptId=att-99&code=APEX99',
      );

      final text = share.formatShareText();

      expect(text, contains('Apex Academy'));
      expect(text, contains('APEX99'));
      expect(text, contains('Priya Sharma'));
      expect(text, contains('Thermodynamics CBT'));
      expect(text, contains('92 / 100 (92%)'));
      expect(text, contains('A+ Outstanding'));
      expect(text, contains('https://classora.app/test-result?attemptId=att-99&code=APEX99'));
      expect(text, contains('classora://test-result?attemptId=att-99&code=APEX99'));
    });

    test('CbtTestModel correctly captures myAttemptId from attempt json', () {
      final json = {
        'id': 'test-cbt-1',
        'title': 'Optics Test',
        'durationMin': 20,
        'totalMarks': 50,
        'questionsCount': 10,
        'myAttempt': {
          'id': 'att-optics-42',
          'score': 45,
          'status': 'EVALUATED',
        },
      };

      final model = CbtTestModel.fromJson(json);

      expect(model.id, 'test-cbt-1');
      expect(model.isAttempted, true);
      expect(model.myScore, 45);
      expect(model.myAttemptId, 'att-optics-42');
    });
  });

  group('Phase 4.6 — TestScoreShareCard Widget Tests', () {
    const testShare = TestShareModel(
      attemptId: 'att-widget-test',
      testId: 'test-widget-test',
      testTitle: 'Modern Physics & Electrostatics CBT',
      durationMin: 60,
      batchName: 'Class 12 JEE Elite',
      subject: 'Physics',
      studentName: 'Aarav Patel',
      score: 88,
      totalMarks: 100,
      percentage: 88,
      status: 'EVALUATED',
      instituteName: 'Apex Science Academy',
      instituteCode: 'APEX01',
      primaryColorHex: '#0A9BE8',
      tagline: 'Leading STEM Coaching',
      deepLink: 'classora://test-result?attemptId=att-widget-test&code=APEX01',
      webLink: 'https://classora.app/test-result?attemptId=att-widget-test&code=APEX01',
    );

    testWidgets('Renders verified test score card with branding, badges, and scores', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TestScoreShareCard(share: testShare),
          ),
        ),
      );

      // Verify Institute details & monogram
      expect(find.text('Apex Science Academy'), findsOneWidget);
      expect(find.text('APEX01'), findsOneWidget);
      expect(find.text('A'), findsWidgets); // Monogram initial

      // Verify student badge
      expect(find.text('Aarav Patel'), findsOneWidget);

      // Verify test title & subject
      expect(find.text('Modern Physics & Electrostatics CBT'), findsOneWidget);
      expect(find.text('Class 12 JEE Elite • Physics'), findsOneWidget);

      // Verify score visual
      expect(find.text('88'), findsOneWidget);
      expect(find.text(' / 100'), findsOneWidget);
      expect(find.text('88% Overall Score'), findsOneWidget);

      // Verify grade pill
      expect(find.text('A Excellent'), findsOneWidget);

      // Verify links & buttons
      expect(find.byKey(const Key('copy_link_btn')), findsOneWidget);
      expect(find.byKey(const Key('share_score_btn')), findsOneWidget);
      expect(find.byKey(const Key('close_share_card_btn')), findsOneWidget);
    });

    testWidgets('Action buttons can be tapped without throwing', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Mock clipboard messenger
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            return null;
          }
          return null;
        },
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TestScoreShareCard(share: testShare),
          ),
        ),
      );

      // Tap Copy Link
      await tester.tap(find.byKey(const Key('copy_link_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Score card link copied to clipboard!'), findsOneWidget);

      // Tap Share
      await tester.tap(find.byKey(const Key('share_score_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Score card details copied ready to share!'), findsOneWidget);
    });
  });
}
