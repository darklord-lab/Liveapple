import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/domain/user_model.dart';
import '../../batch/presentation/batch_controller.dart';
import '../../batch/presentation/join_batch_dialog.dart';
import '../../timetable/presentation/timetable_controller.dart';
import '../../timetable/domain/timetable_model.dart';
import '../../liveclass/presentation/live_class_controller.dart';
import '../../liveclass/domain/live_class_model.dart';
import '../../notifications/presentation/widgets/notification_bell_button.dart';
import '../../learning/presentation/screens/recordings_screen.dart';
import '../../learning/presentation/screens/assignments_screen.dart';
import '../../learning/presentation/screens/cbt_tests_screen.dart';

class StudentHomeScreen extends ConsumerStatefulWidget {
  final UserModel user;

  const StudentHomeScreen({super.key, required this.user});

  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen> with SingleTickerProviderStateMixin {
  int _currentBottomNavIndex = 0; // 0: Home, 1: Schedule, 2: Learn, 3: Profile
  int _learnSubTabIndex = 0; // 0: Material, 1: Recordings, 2: Assign, 3: Tests

  // Learn tab search & filters
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedSort = 'Newest'; // Newest, Oldest, Name A-Z
  String? _selectedFilterType; // 'PDF', 'Video', 'Link', 'Free only'
  final Set<String> _selectedFilterBatches = {};

  // Settings toggles (Panel 6)
  bool _classReminders = true;
  bool _liveAlerts = true;
  bool _homeworkAlerts = false;

  Timer? _fallbackPollingTimer;

  @override
  void initState() {
    super.initState();
    // 10-second fallback polling for live and upcoming classes (Phase C - C6)
    _fallbackPollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        ref.read(liveClassProvider.notifier).loadClasses();
      }
    });

    Future.microtask(() {
      ref.read(liveClassProvider.notifier).loadClasses();
      ref.read(batchListProvider.notifier).loadBatches();
      ref.read(timetableProvider.notifier).loadSlots();
    });
  }

  @override
  void dispose() {
    _fallbackPollingTimer?.cancel();
    _searchController.dispose();
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
    final coachingName = widget.user.effectiveCoachingName;
    final facultyName = widget.user.effectiveFacultyName;

    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        // Sky-blue App Bar matching reference
        appBar: AppBar(
        backgroundColor: AppColors.skyBlue,
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
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    coachingName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Faculty: $facultyName',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
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
    final instituteCode = (widget.user.institute != null && widget.user.institute!.id.length >= 6)
        ? widget.user.institute!.id.substring(0, 6).toUpperCase()
        : 'APEX24';

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
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.slate200,
                    child: Icon(Icons.person_outline, size: 36, color: AppColors.slate500),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textLight),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.user.effectiveCoachingName,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.skyBlue),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Faculty: ${widget.user.effectiveFacultyName} • Code: $instituteCode',
                          style: const TextStyle(fontSize: 11, color: AppColors.slate500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                  const Divider(color: AppColors.borderLight, height: 16),
                  _buildDrawerItem(
                    icon: Icons.person_outline,
                    label: 'Edit Profile',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _currentBottomNavIndex = 3;
                      });
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
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Classora share link copied to clipboard!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.skyBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Share app', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
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
                  child: _buildColouredTile(
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
                  child: _buildColouredTile(
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
                  child: _buildColouredTile(
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
                  child: _buildColouredTile(
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
                          Text('DPP 03 - Motion in 1D', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          SizedBox(height: 2),
                          Text('Assignment • due tomorrow 8 PM', style: TextStyle(color: AppColors.slate500, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF97316),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('PENDING', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 5. Connect with us Card
            InkWell(
              onTap: _showConnectDialog,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
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
                      child: const Icon(Icons.link, color: AppColors.skyBlue, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Connect with us', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        SizedBox(height: 2),
                        Text('YouTube • Telegram • WhatsApp', style: TextStyle(color: AppColors.slate500, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.liveRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.fiber_manual_record, color: Colors.white, size: 8),
                    SizedBox(width: 4),
                    Text('LIVE NOW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10)),
                  ],
                ),
              ),
              Text(
                '${cls.attendanceCount > 0 ? cls.attendanceCount : 32} joined',
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

  Widget _buildColouredTile({
    required String title,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 88,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    height: 1.2,
                  ),
                ),
                const Icon(Icons.arrow_forward, color: Colors.white, size: 14),
              ],
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
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
            '${_getFullDayName(selectedDayIndex)}, 12 Oct',
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
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 48, color: AppColors.slate400),
                        SizedBox(height: 12),
                        Text('No classes scheduled for this day', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Pull down to refresh', style: TextStyle(color: AppColors.slate500, fontSize: 12)),
                      ],
                    ),
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

                        return _buildScheduleItemCard(
                          startTime: TimetableSlotModel.formatMinutes(slot.startMin),
                          endTime: TimetableSlotModel.formatMinutes(slot.endMin),
                          title: slot.subject != null ? '${slot.subject} - Session' : 'Scheduled Class',
                          subtitle: '${slot.batchName ?? 'Batch'} • ${slot.subject ?? 'Subject'}',
                          teacher: slot.teacherName ?? 'Faculty',
                          status: matchingClass?.isLive == true
                              ? 'LIVE'
                              : (idx == 0 ? 'ENDED' : 'UPCOMING'),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.liveRed, borderRadius: BorderRadius.circular(6)),
                  child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 28,
                  child: ElevatedButton(
                    onPressed: () {
                      if (liveClassId != null) context.push('/live/$liveClassId');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.skyBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Join', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ] else if (status == 'ENDED') ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.slate200, borderRadius: BorderRadius.circular(6)),
              child: const Text('ENDED', style: TextStyle(color: AppColors.slate500, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ] else ...[
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.skyBlueLight, borderRadius: BorderRadius.circular(6)),
                  child: const Text('UPCOMING', style: TextStyle(color: AppColors.skyBlue, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 28,
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reminder set: You will be notified 15 minutes prior.')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      side: const BorderSide(color: AppColors.skyBlue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Remind me', style: TextStyle(fontSize: 10, color: AppColors.skyBlue, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
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
        // 4 Sub-Tabs Bar (MATERIAL, RECORDINGS, ASSIGN., TESTS)
        Container(
          color: Colors.white,
          child: Row(
            children: [
              _buildSubTabHeader('MATERIAL', 0),
              _buildSubTabHeader('RECORDINGS', 1),
              _buildSubTabHeader('ASSIGN.', 2),
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
    );
  }

  Widget _buildStudyMaterialSubTab() {
    // Sample material items matching reference screenshot
    final materials = [
      {
        'title': 'Physics Notes',
        'subtitle': 'Folder • Prof. Rajesh Sharma',
        'type': 'folder',
        'batch': 'Class 12 JEE - Physics',
        'isFree': false,
        'size': '',
      },
      {
        'title': 'Kinematics Formula Sheet',
        'subtitle': 'PDF • 1.2 MB • 10 Oct',
        'type': 'pdf',
        'batch': 'Class 12 JEE - Physics',
        'isFree': true,
        'size': '1.2 MB',
      },
      {
        'title': 'DPP 01 - Motion in 1D.pdf',
        'subtitle': 'PDF • 640 KB • 9 Oct',
        'type': 'pdf',
        'batch': 'Class 12 JEE - Physics',
        'isFree': false,
        'size': '640 KB',
      },
      {
        'title': 'Revision Lecture (link)',
        'subtitle': 'Video link • Prof. Anita Verma',
        'type': 'video',
        'batch': 'Class 12 JEE - Maths',
        'isFree': false,
        'size': '',
      },
    ];

    // Filter by query and filters
    final filtered = materials.where((m) {
      if (_searchQuery.isNotEmpty && !m['title']!.toString().toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (_selectedFilterType != null) {
        if (_selectedFilterType == 'Free only' && m['isFree'] != true) return false;
        if (_selectedFilterType == 'PDF' && m['type'] != 'pdf') return false;
        if (_selectedFilterType == 'Video' && m['type'] != 'video') return false;
      }
      if (_selectedFilterBatches.isNotEmpty && !_selectedFilterBatches.contains(m['batch'])) {
        return false;
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Search & Filter Row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search material',
                      hintStyle: TextStyle(color: AppColors.slate400, fontSize: 13),
                      prefixIcon: Icon(Icons.search, color: AppColors.slate400, size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Funnel Button opening Panel 5 Filter Sheet
              IconButton(
                icon: const Icon(Icons.filter_list, color: AppColors.skyBlue),
                tooltip: 'Filters',
                onPressed: _showFilterSheet,
              ),
            ],
          ),
        ),

        // Count & Sort row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL (${filtered.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.slate500),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (_selectedSort == 'Newest') {
                      _selectedSort = 'Oldest';
                    } else if (_selectedSort == 'Oldest') {
                      _selectedSort = 'Name A-Z';
                    } else {
                      _selectedSort = 'Newest';
                    }
                  });
                },
                child: Row(
                  children: [
                    const Icon(Icons.swap_vert, size: 16, color: AppColors.slate500),
                    const SizedBox(width: 4),
                    Text(
                      'SORT ($_selectedSort)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.slate500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Divider(color: AppColors.borderLight, height: 12),

        // Material Items List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, idx) {
              final item = filtered[idx];
              final isFolder = item['type'] == 'folder';
              final isPdf = item['type'] == 'pdf';
              final isFree = item['isFree'] == true;

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    // Icon
                    if (isFolder)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.folder, color: Colors.amber, size: 22),
                      )
                    else if (isPdf)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 22),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.skyBlueLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.videocam, color: AppColors.skyBlue, size: 22),
                      ),
                    const SizedBox(width: 12),

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item['title'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isFree)
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.success,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text('FREE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['subtitle'] as String,
                            style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.slate400),
                  ],
                ),
              );
            },
          ),
        ),

        // Hint Footer
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Filter by batch / subject using the funnel',
            style: TextStyle(color: AppColors.slate400, fontSize: 11),
          ),
        ),
      ],
    );
  }

  /* -------------------------------------------------------------------------- */
  /* PANEL 5: FILTER SHEET MODAL                                                */
  /* -------------------------------------------------------------------------- */
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final batches = ['Class 12 JEE - Physics', 'Class 12 JEE - Maths', 'Class 11 NEET - Chemistry'];
            final types = ['PDF', 'Video', 'Link', 'Free only'];
            final sortOptions = ['Newest', 'Oldest', 'Name A-Z'];

            return Container(
              padding: const EdgeInsets.all(20),
              height: 520,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                          const SizedBox(width: 8),
                          const Text('FILTERS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            _selectedFilterBatches.clear();
                            _selectedFilterType = null;
                            _selectedSort = 'Newest';
                          });
                          setState(() {});
                        },
                        child: const Text('CLEAR', style: TextStyle(color: AppColors.slate500, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Divider(),

                  // Section BATCH
                  const Text('BATCH', style: TextStyle(color: AppColors.slate500, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  ...batches.map((b) {
                    final isChecked = _selectedFilterBatches.contains(b);
                    return CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(b, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      value: isChecked,
                      activeColor: AppColors.skyBlue,
                      onChanged: (val) {
                        setSheetState(() {
                          if (val == true) {
                            _selectedFilterBatches.add(b);
                          } else {
                            _selectedFilterBatches.remove(b);
                          }
                        });
                        setState(() {});
                      },
                    );
                  }),

                  const SizedBox(height: 10),

                  // Section TYPE
                  const Text('TYPE', style: TextStyle(color: AppColors.slate500, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: types.map((t) {
                      final isSelected = _selectedFilterType == t;
                      return ChoiceChip(
                        label: Text(t, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppColors.slate700)),
                        selected: isSelected,
                        selectedColor: AppColors.skyBlue,
                        backgroundColor: AppColors.slate100,
                        onSelected: (val) {
                          setSheetState(() {
                            _selectedFilterType = val ? t : null;
                          });
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 12),

                  // Section SORT BY
                  const Text('SORT BY', style: TextStyle(color: AppColors.slate500, fontSize: 11, fontWeight: FontWeight.bold)),
                  Row(
                    children: sortOptions.map((s) {
                      return Row(
                        children: [
                          Radio<String>(
                            value: s,
                            groupValue: _selectedSort,
                            activeColor: AppColors.skyBlue,
                            onChanged: (val) {
                              setSheetState(() {
                                _selectedSort = val!;
                              });
                              setState(() {});
                            },
                          ),
                          Text(s, style: const TextStyle(fontSize: 12)),
                        ],
                      );
                    }).toList(),
                  ),

                  const Spacer(),

                  // Full-width Apply Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.skyBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('APPLY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /* -------------------------------------------------------------------------- */
  /* PANEL 6: SETTINGS / PROFILE TAB                                            */
  /* -------------------------------------------------------------------------- */
  Widget _buildSettingsTab() {
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
                  child: Text(
                    widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.skyBlue),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.user.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(widget.user.email, style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.skyBlueLight, borderRadius: BorderRadius.circular(4)),
                        child: Text(
                          widget.user.role,
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile edit details will sync with institute portal')),
              );
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
            },
          ),
          const Divider(height: 1, color: AppColors.borderLight),

          _buildSettingsTile(
            title: 'Notification permission',
            subtitle: 'Allowed • open system settings',
            trailing: const Icon(Icons.chevron_right, color: AppColors.slate400),
            onTap: () {},
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
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Classora share link copied to clipboard!')),
                    );
                  },
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
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Thank you for rating Classora!')),
                    );
                  },
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
              onPressed: () => ref.read(authStateProvider.notifier).logout(),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('How to use Classora'),
        content: const Text(
          '1. Home: View live classes and quick access to study modules.\n'
          '2. Schedule: Check timetable and upcoming sessions.\n'
          '3. Learn: Access notes, homework, CBT quizzes, and recordings.\n'
          '4. Join Class: Tap Join to enter the pre-join lobby and configure your mic & camera.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it')),
        ],
      ),
    );
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Connect with us'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(leading: Icon(Icons.play_circle_filled, color: Colors.red), title: Text('YouTube Channel')),
            ListTile(leading: Icon(Icons.telegram, color: Colors.blue), title: Text('Telegram Group')),
            ListTile(leading: Icon(Icons.chat, color: Colors.green), title: Text('WhatsApp Support')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}
