import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  final Function(UserSession) onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _selectedRole = 'student';
  final TextEditingController _emailController = TextEditingController(
    text: 'aarav.patel@student.classora.com',
  );
  final TextEditingController _passwordController = TextEditingController(
    text: '••••••••',
  );
  bool _isLoading = false;
  String? _errorMessage;

  final UserSession _demoStudent = const UserSession(
    id: 'usr-student-01',
    name: 'Aarav Patel',
    email: 'aarav.patel@student.classora.com',
    role: 'student',
    avatar: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=100&h=100&fit=crop',
    batchOrDept: 'Class 12th JEE Masterclass',
  );

  final UserSession _demoTeacher = const UserSession(
    id: 'usr-teacher-01',
    name: 'Prof. Rajesh Sharma',
    email: 'rajesh.sharma@teacher.classora.com',
    role: 'teacher',
    avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop',
    batchOrDept: 'Department of Physics',
  );

  void _handleRoleSwitch(String role) {
    setState(() {
      _selectedRole = role;
      if (role == 'student') {
        _emailController.text = 'aarav.patel@student.classora.com';
      } else {
        _emailController.text = 'rajesh.sharma@teacher.classora.com';
      }
    });
  }

  void _handleSubmit() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (_selectedRole == 'student') {
        widget.onLoginSuccess(_demoStudent.copyWith(
          email: _emailController.text.isNotEmpty ? _emailController.text : _demoStudent.email,
        ));
      } else {
        widget.onLoginSuccess(_demoTeacher.copyWith(
          email: _emailController.text.isNotEmpty ? _emailController.text : _demoTeacher.email,
        ));
      }
    });
  }

  void _quickDemoLogin(String role) {
    if (role == 'student') {
      widget.onLoginSuccess(_demoStudent);
    } else {
      widget.onLoginSuccess(_demoTeacher);
    }
  }

  @override
  void dispose() {
    _emailController.dispose;
    _passwordController.dispose;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = _selectedRole == 'student';

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.slate900,
              AppColors.indigo950,
              AppColors.slate900,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Logo
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.indigo600,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.indigo500.withOpacity(0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'C',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'CLASSORA',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: AppColors.slate900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Unified Live Learning & Digital Classroom Portal',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.slate500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Role Switcher
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.slate100,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.slate200),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _handleRoleSwitch('student'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isStudent ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: isStudent
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.06),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.person_pin_circle_rounded,
                                        size: 16,
                                        color: isStudent ? AppColors.indigo700 : AppColors.slate500,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Student Portal',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isStudent ? AppColors.indigo700 : AppColors.slate600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _handleRoleSwitch('teacher'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: !isStudent ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: !isStudent
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.06),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.school_rounded,
                                        size: 16,
                                        color: !isStudent ? AppColors.indigo700 : AppColors.slate500,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Teacher Console',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: !isStudent ? AppColors.indigo700 : AppColors.slate600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Email input
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          isStudent ? 'Student ID / Registered Email' : 'Teacher ID / Work Email',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.slate700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _emailController,
                        style: const TextStyle(fontSize: 13, color: AppColors.slate900, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email_outlined, size: 18, color: AppColors.slate400),
                          filled: true,
                          fillColor: AppColors.slate50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.slate200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.slate200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.indigo600, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password input
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Account Password',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.slate700,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              _emailController.clear();
                              _passwordController.clear();
                            },
                            child: const Text(
                              'Clear Fields',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.rose600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(fontSize: 13, color: AppColors.slate900, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.slate400),
                          filled: true,
                          fillColor: AppColors.slate50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.slate200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.slate200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.indigo600, width: 2),
                          ),
                        ),
                      ),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.rose50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.rose600,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),

                      // Sign in button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.indigo600,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: AppColors.indigo600.withOpacity(0.35),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Secure Sign In',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_rounded, size: 16),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Instant One-Click Demo Login
                      Container(
                        padding: const EdgeInsets.only(top: 20),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: AppColors.slate100),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'INSTANT ONE-CLICK DEMO LOGIN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: AppColors.slate400,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _quickDemoLogin('student'),
                                    icon: const Icon(Icons.person_pin_circle_rounded, size: 15, color: AppColors.indigo600),
                                    label: const Text(
                                      'Demo Student',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.indigo900),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: AppColors.indigo50.withOpacity(0.7),
                                      side: const BorderSide(color: AppColors.indigo200),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _quickDemoLogin('teacher'),
                                    icon: const Icon(Icons.school_rounded, size: 15, color: AppColors.purple600),
                                    label: const Text(
                                      'Demo Teacher',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.purple900),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: AppColors.purple50.withOpacity(0.7),
                                      side: const BorderSide(color: AppColors.purple200),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // SSL Encrypted Footer
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified_user_rounded, size: 14, color: AppColors.emerald500),
                          SizedBox(width: 6),
                          Text(
                            '256-Bit SSL Encrypted Session',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.slate400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
