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
  final _emailController = TextEditingController(text: 'teacher1@apex.edu');
  final _passwordController = TextEditingController(text: 'Password@123');
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
          title: const Row(
            children: [
              Icon(Icons.dns_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Server Connection'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select a server preset or enter your backend URL:',
                  style: TextStyle(fontSize: 12, color: AppColors.textMutedLight),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.cloud_done, size: 16, color: Colors.blue),
                      label: const Text('Cloudflare (Live)', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        setModalState(() {
                          urlController.text = Endpoints.cloudflareTunnelUrl;
                          testStatus = '';
                        });
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.wifi, size: 16, color: Colors.green),
                      label: const Text('Wi-Fi PC', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        setModalState(() {
                          urlController.text = Endpoints.localWifiUrl;
                          testStatus = '';
                        });
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.android, size: 16, color: Colors.orange),
                      label: const Text('Emulator', style: TextStyle(fontSize: 12)),
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
                  decoration: const InputDecoration(
                    labelText: 'API Base URL',
                    hintText: 'https://....trycloudflare.com/api',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
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
                                    testStatus = '✅ Connected! Server is online.';
                                  } else {
                                    testStatus = '⚠️ Server responded with code ${res.statusCode}';
                                  }
                                });
                              } catch (e) {
                                setModalState(() {
                                  isTesting = false;
                                  testStatus = '❌ Could not connect to this URL.';
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
                      label: const Text('Test Connection', style: TextStyle(fontSize: 12)),
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
                      color: testStatus.startsWith('✅') ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Server Settings (Debug Only)',
              onPressed: _showServerConfigModal,
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo & Heading
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        // Secret 5-tap developer backdoor for QA/testing without exposing UI to clients
                        _logoTapCount++;
                        if (_logoTapCount >= 5) {
                          _logoTapCount = 0;
                          _showServerConfigModal();
                        }
                      },
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'C',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Welcome to Classora',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textDark : AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Sign in to access your institute portal',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textMutedLight,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Error Banner
                  if (authState.status == AuthStatus.error && authState.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppColors.liveRedLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.liveRed.withOpacity(0.3)),
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

                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(Icons.mail_outline),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Email is required';
                            if (!val.contains('@')) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Password is required';
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Login Button
                        ElevatedButton(
                          onPressed: isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
                              : const Text('Sign In', style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Accept Invite CTA
                  OutlinedButton.icon(
                    onPressed: () => context.push('/accept-invite'),
                    icon: const Icon(Icons.card_giftcard_outlined, size: 18),
                    label: const Text('Have an invite code? Accept Invite'),
                  ),

                  const SizedBox(height: 32),

                  // Quick Demo Login Pills (show only in debug mode or when DEMO_MODE build flag is on)
                  if (kDebugMode || const bool.fromEnvironment('DEMO_MODE', defaultValue: false))
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : AppColors.slate100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DEMO ACCOUNTS (PASSWORD: Password@123)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: AppColors.textMutedLight,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ActionChip(
                                label: const Text('Admin'),
                                avatar: const Icon(Icons.admin_panel_settings, size: 16),
                                onPressed: () => _quickFill('admin@apex.edu', 'Password@123'),
                              ),
                              ActionChip(
                                label: const Text('Teacher 1'),
                                avatar: const Icon(Icons.school, size: 16),
                                onPressed: () => _quickFill('teacher1@apex.edu', 'Password@123'),
                              ),
                              ActionChip(
                                label: const Text('Student 1'),
                                avatar: const Icon(Icons.person, size: 16),
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
