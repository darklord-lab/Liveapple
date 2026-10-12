import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../data/mock_data.dart';
import 'components/digital_board.dart';
import 'components/document_viewer.dart';
import 'components/screenshare_view.dart';
import 'components/participants_view.dart';
import 'components/chat_view.dart';
import 'components/doubts_view.dart';

class LiveClassroomScreen extends StatefulWidget {
  final UserSession user;
  final VoidCallback onExit;

  const LiveClassroomScreen({
    super.key,
    required this.user,
    required this.onExit,
  });

  @override
  State<LiveClassroomScreen> createState() => _LiveClassroomScreenState();
}

class _LiveClassroomScreenState extends State<LiveClassroomScreen> with TickerProviderStateMixin {
  // Pre-join lobby state
  bool _isPreJoin = true;

  // AV State
  bool _micOn = true;
  bool _camOn = true;
  bool _isFrontCamera = true;
  bool _handRaised = false;

  // Classroom Mode: 'whiteboard' | 'document' | 'screenshare'
  String _classroomMode = 'whiteboard';

  // Toolbar Visibility
  bool _isDockHidden = false;

  // Active Overlay Modal: 'roster' | 'chat' | 'doubts' | null
  String? _activeModal;

  // Meeting timer
  int _elapsedSeconds = 2532;
  Timer? _timer;

  // Audio Waveform Animation for Mic
  late AnimationController _audioWaveController;

  // Floating PiP Drag Position & View mode
  Offset _pipPosition = const Offset(16, 70);
  bool _pipExpanded = false;

  // In-Call Messages & Doubts
  late List<ChatMessage> _messages;
  late List<DoubtItem> _doubts;
  late List<ParticipantItem> _participants;

  @override
  void initState() {
    super.initState();
    _messages = List.from(MockData.sampleChatMessages);
    _doubts = List.from(MockData.sampleDoubts);
    _participants = List.from(MockData.participants);

    _audioWaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioWaveController.dispose();
    super.dispose();
  }

