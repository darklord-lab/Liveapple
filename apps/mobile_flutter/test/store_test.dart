import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:classora_mobile/features/store/domain/models/store_models.dart';
import 'package:classora_mobile/features/store/data/store_repository.dart';
import 'package:classora_mobile/features/store/presentation/controllers/store_controller.dart';
import 'package:classora_mobile/features/store/presentation/screens/course_store_screen.dart';
import 'package:classora_mobile/features/store/presentation/widgets/checkout_modal_sheet.dart';
import 'package:classora_mobile/features/store/presentation/widgets/invoice_dialog.dart';

class FakeStoreRepository extends StoreRepository {
  List<CourseOfferingModel> mockOfferings = [];
  List<PurchaseModel> mockPurchases = [];
  InvoiceModel? mockInvoice;
  CouponValidationResult? mockCouponResult;
  bool checkoutCalled = false;
  String? lastCheckoutOfferingId;
  String? lastCouponValidated;

  @override
  Future<List<CourseOfferingModel>> getOfferings({
    String? search,
    String? batchId,
    bool? isFeatured,
    double? minPrice,
    double? maxPrice,
    String? sort,
    String? purchasedFilter,
  }) async {
    return mockOfferings;
  }

  @override
  Future<List<PurchaseModel>> getPurchases() async {
    return mockPurchases;
  }

  @override
  Future<CouponValidationResult> validateCoupon(String code, String offeringId) async {
    lastCouponValidated = code;
    if (mockCouponResult != null) return mockCouponResult!;
    if (code.toUpperCase() == 'OFFER50') {
      return const CouponValidationResult(
        valid: true,
        couponId: 'c-1',
        code: 'OFFER50',
        discountType: 'PERCENT',
        discountValue: 50.0,
        originalPrice: 1000.0,
        discountAmount: 500.0,
        finalAmount: 500.0,
      );
    }
    throw Exception('Invalid or expired coupon code');
  }

  @override
  Future<Map<String, dynamic>> checkout(
    String offeringId, {
    String? couponCode,
    String paymentMethod = 'MOCK',
  }) async {
    checkoutCalled = true;
    lastCheckoutOfferingId = offeringId;
    return {
      'mode': 'INSTANT',
      'purchase': {
        'id': 'purch-999',
        'offeringId': offeringId,
        'studentId': 'std-1',
        'amount': 500.0,
        'discount': 500.0,
        'paymentMethod': paymentMethod,
        'transactionId': 'tx-mock-999',
        'status': 'SUCCESS',
        'invoiceNo': 'INV-2026-9999',
        'purchasedAt': DateTime.now().toIso8601String(),
      },
    };
  }

  @override
  Future<InvoiceModel> getInvoice(String purchaseId) async {
    if (mockInvoice != null) return mockInvoice!;
    return InvoiceModel(
      invoiceNo: 'INV-2026-0001',
      transactionId: 'tx-12345',
      status: 'SUCCESS',
      purchasedAt: DateTime(2026, 10, 13, 14, 30),
      paymentMethod: 'RAZORPAY',
      instituteName: 'Apex Medical Academy',
      instituteCode: 'APEX01',
      studentName: 'Rahul Sharma',
      studentEmail: 'rahul@example.com',
      courseTitle: 'NEET Physics Mastery 2026',
      batchName: 'Class 12 - Elite Medical',
      subject: 'Physics',
      mrp: 2000.0,
      basePrice: 2000.0,
      discount: 500.0,
      couponCode: 'EARLYBIRD',
      netPaid: 1500.0,
    );
  }
}

