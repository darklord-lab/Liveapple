import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../storage/secure_storage.dart';
import '../theme/app_colors.dart';
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
        final storage = SecureStorageService();
        await storage.saveFcmToken(initialFcmToken);
        await _repository.registerFcmToken(initialFcmToken);
      } catch (e) {
        debugPrint('[PUSH-SERVICE] Failed to register FCM token: $e');
      }
    }
  }

  /// Register saved FCM token if available in local storage
  Future<void> registerTokenIfSaved() async {
    try {
      final storage = SecureStorageService();
      final token = await storage.getFcmToken();
      if (token != null && token.isNotEmpty) {
        await _repository.registerFcmToken(token);
      }
    } catch (e) {
      debugPrint('[PUSH-SERVICE] Failed to register saved token: $e');
    }
  }

  /// Handle incoming real-time socket / FCM notification
  void handleIncomingNotification(
    BuildContext context,
    Map<String, dynamic> rawData,
  ) {
    final notif = NotificationModel.fromJson(rawData);
    _ref.read(notificationControllerProvider.notifier).onNotificationReceived(notif);

    // Display high-priority floating in-app banner alert
    showInAppBanner(context, notif);
  }

  /// Show sleek, dismissible in-app alert banner
  void showInAppBanner(BuildContext context, NotificationModel notif) {
    final isLive = notif.isLiveStart;
    final accentColor = isLive ? AppColors.liveRed : AppColors.skyBlue;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: Duration(seconds: isLive ? 10 : 6),
        backgroundColor: AppColors.slate900,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: accentColor, width: 1.5),
        ),
        content: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isLive ? Icons.videocam_rounded : Icons.notifications_active_outlined,
                color: accentColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isLive) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.liveRed,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          notif.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notif.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.slate300,
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: isLive ? 'JOIN NOW' : 'VIEW',
          textColor: accentColor,
          onPressed: () {
            handleNotificationTap(context, notif);
          },
        ),
      ),
    );
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
