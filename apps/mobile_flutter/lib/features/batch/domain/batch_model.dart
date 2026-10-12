class BatchModel {
  final String id;
  final String name;
  final String subject;
  final String joinCode;
  final String teacherId;
  final String? teacherName;
  final String? teacherEmail;
  final int activeStudentsCount;
  final int timetableSlotsCount;
  final int liveClassesCount;
  final DateTime? createdAt;

  BatchModel({
    required this.id,
    required this.name,
    required this.subject,
    required this.joinCode,
    required this.teacherId,
    this.teacherName,
    this.teacherEmail,
    this.activeStudentsCount = 0,
    this.timetableSlotsCount = 0,
    this.liveClassesCount = 0,
    this.createdAt,
  });

  factory BatchModel.fromJson(Map<String, dynamic> json) {
    return BatchModel(
      id: json['id'] as String,
      name: json['name'] as String,
      subject: json['subject'] as String,
      joinCode: json['joinCode'] as String,
      teacherId: json['teacherId'] as String,
      teacherName: json['teacher']?['name'] as String?,
      teacherEmail: json['teacher']?['email'] as String?,
      activeStudentsCount: json['_count']?['enrollments'] as int? ?? 0,
      timetableSlotsCount: json['_count']?['timetableSlots'] as int? ?? 0,
      liveClassesCount: json['_count']?['liveClasses'] as int? ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
  }
}

class EnrolledStudentModel {
  final String enrollmentId;
  final String studentId;
  final String name;
  final String email;
  final String? phone;
  final String status;
  final DateTime? enrolledAt;

  EnrolledStudentModel({
    required this.enrollmentId,
    required this.studentId,
    required this.name,
    required this.email,
    this.phone,
    required this.status,
    this.enrolledAt,
  });

  factory EnrolledStudentModel.fromJson(Map<String, dynamic> json) {
    final student = json['student'] ?? json;
    return EnrolledStudentModel(
      enrollmentId: json['id'] as String? ?? '',
      studentId: student['id'] as String? ?? json['studentId'] as String? ?? '',
      name: student['name'] as String? ?? 'N/A',
      email: student['email'] as String? ?? 'N/A',
      phone: student['phone'] as String?,
      status: json['status'] as String? ?? student['status'] as String? ?? 'ACTIVE',
      enrolledAt: json['enrolledAt'] != null ? DateTime.tryParse(json['enrolledAt'] as String) : null,
    );
  }
}

class BulkEnrollResultModel {
  final int total;
  final int enrolled;
  final int alreadyEnrolled;
  final int invited;
  final int failed;
  final List<BulkEnrollRowModel> rows;

  BulkEnrollResultModel({
    required this.total,
    required this.enrolled,
    required this.alreadyEnrolled,
    required this.invited,
    required this.failed,
    required this.rows,
  });

  factory BulkEnrollResultModel.fromJson(Map<String, dynamic> json) {
    final rowsList = (json['rows'] as List<dynamic>?)
            ?.map((r) => BulkEnrollRowModel.fromJson(r as Map<String, dynamic>))
            .toList() ??
        [];
    return BulkEnrollResultModel(
      total: json['total'] as int? ?? 0,
      enrolled: json['enrolled'] as int? ?? 0,
      alreadyEnrolled: json['alreadyEnrolled'] as int? ?? 0,
      invited: json['invited'] as int? ?? 0,
      failed: json['failed'] as int? ?? 0,
      rows: rowsList,
    );
  }
}

class BulkEnrollRowModel {
  final int rowNumber;
  final String name;
  final String email;
  final String? phone;
  final String status;
  final String? reason;
  final String? inviteCode;
  final String? inviteUrl;

  BulkEnrollRowModel({
    required this.rowNumber,
    required this.name,
    required this.email,
    this.phone,
    required this.status,
    this.reason,
    this.inviteCode,
    this.inviteUrl,
  });

  factory BulkEnrollRowModel.fromJson(Map<String, dynamic> json) {
    return BulkEnrollRowModel(
      rowNumber: json['rowNumber'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      status: json['status'] as String? ?? 'UNKNOWN',
      reason: json['reason'] as String?,
      inviteCode: json['inviteCode'] as String?,
      inviteUrl: json['inviteUrl'] as String?,
    );
  }
}
