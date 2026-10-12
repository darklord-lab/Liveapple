class LiveClassModel {
  final String id;
  final String batchId;
  final String? batchName;
  final String? subject;
  final String? teacherId;
  final String? teacherName;
  final String title;
  final DateTime scheduledAt;
  final String status; // SCHEDULED, LIVE, ENDED, CANCELLED
  final String livekitRoom;
  final String? recordingUrl;
  final int attendanceCount;

  LiveClassModel({
    required this.id,
    required this.batchId,
    this.batchName,
    this.subject,
    this.teacherId,
    this.teacherName,
    required this.title,
    required this.scheduledAt,
    required this.status,
    required this.livekitRoom,
    this.recordingUrl,
    this.attendanceCount = 0,
  });

  factory LiveClassModel.fromJson(Map<String, dynamic> json) {
    return LiveClassModel(
      id: json['id'] as String,
      batchId: json['batchId'] as String,
      batchName: json['batch']?['name'] as String?,
      subject: json['batch']?['subject'] as String?,
      teacherId: json['teacherId'] as String? ?? json['teacher']?['id'] as String?,
      teacherName: json['teacher']?['name'] as String?,
      title: json['title'] as String,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      status: json['status'] as String? ?? 'SCHEDULED',
      livekitRoom: json['livekitRoom'] as String? ?? '',
      recordingUrl: json['recordingUrl'] as String?,
      attendanceCount: json['_count']?['attendances'] as int? ?? 0,
    );
  }

  bool get isLive => status.toUpperCase() == 'LIVE';
  bool get isScheduled => status.toUpperCase() == 'SCHEDULED';
  bool get isEnded => status.toUpperCase() == 'ENDED';

  String get formattedDate {
    final now = DateTime.now();
    final isToday = scheduledAt.year == now.year && scheduledAt.month == now.month && scheduledAt.day == now.day;
    final isTomorrow = scheduledAt.year == now.year && scheduledAt.month == now.month && scheduledAt.day == now.day + 1;

    if (isToday) return 'Today';
    if (isTomorrow) return 'Tomorrow';

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${scheduledAt.day} ${months[scheduledAt.month - 1]}';
  }

  String get formattedTime {
    final hour = scheduledAt.hour;
    final minute = scheduledAt.minute;
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour % 12 == 0 ? 12 : hour % 12;
    final formattedMin = minute < 10 ? '0$minute' : '$minute';
    return '$formattedHour:$formattedMin $ampm';
  }
}
