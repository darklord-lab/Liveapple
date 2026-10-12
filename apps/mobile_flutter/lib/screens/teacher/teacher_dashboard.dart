import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../data/mock_data.dart';
import '../classroom/live_classroom_screen.dart';
import '../classroom/components/document_viewer.dart';

class TeacherDashboard extends StatefulWidget {
  final UserSession user;
  final VoidCallback onLogout;

  const TeacherDashboard({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _currentTabIndex = 0; // 0: Home, 1: Classes, 2: Materials, 3: Enroll, 4: Profile
  bool _isInLiveClass = false;
  bool _isViewingDocument = false;

  final List<LiveClassItem> _classes = List.from(MockData.liveClasses);
  final List<ParticipantItem> _students = List.from(MockData.participants);

  // New Student Form
  final _studentNameController = TextEditingController();
  final _studentEmailController = TextEditingController();
  final _studentRollController = TextEditingController();
  bool _studentAddedSuccess = false;

  @override
  void dispose() {
    _studentNameController.dispose();
    _studentEmailController.dispose();
    _studentRollController.dispose();
    super.dispose();
  }

  void _addStudent() {
    final name = _studentNameController.text.trim();
    final email = _studentEmailController.text.trim();
    final roll = _studentRollController.text.trim();

    if (name.isEmpty || email.isEmpty) return;

    final newP = ParticipantItem(
      id: 'usr-student-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      rollNo: roll.isNotEmpty ? roll : 'ROLL-${100 + _students.length}',
      role: 'student',
      avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&h=100&fit=crop',
    );

    setState(() {
      _students.insert(0, newP);
      _studentAddedSuccess = true;
      _studentNameController.clear();
      _studentEmailController.clear();
      _studentRollController.clear();
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _studentAddedSuccess = false);
    });
  }

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
                Row(
                  children: [
                    const Text(
                      'CLASSORA',
                      style: TextStyle(color: AppColors.slate900, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.purple100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'FACULTY',
                        style: TextStyle(color: AppColors.purple800, fontSize: 8, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
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
          _buildClassesTab(),
          _buildMaterialsTab(),
          _buildEnrollTab(),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) => setState(() => _currentTabIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.indigo600,
        unselectedItemColor: AppColors.slate400,
        backgroundColor: Colors.white,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_camera_front_rounded),
            label: 'Classes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_rounded),
            label: 'Materials',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add_alt_1_rounded),
            label: 'Enroll',
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
                colors: [AppColors.indigo950, AppColors.indigo800],
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
                      'Welcome, ${widget.user.name.split(' ').first}! 👋',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('Faculty Console', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  '128 Total Lectures Hosted • 34 Students in Live Room',
                  style: TextStyle(color: AppColors.indigo200, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Host Live Masterclass Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.indigo200),
              boxShadow: [
                BoxShadow(
                  color: AppColors.indigo600.withOpacity(0.08),
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
                          Text('HOST SESSION', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Room #Apex-Physics-101', style: TextStyle(color: AppColors.slate500, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Rotational Dynamics & Torque Masterclass',
                  style: TextStyle(color: AppColors.slate900, fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Class 12th JEE Advanced • 34 Students Waiting',
                  style: TextStyle(color: AppColors.slate500, fontSize: 12),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _isInLiveClass = true),
                    icon: const Icon(Icons.meeting_room_rounded, size: 18),
                    label: const Text('Launch Live Masterclass', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
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
          const SizedBox(height: 20),

          // Quick Stats Grid
          Row(
            children: [
              Expanded(
                child: _statCard('Active Students', '${_students.length}', Icons.groups_rounded, AppColors.indigo600),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard('Live Lectures', '${_classes.length}', Icons.video_call_rounded, AppColors.emerald600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.slate900)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 11, color: AppColors.slate500, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // Classes Tab
  Widget _buildClassesTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _classes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final c = _classes[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.isLive ? AppColors.rose400 : AppColors.slate200),
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
                      color: c.isLive ? AppColors.rose600 : AppColors.slate100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      c.isLive ? 'LIVE NOW' : 'SCHEDULED',
                      style: TextStyle(
                        color: c.isLive ? Colors.white : AppColors.slate700,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(c.time, style: const TextStyle(color: AppColors.slate500, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 10),
              Text(c.title, style: const TextStyle(color: AppColors.slate900, fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('${c.subject} • Host: ${c.teacher}', style: const TextStyle(color: AppColors.slate500, fontSize: 12)),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  onPressed: () => setState(() => _isInLiveClass = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indigo600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(c.isLive ? 'Resume & Host Class' : 'Start Scheduled Session'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Materials Tab
  Widget _buildMaterialsTab() {
    final docs = MockData.sampleDocuments;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Teaching Materials & Presentation Decks',
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
                  Text('${doc.author} • ${doc.fileName}', style: const TextStyle(color: AppColors.slate500, fontSize: 11)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedDocument = doc;
                          _isViewingDocument = true;
                        });
                      },
                      icon: Icon(isPpt ? Icons.slideshow_rounded : Icons.picture_as_pdf_rounded, size: 16),
                      label: Text(
                        isPpt ? 'Present Slide Deck to Class' : 'Open & Present PDF',
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
            );
          }),
        ],
      ),
    );
  }

  // Enroll Student Tab
  Widget _buildEnrollTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.slate200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enroll New Student',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.slate900),
            ),
            const SizedBox(height: 4),
            const Text(
              'Add a student to the Department of Physics roster',
              style: TextStyle(fontSize: 11, color: AppColors.slate500),
            ),
            const SizedBox(height: 16),

            if (_studentAddedSuccess) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.emerald50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.emerald200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppColors.emerald600, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Student enrolled successfully!',
                      style: TextStyle(color: AppColors.emerald800, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Full Name
            const Text('Student Full Name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.slate700)),
            const SizedBox(height: 6),
            TextField(
              controller: _studentNameController,
              decoration: InputDecoration(
                hintText: 'e.g. Priyanshu Verma',
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.slate400),
                filled: true,
                fillColor: AppColors.slate50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
              ),
            ),
            const SizedBox(height: 14),

            // Email
            const Text('Registered Email Address', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.slate700)),
            const SizedBox(height: 6),
            TextField(
              controller: _studentEmailController,
              decoration: InputDecoration(
                hintText: 'e.g. priyanshu@student.classora.com',
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.slate400),
                filled: true,
                fillColor: AppColors.slate50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
              ),
            ),
            const SizedBox(height: 14),

            // Roll No
            const Text('Assigned Roll / Student ID', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.slate700)),
            const SizedBox(height: 6),
            TextField(
              controller: _studentRollController,
              decoration: InputDecoration(
                hintText: 'e.g. ROLL-135',
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.slate400),
                filled: true,
                fillColor: AppColors.slate50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate200)),
              ),
            ),
            const SizedBox(height: 18),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _addStudent,
                icon: const Icon(Icons.person_add_rounded, size: 16),
                label: const Text('Complete Student Enrollment', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indigo600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
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
              color: AppColors.purple50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.purple200),
            ),
            child: Text(
              widget.user.batchOrDept,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.purple800),
            ),
          ),
          const SizedBox(height: 24),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Column(
              children: [
                _profileDetailItem('Faculty ID', 'TCH-PHYS-01', Icons.badge_outlined),
                const Divider(height: 1),
                _profileDetailItem('Experience', '14+ Years in IIT-JEE', Icons.star_border_rounded),
                const Divider(height: 1),
                _profileDetailItem('Total Hosted', '128 Lectures', Icons.video_call_outlined),
                const Divider(height: 1),
                _profileDetailItem('Department', 'Physics & Mechanics', Icons.school_outlined),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Logout
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: widget.onLogout,
              icon: const Icon(Icons.logout_rounded, size: 16, color: AppColors.rose600),
              label: const Text('Log Out of Faculty Console', style: TextStyle(color: AppColors.rose600, fontSize: 13, fontWeight: FontWeight.w700)),
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