  String _formatTimer(int sec) {
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    final s = sec % 60;
    return '${h > 0 ? '$h:' : ''}${m < 10 ? '0' : ''}$m:${s < 10 ? '0' : ''}$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_isPreJoin) {
      return _buildPreJoinLobby();
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_activeModal != null) {
          setState(() => _activeModal = null);
        } else if (_classroomMode != 'whiteboard') {
          setState(() => _classroomMode = 'whiteboard');
        } else {
          _confirmExit();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.slate900,
        body: Stack(
          children: [
            // Stage Content
            Column(
              children: [
                // Top Header Bar
                _buildClassroomHeader(),

                // Active Stage View
                Expanded(
                  child: _buildStageContent(),
                ),
              ],
            ),

            // Draggable Floating PiP Video
            Positioned(
              left: _pipPosition.dx,
              top: _pipPosition.dy,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _pipPosition += details.delta;
                  });
                },
                onDoubleTap: () {
                  setState(() => _pipExpanded = !_pipExpanded);
                },
                child: _buildPipVideo(),
              ),
            ),

            // Floating Bottom Control Dock
            Positioned(
              left: 10,
              right: 10,
              bottom: 12,
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Toolbar Toggle Pill
                    GestureDetector(
                      onTap: () => setState(() => _isDockHidden = !_isDockHidden),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.slate800.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.slate700),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isDockHidden ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isDockHidden ? 'Show Controls' : 'Hide Controls',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Controls Dock Bar
                    if (!_isDockHidden) _buildControlsDock(),
                  ],
                ),
              ),
            ),

            // Full-screen Overlays: Participants, Chat, Doubts
            if (_activeModal == 'roster')
              Positioned.fill(
                child: ParticipantsView(
                  initialParticipants: _participants,
                  isTeacher: widget.user.role == 'teacher',
                  onClose: () => setState(() => _activeModal = null),
                ),
              ),

            if (_activeModal == 'chat')
              Positioned.fill(
                child: ChatView(
                  initialMessages: _messages,
                  currentUser: widget.user,
                  onSendMessage: (text) {},
                  onClose: () => setState(() => _activeModal = null),
                ),
              ),

            if (_activeModal == 'doubts')
              Positioned.fill(
                child: DoubtsView(
                  initialDoubts: _doubts,
                  currentUser: widget.user,
                  onClose: () => setState(() => _activeModal = null),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Pre-join Lobby View
  Widget _buildPreJoinLobby() {
    final isTeacher = widget.user.role == 'teacher';

    return Scaffold(
      backgroundColor: AppColors.slate950,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Brand Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                      const SizedBox(width: 8),
                      const Text(
                        'CLASSORA LIVE CLASSROOM',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: -0.3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Room Details Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.slate900,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.slate800),
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
                                  Text(
                                    'LIVE NOW',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.people_alt_rounded, color: AppColors.slate400, size: 14),
                            const SizedBox(width: 4),
                            const Text(
                              '34 Joined',
                              style: TextStyle(color: AppColors.slate400, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Rotational Dynamics & Torque Masterclass',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Class 12th JEE Advanced • Department of Physics',
                          style: TextStyle(
                            color: AppColors.slate400,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Camera Preview Window with Real-time AV Test
                  Container(
                    width: double.infinity,
                    height: 230,
                    decoration: BoxDecoration(
                      color: AppColors.slate900,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.slate800),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        if (_camOn)
                          Image.network(
                            isTeacher
                                ? 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500&h=400&fit=crop'
                                : 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=500&h=400&fit=crop',
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          )
                        else
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 36,
                                  backgroundColor: AppColors.indigo600,
                                  child: Text(
                                    widget.user.name.isNotEmpty ? widget.user.name[0] : 'U',
                                    style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Camera is currently turned off',
                                  style: TextStyle(color: AppColors.slate400, fontSize: 12),
                                ),
                              ],
                            ),
                          ),

                        // Camera status pill
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _camOn ? AppColors.emerald400 : AppColors.rose500,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _camOn ? '1080p HD • 30fps' : 'Video Muted',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Camera Flip button
                        if (_camOn)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _isFrontCamera = !_isFrontCamera);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(_isFrontCamera ? 'Front Camera Active' : 'Rear Camera Active'),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white, size: 16),
                              ),
                            ),
                          ),

                        // Live Audio Waveform (Bounces when mic is on)
                        if (_micOn)
                          Positioned(
                            bottom: 60,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.graphic_eq_rounded, color: AppColors.emerald400, size: 14),
                                    const SizedBox(width: 6),
                                    AnimatedBuilder(
                                      animation: _audioWaveController,
                                      builder: (context, child) {
                                        final db = (45 + 35 * _audioWaveController.value).toInt();
                                        return Text(
                                          'Mic Active: $db dB',
                                          style: const TextStyle(color: AppColors.emerald400, fontSize: 10, fontWeight: FontWeight.w800),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // AV Toggles Overlay
                        Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _roundLobbyButton(
                                icon: _micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                                isActive: _micOn,
                                onTap: () => setState(() => _micOn = !_micOn),
                              ),
                              const SizedBox(width: 14),
                              _roundLobbyButton(
                                icon: _camOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                                isActive: _camOn,
                                onTap: () => setState(() => _camOn = !_camOn),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Join Masterclass Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _isPreJoin = false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.indigo600,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.meeting_room_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            isTeacher ? 'Host & Broadcast Masterclass' : 'Join Live Masterclass',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Cancel / Back
                  TextButton(
                    onPressed: widget.onExit,
                    child: const Text('Cancel & Return to Dashboard', style: TextStyle(color: AppColors.slate400, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _roundLobbyButton({required IconData icon, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive ? AppColors.indigo600 : AppColors.rose600,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  // Classroom Header
  Widget _buildClassroomHeader() {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          color: AppColors.slate850,
          border: Border(bottom: BorderSide(color: AppColors.slate700)),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: _confirmExit,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.rose600,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatTimer(_elapsedSeconds),
                        style: const TextStyle(
                          color: AppColors.slate300,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'Rotational Dynamics & Torque Masterclass',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Mode switcher buttons
            _headerModeButton('whiteboard', 'Board', Icons.draw_rounded),
            const SizedBox(width: 4),
            _headerModeButton('document', 'Slides/PDF', Icons.picture_as_pdf_rounded),
            const SizedBox(width: 4),
            _headerModeButton('screenshare', 'Share', Icons.screen_share_rounded),
          ],
        ),
      ),
    );
  }

  Widget _headerModeButton(String mode, String label, IconData icon) {
    final isSel = _classroomMode == mode;
    return GestureDetector(
      onTap: () {
        if (mode == 'screenshare') {
          _handleToggleScreenShare();
        } else {
          setState(() => _classroomMode = mode);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isSel ? AppColors.indigo600 : AppColors.slate700,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  void _handleToggleScreenShare() {
    if (_classroomMode == 'screenshare') {
      setState(() => _classroomMode = 'whiteboard');
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.slate900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.slate700),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.indigo600, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.screen_share_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Start Screen Sharing',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Classora will capture everything displayed on your screen (Zoom / Google Meet style), including external apps, photos, documents, and videos.',
              style: TextStyle(color: AppColors.slate300, fontSize: 12, height: 1.45),
            ),
            SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.volume_up_rounded, color: AppColors.emerald400, size: 16),
                SizedBox(width: 8),
                Text(
                  'Share Device Audio: Active (System & Mic)',
                  style: TextStyle(color: AppColors.emerald400, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.slate400, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _classroomMode = 'screenshare');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Screen Sharing Active • Students can see your device screen'),
                  backgroundColor: AppColors.emerald700,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.indigo600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Start Sharing Now', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  // Active Stage Content
  Widget _buildStageContent() {
    if (_classroomMode == 'document') {
      return const DocumentViewer();
    } else if (_classroomMode == 'screenshare') {
      return ScreenShareView(
        isTeacher: widget.user.role == 'teacher',
        onStopSharing: () => setState(() => _classroomMode = 'whiteboard'),
      );
    } else {
      return DigitalBoard(isTeacher: widget.user.role == 'teacher');
    }
  }

  // Floating PiP Video
  Widget _buildPipVideo() {
    final isTeacher = widget.user.role == 'teacher';
    final width = _pipExpanded ? 150.0 : 115.0;
    final height = _pipExpanded ? 190.0 : 145.0;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.slate900,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _micOn ? AppColors.emerald500 : AppColors.indigo500, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Teacher Video Stream
          Image.network(
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300&h=300&fit=crop',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: AppColors.indigo950,
              alignment: Alignment.center,
              child: const Icon(Icons.person_rounded, color: Colors.white, size: 36),
            ),
          ),

          // Faculty speaking indicator with audio wave
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _micOn ? Icons.graphic_eq_rounded : Icons.mic_off_rounded,
                    color: _micOn ? AppColors.emerald400 : AppColors.rose500,
                    size: 10,
                  ),
                  const SizedBox(width: 3),
                  const Text('Prof. Sharma', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),

          // Student self-preview in corner
          if (!isTeacher)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                width: 38,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.slate800,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _camOn ? AppColors.emerald400 : Colors.white.withValues(alpha: 0.6)),
                ),
                clipBehavior: Clip.antiAlias,
                child: _camOn
                    ? Image.network(
                        widget.user.avatar,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white, size: 16),
                      )
                    : const Icon(Icons.videocam_off, color: Colors.white, size: 16),
              ),
            ),
        ],
      ),
    );
  }

  // Floating Controls Dock
  Widget _buildControlsDock() {
    final isTeacher = widget.user.role == 'teacher';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.slate900.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate700),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mic Toggle
            _dockButton(
              icon: _micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
              label: _micOn ? 'Mute' : 'Unmute',
              color: _micOn ? AppColors.slate700 : AppColors.rose600,
              onTap: () {
                setState(() => _micOn = !_micOn);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_micOn ? 'Microphone unmuted (Audio transmitting)' : 'Microphone muted'),
                    duration: const Duration(milliseconds: 900),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),

            // Video Toggle
            _dockButton(
              icon: _camOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
              label: _camOn ? 'Stop Cam' : 'Start Cam',
              color: _camOn ? AppColors.slate700 : AppColors.rose600,
              onTap: () {
                setState(() => _camOn = !_camOn);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_camOn ? 'Camera stream active' : 'Camera stream stopped'),
                    duration: const Duration(milliseconds: 900),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),

            // Screen Share Toggle Button
            _dockButton(
              icon: Icons.screen_share_rounded,
              label: _classroomMode == 'screenshare' ? 'Viewing Share' : 'Share Screen',
              color: _classroomMode == 'screenshare' ? AppColors.emerald600 : AppColors.slate700,
              onTap: _handleToggleScreenShare,
            ),
            const SizedBox(width: 8),

            // Raise hand (for student)
            if (!isTeacher) ...[
              _dockButton(
                icon: Icons.pan_tool_rounded,
                label: _handRaised ? 'Lower' : 'Raise Hand',
                color: _handRaised ? AppColors.amber500 : AppColors.slate700,
                onTap: () {
                  setState(() => _handRaised = !_handRaised);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_handRaised ? 'Hand raised to faculty' : 'Hand lowered'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],

            // Participants Button
            _dockButton(
              icon: Icons.people_alt_rounded,
              label: '34 Roster',
              color: AppColors.slate700,
              badge: '${_participants.length}',
              onTap: () => setState(() => _activeModal = 'roster'),
            ),
            const SizedBox(width: 8),

            // In-call Chat Button
            _dockButton(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Chat',
              color: AppColors.slate700,
              badge: '${_messages.length}',
              onTap: () => setState(() => _activeModal = 'chat'),
            ),
            const SizedBox(width: 8),

            // Doubts Queue Button
            _dockButton(
              icon: Icons.help_outline_rounded,
              label: 'Doubts',
              color: AppColors.slate700,
              badge: '${_doubts.length}',
              onTap: () => setState(() => _activeModal = 'doubts'),
            ),
            const SizedBox(width: 8),

            // Leave / End Call
            _dockButton(
              icon: Icons.call_end_rounded,
              label: isTeacher ? 'End Lecture' : 'Leave Room',
              color: AppColors.rose600,
              onTap: _confirmExit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _dockButton({
    required IconData icon,
    required String label,
    required Color color,
    String? badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 19),
              ),
              if (badge != null)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: const BoxDecoration(
                      color: AppColors.indigo600,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppColors.slate300, fontSize: 9, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _confirmExit() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.slate800,
        title: const Text('Leave Live Masterclass?', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text(
          'Are you sure you want to exit the current live lecture session?',
          style: TextStyle(color: AppColors.slate300, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Stay in Class', style: TextStyle(color: AppColors.slate400)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onExit();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose600),
            child: const Text('Exit Lecture', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
