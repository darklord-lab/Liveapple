import 'package:flutter/material.dart';

class MaterialFolderModel {
  final String id;
  final String batchId;
  final String name;
  final String? parentId;
  final DateTime createdAt;
  final int materialsCount;
  final int childrenCount;

  MaterialFolderModel({
    required this.id,
    required this.batchId,
    required this.name,
    this.parentId,
    required this.createdAt,
    this.materialsCount = 0,
    this.childrenCount = 0,
  });

  factory MaterialFolderModel.fromJson(Map<String, dynamic> json) {
    final count = json['_count'] as Map<String, dynamic>?;

    return MaterialFolderModel(
      id: json['id']?.toString() ?? '',
      batchId: json['batchId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Folder',
      parentId: json['parentId']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      materialsCount: (count?['materials'] as num?)?.toInt() ?? 0,
      childrenCount: (count?['children'] as num?)?.toInt() ?? 0,
    );
  }
}

class StudyMaterialModel {
  final String id;
  final String batchId;
  final String? folderId;
  final String title;
  final String? description;
  final String kind; // 'PDF', 'DOC', 'IMAGE', 'VIDEO_LINK', 'LINK'
  final String? fileKey;
  final String? fileName;
  final String? mimeType;
  final String? url;
  final int? sizeBytes;
  final bool isFree;
  final String uploadedById;
  final String? uploadedByName;
  final String? folderName;
  final DateTime createdAt;

  StudyMaterialModel({
    required this.id,
    required this.batchId,
    this.folderId,
    required this.title,
    this.description,
    required this.kind,
    this.fileKey,
    this.fileName,
    this.mimeType,
    this.url,
    this.sizeBytes,
    this.isFree = false,
    required this.uploadedById,
    this.uploadedByName,
    this.folderName,
    required this.createdAt,
  });

  bool get isLink => kind == 'LINK' || kind == 'VIDEO_LINK';
  bool get isVideo => kind == 'VIDEO_LINK';
  bool get isPdf => kind == 'PDF' || (fileName?.toLowerCase().endsWith('.pdf') ?? false);
  bool get isImage => kind == 'IMAGE';
  bool get isDoc => kind == 'DOC';

  String get formattedSize {
    if (sizeBytes == null || sizeBytes! <= 0) return '';
    if (sizeBytes! < 1024) return '$sizeBytes B';
    if (sizeBytes! < 1024 * 1024) return '${(sizeBytes! / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData get iconData {
    if (isVideo) return Icons.play_circle_fill;
    if (isPdf) return Icons.picture_as_pdf;
    if (isImage) return Icons.image;
    if (isLink) return Icons.link;
    return Icons.description;
  }

  Color get iconColor {
    if (isVideo) return Colors.redAccent;
    if (isPdf) return const Color(0xFFDC2626);
    if (isImage) return const Color(0xFF10B981);
    if (isLink) return const Color(0xFF3B82F6);
    return const Color(0xFF6366F1);
  }

  factory StudyMaterialModel.fromJson(Map<String, dynamic> json) {
    final folder = json['folder'] as Map<String, dynamic>?;
    final uploadedBy = json['uploadedBy'] as Map<String, dynamic>?;

    return StudyMaterialModel(
      id: json['id']?.toString() ?? '',
      batchId: json['batchId']?.toString() ?? '',
      folderId: json['folderId']?.toString(),
      title: json['title']?.toString() ?? 'Untitled Material',
      description: json['description']?.toString(),
      kind: json['kind']?.toString() ?? 'DOC',
      fileKey: json['fileKey']?.toString(),
      fileName: json['fileName']?.toString(),
      mimeType: json['mimeType']?.toString(),
      url: json['url']?.toString(),
      sizeBytes: (json['sizeBytes'] as num?)?.toInt(),
      isFree: json['isFree'] == true,
      uploadedById: json['uploadedById']?.toString() ?? '',
      uploadedByName: uploadedBy?['name']?.toString(),
      folderName: folder?['name']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class StudyMaterialListResult {
  final bool isEnrolled;
  final List<StudyMaterialModel> materials;

  StudyMaterialListResult({
    required this.isEnrolled,
    required this.materials,
  });

  factory StudyMaterialListResult.fromJson(Map<String, dynamic> json) {
    final list = json['materials'] as List<dynamic>? ?? [];
    return StudyMaterialListResult(
      isEnrolled: json['isEnrolled'] == true,
      materials: list
          .map((item) => StudyMaterialModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
