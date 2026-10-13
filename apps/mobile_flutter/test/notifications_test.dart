import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:classora_mobile/core/services/push_notification_service.dart';
import 'package:classora_mobile/features/notifications/data/notification_repository.dart';
import 'package:classora_mobile/features/notifications/domain/models/notification_model.dart';
import 'package:classora_mobile/features/notifications/presentation/controllers/notification_controller.dart';
import 'package:classora_mobile/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:classora_mobile/features/notifications/presentation/widgets/notifications_sheet.dart';

class FakeNotificationRepository extends NotificationRepository {
  List<NotificationModel> mockNotifications = [];
  int mockUnreadCount = 0;
  List<String> registeredTokens = [];
  List<String> markedReadIds = [];
  bool markAllCalled = false;

  @override
  Future<NotificationListResponse> getNotifications({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    return NotificationListResponse(
      notifications: mockNotifications,
      total: mockNotifications.length,
      unreadCount: mockUnreadCount,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    markedReadIds.add(notificationId);
  }

  @override
  Future<int> markAllAsRead() async {
    markAllCalled = true;
    return mockUnreadCount;
  }

  @override
  Future<void> registerFcmToken(String token, {String? deviceId}) async {
    registeredTokens.add(token);
  }

  @override
  Future<void> removeFcmToken() async {}
}

void main() {
  group('Phase 5 — NotificationModel Parsing & Domain Logic', () {
    test('parses standard notification from JSON correctly', () {
      final json = {
        'id': 'notif-101',
        'type': 'SYSTEM',
        'title': 'Welcome to Classora',
        'body': 'Your account has been set up successfully.',
        'createdAt': '2026-10-13T10:00:00Z',
        'readAt': null,
      };

      final notif = NotificationModel.fromJson(json);

      expect(notif.id, 'notif-101');
      expect(notif.type, 'SYSTEM');
      expect(notif.title, 'Welcome to Classora');
      expect(notif.body, 'Your account has been set up successfully.');
      expect(notif.isRead, isFalse);
      expect(notif.isLiveStart, isFalse);
      expect(notif.isReminder, isFalse);
    });

    test('parses LIVE_START notification with classId and deepLink', () {
      final json = {
        'id': 'notif-102',
        'type': 'LIVE_START',
        'title': '🔴 Live Class Started',
        'body': 'Physics - Grade 11 is now live!',
        'classId': 'class-999',
        'batchId': 'batch-888',
        'deepLink': '/live/class-999',
        'createdAt': '2026-10-13T11:00:00Z',
        'readAt': null,
        'payload': {
          'classId': 'class-999',
          'batchId': 'batch-888',
          'deepLink': '/live/class-999',
        },
      };

      final notif = NotificationModel.fromJson(json);

      expect(notif.id, 'notif-102');
      expect(notif.type, 'LIVE_START');
      expect(notif.isLiveStart, isTrue);
      expect(notif.classId, 'class-999');
      expect(notif.batchId, 'batch-888');
      expect(notif.deepLink, '/live/class-999');
      expect(notif.isRead, isFalse);
    });

    test('parses REMINDER_15M notification with stringified JSON payload fallback', () {
      final json = {
        'id': 'notif-103',
        'type': 'REMINDER_15M',
        'title': '⏰ Class in 15 Minutes',
        'body': 'Chemistry starts soon at 11:30 AM',
        'createdAt': '2026-10-13T11:15:00Z',
        'readAt': '2026-10-13T11:16:00Z',
        'payload': '{"classId":"class-555","deepLink":"/live/class-555"}',
      };

      final notif = NotificationModel.fromJson(json);

      expect(notif.id, 'notif-103');
      expect(notif.isReminder, isTrue);
      expect(notif.classId, 'class-555');
      expect(notif.deepLink, '/live/class-555');
      expect(notif.isRead, isTrue);
    });

    test('copyWith updates fields correctly', () {
      final notif = NotificationModel(
        id: 'n1',
        type: 'SYSTEM',
        title: 'Title',
        body: 'Body',
        createdAt: DateTime.now(),
      );

      final readNotif = notif.copyWith(readAt: DateTime.now());
      expect(readNotif.isRead, isTrue);
    });
  });

  group('Phase 5 — NotificationController State Management', () {
    test('fetches notifications and updates unreadCount', () async {
      final fakeRepo = FakeNotificationRepository();
      fakeRepo.mockNotifications = [
        NotificationModel(
          id: 'n1',
          type: 'LIVE_START',
          title: 'Class Live',
          body: 'Started now',
          classId: 'c1',
          createdAt: DateTime.now(),
        ),
      ];
      fakeRepo.mockUnreadCount = 1;

      final controller = NotificationController(repository: fakeRepo);
      await controller.fetchNotifications();

      expect(controller.state.notifications.length, 1);
      expect(controller.state.unreadCount, 1);
      expect(controller.state.isLoading, isFalse);
    });

    test('onNotificationReceived prepends new notification and increments unreadCount', () async {
      final fakeRepo = FakeNotificationRepository();
      final controller = NotificationController(repository: fakeRepo);
      await controller.fetchNotifications();

      final newNotif = NotificationModel(
        id: 'new-1',
        type: 'LIVE_START',
        title: '🔴 Physics Live',
        body: 'Join now',
        classId: 'p1',
        createdAt: DateTime.now(),
      );

      controller.onNotificationReceived(newNotif);

      expect(controller.state.notifications.length, 1);
      expect(controller.state.notifications.first.id, 'new-1');
      expect(controller.state.unreadCount, 1);

      // Duplicate prevention
      controller.onNotificationReceived(newNotif);
      expect(controller.state.notifications.length, 1);
      expect(controller.state.unreadCount, 1);
    });

    test('markAsRead updates target notification and decrements unreadCount', () async {
      final fakeRepo = FakeNotificationRepository();
      fakeRepo.mockNotifications = [
        NotificationModel(
          id: 'n1',
          type: 'LIVE_START',
          title: 'Class Live',
          body: 'Started now',
          classId: 'c1',
          createdAt: DateTime.now(),
        ),
        NotificationModel(
          id: 'n2',
          type: 'SYSTEM',
          title: 'System Note',
          body: 'Hello',
          createdAt: DateTime.now(),
        ),
      ];
      fakeRepo.mockUnreadCount = 2;

      final controller = NotificationController(repository: fakeRepo);
      await controller.fetchNotifications();

      await controller.markAsRead('n1');

      expect(controller.state.unreadCount, 1);
      expect(controller.state.notifications.firstWhere((n) => n.id == 'n1').isRead, isTrue);
      expect(fakeRepo.markedReadIds.contains('n1'), isTrue);
    });

    test('markAllAsRead marks all notifications read and resets unreadCount', () async {
      final fakeRepo = FakeNotificationRepository();
      fakeRepo.mockNotifications = [
        NotificationModel(
          id: 'n1',
          type: 'LIVE_START',
          title: 'Class Live',
          body: 'Started now',
          createdAt: DateTime.now(),
        ),
      ];
      fakeRepo.mockUnreadCount = 1;

      final controller = NotificationController(repository: fakeRepo);
      await controller.fetchNotifications();

      await controller.markAllAsRead();

      expect(controller.state.unreadCount, 0);
      expect(controller.state.notifications.every((n) => n.isRead), isTrue);
      expect(fakeRepo.markAllCalled, isTrue);
    });
  });

  group('Phase 5 — NotificationBellButton Widget', () {
    testWidgets('renders bell button and badge count when unreadCount > 0', (tester) async {
      final fakeRepo = FakeNotificationRepository();
      fakeRepo.mockNotifications = [
        NotificationModel(
          id: 'n1',
          type: 'SYSTEM',
          title: 'Notice',
          body: 'Body',
          createdAt: DateTime.now(),
        ),
      ];
      fakeRepo.mockUnreadCount = 3;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(56),
                child: Row(
                  children: [
                    NotificationBellButton(color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NotificationBellButton), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('hides badge when unreadCount is 0', (tester) async {
      final fakeRepo = FakeNotificationRepository();
      fakeRepo.mockNotifications = [];
      fakeRepo.mockUnreadCount = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(56),
                child: Row(
                  children: [
                    NotificationBellButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('shows 99+ when unreadCount exceeds 99', (tester) async {
      final fakeRepo = FakeNotificationRepository();
      fakeRepo.mockUnreadCount = 120;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(56),
                child: Row(
                  children: [
                    NotificationBellButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('99+'), findsOneWidget);
    });
  });

  group('Phase 5 — NotificationsSheet Light-First Theme & Layout', () {
    testWidgets('renders empty state when no notifications', (tester) async {
      final fakeRepo = FakeNotificationRepository();
      fakeRepo.mockNotifications = [];
      fakeRepo.mockUnreadCount = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationsSheet(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('All caught up!'), findsOneWidget);
      expect(find.text('You have no unread live class or timetable alerts.'), findsOneWidget);
    });

    testWidgets('renders notification list with unread card & Join Live button', (tester) async {
      final fakeRepo = FakeNotificationRepository();
      fakeRepo.mockNotifications = [
        NotificationModel(
          id: 'live-notif',
          type: 'LIVE_START',
          title: '🔴 Physics Live',
          body: 'Grade 10 is now live!',
          classId: 'cls-100',
          createdAt: DateTime.now(),
        ),
        NotificationModel(
          id: 'reminder-notif',
          type: 'REMINDER_15M',
          title: '⏰ Class in 15 Minutes',
          body: 'Maths starts soon',
          classId: 'cls-200',
          createdAt: DateTime.now(),
        ),
      ];
      fakeRepo.mockUnreadCount = 2;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationsSheet(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('2 new'), findsOneWidget);
      expect(find.text('Mark read'), findsOneWidget);
      expect(find.text('🔴 Physics Live'), findsOneWidget);
      expect(find.text('Join Live'), findsOneWidget);
      expect(find.text('Class Soon'), findsOneWidget);
    });

    testWidgets('tapping Mark read triggers markAllAsRead in controller', (tester) async {
      final fakeRepo = FakeNotificationRepository();
      fakeRepo.mockNotifications = [
        NotificationModel(
          id: 'live-notif',
          type: 'LIVE_START',
          title: '🔴 Physics Live',
          body: 'Grade 10 is now live!',
          classId: 'cls-100',
          createdAt: DateTime.now(),
        ),
      ];
      fakeRepo.mockUnreadCount = 1;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationsSheet(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Mark read'), findsOneWidget);
      await tester.tap(find.text('Mark read'));
      await tester.pumpAndSettle();

      expect(fakeRepo.markAllCalled, isTrue);
    });

    testWidgets('renders cleanly on narrow 320dp screen without overflow', (tester) async {
      tester.view.physicalSize = const Size(320 * 2.0, 640 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeRepo = FakeNotificationRepository();
      fakeRepo.mockNotifications = [
        NotificationModel(
          id: 'live-notif',
          type: 'LIVE_START',
          title: '🔴 Advanced Engineering Mathematics Live Stream Now Active',
          body: 'Very long description that details all class requirements and instructions for attending live session.',
          classId: 'cls-100',
          createdAt: DateTime.now(),
        ),
      ];
      fakeRepo.mockUnreadCount = 1;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationsSheet(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Join Live'), findsOneWidget);
    });
  });

  group('Phase 5 — PushNotificationService Realtime In-App Banner', () {
    testWidgets('shows in-app banner toast with JOIN NOW for LIVE_START', (tester) async {
      final fakeRepo = FakeNotificationRepository();

      late PushNotificationService pushService;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  pushService = ref.watch(pushNotificationServiceProvider);
                  return ElevatedButton(
                    onPressed: () {
                      pushService.handleIncomingNotification(context, {
                        'id': 'socket-1',
                        'type': 'LIVE_START',
                        'title': '🔴 Live Now',
                        'body': 'Mathematics class has started!',
                        'classId': 'cls-math',
                        'deepLink': '/live/cls-math',
                      });
                    },
                    child: const Text('Simulate Push'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Simulate Push'));
      await tester.pump();

      expect(find.text('LIVE'), findsOneWidget);
      expect(find.text('🔴 Live Now'), findsOneWidget);
      expect(find.text('Mathematics class has started!'), findsOneWidget);
      expect(find.text('JOIN NOW'), findsOneWidget);
    });
  });
}
