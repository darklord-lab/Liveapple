import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum ClassStatus { live, upcoming, ended }

class StatusPill extends StatelessWidget {
  final ClassStatus status;
  final String? customText;

  const StatusPill({
    super.key,
    required this.status,
    this.customText,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case ClassStatus.live:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.liveRed,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.fiber_manual_record, color: Colors.white, size: 8),
              const SizedBox(width: 4),
              Text(
                customText ?? 'LIVE NOW',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );

      case ClassStatus.upcoming:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.skyBlueLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.skyBlue.withValues(alpha: 0.3)),
          ),
          child: Text(
            customText ?? 'UPCOMING',
            style: const TextStyle(
              color: AppColors.skyBlue,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        );

      case ClassStatus.ended:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.slate100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Text(
            customText ?? 'COMPLETED',
            style: const TextStyle(
              color: AppColors.slate500,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        );
    }
  }
}
