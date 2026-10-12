import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/domain/user_model.dart';
import '../../../core/network/endpoints.dart';

class AdminHomeScreen extends ConsumerWidget {
  final UserModel user;

  const AdminHomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseUrl = Endpoints.defaultBaseUrl;
    final adminWebUrl = baseUrl.contains('/api')
        ? baseUrl.replaceAll('/api', '/admin')
        : '$baseUrl/admin';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.skyBlue,
        elevation: 0,
        title: Text(
          user.institute?.name ?? 'Classora Admin Console',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Sign Out',
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppColors.skyBlueLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.laptop_mac_rounded, size: 64, color: AppColors.skyBlue),
              ),
              const SizedBox(height: 24),
              const Text(
                'Admin Console is on Web',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Institute administration, teacher onboarding, billing, and system configurations are accessible exclusively through the Classora Web Admin Console.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.slate500, height: 1.4),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  children: [
                    const Text('Admin Web Link', style: TextStyle(fontSize: 12, color: AppColors.slate400, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    SelectableText(
                      adminWebUrl,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.skyBlue),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: adminWebUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Admin web portal link copied to clipboard!')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy Web Link'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.skyBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: () => ref.read(authStateProvider.notifier).logout(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.liveRed,
                  side: const BorderSide(color: AppColors.liveRed),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Sign Out / Switch Account', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
