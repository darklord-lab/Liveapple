import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/notifications/domain/models/notification_model.dart';
import '../../features/notifications/presentation/controllers/notification_controller.dart';
import '../../features/notifications/data/notification_repository.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return PushNotificationService(ref: ref, repository: repository);
});

class PushNotificationService {
  final Ref _ref;
  final NotificationRepository _repository;

  PushNotificationService({
    required Ref ref,
    required NotificationRepository repository,
  })  : _ref = ref,
        _repository = repository;

  /// Initialize device push token and listeners
  Future<void> initialize({required String? initialFcmToken}) async {
    if (initialFcmToken != null && initialFcmToken.isNotEmpty) {
      try {
        await _repository.registerFcmToken(initialFcmToken);
      } catch (e) {
        debugPrint('[PUSH-SERVICE] Failed to register FCM token: $e');
      }
    }
  }

  /// Handle incoming real-time socket / FCM notification
  void handleIncomingNotification(
    BuildContext context,
    Map<String, dynamic> rawData,
  ) {
    final notif = NotificationModel.fromJson(rawData);
    _ref.read(notificationControllerProvider.notifier).onNotificationReceived(notif);

    // If it's a live class alert, display high-priority banner toast
    if (notif.isLiveStart && notif.classId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
          ),
          content: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notif.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      notif.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'JOIN NOW',
            textColor: const Color(0xFF38BDF8),
            onPressed: () {
              handleNotificationTap(context, notif);
            },
          ),
        ),
      );
    }
  }

  /// Navigate to target deep link
  void handleNotificationTap(BuildContext context, NotificationModel notif) {
    // Mark as read in state
    _ref.read(notificationControllerProvider.notifier).markAsRead(notif.id);

    if (notif.classId != null && notif.classId!.isNotEmpty) {
      context.push('/live/${notif.classId}');
    } else if (notif.deepLink != null && notif.deepLink!.isNotEmpty) {
      context.push(notif.deepLink!);
    }
  }
}
