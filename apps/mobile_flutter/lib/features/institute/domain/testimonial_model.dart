class TestimonialModel {
  final String id;
  final String instituteId;
  final String studentName;
  final String? batchOrExam;
  final String quote;
  final String? avatarUrl;
  final int rating; // 1 to 5
  final int order;
  final bool isPublished;
  final DateTime? createdAt;

  const TestimonialModel({
    required this.id,
    required this.instituteId,
    required this.studentName,
    this.batchOrExam,
    required this.quote,
    this.avatarUrl,
    this.rating = 5,
    this.order = 0,
    this.isPublished = true,
    this.createdAt,
  });

  factory TestimonialModel.fromJson(Map<String, dynamic> json) {
    return TestimonialModel(
      id: json['id'] as String,
      instituteId: json['instituteId'] as String? ?? '',
      studentName: json['studentName'] as String? ?? '',
      batchOrExam: json['batchOrExam'] as String?,
      quote: json['quote'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      rating: json['rating'] as int? ?? 5,
      order: json['order'] as int? ?? 0,
      isPublished: json['isPublished'] as bool? ?? true,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'instituteId': instituteId,
      'studentName': studentName,
      'batchOrExam': batchOrExam,
      'quote': quote,
      'avatarUrl': avatarUrl,
      'rating': rating,
      'order': order,
      'isPublished': isPublished,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  String get initials {
    if (studentName.trim().isEmpty) return '?';
    final parts = studentName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  TestimonialModel copyWith({
    String? id,
    String? instituteId,
    String? studentName,
    String? batchOrExam,
    String? quote,
    String? avatarUrl,
    int? rating,
    int? order,
    bool? isPublished,
    DateTime? createdAt,
  }) {
    return TestimonialModel(
      id: id ?? this.id,
      instituteId: instituteId ?? this.instituteId,
      studentName: studentName ?? this.studentName,
      batchOrExam: batchOrExam ?? this.batchOrExam,
      quote: quote ?? this.quote,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rating: rating ?? this.rating,
      order: order ?? this.order,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
