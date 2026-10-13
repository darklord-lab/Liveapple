import 'package:flutter/material.dart';

/// Domain model representing a verified test score share card.
class TestShareModel {
  final String attemptId;
  final String testId;
  final String testTitle;
  final int durationMin;
  final String? batchName;
  final String? subject;
  final String studentName;
  final int score;
  final int totalMarks;
  final int percentage;
  final String status;
  final DateTime? submittedAt;
  final String instituteName;
  final String instituteCode;
  final String? instituteLogoUrl;
  final String primaryColorHex;
  final String? tagline;
  final String deepLink;
  final String webLink;

  const TestShareModel({
    required this.attemptId,
    required this.testId,
    required this.testTitle,
    required this.durationMin,
    this.batchName,
    this.subject,
    required this.studentName,
    required this.score,
    required this.totalMarks,
    required this.percentage,
    required this.status,
    this.submittedAt,
    required this.instituteName,
    required this.instituteCode,
    this.instituteLogoUrl,
    this.primaryColorHex = '#0A9BE8',
    this.tagline,
    required this.deepLink,
    required this.webLink,
  });

  Color get primaryColor {
    try {
      final hex = primaryColorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF0A9BE8);
    }
  }

  String get grade {
    if (percentage >= 90) return 'A+ Outstanding';
    if (percentage >= 80) return 'A Excellent';
    if (percentage >= 70) return 'B+ Very Good';
    if (percentage >= 60) return 'B Good';
    if (percentage >= 50) return 'C Pass';
    return 'Needs Improvement';
  }

  Color get gradeColor {
    if (percentage >= 80) return const Color(0xFF10B981); // Emerald
    if (percentage >= 60) return const Color(0xFF0A9BE8); // Sky blue
    if (percentage >= 50) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFFEF4444); // Red
  }

  String formatShareText() {
    final buffer = StringBuffer();
    buffer.writeln('🏆 Classora Verified Score Card');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('🏛 Institute: $instituteName (Code: $instituteCode)');
    buffer.writeln('👤 Student: $studentName');
    buffer.writeln('📝 Test: $testTitle');
    if (batchName != null && batchName!.isNotEmpty) {
      buffer.writeln('📚 Batch: $batchName');
    }
    buffer.writeln('🎯 Score: $score / $totalMarks ($percentage%)');
    buffer.writeln('🏅 Grade: $grade');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('🔗 View online: $webLink');
    buffer.writeln('📱 Open in Classora app: $deepLink');
    return buffer.toString();
  }

  factory TestShareModel.fromJson(Map<String, dynamic> json) {
    final inst = json['institute'] as Map<String, dynamic>? ?? {};

    return TestShareModel(
      attemptId: json['attemptId']?.toString() ?? '',
      testId: json['testId']?.toString() ?? '',
      testTitle: json['testTitle']?.toString() ?? 'CBT Test',
      durationMin: (json['durationMin'] as num?)?.toInt() ?? 30,
      batchName: json['batchName']?.toString(),
      subject: json['subject']?.toString(),
      studentName: json['studentName']?.toString() ?? 'Student',
      score: (json['score'] as num?)?.toInt() ?? 0,
      totalMarks: (json['totalMarks'] as num?)?.toInt() ?? 100,
      percentage: (json['percentage'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'EVALUATED',
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'].toString())
          : null,
      instituteName: inst['name']?.toString() ?? 'Institute',
      instituteCode: inst['code']?.toString() ?? 'APEX01',
      instituteLogoUrl: inst['logoUrl']?.toString(),
      primaryColorHex: inst['primaryColor']?.toString() ?? '#0A9BE8',
      tagline: inst['tagline']?.toString(),
      deepLink: json['deepLink']?.toString() ??
          'classora://test-result?attemptId=${json['attemptId']}&code=${inst['code'] ?? 'APEX01'}',
      webLink: json['webLink']?.toString() ??
          'https://classora.app/test-result?attemptId=${json['attemptId']}&code=${inst['code'] ?? 'APEX01'}',
    );
  }
}
