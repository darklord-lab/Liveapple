import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/network/endpoints.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/domain/user_model.dart';
import '../../batch/presentation/batch_controller.dart';
import '../../batch/presentation/join_batch_dialog.dart';
import '../../timetable/presentation/timetable_controller.dart';
import '../../timetable/domain/timetable_model.dart';
import '../../liveclass/presentation/live_class_controller.dart';
import '../../liveclass/domain/live_class_model.dart';
import '../../notifications/presentation/widgets/notification_bell_button.dart';
import '../../notifications/presentation/controllers/notification_controller.dart';
import '../../../core/services/push_notification_service.dart';
import '../../learning/presentation/screens/recordings_screen.dart';
import '../../learning/presentation/screens/assignments_screen.dart';
import '../../learning/presentation/screens/cbt_tests_screen.dart';
import '../../learning/presentation/screens/study_material_tab_view.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/color_tile.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../core/widgets/permission_rationale_dialog.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../institute/domain/institute_link_model.dart';
import '../../institute/domain/testimonial_model.dart';
import '../../institute/presentation/institute_content_controller.dart';
import '../../institute/presentation/institute_branding_controller.dart';
import '../../institute/presentation/institute_code_dialog.dart';

class StudentHomeScreen extends ConsumerStatefulWidget {
  final UserModel user;

