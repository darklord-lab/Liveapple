import 'package:flutter/material.dart';

class InstituteLinkModel {
  final String id;
  final String instituteId;
  final String title;
  final String platform; // "YOUTUBE" | "TELEGRAM" | "WHATSAPP" | "INSTAGRAM" | "WEBSITE" | "OTHER"
  final String url;
  final String? icon;
  final int order;
  final bool isActive;
  final DateTime? createdAt;

  const InstituteLinkModel({
    required this.id,
    required this.instituteId,
    required this.title,
    required this.platform,
    required this.url,
    this.icon,
    this.order = 0,
    this.isActive = true,
    this.createdAt,
  });

  factory InstituteLinkModel.fromJson(Map<String, dynamic> json) {
    return InstituteLinkModel(
      id: json['id'] as String,
      instituteId: json['instituteId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      platform: (json['platform'] as String? ?? 'OTHER').toUpperCase(),
      url: json['url'] as String? ?? '',
      icon: json['icon'] as String?,
      order: json['order'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'instituteId': instituteId,
      'title': title,
      'platform': platform,
      'url': url,
      'icon': icon,
      'order': order,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  IconData get iconData {
    switch (platform) {
      case 'YOUTUBE':
        return Icons.play_circle_filled_rounded;
      case 'TELEGRAM':
        return Icons.send_rounded;
      case 'WHATSAPP':
        return Icons.chat_rounded;
      case 'INSTAGRAM':
        return Icons.camera_alt_rounded;
      case 'WEBSITE':
        return Icons.language_rounded;
      default:
        return Icons.link_rounded;
    }
  }

  Color get brandColor {
    switch (platform) {
      case 'YOUTUBE':
        return const Color(0xFFDC2626); // YouTube Red
      case 'TELEGRAM':
        return const Color(0xFF0284C7); // Telegram Blue
      case 'WHATSAPP':
        return const Color(0xFF16A34A); // WhatsApp Green
      case 'INSTAGRAM':
        return const Color(0xFFE11D48); // Instagram Rose
      case 'WEBSITE':
        return const Color(0xFF0A9BE8); // Classora Sky Blue
      default:
        return const Color(0xFF4F46E5); // Indigo
    }
  }

  String get platformDisplay {
    switch (platform) {
      case 'YOUTUBE':
        return 'YouTube';
      case 'TELEGRAM':
        return 'Telegram';
      case 'WHATSAPP':
        return 'WhatsApp';
      case 'INSTAGRAM':
        return 'Instagram';
      case 'WEBSITE':
        return 'Website';
      default:
        return 'Link';
    }
  }

  InstituteLinkModel copyWith({
    String? id,
    String? instituteId,
    String? title,
    String? platform,
    String? url,
    String? icon,
    int? order,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return InstituteLinkModel(
      id: id ?? this.id,
      instituteId: instituteId ?? this.instituteId,
      title: title ?? this.title,
      platform: platform ?? this.platform,
      url: url ?? this.url,
      icon: icon ?? this.icon,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
