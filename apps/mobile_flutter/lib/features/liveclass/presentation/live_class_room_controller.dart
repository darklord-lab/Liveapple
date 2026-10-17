import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:livekit_client/livekit_client.dart' as lk;
import '../data/live_class_repository.dart';
import '../domain/live_class_model.dart';
import '../domain/class_participant.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/errors/app_exception.dart';
import 'live_class_controller.dart';

class ChatMessageItem {
  final String id;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String text;
  final DateTime timestamp;
  final bool isSystem;

  ChatMessageItem({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.text,
    required this.timestamp,
    this.isSystem = false,
  });

  factory ChatMessageItem.fromJson(Map<String, dynamic> json) {
    return ChatMessageItem(
      id: json['id'] as String? ?? 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String? ?? 'User',
      senderRole: json['senderRole'] as String? ?? 'STUDENT',
      text: json['text'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      isSystem: json['senderRole'] == 'SYSTEM',
    );
  }
}

class InClassPollItem {
  final String id;
  final String question;
  final List<PollOptionItem> options;
  final bool active;
  final bool userVoted;

  InClassPollItem({
    required this.id,
    required this.question,
    required this.options,
    required this.active,
    this.userVoted = false,
  });
}

class PollOptionItem {
  final int id;
  final String text;
  final int votes;

  PollOptionItem({required this.id, required this.text, required this.votes});
}

class RaisedHandItem {
  final String userId;
  final String userName;
  final String userRole;
  final DateTime raisedAt;

  RaisedHandItem({
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.raisedAt,
  });
}

class LiveClassRoomState {
  final LiveClassModel? liveClass;
  final bool isConnecting;
  final bool isConnected;
  final String connectionState; // 'connecting', 'connected', 'reconnecting', 'disconnected'
  final String? errorMessage;
  final bool isHost;
  final bool isMicMuted;
  final bool isCameraOff;
  final bool isScreenSharing;
  final bool isWhiteboardOpen;
  final bool isBoardAllowed;
  final bool isDocPresenting;
  final String docTitle;
  final int docPage;
  final String? activeSpeakerName;
  final List<ClassParticipant> participants;
  final List<ChatMessageItem> chatMessages;
  final int unreadChatCount;
  final List<RaisedHandItem> handsQueue;
  final List<InClassPollItem> polls;
  final bool isHandRaised;
  final bool isClassEnded;
  final bool isRoomLocked;
  final lk.LocalVideoTrack? localVideoTrack;
  final lk.LocalAudioTrack? localAudioTrack;
  final Map<String, lk.VideoTrack> remoteVideoTracks;
  final lk.VideoTrack? remoteScreenShareTrack;

  LiveClassRoomState({
    this.liveClass,
    this.isConnecting = true,
    this.isConnected = false,
    this.connectionState = 'connecting',
    this.errorMessage,
    this.isHost = false,
    this.isMicMuted = true,
    this.isCameraOff = true,
    this.isScreenSharing = false,
    this.isWhiteboardOpen = false,
    this.isBoardAllowed = false,
    this.isDocPresenting = false,
    this.docTitle = '',
    this.docPage = 1,
    this.activeSpeakerName,
    this.participants = const [],
    this.chatMessages = const [],
    this.unreadChatCount = 0,
    this.handsQueue = const [],
    this.polls = const [],
    this.isHandRaised = false,
    this.isClassEnded = false,
    this.isRoomLocked = false,
    this.localVideoTrack,
    this.localAudioTrack,
    this.remoteVideoTracks = const {},
    this.remoteScreenShareTrack,
  });

