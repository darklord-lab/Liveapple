class TimetableSlotModel {
  final String id;
  final String instituteId;
  final String teacherId;
  final String batchId;
  final String? batchName;
  final String? subject;
  final String? teacherName;
  final String? teacherEmail;
  final int dayOfWeek; // 0 = Sunday, 1 = Monday, ... 6 = Saturday
  final int startMin;
  final int endMin;
  final bool recurring;

  TimetableSlotModel({
    required this.id,
    required this.instituteId,
    required this.teacherId,
    required this.batchId,
    this.batchName,
    this.subject,
    this.teacherName,
    this.teacherEmail,
    required this.dayOfWeek,
    required this.startMin,
    required this.endMin,
    this.recurring = true,
  });

  factory TimetableSlotModel.fromJson(Map<String, dynamic> json) {
    return TimetableSlotModel(
      id: json['id'] as String,
      instituteId: json['instituteId'] as String? ?? '',
      teacherId: json['teacherId'] as String? ?? '',
      batchId: json['batchId'] as String,
      batchName: json['batch']?['name'] as String?,
      subject: json['batch']?['subject'] as String?,
      teacherName: json['teacher']?['name'] as String?,
      teacherEmail: json['teacher']?['email'] as String?,
      dayOfWeek: json['dayOfWeek'] as int,
      startMin: json['startMin'] as int,
      endMin: json['endMin'] as int,
      recurring: json['recurring'] as bool? ?? true,
    );
  }

  String get dayName {
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    if (dayOfWeek >= 0 && dayOfWeek < days.length) {
      return days[dayOfWeek];
    }
    return 'Unknown';
  }

  String get shortDayName {
    const days = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    if (dayOfWeek >= 0 && dayOfWeek < days.length) {
      return days[dayOfWeek];
    }
    return 'UNK';
  }

  static String formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    final ampm = hours >= 12 ? 'PM' : 'AM';
    final formattedHours = hours % 12 == 0 ? 12 : hours % 12;
    final formattedMins = mins < 10 ? '0$mins' : '$mins';
    return '$formattedHours:$formattedMins $ampm';
  }

  String get timeRange => '${formatMinutes(startMin)} – ${formatMinutes(endMin)}';

  int get durationMinutes => endMin - startMin;

  String get durationString {
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    if (hours > 0 && mins > 0) return '${hours}h ${mins}m';
    if (hours > 0) return '${hours}h';
    return '${mins}m';
  }
}
