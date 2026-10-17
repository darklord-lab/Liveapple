import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class InstituteBrandingModel {
  final String id;
  final String name;
  final String slug;
  final String? code;
  final String? logoUrl;
  final String? primaryColor;
  final String? tagline;
  final String? plan;

  const InstituteBrandingModel({
    this.id = '',
    this.name = '',
    this.slug = '',
    this.code,
    this.logoUrl,
    this.primaryColor,
    this.tagline,
    this.plan,
  });

  /// Default baseline Apex Academy branding
  factory InstituteBrandingModel.defaultBranding() {
    return const InstituteBrandingModel(
      id: 'inst-apex-01',
      name: 'Apex IIT-JEE & Medical Academy',
      slug: 'apex',
      code: 'APEX01',
      primaryColor: '#0A9BE8',
      tagline: 'Premier IIT-JEE & Medical Academy',
      plan: 'ENTERPRISE',
    );
  }

  /// Upper-cased institute code (e.g. "APEX01")
  String get effectiveCode {
    if (code != null && code!.trim().isNotEmpty) {
      return code!.trim().toUpperCase();
    }
    if (id.length >= 6) {
      return id.substring(0, 6).toUpperCase();
    }
    return 'APEX01';
  }

  /// Converted Flutter Color from primaryColor hex
  Color get brandColor {
    if (primaryColor == null || primaryColor!.trim().isEmpty) {
      return AppColors.primary;
    }
    try {
      final hex = primaryColor!.replaceAll('#', '').trim();
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return AppColors.primary;
  }

  /// 1-2 letter monogram initials when logo is not provided
  String get initials {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    if (words.isNotEmpty && words[0].isNotEmpty) {
      return words[0].substring(0, 1).toUpperCase();
    }
    return 'C';
  }

  InstituteBrandingModel copyWith({
    String? id,
    String? name,
    String? slug,
    String? code,
    String? logoUrl,
    String? primaryColor,
    String? tagline,
    String? plan,
  }) {
    return InstituteBrandingModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      code: code ?? this.code,
      logoUrl: logoUrl ?? this.logoUrl,
      primaryColor: primaryColor ?? this.primaryColor,
      tagline: tagline ?? this.tagline,
      plan: plan ?? this.plan,
    );
  }

  factory InstituteBrandingModel.fromJson(Map<String, dynamic> json) {
    return InstituteBrandingModel(
      id: json['id'] as String? ?? 'inst-unknown',
      name: json['name'] as String? ?? 'Classora Academy',
      slug: json['slug'] as String? ?? 'classora',
      code: json['code'] as String?,
      logoUrl: json['logoUrl'] as String?,
      primaryColor: json['primaryColor'] as String? ?? '#0A9BE8',
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

  String serialize() => jsonEncode(toJson());

  static InstituteBrandingModel? deserialize(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return InstituteBrandingModel.fromJson(decoded);
      }
    } catch (_) {}
    return null;
  }
}
