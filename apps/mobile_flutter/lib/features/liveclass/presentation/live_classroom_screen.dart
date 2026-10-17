import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/live_class_model.dart';
import '../domain/class_participant.dart';
import 'live_class_controller.dart';
import 'live_class_room_controller.dart';
import '../../../screens/classroom/components/digital_board.dart';
import '../../../core/services/pip_service.dart';

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

  // Real In-Class Session Elapsed Timer (Rule: zero fake timers)
  Timer? _sessionTimer;
  int _sessionSeconds = 0;

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

    _startSessionTimer();

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

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionSeconds = 0;
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _sessionSeconds++;
        });
      }
    });
  }

  String _formatSessionTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _lobbyVideoTrack?.stop();
    _chatTextController.dispose();
    super.dispose();
  }

  Future<void> _handleLeaveOrEnd(bool isHost) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: isHost ? 'End Live Class?' : 'Leave Live Class?',
      message: isHost
          ? 'This will end the live class session for all students and participants.'
          : 'Are you sure you want to leave this live classroom session?',
      confirmText: isHost ? 'End Class' : 'Leave',
      cancelText: 'Cancel',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      if (isHost) {
        await ref.read(liveClassRoomProvider.notifier).endClass();
      } else {
        ref.read(liveClassRoomProvider.notifier).leaveRoom();
      }
      if (mounted) context.pop();
    }
  }

  void _showChatDrawer() {
    final user = ref.read(authStateProvider).user;
    final userName = user?.name ?? 'User';
    final userRole = user?.role ?? 'STUDENT';
    ref.read(liveClassRoomProvider.notifier).markChatRead();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
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
                  const Divider(color: Color(0xFF334155)),
                  Expanded(
                    child: roomState.chatMessages.isEmpty
                        ? const Center(
                            child: Text(
                              'No messages yet. Ask doubt or message the class!',
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
                                    color: isMe ? AppColors.primary : const Color(0xFF0F172A),
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(14),
                                      topRight: const Radius.circular(14),
                                      bottomLeft: Radius.circular(isMe ? 14 : 2),
                                      bottomRight: Radius.circular(isMe ? 2 : 14),
                                    ),
                                    border: isMe ? null : Border.all(color: const Color(0xFF334155)),
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
                            hintText: 'Type doubt or message...',
                            hintStyle: const TextStyle(color: AppColors.slate400, fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: Color(0xFF334155)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: Color(0xFF334155)),
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
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final roomState = ref.watch(liveClassRoomProvider);

            // Sort participants: Hand raised first, then host, then local, then alphabetical
            final sortedParticipants = List<ClassParticipant>.from(roomState.participants)
              ..sort((a, b) {
                if (a.isHandRaised != b.isHandRaised) {
                  return a.isHandRaised ? -1 : 1;
                }
                if (a.isHost != b.isHost) {
                  return a.isHost ? -1 : 1;
                }
                if (a.isLocal != b.isLocal) {
                  return a.isLocal ? -1 : 1;
                }
                return a.name.compareTo(b.name);
              });

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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('All participants muted')),
                            );
                          },
                          icon: const Icon(Icons.mic_off, size: 14),
                          label: const Text('Mute All', style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                        ),
                    ],
                  ),
                  const Divider(color: Color(0xFF334155)),
                  Expanded(
                    child: sortedParticipants.isEmpty
                        ? const Center(
                            child: Text(
                              'No participants in classroom yet',
                              style: TextStyle(color: AppColors.slate400, fontSize: 13),
                            ),
                          )
                        : ListView.builder(
                            itemCount: sortedParticipants.length,
                            itemBuilder: (context, idx) {
                              final p = sortedParticipants[idx];

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
                                    if (p.isHandRaised) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.warning.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: AppColors.warning, width: 0.5),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.pan_tool, size: 9, color: AppColors.warning),
                                            SizedBox(width: 3),
                                            Text(
                                              'Hand Raised',
                                              style: TextStyle(
                                                color: AppColors.warning,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
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
                                        color: const Color(0xFF0F172A),
                                        onSelected: (action) {
                                          if (action == 'remove') {
                                            ref.read(liveClassRoomProvider.notifier).removeParticipant(p.identity);
                                          } else if (action == 'grantBoard') {
                                            ref.read(liveClassRoomProvider.notifier).grantBoardToStudent(p.identity);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Allowed ${p.name} to draw on board')),
                                            );
                                          } else if (action == 'revokeBoard') {
                                            ref.read(liveClassRoomProvider.notifier).revokeBoardFromStudent(p.identity);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Revoked board drawing from ${p.name}')),
                                            );
                                          }
                                        },
                                        itemBuilder: (ctx) => [
                                          const PopupMenuItem(
                                            value: 'grantBoard',
                                            child: Text('Allow Board Draw', style: TextStyle(color: Colors.white, fontSize: 12)),
                                          ),
                                          const PopupMenuItem(
                                            value: 'revokeBoard',
                                            child: Text('Revoke Board Draw', style: TextStyle(color: Colors.white, fontSize: 12)),
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

  void _showMoreActionsSheet(LiveClassRoomState roomState, String userName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'More Options',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.slate400),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(color: Color(0xFF334155)),
              if (!roomState.isHost) ...[
                ListTile(
                  leading: Icon(
                    roomState.isHandRaised ? Icons.pan_tool : Icons.pan_tool_outlined,
                    color: roomState.isHandRaised ? AppColors.warning : Colors.white,
                  ),
                  title: Text(
                    roomState.isHandRaised ? 'Lower Hand' : 'Raise Hand',
                    style: TextStyle(
                      color: roomState.isHandRaised ? AppColors.warning : Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    roomState.isHandRaised ? 'Teacher has notified your hand raise' : 'Notify teacher that you have a doubt',
                    style: const TextStyle(color: AppColors.slate400, fontSize: 11),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref.read(liveClassRoomProvider.notifier).toggleHandRaise(userName);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline, color: AppColors.skyBlue),
                  title: const Text('Ask a Doubt', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Post query in live discussion chat', style: TextStyle(color: AppColors.slate400, fontSize: 11)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showChatDrawer();
                  },
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.mic_off, color: AppColors.error),
                  title: const Text('Mute All Students', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Mute everyone currently in the room', style: TextStyle(color: AppColors.slate400, fontSize: 11)),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref.read(liveClassRoomProvider.notifier).muteAll();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All participants muted')),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    roomState.isRoomLocked ? Icons.lock : Icons.lock_open,
                    color: roomState.isRoomLocked ? AppColors.warning : Colors.white,
                  ),
                  title: Text(
                    roomState.isRoomLocked ? 'Unlock Classroom' : 'Lock Classroom',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    roomState.isRoomLocked ? 'New students cannot enter until unlocked' : 'Prevent new entries into session',
                    style: const TextStyle(color: AppColors.slate400, fontSize: 11),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref.read(liveClassRoomProvider.notifier).toggleLockRoom();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          roomState.isRoomLocked ? 'Classroom unlocked' : 'Classroom locked to new entries',
                        ),
                      ),
                    );
                  },
                ),
              ],
              ListTile(
                key: const Key('enter_pip_menu_tile'),
                leading: const Icon(Icons.picture_in_picture_alt, color: AppColors.skyBlue),
                title: const Text('Picture-in-Picture', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Minimize class to a floating window', style: TextStyle(color: AppColors.slate400, fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _enterPip();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _enterPip() async {
    final pipService = ref.read(pipServiceProvider);
    final entered = await pipService.enterPip(width: 16, height: 9);
    if (!entered && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Picture-in-Picture is not supported on this device/platform'),
          duration: Duration(seconds: 2),
        ),
      );
    }
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
        backgroundColor: const Color(0xFF0F172A),
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
                'Connecting to Live Classroom...',
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
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 56),
                const SizedBox(height: 16),
                const Text(
                  'Failed to Join Live Classroom',
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
                        side: const BorderSide(color: Color(0xFF334155)),
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
    final isPipActive = ref.watch(isPipActiveProvider);

    if (isPipActive) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: _buildVideoStage(roomState),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(liveClass, roomState),

            // Reconnection Alert Banner (Design Spec: Section 6)
            if (roomState.connectionState == 'reconnecting') _buildReconnectBanner(),

            // Main Stage Area (Whiteboard or Meet-like Video Stage)
            Expanded(
              child: roomState.isWhiteboardOpen
                  ? DigitalBoard(isTeacher: roomState.isHost || roomState.isBoardAllowed)
                  : _buildVideoStage(roomState),
            ),

            // Google Meet Style Bottom Controls Toolbar (8 Controls)
            _buildControlsBar(roomState, userName),
          ],
        ),
      ),
    );
  }

  Widget _buildReconnectBanner() {
    return Container(
      width: double.infinity,
      color: AppColors.warning.withValues(alpha: 0.9),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Connection unstable. Attempting to reconnect...',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(LiveClassModel? liveClass, LiveClassRoomState roomState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(bottom: BorderSide(color: Color(0xFF334155), width: 1)),
      ),
      child: Row(
        children: [
          // Red LIVE pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.liveRed,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: Colors.white, size: 7),
                SizedBox(width: 4),
                Text('LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Elapsed Session Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Text(
              _formatSessionTime(_sessionSeconds),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Title & Batch Info (with ellipsis for overflow safety at 320/360 dp)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  liveClass?.title ?? 'Live Class',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  '${liveClass?.batchName ?? 'Batch'} • Host: ${liveClass?.teacherName ?? 'Teacher'}',
                  style: const TextStyle(color: AppColors.slate400, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
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
                  : (roomState.connectionState == 'reconnecting'
                      ? AppColors.warning.withValues(alpha: 0.2)
                      : AppColors.slate700),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: roomState.connectionState == 'connected'
                    ? AppColors.success
                    : (roomState.connectionState == 'reconnecting'
                        ? AppColors.warning
                        : AppColors.slate500),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 6,
                  color: roomState.connectionState == 'connected'
                      ? AppColors.success
                      : (roomState.connectionState == 'reconnecting'
                          ? AppColors.warning
                          : AppColors.slate400),
                ),
                const SizedBox(width: 4),
                Text(
                  roomState.connectionState == 'connected'
                      ? 'Connected'
                      : (roomState.connectionState == 'reconnecting' ? 'Reconnecting' : 'Connecting'),
                  style: TextStyle(
                    color: roomState.connectionState == 'connected'
                        ? AppColors.success
                        : (roomState.connectionState == 'reconnecting'
                            ? AppColors.warning
                            : AppColors.slate400),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Picture-in-Picture Button
          IconButton(
            key: const Key('enter_pip_topbar_btn'),
            tooltip: 'Picture-in-Picture',
            icon: const Icon(Icons.picture_in_picture_alt, size: 18, color: Colors.white70),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: _enterPip,
          ),
          const SizedBox(width: 8),

          // Leave / End button (triggers ConfirmDialog)
          ElevatedButton(
            onPressed: () => _handleLeaveOrEnd(roomState.isHost),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.liveRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(54, 30),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              roomState.isHost ? 'End' : 'Leave',
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

    // Other student participants (limit to max 9 tiles per page per DESIGN.md Section 6)
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
      } else if (roomState.remoteVideoTracks.isNotEmpty) {
        heroVideoTrack = roomState.remoteVideoTracks.values.first;
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          // Hero Box (Host / Teacher / Active Speaker)
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hostParticipant.isSpeaking ? AppColors.success : const Color(0xFF334155),
                  width: hostParticipant.isSpeaking ? 2 : 1,
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
                        mainAxisSize: MainAxisSize.min,
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

          // Secondary Peer Tiles Strip (deduplicated real participants, max 9)
          Expanded(
            flex: 1,
            child: otherParticipants.isEmpty
                ? Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'Waiting for students to join classroom...',
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
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: p.isSpeaking ? AppColors.success : (p.isHandRaised ? AppColors.warning : const Color(0xFF334155)),
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

  // Google Meet Style Bottom Bar (8 Controls)
  Widget _buildControlsBar(LiveClassRoomState roomState, String userName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(top: BorderSide(color: Color(0xFF334155), width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // 1. Mic Toggle
            _buildControlButton(
              icon: roomState.isMicMuted ? Icons.mic_off : Icons.mic,
              label: roomState.isMicMuted ? 'Unmute' : 'Mute',
              isActive: !roomState.isMicMuted,
              color: roomState.isMicMuted ? AppColors.error : AppColors.slate100,
              onTap: () => ref.read(liveClassRoomProvider.notifier).toggleMic(),
            ),

            // 2. Camera Toggle
            _buildControlButton(
              icon: roomState.isCameraOff ? Icons.videocam_off : Icons.videocam,
              label: roomState.isCameraOff ? 'Start Video' : 'Stop Video',
              isActive: !roomState.isCameraOff,
              color: roomState.isCameraOff ? AppColors.error : AppColors.slate100,
              onTap: () => ref.read(liveClassRoomProvider.notifier).toggleCamera(),
            ),

            // 3. Share Screen (Teacher) or Raise Hand (Student)
            if (roomState.isHost)
              _buildControlButton(
                icon: roomState.isScreenSharing ? Icons.stop_screen_share : Icons.screen_share,
                label: roomState.isScreenSharing ? 'Stop Share' : 'Share Screen',
                isActive: roomState.isScreenSharing,
                color: roomState.isScreenSharing ? AppColors.skyBlue : AppColors.slate100,
                onTap: () => ref.read(liveClassRoomProvider.notifier).toggleScreenShare(),
              )
            else
              _buildControlButton(
                icon: roomState.isHandRaised ? Icons.pan_tool : Icons.pan_tool_outlined,
                label: roomState.isHandRaised ? 'Lower Hand' : 'Raise Hand',
                isActive: roomState.isHandRaised,
                color: roomState.isHandRaised ? AppColors.warning : AppColors.slate100,
                onTap: () => ref.read(liveClassRoomProvider.notifier).toggleHandRaise(userName),
              ),

            // 4. Board (Toggle Digital Whiteboard)
            _buildControlButton(
              icon: Icons.draw_outlined,
              label: roomState.isWhiteboardOpen ? 'Close Board' : 'Board',
              isActive: roomState.isWhiteboardOpen,
              color: roomState.isWhiteboardOpen ? AppColors.primary : AppColors.slate100,
              onTap: () => ref.read(liveClassRoomProvider.notifier).toggleWhiteboard(),
            ),

            // 5. Chat Button with Unread Badge
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
                    top: 0,
                    right: 6,
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

            // 6. Participants Sheet
            _buildControlButton(
              icon: Icons.people_outline,
              label: 'People (${roomState.participants.length})',
              isActive: false,
              onTap: _showParticipantsDrawer,
            ),

            // 7. More Options (Raise hand / polls / mute all / lock room)
            _buildControlButton(
              icon: Icons.more_horiz,
              label: 'More',
              isActive: false,
              onTap: () => _showMoreActionsSheet(roomState, userName),
            ),

            // 8. Call End / Leave button
            _buildControlButton(
              icon: Icons.call_end,
              label: roomState.isHost ? 'End Class' : 'Leave',
              isActive: true,
              color: Colors.white,
              backgroundColor: AppColors.liveRed,
              onTap: () => _handleLeaveOrEnd(roomState.isHost),
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
    Color? backgroundColor,
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
                color: backgroundColor ?? (isActive ? AppColors.primary : AppColors.slate800),
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

  // Pre-join Green Room / Lobby Screen
  Widget _buildLobbyScreen(dynamic user) {
    final isTeacher = user?.role == 'TEACHER' || user?.role == 'ADMIN';
    final title = _lobbyClass?.title ?? 'Live Classroom';
    final batch = _lobbyClass?.batchName ?? 'Class';
    final teacher = _lobbyClass?.teacherName ?? 'Teacher';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
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
                      'Check your camera and microphone preview before entering the live class.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.slate400),
                    ),
                    const SizedBox(height: 20),

                    // Camera Preview Card (Zoom / Google Meet Style)
                    Container(
                      height: 320,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _lobbyCameraEnabled ? AppColors.primary : const Color(0xFF334155),
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
                                        color: _lobbyMicEnabled ? const Color(0xFF1E293B) : AppColors.error,
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
                                        color: _lobbyCameraEnabled ? const Color(0xFF1E293B) : AppColors.error,
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
                          side: const BorderSide(color: Color(0xFF334155)),
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
