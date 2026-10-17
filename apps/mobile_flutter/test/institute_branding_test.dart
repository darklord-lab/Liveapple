import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:classora_mobile/core/theme/app_colors.dart';
import 'package:classora_mobile/features/auth/domain/user_model.dart';
import 'package:classora_mobile/features/institute/data/institute_content_repository.dart';
import 'package:classora_mobile/features/institute/domain/institute_branding_model.dart';
import 'package:classora_mobile/features/institute/presentation/institute_content_controller.dart';
import 'package:classora_mobile/features/institute/presentation/institute_branding_controller.dart';
import 'package:classora_mobile/features/institute/presentation/institute_code_dialog.dart';
import 'package:classora_mobile/features/institute/presentation/manage_institute_content_screen.dart';

void main() {
  group('Phase 4.5 — Institute Branding Domain Model Tests', () {
    test('InstituteBrandingModel parses JSON with code, color, tagline, logo', () {
      final json = {
        'id': 'inst-apex-1',
        'name': 'Apex Science Academy',
        'code': 'APEX01',
        'logoUrl': 'https://example.com/logo.png',
        'primaryColor': '#10B981',
        'tagline': 'Excellence in JEE & NEET Coaching',
      };

      final branding = InstituteBrandingModel.fromJson(json);

      expect(branding.id, 'inst-apex-1');
      expect(branding.name, 'Apex Science Academy');
      expect(branding.code, 'APEX01');
      expect(branding.effectiveCode, 'APEX01');
      expect(branding.logoUrl, 'https://example.com/logo.png');
      expect(branding.primaryColor, '#10B981');
      expect(branding.tagline, 'Excellence in JEE & NEET Coaching');
      expect(branding.initials, 'AS');
      expect(branding.brandColor, const Color(0xFF10B981));
    });

    test('InstituteBrandingModel initials computation for varied name formats', () {
      const b1 = InstituteBrandingModel(name: 'Apex Academy');
      expect(b1.initials, 'AA');

      const b2 = InstituteBrandingModel(name: 'Allen');
      expect(b2.initials, 'A');

      const b3 = InstituteBrandingModel(name: 'K');
      expect(b3.initials, 'K');

      const b4 = InstituteBrandingModel(name: '');
      expect(b4.initials, 'C');

      const b5 = InstituteBrandingModel(name: 'Super 30 Patna Center');
      expect(b5.initials, 'S3');
    });

    test('InstituteBrandingModel hex parsing resilience and fallback', () {
      const bValid = InstituteBrandingModel(primaryColor: '#7C3AED');
      expect(bValid.brandColor, const Color(0xFF7C3AED));

      const bInvalid = InstituteBrandingModel(primaryColor: 'not-a-color');
      expect(bInvalid.brandColor, AppColors.skyBlue);

      const bNull = InstituteBrandingModel(primaryColor: null);
      expect(bNull.brandColor, AppColors.skyBlue);
    });

    test('InstituteModel and UserModel correctly serialize brand fields', () {
      const inst = InstituteModel(
        id: 'inst-xyz',
        name: 'FIITJEE South Campus',
        slug: 'fiitjee',
        code: 'FITJ24',
        primaryColor: '#F59E0B',
        tagline: 'Leading the JEE Revolution',
      );

      const user = UserModel(
        id: 'u-1',
        email: 'student@example.com',
        name: 'Karan Mehra',
        role: 'STUDENT',
        status: 'ACTIVE',
        instituteId: 'inst-xyz',
        institute: inst,
      );

      expect(inst.effectiveCode, 'FITJ24');
      expect(inst.initials, 'FS');
      expect(inst.brandColor, const Color(0xFFF59E0B));
      expect(user.effectiveInstituteCode, 'FITJ24');
      expect(user.brandColor, const Color(0xFFF59E0B));
    });
  });

  group('Phase 4.5 — InstituteCodeDialog Widget Tests', () {
    testWidgets('renders dialog title, input field, and quick presets', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            instituteBrandingProvider.overrideWith(
              (ref) => _FakeInstituteBrandingController(
                const InstituteBrandingState(
                  branding: InstituteBrandingModel(
                    id: 'inst-test',
                    name: 'Apex Academy',
                    code: 'APEX01',
                    primaryColor: '#0A9BE8',
                  ),
                  isLoading: false,
                ),
              ),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => InstituteCodeDialog.show(ctx),
                  child: const Text('Open Code Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Code Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Institute Code'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Verify Code'), findsOneWidget);
      expect(find.text('Sample Codes: '), findsOneWidget);
      expect(find.text('APEX01'), findsWidgets);

      // Tap preset chip 'APEX01'
      await tester.tap(find.text('APEX01').last);
      await tester.pumpAndSettle();

      expect(find.text('APEX01'), findsWidgets);
    });
  });

  group('Phase 4.5 — ManageInstituteContentScreen White-Label Tab Tests', () {
    testWidgets('renders White-Label tab with live student app bar preview and color presets', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            instituteLinksProvider.overrideWith((ref) => _FakeInstituteLinksNotifier()),
            testimonialsProvider.overrideWith((ref) => _FakeTestimonialsNotifier()),
            instituteBrandingProvider.overrideWith(
              (ref) => _FakeInstituteBrandingController(
                const InstituteBrandingState(
                  branding: InstituteBrandingModel(
                    id: 'inst-test',
                    name: 'Apex Academy',
                    code: 'APEX01',
                    primaryColor: '#0A9BE8',
                    tagline: 'Premier IIT-JEE & Medical Academy',
                  ),
                  isLoading: false,
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: ManageInstituteContentScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap tab 3 "White-Label"
      await tester.tap(find.text('White-Label'));
      await tester.pumpAndSettle();

      // Check tab exists and White-Label content renders
      expect(find.text('White-Label'), findsOneWidget);
      expect(find.text('STUDENT APP BAR LIVE PREVIEW'), findsOneWidget);
      expect(find.text('Apex Academy'), findsWidgets);
      expect(find.text('APEX01'), findsWidgets);
      expect(find.text('Institute / Academy Name *'), findsOneWidget);
      expect(find.text('Institute Code *'), findsOneWidget);
      expect(find.text('PRIMARY BRAND COLOR'), findsOneWidget);
      expect(find.text('Save White-Label Branding'), findsOneWidget);
    });
  });
}

class _FakeInstituteBrandingController extends InstituteBrandingController {
  final InstituteBrandingState _state;
  _FakeInstituteBrandingController(this._state) : super(autoInitialize: false) {
    state = _state;
  }

  @override
  Future<void> loadServerBranding() async {}

  @override
  Future<void> syncFromUser(UserModel user) async {}
}

class _FakeInstituteLinksNotifier extends InstituteLinksNotifier {
  _FakeInstituteLinksNotifier() : super(InstituteContentRepository()) {
    state = const InstituteLinksState(links: [], isLoading: false);
  }

  @override
  Future<void> loadLinks({bool all = false}) async {}
}

class _FakeTestimonialsNotifier extends TestimonialsNotifier {
  _FakeTestimonialsNotifier() : super(InstituteContentRepository()) {
    state = const TestimonialsState(testimonials: [], isLoading: false);
  }

  @override
  Future<void> loadTestimonials({bool all = false}) async {}
}