  LiveClassRoomState copyWith({
    LiveClassModel? liveClass,
    bool? isConnecting,
    bool? isConnected,
    String? connectionState,
    String? errorMessage,
    bool? isHost,
    bool? isMicMuted,
    bool? isCameraOff,
    bool? isScreenSharing,
    bool? isWhiteboardOpen,
    bool? isBoardAllowed,
    bool? isDocPresenting,
    String? docTitle,
    int? docPage,
    String? activeSpeakerName,
    List<ClassParticipant>? participants,
    List<ChatMessageItem>? chatMessages,
    int? unreadChatCount,
    List<RaisedHandItem>? handsQueue,
    List<InClassPollItem>? polls,
    bool? isHandRaised,
    bool? isClassEnded,
    bool? isRoomLocked,
    lk.LocalVideoTrack? localVideoTrack,
    lk.LocalAudioTrack? localAudioTrack,
    Map<String, lk.VideoTrack>? remoteVideoTracks,
    lk.VideoTrack? remoteScreenShareTrack,
    bool clearLocalVideo = false,
    bool clearLocalAudio = false,
    bool clearRemoteScreenShare = false,
  }) {
    return LiveClassRoomState(
      liveClass: liveClass ?? this.liveClass,
      isConnecting: isConnecting ?? this.isConnecting,
      isConnected: isConnected ?? this.isConnected,
      connectionState: connectionState ?? this.connectionState,
      errorMessage: errorMessage,
      isHost: isHost ?? this.isHost,
      isMicMuted: isMicMuted ?? this.isMicMuted,
      isCameraOff: isCameraOff ?? this.isCameraOff,
      isScreenSharing: isScreenSharing ?? this.isScreenSharing,
      isWhiteboardOpen: isWhiteboardOpen ?? this.isWhiteboardOpen,
      isBoardAllowed: isBoardAllowed ?? this.isBoardAllowed,
      isDocPresenting: isDocPresenting ?? this.isDocPresenting,
      docTitle: docTitle ?? this.docTitle,
      docPage: docPage ?? this.docPage,
      activeSpeakerName: activeSpeakerName ?? this.activeSpeakerName,
      participants: participants ?? this.participants,
      chatMessages: chatMessages ?? this.chatMessages,
      unreadChatCount: unreadChatCount ?? this.unreadChatCount,
      handsQueue: handsQueue ?? this.handsQueue,
      polls: polls ?? this.polls,
      isHandRaised: isHandRaised ?? this.isHandRaised,
      isClassEnded: isClassEnded ?? this.isClassEnded,
      isRoomLocked: isRoomLocked ?? this.isRoomLocked,
      localVideoTrack: clearLocalVideo ? null : (localVideoTrack ?? this.localVideoTrack),
      localAudioTrack: clearLocalAudio ? null : (localAudioTrack ?? this.localAudioTrack),
      remoteVideoTracks: remoteVideoTracks ?? this.remoteVideoTracks,
      remoteScreenShareTrack: clearRemoteScreenShare ? null : (remoteScreenShareTrack ?? this.remoteScreenShareTrack),
    );
  }
}

class LiveClassRoomNotifier extends StateNotifier<LiveClassRoomState> {
  final LiveClassRepository _repository;
  final SecureStorageService _storage;
  io.Socket? _socket;
  lk.Room? _liveKitRoom;
  String? _currentClassId;

  final StreamController<Map<String, dynamic>> _drawStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<void> _clearStreamController =
      StreamController<void>.broadcast();

  Stream<Map<String, dynamic>> get remoteDrawStream => _drawStreamController.stream;
  Stream<void> get remoteClearStream => _clearStreamController.stream;

  LiveClassRoomNotifier({
    LiveClassRepository? repository,
    SecureStorageService? storage,
  })  : _repository = repository ?? LiveClassRepository(),
        _storage = storage ?? SecureStorageService(),
        super(LiveClassRoomState());