  const StudentHomeScreen({super.key, required this.user});

  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen> with SingleTickerProviderStateMixin {
  int _currentBottomNavIndex = 0; // 0: Home, 1: Schedule, 2: Learn, 3: Profile
  int _learnSubTabIndex = 0; // 0: Material, 1: Recordings, 2: Assign, 3: Tests
  String? _selectedStudyBatchId;



  // Settings toggles (Panel 6)
  late bool _classReminders;
  late bool _liveAlerts;
  late bool _homeworkAlerts;

  Timer? _fallbackPollingTimer;
  io.Socket? _globalSocket;

  @override
  void initState() {
    super.initState();
    _classReminders = widget.user.remindersEnabled;
    _liveAlerts = widget.user.liveAlertsEnabled;
    _homeworkAlerts = widget.user.homeworkEnabled;

    // 10-second fallback polling for live classes and notifications
    _fallbackPollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        ref.read(liveClassProvider.notifier).loadClasses();
        ref.read(notificationControllerProvider.notifier).fetchNotifications(showLoading: false);
      }
    });

    Future.microtask(() {
      ref.read(liveClassProvider.notifier).loadClasses();
      ref.read(batchListProvider.notifier).loadBatches();
      ref.read(timetableProvider.notifier).loadSlots();
      ref.read(instituteLinksProvider.notifier).loadLinks();
      ref.read(testimonialsProvider.notifier).loadTestimonials();
      ref.read(instituteBrandingProvider.notifier).syncFromUser(widget.user);
      ref.read(notificationControllerProvider.notifier).fetchNotifications(showLoading: false);
      _initGlobalSocket();
    });
  }

  Future<void> _syncNotificationPrefs() async {
    final prefs = {
      'reminders': _classReminders,
      'liveAlerts': _liveAlerts,
      'homework': _homeworkAlerts,
      'testAlerts': true,
    };
    await ref.read(authStateProvider.notifier).updateProfile(
      notificationPrefs: prefs,
    );
  }

  /// Connects a background socket to receive instant 'class:live' and 'notification:new' push events.
  /// When a teacher starts a class or a notification is dispatched, this fires immediately.
  Future<void> _initGlobalSocket() async {
    try {
      final storage = SecureStorageService();
      final baseUrl = await storage.getBaseUrl() ?? Endpoints.defaultBaseUrl;
      final accessToken = await storage.getAccessToken();
      if (accessToken == null) return;

      // Register device FCM token if saved
      ref.read(pushNotificationServiceProvider).registerTokenIfSaved();

      final uri = Uri.parse(baseUrl);
      final socketHost = '${uri.scheme}://${uri.host}:${uri.port}';

      _globalSocket = io.io(
        socketHost,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': accessToken})
            .enableAutoConnect()
            .build(),
      );

      _globalSocket?.on('class:live', (data) {
        debugPrint('[HOME-SOCKET] class:live — teacher started a class! Reloading...');
        if (mounted) {
          ref.read(liveClassProvider.notifier).loadClasses();
        }
      });

      _globalSocket?.on('class:scheduled', (data) {
        if (mounted) {
          ref.read(liveClassProvider.notifier).loadClasses();
        }
      });

      _globalSocket?.on('notification:new', (data) {
        debugPrint('[HOME-SOCKET] notification:new received: $data');
        if (mounted && data != null) {
          final dataMap = data is Map<String, dynamic>
              ? data
              : Map<String, dynamic>.from(data as Map);
          ref.read(pushNotificationServiceProvider).handleIncomingNotification(context, dataMap);
        }
      });

      _globalSocket?.on('connect_error', (err) {
        debugPrint('[HOME-SOCKET] connect error: $err');
      });
    } catch (e) {
      debugPrint('[HOME-SOCKET] setup error: $e');
    }
  }

  @override
  void dispose() {
    _fallbackPollingTimer?.cancel();
    _globalSocket?.disconnect();
    _globalSocket?.dispose();
    _globalSocket = null;
    super.dispose();
  }

  void _showJoinBatchDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const JoinBatchDialog(),
    );
  }

  void _showBatchesSheet() {
    final batchState = ref.watch(batchListProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 480,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('My Enrolled Batches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: batchState.batches.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.school_outlined, size: 48, color: AppColors.slate400),
                            const SizedBox(height: 10),
                            const Text('No batches enrolled yet', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _showJoinBatchDialog();
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.skyBlue),
                              child: const Text('Join Batch with Code'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: batchState.batches.length,
                        itemBuilder: (context, idx) {
                          final b = batchState.batches[idx];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.slate50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.skyBlueLight,
                                  child: Text(
                                    b.subject.isNotEmpty ? b.subject[0].toUpperCase() : 'B',
                                    style: const TextStyle(color: AppColors.skyBlue, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(b.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      Text('${b.subject} • Faculty: ${b.teacherName ?? 'Teacher'}', style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.successLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('ENROLLED', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showJoinBatchDialog();
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Join Another Batch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.skyBlue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final brandingState = ref.watch(instituteBrandingProvider);
    final brandColor = brandingState.branding.brandColor;
    final coachingName = brandingState.branding.name.isNotEmpty
        ? brandingState.branding.name
        : widget.user.effectiveCoachingName;
    final instituteCode = brandingState.branding.effectiveCode;

    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        // Branded App Bar matching institute white-label
        appBar: AppBar(
          backgroundColor: brandColor,
          elevation: 0,
          centerTitle: false,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              tooltip: 'Menu',
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          title: _currentBottomNavIndex == 0
              ? Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: (brandingState.branding.logoUrl != null &&
                              brandingState.branding.logoUrl!.isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                brandingState.branding.logoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                    brandingState.branding.initials,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: brandColor,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                brandingState.branding.initials,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: brandColor,
                                ),
                              ),
                            ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  coachingName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => InstituteCodeDialog.show(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    instituteCode,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 9,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            widget.user.name,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Text(
                  _currentBottomNavIndex == 1
                      ? 'Schedule'
                      : _currentBottomNavIndex == 2
                          ? 'Learn'
                          : 'Settings',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
        actions: [
          const NotificationBellButton(),
          const SizedBox(width: 8),
        ],
      ),
      // Drawer matching Panel 2
      drawer: _buildDrawer(),
      body: IndexedStack(
        index: _currentBottomNavIndex,
        children: [
          _buildHomeTab(),
          _buildScheduleTab(),
          _buildLearnTab(),
          _buildSettingsTab(),
        ],
      ),
      // 4-Tab Bottom Navigation Bar matching reference
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.borderLight, width: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentBottomNavIndex,
          onTap: (index) {
            setState(() {
              _currentBottomNavIndex = index;
            });
          },
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.skyBlue,
          unselectedItemColor: AppColors.slate400,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              label: 'Schedule',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              label: 'Learn',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
    ),
  );
  }

  /* -------------------------------------------------------------------------- */
  /* PANEL 2: DRAWER                                                            */
  /* -------------------------------------------------------------------------- */
  Widget _buildDrawer() {
    final authState = ref.watch(authStateProvider);
    final currentUser = authState.user ?? widget.user;
    final brandingState = ref.watch(instituteBrandingProvider);
    final instituteCode = brandingState.branding.effectiveCode;
    final coachingName = brandingState.branding.name.isNotEmpty
        ? brandingState.branding.name
        : currentUser.effectiveCoachingName;
    final brandColor = brandingState.branding.brandColor;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.borderLight)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: brandColor.withValues(alpha: 0.15),
                    backgroundImage: (currentUser.avatarUrl != null && currentUser.avatarUrl!.isNotEmpty)
                        ? NetworkImage(currentUser.avatarUrl!)
                        : null,
                    child: (currentUser.avatarUrl == null || currentUser.avatarUrl!.isEmpty)
                        ? Text(
                            currentUser.name.isNotEmpty ? currentUser.name[0].toUpperCase() : 'U',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: brandColor),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textLight),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          coachingName,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: brandColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Row(
                          children: [
                            Text(
                              'Code: $instituteCode',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.slate500),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                                InstituteCodeDialog.show(context);
                              },
                              child: Icon(Icons.edit_outlined, size: 13, color: brandColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    icon: Icons.folder_open_outlined,
                    label: 'Study Material',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _currentBottomNavIndex = 2;
                        _learnSubTabIndex = 0;
                      });
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.edit_note_outlined,
                    label: 'Assignments',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _currentBottomNavIndex = 2;
                        _learnSubTabIndex = 2;
                      });
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.timer_outlined,
                    label: 'Tests',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _currentBottomNavIndex = 2;
                        _learnSubTabIndex = 3;
                      });
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.videocam_outlined,
                    label: 'Recordings',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _currentBottomNavIndex = 2;
                        _learnSubTabIndex = 1;
                      });
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.calendar_today_outlined,
                    label: 'Attendance',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/attendance');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.credit_card_outlined,
                    label: 'Fees & Receipts',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/fees');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.storefront_outlined,
                    label: 'Course Store',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/store');
                    },
                  ),
                  const Divider(color: AppColors.borderLight, height: 16),
                  _buildDrawerItem(
                    icon: Icons.person_outline,
                    label: 'Edit Profile',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/edit-profile');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _currentBottomNavIndex = 3;
                      });
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.help_outline,
                    label: 'Help / How to use',
                    onTap: () {
                      Navigator.pop(context);
                      _showHelpDialog();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.share_rounded,
                    label: 'Connect With Us',
                    onTap: () {
                      Navigator.pop(context);
                      _showConnectDialog();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.vpn_key_outlined,
                    label: 'Institute Code ($instituteCode)',
                    onTap: () {
                      Navigator.pop(context);
                      InstituteCodeDialog.show(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.shield_outlined,
                    label: 'Privacy Policy',
                    onTap: () {
                      Navigator.pop(context);
                      _showPrivacyDialog();
                    },
                  ),
                ],
              ),
            ),

            // Share App Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _handleShareApp,
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: const Text('Share App with Classmates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.skyBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: AppColors.slate700, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textLight)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }

  /* -------------------------------------------------------------------------- */
  /* PANEL 1: HOME TAB                                                          */
  /* -------------------------------------------------------------------------- */
  Widget _buildHomeTab() {
    final liveClassState = ref.watch(liveClassProvider);
    final linksState = ref.watch(instituteLinksProvider);
    final testimonialsState = ref.watch(testimonialsProvider);
    final classes = liveClassState.classes;

    // Find first active LIVE class, or null
    final activeLiveClass = classes.cast<LiveClassModel?>().firstWhere(
          (c) => c != null && c.isLive,
          orElse: () => null,
        );

    // Upcoming classes for "Next classes" section
    final upcomingClasses = classes.where((c) => !c.isEnded).toList();

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(liveClassProvider.notifier).loadClasses();
        await ref.read(batchListProvider.notifier).loadBatches();
        await ref.read(instituteLinksProvider.notifier).loadLinks();
        await ref.read(testimonialsProvider.notifier).loadTestimonials();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 0. Teacher & Coaching Centre Branding Card
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.skyBlue, Color(0xFF6366F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.school, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user.effectiveCoachingName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Faculty: ${widget.user.effectiveFacultyName}${widget.user.teacher?.subjects != null ? ' • ${widget.user.teacher!.subjects}' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.slate500,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.skyBlueLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Verified Faculty',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.skyBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 1. LIVE NOW Card (Hero)
            if (activeLiveClass != null)
              _buildLiveHeroCard(activeLiveClass)
            else if (upcomingClasses.isNotEmpty)
              _buildUpcomingHeroCard(upcomingClasses.first)
            else
              _buildDefaultHeroCard(),

            const SizedBox(height: 18),

            // 2. Quick Access (2x2 Coloured Tiles matching Reference UI)
            const Text(
              'Quick access',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textLight),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ColorTile(
                    title: 'Live\nSchedule',
                    color: AppColors.tileSchedule,
                    icon: Icons.access_time_filled_rounded,
                    onTap: () {
                      setState(() {
                        _currentBottomNavIndex = 1;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ColorTile(
                    title: 'Study\nMaterial',
                    color: AppColors.tileMaterial,
                    icon: Icons.folder_rounded,
                    onTap: () {
                      setState(() {
                        _currentBottomNavIndex = 2;
                        _learnSubTabIndex = 0;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ColorTile(
                    title: 'Recorded\nClasses',
                    color: AppColors.tileRecordings,
                    icon: Icons.videocam_rounded,
                    onTap: () {
                      setState(() {
                        _currentBottomNavIndex = 2;
                        _learnSubTabIndex = 1;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ColorTile(
                    title: 'My\nBatches',
                    color: AppColors.tileBatches,
                    icon: Icons.grid_view_rounded,
                    onTap: _showBatchesSheet,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // 3. Next classes Header with "See all"
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Next classes',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textLight),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentBottomNavIndex = 1;
                    });
                  },
                  child: const Text(
                    'See all',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.skyBlue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Horizontal Next Classes Cards
            SizedBox(
              height: 110,
              child: upcomingClasses.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: const Center(
                        child: Text(
                          'No upcoming classes scheduled right now.',
                          style: TextStyle(color: AppColors.slate500, fontSize: 13),
                        ),
                      ),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: upcomingClasses.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, idx) {
                        final cls = upcomingClasses[idx];
                        return _buildNextClassCard(cls);
                      },
                    ),
            ),

            const SizedBox(height: 20),

            // 4. Homework & tests due Card
            const Text(
              'Homework & tests due',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textLight),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () {
                setState(() {
                  _currentBottomNavIndex = 2;
                  _learnSubTabIndex = 2;
                });
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.skyBlueLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit_outlined, color: AppColors.skyBlue, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Homework & CBT Quizzes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          SizedBox(height: 2),
                          Text('Assignments, study tasks & test submissions', style: TextStyle(color: AppColors.slate500, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.skyBlueLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('VIEW ALL', style: TextStyle(color: AppColors.skyBlue, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Course Store Promo Banner (Stage 6)
            _buildStorePromoBanner(),

            // 5. Student Testimonials Section (DESIGN.md)
            _buildTestimonialsSection(testimonialsState.testimonials),

            // 6. Connect With Us Section (DESIGN.md: only if links set)
            _buildConnectWithUsSection(linksState.links),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStorePromoBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.skyBlue.withValues(alpha: 0.12),
            const Color(0xFF6366F1).withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.skyBlue.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.skyBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Course Store & Test Series',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textLight,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Explore new batches, test series & apply coupons',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.slate500,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => context.push('/store'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.skyBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 36),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Explore', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveHeroCard(LiveClassModel cls) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.liveRed.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const StatusPill(status: ClassStatus.live),
              Text(
                '${cls.attendanceCount} joined',
                style: const TextStyle(fontSize: 11, color: AppColors.slate500),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cls.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textLight),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${cls.teacherName ?? 'Teacher'} • ${cls.batchName ?? 'Batch'}',
                      style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => context.push('/live/${cls.id}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.skyBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  elevation: 0,
                ),
                child: const Text('Join', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingHeroCard(LiveClassModel cls) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.skyBlue.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.skyBlueLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(cls.timeUntilText, style: const TextStyle(color: AppColors.skyBlue, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
              Text('${cls.formattedDate} • ${cls.formattedTime} IST', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.slate500)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cls.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('${cls.teacherName ?? 'Teacher'} • ${cls.batchName ?? 'Batch'}', style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => context.push('/live/${cls.id}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.skyBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Waiting Room', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultHeroCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppColors.skyBlueLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school, color: AppColors.skyBlue, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome to Student Portal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                SizedBox(height: 2),
                Text('All live sessions & timetable are synced', style: TextStyle(fontSize: 12, color: AppColors.slate500)),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildNextClassCard(LiveClassModel cls) {
    final subject = cls.subject ?? 'General';

    return Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.slate100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              subject,
              style: const TextStyle(fontSize: 10, color: AppColors.slate700, fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            cls.title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            cls.teacherName ?? 'Teacher',
            style: const TextStyle(fontSize: 11, color: AppColors.slate500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${cls.formattedDate} • ${cls.formattedTime}',
            style: const TextStyle(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  /* -------------------------------------------------------------------------- */
  /* PANEL 3: SCHEDULE TAB                                                      */
  /* -------------------------------------------------------------------------- */
  Widget _buildScheduleTab() {
    final timetableState = ref.watch(timetableProvider);
    final liveClassState = ref.watch(liveClassProvider);
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final selectedDayIndex = timetableState.selectedDay;

    // Filter classes or slots for selected day
    final slots = timetableState.slots.where((s) => s.dayOfWeek == selectedDayIndex).toList();

    final now = DateTime.now();
    final todaySlotDay = now.weekday % 7; // Sunday=0, Monday=1, ...
    final dayOffset = selectedDayIndex - todaySlotDay;
    final targetDate = now.add(Duration(days: dayOffset));
    final formattedDate = DateFormat('d MMM').format(targetDate);
    final currentMinutes = now.hour * 60 + now.minute;

    return Column(
      children: [
        // Horizontal Day Selector Chips
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(7, (idx) {
                final isSelected = selectedDayIndex == idx;
                final count = timetableState.slots.where((s) => s.dayOfWeek == idx).length;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => ref.read(timetableProvider.notifier).selectDay(idx),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black87 : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.black87 : AppColors.borderLight,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (isSelected) ...[
                            const Icon(Icons.check, size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            '${days[idx]} ($count)',
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.slate700,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),

        const Divider(height: 1, color: AppColors.borderLight),

        // Selected Day Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            '${_getFullDayName(selectedDayIndex)}, $formattedDate',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textLight),
          ),
        ),

        // Agenda Timeline List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await ref.read(timetableProvider.notifier).loadSlots();
              await ref.read(liveClassProvider.notifier).loadClasses();
            },
            child: slots.isEmpty && liveClassState.classes.isEmpty
                ? const EmptyState(
                    icon: Icons.calendar_today_outlined,
                    title: 'No classes scheduled for this day',
                    subtitle: 'Check other days or pull down to refresh',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: slots.isNotEmpty ? slots.length : liveClassState.classes.length,
                    itemBuilder: (context, idx) {
                      if (slots.isNotEmpty) {
                        final slot = slots[idx];
                        // Match with live class if one exists for this slot/batch
                        final matchingClass = liveClassState.classes.cast<LiveClassModel?>().firstWhere(
                              (c) => c?.batchId == slot.batchId,
                              orElse: () => null,
                            );

                        final String slotStatus;
                        if (matchingClass?.isLive == true) {
                          slotStatus = 'LIVE';
                        } else if (selectedDayIndex < todaySlotDay ||
                            (selectedDayIndex == todaySlotDay && currentMinutes > slot.endMin)) {
                          slotStatus = 'ENDED';
                        } else {
                          slotStatus = 'UPCOMING';
                        }

                        return _buildScheduleItemCard(
                          startTime: TimetableSlotModel.formatMinutes(slot.startMin),
                          endTime: TimetableSlotModel.formatMinutes(slot.endMin),
                          title: slot.subject != null ? '${slot.subject} - Session' : 'Scheduled Class',
                          subtitle: '${slot.batchName ?? 'Batch'} • ${slot.subject ?? 'Subject'}',
                          teacher: slot.teacherName ?? 'Faculty',
                          status: slotStatus,
                          liveClassId: matchingClass?.id,
                        );
                      } else {
                        final cls = liveClassState.classes[idx];
                        return _buildScheduleItemCard(
                          startTime: cls.formattedTime,
                          endTime: '',
                          title: cls.title,
                          subtitle: '${cls.batchName ?? 'Batch'} • ${cls.subject ?? 'Subject'}',
                          teacher: cls.teacherName ?? 'Teacher',
                          status: cls.isLive ? 'LIVE' : (cls.isEnded ? 'ENDED' : 'UPCOMING'),
                          liveClassId: cls.id,
                        );
                      }
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleItemCard({
    required String startTime,
    required String endTime,
    required String title,
    required String subtitle,
    required String teacher,
    required String status,
    String? liveClassId,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Blue Time Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.skyBlueLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(startTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.skyBlue)),
                if (endTime.isNotEmpty)
                  Text('to $endTime', style: const TextStyle(fontSize: 9, color: AppColors.skyBlue)),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.slate500), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('Prof. $teacher', style: const TextStyle(fontSize: 11, color: AppColors.slate400), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),

          // Status Button / Badge
          if (status == 'LIVE') ...[
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const StatusPill(status: ClassStatus.live),
                if (liveClassId != null) ...[
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 28,
                    child: ElevatedButton(
                      onPressed: () => context.push('/live/$liveClassId'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.skyBlue,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Join', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ],
            ),
          ] else if (status == 'ENDED') ...[
            const StatusPill(status: ClassStatus.ended),
          ] else ...[
            const StatusPill(status: ClassStatus.upcoming),
          ],
        ],
      ),
    );
  }

  String _getFullDayName(int day) {
    const names = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return names[day.clamp(0, 6)];
  }

  /* -------------------------------------------------------------------------- */
  /* PANEL 4 & 5: LEARN TAB                                                     */
  /* -------------------------------------------------------------------------- */
  Widget _buildLearnTab() {
    return Column(
      children: [
        // 4 Sub-Tabs Bar (MATERIAL, RECORDINGS, ASSIGNMENTS, TESTS)
        Container(
          color: Colors.white,
          child: Row(
            children: [
              _buildSubTabHeader('MATERIAL', 0),
              _buildSubTabHeader('RECORDINGS', 1),
              _buildSubTabHeader('ASSIGNMENTS', 2),
              _buildSubTabHeader('TESTS', 3),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.borderLight),

        // Sub-Tab Content
        Expanded(
          child: _learnSubTabIndex == 0
              ? _buildStudyMaterialSubTab()
              : _learnSubTabIndex == 1
                  ? const RecordingsScreen()
                  : _learnSubTabIndex == 2
                      ? const AssignmentsScreen(isTeacher: false)
                      : const CbtTestsScreen(),
        ),
      ],
    );
  }

  Widget _buildSubTabHeader(String title, int index) {
    final isSelected = _learnSubTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _learnSubTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.skyBlue : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? AppColors.skyBlue : AppColors.slate500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudyMaterialSubTab() {
    final batchState = ref.watch(batchListProvider);
    final batches = batchState.batches;

    if (batches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: EmptyState(
            icon: Icons.school_outlined,
            title: 'No Enrolled Batches',
            subtitle: 'Join a batch using your class join code to access study materials, notes, and video lectures.',
            buttonText: 'Join a Batch',
            onAction: () {
              showDialog(
                context: context,
                builder: (_) => const JoinBatchDialog(),
              );
            },
          ),
        ),
      );
    }

    final selectedBatch = batches.firstWhere(
      (b) => b.id == _selectedStudyBatchId,
      orElse: () => batches.first,
    );

    return Column(
      children: [
        if (batches.length > 1)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                const Text(
                  'BATCH:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slate500, letterSpacing: 0.8),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: batches.map((b) {
                        final isSel = b.id == selectedBatch.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(
                              b.name,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                color: isSel ? Colors.white : AppColors.textLight,
                              ),
                            ),
                            selected: isSel,
                            selectedColor: AppColors.skyBlue,
                            backgroundColor: AppColors.backgroundLight,
                            onSelected: (_) {
                              setState(() {
                                _selectedStudyBatchId = b.id;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: StudyMaterialTabView(
            batchId: selectedBatch.id,
            isTeacher: false,
            batchName: selectedBatch.name,
          ),
        ),
      ],
    );
  }








  /* -------------------------------------------------------------------------- */
  /* PANEL 6: SETTINGS / PROFILE TAB                                            */
  /* -------------------------------------------------------------------------- */
  Widget _buildSettingsTab() {
    final authState = ref.watch(authStateProvider);
    final currentUser = authState.user ?? widget.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Details Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.skyBlueLight,
                  backgroundImage: (currentUser.avatarUrl != null && currentUser.avatarUrl!.isNotEmpty)
                      ? NetworkImage(currentUser.avatarUrl!)
                      : null,
                  child: (currentUser.avatarUrl == null || currentUser.avatarUrl!.isEmpty)
                      ? Text(
                          currentUser.name.isNotEmpty ? currentUser.name[0].toUpperCase() : 'U',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.skyBlue),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(currentUser.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(currentUser.email, style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.skyBlueLight, borderRadius: BorderRadius.circular(4)),
                        child: Text(
                          currentUser.role,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.skyBlue),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Settings Items matching Panel 6
          _buildSettingsTile(
            title: 'Edit Profile',
            subtitle: 'Name, photo, phone',
            trailing: const Icon(Icons.chevron_right, color: AppColors.slate400),
            onTap: () {
              context.push('/edit-profile');
            },
          ),
          const Divider(height: 1, color: AppColors.borderLight),

          _buildSettingsSwitchTile(
            title: 'Class reminders',
            subtitle: '15 minutes before a class',
            value: _classReminders,
            onChanged: (val) {
              setState(() {
                _classReminders = val;
              });
              _syncNotificationPrefs();
            },
          ),
          const Divider(height: 1, color: AppColors.borderLight),

          _buildSettingsSwitchTile(
            title: 'Live class alerts',
            subtitle: 'When a teacher goes live',
            value: _liveAlerts,
            onChanged: (val) {
              setState(() {
                _liveAlerts = val;
              });
              _syncNotificationPrefs();
            },
          ),
          const Divider(height: 1, color: AppColors.borderLight),

          _buildSettingsSwitchTile(
            title: 'Homework & test alerts',
            subtitle: 'Remind when deadlines near',
            value: _homeworkAlerts,
            onChanged: (val) {
              setState(() {
                _homeworkAlerts = val;
              });
              _syncNotificationPrefs();
            },
          ),
          const Divider(height: 1, color: AppColors.borderLight),

          _buildSettingsTile(
            title: 'Notification permission',
            subtitle: 'Configure alerts & permissions',
            trailing: const Icon(Icons.chevron_right, color: AppColors.slate400),
            onTap: () {
              PermissionRationaleDialog.show(
                context,
                type: PermissionType.notifications,
              );
            },
          ),
          const Divider(height: 1, color: AppColors.borderLight),

          _buildSettingsTile(
            title: 'Help / How to use the app',
            subtitle: 'Guides and student tutorials',
            trailing: const Icon(Icons.chevron_right, color: AppColors.slate400),
            onTap: _showHelpDialog,
          ),

          const SizedBox(height: 24),

          // Two Action Buttons: Share app | Rate us
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _handleShareApp,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.skyBlue,
                    side: const BorderSide(color: AppColors.skyBlue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Share app', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: OutlinedButton(
                  onPressed: _showRateAppDialog,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.skyBlue,
                    side: const BorderSide(color: AppColors.skyBlue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Rate us', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Sign Out Button
          Center(
            child: TextButton(
              onPressed: () async {
                final confirm = await ConfirmDialog.show(
                  context,
                  title: 'Sign Out',
                  message: 'Are you sure you want to sign out from Classora?',
                  confirmText: 'Sign Out',
                  isDestructive: true,
                );
                if (confirm == true) {
                  ref.read(authStateProvider.notifier).logout();
                }
              },
              child: const Text(
                'Sign Out',
                style: TextStyle(color: AppColors.liveRed, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Footer
          Center(
            child: Column(
              children: [
                const Text('Version 2.0.0', style: TextStyle(color: AppColors.slate400, fontSize: 11)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _showPrivacyDialog,
                      child: const Text('Terms & conditions', style: TextStyle(color: AppColors.skyBlue, fontSize: 11)),
                    ),
                    const Text(' • ', style: TextStyle(color: AppColors.slate400)),
                    GestureDetector(
                      onTap: _showPrivacyDialog,
                      child: const Text('Privacy Policy', style: TextStyle(color: AppColors.skyBlue, fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildSettingsSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
      trailing: Switch(
        value: value,
        activeColor: AppColors.skyBlue,
        onChanged: onChanged,
      ),
    );
  }

  void _showHelpDialog() {
    context.push('/help?role=STUDENT');
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy & Security'),
        content: const Text(
          'Your classroom data, recordings, and submissions are securely stored with role-based access control and tenant isolation.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showConnectDialog() {
    final links = ref.read(instituteLinksProvider).links;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.share_rounded, color: AppColors.skyBlue, size: 22),
            SizedBox(width: 8),
            Text('Connect With Us', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: links.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No official connect links published yet by your institute.', style: TextStyle(color: AppColors.slate500, fontSize: 13)),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: links.map((link) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: link.brandColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(link.iconData, color: link.brandColor, size: 20),
                      ),
                      title: Text(link.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text(link.url, style: const TextStyle(fontSize: 11, color: AppColors.slate500), maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: const Icon(Icons.copy, size: 16, color: AppColors.skyBlue),
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: link.url));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${link.title} link copied to clipboard!'),
                            backgroundColor: AppColors.skyBlue,
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildTestimonialsSection(List<TestimonialModel> testimonials) {
    if (testimonials.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Student Testimonials',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textLight),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.star_rounded, size: 14, color: Color(0xFFD97706)),
                  SizedBox(width: 3),
                  Text('Wall of Fame', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: testimonials.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, idx) {
              final t = testimonials[idx];
              return Container(
                width: 280,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.skyBlueLight,
                          child: Text(
                            t.initials,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.skyBlue),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.studentName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textLight),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (t.batchOrExam != null && t.batchOrExam!.isNotEmpty)
                                Text(
                                  t.batchOrExam!,
                                  style: const TextStyle(fontSize: 10, color: AppColors.slate500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        Row(
                          children: List.generate(
                            t.rating,
                            (_) => const Icon(Icons.star_rounded, size: 13, color: Color(0xFFF59E0B)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Text(
                        '"${t.quote}"',
                        style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.slate700, height: 1.35),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConnectWithUsSection(List<InstituteLinkModel> links) {
    if (links.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        const Text(
          'Connect with us',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textLight),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Official channels & communities:',
                style: TextStyle(fontSize: 12, color: AppColors.slate500),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: links.map((link) {
                  return InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: link.url));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${link.title} link copied to clipboard!\n${link.url}'),
                          backgroundColor: AppColors.skyBlue,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: link.brandColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: link.brandColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(link.iconData, size: 16, color: link.brandColor),
                          const SizedBox(width: 8),
                          Text(
                            link.title,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: link.brandColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.open_in_new, size: 12, color: link.brandColor.withValues(alpha: 0.7)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleShareApp() {
    final user = ref.read(authStateProvider).user ?? widget.user;
    final shareText = 'Join my classroom on Classora! Access live classes, interactive quizzes, and study material.\nDownload App: https://classora.app/download\nInstitute: ${user.effectiveCoachingName}';
    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Classora invite link copied to clipboard! Share it with your classmates.'),
        backgroundColor: AppColors.skyBlue,
      ),
    );
  }

  void _showRateAppDialog() {
    int selectedRating = 5;
    final feedbackController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Rate Classora App', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'How is your classroom experience with Classora?',
                style: TextStyle(fontSize: 13, color: AppColors.slate500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return IconButton(
                    icon: Icon(
                      starIndex <= selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 34,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        selectedRating = starIndex;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: feedbackController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Any feedback or suggestions? (Optional)',
                  hintStyle: const TextStyle(fontSize: 12, color: AppColors.slate400),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Maybe Later', style: TextStyle(color: AppColors.slate500)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.skyBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Thank you for rating Classora $selectedRating stars! Your review helps us improve.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              child: const Text('Submit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
