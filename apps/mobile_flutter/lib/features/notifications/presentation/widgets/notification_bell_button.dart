import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/notification_controller.dart';
import 'notifications_sheet.dart';

class NotificationBellButton extends ConsumerWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationControllerProvider);

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            color: Color(0xFF94A3B8),
            size: 22,
          ),
          onPressed: () {
            NotificationsSheet.show(context);
          },
          tooltip: 'Notifications',
        ),
        if (state.unreadCount > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                state.unreadCount > 99 ? '99+' : '${state.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
