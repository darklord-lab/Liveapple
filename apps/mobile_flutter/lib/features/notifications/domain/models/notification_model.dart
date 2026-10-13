import 'dart:convert';

class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String body;
  final String? deepLink;
  final String? classId;
  final String? batchId;
  final DateTime? readAt;
  final DateTime createdAt;
  final Map<String, dynamic> payload;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.deepLink,
    this.classId,
    this.batchId,
    this.readAt,
    required this.createdAt,
    this.payload = const {},
  });

  bool get isRead => readAt != null;
  bool get isLiveStart => type == 'LIVE_START';
  bool get isReminder => type == 'REMINDER_15M';

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    DateTime? parseNullableDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    Map<String, dynamic> parsePayload(dynamic raw) {
      if (raw == null) return <String, dynamic>{};
      if (raw is Map<String, dynamic>) return raw;
      if (raw is Map) return Map<String, dynamic>.from(raw);
      if (raw is String) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) return decoded;
          if (decoded is Map) return Map<String, dynamic>.from(decoded);
        } catch (_) {}
      }
      return <String, dynamic>{};
    }

    final payloadMap = parsePayload(json['payload']);

    return NotificationModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'SYSTEM',
      title: json['title']?.toString() ?? payloadMap['title']?.toString() ?? 'Notification',
      body: json['body']?.toString() ?? payloadMap['body']?.toString() ?? '',
      deepLink: json['deepLink']?.toString() ?? payloadMap['deepLink']?.toString(),
      classId: json['classId']?.toString() ?? payloadMap['classId']?.toString(),
      batchId: json['batchId']?.toString() ?? payloadMap['batchId']?.toString(),
      readAt: parseNullableDate(json['readAt']),
      createdAt: parseDate(json['createdAt']),
      payload: payloadMap,
    );
  }

  NotificationModel copyWith({
    String? id,
    String? type,
    String? title,
    String? body,
    String? deepLink,
    String? classId,
    String? batchId,
    DateTime? readAt,
    DateTime? createdAt,
    Map<String, dynamic>? payload,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      deepLink: deepLink ?? this.deepLink,
      classId: classId ?? this.classId,
      batchId: batchId ?? this.batchId,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      payload: payload ?? this.payload,
    );
  }
}
