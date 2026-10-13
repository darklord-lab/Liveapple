import 'package:flutter/foundation.dart';

class Endpoints {
  // Remote dynamic config endpoint (auto-updated from repo)
  static const String remoteConfigUrl =
      'https://raw.githubusercontent.com/weblo32/Liveapple/main/server_config.json';

  // Primary production backend (Render.com 24/7 hosting)
  static const String cloudflareTunnelUrl =
      'https://liveapple.onrender.com/api';
  static const String localWifiUrl = 'http://10.186.250.171:4000/api';
  static const String emulatorUrl = 'http://10.0.2.2:4000/api';
  static const String localHostUrl = 'http://localhost:4000/api';

  // Determine standard default base URL
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return localHostUrl;
    }
    // Default to Cloudflare Tunnel for real devices across 4G/5G/Wi-Fi
    return cloudflareTunnelUrl;
  }

  // Auth endpoints
  static const String login = '/v1/auth/login';
  static const String refresh = '/v1/auth/refresh';
  static const String logout = '/v1/auth/logout';
  static const String acceptInvite = '/v1/auth/accept-invite';
  static const String me = '/v1/auth/me';
  static const String updateProfile = '/v1/auth/profile';
  static const String uploadAvatar = '/v1/auth/avatar';

  // Invites
  static const String validateInvite = '/v1/invites/validate';
  static const String invites = '/v1/invites';

  // Admin
  static const String adminTeachers = '/v1/admin/teachers';
  static const String adminBulkTeachers = '/v1/admin/teachers/bulk';

  // Batches & Enrollment
  static const String batches = '/v1/batches';
  static const String joinBatch = '/v1/batches/join';

  // Timetable
  static const String timetable = '/v1/timetable';

  // Live Classes
  static const String classes = '/v1/classes';
  static const String generateUpcomingClasses = '/v1/classes/generate-upcoming';

  // Devices & Push Notifications
  static const String deviceFcmToken = '/v1/devices/fcm-token';
  static const String notifications = '/v1/notifications';
  static const String notificationsReadAll = '/v1/notifications/read-all';

  // Phase 6 Learning Modules
  static const String recordings = '/v1/recordings';
  static const String attendanceJoin = '/v1/attendance/join';
  static const String attendanceLeave = '/v1/attendance/leave';
  static const String attendanceMySummary = '/v1/attendance/my-summary';
  static const String attendanceClass = '/v1/attendance/class';
  static const String assignments = '/v1/assignments';
  static const String tests = '/v1/tests';
  static const String feePlans = '/v1/fees/plans';
  static const String feePay = '/v1/fees/pay';
  static const String feeDues = '/v1/fees/my-dues';
  static const String feeReports = '/v1/fees/reports';

  // Phase 4.1 Study Material & Folders
  static String batchFolders(String batchId) => '/v1/batches/$batchId/folders';
  static String batchMaterials(String batchId) => '/v1/batches/$batchId/materials';
  static String downloadMaterial(String materialId) => '/v1/materials/$materialId/download';
  static String deleteMaterial(String materialId) => '/v1/materials/$materialId';
  static String deleteFolder(String folderId) => '/v1/materials/folders/$folderId';

  // Health
  static const String health = '/health';
}
