import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/domain/user_model.dart';
import '../../batch/presentation/batch_controller.dart';
import '../../batch/presentation/create_batch_dialog.dart';
import '../../batch/presentation/batch_students_dialog.dart';
import '../../timetable/presentation/timetable_controller.dart';
import '../../timetable/presentation/add_timetable_slot_dialog.dart';
import '../../timetable/domain/timetable_model.dart';
import '../../liveclass/presentation/live_class_controller.dart';
import '../../liveclass/domain/live_class_model.dart';
import '../../notifications/presentation/widgets/notification_bell_button.dart';

class TeacherHomeScreen extends ConsumerStatefulWidget {
  final UserModel user;

  const TeacherHomeScreen({super.key, required this.user});

  @override
  ConsumerState<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends ConsumerState<TeacherHomeScreen> {
  int _currentBottomNavIndex = 0; // 0: Home, 1: Timetable, 2: Batches, 3: Profile
  bool _showPastClasses = false;

  // Settings switches
  bool _classReminders = true;
  bool _liveAlerts = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(batchListProvider.notifier).loadBatches();
      ref.read(timetableProvider.notifier).loadSlots();
      ref.read(liveClassProvider.notifier).loadClasses();
    });
  }

  void _showCreateBatch() {
    showDialog(
      context: context,
      builder: (ctx) => const CreateBatchDialog(),
    );
  }

  void _showAddSlot({String? batchId, int? day}) {
    showDialog(
      context: context,
      builder: (ctx) => AddTimetableSlotDialog(
        preselectedBatchId: batchId,
        preselectedDay: day,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final instituteName = widget.user.institute?.name ?? 'Apex IIT-JEE Academy';

    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        // Sky-blue App Bar matching Reference UI
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
        title: Text(
          _currentBottomNavIndex == 0
              ? instituteName
              : _currentBottomNavIndex == 1
                  ? 'Timetable Manager'
                  : _currentBottomNavIndex == 2
                      ? 'My Batches'
                      : 'Faculty Profile',
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
      // Drawer matching Reference UI
      drawer: _buildDrawer(),
      body: IndexedStack(
        index: _currentBottomNavIndex,
        children: [
          _buildHomeTab(),
          _buildTimetableTab(),
          _buildBatchesTab(),
          _buildProfileTab(),
        ],
      ),
      // 4-Tab Bottom Navigation Bar
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
          onTap: (idx) {
            setState(() {
              _currentBottomNavIndex = idx;
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
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: 'Timetable'),
            BottomNavigationBarItem(icon: Icon(Icons.school_outlined), label: 'Batches'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      ),
    ),
  );
  }

  /* -------------------------------------------------------------------------- */
  /* DRAWER (FACULTY)                                                           */
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
                        const SizedBox(height: 3),
                        Text(
                          'Faculty • Code $instituteCode',
                          style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    icon: Icons.school_outlined,
                    label: 'My Batches',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentBottomNavIndex = 2);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.calendar_month_outlined,
                    label: 'Timetable Manager',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentBottomNavIndex = 1);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.sensors,
                    label: 'Live Classes',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentBottomNavIndex = 0);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.edit_note_outlined,
                    label: 'Assignments',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/assignments');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.videocam_outlined,
                    label: 'Recordings',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/recordings');
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
                  const Divider(color: AppColors.borderLight, height: 16),
                  _buildDrawerItem(
                    icon: Icons.person_outline,
                    label: 'Profile',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentBottomNavIndex = 3);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.help_outline,
                    label: 'Help / Faculty Guide',
                    onTap: () {
                      Navigator.pop(context);
                      _showHelpDialog();
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
                      const SnackBar(content: Text('Classora Faculty invite link copied!')),
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
  /* TAB 0: HOME TAB (FACULTY)                                                  */
  /* -------------------------------------------------------------------------- */
  Widget _buildHomeTab() {
    final liveClassState = ref.watch(liveClassProvider);
    final activeLiveClass = liveClassState.classes.cast<LiveClassModel?>().firstWhere(
          (c) => c != null && c.isLive,
          orElse: () => null,
        );
    final upcoming = liveClassState.classes.where((c) => !c.isEnded).toList();

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
            // 1. Hero Card (Start Live Class / Go Live)
            if (activeLiveClass != null)
              _buildTeacherLiveHero(activeLiveClass)
            else if (upcoming.isNotEmpty)
              _buildTeacherUpcomingHero(upcoming.first)
            else
              _buildTeacherDefaultHero(),

            const SizedBox(height: 18),

            // 2. Quick Access (2x2 Coloured Tiles)
            const Text(
              'Quick access',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textLight),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildColouredTile(
                    title: 'Start\nLive Class',
                    color: AppColors.tileSchedule,
                    icon: Icons.sensors,
                    onTap: () {
                      if (upcoming.isNotEmpty) {
                        _startOrEnterClass(upcoming.first);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please schedule a class from Timetable or Batches first')),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildColouredTile(
                    title: 'My\nBatches',
                    color: AppColors.tileMaterial,
                    icon: Icons.school,
                    onTap: () => setState(() => _currentBottomNavIndex = 2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildColouredTile(
                    title: 'Timetable\nSlots',
                    color: AppColors.tileRecordings,
                    icon: Icons.calendar_month,
                    onTap: () => setState(() => _currentBottomNavIndex = 1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildColouredTile(
                    title: 'Create\nBatch',
                    color: AppColors.tileBatches,
                    icon: Icons.add_circle_outline,
                    onTap: _showCreateBatch,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // 3. Learning Hub Quick Chips
            const Text(
              'Faculty Modules',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textLight),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickModuleChip(icon: Icons.edit_note, label: 'Assignments', color: Colors.purple, route: '/assignments'),
                  const SizedBox(width: 8),
                  _buildQuickModuleChip(icon: Icons.quiz_outlined, label: 'CBT Quizzes', color: Colors.teal, route: '/tests'),
                  const SizedBox(width: 8),
                  _buildQuickModuleChip(icon: Icons.videocam_outlined, label: 'Recordings', color: AppColors.skyBlue, route: '/recordings'),
                  const SizedBox(width: 8),
                  _buildQuickModuleChip(icon: Icons.how_to_reg_outlined, label: 'Attendance', color: AppColors.success, route: '/attendance'),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // 4. Scheduled Classes for Faculty
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Scheduled Classes',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textLight),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showPastClasses = !_showPastClasses;
                    });
                  },
                  child: Text(
                    _showPastClasses ? 'Hide Past' : 'Show Past',
                    style: const TextStyle(fontSize: 12, color: AppColors.skyBlue, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (liveClassState.isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (upcoming.isEmpty && !_showPastClasses)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Center(
                  child: Text(
                    'No pending classes. Use Timetable tab to add slots.',
                    style: TextStyle(color: AppColors.slate500, fontSize: 13),
                  ),
                ),
              )
            else
              ...(_showPastClasses ? liveClassState.classes : upcoming).map((cls) => _buildClassCard(cls)),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherLiveHero(LiveClassModel cls) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.liveRed.withValues(alpha: 0.4)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.liveRed, borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  children: [
                    Icon(Icons.fiber_manual_record, color: Colors.white, size: 8),
                    SizedBox(width: 4),
                    Text('YOU ARE LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10)),
                  ],
                ),
              ),
              Text('${cls.attendanceCount} Students Connected', style: const TextStyle(fontSize: 11, color: AppColors.slate500)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cls.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(cls.batchName ?? 'Batch', style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => context.push('/live/${cls.id}'),
                icon: const Icon(Icons.videocam, size: 16, color: Colors.white),
                label: const Text('Enter Room', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.liveRed),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherUpcomingHero(LiveClassModel cls) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.skyBlue.withValues(alpha: 0.3)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
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
                    decoration: BoxDecoration(color: AppColors.skyBlueLight, borderRadius: BorderRadius.circular(12)),
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
                    Text(cls.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(cls.batchName ?? 'Batch', style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _startOrEnterClass(cls),
                icon: const Icon(Icons.play_arrow, size: 16, color: Colors.white),
                label: const Text('Start Class', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.skyBlue),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherDefaultHero() {
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
            decoration: const BoxDecoration(color: AppColors.skyBlueLight, shape: BoxShape.circle),
            child: const Icon(Icons.school, color: AppColors.skyBlue, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Faculty Command Center', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                SizedBox(height: 2),
                Text('Schedule classes, broadcast live, and track student mastery', style: TextStyle(fontSize: 12, color: AppColors.slate500)),
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
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 3))],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, height: 1.2)),
                const Icon(Icons.arrow_forward, color: Colors.white, size: 14),
              ],
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickModuleChip({
    required IconData icon,
    required String label,
    required Color color,
    required String route,
  }) {
    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildClassCard(LiveClassModel cls) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cls.isLive ? AppColors.liveRed : AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: cls.isLive ? AppColors.liveRed : AppColors.skyBlueLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              cls.isLive ? 'LIVE' : cls.status,
              style: TextStyle(color: cls.isLive ? Colors.white : AppColors.skyBlue, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cls.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${cls.batchName ?? 'Batch'} • ${cls.formattedDate} • ${cls.formattedTime}', style: const TextStyle(fontSize: 11, color: AppColors.slate500)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _startOrEnterClass(cls),
            style: ElevatedButton.styleFrom(
              backgroundColor: cls.isLive ? AppColors.liveRed : AppColors.skyBlue,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: Text(cls.isLive ? 'Enter' : 'Start', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _startOrEnterClass(LiveClassModel cls) async {
    if (!cls.isLive) {
      final success = await ref.read(liveClassProvider.notifier).startClass(cls.id);
      if (success != null && mounted) {
        context.push('/live/${cls.id}');
      }
    } else {
      context.push('/live/${cls.id}');
    }
  }

  /* -------------------------------------------------------------------------- */
  /* TAB 1: TIMETABLE MANAGER                                                   */
  /* -------------------------------------------------------------------------- */
  Widget _buildTimetableTab() {
    final timetableState = ref.watch(timetableProvider);
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final selectedDayIndex = timetableState.selectedDay;
    final currentDaySlots = timetableState.slots.where((s) => s.dayOfWeek == selectedDayIndex).toList();

    return Column(
      children: [
        // Day selector strip
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
                        border: Border.all(color: isSelected ? Colors.black87 : AppColors.borderLight),
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

        // Action Bar: Add Slot
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${days[selectedDayIndex]} Schedule (${currentDaySlots.length} slots)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddSlot(day: selectedDayIndex),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Slot', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.skyBlue),
              ),
            ],
          ),
        ),

        // Slots List
        Expanded(
          child: currentDaySlots.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.alarm_off_outlined, size: 48, color: AppColors.slate400),
                      const SizedBox(height: 10),
                      Text('No slots scheduled for ${days[selectedDayIndex]}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => _showAddSlot(day: selectedDayIndex),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.skyBlue),
                        child: const Text('Schedule Slot Now'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  itemCount: currentDaySlots.length,
                  itemBuilder: (context, idx) {
                    final slot = currentDaySlots[idx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.skyBlueLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(TimetableSlotModel.formatMinutes(slot.startMin), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.skyBlue)),
                                Text('to ${TimetableSlotModel.formatMinutes(slot.endMin)}', style: const TextStyle(fontSize: 9, color: AppColors.skyBlue)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(slot.batchName ?? 'Batch', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('${slot.subject ?? 'Subject'} • ${slot.durationString}', style: const TextStyle(fontSize: 11, color: AppColors.slate500)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.liveRed, size: 20),
                            onPressed: () async {
                              await ref.read(timetableProvider.notifier).deleteSlot(slot.id);
                            },
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
  /* TAB 2: MY BATCHES                                                          */
  /* -------------------------------------------------------------------------- */
  Widget _buildBatchesTab() {
    final batchState = ref.watch(batchListProvider);

    return Column(
      children: [
        // Action Bar: Create Batch
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Cohort Batches (${batchState.batches.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textLight)),
              ElevatedButton.icon(
                onPressed: _showCreateBatch,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Create Batch', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.skyBlue),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.borderLight),

        Expanded(
          child: batchState.batches.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.school_outlined, size: 52, color: AppColors.slate400),
                      const SizedBox(height: 12),
                      const Text('No batches created yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textLight)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _showCreateBatch,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.skyBlue),
                        child: const Text('Create First Batch'),
                      ),
                    ],
                  ),
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
                              Text(b.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textLight)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: AppColors.skyBlueLight, borderRadius: BorderRadius.circular(6)),
                                child: Text('${b.activeStudentsCount} Students', style: const TextStyle(color: AppColors.skyBlue, fontSize: 10, fontWeight: FontWeight.bold)),
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
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => BatchStudentsDialog(batch: b),
                                  );
                                },
                                icon: const Icon(Icons.people_outline, size: 14),
                                label: const Text('Students', style: TextStyle(fontSize: 11)),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.skyBlue),
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
  /* TAB 3: PROFILE / SETTINGS                                                  */
  /* -------------------------------------------------------------------------- */
  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
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
                    widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : 'F',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.skyBlue),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                      const SizedBox(height: 2),
                      Text(widget.user.email, style: const TextStyle(fontSize: 13, color: AppColors.slate500)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.skyBlueLight, borderRadius: BorderRadius.circular(4)),
                        child: const Text('FACULTY / TEACHER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.skyBlue)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Settings Switches
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Class schedule reminders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textLight)),
            subtitle: const Text('Notify 15m prior to scheduled sessions', style: TextStyle(fontSize: 12, color: AppColors.slate500)),
            trailing: Switch(
              value: _classReminders,
              activeColor: AppColors.skyBlue,
              onChanged: (v) => setState(() => _classReminders = v),
            ),
          ),
          const Divider(height: 1, color: AppColors.borderLight),

          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Live alert broadcasts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textLight)),
            subtitle: const Text('Notify students automatically when starting class', style: TextStyle(fontSize: 12, color: AppColors.slate500)),
            trailing: Switch(
              value: _liveAlerts,
              activeColor: AppColors.skyBlue,
              onChanged: (v) => setState(() => _liveAlerts = v),
            ),
          ),
          const Divider(height: 1, color: AppColors.borderLight),

          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Faculty Guide & Resources', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textLight)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.slate400),
            onTap: _showHelpDialog,
          ),
          const Divider(height: 1, color: AppColors.borderLight),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Classora Faculty share link copied!')));
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
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thank you for rating Classora!')));
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

          Center(
            child: TextButton(
              onPressed: () => ref.read(authStateProvider.notifier).logout(),
              child: const Text('Sign Out', style: TextStyle(color: AppColors.liveRed, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),

          const SizedBox(height: 20),
          const Center(
            child: Text('Version 2.0.0 • Classora Education Systems', style: TextStyle(color: AppColors.slate400, fontSize: 11)),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Faculty Help & Guide'),
        content: const Text(
          '1. Home: View active live sessions and start teaching.\n'
          '2. Timetable: Add recurring slots. Conflict detection prevents overlapping sessions.\n'
          '3. Batches: Create batch cohorts and share unique join codes.\n'
          '4. Live Classroom: Full whiteboard, student audio/video feeds, and interactive chat.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it')),
        ],
      ),
    );
  }
}