void main() {
  group('Phase 6 — Store Models Serialization & Computed Properties', () {
    test('CourseOfferingModel parses correctly and computes discount', () {
      final json = {
        'id': 'off-1',
        'batchId': 'b-1',
        'title': 'IIT JEE Physics 2026',
        'description': 'Complete crash course covering mechanics, optics & electrodynamics',
        'thumbnailUrl': 'https://example.com/physics.jpg',
        'price': 1500.0,
        'mrp': 3000.0,
        'discountPercent': 50,
        'isFeatured': true,
        'isPublished': true,
        'isPurchased': false,
        'totalEnrolled': 42,
        'batch': {
          'id': 'b-1',
          'name': 'Batch Alpha JEE',
          'subject': 'Physics',
          'teacher': {
            'name': 'Dr. H. C. Verma',
          },
        },
        'createdAt': '2026-10-10T10:00:00Z',
      };

      final offering = CourseOfferingModel.fromJson(json);

      expect(offering.id, 'off-1');
      expect(offering.batchId, 'b-1');
      expect(offering.title, 'IIT JEE Physics 2026');
      expect(offering.price, 1500.0);
      expect(offering.mrp, 3000.0);
      expect(offering.discountPercent, 50);
      expect(offering.hasDiscount, isTrue);
      expect(offering.isFeatured, isTrue);
      expect(offering.isPurchased, isFalse);
      expect(offering.totalEnrolled, 42);
      expect(offering.batchName, 'Batch Alpha JEE');
      expect(offering.batchSubject, 'Physics');
      expect(offering.teacherName, 'Dr. H. C. Verma');
    });

    test('CourseOfferingModel calculates discount fallback if discountPercent missing', () {
      final json = {
        'id': 'off-2',
        'batchId': 'b-2',
        'title': 'Chemistry Fast-Track',
        'price': 800.0,
        'mrp': 1000.0,
        'createdAt': '2026-10-10T10:00:00Z',
      };

      final offering = CourseOfferingModel.fromJson(json);

      expect(offering.price, 800.0);
      expect(offering.mrp, 1000.0);
      expect(offering.discountPercent, 20); // (1000-800)/1000 = 20%
      expect(offering.hasDiscount, isTrue);
    });

    test('CouponValidationResult parses percent and flat discounts correctly', () {
      final jsonPercent = {
        'valid': true,
        'coupon': {
          'id': 'cpn-1',
          'code': 'NEET30',
          'discountType': 'PERCENT',
          'discountValue': 30,
        },
        'originalPrice': 2000.0,
        'discountAmount': 600.0,
        'finalAmount': 1400.0,
      };

      final result = CouponValidationResult.fromJson(jsonPercent);

      expect(result.valid, isTrue);
      expect(result.code, 'NEET30');
      expect(result.discountType, 'PERCENT');
      expect(result.discountValue, 30.0);
      expect(result.originalPrice, 2000.0);
      expect(result.discountAmount, 600.0);
      expect(result.finalAmount, 1400.0);
    });

    test('PurchaseModel and InvoiceModel parse correctly', () {
      final purchaseJson = {
        'id': 'p-100',
        'offeringId': 'off-1',
        'studentId': 'usr-1',
        'amount': 1500.0,
        'discount': 500.0,
        'paymentMethod': 'RAZORPAY',
        'transactionId': 'pay_998877',
        'status': 'SUCCESS',
        'invoiceNo': 'INV-2026-0089',
        'purchasedAt': '2026-10-12T15:30:00Z',
        'offering': {
          'title': 'NEET Crash Course',
          'batch': {
            'name': 'Batch 2026',
          },
        },
      };

      final purchase = PurchaseModel.fromJson(purchaseJson);

      expect(purchase.id, 'p-100');
      expect(purchase.isSuccess, isTrue);
      expect(purchase.isRefunded, isFalse);
      expect(purchase.amount, 1500.0);
      expect(purchase.discount, 500.0);
      expect(purchase.invoiceNo, 'INV-2026-0089');
      expect(purchase.courseTitle, 'NEET Crash Course');
      expect(purchase.batchName, 'Batch 2026');
    });
  });

  group('Phase 6 — StoreController Logic & State Filtering', () {
    test('filters offerings by search query and category correctly', () {
      final offerings = [
        CourseOfferingModel(
          id: '1',
          batchId: 'b-1',
          title: 'Physics Mechanics Masterclass',
          price: 1000,
          mrp: 1500,
          isFeatured: true,
          isPurchased: false,
          batchSubject: 'Physics',
          createdAt: DateTime.now(),
        ),
        CourseOfferingModel(
          id: '2',
          batchId: 'b-2',
          title: 'Organic Chemistry Reactions',
          price: 1200,
          mrp: 1200,
          isFeatured: false,
          isPurchased: true,
          batchSubject: 'Chemistry',
          createdAt: DateTime.now(),
        ),
        CourseOfferingModel(
          id: '3',
          batchId: 'b-3',
          title: 'Calculus and Vectors',
          price: 900,
          mrp: 1800,
          isFeatured: true,
          isPurchased: false,
          batchSubject: 'Mathematics',
          createdAt: DateTime.now(),
        ),
      ];

      final state = StoreState(offerings: offerings);

      // Search query filtering
      final searched = state.copyWith(searchQuery: 'chemistry');
      expect(searched.filteredOfferings.length, 1);
      expect(searched.filteredOfferings.first.title, 'Organic Chemistry Reactions');

      // Filter: AVAILABLE
      final available = state.copyWith(selectedFilter: 'AVAILABLE');
      expect(available.filteredOfferings.length, 2);
      expect(available.filteredOfferings.any((o) => o.isPurchased), isFalse);

      // Filter: PURCHASED
      final purchased = state.copyWith(selectedFilter: 'PURCHASED');
      expect(purchased.filteredOfferings.length, 1);
      expect(purchased.filteredOfferings.first.id, '2');

      // Filter: FEATURED
      final featured = state.copyWith(selectedFilter: 'FEATURED');
      expect(featured.filteredOfferings.length, 2);
    });

    test('optimistically marks course as purchased on checkout', () async {
      final fakeRepo = FakeStoreRepository();
      fakeRepo.mockOfferings = [
        CourseOfferingModel(
          id: 'course-1',
          batchId: 'b-1',
          title: 'Mathematics Fast-Track',
          price: 1500,
          mrp: 2000,
          isPurchased: false,
          createdAt: DateTime.now(),
        ),
      ];

      final controller = StoreController(repository: fakeRepo);
      await controller.loadOfferings();

      expect(controller.state.offerings.first.isPurchased, isFalse);

      await controller.checkoutCourse('course-1', paymentMethod: 'MOCK');

      expect(fakeRepo.checkoutCalled, isTrue);
      expect(fakeRepo.lastCheckoutOfferingId, 'course-1');
      expect(controller.state.offerings.first.isPurchased, isTrue);
    });
  });

  group('Phase 6 — Store Widgets & Screens', () {
    testWidgets('CourseStoreScreen renders list, badges, and search bar', (WidgetTester tester) async {
      final fakeRepo = FakeStoreRepository();
      fakeRepo.mockOfferings = [
        CourseOfferingModel(
          id: 'c-1',
          batchId: 'b-1',
          title: 'Physics Crash Course 2026',
          price: 999,
          mrp: 1999,
          discountPercent: 50,
          isFeatured: true,
          isPurchased: false,
          batchName: 'Batch 12 Physics',
          batchSubject: 'Physics',
          teacherName: 'Prof. Sharma',
          createdAt: DateTime.now(),
        ),
        CourseOfferingModel(
          id: 'c-2',
          batchId: 'b-2',
          title: 'Chemistry Organic Booster',
          price: 1200,
          mrp: 1200,
          isFeatured: false,
          isPurchased: true,
          batchName: 'Batch 12 Chemistry',
          batchSubject: 'Chemistry',
          createdAt: DateTime.now(),
        ),
      ];

      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: CourseStoreScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Course Store'), findsOneWidget);
      expect(find.text('Physics Crash Course 2026'), findsWidgets);
      expect(find.text('Chemistry Organic Booster'), findsOneWidget);
      expect(find.text('Enrolled ✓'), findsOneWidget);
      expect(find.text('ENROLL NOW'), findsWidgets);
    });

    testWidgets('CheckoutModalSheet renders price breakdown and coupon field', (WidgetTester tester) async {
      final offering = CourseOfferingModel(
        id: 'off-test',
        batchId: 'b-test',
        title: 'JEE Advanced Masterclass',
        price: 2499,
        mrp: 4999,
        discountPercent: 50,
        batchName: 'JEE Super 30',
        batchSubject: 'Mathematics',
        createdAt: DateTime.now(),
      );

      final fakeRepo = FakeStoreRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CheckoutModalSheet(offering: offering),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Course Checkout'), findsOneWidget);
      expect(find.text('JEE Advanced Masterclass'), findsOneWidget);
      expect(find.textContaining('JEE Super 30'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);
      expect(find.textContaining('Enroll Now'), findsOneWidget);
    });

    testWidgets('InvoiceDialog displays full receipt and transaction details', (WidgetTester tester) async {
      final invoice = InvoiceModel(
        invoiceNo: 'INV-2026-9090',
        transactionId: 'txn_razorpay_9988',
        status: 'SUCCESS',
        purchasedAt: DateTime(2026, 10, 13, 16, 0),
        paymentMethod: 'RAZORPAY',
        instituteName: 'Zenith Kota Academy',
        instituteCode: 'ZENITH',
        studentName: 'Aarav Patel',
        studentEmail: 'aarav@zenith.in',
        courseTitle: 'Complete Botany & Zoology for NEET',
        batchName: 'Medical Target 2026',
        subject: 'Biology',
        mrp: 4000,
        basePrice: 4000,
        discount: 1000,
        couponCode: 'MEDIC25',
        netPaid: 3000,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InvoiceDialog(invoice: invoice),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Zenith Kota Academy'), findsOneWidget);
      expect(find.text('INV-2026-9090'), findsOneWidget);
      expect(find.text('Aarav Patel'), findsOneWidget);
      expect(find.text('Complete Botany & Zoology for NEET'), findsOneWidget);
      expect(find.textContaining('MEDIC25'), findsOneWidget);
      expect(find.text('₹3000'), findsOneWidget);
    });
  });

  group('Phase 6 — 320dp Screen Layout Overflow Tests', () {
    testWidgets('CourseStoreScreen renders at 320dp without overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeRepo = FakeStoreRepository();
      fakeRepo.mockOfferings = [
        CourseOfferingModel(
          id: 'c-320',
          batchId: 'b-320',
          title: 'Intensive Revision Course for Board Examinations 2026',
          price: 1999,
          mrp: 3999,
          discountPercent: 50,
          isFeatured: true,
          isPurchased: false,
          batchName: 'CBSE Class 12 Boards Batch',
          batchSubject: 'Physics',
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: CourseStoreScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Course Store'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'CourseStoreScreen must have 0 overflow at 320dp width');
    });

    testWidgets('CheckoutModalSheet renders at 320dp without overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final offering = CourseOfferingModel(
        id: 'c-narrow',
        batchId: 'b-narrow',
        title: 'Comprehensive Mathematics for JEE Advanced and Olympiads',
        price: 2999,
        mrp: 5999,
        discountPercent: 50,
        batchName: 'Olympiad Elite Batch',
        batchSubject: 'Mathematics',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeRepositoryProvider.overrideWithValue(FakeStoreRepository()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CheckoutModalSheet(offering: offering),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Course Checkout'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'CheckoutModalSheet must have 0 overflow at 320dp width');
    });

    testWidgets('InvoiceDialog renders at 320dp without overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final invoice = InvoiceModel(
        invoiceNo: 'INV-2026-NARROW',
        transactionId: 'txn_narrow_123456789',
        status: 'SUCCESS',
        purchasedAt: DateTime(2026, 10, 13, 17, 0),
        paymentMethod: 'RAZORPAY',
        instituteName: 'Very Long Coaching Academy Name for Medical and Engineering Examinations',
        instituteCode: 'LONGINST',
        studentName: 'Shubham Kumar Srivastava',
        studentEmail: 'shubham.kumar@example.com',
        courseTitle: 'Comprehensive Two Year Classroom Program for NEET UG',
        batchName: 'Two Year Foundation Batch 2026-2028',
        subject: 'Biology and Chemistry Combined',
        mrp: 15000,
        basePrice: 15000,
        discount: 3000,
        couponCode: 'SCHOLARSHIP20',
        netPaid: 12000,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InvoiceDialog(invoice: invoice),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('INV-2026-NARROW'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'InvoiceDialog must have 0 overflow at 320dp width');
    });
  });
}