  Future<void> joinRoom(
    String classId, {
    String? currentUserId,
    String? currentUserName,
    String? currentUserRole,
    bool? initialMicMuted,
    bool? initialCameraOff,
    lk.LocalVideoTrack? prewarmVideoTrack,
    lk.LocalAudioTrack? prewarmAudioTrack,
  }) async {
    _currentClassId = classId;
    state = state.copyWith(isConnecting: true, errorMessage: null, connectionState: 'connecting');

    try {
      final tokenData = await _repository.getToken(classId);
      final isHost = tokenData['isHost'] as bool? ?? false;
      final livekitToken = tokenData['token'] as String? ?? '';
      final livekitServerUrl = tokenData['serverUrl'] as String? ?? '';
      final classDetails = await _repository.getClassById(classId);

      // Initial local participant
      final localUserId = currentUserId ?? (isHost ? (classDetails.teacherId ?? 'local_host') : 'local_student');
      final localUserName = currentUserName ?? (isHost ? (classDetails.teacherName ?? 'Teacher') : 'Student');
      final localRole = currentUserRole ?? (isHost ? 'TEACHER' : 'STUDENT');

      // Use lobby-selected settings (or default: teacher on, student muted)
      final micMuted = initialMicMuted ?? !isHost;
      final cameraOff = initialCameraOff ?? !isHost;

      // Real device video track
      lk.LocalVideoTrack? videoTrack = prewarmVideoTrack;
      if (!cameraOff && videoTrack == null) {
        try {
          videoTrack = await lk.LocalVideoTrack.createCameraTrack();
        } catch (camErr) {
          debugPrint('[CAMERA] Startup note: $camErr');
        }
      }

      // Real device audio track
      lk.LocalAudioTrack? audioTrack = prewarmAudioTrack;
      if (!micMuted && audioTrack == null) {
        try {
          audioTrack = await lk.LocalAudioTrack.create();
        } catch (audErr) {
          debugPrint('[AUDIO] Startup note: $audErr');
        }
      }

      final initialParticipant = ClassParticipant(
        identity: localUserId,
        name: localUserName,
        role: localRole,
        isHost: isHost,
        isLocal: true,
        isMicMuted: micMuted,
        isCameraOff: cameraOff,
      );

      final participantsList = ClassParticipant.deduplicateAndSort([initialParticipant]);

      state = state.copyWith(
        liveClass: classDetails,
        isHost: isHost,
        isConnecting: false,
        isConnected: true,
        connectionState: 'connected',
        isMicMuted: micMuted,
        isCameraOff: cameraOff,
        isBoardAllowed: isHost,
        activeSpeakerName: classDetails.teacherName ?? 'Teacher',
        participants: participantsList,
        localVideoTrack: videoTrack,
        localAudioTrack: audioTrack,
      );

      // Connect to Socket.IO for realtime chat, hand queue, and room events
      await _initSocketConnection(classId, localUserId, localUserName, localRole);

      // Broadcast initial media state to room
      _socket?.emit('media:state', {
        'classId': classId,
        'isMicMuted': micMuted,
        'isCameraOff': cameraOff,
      });

      // Connect to LiveKit SFU (gracefully handle headless/mock environments)
      if (livekitToken.isNotEmpty && livekitServerUrl.isNotEmpty) {
        _initLiveKit(livekitServerUrl, livekitToken);
      }
    } catch (e) {
      final msg = e is AppException ? e.message : e.toString();
      state = state.copyWith(
        isConnecting: false,
        errorMessage: msg,
        connectionState: 'disconnected',
      );
    }
  }

