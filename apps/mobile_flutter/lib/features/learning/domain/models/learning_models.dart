class RecordingModel {
  final String id;
  final String title;
  final String videoUrl;
  final int durationSec;
  final double fileSizeMb;
  final String? batchName;
  final String? subject;
  final DateTime createdAt;

  RecordingModel({
    required this.id,
    required this.title,
    required this.videoUrl,
    required this.durationSec,
    required this.fileSizeMb,
    this.batchName,
    this.subject,
    required this.createdAt,
  });

  String get durationFormatted {
    final mins = (durationSec / 60).floor();
    final secs = durationSec % 60;
    return '${mins}m ${secs}s';
  }

  factory RecordingModel.fromJson(Map<String, dynamic> json) {
    final liveClass = json['liveClass'] as Map<String, dynamic>?;
    final batch = liveClass?['batch'] as Map<String, dynamic>?;

    return RecordingModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Class Recording',
      videoUrl: json['videoUrl']?.toString() ?? '',
      durationSec: (json['durationSec'] as num?)?.toInt() ?? 0,
      fileSizeMb: (json['fileSizeMb'] as num?)?.toDouble() ?? 0.0,
      batchName: batch?['name']?.toString(),
      subject: batch?['subject']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class AttendanceSummaryModel {
  final int totalClasses;
  final int attendedClasses;
  final int missedClasses;
  final int overallPercentage;
  final int totalMinutesAttended;

  AttendanceSummaryModel({
    required this.totalClasses,
    required this.attendedClasses,
    required this.missedClasses,
    required this.overallPercentage,
    required this.totalMinutesAttended,
  });

  factory AttendanceSummaryModel.fromJson(Map<String, dynamic> json) {
    return AttendanceSummaryModel(
      totalClasses: (json['totalClasses'] as num?)?.toInt() ?? 0,
      attendedClasses: (json['attendedClasses'] as num?)?.toInt() ?? 0,
      missedClasses: (json['missedClasses'] as num?)?.toInt() ?? 0,
      overallPercentage: (json['overallPercentage'] as num?)?.toInt() ?? 0,
      totalMinutesAttended: (json['totalMinutesAttended'] as num?)?.toInt() ?? 0,
    );
  }
}

class AttendanceRosterItem {
  final String studentName;
  final String studentEmail;
  final String status;
  final int totalDurationMin;
  final int sessionsCount;

  AttendanceRosterItem({
    required this.studentName,
    required this.studentEmail,
    required this.status,
    required this.totalDurationMin,
    required this.sessionsCount,
  });

  bool get isPresent => status == 'PRESENT';

  factory AttendanceRosterItem.fromJson(Map<String, dynamic> json) {
    final student = json['student'] as Map<String, dynamic>?;
    return AttendanceRosterItem(
      studentName: student?['name']?.toString() ?? 'Student',
      studentEmail: student?['email']?.toString() ?? '',
      status: json['status']?.toString() ?? 'ABSENT',
      totalDurationMin: (json['totalDurationMin'] as num?)?.toInt() ?? 0,
      sessionsCount: (json['sessionsCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class AttendanceClassRosterModel {
  final String classId;
  final String title;
  final int totalEnrolled;
  final int presentCount;
  final int absentCount;
  final int attendancePercentage;
  final List<AttendanceRosterItem> roster;

  AttendanceClassRosterModel({
    required this.classId,
    required this.title,
    required this.totalEnrolled,
    required this.presentCount,
    required this.absentCount,
    required this.attendancePercentage,
    required this.roster,
  });

  factory AttendanceClassRosterModel.fromJson(Map<String, dynamic> json) {
    final rawRoster = json['roster'] as List<dynamic>? ?? [];
    return AttendanceClassRosterModel(
      classId: json['classId']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Live Class',
      totalEnrolled: (json['totalEnrolled'] as num?)?.toInt() ?? 0,
      presentCount: (json['presentCount'] as num?)?.toInt() ?? 0,
      absentCount: (json['absentCount'] as num?)?.toInt() ?? 0,
      attendancePercentage: (json['attendancePercentage'] as num?)?.toInt() ?? 0,
      roster: rawRoster
          .map((item) => AttendanceRosterItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AssignmentModel {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String? attachmentUrl;
  final int maxMarks;
  final String? batchName;
  final String? subject;
  final bool isSubmitted;
  final int? marksObtained;
  final String? submissionStatus;

  AssignmentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    this.attachmentUrl,
    required this.maxMarks,
    this.batchName,
    this.subject,
    required this.isSubmitted,
    this.marksObtained,
    this.submissionStatus,
  });

  bool get isGraded => submissionStatus == 'GRADED';

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    final batch = json['batch'] as Map<String, dynamic>?;
    final mySub = json['mySubmission'] as Map<String, dynamic>?;

    return AssignmentModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Assignment',
      description: json['description']?.toString() ?? '',
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      attachmentUrl: json['attachmentUrl']?.toString(),
      maxMarks: (json['maxMarks'] as num?)?.toInt() ?? 100,
      batchName: batch?['name']?.toString(),
      subject: batch?['subject']?.toString(),
      isSubmitted: json['isSubmitted'] == true || mySub != null,
      marksObtained: (mySub?['marksObtained'] as num?)?.toInt(),
      submissionStatus: mySub?['status']?.toString(),
    );
  }
}

class CbtQuestionModel {
  final String id;
  final String text;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final int marks;
  final String? correctOption;
  final String? explanation;

  CbtQuestionModel({
    required this.id,
    required this.text,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.marks,
    this.correctOption,
    this.explanation,
  });

  factory CbtQuestionModel.fromJson(Map<String, dynamic> json) {
    return CbtQuestionModel(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      optionA: json['optionA']?.toString() ?? '',
      optionB: json['optionB']?.toString() ?? '',
      optionC: json['optionC']?.toString() ?? '',
      optionD: json['optionD']?.toString() ?? '',
      marks: (json['marks'] as num?)?.toInt() ?? 1,
      correctOption: json['correctOption']?.toString(),
      explanation: json['explanation']?.toString(),
    );
  }
}

class CbtTestModel {
  final String id;
  final String title;
  final String? description;
  final int durationMin;
  final int totalMarks;
  final int questionsCount;
  final bool isAttempted;
  final int? myScore;
  final String? myAttemptId;
  final String? batchName;
  final String? subject;
  final List<CbtQuestionModel> questions;

  CbtTestModel({
    required this.id,
    required this.title,
    this.description,
    required this.durationMin,
    required this.totalMarks,
    required this.questionsCount,
    required this.isAttempted,
    this.myScore,
    this.myAttemptId,
    this.batchName,
    this.subject,
    this.questions = const [],
  });

  factory CbtTestModel.fromJson(Map<String, dynamic> json) {
    final batch = json['batch'] as Map<String, dynamic>?;
    final myAtt = json['myAttempt'] as Map<String, dynamic>?;
    final rawQuestions = json['questions'] as List<dynamic>? ?? [];

    return CbtTestModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'CBT Test',
      description: json['description']?.toString(),
      durationMin: (json['durationMin'] as num?)?.toInt() ?? 30,
      totalMarks: (json['totalMarks'] as num?)?.toInt() ?? 100,
      questionsCount: (json['questionsCount'] as num?)?.toInt() ?? rawQuestions.length,
      isAttempted: json['isAttempted'] == true || myAtt != null,
      myScore: (myAtt?['score'] as num?)?.toInt(),
      myAttemptId: myAtt?['id']?.toString() ?? json['attemptId']?.toString(),
      batchName: batch?['name']?.toString(),
      subject: batch?['subject']?.toString(),
      questions: rawQuestions
          .map((q) => CbtQuestionModel.fromJson(q as Map<String, dynamic>))
          .toList(),
    );
  }
}

class FeePlanModel {
  final String id;
  final String name;
  final double amount;
  final String interval;
  final String? description;
  final String? batchName;

  FeePlanModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.interval,
    this.description,
    this.batchName,
  });

  factory FeePlanModel.fromJson(Map<String, dynamic> json) {
    final batch = json['batch'] as Map<String, dynamic>?;
    return FeePlanModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Fee Plan',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      interval: json['interval']?.toString() ?? 'MONTHLY',
      description: json['description']?.toString(),
      batchName: batch?['name']?.toString(),
    );
  }
}

class PaymentReceiptModel {
  final String id;
  final double amount;
  final String status;
  final String paymentMethod;
  final String transactionId;
  final String receiptNo;
  final DateTime paidAt;
  final String? feePlanName;

  PaymentReceiptModel({
    required this.id,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    required this.transactionId,
    required this.receiptNo,
    required this.paidAt,
    this.feePlanName,
  });

  factory PaymentReceiptModel.fromJson(Map<String, dynamic> json) {
    final plan = json['feePlan'] as Map<String, dynamic>?;
    return PaymentReceiptModel(
      id: json['id']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'SUCCESS',
      paymentMethod: json['paymentMethod']?.toString() ?? 'UPI',
      transactionId: json['transactionId']?.toString() ?? '',
      receiptNo: json['receiptNo']?.toString() ?? '',
      paidAt: json['paidAt'] != null
          ? DateTime.tryParse(json['paidAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      feePlanName: plan?['name']?.toString(),
    );
  }
}

class StudentDuesModel {
  final double totalDue;
  final double totalPaid;
  final double outstandingBalance;
  final List<FeePlanModel> applicablePlans;
  final List<PaymentReceiptModel> paymentHistory;

  StudentDuesModel({
    required this.totalDue,
    required this.totalPaid,
    required this.outstandingBalance,
    required this.applicablePlans,
    required this.paymentHistory,
  });

  factory StudentDuesModel.fromJson(Map<String, dynamic> json) {
    final rawPlans = json['applicablePlans'] as List<dynamic>? ?? [];
    final rawHistory = json['paymentHistory'] as List<dynamic>? ?? [];

    return StudentDuesModel(
      totalDue: (json['totalDue'] as num?)?.toDouble() ?? 0.0,
      totalPaid: (json['totalPaid'] as num?)?.toDouble() ?? 0.0,
      outstandingBalance: (json['outstandingBalance'] as num?)?.toDouble() ?? 0.0,
      applicablePlans: rawPlans
          .map((p) => FeePlanModel.fromJson(p as Map<String, dynamic>))
          .toList(),
      paymentHistory: rawHistory
          .map((h) => PaymentReceiptModel.fromJson(h as Map<String, dynamic>))
          .toList(),
    );
  }
}
