import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../domain/models/notification_model.dart';

class NotificationListResponse {
  final List<NotificationModel> notifications;
  final int total;
  final int unreadCount;
  final int page;
  final int limit;

  NotificationListResponse({
    required this.notifications,
    required this.total,
    required this.unreadCount,
    required this.page,
    required this.limit,
  });
}

class NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Fetch user notifications with unread counts
  Future<NotificationListResponse> getNotifications({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    final response = await _apiClient.dio.get(
      Endpoints.notifications,
      queryParameters: {
        'page': page,
        'limit': limit,
        'unreadOnly': unreadOnly,
      },
    );

    final data = response.data['data'] as Map<String, dynamic>;
    final rawList = data['notifications'] as List<dynamic>? ?? [];

    final notifications = rawList
        .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return NotificationListResponse(
      notifications: notifications,
      total: (data['total'] as num?)?.toInt() ?? notifications.length,
      unreadCount: (data['unreadCount'] as num?)?.toInt() ?? 0,
      page: (data['page'] as num?)?.toInt() ?? page,
      limit: (data['limit'] as num?)?.toInt() ?? limit,
    );
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String notificationId) async {
    await _apiClient.dio.patch('${Endpoints.notifications}/$notificationId/read');
  }

  /// Mark all unread notifications as read
  Future<int> markAllAsRead() async {
    final response = await _apiClient.dio.patch(Endpoints.notificationsReadAll);
    final data = response.data['data'] as Map<String, dynamic>?;
    return (data?['updatedCount'] as num?)?.toInt() ?? 0;
  }

  /// Register FCM push token for this device
  Future<void> registerFcmToken(String token, {String? deviceId}) async {
    await _apiClient.dio.post(
      Endpoints.deviceFcmToken,
      data: {
        'fcmToken': token,
        if (deviceId != null) 'deviceId': deviceId,
      },
    );
  }

  /// Remove FCM push token on device logout
  Future<void> removeFcmToken() async {
    try {
      await _apiClient.dio.delete(Endpoints.deviceFcmToken);
    } catch (_) {
      // Ignore if already deleted/logged out
    }
  }
}