  Future<void> _initSocketConnection(
    String classId,
    String userId,
    String userName,
    String userRole,
  ) async {
    try {
      final baseUrl = await _storage.getBaseUrl() ?? Endpoints.defaultBaseUrl;
      final uri = Uri.parse(baseUrl);
      final socketHost = uri.hasPort && uri.port != 80 && uri.port != 443
          ? '${uri.scheme}://${uri.host}:${uri.port}'
          : '${uri.scheme}://${uri.host}';
      final accessToken = await _storage.getAccessToken();

      _socket = io.io(
        socketHost,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .setAuth({'token': accessToken})
            .enableAutoConnect()
            .enableReconnection()
            .build(),
      );

      _socket?.onConnect((_) {
        debugPrint('[SOCKET] Connected to classroom gateway');
        _socket?.emit('class:join', {'classId': classId});
        state = state.copyWith(connectionState: 'connected');
      });

      _socket?.on('connect_error', (err) {
        debugPrint('[SOCKET] Connection error: $err');
      });

      // 1. Chat History (last 50 messages on join)
      _socket?.on('chat:history', (data) {
        if (data is Map && data['messages'] is List) {
          final rawMsgs = data['messages'] as List;
          final messages = rawMsgs
              .map((m) => ChatMessageItem.fromJson(m as Map<String, dynamic>))
              .toList();
          state = state.copyWith(chatMessages: messages);
        }
      });

      // 2. Realtime Chat Message delivery
      _socket?.on('chat:message', (data) {
        if (data is Map) {
          final msg = ChatMessageItem.fromJson(Map<String, dynamic>.from(data));
          // Avoid duplicate local messages
          if (!state.chatMessages.any((m) => m.id == msg.id)) {
            state = state.copyWith(
              chatMessages: [...state.chatMessages, msg],
              unreadChatCount: state.unreadChatCount + 1,
            );
          }
        }
      });

      // 3. Hand Raise Queue updates
      _socket?.on('hand:queue', (data) {
        if (data is Map && data['hands'] is List) {
          final rawHands = data['hands'] as List;
          final queue = rawHands.map((h) {
            final m = h as Map;
            return RaisedHandItem(
              userId: m['userId'] as String? ?? '',
              userName: m['userName'] as String? ?? 'Student',
              userRole: m['userRole'] as String? ?? 'STUDENT',
              raisedAt: DateTime.tryParse(m['raisedAt'] as String? ?? '') ?? DateTime.now(),
            );
          }).toList();

          // Sync participant hand raised status
          final handIds = queue.map((h) => h.userId).toSet();
          final updatedParticipants = state.participants.map((p) {
            return p.copyWith(isHandRaised: handIds.contains(p.identity));
          }).toList();

          final isMyHandRaised = handIds.contains(userId);

          state = state.copyWith(
            handsQueue: queue,
            isHandRaised: isMyHandRaised,
            participants: ClassParticipant.deduplicateAndSort(updatedParticipants),
          );
        }
      });

      // 4. Peer Joined
      _socket?.on('peer:joined', (data) {
        if (data is Map) {
          final peerId = data['userId'] as String? ?? '';
          final peerName = data['name'] as String? ?? 'Student';
          final peerRole = data['role'] as String? ?? 'STUDENT';
          final isHostPeer = peerRole == 'TEACHER' || peerRole == 'ADMIN';

          final newPeer = ClassParticipant(
            identity: peerId,
            name: peerName,
            role: peerRole,
            isHost: isHostPeer,
            isLocal: false,
            isMicMuted: true,
            isCameraOff: true,
          );

          state = state.copyWith(
            participants: ClassParticipant.deduplicateAndSort([...state.participants, newPeer]),
          );
        }
      });

      // 5. Peer Left
      _socket?.on('peer:left', (data) {
        if (data is Map) {
          final peerId = data['userId'] as String? ?? '';
          final filtered = state.participants.where((p) => p.identity != peerId).toList();
          state = state.copyWith(
            participants: ClassParticipant.deduplicateAndSort(filtered),
          );
        }
      });

      // 6. Peer Media State Sync (Mic & Camera)
      _socket?.on('peer:media:state', (data) {
        if (data is Map) {
          final peerId = data['userId'] as String? ?? '';
          final peerMicMuted = data['isMicMuted'] as bool? ?? true;
          final peerCameraOff = data['isCameraOff'] as bool? ?? true;

          final updated = state.participants.map((p) {
            if (p.identity == peerId) {
              return p.copyWith(isMicMuted: peerMicMuted, isCameraOff: peerCameraOff);
            }
            return p;
          }).toList();

          state = state.copyWith(
            participants: ClassParticipant.deduplicateAndSort(updated),
          );
        }
      });

      // 7. Host Muted All event
      _socket?.on('host:muted', (_) {
        if (!state.isHost) {
          state = state.copyWith(isMicMuted: true);
          state.localAudioTrack?.stop();
        }
      });

      // 8. Whiteboard Sync events
      _socket?.on('board:state', (data) {
        if (data is Map && data['isOpen'] is bool) {
          state = state.copyWith(isWhiteboardOpen: data['isOpen'] as bool);
        }
      });

      _socket?.on('board:granted', (data) {
        if (data is Map && data['studentId'] == userId) {
          state = state.copyWith(isBoardAllowed: true);
        }
      });

      _socket?.on('board:revoked', (data) {
        if (data is Map && data['studentId'] == userId) {
          state = state.copyWith(isBoardAllowed: false);
        }
      });

      // 8b. Realtime Whiteboard strokes sync
      _socket?.on('whiteboard:draw', (data) {
        if (data is Map && !_drawStreamController.isClosed) {
          _drawStreamController.add(Map<String, dynamic>.from(data));
        }
      });

      _socket?.on('whiteboard:clear', (_) {
        if (!_clearStreamController.isClosed) {
          _clearStreamController.add(null);
        }
      });

      // 8c. Document Presentation Sync event (Teacher presents to all students)
      _socket?.on('doc:present', (data) {
        if (data is Map) {
          final isOpen = data['isOpen'] as bool? ?? false;
          final title = data['title'] as String? ?? '';
          final page = data['page'] as int? ?? 1;
          state = state.copyWith(
            isDocPresenting: isOpen,
            docTitle: title,
            docPage: page,
          );
        }
      });

      // 9. Class Ended event
      _socket?.on('class:ended', (_) {
        state = state.copyWith(isClassEnded: true, isConnected: false);
      });

      // 10. Class became LIVE event
      _socket?.on('class:live', (data) {
        debugPrint('[SOCKET] class:live received — teacher started the class!');
        _syncExistingRemoteParticipants();
      });

      _socket?.onDisconnect((_) {
        state = state.copyWith(connectionState: 'disconnected');
      });
    } catch (e) {
      debugPrint('[SOCKET] Setup error: $e');
    }
  }

