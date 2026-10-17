import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class UserModel {
  final String id;
  final String instituteId;
  final String role; // "ADMIN" | "TEACHER" | "STUDENT"
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String? notificationPrefs;
  final String status;
  final InstituteModel? institute;
  final TeacherProfileModel? teacher;
  final String? coachingName;
  final String? centreLogo;
  final String? centreAddress;
  final String? contactPhone;
  final String? bio;
  final String? subjects;

  const UserModel({
    required this.id,
    required this.instituteId,
    required this.role,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.notificationPrefs,
    required this.status,
    this.institute,
    this.teacher,
    this.coachingName,
    this.centreLogo,
    this.centreAddress,
    this.contactPhone,
    this.bio,
    this.subjects,
  });

  bool get isAdmin => role == 'ADMIN';
  bool get isTeacher => role == 'TEACHER';
  bool get isStudent => role == 'STUDENT';

  /// Effective coaching centre brand name
  String get effectiveCoachingName =>
      teacher?.coachingName ?? coachingName ?? institute?.name ?? 'Apex Academy';

  /// Effective faculty member / instructor name
  String get effectiveFacultyName =>
      teacher?.name ?? (isTeacher ? name : 'Classora Faculty');

  /// Effective primary brand color
  Color get brandColor => institute?.brandColor ?? AppColors.primary;

  /// Effective institute code
  String get effectiveInstituteCode => institute?.effectiveCode ?? 'APEX01';

  /// Parse notification preferences map safely
  Map<String, dynamic> get parsedNotificationPrefs {
    if (notificationPrefs == null || notificationPrefs!.isEmpty) {
      return {'reminders': true, 'liveAlerts': true, 'homework': true, 'testAlerts': true};
    }
    try {
      final decoded = jsonDecode(notificationPrefs!);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'reminders': true, 'liveAlerts': true, 'homework': true, 'testAlerts': true};
    } catch (_) {
      return {'reminders': true, 'liveAlerts': true, 'homework': true, 'testAlerts': true};
    }
  }

  bool get remindersEnabled => parsedNotificationPrefs['reminders'] as bool? ?? true;
  bool get liveAlertsEnabled => parsedNotificationPrefs['liveAlerts'] as bool? ?? true;
  bool get homeworkEnabled => parsedNotificationPrefs['homework'] as bool? ?? true;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      instituteId: json['instituteId'] as String,
      role: (json['role'] as String).toUpperCase(),
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      notificationPrefs: json['notificationPrefs'] is Map
          ? jsonEncode(json['notificationPrefs'])
          : json['notificationPrefs'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      institute: json['institute'] != null
          ? InstituteModel.fromJson(json['institute'] as Map<String, dynamic>)
          : null,
      teacher: json['teacher'] != null
          ? TeacherProfileModel.fromJson(json['teacher'] as Map<String, dynamic>)
          : null,
      coachingName: json['coachingName'] as String?,
      centreLogo: json['centreLogo'] as String?,
      centreAddress: json['centreAddress'] as String?,
      contactPhone: json['contactPhone'] as String?,
      bio: json['bio'] as String?,
      subjects: json['subjects'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'instituteId': instituteId,
      'role': role,
      'name': name,
      'email': email,
      if (phone != null) 'phone': phone,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (notificationPrefs != null) 'notificationPrefs': notificationPrefs,
      'status': status,
      if (institute != null) 'institute': institute!.toJson(),
      if (teacher != null) 'teacher': teacher!.toJson(),
      if (coachingName != null) 'coachingName': coachingName,
      if (centreLogo != null) 'centreLogo': centreLogo,
      if (centreAddress != null) 'centreAddress': centreAddress,
      if (contactPhone != null) 'contactPhone': contactPhone,
      if (bio != null) 'bio': bio,
      if (subjects != null) 'subjects': subjects,
    };
  }

  UserModel copyWith({
    String? id,
    String? instituteId,
    String? role,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? notificationPrefs,
    String? status,
    InstituteModel? institute,
    TeacherProfileModel? teacher,
    String? coachingName,
    String? centreLogo,
    String? centreAddress,
    String? contactPhone,
    String? bio,
    String? subjects,
  }) {
    return UserModel(
      id: id ?? this.id,
      instituteId: instituteId ?? this.instituteId,
      role: role ?? this.role,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      notificationPrefs: notificationPrefs ?? this.notificationPrefs,
      status: status ?? this.status,
      institute: institute ?? this.institute,
      teacher: teacher ?? this.teacher,
      coachingName: coachingName ?? this.coachingName,
      centreLogo: centreLogo ?? this.centreLogo,
      centreAddress: centreAddress ?? this.centreAddress,
      contactPhone: contactPhone ?? this.contactPhone,
      bio: bio ?? this.bio,
      subjects: subjects ?? this.subjects,
    );
  }
}

class InstituteModel {
  final String id;
  final String name;
  final String slug;
  final String? code;
  final String? logoUrl;
  final String? primaryColor;
  final String? tagline;
  final String? plan;

  const InstituteModel({
    required this.id,
    required this.name,
    required this.slug,
    this.code,
    this.logoUrl,
    this.primaryColor,
    this.tagline,
    this.plan,
  });

  String get effectiveCode =>
      (code != null && code!.isNotEmpty)
          ? code!.toUpperCase()
          : (id.length >= 6 ? id.substring(0, 6).toUpperCase() : 'APEX01');

  Color get brandColor {
    if (primaryColor == null || primaryColor!.isEmpty) return AppColors.primary;
    try {
      final hex = primaryColor!.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return AppColors.primary;
  }

  String get initials {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'C';
  }

  factory InstituteModel.fromJson(Map<String, dynamic> json) {
    return InstituteModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      code: json['code'] as String?,
      logoUrl: json['logoUrl'] as String?,
      primaryColor: json['primaryColor'] as String?,
      tagline: json['tagline'] as String?,
      plan: json['plan'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      if (code != null) 'code': code,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (primaryColor != null) 'primaryColor': primaryColor,
      if (tagline != null) 'tagline': tagline,
      if (plan != null) 'plan': plan,
    };
  }
}

class TeacherProfileModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? coachingName;
  final String? centreLogo;
  final String? centreAddress;
  final String? contactPhone;
  final String? bio;
  final String? subjects;

  const TeacherProfileModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.coachingName,
    this.centreLogo,
    this.centreAddress,
    this.contactPhone,
    this.bio,
    this.subjects,
  });

  factory TeacherProfileModel.fromJson(Map<String, dynamic> json) {
    return TeacherProfileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      coachingName: json['coachingName'] as String?,
      centreLogo: json['centreLogo'] as String?,
      centreAddress: json['centreAddress'] as String?,
      contactPhone: json['contactPhone'] as String?,
      bio: json['bio'] as String?,
      subjects: json['subjects'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      if (phone != null) 'phone': phone,
      if (coachingName != null) 'coachingName': coachingName,
      if (centreLogo != null) 'centreLogo': centreLogo,
      if (centreAddress != null) 'centreAddress': centreAddress,
      if (contactPhone != null) 'contactPhone': contactPhone,
      if (bio != null) 'bio': bio,
      if (subjects != null) 'subjects': subjects,
    };
  }
}
