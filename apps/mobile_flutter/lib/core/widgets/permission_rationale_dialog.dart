import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum PermissionType {
  camera,
  microphone,
  notifications,
  storage,
}

class PermissionRationaleDialog extends StatelessWidget {
  final PermissionType type;
  final VoidCallback onContinue;
  final VoidCallback? onCancel;

  const PermissionRationaleDialog({
    super.key,
    required this.type,
    required this.onContinue,
    this.onCancel,
  });

  static Future<bool?> show(
    BuildContext context, {
    required PermissionType type,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => PermissionRationaleDialog(
        type: type,
        onContinue: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
  }

  IconData get _icon {
    switch (type) {
      case PermissionType.camera:
        return Icons.videocam_rounded;
      case PermissionType.microphone:
        return Icons.mic_rounded;
      case PermissionType.notifications:
        return Icons.notifications_active_rounded;
      case PermissionType.storage:
        return Icons.folder_rounded;
    }
  }

  String get _title {
    switch (type) {
      case PermissionType.camera:
        return 'Camera Access Required';
      case PermissionType.microphone:
        return 'Microphone Access Required';
      case PermissionType.notifications:
        return 'Enable Class Notifications';
      case PermissionType.storage:
        return 'Files & Storage Access';
    }
  }

  String get _description {
    switch (type) {
      case PermissionType.camera:
        return 'Classora uses your camera so your teacher and peers can see you when you speak during live classes.';
      case PermissionType.microphone:
        return 'Classora uses your microphone so you can ask doubts and interact during interactive live lectures.';
      case PermissionType.notifications:
        return 'Stay updated when your faculty goes live, class reminders 15 minutes before, and pending assignments.';
      case PermissionType.storage:
        return 'Needed to download and view study notes, assignments, and offline lecture materials.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.skyBlueLight,
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, color: AppColors.skyBlue, size: 28),
            ),
            const SizedBox(height: 18),
            Text(
              _title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMutedLight,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel ?? () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.borderLight),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Not Now', style: TextStyle(color: AppColors.slate500, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.skyBlue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Continue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
