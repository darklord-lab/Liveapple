class TeacherModel {
  final String id;
  final String instituteId;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String status; // "ACTIVE" | "INVITED" | "SUSPENDED"
  final DateTime createdAt;
  final int batchesCount;
  final int classesCount;

  const TeacherModel({
    required this.id,
    required this.instituteId,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.status,
    required this.createdAt,
    this.batchesCount = 0,
    this.classesCount = 0,
  });

  bool get isActive => status == 'ACTIVE';
  bool get isInvited => status == 'INVITED';
  bool get isSuspended => status == 'SUSPENDED';

  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    final counts = json['_count'] as Map<String, dynamic>?;
    return TeacherModel(
      id: json['id'] as String,
      instituteId: json['instituteId'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'TEACHER',
      status: json['status'] as String? ?? 'ACTIVE',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      batchesCount: counts?['taughtBatches'] as int? ?? (json['taughtBatches'] as List?)?.length ?? 0,
      classesCount: counts?['taughtClasses'] as int? ?? 0,
    );
  }
}

class AddTeacherResult {
  final TeacherModel teacher;
  final String inviteCode;
  final DateTime expiresAt;

  const AddTeacherResult({
    required this.teacher,
    required this.inviteCode,
    required this.expiresAt,
  });

  factory AddTeacherResult.fromJson(Map<String, dynamic> json) {
    return AddTeacherResult(
      teacher: TeacherModel.fromJson(json['teacher'] as Map<String, dynamic>),
      inviteCode: json['invite']['inviteCode'] as String,
      expiresAt: DateTime.tryParse(json['invite']['expiresAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class BulkOnboardReport {
  final int total;
  final int successfulCount;
  final int failedCount;
  final List<BulkSuccessItem> successful;
  final List<BulkFailedItem> failed;

  const BulkOnboardReport({
    required this.total,
    required this.successfulCount,
    required this.failedCount,
    required this.successful,
    required this.failed,
  });

  factory BulkOnboardReport.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? {};
    final succList = (json['successful'] as List?) ?? [];
    final failList = (json['failed'] as List?) ?? [];

    return BulkOnboardReport(
      total: summary['total'] as int? ?? 0,
      successfulCount: summary['successfulCount'] as int? ?? 0,
      failedCount: summary['failedCount'] as int? ?? 0,
      successful: succList.map((e) => BulkSuccessItem.fromJson(e as Map<String, dynamic>)).toList(),
      failed: failList.map((e) => BulkFailedItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class BulkSuccessItem {
  final int rowNumber;
  final String name;
  final String email;
  final String? phone;
  final String inviteCode;
  final DateTime expiresAt;

  const BulkSuccessItem({
    required this.rowNumber,
    required this.name,
    required this.email,
    this.phone,
    required this.inviteCode,
    required this.expiresAt,
  });

  factory BulkSuccessItem.fromJson(Map<String, dynamic> json) {
    return BulkSuccessItem(
      rowNumber: json['rowNumber'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      inviteCode: json['inviteCode'] as String? ?? '',
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class BulkFailedItem {
  final int rowNumber;
  final String? name;
  final String? email;
  final String reason;

  const BulkFailedItem({
    required this.rowNumber,
    this.name,
    this.email,
    required this.reason,
  });

  factory BulkFailedItem.fromJson(Map<String, dynamic> json) {
    return BulkFailedItem(
      rowNumber: json['rowNumber'] as int? ?? 0,
      name: json['name'] as String?,
      email: json['email'] as String?,
      reason: json['reason'] as String? ?? 'Unknown error',
    );
  }
}
