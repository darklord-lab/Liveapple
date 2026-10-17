class CourseOfferingModel {
  final String id;
  final String batchId;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final double price;
  final double mrp;
  final int discountPercent;
  final bool isFeatured;
  final bool isPublished;
  final bool isPurchased;
  final int totalEnrolled;
  final String? batchName;
  final String? batchSubject;
  final String? teacherName;
  final DateTime createdAt;

  const CourseOfferingModel({
    required this.id,
    required this.batchId,
    required this.title,
    this.description,
    this.thumbnailUrl,
    required this.price,
    required this.mrp,
    this.discountPercent = 0,
    this.isFeatured = false,
    this.isPublished = true,
    this.isPurchased = false,
    this.totalEnrolled = 0,
    this.batchName,
    this.batchSubject,
    this.teacherName,
    required this.createdAt,
  });

  bool get hasDiscount => mrp > price;

  factory CourseOfferingModel.fromJson(Map<String, dynamic> json) {
    final batchMap = json['batch'] is Map<String, dynamic>
        ? json['batch'] as Map<String, dynamic>
        : (json['batch'] is Map ? Map<String, dynamic>.from(json['batch'] as Map) : null);

    final teacherMap = batchMap?['teacher'] is Map<String, dynamic>
        ? batchMap!['teacher'] as Map<String, dynamic>
        : (batchMap?['teacher'] is Map ? Map<String, dynamic>.from(batchMap!['teacher'] as Map) : null);

    final priceVal = (json['price'] as num?)?.toDouble() ?? 0.0;
    final mrpVal = (json['mrp'] as num?)?.toDouble() ?? priceVal;
    final discountVal = (json['discountPercent'] as num?)?.toInt() ??
        (mrpVal > 0 ? (((mrpVal - priceVal) / mrpVal) * 100).round() : 0);

    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    return CourseOfferingModel(
      id: json['id']?.toString() ?? '',
      batchId: json['batchId']?.toString() ?? batchMap?['id']?.toString() ?? '',
      title: json['title']?.toString() ?? batchMap?['name']?.toString() ?? 'Course Offering',
      description: json['description']?.toString(),
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      price: priceVal,
      mrp: mrpVal,
      discountPercent: discountVal,
      isFeatured: json['isFeatured'] == true,
      isPublished: json['isPublished'] != false,
      isPurchased: json['isPurchased'] == true,
      totalEnrolled: (json['totalEnrolled'] as num?)?.toInt() ??
          (json['_count'] is Map ? (json['_count']['purchases'] as num?)?.toInt() ?? 0 : 0),
      batchName: batchMap?['name']?.toString(),
      batchSubject: batchMap?['subject']?.toString(),
      teacherName: teacherMap?['name']?.toString(),
      createdAt: parseDate(json['createdAt']),
    );
  }

  CourseOfferingModel copyWith({
    String? id,
    String? batchId,
    String? title,
    String? description,
    String? thumbnailUrl,
    double? price,
    double? mrp,
    int? discountPercent,
    bool? isFeatured,
    bool? isPublished,
    bool? isPurchased,
    int? totalEnrolled,
    String? batchName,
    String? batchSubject,
    String? teacherName,
    DateTime? createdAt,
  }) {
    return CourseOfferingModel(
      id: id ?? this.id,
      batchId: batchId ?? this.batchId,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      price: price ?? this.price,
      mrp: mrp ?? this.mrp,
      discountPercent: discountPercent ?? this.discountPercent,
      isFeatured: isFeatured ?? this.isFeatured,
      isPublished: isPublished ?? this.isPublished,
      isPurchased: isPurchased ?? this.isPurchased,
      totalEnrolled: totalEnrolled ?? this.totalEnrolled,
      batchName: batchName ?? this.batchName,
      batchSubject: batchSubject ?? this.batchSubject,
      teacherName: teacherName ?? this.teacherName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class CouponValidationResult {
  final bool valid;
  final String couponId;
  final String code;
  final String discountType; // "PERCENT" | "FLAT"
  final double discountValue;
  final double originalPrice;
  final double discountAmount;
  final double finalAmount;

  const CouponValidationResult({
    required this.valid,
    required this.couponId,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.originalPrice,
    required this.discountAmount,
    required this.finalAmount,
  });

  factory CouponValidationResult.fromJson(Map<String, dynamic> json) {
    final coupon = json['coupon'] is Map<String, dynamic>
        ? json['coupon'] as Map<String, dynamic>
        : (json['coupon'] is Map ? Map<String, dynamic>.from(json['coupon'] as Map) : <String, dynamic>{});

    return CouponValidationResult(
      valid: json['valid'] == true,
      couponId: coupon['id']?.toString() ?? '',
      code: coupon['code']?.toString() ?? '',
      discountType: coupon['discountType']?.toString() ?? 'PERCENT',
      discountValue: (coupon['discountValue'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (json['originalPrice'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      finalAmount: (json['finalAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PurchaseModel {
  final String id;
  final String offeringId;
  final String studentId;
  final double amount;
  final double discount;
  final String? couponCode;
  final String paymentMethod;
  final String transactionId;
  final String status; // "SUCCESS" | "REFUNDED" | "PENDING"
  final String invoiceNo;
  final DateTime purchasedAt;
  final String? courseTitle;
  final String? batchName;

  const PurchaseModel({
    required this.id,
    required this.offeringId,
    required this.studentId,
    required this.amount,
    this.discount = 0.0,
    this.couponCode,
    required this.paymentMethod,
    required this.transactionId,
    required this.status,
    required this.invoiceNo,
    required this.purchasedAt,
    this.courseTitle,
    this.batchName,
  });

  bool get isSuccess => status == 'SUCCESS';
  bool get isRefunded => status == 'REFUNDED';

  factory PurchaseModel.fromJson(Map<String, dynamic> json) {
    final offeringMap = json['offering'] is Map<String, dynamic>
        ? json['offering'] as Map<String, dynamic>
        : (json['offering'] is Map ? Map<String, dynamic>.from(json['offering'] as Map) : null);

    final batchMap = offeringMap?['batch'] is Map<String, dynamic>
        ? offeringMap!['batch'] as Map<String, dynamic>
        : (offeringMap?['batch'] is Map ? Map<String, dynamic>.from(offeringMap!['batch'] as Map) : null);

    final couponMap = json['coupon'] is Map<String, dynamic>
        ? json['coupon'] as Map<String, dynamic>
        : (json['coupon'] is Map ? Map<String, dynamic>.from(json['coupon'] as Map) : null);

    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    return PurchaseModel(
      id: json['id']?.toString() ?? '',
      offeringId: json['offeringId']?.toString() ?? offeringMap?['id']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      couponCode: couponMap?['code']?.toString() ?? json['couponCode']?.toString(),
      paymentMethod: json['paymentMethod']?.toString() ?? 'RAZORPAY',
      transactionId: json['transactionId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'SUCCESS',
      invoiceNo: json['invoiceNo']?.toString() ?? '',
      purchasedAt: parseDate(json['purchasedAt'] ?? json['createdAt']),
      courseTitle: offeringMap?['title']?.toString() ?? json['title']?.toString(),
      batchName: batchMap?['name']?.toString() ?? json['batchName']?.toString(),
    );
  }
}

class InvoiceModel {
  final String invoiceNo;
  final String transactionId;
  final String status;
  final DateTime purchasedAt;
  final String paymentMethod;
  final String instituteName;
  final String? instituteCode;
  final String studentName;
  final String studentEmail;
  final String courseTitle;
  final String batchName;
  final String subject;
  final double mrp;
  final double basePrice;
  final String? couponCode;
  final double discount;
  final double netPaid;
  final String currency;

  const InvoiceModel({
    required this.invoiceNo,
    required this.transactionId,
    required this.status,
    required this.purchasedAt,
    required this.paymentMethod,
    required this.instituteName,
    this.instituteCode,
    required this.studentName,
    required this.studentEmail,
    required this.courseTitle,
    required this.batchName,
    required this.subject,
    required this.mrp,
    required this.basePrice,
    this.couponCode,
    required this.discount,
    required this.netPaid,
    this.currency = 'INR',
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    final inst = json['institute'] is Map ? json['institute'] as Map : {};
    final student = json['student'] is Map ? json['student'] as Map : {};
    final course = json['course'] is Map ? json['course'] as Map : {};
    final pricing = json['pricing'] is Map ? json['pricing'] as Map : {};

    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    return InvoiceModel(
      invoiceNo: json['invoiceNo']?.toString() ?? '',
      transactionId: json['transactionId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'SUCCESS',
      purchasedAt: parseDate(json['purchasedAt']),
      paymentMethod: json['paymentMethod']?.toString() ?? 'RAZORPAY',
      instituteName: inst['name']?.toString() ?? 'Classora Academy',
      instituteCode: inst['code']?.toString(),
      studentName: student['name']?.toString() ?? 'Student',
      studentEmail: student['email']?.toString() ?? '',
      courseTitle: course['title']?.toString() ?? 'Course Package',
      batchName: course['batchName']?.toString() ?? 'Batch',
      subject: course['subject']?.toString() ?? '',
      mrp: (pricing['mrp'] as num?)?.toDouble() ?? 0.0,
      basePrice: (pricing['basePrice'] as num?)?.toDouble() ?? 0.0,
      couponCode: pricing['couponCode']?.toString(),
      discount: (pricing['discount'] as num?)?.toDouble() ?? 0.0,
      netPaid: (pricing['netPaid'] as num?)?.toDouble() ?? 0.0,
      currency: pricing['currency']?.toString() ?? 'INR',
    );
  }
}
