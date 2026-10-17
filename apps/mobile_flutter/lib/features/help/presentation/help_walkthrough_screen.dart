import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/domain/user_model.dart';
import '../../auth/presentation/auth_controller.dart';

class WalkthroughStep {
  final String title;
  final String badge;
  final IconData icon;
  final Color color;
  final String description;
  final List<String> highlights;
  final String proTip;

  const WalkthroughStep({
    required this.title,
    required this.badge,
    required this.icon,
    required this.color,
    required this.description,
    required this.highlights,
    required this.proTip,
  });
}

class HelpFaq {
  final String question;
  final String answer;

  const HelpFaq({required this.question, required this.answer});
}

class HelpWalkthroughScreen extends ConsumerStatefulWidget {
  final String initialRole;
  final UserModel? user;
  final bool openTourImmediately;

  const HelpWalkthroughScreen({
    super.key,
    this.initialRole = 'STUDENT',
    this.user,
    this.openTourImmediately = false,
  });

  @override
  ConsumerState<HelpWalkthroughScreen> createState() => _HelpWalkthroughScreenState();
}

class _HelpWalkthroughScreenState extends ConsumerState<HelpWalkthroughScreen> {
  late String _selectedRole;
  final SecureStorageService _storage = SecureStorageService();

  @override
  void initState() {
    super.initState();
    final role = widget.initialRole.toUpperCase();
    if (role == 'ADMIN' || role == 'TEACHER' || role == 'STUDENT') {
      _selectedRole = role;
    } else {
      _selectedRole = 'STUDENT';
    }

    if (widget.openTourImmediately) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _launchInteractiveTour();
      });
    }
  }

  List<WalkthroughStep> _getStepsForRole(String role) {
    switch (role) {
      case 'TEACHER':
        return const [
          WalkthroughStep(
            badge: 'STEP 1 • LIVE STAGE',
            title: 'Go Live & Lead Interactive Lectures',
            icon: Icons.live_tv_rounded,
            color: AppColors.liveRed,
            description:
                'Start live classes instantly from your Home dashboard or scheduled timetable slots. Share high-definition video, audio, and screens with students.',
            highlights: ['1-Tap Go Live', 'Screen Sharing', 'Mute All Controls', 'Real-Time In-Class Chat'],
            proTip:
                'Always join 2 minutes before the scheduled time to test your microphone and camera in the pre-join lobby.',
          ),
          WalkthroughStep(
            badge: 'STEP 2 • WHITEBOARD',
            title: 'Interactive Digital Whiteboard',
            icon: Icons.draw_rounded,
            color: Color(0xFF4F46E5),
            description:
                'Draw diagrams, explain formulas, and illustrate complex problems on the built-in digital board. Students stay view-only by default to avoid disruptions.',
            highlights: ['Real-Time Drawing', 'View-Only Guard', 'Grant Permission', 'In-Class Exclusivity'],
            proTip:
                'You can selectively grant whiteboard drawing access to active students from the live participants panel.',
          ),
          WalkthroughStep(
            badge: 'STEP 3 • TIMETABLE',
            title: 'Smart Scheduling & Conflict Engine',
            icon: Icons.schedule_rounded,
            color: AppColors.skyBlue,
            description:
                'Set up recurring weekly lecture slots across your assigned batches. Classora automatically detects time overlaps and alerts you of room conflicts.',
            highlights: ['Recurring Slots', 'Conflict Engine', 'Week View Strip', 'Auto-Class Generator'],
            proTip:
                'Timetable slots generate automatic 15-minute reminders so all enrolled students attend on time.',
          ),
          WalkthroughStep(
            badge: 'STEP 4 • COHORT BATCHES',
            title: 'Batch Roster & Quick Student Invites',
            icon: Icons.groups_rounded,
            color: Color(0xFF2FA37A),
            description:
                'Manage enrolled students, approve pending admission requests, and share unique 6-character batch join codes or QR invites with your students.',
            highlights: ['6-Digit Join Codes', 'QR Code Invites', 'Admissions Approval', 'Student Roster'],
            proTip:
                'Tap on any batch card to review enrolled students, attendance percentages, and study documents.',
          ),
          WalkthroughStep(
            badge: 'STEP 5 • STUDY MATERIALS',
            title: 'Organize Folders & Curricular Handouts',
            icon: Icons.upload_file_rounded,
            color: Color(0xFFF28A30),
            description:
                'Upload PDF lecture notes, formula sheets, and reference docs organized into batch topic folders. Mark introductory materials as free previews.',
            highlights: ['Topic Folders', 'PDF & Doc Uploads', 'Free Preview Flag', 'Batch Homework'],
            proTip:
                'All uploads are protected with role-based access control and tenant isolation.',
          ),
        ];

      case 'ADMIN':
        return const [
          WalkthroughStep(
            badge: 'STEP 1 • COMMAND CENTER',
            title: 'Institute Overview & Real-Time Pulse',
            icon: Icons.dashboard_rounded,
            color: AppColors.skyBlue,
            description:
                'Monitor overall academy health at a glance: total enrolled students, active faculty teachers, class attendance rates, and fee revenue metrics.',
            highlights: ['Live Statistics', 'Active Teachers', 'Attendance Rates', 'Revenue Tracking'],
            proTip:
                'Check the Overview dashboard every morning to see classes scheduled for the day across all departments.',
          ),
          WalkthroughStep(
            badge: 'STEP 2 • FACULTY ONBOARDING',
            title: 'Teacher Directory & Bulk CSV Invites',
            icon: Icons.person_add_rounded,
            color: Color(0xFF4F46E5),
            description:
                'Onboard teachers individually or in bulk with a single CSV file upload. Classora creates secure 48-hour one-time invite codes for instant password setup.',
            highlights: ['Single & Bulk Onboard', 'CSV Template', 'One-Time Invites', 'Suspend/Reactivate'],
            proTip:
                'Copy generated invite links with one tap and share them directly via WhatsApp or official email.',
          ),
          WalkthroughStep(
            badge: 'STEP 3 • CURRICULUM BATCHES',
            title: 'Master Batches & Institute Timetable',
            icon: Icons.account_tree_rounded,
            color: Color(0xFF2FA37A),
            description:
                'Create standardized batch cohorts, assign subject teachers, monitor batch enrollment join codes, and inspect global timetable schedules.',
            highlights: ['Batch Creation', 'Faculty Assignment', 'Join Code Oversight', 'Master Schedules'],
            proTip:
                'Assign dedicated subject teachers so their personal timetables automatically sync with batch cohorts.',
          ),
          WalkthroughStep(
            badge: 'STEP 4 • WHITE-LABEL BRANDING',
            title: 'Institute Identity, Social Links & Reviews',
            icon: Icons.branding_watermark_rounded,
            color: Color(0xFFF28A30),
            description:
                'Personalize the app with your institute name, logo, 6-character institute code, official YouTube/Telegram/WhatsApp links, and student testimonials.',
            highlights: ['Institute Code', 'App Bar Branding', 'Social Connect Links', 'Curated Testimonials'],
            proTip:
                'When students enter your institute code during onboarding, the app header displays your academy name.',
          ),
          WalkthroughStep(
            badge: 'STEP 5 • FINANCIALS & SECURITY',
            title: 'Fee Dues & Enterprise Tenant Isolation',
            icon: Icons.security_rounded,
            color: Color(0xFF8B5E3C),
            description:
                'Track collected and pending student fee dues, issue receipts, and manage accounts under strict multi-tenant database isolation and argon2id security.',
            highlights: ['Fee Records', 'Receipt Tracking', 'Tenant Isolation', 'Audit Logs'],
            proTip:
                'All data queries are strictly scoped to your institute ID, ensuring complete privacy and isolation.',
          ),
        ];

      case 'STUDENT':
      default:
        return const [
          WalkthroughStep(
            badge: 'STEP 1 • LIVE LECTURES',
            title: 'Join Live Classes with 1-Tap & Attendance',
            icon: Icons.videocam_rounded,
            color: AppColors.skyBlue,
            description:
                'When your teacher goes live, tap the big red "Join Class" card on your Home screen. Your attendance is recorded automatically without roll calls.',
            highlights: ['1-Tap Join', 'Crystal-Clear Video', 'Auto Attendance', 'Live In-Class Chat'],
            proTip:
                'Use headphones for the best audio experience and enter the classroom 1 minute before class starts.',
          ),
          WalkthroughStep(
            badge: 'STEP 2 • TIMETABLE',
            title: 'Weekly Schedule & 15-Minute Reminders',
            icon: Icons.calendar_month_rounded,
            color: Color(0xFF2FA37A),
            description:
                'Check your daily and weekly timetable strip to see upcoming classes across all your enrolled batches. Get automatic reminders before each session.',
            highlights: ['Week Strip View', '15-Min Reminders', 'Batch Timetable', 'Today Agenda'],
            proTip:
                'Tap any day in the top strip to see the full agenda and subjects scheduled for that date.',
          ),
          WalkthroughStep(
            badge: 'STEP 3 • STUDY MATERIAL',
            title: 'Curricular Notes, PDFs & Handouts',
            icon: Icons.folder_shared_rounded,
            color: Color(0xFFF28A30),
            description:
                'Access study materials uploaded by your teachers organized neatly into topic folders. Read PDFs, formula cheat sheets, and free demo resources.',
            highlights: ['Topic Folders', 'PDF Reader', 'Free Handouts', 'Offline View Support'],
            proTip:
                'Introductory study materials with the "FREE" badge can be previewed without prior batch enrollment.',
          ),
          WalkthroughStep(
            badge: 'STEP 4 • TESTS & REPLAYS',
            title: 'Batch CBT Quizzes, Homework & Recordings',
            icon: Icons.assignment_turned_in_rounded,
            color: Color(0xFF4F46E5),
            description:
                'Attempt timed CBT practice tests with instant grading, submit homework assignments, and watch published video recordings if you ever miss a class.',
            highlights: ['Timed CBT Tests', 'Instant Scores', 'Homework Submissions', 'Class Replays'],
            proTip:
                'Missed a live session? Go to the Learn tab and tap Recordings to replay past lectures.',
          ),
          WalkthroughStep(
            badge: 'STEP 5 • PROFILE & SUPPORT',
            title: 'Personal Profile, Settings & Community',
            icon: Icons.person_pin_rounded,
            color: Color(0xFF8B5E3C),
            description:
                'Upload your profile photo via camera or gallery, customize reminder notifications, rate the app, and connect with your institute via social links.',
            highlights: ['Photo Upload', 'Notification Toggles', 'Fee Receipts', 'Connect With Us'],
            proTip:
                'Keep "Live Class Alerts" enabled in Settings so you never miss an unannounced revision session.',
          ),
        ];
    }
  }

  List<HelpFaq> _getFaqsForRole(String role) {
    switch (role) {
      case 'TEACHER':
        return const [
          HelpFaq(
            question: 'How do I start a live lecture?',
            answer:
                'Go to your Home screen and tap "Go Live" on any scheduled class card, or navigate to Live Classes tab and select "Start Session". Enter the pre-join lobby to check camera/mic, then tap "Go Live".',
          ),
          HelpFaq(
            question: 'How does the Whiteboard view-only protection work?',
            answer:
                'By default, all enrolled students can view your drawings in real time but cannot draw. If you want a student to solve a problem on the board, open the participant list and tap "Grant Whiteboard Access".',
          ),
          HelpFaq(
            question: 'What happens if two classes conflict in the timetable?',
            answer:
                'Classora includes a built-in conflict engine. When adding a timetable slot, if there is an overlapping slot with the same batch or room, an alert is displayed and the slot cannot be saved until resolved.',
          ),
          HelpFaq(
            question: 'How do students join my batch?',
            answer:
                'Open your Batch Details screen and share the unique 6-character Batch Code or QR code. When students enter this code, they join your roster automatically.',
          ),
        ];

      case 'ADMIN':
        return const [
          HelpFaq(
            question: 'How do I onboard multiple teachers at once?',
            answer:
                'In the Faculty tab, tap "Bulk CSV Onboard". You can download the sample CSV template, fill in teacher names and emails, and upload it. The system generates secure one-time invite codes for each teacher.',
          ),
          HelpFaq(
            question: 'How long are faculty invite codes valid?',
            answer:
                'Invite codes remain valid for 48 hours for security reasons. If an invite expires before the teacher registers, you can easily re-issue an invite from the Faculty directory.',
          ),
          HelpFaq(
            question: 'Is our institute data isolated from other institutes?',
            answer:
                'Yes. Classora enforces strict tenant isolation on the database level. Every single query is filtered by your unique Institute ID, preventing cross-institute access.',
          ),
          HelpFaq(
            question: 'Where do I configure our institute logo and connect links?',
            answer:
                'Navigate to Admin Hub (More tab) -> Branding & Connect Links. You can add your institute name, official YouTube, Telegram, and WhatsApp links, and curate student testimonials.',
          ),
        ];

      case 'STUDENT':
      default:
        return const [
          HelpFaq(
            question: 'How do I join a live lecture?',
            answer:
                'When your teacher begins a live class, a glowing "LIVE NOW" banner appears on your Home screen. Tap "Join Class", verify your mic/camera in the lobby, and you will enter the classroom.',
          ),
          HelpFaq(
            question: 'Why are my microphone and camera muted when I join?',
            answer:
                'Students join live classes muted by default to minimize background noise for the batch. You can raise your hand or ask questions in the in-class chat. The teacher can grant you permission to speak.',
          ),
          HelpFaq(
            question: 'How do I enroll in a new batch?',
            answer:
                'Tap "Join Batch" on your Home screen or under Learn -> Batches. Enter the 6-character code given by your teacher or institute and tap "Enroll".',
          ),
          HelpFaq(
            question: 'Where can I find recorded classes if I miss a lecture?',
            answer:
                'Navigate to the "Learn" tab and select "Recordings". You can view all published lecture replays for your enrolled batches.',
          ),
        ];
    }
  }

  void _launchInteractiveTour() {
    final steps = _getStepsForRole(_selectedRole);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _InteractiveTourDialog(
        role: _selectedRole,
        steps: steps,
        onFinished: () async {
          await _storage.setCompletedWalkthrough(_selectedRole);
        },
      ),
    );
  }

  void _showSupportDialog() {
    final currentUser = widget.user ?? ref.read(authStateProvider).user;
    final instituteName = currentUser?.institute?.name ?? 'Classora Support Desk';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.headset_mic_rounded, color: AppColors.skyBlue, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Help & Support',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connected to: $instituteName',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textLight),
            ),
            const SizedBox(height: 8),
            const Text(
              'For technical assistance, live class connectivity issues, or batch enrollment inquiries, please reach out to your institute coordinator or admin.',
              style: TextStyle(fontSize: 13, color: AppColors.slate600, height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const Row(
                children: [
                  Icon(Icons.mail_outline, size: 18, color: AppColors.skyBlue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'support@classora.app',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.skyBlue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = widget.user ?? ref.read(authStateProvider).user;
    final userActualRole = currentUser?.role ?? 'STUDENT';
    final steps = _getStepsForRole(_selectedRole);
    final faqs = _getFaqsForRole(_selectedRole);

    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.skyBlue,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            tooltip: 'Back',
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Help & User Guide',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline, color: Colors.white),
              tooltip: 'Interactive Tour',
              onPressed: _launchInteractiveTour,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // Role Switcher / Tabs
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  _buildRoleTab('STUDENT', 'Student', Icons.school_outlined),
                  _buildRoleTab('TEACHER', 'Teacher', Icons.cast_for_education_outlined),
                  _buildRoleTab('ADMIN', 'Admin', Icons.admin_panel_settings_outlined),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Interactive Tour Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.skyBlue, Color(0xFF0284C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.skyBlue.withValues(alpha: 0.25),
                    blurRadius: 10,
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$_selectedRole ONBOARDING',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (_selectedRole == userActualRole)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'YOUR ROLE',
                            style: TextStyle(
                              color: AppColors.skyBlue,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Interactive ${_selectedRole.toLowerCase().capitalize()} Tour',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Take a visual 5-step walkthrough tailored for ${_selectedRole.toLowerCase()}s. Learn how to navigate live classes, study materials, and key features.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.skyBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    icon: const Icon(Icons.play_circle_filled_rounded, size: 18),
                    label: const Text(
                      'Start Interactive Walkthrough',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: _launchInteractiveTour,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Walkthrough Modules Section
            Row(
              children: [
                const Icon(Icons.auto_stories_rounded, size: 20, color: AppColors.skyBlue),
                const SizedBox(width: 8),
                Text(
                  '${_selectedRole.toLowerCase().capitalize()} Core Workflows',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textLight),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ...steps.map((step) => _buildStepSummaryCard(step)),

            const SizedBox(height: 20),

            // FAQs Section
            const Row(
              children: [
                Icon(Icons.help_center_rounded, size: 20, color: AppColors.skyBlue),
                SizedBox(width: 8),
                Text(
                  'Frequently Asked Questions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textLight),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ...faqs.map((faq) => _buildFaqTile(faq)),

            const SizedBox(height: 20),

            // Device & Permissions Troubleshooting
            _buildTroubleshootingCard(),

            const SizedBox(height: 16),

            // Support Contact Card
            _buildSupportCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleTab(String role, String label, IconData icon) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.skyBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.slate500,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                  color: isSelected ? Colors.white : AppColors.slate600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepSummaryCard(WalkthroughStep step) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: step.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(step.icon, size: 22, color: step.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.badge,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: step.color,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      step.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            step.description,
            style: const TextStyle(fontSize: 12, color: AppColors.slate600, height: 1.4),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: step.highlights.map((h) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Text(
                  h,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.slate600),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, size: 14, color: Color(0xFF16A34A)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    step.proTip,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF15803D), height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqTile(HelpFaq faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.skyBlue,
          collapsedIconColor: AppColors.slate400,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          title: Text(
            faq.question,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textLight),
          ),
          children: [
            Text(
              faq.answer,
              style: const TextStyle(fontSize: 12, color: AppColors.slate600, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTroubleshootingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.build_circle_outlined, size: 18, color: AppColors.skyBlue),
              SizedBox(width: 8),
              Text(
                'Troubleshooting & System Checks',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textLight),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildTroubleshootItem(
            Icons.mic_none_outlined,
            'Microphone & Camera',
            'Ensure device permissions are granted in Phone Settings -> Apps -> Classora.',
          ),
          _buildTroubleshootItem(
            Icons.notifications_active_outlined,
            'Live Class Alerts',
            'Check that notifications are enabled in App Settings so you get reminders 15 minutes before class.',
          ),
          _buildTroubleshootItem(
            Icons.wifi_outlined,
            'Network & Weak Signal',
            'If live stream buffers, move closer to Wi-Fi. LiveKit automatically optimizes stream bitrates.',
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.slate500),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: AppColors.slate600, height: 1.3),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textLight),
                  ),
                  TextSpan(text: subtitle),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.skyBlueLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.skyBlue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            child: Icon(Icons.contact_support_rounded, color: AppColors.skyBlue, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need personal assistance?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textLight),
                ),
                SizedBox(height: 2),
                Text(
                  'Contact your institute coordinator or Classora desk',
                  style: TextStyle(fontSize: 11, color: AppColors.slate500),
                ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _showSupportDialog,
            child: const Text('Contact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.skyBlue)),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* INTERACTIVE TOUR MODAL DIALOG                                              */
/* -------------------------------------------------------------------------- */
class _InteractiveTourDialog extends StatefulWidget {
  final String role;
  final List<WalkthroughStep> steps;
  final VoidCallback onFinished;

  const _InteractiveTourDialog({
    required this.role,
    required this.steps,
    required this.onFinished,
  });

  @override
  State<_InteractiveTourDialog> createState() => _InteractiveTourDialogState();
}

class _InteractiveTourDialogState extends State<_InteractiveTourDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < widget.steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onFinished();
      Navigator.pop(context);
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSteps = widget.steps.length;
    final progress = (_currentPage + 1) / totalSteps;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 620),
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 10),
              child: Row(
                children: [
                  Text(
                    '${widget.role.toLowerCase().capitalize()} Tour (${_currentPage + 1}/$totalSteps)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.slate600),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: AppColors.slate400),
                    tooltip: 'Skip Tour',
                    onPressed: () {
                      widget.onFinished();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),

            // Progress Bar
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.backgroundLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.skyBlue),
              minHeight: 3,
            ),

            // Page Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: totalSteps,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (context, index) {
                  final s = widget.steps[index];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Step Icon
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: s.color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(s.icon, size: 36, color: s.color),
                        ),
                        const SizedBox(height: 14),

                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: s.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            s.badge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: s.color,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Title
                        Text(
                          s.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Description
                        Text(
                          s.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.slate600,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Highlights
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: s.highlights.map((h) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundLight,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.borderLight),
                              ),
                              child: Text(
                                h,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.slate700,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),

                        // Pro Tip Box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.lightbulb_rounded, size: 16, color: Color(0xFF16A34A)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  s.proTip,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF15803D),
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.borderLight)),
              ),
              child: Row(
                children: [
                  // Back Button
                  if (_currentPage > 0)
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onPressed: _prevPage,
                      child: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    )
                  else
                    const SizedBox(width: 60),

                  const Spacer(),

                  // Page Dots
                  Row(
                    children: List.generate(totalSteps, (idx) {
                      final isActive = idx == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 16 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.skyBlue : AppColors.slate300,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),

                  const Spacer(),

                  // Next / Done Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.skyBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    onPressed: _nextPage,
                    child: Text(
                      _currentPage == totalSteps - 1 ? 'Got it!' : 'Next',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