  void _initLiveKit(String serverUrl, String token) async {
    try {
      debugPrint('[LIVEKIT] Connecting to LiveKit Cloud: $serverUrl');
      _liveKitRoom = lk.Room();

      _liveKitRoom?.events.listen((event) {
        debugPrint('[LIVEKIT-EVENT] $event');
        if (event is lk.TrackSubscribedEvent) {
          if (event.track is lk.VideoTrack) {
            final vt = event.track as lk.VideoTrack;
            if (vt.source == lk.TrackSource.screenShareVideo) {
              state = state.copyWith(remoteScreenShareTrack: vt);
            } else {
              final updated = Map<String, lk.VideoTrack>.from(state.remoteVideoTracks);
              updated[event.participant.identity] = vt;
              final updatedParticipants = state.participants.map((p) {
                if (p.identity == event.participant.identity) {
                  return p.copyWith(isCameraOff: false);
                }
                return p;
              }).toList();
              state = state.copyWith(
                remoteVideoTracks: updated,
                participants: ClassParticipant.deduplicateAndSort(updatedParticipants),
              );
            }
          } else if (event.track is lk.AudioTrack) {
            final at = event.track as lk.AudioTrack;
            try {
              at.start();
            } catch (_) {}
            final updatedParticipants = state.participants.map((p) {
              if (p.identity == event.participant.identity) {
                return p.copyWith(isMicMuted: false);
              }
              return p;
            }).toList();
            state = state.copyWith(
              participants: ClassParticipant.deduplicateAndSort(updatedParticipants),
            );
          }
        } else if (event is lk.TrackUnsubscribedEvent) {
          if (event.track is lk.VideoTrack) {
            final vt = event.track as lk.VideoTrack;
            if (vt.source == lk.TrackSource.screenShareVideo) {
              state = state.copyWith(clearRemoteScreenShare: true);
            } else {
              final updated = Map<String, lk.VideoTrack>.from(state.remoteVideoTracks);
              updated.remove(event.participant.identity);
              final updatedParticipants = state.participants.map((p) {
                if (p.identity == event.participant.identity) {
                  return p.copyWith(isCameraOff: true);
                }
                return p;
              }).toList();
              state = state.copyWith(
                remoteVideoTracks: updated,
                participants: ClassParticipant.deduplicateAndSort(updatedParticipants),
              );
            }
          } else if (event.track is lk.AudioTrack) {
            final updatedParticipants = state.participants.map((p) {
              if (p.identity == event.participant.identity) {
                return p.copyWith(isMicMuted: true);
              }
              return p;
            }).toList();
            state = state.copyWith(
              participants: ClassParticipant.deduplicateAndSort(updatedParticipants),
            );
          }
        } else if (event is lk.ActiveSpeakersChangedEvent) {
          final speakerIds = event.speakers.map((s) => s.identity).toSet();
          final updatedParticipants = state.participants.map((p) {
            return p.copyWith(isSpeaking: speakerIds.contains(p.identity));
          }).toList();
          final firstSpeaker = event.speakers.isNotEmpty ? event.speakers.first.name : state.activeSpeakerName;
          state = state.copyWith(
            participants: ClassParticipant.deduplicateAndSort(updatedParticipants),
            activeSpeakerName: (firstSpeaker?.isNotEmpty ?? false) ? firstSpeaker : state.activeSpeakerName,
          );
        } else if (event is lk.ParticipantConnectedEvent) {
          final p = event.participant;
          final isHostPeer = (p.metadata?.contains('isHost":true') ?? false) ||
              p.identity.startsWith('teacher') || p.identity.startsWith('admin');
          final newPeer = ClassParticipant(
            identity: p.identity,
            name: p.name.isNotEmpty ? p.name : p.identity,
            role: isHostPeer ? 'TEACHER' : 'STUDENT',
            isHost: isHostPeer,
            isLocal: false,
            isMicMuted: true,
            isCameraOff: true,
          );
          state = state.copyWith(
            participants: ClassParticipant.deduplicateAndSort([...state.participants, newPeer]),
          );
        } else if (event is lk.ParticipantDisconnectedEvent) {
          final filtered = state.participants.where((p) => p.identity != event.participant.identity).toList();
          final updatedVideoTracks = Map<String, lk.VideoTrack>.from(state.remoteVideoTracks);
          updatedVideoTracks.remove(event.participant.identity);
          state = state.copyWith(
            participants: ClassParticipant.deduplicateAndSort(filtered),
            remoteVideoTracks: updatedVideoTracks,
          );
        }
      });

      await _liveKitRoom?.connect(serverUrl, token);
      debugPrint('[LIVEKIT] Connected successfully. Connection state: ${_liveKitRoom?.connectionState}');

      // Process already-connected remote participants
      _syncExistingRemoteParticipants();

      // If local video/audio tracks are ready and active, publish to SFU
      if (!state.isCameraOff) {
        try {
          await _liveKitRoom?.localParticipant?.setCameraEnabled(true);
        } catch (_) {}
      }
      if (!state.isMicMuted) {
        try {
          await _liveKitRoom?.localParticipant?.setMicrophoneEnabled(true);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[LIVEKIT] LiveKit initialization note: $e');
    }
  }

  /// Sync any already-connected remote participants and their published tracks.
  void _syncExistingRemoteParticipants() {
    try {
      final remoteParticipants = _liveKitRoom?.remoteParticipants;
      if (remoteParticipants == null || remoteParticipants.isEmpty) return;

      final updatedVideoTracks = Map<String, lk.VideoTrack>.from(state.remoteVideoTracks);
      final newParticipants = List<ClassParticipant>.from(state.participants);
      lk.VideoTrack? screenShareTrack;

      for (final entry in remoteParticipants.entries) {
        final p = entry.value;
        final isHostPeer = (p.metadata?.contains('isHost":true') ?? false) ||
            p.identity.startsWith('teacher') || p.identity.startsWith('admin');

        bool hasVideo = false;
        for (final trackPub in p.videoTrackPublications) {
          final vt = trackPub.track;
          if (vt != null) {
            if (vt.source == lk.TrackSource.screenShareVideo) {
              screenShareTrack = vt;
            } else {
              updatedVideoTracks[p.identity] = vt;
              hasVideo = true;
            }
          }
        }

        final existingIdx = newParticipants.indexWhere((cp) => cp.identity == p.identity);
        if (existingIdx >= 0) {
          newParticipants[existingIdx] = newParticipants[existingIdx].copyWith(
            isCameraOff: !hasVideo,
          );
        } else {
          newParticipants.add(ClassParticipant(
            identity: p.identity,
            name: p.name.isNotEmpty ? p.name : p.identity,
            role: isHostPeer ? 'TEACHER' : 'STUDENT',
            isHost: isHostPeer,
            isLocal: false,
            isMicMuted: true,
            isCameraOff: !hasVideo,
          ));
        }
      }

      state = state.copyWith(
        remoteVideoTracks: updatedVideoTracks,
        remoteScreenShareTrack: screenShareTrack ?? state.remoteScreenShareTrack,
        participants: ClassParticipant.deduplicateAndSort(newParticipants),
      );
    } catch (e) {
      debugPrint('[LIVEKIT] Error syncing existing participants: $e');
    }
  }

  Future<void> toggleMic() async {
    final newMicState = !state.isMicMuted;
    lk.LocalAudioTrack? audioTrack = state.localAudioTrack;

    try {
      if (newMicState) {
        // Mute
        await audioTrack?.stop();
        if (_liveKitRoom?.connectionState == lk.ConnectionState.connected) {
          await _liveKitRoom?.localParticipant?.setMicrophoneEnabled(false);
        }
      } else {
        // Unmute
        if (_liveKitRoom?.connectionState == lk.ConnectionState.connected) {
          await _liveKitRoom?.localParticipant?.setMicrophoneEnabled(true);
        } else {
          if (audioTrack == null) {
            audioTrack = await lk.LocalAudioTrack.create();
          } else {
            await audioTrack.start();
          }
        }
      }
    } catch (e) {
      debugPrint('[AUDIO] Toggle error: $e');
    }

    state = state.copyWith(
      isMicMuted: newMicState,
      localAudioTrack: audioTrack,
    );

    // Update local participant in participants list
    final updated = state.participants.map((p) {
      if (p.isLocal) return p.copyWith(isMicMuted: newMicState);
      return p;
    }).toList();

    state = state.copyWith(
      participants: ClassParticipant.deduplicateAndSort(updated),
    );

    if (_currentClassId != null) {
      _socket?.emit('media:state', {
        'classId': _currentClassId,
        'isMicMuted': newMicState,
        'isCameraOff': state.isCameraOff,
      });
    }
  }

  Future<void> toggleCamera() async {
    final newCamState = !state.isCameraOff;
    lk.LocalVideoTrack? videoTrack = state.localVideoTrack;

    try {
      if (newCamState) {
        // Turn off camera
        await videoTrack?.stop();
        if (_liveKitRoom?.connectionState == lk.ConnectionState.connected) {
          await _liveKitRoom?.localParticipant?.setCameraEnabled(false);
        }
        videoTrack = null;
      } else {
        // Turn on camera
        if (_liveKitRoom?.connectionState == lk.ConnectionState.connected) {
          await _liveKitRoom?.localParticipant?.setCameraEnabled(true);
          final localPub = _liveKitRoom?.localParticipant?.videoTrackPublications.firstOrNull;
          if (localPub?.track is lk.LocalVideoTrack) {
            videoTrack = localPub!.track as lk.LocalVideoTrack;
          }
        }
        videoTrack ??= await lk.LocalVideoTrack.createCameraTrack();
      }
    } catch (e) {
      debugPrint('[CAMERA] Toggle error: $e');
    }

    state = state.copyWith(
      isCameraOff: newCamState,
      localVideoTrack: videoTrack,
      clearLocalVideo: newCamState,
    );

    // Update local participant in participants list
    final updated = state.participants.map((p) {
      if (p.isLocal) return p.copyWith(isCameraOff: newCamState);
      return p;
    }).toList();

    state = state.copyWith(
      participants: ClassParticipant.deduplicateAndSort(updated),
    );

    if (_currentClassId != null) {
      _socket?.emit('media:state', {
        'classId': _currentClassId,
        'isMicMuted': state.isMicMuted,
        'isCameraOff': newCamState,
      });
    }
  }

  Future<void> toggleScreenShare() async {
    final next = !state.isScreenSharing;
    try {
      if (_liveKitRoom?.connectionState == lk.ConnectionState.connected) {
        await _liveKitRoom?.localParticipant?.setScreenShareEnabled(next);
      }
    } catch (e) {
      debugPrint('[SCREEN_SHARE] Toggle error: $e');
    }
    state = state.copyWith(isScreenSharing: next);
  }

  void toggleWhiteboard() {
    final next = !state.isWhiteboardOpen;
    state = state.copyWith(isWhiteboardOpen: next);
    if (_currentClassId != null && state.isHost) {
      _socket?.emit('board:toggle', {'classId': _currentClassId, 'isOpen': next});
    }
  }

  void sendDrawStroke(Map<String, dynamic> stroke) {
    if (_currentClassId != null) {
      _socket?.emit('whiteboard:draw', {
        'classId': _currentClassId,
        'stroke': stroke,
      });
    }
  }

  void sendClearBoard() {
    if (_currentClassId != null) {
      _socket?.emit('whiteboard:clear', {
        'classId': _currentClassId,
      });
    }
  }

  void setDocPresentation({required bool isOpen, String title = '', int page = 1}) {
    state = state.copyWith(isDocPresenting: isOpen, docTitle: title, docPage: page);
    if (_currentClassId != null && state.isHost) {
      _socket?.emit('doc:present', {
        'classId': _currentClassId,
        'isOpen': isOpen,
        'title': title,
        'page': page,
      });
    }
  }

  void toggleHandRaise(String userName) {
    if (_currentClassId == null) return;
    final next = !state.isHandRaised;
    state = state.copyWith(isHandRaised: next);

    if (next) {
      _socket?.emit('hand:raise', {'classId': _currentClassId});
    } else {
      _socket?.emit('hand:lower', {'classId': _currentClassId});
    }
  }

  void sendChatMessage(String text, String senderName, String senderRole) {
    if (text.trim().isEmpty || _currentClassId == null) return;

    final trimmed = text.trim();
    // Emit through socket for real delivery to all participants
    _socket?.emit('chat:send', {
      'classId': _currentClassId,
      'text': trimmed,
    });
  }

  void markChatRead() {
    state = state.copyWith(unreadChatCount: 0);
  }

  Future<void> muteAll() async {
    if (state.liveClass != null && state.isHost) {
      await _repository.muteAll(state.liveClass!.id);
      // Also emit via socket
      _socket?.emit('host:muteAll', {'classId': state.liveClass!.id});
    }
  }

  Future<void> removeParticipant(String participantId) async {
    if (state.liveClass != null && state.isHost) {
      await _repository.removeParticipant(state.liveClass!.id, participantId);
      final updated = state.participants.where((p) => p.identity != participantId).toList();
      state = state.copyWith(
        participants: ClassParticipant.deduplicateAndSort(updated),
      );
    }
  }

  void grantBoardToStudent(String studentId) {
    if (state.isHost && _currentClassId != null) {
      _socket?.emit('board:permission:grant', {'classId': _currentClassId, 'studentId': studentId});
      _socket?.emit('board:grant', {'classId': _currentClassId, 'studentId': studentId});
    }
  }

  void revokeBoardFromStudent(String studentId) {
    if (state.isHost && _currentClassId != null) {
      _socket?.emit('board:permission:revoke', {'classId': _currentClassId, 'studentId': studentId});
      _socket?.emit('board:revoke', {'classId': _currentClassId, 'studentId': studentId});
    }
  }

  void toggleLockRoom() {
    final next = !state.isRoomLocked;
    state = state.copyWith(isRoomLocked: next);
    if (_currentClassId != null && state.isHost) {
      _socket?.emit('room:lock', {'classId': _currentClassId, 'isLocked': next});
    }
  }

  Future<void> endClass() async {
    if (state.liveClass != null && state.isHost) {
      await _repository.endClass(state.liveClass!.id);
    }
    leaveRoom();
  }

  void leaveRoom() {
    try {
      state.localVideoTrack?.stop();
      state.localAudioTrack?.stop();
    } catch (_) {}

    if (_currentClassId != null) {
      _socket?.emit('class:leave', {'classId': _currentClassId});
    }
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;

    _liveKitRoom?.disconnect();
    _liveKitRoom?.dispose();
    _liveKitRoom = null;

    if (!_drawStreamController.isClosed) _drawStreamController.close();
    if (!_clearStreamController.isClosed) _clearStreamController.close();
  }

  @override
  void dispose() {
    leaveRoom();
    super.dispose();
  }
}

final liveClassRoomProvider =
    StateNotifierProvider.autoDispose<LiveClassRoomNotifier, LiveClassRoomState>((ref) {
  final repo = ref.watch(liveClassRepositoryProvider);
  return LiveClassRoomNotifier(repository: repo);
});
