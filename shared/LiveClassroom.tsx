import React, { useState, useEffect, useRef } from 'react';
import {
  Mic,
  MicOff,
  Video,
  VideoOff,
  Hand,
  MessageSquare,
  BarChart2,
  Users,
  PhoneOff,
  HelpCircle,
  CheckCircle2,
  Send,
  X,
  Maximize2,
  ChevronDown,
  Sparkles,
  Radio,
  Monitor,
  MonitorOff,
  CircleDot,
  Square as StopIcon,
  Play,
  Pause,
  Download,
  Film,
  Layers,
} from 'lucide-react';
import { io, Socket } from 'socket.io-client';
import { DigitalBoard } from './DigitalBoard';
import { ChatMessage, ActivePoll, DoubtItem } from './types';

export interface LiveClassroomProps {
  role: 'teacher' | 'student';
  userName: string;
  onExit: () => void;
  classInfo?: {
    id: string;
    title: string;
    subject: string;
    chapter?: string;
    batchName?: string;
    teacherName?: string;
    roomId: string;
  };
  hardwareConfig?: {
    cameraId?: string;
    micId?: string;
    bluetoothDevice?: string;
  };
}

export const LiveClassroom: React.FC<LiveClassroomProps> = ({
  role,
  userName,
  onExit,
  classInfo,
  hardwareConfig,
}) => {
  const isTeacher = role === 'teacher';
  const roomId = classInfo?.roomId || 'room-live-demo';

  const [micOn, setMicOn] = useState(true);
  const [camOn, setCamOn] = useState(true);
  const [activePanel, setActivePanel] = useState<'chat' | 'doubts' | 'polls' | 'roster' | null>('chat');

  // Socket & WebRTC refs
  const socketRef = useRef<Socket | null>(null);
  const localStreamRef = useRef<MediaStream | null>(null);
  const localVideoRef = useRef<HTMLVideoElement | null>(null);
  const remoteVideoRef = useRef<HTMLVideoElement | null>(null);
  const peerConnectionsRef = useRef<Record<string, RTCPeerConnection>>({});
  const studentPeerConnectionRef = useRef<RTCPeerConnection | null>(null);

  const [socketConnected, setSocketConnected] = useState(false);
  const [hasRemoteVideo, setHasRemoteVideo] = useState(false);
  const [isCameraActive, setIsCameraActive] = useState(false);

  // Screen Sharing State
  const [isScreenSharing, setIsScreenSharing] = useState<boolean>(false);
  const [teacherSharingScreen, setTeacherSharingScreen] = useState<boolean>(false);
  const [classroomView, setClassroomView] = useState<'board' | 'screen'>('board');
  const screenStreamRef = useRef<MediaStream | null>(null);
  const screenVideoRef = useRef<HTMLVideoElement | null>(null);

  // Full HD Class Recording State
  const [isRecording, setIsRecording] = useState<boolean>(false);
  const [isRecordingPaused, setIsRecordingPaused] = useState<boolean>(false);
  const [recordingDuration, setRecordingDuration] = useState<number>(0);
  const [recordingModalOpen, setRecordingModalOpen] = useState<boolean>(false);
  const [recordingBlobUrl, setRecordingBlobUrl] = useState<string | null>(null);
  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const recordedChunksRef = useRef<Blob[]>([]);
  const timerIntervalRef = useRef<any>(null);

  // Chat
  const [chatMessages, setChatMessages] = useState<ChatMessage[]>([]);
  const [currentChatInput, setCurrentChatInput] = useState('');

  // Doubts
  const [doubts, setDoubts] = useState<DoubtItem[]>([]);
  const [newDoubtText, setNewDoubtText] = useState('');
  const [handRaised, setHandRaised] = useState(false);

  // Poll
  const [activePoll, setActivePoll] = useState<ActivePoll | null>(null);
  const [userVoted, setUserVoted] = useState<number | null>(null);
  const [newPollQuestion, setNewPollQuestion] = useState('');
  const [newPollOpt1, setNewPollOpt1] = useState('');
  const [newPollOpt2, setNewPollOpt2] = useState('');

  // Participants roster
  const [participants, setParticipants] = useState<Array<{ name: string; role: string; status: string }>>([
    { name: isTeacher ? `${userName} (Teacher)` : (classInfo?.teacherName || 'Prof. Rajesh Sharma'), role: 'teacher', status: 'Speaking' },
    { name: isTeacher ? 'Aarav Patel' : `${userName} (You)`, role: 'student', status: 'Attending' },
  ]);

  // Connect Socket.IO and WebRTC Media
  useEffect(() => {
    const socket = io('http://localhost:4000');
    socketRef.current = socket;

    socket.on('connect', () => {
      setSocketConnected(true);
      socket.emit('join-room', {
        roomId,
        role,
        userName,
      });
    });

    socket.on('disconnect', () => {
      setSocketConnected(false);
    });

    // Chat listener
    socket.on('receive-chat', (msg: ChatMessage) => {
      setChatMessages((prev) => [...prev, msg]);
    });

    // Doubts listener
    socket.on('doubt-list', (list: DoubtItem[]) => {
      setDoubts(list);
    });

    // Poll listener
    socket.on('active-poll', (poll: ActivePoll) => {
      setActivePoll(poll);
    });

    // User joined room
    socket.on('user-joined', ({ userName: joinedName, role: joinedRole }) => {
      setParticipants((prev) => {
        if (prev.some((p) => p.name.includes(joinedName))) return prev;
        return [...prev, { name: joinedName, role: joinedRole, status: 'Attending' }];
      });
    });

    // Screen share signaling
    socket.on('screen-share-started', () => {
      setTeacherSharingScreen(true);
      setClassroomView('screen');
    });

    socket.on('screen-share-stopped', () => {
      setTeacherSharingScreen(false);
      setClassroomView('board');
    });

    // -------------------------------------------------------------
    // WEBRTC SIGNALING: TEACHER (BROADCASTER)
    // -------------------------------------------------------------
    if (isTeacher) {
      // Start teacher's webcam & mic
      const startLocalMedia = async () => {
        let stream: MediaStream | null = null;
        try {
          const isRealId = (id?: string) => id && !id.startsWith('cam-') && !id.startsWith('mic-');
          const constraints: MediaStreamConstraints = {
            video: isRealId(hardwareConfig?.cameraId) ? { deviceId: { exact: hardwareConfig!.cameraId! } } : true,
            audio: isRealId(hardwareConfig?.micId) ? { deviceId: { exact: hardwareConfig!.micId! } } : true,
          };
          stream = await navigator.mediaDevices.getUserMedia(constraints);
        } catch (err) {
          try {
            stream = await navigator.mediaDevices.getUserMedia({ video: true, audio: true });
          } catch (err2) {
            console.warn('Real webcam not available, using simulated stream mode');
          }
        }

        if (stream) {
          localStreamRef.current = stream;
          if (localVideoRef.current) {
            localVideoRef.current.srcObject = stream;
          }
          setIsCameraActive(true);
        } else {
          setIsCameraActive(false);
        }
      };
      startLocalMedia();

      // When a student joins, create offer for them
      socket.on('webrtc-new-viewer', async ({ viewerSocketId, userName: viewerName }) => {
        try {
          const pc = new RTCPeerConnection({
            iceServers: [{ urls: 'stun:stun.l.google.com:19302' }],
          });
          peerConnectionsRef.current[viewerSocketId] = pc;

          if (localStreamRef.current) {
            localStreamRef.current.getTracks().forEach((track) => {
              pc.addTrack(track, localStreamRef.current!);
            });
          }

          pc.onicecandidate = (event) => {
            if (event.candidate) {
              socket.emit('webrtc-ice-candidate', {
                targetSocketId: viewerSocketId,
                candidate: event.candidate,
              });
            }
          };

          const offer = await pc.createOffer();
          await pc.setLocalDescription(offer);

          socket.emit('webrtc-offer', {
            targetSocketId: viewerSocketId,
            offer,
          });
        } catch (e) {
          console.error('Error creating WebRTC offer for viewer:', e);
        }
      });

      // Receive student answer
      socket.on('webrtc-answer-received', async ({ answer, viewerSocketId }) => {
        const pc = peerConnectionsRef.current[viewerSocketId];
        if (pc) {
          await pc.setRemoteDescription(new RTCSessionDescription(answer));
        }
      });

      // Receive ICE candidate from student
      socket.on('webrtc-ice-candidate-received', async ({ candidate, senderSocketId }) => {
        const pc = peerConnectionsRef.current[senderSocketId];
        if (pc) {
          await pc.addIceCandidate(new RTCIceCandidate(candidate));
        }
      });
    }

    // -------------------------------------------------------------
    // WEBRTC SIGNALING: STUDENT (VIEWER)
    // -------------------------------------------------------------
    if (!isTeacher) {
      socket.on('webrtc-offer-received', async ({ offer, broadcasterSocketId }) => {
        try {
          const pc = new RTCPeerConnection({
            iceServers: [{ urls: 'stun:stun.l.google.com:19302' }],
          });
          studentPeerConnectionRef.current = pc;

          pc.ontrack = (event) => {
            if (remoteVideoRef.current && event.streams[0]) {
              remoteVideoRef.current.srcObject = event.streams[0];
              setHasRemoteVideo(true);
            }
          };

          pc.onicecandidate = (event) => {
            if (event.candidate) {
              socket.emit('webrtc-ice-candidate', {
                targetSocketId: broadcasterSocketId,
                candidate: event.candidate,
              });
            }
          };

          await pc.setRemoteDescription(new RTCSessionDescription(offer));
          const answer = await pc.createAnswer();
          await pc.setLocalDescription(answer);

          socket.emit('webrtc-answer', {
            broadcasterSocketId,
            answer,
          });
        } catch (e) {
          console.error('Error handling WebRTC offer on student:', e);
        }
      });

      socket.on('webrtc-ice-candidate-received', async ({ candidate }) => {
        if (studentPeerConnectionRef.current) {
          await studentPeerConnectionRef.current.addIceCandidate(new RTCIceCandidate(candidate));
        }
      });
    }

    // Default sample messages if none exists
    setChatMessages([
      {
        id: 'msg-init-1',
        sender: classInfo?.teacherName || 'Prof. Rajesh Sharma',
        message: 'Welcome everyone! Today we will learn electromagnetic induction and solve core problems.',
        role: 'teacher',
        timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      },
    ]);

    return () => {
      // Clean up media tracks & peer connections
      if (localStreamRef.current) {
        localStreamRef.current.getTracks().forEach((t) => t.stop());
      }
      if (screenStreamRef.current) {
        screenStreamRef.current.getTracks().forEach((t) => t.stop());
      }
      if (timerIntervalRef.current) {
        clearInterval(timerIntervalRef.current);
      }
      Object.values(peerConnectionsRef.current).forEach((pc) => pc.close());
      if (studentPeerConnectionRef.current) {
        studentPeerConnectionRef.current.close();
      }
      socket.off('screen-share-started');
      socket.off('screen-share-stopped');
      socket.disconnect();
    };
  }, [roomId, role, userName, isTeacher, hardwareConfig]);

  // Toggle Mic
  const toggleMic = () => {
    if (localStreamRef.current) {
      localStreamRef.current.getAudioTracks().forEach((track) => {
        track.enabled = !micOn;
      });
    }
    setMicOn(!micOn);
  };

  // Toggle Camera
  const toggleCam = () => {
    if (localStreamRef.current) {
      localStreamRef.current.getVideoTracks().forEach((track) => {
        track.enabled = !camOn;
      });
    }
    setCamOn(!camOn);
  };

  // Chat Submission
  const handleSendChat = (e: React.FormEvent) => {
    e.preventDefault();
    if (!currentChatInput.trim() || !socketRef.current) return;
    socketRef.current.emit('send-chat', {
      roomId,
      sender: userName,
      message: currentChatInput.trim(),
      role,
    });
    setCurrentChatInput('');
  };

  // Doubt Submission
  const handleSubmitDoubt = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newDoubtText.trim() || !socketRef.current) return;
    socketRef.current.emit('raise-doubt', {
      roomId,
      studentName: userName,
      doubtText: newDoubtText.trim(),
    });
    setNewDoubtText('');
  };

  // Resolve Doubt (Teacher)
  const handleResolveDoubt = (doubtId: string) => {
    if (!socketRef.current) return;
    socketRef.current.emit('resolve-doubt', { roomId, doubtId });
  };

  // Create Poll (Teacher)
  const handleCreatePoll = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newPollQuestion.trim() || !newPollOpt1.trim() || !newPollOpt2.trim() || !socketRef.current) return;
    socketRef.current.emit('launch-poll', {
      roomId,
      question: newPollQuestion.trim(),
      options: [newPollOpt1.trim(), newPollOpt2.trim()],
    });
    setUserVoted(null);
    setNewPollQuestion('');
    setNewPollOpt1('');
    setNewPollOpt2('');
  };

  // Vote Poll (Student)
  const handleVote = (idx: number) => {
    if (userVoted !== null || !activePoll || !socketRef.current) return;
    setUserVoted(idx);
    socketRef.current.emit('vote-poll', {
      roomId,
      optionIndex: idx,
    });
  };

  // Screen Share Controllers
  const startScreenShare = async () => {
    try {
      const stream = await navigator.mediaDevices.getDisplayMedia({
        video: {
          displaySurface: 'monitor',
          frameRate: { ideal: 30, max: 60 },
        },
        audio: true,
      });

      screenStreamRef.current = stream;
      setIsScreenSharing(true);
      setClassroomView('screen');

      if (screenVideoRef.current) {
        screenVideoRef.current.srcObject = stream;
      }

      if (socketRef.current) {
        socketRef.current.emit('screen-share-started', { roomId });
      }

      const videoTrack = stream.getVideoTracks()[0];
      if (videoTrack) {
        videoTrack.onended = () => {
          stopScreenShare();
        };
      }
    } catch (err) {
      console.warn('Screen share cancelled or not allowed:', err);
    }
  };

  const stopScreenShare = () => {
    if (screenStreamRef.current) {
      screenStreamRef.current.getTracks().forEach((t) => t.stop());
      screenStreamRef.current = null;
    }
    setIsScreenSharing(false);
    setClassroomView('board');
    if (socketRef.current) {
      socketRef.current.emit('screen-share-stopped', { roomId });
    }
  };

  // Sync screen video element when stream or view changes
  useEffect(() => {
    if (screenVideoRef.current && screenStreamRef.current) {
      screenVideoRef.current.srcObject = screenStreamRef.current;
    }
  }, [classroomView, isScreenSharing]);

  // Full HD Lecture Recording Controllers
  const formatTime = (secs: number) => {
    const h = Math.floor(secs / 3600);
    const m = Math.floor((secs % 3600) / 60);
    const s = secs % 60;
    const pad = (n: number) => n.toString().padStart(2, '0');
    if (h > 0) return `${pad(h)}:${pad(m)}:${pad(s)}`;
    return `${pad(m)}:${pad(s)}`;
  };

  const startRecording = () => {
    try {
      recordedChunksRef.current = [];
      let captureStream: MediaStream | null = null;

      if (isScreenSharing && screenStreamRef.current) {
        captureStream = screenStreamRef.current.clone();
      } else {
        const canvas = document.querySelector('canvas') as HTMLCanvasElement;
        if (canvas && typeof (canvas as any).captureStream === 'function') {
          captureStream = (canvas as any).captureStream(30);
        }
      }

      if (!captureStream) {
        alert('Canvas or screen stream not available for recording.');
        return;
      }

      // Mix local microphone audio
      if (localStreamRef.current && localStreamRef.current.getAudioTracks().length > 0) {
        const audioTrack = localStreamRef.current.getAudioTracks()[0];
        captureStream.addTrack(audioTrack);
      }

      let recorder: MediaRecorder;
      try {
        recorder = new MediaRecorder(captureStream, { mimeType: 'video/webm;codecs=vp9,opus' });
      } catch (e) {
        try {
          recorder = new MediaRecorder(captureStream, { mimeType: 'video/webm' });
        } catch (e2) {
          recorder = new MediaRecorder(captureStream);
        }
      }

      recorder.ondataavailable = (event) => {
        if (event.data && event.data.size > 0) {
          recordedChunksRef.current.push(event.data);
        }
      };

      recorder.onstop = () => {
        const blob = new Blob(recordedChunksRef.current, { type: 'video/webm' });
        const url = URL.createObjectURL(blob);
        setRecordingBlobUrl(url);
        setRecordingModalOpen(true);
      };

      recorder.start(1000);
      mediaRecorderRef.current = recorder;
      setIsRecording(true);
      setIsRecordingPaused(false);
      setRecordingDuration(0);

      timerIntervalRef.current = setInterval(() => {
        setRecordingDuration((prev) => prev + 1);
      }, 1000);
    } catch (err) {
      console.error('Failed to start recording:', err);
      alert('Could not start recording: ' + err);
    }
  };

  const pauseResumeRecording = () => {
    if (!mediaRecorderRef.current) return;
    if (isRecordingPaused) {
      mediaRecorderRef.current.resume();
      setIsRecordingPaused(false);
      timerIntervalRef.current = setInterval(() => {
        setRecordingDuration((prev) => prev + 1);
      }, 1000);
    } else {
      mediaRecorderRef.current.pause();
      setIsRecordingPaused(true);
      if (timerIntervalRef.current) clearInterval(timerIntervalRef.current);
    }
  };

  const stopRecording = () => {
    if (timerIntervalRef.current) {
      clearInterval(timerIntervalRef.current);
      timerIntervalRef.current = null;
    }
    if (mediaRecorderRef.current && mediaRecorderRef.current.state !== 'inactive') {
      mediaRecorderRef.current.stop();
    }
    setIsRecording(false);
    setIsRecordingPaused(false);
  };

  return (
    <div className="relative w-full h-[calc(100vh-64px)] flex bg-slate-50 overflow-hidden font-sans">
      {/* Main Canvas Area */}
      <div className="relative flex-1 flex flex-col h-full overflow-hidden">
        {/* Top Class Info Bar */}
        <div className="h-10 bg-white border-b border-slate-200 px-4 flex items-center justify-between z-10 shadow-xs">
          <div className="flex items-center space-x-2 sm:space-x-3 truncate">
            <span className="inline-flex items-center px-2 py-0.5 rounded text-[11px] font-bold bg-rose-50 text-rose-700 border border-rose-200 shrink-0">
              <span className="w-1.5 h-1.5 rounded-full bg-rose-500 animate-pulse mr-1.5" />
              LIVE
            </span>
            <h3 className="text-xs font-bold text-slate-800 truncate">
              {classInfo?.title || 'Live Interactive Classroom'}
            </h3>
            {classInfo?.batchName && (
              <span className="hidden md:inline-flex items-center text-[10px] font-bold text-indigo-700 bg-indigo-50 px-2 py-0.5 rounded border border-indigo-200">
                {classInfo.batchName}
              </span>
            )}
            {hardwareConfig?.bluetoothDevice && (
              <span className="hidden lg:inline-flex items-center text-[10px] font-semibold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded-full border border-emerald-200">
                BT: {hardwareConfig.bluetoothDevice}
              </span>
            )}
          </div>
          <div className="flex items-center space-x-2 text-xs font-semibold text-slate-600 shrink-0">
            {/* Live Recording Badge */}
            {isRecording && (
              <div className="flex items-center space-x-1.5 px-2.5 py-1 bg-rose-50 border border-rose-300 text-rose-700 rounded-full text-xs font-bold animate-pulse shadow-2xs">
                <span className="w-2 h-2 rounded-full bg-rose-600 animate-ping" />
                <span>REC {formatTime(recordingDuration)}</span>
                {isTeacher && (
                  <button
                    onClick={pauseResumeRecording}
                    className="ml-1 p-0.5 hover:bg-rose-100 rounded text-rose-800 transition-colors"
                    title={isRecordingPaused ? 'Resume Recording' : 'Pause Recording'}
                  >
                    {isRecordingPaused ? <Play className="w-3 h-3" /> : <Pause className="w-3 h-3" />}
                  </button>
                )}
              </div>
            )}

            {/* Stage View Switcher (Whiteboard vs Screen Share) */}
            <div className="flex items-center bg-slate-100 p-0.5 rounded-lg border border-slate-200 text-xs font-medium">
              <button
                onClick={() => setClassroomView('board')}
                className={`px-2 py-0.5 rounded transition-colors ${
                  classroomView === 'board'
                    ? 'bg-white text-indigo-600 shadow-2xs font-bold'
                    : 'text-slate-600 hover:text-slate-900'
                }`}
              >
                Whiteboard
              </button>
              <button
                onClick={() => setClassroomView('screen')}
                className={`px-2 py-0.5 rounded transition-colors flex items-center space-x-1 ${
                  classroomView === 'screen'
                    ? 'bg-white text-indigo-600 shadow-2xs font-bold'
                    : 'text-slate-600 hover:text-slate-900'
                } ${isScreenSharing || teacherSharingScreen ? 'text-emerald-700 font-bold' : ''}`}
              >
                <span>Screen Share</span>
                {(isScreenSharing || teacherSharingScreen) && (
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
                )}
              </button>
            </div>

            <span className="inline-flex items-center space-x-1.5 px-2 py-0.5 rounded-full bg-slate-100 border border-slate-200 text-[11px]">
              <span className={`w-2 h-2 rounded-full ${socketConnected ? 'bg-emerald-500' : 'bg-amber-500'}`} />
              <span className="text-slate-600">{socketConnected ? 'Connected' : 'Syncing...'}</span>
            </span>
            <div className="flex items-center space-x-1 text-slate-700 font-bold ml-2">
              <Users className="w-3.5 h-3.5 text-indigo-600" />
              <span>{participants.length} Active</span>
            </div>
          </div>
        </div>

        {/* Main Stage: Digital Board or Full HD Screen Share */}
        <div className="relative flex-1 w-full h-full overflow-hidden bg-slate-950">
          {classroomView === 'screen' ? (
            <div className="relative w-full h-full flex flex-col items-center justify-center bg-slate-950 p-2">
              {isTeacher ? (
                isScreenSharing ? (
                  <video
                    ref={screenVideoRef}
                    autoPlay
                    playsInline
                    className="w-full h-full object-contain rounded-xl shadow-2xl border border-slate-800"
                  />
                ) : (
                  <div className="flex flex-col items-center justify-center text-center p-6 text-white">
                    <Monitor className="w-14 h-14 text-indigo-400 mb-3" />
                    <h3 className="text-base font-bold mb-1">Screen Share Inactive</h3>
                    <p className="text-xs text-slate-400 mb-4 max-w-sm">
                      Share your entire screen, application window, or browser tab with students across all devices in Full HD.
                    </p>
                    <button
                      onClick={startScreenShare}
                      className="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs rounded-xl shadow-md flex items-center space-x-2 transition-colors"
                    >
                      <Monitor className="w-4 h-4" />
                      <span>Start Sharing Screen</span>
                    </button>
                  </div>
                )
              ) : (
                // Student Screen Share View
                teacherSharingScreen ? (
                  <video
                    ref={remoteVideoRef}
                    autoPlay
                    playsInline
                    className="w-full h-full object-contain rounded-xl shadow-2xl border border-slate-800"
                  />
                ) : (
                  <div className="flex flex-col items-center justify-center text-center p-6 text-white">
                    <Monitor className="w-12 h-12 text-slate-500 mb-2" />
                    <h3 className="text-sm font-bold mb-1">Teacher is not sharing screen right now</h3>
                    <p className="text-xs text-slate-400 mb-3">
                      Switch back to Whiteboard view to follow live teacher notes.
                    </p>
                    <button
                      onClick={() => setClassroomView('board')}
                      className="px-3 py-1.5 bg-slate-800 hover:bg-slate-700 text-white text-xs font-semibold rounded-lg"
                    >
                      Switch to Whiteboard
                    </button>
                  </div>
                )
              )}

              {/* Fullscreen button overlay */}
              <button
                onClick={() => {
                  if (document.fullscreenElement) {
                    document.exitFullscreen();
                  } else {
                    document.documentElement.requestFullscreen();
                  }
                }}
                className="absolute top-4 right-4 p-2 bg-slate-900/80 hover:bg-slate-900 text-white rounded-lg backdrop-blur-xs border border-slate-700 shadow-md transition-colors"
                title="Toggle Fullscreen"
              >
                <Maximize2 className="w-4 h-4" />
              </button>
            </div>
          ) : (
            <DigitalBoard isTeacher={isTeacher} roomId={roomId} socket={socketRef.current} />
          )}

          {/* Floating Teacher PiP Video Camera */}
          <div className="absolute top-14 right-4 w-44 sm:w-60 bg-white rounded-2xl shadow-elevated border border-slate-200 overflow-hidden z-30 transition-all hover:scale-102">
            <div className="relative aspect-video bg-slate-900 flex items-center justify-center overflow-hidden">
              {isTeacher ? (
                // Teacher's Local Camera Feed
                camOn ? (
                  isCameraActive ? (
                    <video
                      ref={localVideoRef}
                      autoPlay
                      playsInline
                      muted
                      className="w-full h-full object-cover"
                    />
                  ) : (
                    <div className="relative w-full h-full flex flex-col items-center justify-center bg-slate-900">
                      <img
                        src="https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300&h=200&fit=crop"
                        alt="Teacher"
                        className="w-full h-full object-cover opacity-90"
                      />
                      <div className="absolute inset-0 bg-indigo-950/30 flex items-center justify-center">
                        <span className="text-[10px] font-bold text-white bg-slate-900/80 px-2 py-0.5 rounded-full border border-indigo-400">
                          Live Camera Active
                        </span>
                      </div>
                    </div>
                  )
                ) : (
                  <div className="flex flex-col items-center justify-center text-slate-400">
                    <VideoOff className="w-6 h-6 mb-1 text-slate-500" />
                    <span className="text-[10px] font-semibold">Camera Paused</span>
                  </div>
                )
              ) : (
                // Student's View of Teacher's Feed
                hasRemoteVideo ? (
                  <video
                    ref={remoteVideoRef}
                    autoPlay
                    playsInline
                    className="w-full h-full object-cover"
                  />
                ) : (
                  <div className="relative w-full h-full flex flex-col items-center justify-center bg-gradient-to-br from-indigo-900 to-slate-900 text-white p-2 text-center">
                    <img
                      src="https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&h=150&fit=crop"
                      alt="Teacher"
                      className="w-10 h-10 rounded-full border-2 border-indigo-400 shadow-md mb-1 object-cover"
                    />
                    <p className="text-[11px] font-bold truncate">
                      {classInfo?.teacherName || 'Prof. Rajesh Sharma'}
                    </p>
                    <span className="inline-flex items-center text-[9px] text-emerald-300 font-semibold mt-0.5">
                      <Radio className="w-2.5 h-2.5 mr-1 animate-pulse" /> Live Broadcast
                    </span>
                  </div>
                )
              )}

              {/* Tag overlay */}
              <div className="absolute bottom-1.5 left-2 bg-slate-900/85 backdrop-blur-xs text-white text-[10px] font-bold px-2 py-0.5 rounded-full flex items-center space-x-1">
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse"></span>
                <span>{isTeacher ? 'You (Broadcasting)' : (classInfo?.teacherName || 'Prof. Sharma')}</span>
              </div>
              <div className="absolute bottom-1.5 right-2">
                {micOn ? (
                  <span className="p-1 bg-slate-900/80 rounded-full text-emerald-400 text-[10px] flex items-center">
                    <Mic className="w-2.5 h-2.5" />
                  </span>
                ) : (
                  <span className="p-1 bg-rose-600 text-white rounded-full text-[10px] flex items-center">
                    <MicOff className="w-2.5 h-2.5" />
                  </span>
                )}
              </div>
            </div>
          </div>

          {/* Bottom Floating Classroom Dock */}
          <div className="absolute bottom-3 left-1/2 -translate-x-1/2 bg-white/95 backdrop-blur-md border border-slate-200 shadow-elevated rounded-2xl px-2.5 py-1.5 flex items-center space-x-1.5 sm:space-x-2 z-30">
            {/* Mic */}
            <button
              onClick={toggleMic}
              className={`p-2 sm:p-2.5 rounded-xl border transition-colors ${
                micOn ? 'bg-slate-100 hover:bg-slate-200 text-slate-700 border-slate-200' : 'bg-rose-50 text-rose-600 border-rose-200'
              }`}
              title={micOn ? 'Mute Mic' : 'Unmute Mic'}
            >
              {micOn ? <Mic className="w-4 h-4" /> : <MicOff className="w-4 h-4" />}
            </button>

            {/* Video */}
            <button
              onClick={toggleCam}
              className={`p-2 sm:p-2.5 rounded-xl border transition-colors ${
                camOn ? 'bg-slate-100 hover:bg-slate-200 text-slate-700 border-slate-200' : 'bg-rose-50 text-rose-600 border-rose-200'
              }`}
              title={camOn ? 'Turn Camera Off' : 'Turn Camera On'}
            >
              {camOn ? <Video className="w-4 h-4" /> : <VideoOff className="w-4 h-4" />}
            </button>

            {/* Screen Share (Teacher) */}
            {isTeacher && (
              <button
                onClick={isScreenSharing ? stopScreenShare : startScreenShare}
                className={`p-2 sm:p-2.5 rounded-xl border transition-colors flex items-center space-x-1.5 ${
                  isScreenSharing
                    ? 'bg-emerald-600 hover:bg-emerald-700 text-white border-emerald-600 shadow-xs'
                    : 'bg-slate-100 hover:bg-slate-200 text-slate-700 border-slate-200'
                }`}
                title={isScreenSharing ? 'Stop Screen Share' : 'Share Full Screen / Window with Students'}
              >
                {isScreenSharing ? <MonitorOff className="w-4 h-4" /> : <Monitor className="w-4 h-4" />}
                <span className="text-xs font-semibold hidden lg:inline">
                  {isScreenSharing ? 'Stop Share' : 'Share Screen'}
                </span>
              </button>
            )}

            {/* Record Class Full HD (Teacher) */}
            {isTeacher && (
              <button
                onClick={isRecording ? stopRecording : startRecording}
                className={`p-2 sm:p-2.5 rounded-xl border transition-colors flex items-center space-x-1.5 ${
                  isRecording
                    ? 'bg-rose-600 hover:bg-rose-700 text-white border-rose-600 shadow-xs animate-pulse'
                    : 'bg-slate-100 hover:bg-slate-200 text-rose-600 border-slate-200'
                }`}
                title={isRecording ? 'Stop Recording' : 'Start Full HD Class Recording (Audio + Video)'}
              >
                {isRecording ? <StopIcon className="w-4 h-4 fill-white" /> : <CircleDot className="w-4 h-4 text-rose-600" />}
                <span className="text-xs font-bold hidden lg:inline">
                  {isRecording ? `Stop REC (${formatTime(recordingDuration)})` : 'Record (REC)'}
                </span>
              </button>
            )}

            {/* Raise Hand (Student) */}
            {!isTeacher && (
              <button
                onClick={() => {
                  setHandRaised(!handRaised);
                  if (!handRaised && socketRef.current) {
                    socketRef.current.emit('raise-doubt', {
                      roomId,
                      studentName: userName,
                      doubtText: 'Raised Hand for Audio Question',
                    });
                  }
                }}
                className={`p-2 sm:p-2.5 rounded-xl border transition-colors ${
                  handRaised ? 'bg-amber-100 text-amber-800 border-amber-300 font-bold' : 'bg-slate-100 hover:bg-slate-200 text-slate-700 border-slate-200'
                }`}
                title="Raise Hand to Speak"
              >
                <Hand className="w-4 h-4" />
              </button>
            )}

            <div className="h-5 w-px bg-slate-200 mx-1" />

            {/* Panel Buttons */}
            <button
              onClick={() => setActivePanel(activePanel === 'chat' ? null : 'chat')}
              className={`p-2 sm:p-2.5 rounded-xl border transition-colors relative ${
                activePanel === 'chat' ? 'bg-indigo-600 text-white border-indigo-600' : 'bg-slate-100 hover:bg-slate-200 text-slate-700 border-slate-200'
              }`}
              title="Live Chat"
            >
              <MessageSquare className="w-4 h-4" />
              {chatMessages.length > 0 && (
                <span className="absolute -top-1 -right-1 w-4 h-4 bg-indigo-500 text-white text-[9px] font-bold rounded-full flex items-center justify-center">
                  {chatMessages.length}
                </span>
              )}
            </button>

            <button
              onClick={() => setActivePanel(activePanel === 'doubts' ? null : 'doubts')}
              className={`p-2 sm:p-2.5 rounded-xl border transition-colors relative ${
                activePanel === 'doubts' ? 'bg-indigo-600 text-white border-indigo-600' : 'bg-slate-100 hover:bg-slate-200 text-slate-700 border-slate-200'
              }`}
              title="Doubts & Questions"
            >
              <HelpCircle className="w-4 h-4" />
              {doubts.filter((d) => d.status === 'pending').length > 0 && (
                <span className="absolute -top-1 -right-1 w-4 h-4 bg-rose-500 text-white text-[9px] font-bold rounded-full flex items-center justify-center">
                  {doubts.filter((d) => d.status === 'pending').length}
                </span>
              )}
            </button>

            <button
              onClick={() => setActivePanel(activePanel === 'polls' ? null : 'polls')}
              className={`p-2 sm:p-2.5 rounded-xl border transition-colors relative ${
                activePanel === 'polls' ? 'bg-indigo-600 text-white border-indigo-600' : 'bg-slate-100 hover:bg-slate-200 text-slate-700 border-slate-200'
              }`}
              title="Live Polls"
            >
              <BarChart2 className="w-4 h-4" />
              {activePoll?.active && (
                <span className="absolute -top-1 -right-1 w-2.5 h-2.5 bg-emerald-500 rounded-full animate-ping" />
              )}
            </button>

            <button
              onClick={() => setActivePanel(activePanel === 'roster' ? null : 'roster')}
              className={`p-2 sm:p-2.5 rounded-xl border transition-colors ${
                activePanel === 'roster' ? 'bg-indigo-600 text-white border-indigo-600' : 'bg-slate-100 hover:bg-slate-200 text-slate-700 border-slate-200'
              }`}
              title="Participant Roster"
            >
              <Users className="w-4 h-4" />
            </button>

            <div className="h-5 w-px bg-slate-200 mx-1" />

            {/* End / Leave Class */}
            <button
              onClick={onExit}
              className="px-3 py-2 sm:py-2.5 bg-rose-600 hover:bg-rose-700 text-white font-bold text-xs rounded-xl flex items-center space-x-1.5 transition-colors shadow-xs"
            >
              <PhoneOff className="w-3.5 h-3.5" />
              <span className="hidden sm:inline">{isTeacher ? 'End Broadcast' : 'Leave Class'}</span>
            </button>
          </div>
        </div>
      </div>

      {/* Right Drawer Panel */}
      {activePanel && (
        <div className="w-80 md:w-88 bg-white border-l border-slate-200 flex flex-col h-full z-20 shadow-lg animate-in slide-in-from-right duration-200">
          {/* Header */}
          <div className="h-12 border-b border-slate-200 px-4 flex items-center justify-between bg-slate-50/50">
            <h3 className="font-bold text-xs uppercase tracking-wider text-slate-700 flex items-center space-x-2">
              {activePanel === 'chat' && (
                <>
                  <MessageSquare className="w-4 h-4 text-indigo-600" />
                  <span>Class Discussion</span>
                </>
              )}
              {activePanel === 'doubts' && (
                <>
                  <HelpCircle className="w-4 h-4 text-rose-600" />
                  <span>Doubts & Questions</span>
                </>
              )}
              {activePanel === 'polls' && (
                <>
                  <BarChart2 className="w-4 h-4 text-emerald-600" />
                  <span>Real-Time Polls</span>
                </>
              )}
              {activePanel === 'roster' && (
                <>
                  <Users className="w-4 h-4 text-indigo-600" />
                  <span>Classroom Roster</span>
                </>
              )}
            </h3>
            <button
              onClick={() => setActivePanel(null)}
              className="p-1 hover:bg-slate-200 rounded-lg text-slate-500"
            >
              <X className="w-4 h-4" />
            </button>
          </div>

          {/* Chat Panel */}
          {activePanel === 'chat' && (
            <div className="flex-1 flex flex-col justify-between overflow-hidden">
              <div className="flex-1 p-3 overflow-y-auto space-y-3">
                {chatMessages.map((msg) => (
                  <div key={msg.id} className="flex flex-col space-y-0.5">
                    <div className="flex items-center space-x-1.5">
                      <span
                        className={`text-[11px] font-bold ${
                          msg.role === 'teacher' ? 'text-indigo-600' : 'text-slate-800'
                        }`}
                      >
                        {msg.sender}
                      </span>
                      {msg.role === 'teacher' && (
                        <span className="px-1.5 py-0.2 bg-indigo-50 text-indigo-700 text-[9px] font-extrabold rounded border border-indigo-200">
                          Teacher
                        </span>
                      )}
                      <span className="text-[9px] text-slate-400">{msg.timestamp}</span>
                    </div>
                    <p className="text-xs text-slate-700 bg-slate-50 rounded-xl p-2 border border-slate-100 leading-relaxed break-words">
                      {msg.message}
                    </p>
                  </div>
                ))}
              </div>
              <form onSubmit={handleSendChat} className="p-3 border-t border-slate-200 flex items-center space-x-2 bg-slate-50">
                <input
                  type="text"
                  value={currentChatInput}
                  onChange={(e) => setCurrentChatInput(e.target.value)}
                  placeholder="Ask something to the class..."
                  className="flex-1 text-xs px-3 py-2 bg-white border border-slate-200 rounded-xl focus:outline-none focus:border-indigo-500"
                />
                <button
                  type="submit"
                  className="p-2 bg-indigo-600 text-white rounded-xl hover:bg-indigo-700 transition-colors shrink-0"
                >
                  <Send className="w-3.5 h-3.5" />
                </button>
              </form>
            </div>
          )}

          {/* Doubts Panel */}
          {activePanel === 'doubts' && (
            <div className="flex-1 flex flex-col justify-between overflow-hidden">
              <div className="flex-1 p-3 overflow-y-auto space-y-2.5">
                {doubts.length === 0 ? (
                  <div className="text-center py-8 text-slate-400 text-xs">
                    <HelpCircle className="w-8 h-8 mx-auto mb-2 opacity-50" />
                    No doubts asked yet. Students can raise doubts anytime!
                  </div>
                ) : (
                  doubts.map((d) => (
                    <div
                      key={d.id}
                      className={`p-3 rounded-2xl border text-xs transition-all ${
                        d.status === 'resolved' ? 'bg-slate-50 border-slate-200 opacity-60' : 'bg-rose-50/50 border-rose-200'
                      }`}
                    >
                      <div className="flex justify-between items-center mb-1">
                        <span className="font-bold text-slate-800">{d.studentName}</span>
                        <span className="text-[10px] text-slate-400">{d.timestamp}</span>
                      </div>
                      <p className="text-slate-700 mb-2 leading-relaxed">{d.doubtText}</p>
                      <div className="flex justify-end">
                        {d.status === 'resolved' ? (
                          <span className="inline-flex items-center text-[10px] font-bold text-emerald-600 bg-emerald-50 px-2 py-0.5 rounded-full border border-emerald-200">
                            <CheckCircle2 className="w-3 h-3 mr-1" /> Answered
                          </span>
                        ) : isTeacher ? (
                          <button
                            onClick={() => handleResolveDoubt(d.id)}
                            className="px-2.5 py-1 bg-indigo-600 text-white font-bold text-[10px] rounded-lg hover:bg-indigo-700"
                          >
                            Mark Answered
                          </button>
                        ) : (
                          <span className="text-[10px] text-amber-600 font-semibold bg-amber-50 px-2 py-0.5 rounded-full border border-amber-200">
                            Waiting for Teacher
                          </span>
                        )}
                      </div>
                    </div>
                  ))
                )}
              </div>
              {!isTeacher && (
                <form onSubmit={handleSubmitDoubt} className="p-3 border-t border-slate-200 bg-slate-50">
                  <div className="flex space-x-2">
                    <input
                      type="text"
                      value={newDoubtText}
                      onChange={(e) => setNewDoubtText(e.target.value)}
                      placeholder="Type your question for teacher..."
                      className="flex-1 text-xs px-3 py-2 bg-white border border-slate-200 rounded-xl focus:outline-none focus:border-indigo-500"
                    />
                    <button
                      type="submit"
                      className="px-3 py-2 bg-rose-600 text-white font-bold text-xs rounded-xl hover:bg-rose-700"
                    >
                      Raise
                    </button>
                  </div>
                </form>
              )}
            </div>
          )}

          {/* Polls Panel */}
          {activePanel === 'polls' && (
            <div className="flex-1 p-4 overflow-y-auto space-y-4">
              {activePoll ? (
                <div className="bg-white border border-slate-200 rounded-2xl p-4 shadow-subtle">
                  <span className="text-[10px] font-extrabold uppercase text-indigo-600 bg-indigo-50 px-2 py-0.5 rounded">
                    Active Poll
                  </span>
                  <h4 className="text-xs font-bold text-slate-800 mt-2 mb-3 leading-snug">
                    {activePoll.question}
                  </h4>
                  <div className="space-y-2">
                    {activePoll.options.map((opt, i) => {
                      const pct = activePoll.totalVotes > 0 ? Math.round((opt.votes / activePoll.totalVotes) * 100) : 0;
                      return (
                        <button
                          key={i}
                          onClick={() => handleVote(i)}
                          disabled={userVoted !== null || isTeacher}
                          className={`w-full text-left p-2.5 rounded-xl border text-xs relative overflow-hidden transition-all ${
                            userVoted === i ? 'border-indigo-500 bg-indigo-50/50 font-bold' : 'border-slate-200 hover:border-slate-300'
                          }`}
                        >
                          <div className="absolute left-0 top-0 bottom-0 bg-indigo-100/60" style={{ width: `${pct}%` }} />
                          <div className="relative flex justify-between items-center">
                            <span className="font-semibold text-slate-800">{opt.text}</span>
                            <span className="font-bold text-indigo-600">{pct}% ({opt.votes})</span>
                          </div>
                        </button>
                      );
                    })}
                  </div>
                </div>
              ) : (
                <p className="text-xs text-slate-500 text-center py-6">No active poll right now.</p>
              )}

              {isTeacher && (
                <form onSubmit={handleCreatePoll} className="border-t border-slate-200 pt-3 text-xs">
                  <h5 className="font-bold text-slate-700 mb-2">Create Rapid Quiz Poll</h5>
                  <input
                    type="text"
                    value={newPollQuestion}
                    onChange={(e) => setNewPollQuestion(e.target.value)}
                    placeholder="Question..."
                    className="w-full p-2 border border-slate-200 rounded-lg mb-2"
                  />
                  <input
                    type="text"
                    value={newPollOpt1}
                    onChange={(e) => setNewPollOpt1(e.target.value)}
                    placeholder="Option 1"
                    className="w-full p-2 border border-slate-200 rounded-lg mb-2"
                  />
                  <input
                    type="text"
                    value={newPollOpt2}
                    onChange={(e) => setNewPollOpt2(e.target.value)}
                    placeholder="Option 2"
                    className="w-full p-2 border border-slate-200 rounded-lg mb-3"
                  />
                  <button
                    type="submit"
                    className="w-full py-2 font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-xl shadow-xs"
                  >
                    Broadcast Poll
                  </button>
                </form>
              )}
            </div>
          )}

          {/* Roster Panel */}
          {activePanel === 'roster' && (
            <div className="flex-1 p-3 overflow-y-auto space-y-2">
              {participants.map((p, idx) => (
                <div key={idx} className="flex items-center justify-between p-2 rounded-xl border border-slate-100 text-xs bg-slate-50/50">
                  <div className="flex items-center space-x-2">
                    <div className="w-7 h-7 rounded-full bg-indigo-100 text-indigo-700 font-bold flex items-center justify-center text-[10px]">
                      {p.name.charAt(0)}
                    </div>
                    <div>
                      <p className="font-bold text-slate-800">{p.name}</p>
                      <p className="text-[10px] text-slate-400 capitalize">{p.role}</p>
                    </div>
                  </div>
                  <span
                    className={`text-[10px] font-semibold px-2 py-0.5 rounded-full ${
                      p.status === 'Speaking' ? 'bg-emerald-100 text-emerald-800' : p.status === 'Hand Raised' ? 'bg-amber-100 text-amber-800 font-bold' : 'bg-slate-100 text-slate-600'
                    }`}
                  >
                    {p.status}
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* Full HD Recording Download Modal */}
      {recordingModalOpen && recordingBlobUrl && (
        <div className="absolute inset-0 bg-slate-900/60 backdrop-blur-sm flex items-center justify-center z-50 p-4 animate-in fade-in duration-200">
          <div className="bg-white rounded-2xl shadow-elevated border border-slate-200 w-full max-w-lg overflow-hidden flex flex-col">
            <div className="p-4 border-b border-slate-200 flex items-center justify-between bg-slate-50">
              <div className="flex items-center space-x-2.5">
                <div className="w-8 h-8 rounded-full bg-rose-100 text-rose-600 flex items-center justify-center font-bold">
                  <Film className="w-4 h-4" />
                </div>
                <div>
                  <h3 className="text-sm font-bold text-slate-800">Lecture Recording Ready</h3>
                  <p className="text-[11px] text-slate-500">Full HD 1080p Video + Clear Audio</p>
                </div>
              </div>
              <button
                onClick={() => setRecordingModalOpen(false)}
                className="p-1 hover:bg-slate-200 rounded-lg text-slate-400 hover:text-slate-600 transition-colors"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="p-4 flex flex-col space-y-3">
              {/* Video Preview */}
              <div className="relative aspect-video bg-black rounded-xl overflow-hidden shadow-inner border border-slate-200">
                <video
                  src={recordingBlobUrl}
                  controls
                  className="w-full h-full object-contain"
                />
              </div>

              {/* Video Info Card */}
              <div className="bg-slate-50 rounded-xl p-3 border border-slate-200 text-xs flex items-center justify-between">
                <div>
                  <p className="font-bold text-slate-800">{classInfo?.title || 'Interactive Class Session'}</p>
                  <p className="text-slate-500 text-[11px]">Duration: {formatTime(recordingDuration)}</p>
                </div>
                <span className="px-2.5 py-1 bg-emerald-100 text-emerald-800 font-bold rounded-lg text-[10px]">
                  1080p Full HD
                </span>
              </div>
            </div>

            <div className="p-4 border-t border-slate-200 bg-slate-50 flex items-center justify-end space-x-2">
              <button
                onClick={() => setRecordingModalOpen(false)}
                className="px-4 py-2 text-xs font-semibold text-slate-600 hover:bg-slate-200 rounded-xl transition-colors"
              >
                Close
              </button>
              <a
                href={recordingBlobUrl}
                download={`Classora-Lecture-${(classInfo?.title || 'Class').replace(/\s+/g, '_')}-${Date.now()}.webm`}
                className="px-4 py-2 text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-xl shadow-xs flex items-center space-x-1.5 transition-colors"
              >
                <Download className="w-4 h-4" />
                <span>Download Recording (Full HD)</span>
              </a>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
