import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/storage/secure_storage.dart';
import 'auth_controller.dart';
import '../domain/auth_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  // Default to empty for production security; demo chips available in debug/demo builds
  final _emailController = TextEditingController(
    text: (kDebugMode || const bool.fromEnvironment('DEMO_MODE', defaultValue: false))
        ? 'teacher1@apex.edu'
        : '',
  );
  final _passwordController = TextEditingController(
    text: (kDebugMode || const bool.fromEnvironment('DEMO_MODE', defaultValue: false))
        ? 'Password@123'
        : '',
  );
  bool _obscurePassword = true;
  int _logoTapCount = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authStateProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }

  void _quickFill(String email, String password) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = password;
    });
  }

  void _showServerConfigModal() async {
    final storage = SecureStorageService();
    final currentUrl = await storage.getBaseUrl() ?? Endpoints.defaultBaseUrl;
    final urlController = TextEditingController(text: currentUrl);
    String testStatus = '';
    bool isTesting = false;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.dns_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Server Connection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select a server preset or enter backend URL:',
                  style: TextStyle(fontSize: 12, color: AppColors.textMutedLight),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.cloud_done, size: 16, color: AppColors.primary),
                      label: const Text('Cloudflare (Live)', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        setModalState(() {
                          urlController.text = Endpoints.cloudflareTunnelUrl;
                          testStatus = '';
                        });
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.wifi, size: 16, color: AppColors.success),
                      label: const Text('Wi-Fi PC', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        setModalState(() {
                          urlController.text = Endpoints.localWifiUrl;
                          testStatus = '';
                        });
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.android, size: 16, color: AppColors.warning),
                      label: const Text('Emulator', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        setModalState(() {
                          urlController.text = Endpoints.emulatorUrl;
                          testStatus = '';
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: urlController,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'API Base URL',
                    hintText: 'https://....trycloudflare.com/api',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: isTesting
                          ? null
                          : () async {
                              setModalState(() {
                                isTesting = true;
                                testStatus = 'Testing connection...';
                              });
                              try {
                                String testUrl = urlController.text.trim();
                                if (!testUrl.endsWith('/health')) {
                                  testUrl = testUrl.endsWith('/')
                                      ? '${testUrl}health'
                                      : '$testUrl/health';
                                }
                                final dio = Dio(
                                  BaseOptions(
                                    connectTimeout: const Duration(seconds: 8),
                                    receiveTimeout: const Duration(seconds: 8),
                                  ),
                                );
                                final res = await dio.get(testUrl);
                                setModalState(() {
                                  isTesting = false;
                                  if (res.statusCode == 200) {
                                    testStatus = '✅ Connected! Server online.';
                                  } else {
                                    testStatus = '⚠️ Status code: ${res.statusCode}';
                                  }
                                });
                              } catch (e) {
                                setModalState(() {
                                  isTesting = false;
                                  testStatus = '❌ Could not connect.';
                                });
                              }
                            },
                      icon: isTesting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.network_check, size: 16),
                      label: const Text('Test Connection', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
                if (testStatus.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    testStatus,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: testStatus.startsWith('✅') ? AppColors.success : AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMutedLight)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              onPressed: () async {
                final newUrl = urlController.text.trim();
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(dialogCtx);
                await storage.saveBaseUrl(newUrl);
                nav.pop();
                messenger.showSnackBar(
                  SnackBar(content: Text('Updated Base URL to: $newUrl')),
                );
              },
              child: const Text('Save & Use'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: AppColors.textMutedLight),
              tooltip: 'Server Settings (Debug Only)',
              onPressed: _showServerConfigModal,
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo Emblem with Secret 5-tap for QA settings
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        _logoTapCount++;
                        if (_logoTapCount >= 5) {
                          _logoTapCount = 0;
                          _showServerConfigModal();
                        }
                      },
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.accent, AppColors.primary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'C',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Brand Heading
                  Text(
                    'Classora 2.0',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: isDark ? AppColors.textDark : AppColors.textLight,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Sign in to access your institute live classroom & study portal',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMutedLight,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error Banner
                  if (authState.status == AuthStatus.error && authState.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppColors.liveRedLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.liveRed.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.liveRed, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              authState.errorMessage!,
                              style: const TextStyle(
                                color: AppColors.liveRed,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Main Form Card (Light-first Card with radius 12, soft shadow)
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                      boxShadow: [
                        if (!isDark)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Account Credentials',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textDark : AppColors.textLight,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Email field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              hintText: 'name@institute.edu',
                              prefixIcon: const Icon(Icons.mail_outline, size: 20),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF0F172A) : AppColors.backgroundLight,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Email is required';
                              if (!val.contains('@')) return 'Enter a valid email address';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter account password',
                              prefixIcon: const Icon(Icons.lock_outline, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF0F172A) : AppColors.backgroundLight,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Password is required';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Sign In CTA Button (min touch target 48 dp per DESIGN.md Section 1)
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 1,
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Sign In',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Accept Invite / Batch Code Outlined Button
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/accept-invite'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary, width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.school_outlined, size: 18),
                      label: const Text(
                        'Have an Invite or Batch Code? Join Here',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Demo Quick-Fill Accounts (Clean isolated card for QA in debug/demo builds)
                  if (kDebugMode || const bool.fromEnvironment('DEMO_MODE', defaultValue: false))
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.developer_mode, size: 14, color: AppColors.accent),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'QUICK LOGIN (DEBUG & QA TEST ONLY)',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: AppColors.textMutedLight,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ActionChip(
                                label: const Text('Admin', style: TextStyle(fontSize: 12)),
                                avatar: const Icon(Icons.admin_panel_settings, size: 14, color: AppColors.primary),
                                backgroundColor: isDark ? const Color(0xFF0F172A) : AppColors.backgroundLight,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                onPressed: () => _quickFill('admin@apex.edu', 'Password@123'),
                              ),
                              ActionChip(
                                label: const Text('Teacher 1', style: TextStyle(fontSize: 12)),
                                avatar: const Icon(Icons.school, size: 14, color: AppColors.accent),
                                backgroundColor: isDark ? const Color(0xFF0F172A) : AppColors.backgroundLight,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                onPressed: () => _quickFill('teacher1@apex.edu', 'Password@123'),
                              ),
                              ActionChip(
                                label: const Text('Student 1', style: TextStyle(fontSize: 12)),
                                avatar: const Icon(Icons.person, size: 14, color: AppColors.success),
                                backgroundColor: isDark ? const Color(0xFF0F172A) : AppColors.backgroundLight,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                onPressed: () => _quickFill('student1@apex.edu', 'Password@123'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
