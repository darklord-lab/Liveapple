import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../data/mock_data.dart';
import '../classroom/live_classroom_screen.dart';
import '../classroom/components/document_viewer.dart';

class StudentDashboard extends StatefulWidget {
  final UserSession user;
  final VoidCallback onLogout;

  const StudentDashboard({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentTabIndex = 0; // 0: Home, 1: Learning, 2: Profile
  String _learningSection = 'live'; // 'live', 'courses', 'notes', 'recordings'
  bool _isInLiveClass = false;
  bool _isViewingDocument = false;

  final List<CourseItem> _courses = MockData.courses;
  final List<LiveClassItem> _liveClasses = MockData.liveClasses;

  DocumentItem? _selectedDocument;

  @override
  Widget build(BuildContext context) {
    if (_isInLiveClass) {
      return LiveClassroomScreen(
        user: widget.user,
        onExit: () => setState(() => _isInLiveClass = false),
      );
    }

    if (_isViewingDocument) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) setState(() => _isViewingDocument = false);
        },
        child: Scaffold(
          body: SafeArea(
            child: DocumentViewer(
              initialDocument: _selectedDocument,
              onClose: () => setState(() => _isViewingDocument = false),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.indigo600,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Text('C', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CLASSORA',
                  style: TextStyle(color: AppColors.slate900, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
                Text(
                  widget.user.batchOrDept,
                  style: const TextStyle(color: AppColors.slate500, fontSize: 10, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(widget.user.avatar),
              backgroundColor: AppColors.slate200,
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          _buildHomeTab(),
          _buildLearningHubTab(),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) => setState(() => _currentTabIndex = index),
        selectedItemColor: AppColors.indigo600,
        unselectedItemColor: AppColors.slate400,
        backgroundColor: Colors.white,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_rounded),
            label: 'Learning Hub',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // Home Tab
  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.indigo900, AppColors.indigo700],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.indigo700.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Welcome back, ${widget.user.name.split(' ').first}! 👋',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('JEE 2026', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your daily attendance is 96.4% • Rank #1 in Physics Batch',
                  style: TextStyle(color: AppColors.indigo200, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Live Lecture Now Alert Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.rose500.withOpacity(0.4)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.rose500.withOpacity(0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.rose600,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fiber_manual_record_rounded, size: 8, color: Colors.white),
                          SizedBox(width: 4),
                          Text('LIVE NOW', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Department of Physics', style: TextStyle(color: AppColors.slate500, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Rotational Dynamics & Torque Masterclass',
                  style: TextStyle(color: AppColors.slate900, fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Prof. Rajesh Sharma • 34 Students Joined',
                  style: TextStyle(color: AppColors.slate500, fontSize: 12),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _isInLiveClass = true),
                    icon: const Icon(Icons.videocam_rounded, size: 18),
                    label: const Text('Join Live Masterclass', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.indigo600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Enrolled Courses Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Enrolled Courses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.slate900)),
              TextButton(
                onPressed: () {
                  setState(() {
                    _currentTabIndex = 1;
                    _learningSection = 'courses';
                  });
                },
                child: const Text('View All', style: TextStyle(color: AppColors.indigo600, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Course Cards
          ..._courses.take(2).map((c) => _buildCourseCard(c)),
        ],
      ),
    );
  }

  // Learning Hub Tab
  Widget _buildLearningHubTab() {
    return Column(
      children: [
        // Sub-sections header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: Colors.white,
          child: Row(
            children: [
              _learningSubTab('live', 'Live Classes', Icons.live_tv_rounded),
              _learningSubTab('courses', 'Courses', Icons.school_rounded),
              _learningSubTab('notes', 'Notes & PPT', Icons.menu_book_rounded),
              _learningSubTab('recordings', 'Recordings', Icons.play_circle_fill_rounded),
            ],
          ),
        ),

        // Body content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _learningSection == 'live'
                ? _buildLiveSection()
                : (_learningSection == 'courses'
                    ? _buildCoursesSection()
                    : (_learningSection == 'notes' ? _buildNotesSection() : _buildRecordingsSection())),
          ),
        ),
      ],
    );
  }

  Widget _learningSubTab(String id, String label, IconData icon) {
    final isSel = _learningSection == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _learningSection = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? AppColors.indigo50 : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSel ? Border.all(color: AppColors.indigo200) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: isSel ? AppColors.indigo600 : AppColors.slate400),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                  color: isSel ? AppColors.indigo700 : AppColors.slate500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._liveClasses.map((item) {
          final isLive = item.isLive;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isLive ? AppColors.rose400 : AppColors.slate200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
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
                        color: isLive ? AppColors.rose600 : AppColors.slate100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isLive ? 'LIVE NOW' : 'SCHEDULED',
                        style: TextStyle(
                          color: isLive ? Colors.white : AppColors.slate700,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(item.time, style: const TextStyle(color: AppColors.slate500, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.title,
                  style: const TextStyle(color: AppColors.slate900, fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.subject} • ${item.teacher}',
                  style: const TextStyle(color: AppColors.slate500, fontSize: 12),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: isLive ? () => setState(() => _isInLiveClass = true) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.indigo600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(isLive ? 'Join Live Lecture' : 'Starts at ${item.time}'),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCoursesSection() {
    return Column(
      children: _courses.map((c) => _buildCourseCard(c)).toList(),
    );
  }

  Widget _buildNotesSection() {
    final docs = MockData.sampleDocuments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Academic Lecture Notes & Curriculum PPT/PDF Decks',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.slate900),
        ),
        const SizedBox(height: 12),
        ...docs.map((doc) {
          final isPpt = doc.type.contains('PPT');
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isPpt ? AppColors.indigo200 : AppColors.slate200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPpt ? AppColors.indigo100 : AppColors.emerald50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        doc.type.toUpperCase(),
                        style: TextStyle(
                          color: isPpt ? AppColors.indigo800 : AppColors.emerald800,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text('${doc.slides.length} Slides', style: const TextStyle(color: AppColors.slate500, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  doc.title,
                  style: const TextStyle(color: AppColors.slate900, fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '${doc.author} • ${doc.fileName}',
                  style: const TextStyle(color: AppColors.slate500, fontSize: 11),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedDocument = doc;
                            _isViewingDocument = true;
                          });
                        },
                        icon: Icon(isPpt ? Icons.slideshow_rounded : Icons.picture_as_pdf_rounded, size: 16),
                        label: Text(
                          isPpt ? 'Open Interactive PPT Deck' : 'Open & View PDF Document',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPpt ? AppColors.indigo600 : AppColors.emerald600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRecordingsSection() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.video_library_rounded, size: 48, color: AppColors.slate300),
            SizedBox(height: 12),
            Text('No archived recordings yet', style: TextStyle(color: AppColors.slate600, fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text('Completed live lectures will appear here automatically', style: TextStyle(color: AppColors.slate400, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(CourseItem c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              c.image,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.indigo50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(c.subject, style: const TextStyle(color: AppColors.indigo700, fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                    Text('${c.progress}% Completed', style: const TextStyle(color: AppColors.emerald600, fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  c.title,
                  style: const TextStyle(color: AppColors.slate900, fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text('Instructor: ${c.instructor}', style: const TextStyle(color: AppColors.slate500, fontSize: 11)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: c.progress / 100,
                    minHeight: 6,
                    backgroundColor: AppColors.slate100,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.emerald500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Profile Tab
  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundImage: NetworkImage(widget.user.avatar),
            backgroundColor: AppColors.slate200,
          ),
          const SizedBox(height: 12),
          Text(
            widget.user.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.slate900),
          ),
          Text(
            widget.user.email,
            style: const TextStyle(fontSize: 12, color: AppColors.slate500),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.indigo50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.indigo200),
            ),
            child: Text(
              widget.user.batchOrDept,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.indigo700),
            ),
          ),
          const SizedBox(height: 24),

          // Details List
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Column(
              children: [
                _profileDetailItem('Student ID', 'APX-2025-042', Icons.badge_outlined),
                const Divider(height: 1),
                _profileDetailItem('Attendance Rate', '96.4%', Icons.check_circle_outline),
                const Divider(height: 1),
                _profileDetailItem('Batch Rank', '#1 / 32 in Physics', Icons.emoji_events_outlined),
                const Divider(height: 1),
                _profileDetailItem('Enrolled Since', 'August 2025', Icons.calendar_today_outlined),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Logout Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: widget.onLogout,
              icon: const Icon(Icons.logout_rounded, size: 16, color: AppColors.rose600),
              label: const Text('Log Out of Classora', style: TextStyle(color: AppColors.rose600, fontSize: 13, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.rose200),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileDetailItem(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.slate400),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 13, color: AppColors.slate600, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.slate900)),
        ],
      ),
    );
  }
}
