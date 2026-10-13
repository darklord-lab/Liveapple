import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/color_tile.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_pill.dart';
import '../../auth/domain/user_model.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../batch/presentation/batch_controller.dart';
import '../../batch/presentation/batch_detail_screen.dart';
import '../../batch/presentation/batch_students_dialog.dart';
import '../../batch/presentation/create_batch_dialog.dart';
import '../../liveclass/domain/live_class_model.dart';
import '../../liveclass/presentation/live_class_controller.dart';
import '../../notifications/presentation/widgets/notification_bell_button.dart';
import '../domain/teacher_model.dart';
import 'add_teacher_dialog.dart';
import 'admin_controller.dart';
import 'bulk_onboard_dialog.dart';
import '../../institute/presentation/institute_branding_controller.dart';
import '../../institute/presentation/institute_code_dialog.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  final UserModel user;

  const AdminHomeScreen({super.key, required this.user});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  int _currentBottomNavIndex = 0; // 0: Overview, 1: Teachers, 2: Batches, 3: More
  final TextEditingController _teacherSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(adminTeachersProvider.notifier).loadTeachers();
      ref.read(batchListProvider.notifier).loadBatches();
      ref.read(liveClassProvider.notifier).loadClasses();
      ref.read(instituteBrandingProvider.notifier).syncFromUser(widget.user);
    });
  }

  @override
  void dispose() {
    _teacherSearchController.dispose();
    super.dispose();
  }

  void _showAddTeacher() {
    showDialog(
      context: context,
      builder: (_) => const AddTeacherDialog(),
    );
  }

  void _showBulkOnboard() {
    showDialog(
      context: context,
      builder: (_) => const BulkOnboardDialog(),
    );
  }

  void _showCreateBatch() {
    showDialog(
      context: context,
      builder: (_) => const CreateBatchDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brandingState = ref.watch(instituteBrandingProvider);
    final brandColor = brandingState.branding.brandColor;
    final instituteName = brandingState.branding.name.isNotEmpty
        ? brandingState.branding.name
        : (widget.user.institute?.name ?? 'Classora Admin Console');
    final instituteCode = brandingState.branding.effectiveCode;

    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
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
                                  instituteName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => InstituteCodeDialog.show(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    instituteCode,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            'ADMINISTRATOR CONSOLE',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentBottomNavIndex == 1
                          ? 'Faculty Directory'
                          : _currentBottomNavIndex == 2
                              ? 'Cohort Batches'
                              : 'Admin Hub',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text(
                      'ADMINISTRATOR CONSOLE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
          actions: [
            const NotificationBellButton(),
            const SizedBox(width: 8),
          ],
        ),
        drawer: _buildDrawer(),
        body: IndexedStack(
          index: _currentBottomNavIndex,
          children: [
            _buildOverviewTab(),
            _buildTeachersTab(),
            _buildBatchesTab(),
            _buildMoreTab(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.borderLight, width: 0.8)),
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -1)),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentBottomNavIndex,
            onTap: (idx) => setState(() => _currentBottomNavIndex = idx),
            backgroundColor: Colors.white,
            selectedItemColor: brandColor,
            unselectedItemColor: AppColors.slate400,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Overview'),
              BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Teachers'),
              BottomNavigationBarItem(icon: Icon(Icons.school_outlined), activeIcon: Icon(Icons.school), label: 'Batches'),
              BottomNavigationBarItem(icon: Icon(Icons.more_horiz), activeIcon: Icon(Icons.more_horiz), label: 'More'),
            ],
          ),
        ),
      ),
    );
  }

  /* -------------------------------------------------------------------------- */
  /* DRAWER (ADMIN)                                                             */
  /* -------------------------------------------------------------------------- */
  Widget _buildDrawer() {
    final brandingState = ref.watch(instituteBrandingProvider);
    final instituteCode = brandingState.branding.effectiveCode;
    final coachingName = brandingState.branding.name.isNotEmpty
        ? brandingState.branding.name
        : (widget.user.institute?.name ?? 'Classora Academy');
    final brandColor = brandingState.branding.brandColor;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.borderLight)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: brandColor.withValues(alpha: 0.15),
                    child: Icon(Icons.admin_panel_settings, size: 28, color: brandColor),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textLight),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                              'Administrator • Code $instituteCode',
                              style: const TextStyle(fontSize: 12, color: AppColors.slate500),
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
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    icon: Icons.dashboard_outlined,
                    label: 'Overview',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentBottomNavIndex = 0);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.people_outline,
                    label: 'Faculty Teachers',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentBottomNavIndex = 1);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.school_outlined,
                    label: 'Cohort Batches',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentBottomNavIndex = 2);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Fees & Dues',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/fees');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.calendar_today_outlined,
                    label: 'Attendance Records',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/attendance');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.videocam_outlined,
                    label: 'Class Recordings',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/recordings');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.menu_book_outlined,
                    label: 'Study Materials & Assignments',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/assignments');
                    },
                  ),
                  const Divider(color: AppColors.borderLight, height: 16),
                  _buildDrawerItem(
                    icon: Icons.laptop_mac_outlined,
                    label: 'Admin Web Portal',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentBottomNavIndex = 3);
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
                    icon: Icons.palette_outlined,
                    label: 'White-Label & Web Content',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/institute-content');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.help_outline,
                    label: 'Help & Administrator Guide',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/help?role=ADMIN');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.logout,
                    label: 'Sign Out',
                    textColor: AppColors.liveRed,
                    onTap: () async {
                      Navigator.pop(context);
                      final confirmed = await ConfirmDialog.show(
                        context,
                        title: 'Sign Out',
                        message: 'Are you sure you want to log out from the Administrator account?',
                        confirmText: 'Sign Out',
                        isDestructive: true,
                      );
                      if (confirmed == true) {
                        ref.read(authStateProvider.notifier).logout();
                      }
                    },
                  ),
                ],
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
    Color? textColor,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: textColor ?? AppColors.slate700, size: 20),
      title: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textColor ?? AppColors.textLight)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }

  /* -------------------------------------------------------------------------- */
  /* TAB 0: OVERVIEW TAB                                                        */
  /* -------------------------------------------------------------------------- */
  Widget _buildOverviewTab() {
    final teacherState = ref.watch(adminTeachersProvider);
    final batchState = ref.watch(batchListProvider);
    final liveClassState = ref.watch(liveClassProvider);

    final totalStudents = batchState.batches.fold<int>(0, (sum, b) => sum + b.activeStudentsCount);
    final totalTeachers = teacherState.teachers.length;
    final totalBatches = batchState.batches.length;
    final liveClasses = liveClassState.classes.where((c) => c.isLive).toList();
    final upcomingClasses = liveClassState.classes.where((c) => c.isScheduled).toList();

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(adminTeachersProvider.notifier).loadTeachers();
        await ref.read(batchListProvider.notifier).loadBatches();
        await ref.read(liveClassProvider.notifier).loadClasses();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AppColors.skyBlueLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance, color: AppColors.skyBlue, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user.institute?.name ?? 'Classora Academy',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textLight),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Text('Institute Command & Onboarding Hub', style: TextStyle(fontSize: 12, color: AppColors.slate500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 4 Metrics Cards (2x2 Grid)
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total Students',
                    value: '$totalStudents',
                    icon: Icons.people_outline,
                    color: AppColors.skyBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Faculty Teachers',
                    value: '$totalTeachers',
                    icon: Icons.school_outlined,
                    color: AppColors.tileBatches,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Active Batches',
                    value: '$totalBatches',
                    icon: Icons.class_outlined,
                    color: AppColors.tileRecordings,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Live Now',
                    value: '${liveClasses.length}',
                    icon: Icons.sensors,
                    color: liveClasses.isNotEmpty ? AppColors.liveRed : AppColors.slate500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // Quick Actions 2x2 ColorTiles
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textLight),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ColorTile(
                    title: 'Onboard\nTeacher',
                    color: AppColors.tileBatches,
                    icon: Icons.person_add_alt_1,
                    onTap: _showAddTeacher,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ColorTile(
                    title: 'Bulk CSV\nOnboard',
                    color: AppColors.tileSchedule,
                    icon: Icons.upload_file,
                    onTap: _showBulkOnboard,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ColorTile(
                    title: 'Create\nBatch',
                    color: AppColors.tileRecordings,
                    icon: Icons.add_circle_outline,
                    onTap: _showCreateBatch,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ColorTile(
                    title: 'Fees &\nReceipts',
                    color: AppColors.tileMaterial,
                    icon: Icons.account_balance_wallet_outlined,
                    onTap: () => context.push('/fees'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Live Classes / Recent Sessions Monitoring
            const Text(
              'Institute Live Sessions',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textLight),
            ),
            const SizedBox(height: 10),
            if (liveClasses.isEmpty && upcomingClasses.isEmpty)
              const EmptyState(
                icon: Icons.sensors_off,
                title: 'No active classes right now',
                subtitle: 'Classes scheduled by faculty will appear here in real-time.',
              )
            else ...[
              ...liveClasses.map((cls) => _buildLiveSessionCard(cls, isLive: true)),
              ...upcomingClasses.take(3).map((cls) => _buildLiveSessionCard(cls, isLive: false)),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.textLight),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: AppColors.slate500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLiveSessionCard(LiveClassModel cls, {required bool isLive}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isLive ? AppColors.liveRed.withValues(alpha: 0.5) : AppColors.borderLight),
      ),
      child: Row(
        children: [
          StatusPill(status: isLive ? ClassStatus.live : ClassStatus.upcoming),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cls.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textLight),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${cls.batchName ?? 'Batch'} • ${cls.formattedDate} • ${cls.formattedTime}',
                  style: const TextStyle(fontSize: 11, color: AppColors.slate500),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => context.push('/live/${cls.id}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isLive ? AppColors.liveRed : AppColors.skyBlue,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              isLive ? 'Monitor' : 'Details',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /* -------------------------------------------------------------------------- */
  /* TAB 1: TEACHERS TAB                                                        */
  /* -------------------------------------------------------------------------- */
  Widget _buildTeachersTab() {
    final teacherState = ref.watch(adminTeachersProvider);
    final teachers = teacherState.teachers;

    return Column(
      children: [
        // Action Header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Faculty Teachers (${teacherState.totalCount})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textLight),
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _showAddTeacher,
                        icon: const Icon(Icons.person_add, size: 14, color: Colors.white),
                        label: const Text('+ Single', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.skyBlue,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _showBulkOnboard,
                        icon: const Icon(Icons.upload_file, size: 14, color: AppColors.skyBlue),
                        label: const Text('Bulk CSV', style: TextStyle(fontSize: 11, color: AppColors.skyBlue, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.skyBlue),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Search Input
              TextField(
                controller: _teacherSearchController,
                onChanged: (val) => ref.read(adminTeachersProvider.notifier).setSearch(val),
                decoration: InputDecoration(
                  hintText: 'Search faculty by name or email...',
                  hintStyle: const TextStyle(fontSize: 12, color: AppColors.slate400),
                  prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.slate400),
                  suffixIcon: _teacherSearchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _teacherSearchController.clear();
                            ref.read(adminTeachersProvider.notifier).setSearch('');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  filled: true,
                  fillColor: AppColors.backgroundLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 8),
              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTeacherFilterChip('ALL', 'All'),
                    const SizedBox(width: 8),
                    _buildTeacherFilterChip('ACTIVE', 'Active'),
                    const SizedBox(width: 8),
                    _buildTeacherFilterChip('INVITED', 'Invited'),
                    const SizedBox(width: 8),
                    _buildTeacherFilterChip('SUSPENDED', 'Suspended'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.borderLight),

        // Teachers List
        Expanded(
          child: teacherState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : teacherState.errorMessage != null
                  ? Center(child: Text(teacherState.errorMessage!, style: const TextStyle(color: AppColors.error)))
                  : teachers.isEmpty
                      ? EmptyState(
                          icon: Icons.people_outline,
                          title: 'No teachers found',
                          subtitle: 'Invite faculty members individually or import via CSV.',
                          buttonText: 'Add First Teacher',
                          onAction: _showAddTeacher,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                          itemCount: teachers.length,
                          itemBuilder: (context, idx) {
                            final t = teachers[idx];
                            return _buildTeacherCard(t);
                          },
                        ),
        ),
      ],
    );
  }

  Widget _buildTeacherFilterChip(String filterKey, String label) {
    final isSelected = ref.watch(adminTeachersProvider).statusFilter == filterKey;
    return InkWell(
      onTap: () => ref.read(adminTeachersProvider.notifier).setStatusFilter(filterKey),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.skyBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.skyBlue : AppColors.borderLight),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.slate700,
          ),
        ),
      ),
    );
  }

  Widget _buildTeacherCard(TeacherModel t) {
    Color statusColor;
    String statusLabel = t.status;
    if (t.isActive) {
      statusColor = AppColors.success;
    } else if (t.isInvited) {
      statusColor = AppColors.warning;
    } else {
      statusColor = AppColors.liveRed;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
                radius: 20,
                backgroundColor: AppColors.skyBlueLight,
                child: Text(
                  t.name.isNotEmpty ? t.name[0].toUpperCase() : 'T',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.skyBlue),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textLight),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      t.email,
                      style: const TextStyle(fontSize: 11, color: AppColors.slate500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${t.batchesCount} Batches • ${t.classesCount} Classes',
                style: const TextStyle(fontSize: 11, color: AppColors.slate500),
              ),
              if (t.isActive)
                TextButton.icon(
                  onPressed: () async {
                    final confirmed = await ConfirmDialog.show(
                      context,
                      title: 'Suspend Faculty Access',
                      message: 'Are you sure you want to suspend ${t.name}? Their active sessions will be terminated.',
                      confirmText: 'Suspend',
                      isDestructive: true,
                    );
                    if (confirmed == true) {
                      await ref.read(adminTeachersProvider.notifier).toggleTeacherStatus(t.id, t.status);
                    }
                  },
                  icon: const Icon(Icons.block, size: 14, color: AppColors.liveRed),
                  label: const Text('Suspend', style: TextStyle(color: AppColors.liveRed, fontSize: 11, fontWeight: FontWeight.bold)),
                )
              else if (t.isSuspended)
                TextButton.icon(
                  onPressed: () async {
                    final confirmed = await ConfirmDialog.show(
                      context,
                      title: 'Reactivate Faculty Access',
                      message: 'Reactivate ${t.name}? They will be permitted to log in and teach.',
                      confirmText: 'Reactivate',
                    );
                    if (confirmed == true) {
                      await ref.read(adminTeachersProvider.notifier).toggleTeacherStatus(t.id, t.status);
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 14, color: AppColors.success),
                  label: const Text('Reactivate', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
                )
              else if (t.isInvited)
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: 'Join as faculty on Classora! Check email: ${t.email}'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Faculty invite info for ${t.name} copied!')),
                    );
                  },
                  icon: const Icon(Icons.share, size: 12),
                  label: const Text('Share Info', style: TextStyle(fontSize: 11)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /* -------------------------------------------------------------------------- */
  /* TAB 2: BATCHES TAB                                                         */
  /* -------------------------------------------------------------------------- */
  Widget _buildBatchesTab() {
    final batchState = ref.watch(batchListProvider);

    return Column(
      children: [
        // Action Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Institute Batches (${batchState.batches.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textLight),
              ),
              ElevatedButton.icon(
                onPressed: _showCreateBatch,
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: const Text('Create Batch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.skyBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.borderLight),

        Expanded(
          child: batchState.batches.isEmpty
              ? EmptyState(
                  icon: Icons.school_outlined,
                  title: 'No cohorts created yet',
                  subtitle: 'Create batches for your institute and assign teachers or students.',
                  buttonText: 'Create Batch',
                  onAction: _showCreateBatch,
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  itemCount: batchState.batches.length,
                  itemBuilder: (context, idx) {
                    final b = batchState.batches[idx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  b.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textLight),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.skyBlueLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${b.activeStudentsCount} Students',
                                  style: const TextStyle(color: AppColors.skyBlue, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('${b.subject} • Join Code: ${b.joinCode}', style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: b.joinCode));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Join code ${b.joinCode} copied!')),
                                  );
                                },
                                icon: const Icon(Icons.copy, size: 14),
                                label: const Text('Copy Code', style: TextStyle(fontSize: 11)),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => BatchDetailScreen(batch: b)),
                                  );
                                },
                                icon: const Icon(Icons.info_outline, size: 14, color: Colors.white),
                                label: const Text('Batch Details', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.skyBlue,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => BatchStudentsDialog(batch: b),
                                  );
                                },
                                icon: const Icon(Icons.people_outline, size: 14),
                                label: const Text('Students', style: TextStyle(fontSize: 11)),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
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

  /* -------------------------------------------------------------------------- */
  /* TAB 3: MORE / SETTINGS TAB                                                 */
  /* -------------------------------------------------------------------------- */
  Widget _buildMoreTab() {
    final baseUrl = Endpoints.defaultBaseUrl;
    final adminWebUrl = baseUrl.contains('/api') ? baseUrl.replaceAll('/api', '/admin') : '$baseUrl/admin';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Institute Profile Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.skyBlueLight,
                  child: Icon(Icons.business_outlined, size: 30, color: AppColors.skyBlue),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.institute?.name ?? 'Classora Academy',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textLight),
                      ),
                      const SizedBox(height: 2),
                      Text('Admin: ${widget.user.email}', style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.skyBlueLight, borderRadius: BorderRadius.circular(4)),
                        child: const Text('FULL ACCESS • ADMIN', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.skyBlue)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Administration Modules
          const Text('Administrative Modules', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textLight)),
          const SizedBox(height: 8),

          _buildModuleTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Fee Management & Dues',
            subtitle: 'Overview of student fee plans and collected dues',
            onTap: () => context.push('/fees'),
          ),
          _buildModuleTile(
            icon: Icons.calendar_today_outlined,
            title: 'Attendance Records',
            subtitle: 'View live class and session attendance tracking',
            onTap: () => context.push('/attendance'),
          ),
          _buildModuleTile(
            icon: Icons.videocam_outlined,
            title: 'Class Recordings',
            subtitle: 'Published class recordings and video library',
            onTap: () => context.push('/recordings'),
          ),
          _buildModuleTile(
            icon: Icons.menu_book_outlined,
            title: 'Study Materials & Assignments',
            subtitle: 'Manage curricular documents and student homework',
            onTap: () => context.push('/assignments'),
          ),
          _buildModuleTile(
            icon: Icons.help_outline_rounded,
            title: 'Help & Administrator Guide',
            subtitle: 'Onboarding walkthrough, security and admin FAQs',
            onTap: () => context.push('/help?role=ADMIN'),
          ),
          _buildModuleTile(
            icon: Icons.share_rounded,
            title: 'Branding, Links & Testimonials',
            subtitle: 'Curate YouTube/Telegram/WhatsApp channels and reviews',
            onTap: () => context.push('/institute-content'),
          ),

          const SizedBox(height: 20),

          // Web Admin Portal Link Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.skyBlue.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.laptop_mac_rounded, size: 20, color: AppColors.skyBlue),
                    SizedBox(width: 8),
                    Text('Web Admin Console', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textLight)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Access advanced institute billing, white-label branding, and CSV exports on desktop:',
                  style: TextStyle(fontSize: 12, color: AppColors.slate500, height: 1.3),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          adminWebUrl,
                          style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.skyBlue, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16, color: AppColors.skyBlue),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: adminWebUrl));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Web admin link copied to clipboard!')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Center(
            child: TextButton(
              onPressed: () async {
                final confirmed = await ConfirmDialog.show(
                  context,
                  title: 'Sign Out',
                  message: 'Are you sure you want to log out from the Administrator account?',
                  confirmText: 'Sign Out',
                  isDestructive: true,
                );
                if (confirmed == true) {
                  ref.read(authStateProvider.notifier).logout();
                }
              },
              child: const Text('Sign Out', style: TextStyle(color: AppColors.liveRed, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),

          const SizedBox(height: 16),
          const Center(
            child: Text('Version 2.0.0 • Classora Education Systems', style: TextStyle(color: AppColors.slate400, fontSize: 11)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildModuleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: ListTile(
        onTap: onTap,
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.skyBlueLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.skyBlue),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textLight)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.slate500)),
        trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.slate400),
      ),
    );
  }
}
