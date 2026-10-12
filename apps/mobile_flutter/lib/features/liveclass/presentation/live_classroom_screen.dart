import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/live_class_model.dart';
import '../domain/class_participant.dart';
import 'live_class_controller.dart';
import 'live_class_room_controller.dart';
import '../../../screens/classroom/components/digital_board.dart';

class LiveClassroomScreen extends ConsumerStatefulWidget {
  final String classId;

  const LiveClassroomScreen({super.key, required this.classId});

  @override
  ConsumerState<LiveClassroomScreen> createState() => _LiveClassroomScreenState();
}

class _LiveClassroomScreenState extends ConsumerState<LiveClassroomScreen> {
  final _chatTextController = TextEditingController();

  // Green Room / Pre-Join Lobby State (Zoom & Meet style)
  bool _isInLobby = true;
  bool _isLoadingLobby = true;
  LiveClassModel? _lobbyClass;
  bool _lobbyMicEnabled = false;
  bool _lobbyCameraEnabled = false;
  lk.LocalVideoTrack? _lobbyVideoTrack;

  // Live PPT / PDF Document Presenter State (User Feature Request)
  bool _isDocPresenterOpen = false;
  String _currentDocTitle = 'Electromagnetic Induction — Lecture Slides.pptx';
  int _currentSlideNumber = 1;
  final int _totalSlides = 8;

  @override
  void initState() {
    super.initState();
    _initLobby();
  }

  Future<void> _initLobby() async {
    final user = ref.read(authStateProvider).user;
    final isTeacher = user?.role == 'TEACHER' || user?.role == 'ADMIN';
    _lobbyMicEnabled = isTeacher;
    _lobbyCameraEnabled = isTeacher;

    try {
      final repo = ref.read(liveClassRepositoryProvider);
      final cls = await repo.getClassById(widget.classId);
      if (mounted) {
        setState(() {
          _lobbyClass = cls;
          _isLoadingLobby = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingLobby = false;
        });
      }
    }

    if (_lobbyCameraEnabled) {
      _startLobbyCamera();
    }
  }

  Future<void> _startLobbyCamera() async {
    try {
      final track = await lk.LocalVideoTrack.createCameraTrack();
      if (mounted) {
        setState(() {
          _lobbyVideoTrack = track;
          _lobbyCameraEnabled = true;
        });
      }
    } catch (e) {
      debugPrint('[LOBBY] Camera start error: $e');
      if (mounted) {
        setState(() {
          _lobbyCameraEnabled = false;
        });
      }
    }
  }

