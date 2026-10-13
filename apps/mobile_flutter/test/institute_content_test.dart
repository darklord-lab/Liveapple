import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:classora_mobile/features/auth/domain/user_model.dart';
import 'package:classora_mobile/features/institute/domain/institute_link_model.dart';
import 'package:classora_mobile/features/institute/domain/testimonial_model.dart';
import 'package:classora_mobile/features/institute/presentation/institute_content_controller.dart';
import 'package:classora_mobile/features/institute/presentation/manage_institute_content_screen.dart';
import 'package:classora_mobile/features/student/presentation/student_home_screen.dart';

void main() {
  const dummyStudent = UserModel(
    id: 'user-stu-1',
    email: 'student@example.com',
    name: 'Aarav Sharma',
    role: 'STUDENT',
    status: 'ACTIVE',
    instituteId: 'inst-1',
    institute: InstituteModel(id: 'inst-1', name: 'Apex Academy', slug: 'apex'),
  );

  final sampleLinks = [
    const InstituteLinkModel(
      id: 'link-1',
      instituteId: 'inst-1',
      title: 'Official YouTube Lectures',
      platform: 'YOUTUBE',
      url: 'https://youtube.com/@apex',
      isActive: true,
    ),
    const InstituteLinkModel(
      id: 'link-2',
      instituteId: 'inst-1',
      title: 'Telegram Study Group',
      platform: 'TELEGRAM',
      url: 'https://t.me/apexstudy',
      isActive: true,
    ),
  ];

  final sampleTestimonials = [
    const TestimonialModel(
      id: 't-1',
      instituteId: 'inst-1',
      studentName: 'Priya Verma',
      batchOrExam: 'JEE Advanced Rank 142',
      quote: 'Classora live classes and digital whiteboard made complex physics intuitive!',
      rating: 5,
      isPublished: true,
    ),
  ];

  group('Phase 4.4 — Institute Links & Testimonials Domain Tests', () {
    test('InstituteLinkModel parses JSON and determines styling', () {
      final json = {
        'id': 'link-yt',
        'instituteId': 'inst-1',
        'title': 'YouTube Channel',
        'platform': 'YOUTUBE',
        'url': 'https://youtube.com/@apex',
        'isActive': true,
      };

      final model = InstituteLinkModel.fromJson(json);
      expect(model.id, 'link-yt');
      expect(model.platform, 'YOUTUBE');
      expect(model.platformDisplay, 'YouTube');
      expect(model.iconData, Icons.play_circle_filled_rounded);
      expect(model.brandColor, const Color(0xFFDC2626));
    });

    test('TestimonialModel parses JSON and computes initials', () {
      final json = {
        'id': 'test-1',
        'instituteId': 'inst-1',
        'studentName': 'Rahul Sharma',
        'batchOrExam': 'NEET 2024',
        'quote': 'Brilliant teachers!',
        'rating': 5,
        'isPublished': true,
      };

      final model = TestimonialModel.fromJson(json);
      expect(model.id, 'test-1');
      expect(model.studentName, 'Rahul Sharma');
      expect(model.initials, 'RS');
      expect(model.rating, 5);
      expect(model.isPublished, true);
    });
  });

  group('Phase 4.4 — ManageInstituteContentScreen Widget Tests', () {
    testWidgets('renders tabs, add buttons, and switches tabs', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            instituteLinksProvider.overrideWith((ref) {
              final repo = ref.watch(instituteContentRepositoryProvider);
              final notifier = InstituteLinksNotifier(repo);
              notifier.state = InstituteLinksState(links: sampleLinks, isLoading: false);
              return notifier;
            }),
            testimonialsProvider.overrideWith((ref) {
              final repo = ref.watch(instituteContentRepositoryProvider);
              final notifier = TestimonialsNotifier(repo);
              notifier.state = TestimonialsState(testimonials: sampleTestimonials, isLoading: false);
              return notifier;
            }),
          ],
          child: const MaterialApp(
            home: ManageInstituteContentScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top title and tabs
      expect(find.text('Connect Links & Testimonials'), findsOneWidget);
      expect(find.text('Connect Links'), findsOneWidget);
      expect(find.text('Testimonials'), findsOneWidget);

      // Links tab actions
      expect(find.text('Student Connect Links'), findsOneWidget);
      expect(find.text('Add Link'), findsOneWidget);

      // Switch to Testimonials tab
      await tester.tap(find.text('Testimonials'));
      await tester.pumpAndSettle();

      expect(find.text('Student Testimonials'), findsOneWidget);
      expect(find.text('Add Review'), findsOneWidget);
    });
  });

  group('Phase 4.4 — StudentHomeScreen Connect With Us & Testimonials Display Tests', () {
    testWidgets('renders testimonials and connect links when available in provider', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            instituteLinksProvider.overrideWith((ref) {
              final repo = ref.watch(instituteContentRepositoryProvider);
              final notifier = InstituteLinksNotifier(repo);
              notifier.state = InstituteLinksState(links: sampleLinks, isLoading: false);
              return notifier;
            }),
            testimonialsProvider.overrideWith((ref) {
              final repo = ref.watch(instituteContentRepositoryProvider);
              final notifier = TestimonialsNotifier(repo);
              notifier.state = TestimonialsState(testimonials: sampleTestimonials, isLoading: false);
              return notifier;
            }),
          ],
          child: const MaterialApp(
            home: StudentHomeScreen(user: dummyStudent),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to Testimonials
      await tester.scrollUntilVisible(
        find.text('Student Testimonials'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Student Testimonials'), findsOneWidget);
      expect(find.text('Priya Verma'), findsOneWidget);
      expect(find.textContaining('Classora live classes and digital whiteboard'), findsOneWidget);

      // Scroll to Connect With Us
      await tester.scrollUntilVisible(
        find.text('Connect with us'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Connect with us'), findsOneWidget);
      expect(find.text('Official YouTube Lectures'), findsOneWidget);
      expect(find.text('Telegram Study Group'), findsOneWidget);
    });
  });
}
