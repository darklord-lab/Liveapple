import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/notification_repository.dart';
import '../../domain/models/notification_model.dart';

class NotificationState {
  final bool isLoading;
  final List<NotificationModel> notifications;
  final int unreadCount;
  final String? errorMessage;

  const NotificationState({
    this.isLoading = false,
    this.notifications = const [],
    this.unreadCount = 0,
    this.errorMessage,
  });

  NotificationState copyWith({
    bool? isLoading,
    List<NotificationModel>? notifications,
    int? unreadCount,
    String? errorMessage,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      errorMessage: errorMessage,
    );
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

final notificationControllerProvider =
    StateNotifierProvider<NotificationController, NotificationState>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return NotificationController(repository: repository);
});

class NotificationController extends StateNotifier<NotificationState> {
  final NotificationRepository _repository;

  NotificationController({required NotificationRepository repository})
      : _repository = repository,
        super(const NotificationState()) {
    fetchNotifications();
  }

  /// Load user notifications from API
  Future<void> fetchNotifications({bool showLoading = true}) async {
    if (showLoading) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }
    try {
      final res = await _repository.getNotifications();
      state = state.copyWith(
        isLoading: false,
        notifications: res.notifications,
        unreadCount: res.unreadCount,
        errorMessage: null,
      );
    } catch (err) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: err.toString(),
      );
    }
  }

  /// Handle incoming live real-time notification
  void onNotificationReceived(NotificationModel notif) {
    // Avoid duplicate
    final existingIndex = state.notifications.indexWhere((n) => n.id == notif.id);
    if (existingIndex >= 0) return;

    state = state.copyWith(
      notifications: [notif, ...state.notifications],
      unreadCount: state.unreadCount + 1,
    );
  }

  /// Mark single notification as read
  Future<void> markAsRead(String id) async {
    // Optimistic UI update
    final updatedList = state.notifications.map((n) {
      if (n.id == id && !n.isRead) {
        return n.copyWith(readAt: DateTime.now());
      }
      return n;
    }).toList();

    final prevUnread = state.unreadCount;
    state = state.copyWith(
      notifications: updatedList,
      unreadCount: prevUnread > 0 ? prevUnread - 1 : 0,
    );

    try {
      await _repository.markAsRead(id);
    } catch (_) {
      // Revert if API fails
      fetchNotifications(showLoading: false);
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final now = DateTime.now();
    final updatedList = state.notifications.map((n) => n.copyWith(readAt: now)).toList();
    state = state.copyWith(notifications: updatedList, unreadCount: 0);

    try {
      await _repository.markAllAsRead();
    } catch (_) {
      fetchNotifications(showLoading: false);
    }
  }
}