  Future<void> _stopLobbyCamera() async {
    try {
      await _lobbyVideoTrack?.stop();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _lobbyVideoTrack = null;
        _lobbyCameraEnabled = false;
      });
    }
  }

  void _toggleLobbyMic() {
    setState(() {
      _lobbyMicEnabled = !_lobbyMicEnabled;
    });
  }

  void _toggleLobbyCamera() {
    if (_lobbyCameraEnabled) {
      _stopLobbyCamera();
    } else {
      _startLobbyCamera();
    }
  }

  void _enterClassroom() {
    final user = ref.read(authStateProvider).user;
    setState(() {
      _isInLobby = false;
    });

    ref.read(liveClassRoomProvider.notifier).joinRoom(
          widget.classId,
          currentUserId: user?.id,
          currentUserName: user?.name,
          currentUserRole: user?.role,
          initialMicMuted: !_lobbyMicEnabled,
          initialCameraOff: !_lobbyCameraEnabled,
          prewarmVideoTrack: _lobbyVideoTrack,
        );
  }

  @override
  void dispose() {
    _lobbyVideoTrack?.stop();
    _chatTextController.dispose();
    super.dispose();
  }

  void _showChatDrawer() {
    final user = ref.read(authStateProvider).user;
    final userName = user?.name ?? 'User';
    final userRole = user?.role ?? 'STUDENT';
    ref.read(liveClassRoomProvider.notifier).markChatRead();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final roomState = ref.watch(liveClassRoomProvider);

            return Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              height: 520,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.chat_bubble_outline, color: AppColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'In-Class Discussion',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.borderDark),
                  Expanded(
                    child: roomState.chatMessages.isEmpty
                        ? const Center(
                            child: Text(
                              'No messages yet. Say hi to your class!',
                              style: TextStyle(color: AppColors.slate400, fontSize: 13),
                            ),
                          )
                        : ListView.builder(
                            itemCount: roomState.chatMessages.length,
                            itemBuilder: (context, idx) {
                              final msg = roomState.chatMessages[idx];
                              final isMe = msg.senderId == (user?.id ?? 'me');

                              if (msg.isSystem) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Center(
                                    child: Text(
                                      msg.text,
                                      style: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                        fontSize: 11,
                                        color: AppColors.slate400,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              return Align(
                                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                                  ),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isMe ? AppColors.primary : AppColors.surfaceDark,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(14),
                                      topRight: const Radius.circular(14),
                                      bottomLeft: Radius.circular(isMe ? 14 : 2),
                                      bottomRight: Radius.circular(isMe ? 2 : 14),
                                    ),
                                    border: isMe ? null : Border.all(color: AppColors.borderDark),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            isMe ? 'You' : msg.senderName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: isMe ? Colors.white : AppColors.primaryLight,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: msg.senderRole == 'TEACHER'
                                                  ? AppColors.primaryLight.withValues(alpha: 0.2)
                                                  : AppColors.slate700,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              msg.senderRole,
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: isMe ? Colors.white : AppColors.slate400,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isMe ? Colors.white70 : AppColors.slate400,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        msg.text,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _chatTextController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Ask doubt or message class...',
                            hintStyle: const TextStyle(color: AppColors.slate400, fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            filled: true,
                            fillColor: AppColors.surfaceDark,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: AppColors.borderDark),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: AppColors.borderDark),
                            ),
                          ),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              ref.read(liveClassRoomProvider.notifier).sendChatMessage(
                                    val,
                                    userName,
                                    userRole,
                                  );
                              _chatTextController.clear();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        icon: const Icon(Icons.send, size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.all(12),
                        ),
                        onPressed: () {
                          if (_chatTextController.text.trim().isNotEmpty) {
                            ref.read(liveClassRoomProvider.notifier).sendChatMessage(
                                  _chatTextController.text,
                                  userName,
                                  userRole,
                                );
                            _chatTextController.clear();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showParticipantsDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final roomState = ref.watch(liveClassRoomProvider);

            return Container(
              padding: const EdgeInsets.all(16),
              height: 480,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Participants (${roomState.participants.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      if (roomState.isHost)
                        ElevatedButton.icon(
                          onPressed: () {
                            ref.read(liveClassRoomProvider.notifier).muteAll();
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('All participants muted')),
                            );
                          },
                          icon: const Icon(Icons.mic_off, size: 14),
                          label: const Text('Mute All', style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                        ),
                    ],
                  ),
                  const Divider(color: AppColors.borderDark),
                  Expanded(
                    child: ListView.builder(
                      itemCount: roomState.participants.length,
                      itemBuilder: (context, idx) {
                        final p = roomState.participants[idx];

                        return ListTile(
                          dense: true,
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                backgroundColor: p.isHost ? AppColors.primary : AppColors.slate700,
                                child: Text(
                                  p.initials,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              if (p.isHandRaised)
                                const Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: CircleAvatar(
                                    radius: 7,
                                    backgroundColor: AppColors.warning,
                                    child: Icon(Icons.pan_tool, size: 8, color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  p.isLocal ? '${p.name} (You)' : p.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (p.isHost) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'HOST',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              if (p.deviceCount > 1) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.slate700,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${p.deviceCount} devices',
                                    style: const TextStyle(color: AppColors.slate400, fontSize: 9),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                p.isMicMuted ? Icons.mic_off : Icons.mic,
                                size: 16,
                                color: p.isMicMuted ? AppColors.error : AppColors.success,
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                p.isCameraOff ? Icons.videocam_off : Icons.videocam,
                                size: 16,
                                color: p.isCameraOff ? AppColors.slate500 : AppColors.success,
                              ),
                              if (roomState.isHost && !p.isHost) ...[
                                const SizedBox(width: 6),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 18, color: Colors.white70),
                                  color: AppColors.surfaceDark,
                                  onSelected: (action) {
                                    if (action == 'remove') {
                                      ref.read(liveClassRoomProvider.notifier).removeParticipant(p.identity);
                                    } else if (action == 'grantBoard') {
                                      ref.read(liveClassRoomProvider.notifier).grantBoardToStudent(p.identity);
                                    } else if (action == 'revokeBoard') {
                                      ref.read(liveClassRoomProvider.notifier).revokeBoardFromStudent(p.identity);
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(
                                      value: 'grantBoard',
                                      child: Text('Allow Whiteboard Draw', style: TextStyle(color: Colors.white, fontSize: 12)),
                                    ),
                                    const PopupMenuItem(
                                      value: 'revokeBoard',
                                      child: Text('Revoke Whiteboard', style: TextStyle(color: Colors.white, fontSize: 12)),
                                    ),
                                    const PopupMenuItem(
                                      value: 'remove',
                                      child: Text('Remove from Class', style: TextStyle(color: AppColors.error, fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      },
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

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(liveClassRoomProvider);
    final user = ref.watch(authStateProvider).user;
    final userName = user?.name ?? 'User';

    // 1. Zoom & Google Meet Style Pre-Join Lobby (Green Room)
    if (_isInLobby) {
      return _buildLobbyScreen(user);
    }

    if (roomState.isConnecting) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const CircularProgressIndicator(color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              const Text(
                'Connecting to Live Room...',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              const Text(
                'Establishing secure media session and interactive canvas',
                style: TextStyle(color: AppColors.slate400, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    if (roomState.errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 56),
                const SizedBox(height: 16),
                const Text(
                  'Failed to Join Live Room',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  roomState.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.slate400, fontSize: 13),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _isInLobby = true;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: AppColors.borderDark),
                      ),
                      child: const Text('Back to Lobby'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        ref.read(liveClassRoomProvider.notifier).joinRoom(
                              widget.classId,
                              currentUserId: user?.id,
                              currentUserName: user?.name,
                              currentUserRole: user?.role,
                              initialMicMuted: !_lobbyMicEnabled,
                              initialCameraOff: !_lobbyCameraEnabled,
                              prewarmVideoTrack: _lobbyVideoTrack,
                            );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    final liveClass = roomState.liveClass;

    return Scaffold(
      backgroundColor: AppColors.slate900,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(liveClass, roomState),

            // Main Stage Area (Document Presenter, Whiteboard, or Video Feeds)
            Expanded(
              child: _isDocPresenterOpen
                  ? _buildDocumentPresentationStage()
                  : roomState.isWhiteboardOpen
                      ? DigitalBoard(isTeacher: roomState.isHost || roomState.isBoardAllowed)
                      : _buildVideoStage(roomState),
            ),

            // Bottom Controls Toolbar
            _buildControlsBar(roomState, userName),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(LiveClassModel? liveClass, LiveClassRoomState roomState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.surfaceDark,
      child: Row(
        children: [
          // LIVE pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.liveRed,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Icon(Icons.fiber_manual_record, color: Colors.white, size: 8),
                SizedBox(width: 4),
                Text('LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Title & Batch
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  liveClass?.title ?? 'Live Class',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${liveClass?.batchName ?? 'Batch'} • Host: ${liveClass?.teacherName ?? 'Teacher'}',
                  style: const TextStyle(color: AppColors.slate400, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Connection status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: roomState.connectionState == 'connected'
                  ? AppColors.success.withValues(alpha: 0.2)
                  : AppColors.warning.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: roomState.connectionState == 'connected' ? AppColors.success : AppColors.warning,
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 6,
                  color: roomState.connectionState == 'connected' ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(width: 4),
                Text(
                  roomState.connectionState == 'connected' ? 'Connected' : 'Connecting...',
                  style: TextStyle(
                    color: roomState.connectionState == 'connected' ? AppColors.success : AppColors.warning,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Leave / End button
          ElevatedButton(
            onPressed: () async {
              if (roomState.isHost) {
                await ref.read(liveClassRoomProvider.notifier).endClass();
              } else {
                ref.read(liveClassRoomProvider.notifier).leaveRoom();
              }
              if (mounted) context.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.liveRed,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(56, 30),
            ),
            child: Text(
              roomState.isHost ? 'End Class' : 'Leave',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoStage(LiveClassRoomState roomState) {
    // Find teacher / host participant
    final hostParticipant = roomState.participants.firstWhere(
      (p) => p.isHost,
      orElse: () => ClassParticipant(
        identity: 'host',
        name: roomState.liveClass?.teacherName ?? 'Teacher',
        role: 'TEACHER',
        isHost: true,
      ),
    );

    // Other student participants (limit to max 9 tiles for students per C3 rule)
    final otherParticipants = roomState.participants.where((p) => !p.isHost).take(9).toList();

    // Determine hero video track
    lk.VideoTrack? heroVideoTrack;
    if (hostParticipant.isLocal) {
      if (roomState.localVideoTrack != null && !roomState.isCameraOff) {
        heroVideoTrack = roomState.localVideoTrack;
      }
    } else {
      if (roomState.remoteVideoTracks.containsKey(hostParticipant.identity) && !hostParticipant.isCameraOff) {
        heroVideoTrack = roomState.remoteVideoTracks[hostParticipant.identity];
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColors.backgroundDark,
      child: Column(
        children: [
          // Hero Box (Host / Teacher / Active Speaker)
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hostParticipant.isSpeaking ? AppColors.success : AppColors.primary,
                  width: 2,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  if (heroVideoTrack != null)
                    Positioned.fill(
                      child: lk.VideoTrackRenderer(
                        heroVideoTrack,
                        fit: lk.VideoViewFit.cover,
                      ),
                    )
                  else
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              hostParticipant.initials,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            hostParticipant.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                hostParticipant.isMicMuted ? Icons.mic_off : Icons.graphic_eq,
                                color: hostParticipant.isMicMuted ? AppColors.error : AppColors.primaryLight,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                hostParticipant.isMicMuted ? 'Microphone Muted' : 'Speaking (Host)',
                                style: const TextStyle(color: AppColors.slate400, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  // Bottom left badge with name and mic status
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            hostParticipant.isMicMuted ? Icons.mic_off : Icons.mic,
                            color: hostParticipant.isMicMuted ? AppColors.error : AppColors.success,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            hostParticipant.name,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Secondary Peer Tiles Grid (deduplicated, real names)
          Expanded(
            flex: 1,
            child: otherParticipants.isEmpty
                ? Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'Waiting for students to join room...',
                        style: TextStyle(color: AppColors.slate400, fontSize: 12),
                      ),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: otherParticipants.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final p = otherParticipants[index];
                      return SizedBox(
                        width: 120,
                        child: _buildParticipantTile(p, roomState),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantTile(ClassParticipant p, LiveClassRoomState roomState) {
    lk.VideoTrack? tileVideoTrack;
    if (p.isLocal) {
      if (roomState.localVideoTrack != null && !roomState.isCameraOff) {
        tileVideoTrack = roomState.localVideoTrack;
      }
    } else {
      if (roomState.remoteVideoTracks.containsKey(p.identity) && !p.isCameraOff) {
        tileVideoTrack = roomState.remoteVideoTracks[p.identity];
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: p.isSpeaking ? AppColors.success : (p.isHandRaised ? AppColors.warning : AppColors.borderDark),
          width: p.isSpeaking || p.isHandRaised ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (tileVideoTrack != null)
            Positioned.fill(
              child: lk.VideoTrackRenderer(
                tileVideoTrack,
                fit: lk.VideoViewFit.cover,
              ),
            )
          else
            Center(
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.slate700,
                child: Text(
                  p.initials,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
          if (p.isHandRaised)
            const Positioned(
              top: 6,
              right: 6,
              child: Icon(Icons.pan_tool, color: AppColors.warning, size: 14),
            ),
          Positioned(
            bottom: 6,
            left: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      p.isLocal ? '${p.name} (You)' : p.name,
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    p.isMicMuted ? Icons.mic_off : Icons.mic,
                    color: p.isMicMuted ? AppColors.error : AppColors.success,
                    size: 11,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsBar(LiveClassRoomState roomState, String userName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: AppColors.surfaceDark,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Mic Toggle
            _buildControlButton(
              icon: roomState.isMicMuted ? Icons.mic_off : Icons.mic,
              label: roomState.isMicMuted ? 'Unmute' : 'Mute',
              isActive: !roomState.isMicMuted,
              color: roomState.isMicMuted ? AppColors.error : AppColors.slate100,
              onTap: () => ref.read(liveClassRoomProvider.notifier).toggleMic(),
            ),

            // Camera Toggle
            _buildControlButton(
              icon: roomState.isCameraOff ? Icons.videocam_off : Icons.videocam,
              label: roomState.isCameraOff ? 'Start Video' : 'Stop Video',
              isActive: !roomState.isCameraOff,
              color: roomState.isCameraOff ? AppColors.error : AppColors.slate100,
              onTap: () => ref.read(liveClassRoomProvider.notifier).toggleCamera(),
            ),

            // Digital Whiteboard
            _buildControlButton(
              icon: Icons.draw_outlined,
              label: roomState.isWhiteboardOpen ? 'Close Board' : 'Board',
              isActive: roomState.isWhiteboardOpen,
              color: roomState.isWhiteboardOpen ? AppColors.primary : AppColors.slate100,
              onTap: () {
                if (_isDocPresenterOpen) {
                  setState(() => _isDocPresenterOpen = false);
                }
                ref.read(liveClassRoomProvider.notifier).toggleWhiteboard();
              },
            ),

            // PPT / PDF Presentation Button
            _buildControlButton(
              icon: Icons.picture_as_pdf_outlined,
              label: _isDocPresenterOpen ? 'Close Doc' : 'PPT / PDF',
              isActive: _isDocPresenterOpen,
              color: _isDocPresenterOpen ? AppColors.skyBlue : AppColors.slate100,
              onTap: _toggleDocPresenter,
            ),

            // Chat Button with Unread Badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                _buildControlButton(
                  icon: Icons.chat_bubble_outline,
                  label: 'Chat',
                  isActive: false,
                  onTap: _showChatDrawer,
                ),
                if (roomState.unreadChatCount > 0)
                  Positioned(
                    top: -2,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.liveRed,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '${roomState.unreadChatCount}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),

            // Participants Sheet
            _buildControlButton(
              icon: Icons.people_outline,
              label: 'People (${roomState.participants.length})',
              isActive: false,
              onTap: _showParticipantsDrawer,
            ),

            // Hand Raise for students / Mute All for teacher
            if (roomState.isHost)
              _buildControlButton(
                icon: Icons.volume_off,
                label: 'Mute All',
                isActive: false,
                color: AppColors.error,
                onTap: () => ref.read(liveClassRoomProvider.notifier).muteAll(),
              )
            else
              _buildControlButton(
                icon: Icons.pan_tool_outlined,
                label: roomState.isHandRaised ? 'Lower' : 'Raise',
                isActive: roomState.isHandRaised,
                color: roomState.isHandRaised ? AppColors.warning : AppColors.slate100,
                onTap: () => ref.read(liveClassRoomProvider.notifier).toggleHandRaise(userName),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    Color? color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.slate800,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color ?? Colors.white, size: 18),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color ?? AppColors.slate400,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* -------------------------------------------------------------------------- */
  /* PPT / PDF LIVE DOCUMENT PRESENTER (User Feature Request)                  */
  /* -------------------------------------------------------------------------- */
  void _toggleDocPresenter() {
    if (_isDocPresenterOpen) {
      setState(() => _isDocPresenterOpen = false);
    } else {
      _showDocPickerSheet();
    }
  }

  void _showDocPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.slideshow_rounded, color: AppColors.skyBlue, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Present PPT / PDF to Class',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.slate400),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Select lecture material or upload slides to present on the live classroom stage:',
              style: TextStyle(color: AppColors.slate400, fontSize: 12),
            ),
            const SizedBox(height: 16),
            _buildDocOptionTile(
              icon: Icons.slideshow,
              color: Colors.orangeAccent,
              title: 'Electromagnetic Induction — Lecture Slides (PPTX)',
              subtitle: '8 Interactive Slides • Class 12 Physics JEE',
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _isDocPresenterOpen = true;
                  _currentDocTitle = 'Electromagnetic Induction — Lecture Slides.pptx';
                  _currentSlideNumber = 1;
                });
              },
            ),
            const SizedBox(height: 10),
            _buildDocOptionTile(
              icon: Icons.picture_as_pdf,
              color: Colors.redAccent,
              title: 'Formulas & Derivations Quick Reference (PDF)',
              subtitle: '8 Pages • Comprehensive Physics Formula Sheet',
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _isDocPresenterOpen = true;
                  _currentDocTitle = 'Formulas & Derivations Reference.pdf';
                  _currentSlideNumber = 1;
                });
              },
            ),
            const SizedBox(height: 10),
            _buildDocOptionTile(
              icon: Icons.folder_open_rounded,
              color: AppColors.skyBlue,
              title: 'Choose PDF / PPT From Device',
              subtitle: 'Select presentation file directly from phone storage',
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf', 'ppt', 'pptx'],
                  );
                  if (result != null && result.files.isNotEmpty) {
                    final pickedFile = result.files.first;
                    setState(() {
                      _isDocPresenterOpen = true;
                      _currentDocTitle = pickedFile.name;
                      _currentSlideNumber = 1;
                    });
                  }
                } catch (e) {
                  _showCustomDocLinkDialog();
                }
              },
            ),
            const SizedBox(height: 10),
            _buildDocOptionTile(
              icon: Icons.link_rounded,
              color: Colors.purpleAccent,
              title: 'Enter Cloud / Drive Link',
              subtitle: 'Present via web URL or Google Drive link',
              onTap: () {
                Navigator.pop(ctx);
                _showCustomDocLinkDialog();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildDocOptionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: AppColors.slate400, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.slate400, size: 18),
          ],
        ),
      ),
    );
  }

  void _showCustomDocLinkDialog() {
    final controller = TextEditingController();
    String? selectedFileName;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Row(
            children: [
              Icon(Icons.file_present_rounded, color: AppColors.skyBlue, size: 22),
              SizedBox(width: 8),
              Text('Present Document', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Direct File Picker CTA
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.skyBlue),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.folder_open, color: AppColors.skyBlue),
                label: Text(
                  selectedFileName ?? 'Select PDF / PPT From Device Storage',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: () async {
                  try {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf', 'ppt', 'pptx'],
                    );
                    if (result != null && result.files.isNotEmpty) {
                      setDialogState(() {
                        selectedFileName = result.files.first.name;
                        controller.text = result.files.first.name;
                      });
                    }
                  } catch (_) {}
                },
              ),
              const SizedBox(height: 14),
              const Row(
                children: [
                  Expanded(child: Divider(color: Color(0xFF334155))),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('OR VIA LINK', style: TextStyle(color: AppColors.slate500, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(child: Divider(color: Color(0xFF334155))),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Enter PDF / PPT Web Link (Optional):', style: TextStyle(color: AppColors.slate400, fontSize: 12)),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'https://... (or leave empty if file chosen)',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.slate400))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.skyBlue),
              onPressed: () {
                final chosen = selectedFileName ?? controller.text.trim();
                if (chosen.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a file or enter a link')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                setState(() {
                  _isDocPresenterOpen = true;
                  _currentDocTitle = chosen.split('/').last;
                  _currentSlideNumber = 1;
                });
              },
              child: const Text('Start Presenting'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentPresentationStage() {
    return Container(
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          // Presentation Stage Top Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              border: Border(bottom: BorderSide(color: Color(0xFF334155), width: 1)),
            ),
            child: Row(
              children: [
                Icon(
                  _currentDocTitle.endsWith('.pdf') ? Icons.picture_as_pdf : Icons.slideshow_rounded,
                  color: _currentDocTitle.endsWith('.pdf') ? Colors.redAccent : Colors.orangeAccent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentDocTitle,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white, size: 22),
                  tooltip: 'Previous Slide',
                  onPressed: _currentSlideNumber > 1
                      ? () => setState(() => _currentSlideNumber--)
                      : null,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Text(
                    '$_currentSlideNumber / $_totalSlides',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white, size: 22),
                  tooltip: 'Next Slide',
                  onPressed: _currentSlideNumber < _totalSlides
                      ? () => setState(() => _currentSlideNumber++)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.folder_open, color: AppColors.skyBlue, size: 20),
                  tooltip: 'Switch Document',
                  onPressed: _showDocPickerSheet,
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.liveRed, size: 20),
                  tooltip: 'Close Presentation',
                  onPressed: () => setState(() => _isDocPresenterOpen = false),
                ),
              ],
            ),
          ),

          // Slide Display Canvas
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildSlideContent(_currentSlideNumber),
              ),
            ),
          ),

          // Quick Slide Navigation Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: const Color(0xFF1E293B),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_totalSlides, (idx) {
                  final slideNum = idx + 1;
                  final isCurrent = slideNum == _currentSlideNumber;
                  return InkWell(
                    onTap: () => setState(() => _currentSlideNumber = slideNum),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isCurrent ? AppColors.skyBlue : const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isCurrent ? AppColors.skyBlue : const Color(0xFF334155),
                        ),
                      ),
                      child: Text(
                        'Slide $slideNum',
                        style: TextStyle(
                          color: isCurrent ? Colors.white : AppColors.slate400,
                          fontSize: 11,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlideContent(int slideNum) {
    final slides = [
      {
        'title': 'Chapter 6: Electromagnetic Induction',
        'subtitle': 'IIT-JEE Physics • Concept & Theory Lecture',
        'formula': r'Φ_B = ∫ B · dA = B A cos(θ)',
        'bullets': [
          'Magnetic flux measures the total magnetic field lines passing through a given surface area.',
          'Unit of Magnetic Flux: Weber (Wb) or Tesla·m².',
          'Scalar quantity: Can be positive, negative, or zero based on angle θ.',
        ],
      },
      {
        'title': "Faraday's Laws of Induction",
        'subtitle': 'Fundamental Discovery of Induced Electromotive Force',
        'formula': r'ℰ = - (dΦ_B / dt)',
        'bullets': [
          'Whenever magnetic flux linked with a circuit changes, an EMF is induced in the circuit.',
          'Magnitude of induced EMF is directly proportional to rate of change of magnetic flux.',
          'For a coil having N turns: ℰ = - N · (dΦ_B / dt).',
        ],
      },
      {
        'title': "Lenz's Law & Energy Conservation",
        'subtitle': 'Direction of Induced Current',
        'formula': r'Sign (-) in Faraday’s Law represents Lenz’s Law',
        'bullets': [
          'Induced current always flows in such a direction as to oppose the change producing it.',
          'Direct manifestation of the Law of Conservation of Energy.',
          'Mechanical work done in moving a magnet is converted into electrical energy.',
        ],
      },
      {
        'title': 'Motional Electromotive Force',
        'subtitle': 'Conductor Moving in a Uniform Magnetic Field',
        'formula': r'ℰ = B · l · v  (for v ⊥ B and l ⊥ B)',
        'bullets': [
          'Lorentz force acts on free electrons: F = q(v × B).',
          'Current induced in closed loop: I = (B · l · v) / R.',
          'Retarding magnetic force: F_mag = (B² · l² · v) / R.',
        ],
      },
      {
        'title': 'Eddy Currents & Applications',
        'subtitle': 'Circulating Currents Induced in Bulk Conductors',
        'formula': r'P_loss = (k · f² · B_max² · d²) / ρ',
        'bullets': [
          'Eddy currents are induced in metal blocks when subjected to changing magnetic fields.',
          'Useful in: Electromagnetic braking in trains, Induction furnaces, Electric meters.',
          'Minimized by using laminated cores in transformers.',
        ],
      },
      {
        'title': 'Self-Inductance (L)',
        'subtitle': 'Inertia of Electricity & Back EMF',
        'formula': r'ℰ_back = - L · (dI / dt),   L = (μ₀ · N² · A) / l',
        'bullets': [
          'Phenomenon where changing current in a coil induces EMF in the same coil.',
          'Unit: Henry (H).',
          'Magnetic energy stored in inductor: U_B = ½ · L · I².',
        ],
      },
      {
        'title': 'Mutual Inductance (M)',
        'subtitle': 'Coupling Between Two Coaxial Solenoids',
        'formula': r'ℰ₂ = - M · (dI₁ / dt),   M = (μ₀ · N₁ · N₂ · A) / l',
        'bullets': [
          'EMF induced in secondary coil due to rate of change of current in primary coil.',
          'Reciprocity Theorem: M₁₂ = M₂₁ = M.',
          'Coefficient of coupling: k = M / √(L₁ · L₂), where 0 ≤ k ≤ 1.',
        ],
      },
      {
        'title': 'JEE Advanced Practice Problem',
        'subtitle': 'Rotating Rod in a Transverse Magnetic Field',
        'formula': r'ℰ = ½ · B · ω · R²',
        'bullets': [
          'A metallic rod of length R rotates with constant angular speed ω in perpendicular field B.',
          'Potential difference developed across ends: V = ½ · B · ω · R².',
          'Current in connected circuit: I = (B · ω · R²) / (2 · R_circuit).',
        ],
      },
    ];

    final slideData = slides[(slideNum - 1) % slides.length];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.skyBlueLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('SLIDE $slideNum OF $_totalSlides', style: const TextStyle(color: AppColors.skyBlue, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const Row(
                children: [
                  Icon(Icons.school, size: 16, color: AppColors.slate500),
                  SizedBox(width: 4),
                  Text('Classora Live Classroom', style: TextStyle(color: AppColors.slate500, fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            slideData['title'] as String,
            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            slideData['subtitle'] as String,
            style: const TextStyle(color: AppColors.slate500, fontSize: 12),
          ),
          const SizedBox(height: 16),
          // Formula Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.functions, color: AppColors.skyBlue, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    slideData['formula'] as String,
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Key Concept Bullet Points
          ...((slideData['bullets'] as List<String>).map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: Icon(Icons.fiber_manual_record, size: 7, color: AppColors.skyBlue),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    b,
                    style: const TextStyle(color: Color(0xFF334155), fontSize: 13, height: 1.35),
                  ),
                ),
              ],
            ),
          ))),
        ],
      ),
    );
  }

  Widget _buildLobbyScreen(dynamic user) {
    final isTeacher = user?.role == 'TEACHER' || user?.role == 'ADMIN';
    final title = _lobbyClass?.title ?? 'Live Classroom';
    final batch = _lobbyClass?.batchName ?? 'Class';
    final teacher = _lobbyClass?.teacherName ?? 'Teacher';

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            _stopLobbyCamera();
            if (mounted) context.pop();
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '$batch • Host: $teacher',
              style: const TextStyle(fontSize: 11, color: AppColors.slate400),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: _isLoadingLobby
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Heading
                    const Text(
                      'Ready to join?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Set up your camera and microphone before entering the class.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.slate400),
                    ),
                    const SizedBox(height: 20),

                    // Camera Preview Card (Zoom / Google Meet Style)
                    Container(
                      height: 320,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _lobbyCameraEnabled ? AppColors.primary : AppColors.borderDark,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Live camera preview or avatar placeholder
                          if (_lobbyCameraEnabled && _lobbyVideoTrack != null)
                            Positioned.fill(
                              child: lk.VideoTrackRenderer(
                                _lobbyVideoTrack!,
                                fit: lk.VideoViewFit.cover,
                              ),
                            )
                          else
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 46,
                                  backgroundColor: AppColors.primary,
                                  child: Text(
                                    (user?.name != null && user!.name.isNotEmpty)
                                        ? user.name.substring(0, 1).toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      fontSize: 34,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  user?.name ?? 'You',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Camera is off',
                                  style: TextStyle(color: AppColors.slate400, fontSize: 12),
                                ),
                              ],
                            ),

                          // Pre-join Quick Controls (Mic & Cam toggle pills overlaid at bottom)
                          Positioned(
                            bottom: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Mic Toggle
                                  InkWell(
                                    onTap: _toggleLobbyMic,
                                    borderRadius: BorderRadius.circular(24),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: _lobbyMicEnabled ? AppColors.surfaceDark : AppColors.error,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _lobbyMicEnabled ? Icons.mic : Icons.mic_off,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  // Camera Toggle
                                  InkWell(
                                    onTap: _toggleLobbyCamera,
                                    borderRadius: BorderRadius.circular(24),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: _lobbyCameraEnabled ? AppColors.surfaceDark : AppColors.error,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _lobbyCameraEnabled ? Icons.videocam : Icons.videocam_off,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Media Status Summary Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLobbyBadge(
                          icon: _lobbyMicEnabled ? Icons.mic : Icons.mic_off,
                          label: _lobbyMicEnabled ? 'Mic On' : 'Mic Off',
                          isPositive: _lobbyMicEnabled,
                        ),
                        const SizedBox(width: 12),
                        _buildLobbyBadge(
                          icon: _lobbyCameraEnabled ? Icons.videocam : Icons.videocam_off,
                          label: _lobbyCameraEnabled ? 'Camera On' : 'Camera Off',
                          isPositive: _lobbyCameraEnabled,
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Action Buttons
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        icon: Icon(
                          isTeacher ? Icons.play_arrow : Icons.login,
                          color: Colors.white,
                        ),
                        label: Text(
                          isTeacher ? 'Start Class Now' : 'Join Classroom Now',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 4,
                        ),
                        onPressed: _enterClassroom,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.borderDark),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          _stopLobbyCamera();
                          if (mounted) context.pop();
                        },
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLobbyBadge({
    required IconData icon,
    required String label,
    required bool isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (isPositive ? AppColors.success : AppColors.error).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isPositive ? AppColors.success : AppColors.error).withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isPositive ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isPositive ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}
