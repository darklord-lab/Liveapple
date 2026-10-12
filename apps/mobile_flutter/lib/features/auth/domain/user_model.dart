class UserModel {
  final String id;
  final String instituteId;
  final String role; // "ADMIN" | "TEACHER" | "STUDENT"
  final String name;
  final String email;
  final String? phone;
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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      instituteId: json['instituteId'] as String,
      role: (json['role'] as String).toUpperCase(),
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
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
}

class InstituteModel {
  final String id;
  final String name;
  final String slug;
  final String? plan;

  const InstituteModel({
    required this.id,
    required this.name,
    required this.slug,
    this.plan,
  });

  factory InstituteModel.fromJson(Map<String, dynamic> json) {
    return InstituteModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      plan: json['plan'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
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
