import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/notification_controller.dart';
import 'notifications_sheet.dart';

class NotificationBellButton extends ConsumerWidget {
  final Color color;
  final Color badgeColor;

  const NotificationBellButton({
    super.key,
    this.color = Colors.white,
    this.badgeColor = AppColors.liveRed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationControllerProvider);

    return Semantics(
      button: true,
      label: state.unreadCount > 0
          ? 'Notifications, ${state.unreadCount} unread'
          : 'Notifications',
      child: Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: color,
              size: 24,
            ),
            constraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
            padding: const EdgeInsets.all(8),
            onPressed: () {
              NotificationsSheet.show(context);
            },
            tooltip: 'Notifications',
          ),
          if (state.unreadCount > 0)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.2),
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  state.unreadCount > 99 ? '99+' : '${state.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
