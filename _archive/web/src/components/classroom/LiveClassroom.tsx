import React, { useState, useEffect, useRef } from 'react';
import {
  Mic,
  MicOff,
  Video,
  VideoOff,
  Hand,
  MessageSquare,
  Users,
  PhoneOff,
  HelpCircle,
  CheckCircle2,
  Send,
  Share2,
  Lock,
  Maximize2,
  Minimize2,
  FileText,
  Play,
  FolderOpen,
  Upload,
  Sparkles,
  ChevronDown,
  ChevronUp,
  Monitor,
  Search,
  X,
  ArrowLeft,
  Volume2,
  VolumeX,
  ShieldCheck,
  Smile,
} from 'lucide-react';
import { DigitalBoard } from '../board/DigitalBoard.js';
import { DocumentViewer, samplePhysicsDocument, DocumentItem } from '../document/DocumentViewer.js';
import { ChatMessage, DoubtItem } from '../../types/index.js';
import { useMobileNavigation } from '../../hooks/useMobileNavigation.js';

interface LiveClassroomProps {
  role: 'teacher' | 'student';
  userName: string;
  onExit: () => void;
}

export const LiveClassroom: React.FC<LiveClassroomProps> = ({ role, userName, onExit }) => {
  const isTeacher = role === 'teacher';

  // 1. Pre-join Lobby State (Zoom/Meet Style)
  const [isPreJoin, setIsPreJoin] = useState(true);

  // AV State
  const [micOn, setMicOn] = useState(true);
  const [camOn, setCamOn] = useState(true);
  const [isFullscreen, setIsFullscreen] = useState(false);
  const [isDockHidden, setIsDockHidden] = useState(false);

  // Media Stream Refs
  const preJoinVideoRef = useRef<HTMLVideoElement | null>(null);
  const liveVideoRef = useRef<HTMLVideoElement | null>(null);
  const fileInputRef = useRef<HTMLInputElement | null>(null);
  const [mediaStream, setMediaStream] = useState<MediaStream | null>(null);

  // Classroom Mode: 'whiteboard' | 'document' | 'screenshare'
  const [classroomMode, setClassroomMode] = useState<'whiteboard' | 'document' | 'screenshare'>('whiteboard');

  // Screen Share State
  const [isScreenSharing, setIsScreenSharing] = useState(false);
  const [screenStream, setScreenStream] = useState<MediaStream | null>(null);
  const [screenShareTab, setScreenShareTab] = useState<'google' | 'wiki' | 'simulation'>('google');
  const screenVideoRef = useRef<HTMLVideoElement | null>(null);

  // Currently Presented Document (Supports system file upload!)
  const [currentPresentedDocument, setCurrentPresentedDocument] = useState<DocumentItem>(samplePhysicsDocument);
  const [loadedFileName, setLoadedFileName] = useState<string | null>(null);

  // Side Drawer Panels: 'chat' | 'doubts' | 'roster' | null (Defaults to null so class view is immediately visible!)
  const [activePanel, setActivePanel] = useState<'chat' | 'doubts' | 'roster' | null>(null);

  // Mobile Motion Navigation & Gesture Back Handler (Edge Swipe, Android Hardware Back, and Screen Touch Slide)
  const { touchHandlers: panelTouchHandlers } = useMobileNavigation({
    onBack: () => {
      if (activePanel) {
        setActivePanel(null);
      } else if (classroomMode !== 'whiteboard') {
        setClassroomMode('whiteboard');
      } else {
        onExit();
      }
    },
    enabled: true,
  });

  // Elapsed Meeting Timer
  const [elapsedSeconds, setElapsedSeconds] = useState(2532);
  useEffect(() => {
    const timer = setInterval(() => setElapsedSeconds((s) => s + 1), 1000);
    return () => clearInterval(timer);
  }, []);

  const formatTimer = (sec: number) => {
    const h = Math.floor(sec / 3600);
    const m = Math.floor((sec % 3600) / 60);
    const s = sec % 60;
    return `${h > 0 ? h + ':' : ''}${m < 10 ? '0' : ''}${m}:${s < 10 ? '0' : ''}${s}`;
  };

  // Screen Share Handler (Allows Teacher to share screen/browser tab for Google Search, Youtube, etc.)
  const handleToggleScreenShare = async () => {
    if (isScreenSharing) {
      if (screenStream) {
        screenStream.getTracks().forEach((t) => t.stop());
      }
      setScreenStream(null);
      setIsScreenSharing(false);
      setClassroomMode('whiteboard');
      return;
    }

    try {
      if (navigator.mediaDevices && navigator.mediaDevices.getDisplayMedia) {
        const stream = await navigator.mediaDevices.getDisplayMedia({
          video: { cursor: 'always' } as any,
          audio: true,
        });

        setScreenStream(stream);
        setIsScreenSharing(true);
        setClassroomMode('screenshare');

        // Handle user clicking native browser "Stop sharing" floating bar
        stream.getVideoTracks()[0].onended = () => {
          setScreenStream(null);
          setIsScreenSharing(false);
          setClassroomMode('whiteboard');
        };
      } else {
        // Fallback for demo environments
        setIsScreenSharing(true);
        setClassroomMode('screenshare');
      }
    } catch (err) {
      console.warn('Screen share canceled or not granted:', err);
    }
  };

  // Camera initialization helper using getUserMedia
  useEffect(() => {
    let stream: MediaStream | null = null;

    async function initCamera() {
      if (!camOn) {
        if (mediaStream) {
          mediaStream.getTracks().forEach((track) => track.stop());
          setMediaStream(null);
        }
        return;
      }

      try {
        if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
          stream = await navigator.mediaDevices.getUserMedia({ video: true, audio: micOn });
          setMediaStream(stream);
        }
      } catch (err) {
        console.warn('Camera stream not accessible or permission denied, fallback active:', err);
      }
    }

    initCamera();

    return () => {
      if (stream) {
        stream.getTracks().forEach((t) => t.stop());
      }
    };
  }, [camOn]);

  // Bind video element srcObjects
  useEffect(() => {
    if (preJoinVideoRef.current && mediaStream) {
      preJoinVideoRef.current.srcObject = mediaStream;
    }
    if (liveVideoRef.current && mediaStream) {
      liveVideoRef.current.srcObject = mediaStream;
    }
    if (screenVideoRef.current && screenStream) {
      screenVideoRef.current.srcObject = screenStream;
    }
  }, [mediaStream, screenStream, isPreJoin, classroomMode]);

  // Local System File Picker Handler (Opens PDF / PPT directly from user's computer!)
  const handleOpenLocalFile = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const fileUrl = URL.createObjectURL(file);
    const fileExt = file.name.split('.').pop()?.toUpperCase() || 'DOCUMENT';
    const fileSizeMB = (file.size / (1024 * 1024)).toFixed(2);
    const cleanName = file.name.replace(/\.[^/.]+$/, '');
    setLoadedFileName(file.name);

    const newDoc: DocumentItem = {
      id: `doc-local-${Date.now()}`,
      title: cleanName,
      fileName: file.name,
      fileUrl: fileUrl,
      author: userName || 'Faculty Instructor',
      totalPages: 4,
      slides: [
        {
          pageNumber: 1,
          title: `Page 1: ${cleanName} - Executive Overview`,
          subtitle: `Uploaded File: ${fileExt} (${fileSizeMB} MB)`,
          content: [
            `• Successfully loaded "${file.name}" directly from local disk storage.`,
            `• Live Synchronized Presentation Stream active for all 34 enrolled students.`,
            `• Format: ${fileExt} • Size: ${fileSizeMB} MB.`,
          ],
          formula: 'Live Slide Stream \\quad \\text{Status: Synchronized}',
          diagramUrl: 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=600&h=350&fit=crop',
        },
        {
          pageNumber: 2,
          title: `Page 2: Core Modules & Architecture`,
          subtitle: `System Presentation - ${cleanName}`,
          content: [
            `• Key Derivations, Problem Solving Diagrams & Specifications.`,
            `• Interactive Whiteboard Annotation & Marker tools enabled over document.`,
            `• Real-time broadcast synced across student devices.`,
          ],
          formula: 'Architecture \\quad \\text{Level: High Performance}',
          diagramUrl: 'https://images.unsplash.com/photo-1507238691740-187a5b1d37b8?w=600&h=350&fit=crop',
        },
        {
          pageNumber: 3,
          title: `Page 3: Analysis & Worked Examples`,
          subtitle: `Practice Problem Set - ${cleanName}`,
          content: [
            `• Example Problem 01: Calculate rotational kinetic energy of rigid body.`,
            `• Example Problem 02: Determine angular acceleration on inclined plane.`,
          ],
          formula: 'K_{rot} = \\frac{1}{2} I \\omega^2',
          diagramUrl: 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=600&h=350&fit=crop',
        },
        {
          pageNumber: 4,
          title: `Page 4: Summary & Concluding Remarks`,
          subtitle: `Final Lecture Slide - ${cleanName}`,
          content: [
            `• Practice Questions assigned for upcoming live evaluation.`,
            `• Complete PDF notes available for all enrolled batch students to download.`,
          ],
          formula: 'L_{final} = L_{initial}',
          diagramUrl: 'https://images.unsplash.com/photo-1531403009284-440f080d1e12?w=600&h=350&fit=crop',
        },
      ],
    };

    setCurrentPresentedDocument(newDoc);
    setClassroomMode('document');
  };

  // Chat state
  const [chatMessages, setChatMessages] = useState<ChatMessage[]>([
    {
      id: '1',
      sender: 'Prof. Rajesh Sharma',
      message: 'Welcome everyone! Today we will solve rotational dynamics problems.',
      role: 'teacher',
      timestamp: '18:30',
    },
    {
      id: '2',
      sender: 'Priya Singh',
      message: 'Good evening Sir, will we cover conservation of angular momentum today?',
      role: 'student',
      timestamp: '18:31',
    },
    {
      id: '3',
      sender: 'Prof. Rajesh Sharma',
      message: 'Yes Priya, right after solving the rolling disc example on the board.',
      role: 'teacher',
      timestamp: '18:32',
    },
  ]);
  const [currentChatInput, setCurrentChatInput] = useState('');

  // Doubts state
  const [doubts, setDoubts] = useState<DoubtItem[]>([
    {
      id: 'd-1',
      studentName: 'Rohan Verma',
      doubtText: 'Sir, why does static friction do no work in pure rolling?',
      status: 'pending',
      timestamp: '18:33',
    },
    {
      id: 'd-2',
      studentName: 'Aarav Patel',
      doubtText: 'Can you re-explain the torque about the instantaneous axis?',
      status: 'resolved',
      timestamp: '18:31',
    },
  ]);
  const [newDoubtText, setNewDoubtText] = useState('');
  const [handRaised, setHandRaised] = useState(false);

  // Full 34 Class Participants State
  const [participantsList, setParticipantsList] = useState<Array<{
    id: string;
    name: string;
    role: 'teacher' | 'student';
    rollNo: string;
    status: 'Speaking' | 'Hand Raised' | 'Attending';
    mic: boolean;
    video: boolean;
  }>>([
    { id: 'p-1', name: 'Prof. Rajesh Sharma', role: 'teacher', rollNo: 'HOST-01', status: 'Speaking', mic: micOn, video: camOn },
    { id: 'p-2', name: 'Priya Singh', role: 'student', rollNo: 'JEE-2401', status: 'Attending', mic: false, video: true },
    { id: 'p-3', name: 'Aarav Patel', role: 'student', rollNo: 'JEE-2402', status: 'Attending', mic: false, video: true },
    { id: 'p-4', name: 'Rohan Verma', role: 'student', rollNo: 'JEE-2403', status: 'Hand Raised', mic: false, video: false },
    { id: 'p-5', name: 'Neha Sharma', role: 'student', rollNo: 'JEE-2404', status: 'Attending', mic: false, video: true },
    { id: 'p-6', name: 'Aditya Kumar', role: 'student', rollNo: 'JEE-2405', status: 'Hand Raised', mic: false, video: true },
    { id: 'p-7', name: 'Ananya Roy', role: 'student', rollNo: 'JEE-2406', status: 'Attending', mic: false, video: true },
    { id: 'p-8', name: 'Siddharth Verma', role: 'student', rollNo: 'JEE-2407', status: 'Attending', mic: false, video: false },
    { id: 'p-9', name: 'Ishita Gupta', role: 'student', rollNo: 'JEE-2408', status: 'Attending', mic: false, video: true },
    { id: 'p-10', name: 'Rahul Das', role: 'student', rollNo: 'JEE-2409', status: 'Attending', mic: false, video: true },
    { id: 'p-11', name: 'Pooja Mehta', role: 'student', rollNo: 'JEE-2410', status: 'Attending', mic: false, video: false },
    { id: 'p-12', name: 'Vikram Malhotra', role: 'student', rollNo: 'JEE-2411', status: 'Attending', mic: false, video: true },
    { id: 'p-13', name: 'Sneha Nair', role: 'student', rollNo: 'JEE-2412', status: 'Attending', mic: false, video: true },
    { id: 'p-14', name: 'Tanmay Joshi', role: 'student', rollNo: 'JEE-2413', status: 'Attending', mic: false, video: false },
    { id: 'p-15', name: 'Divya Agarwal', role: 'student', rollNo: 'JEE-2414', status: 'Attending', mic: false, video: true },
    { id: 'p-16', name: 'Manav Bansal', role: 'student', rollNo: 'JEE-2415', status: 'Attending', mic: false, video: true },
    { id: 'p-17', name: 'Kavya Iyer', role: 'student', rollNo: 'JEE-2416', status: 'Attending', mic: false, video: false },
    { id: 'p-18', name: 'Harsh Vardhan', role: 'student', rollNo: 'JEE-2417', status: 'Attending', mic: false, video: true },
    { id: 'p-19', name: 'Simran Kaur', role: 'student', rollNo: 'JEE-2418', status: 'Attending', mic: false, video: true },
    { id: 'p-20', name: 'Kunal Choudhary', role: 'student', rollNo: 'JEE-2419', status: 'Attending', mic: false, video: false },
    { id: 'p-21', name: 'Riya Sen', role: 'student', rollNo: 'JEE-2420', status: 'Attending', mic: false, video: true },
    { id: 'p-22', name: 'Devansh Tripathi', role: 'student', rollNo: 'JEE-2421', status: 'Attending', mic: false, video: true },
    { id: 'p-23', name: 'Meera Nambiar', role: 'student', rollNo: 'JEE-2422', status: 'Attending', mic: false, video: false },
    { id: 'p-24', name: 'Yash Singhal', role: 'student', rollNo: 'JEE-2423', status: 'Attending', mic: false, video: true },
    { id: 'p-25', name: 'Shreya Bhattacharya', role: 'student', rollNo: 'JEE-2424', status: 'Attending', mic: false, video: true },
    { id: 'p-26', name: 'Ayush Rawat', role: 'student', rollNo: 'JEE-2425', status: 'Attending', mic: false, video: false },
    { id: 'p-27', name: 'Kritika Saxena', role: 'student', rollNo: 'JEE-2426', status: 'Attending', mic: false, video: true },
    { id: 'p-28', name: 'Nikhil Tiwari', role: 'student', rollNo: 'JEE-2427', status: 'Attending', mic: false, video: true },
    { id: 'p-29', name: 'Alok Mishra', role: 'student', rollNo: 'JEE-2428', status: 'Attending', mic: false, video: false },
    { id: 'p-30', name: 'Swati Pandey', role: 'student', rollNo: 'JEE-2429', status: 'Attending', mic: false, video: true },
    { id: 'p-31', name: 'Gaurav Chauhan', role: 'student', rollNo: 'JEE-2430', status: 'Attending', mic: false, video: true },
    { id: 'p-32', name: 'Prachi Deshmukh', role: 'student', rollNo: 'JEE-2431', status: 'Attending', mic: false, video: false },
    { id: 'p-33', name: 'Ritvik Kapoor', role: 'student', rollNo: 'JEE-2432', status: 'Attending', mic: false, video: true },
    { id: 'p-34', name: 'Sanya Mirza', role: 'student', rollNo: 'JEE-2433', status: 'Attending', mic: false, video: true },
  ]);

  const [rosterSearch, setRosterSearch] = useState('');
  const [rosterFilter, setRosterFilter] = useState<'all' | 'hands' | 'teachers'>('all');

  const handleMuteAll = () => {
    setParticipantsList((prev) =>
      prev.map((p) => (p.role === 'student' ? { ...p, mic: false } : p))
    );
  };

  const handleToggleParticipantMic = (id: string) => {
    setParticipantsList((prev) =>
      prev.map((p) => (p.id === id ? { ...p, mic: !p.mic } : p))
    );
  };

  const handleLowerParticipantHand = (id: string) => {
    setParticipantsList((prev) =>
      prev.map((p) => (p.id === id ? { ...p, status: 'Attending' } : p))
    );
  };

  const filteredParticipants = participantsList.filter((p) => {
    const matchesSearch =
      p.name.toLowerCase().includes(rosterSearch.toLowerCase()) ||
      p.rollNo.toLowerCase().includes(rosterSearch.toLowerCase());
    if (!matchesSearch) return false;
    if (rosterFilter === 'hands') return p.status === 'Hand Raised';
    if (rosterFilter === 'teachers') return p.role === 'teacher';
    return true;
  });

  const handleQuickReaction = (emoji: string) => {
    const newMsg: ChatMessage = {
      id: `chat-${Date.now()}`,
      sender: userName,
      message: emoji,
      role: role,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    };
    setChatMessages((prev) => [...prev, newMsg]);
  };

  // Toggle Fullscreen
  const toggleFullscreen = () => {
    if (!document.fullscreenElement) {
      document.documentElement.requestFullscreen().catch(() => {});
      setIsFullscreen(true);
    } else {
      if (document.exitFullscreen) {
        document.exitFullscreen().catch(() => {});
      }
      setIsFullscreen(false);
    }
  };

  // Send Chat
  const handleSendChat = (e: React.FormEvent) => {
    e.preventDefault();
    if (!currentChatInput.trim()) return;
    const newMsg: ChatMessage = {
      id: `chat-${Date.now()}`,
      sender: userName,
      message: currentChatInput.trim(),
      role: role,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    };
    setChatMessages((prev) => [...prev, newMsg]);
    setCurrentChatInput('');
  };

  // Submit Doubt
  const handleSubmitDoubt = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newDoubtText.trim()) return;
    const newDoubt: DoubtItem = {
      id: `d-${Date.now()}`,
      studentName: userName,
      doubtText: newDoubtText.trim(),
      status: 'pending',
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    };
    setDoubts((prev) => [newDoubt, ...prev]);
    setNewDoubtText('');
  };

  // Resolve Doubt
  const handleResolveDoubt = (id: string) => {
    setDoubts((prev) =>
      prev.map((d) => (d.id === id ? { ...d, status: 'resolved' } : d))
    );
  };

  // ==================== 1. ZOOM / MEET PRE-JOIN LOBBY SCREEN ====================
  if (isPreJoin) {
    return (
      <div className="fixed inset-0 z-50 bg-slate-950 text-slate-100 flex flex-col items-center justify-center p-4 font-sans select-none">
        {/* Brand Header */}
        <div className="flex items-center space-x-2 mb-6">
          <div className="w-8 h-8 rounded-xl bg-indigo-600 text-white font-black text-sm flex items-center justify-center shadow-md">
            C
          </div>
          <span className="text-lg font-black tracking-tight text-white">CLASSORA LIVE CLASSROOM</span>
        </div>

        <div className="bg-slate-900 border border-slate-800 rounded-3xl p-6 sm:p-8 max-w-xl w-full shadow-2xl space-y-6">
          <div className="text-center space-y-1">
            <span className="text-[11px] font-bold uppercase tracking-wider text-emerald-400 bg-emerald-500/10 px-3 py-1 rounded-full border border-emerald-500/30">
              Pre-Join Audio & Video Check
            </span>
            <h2 className="text-xl sm:text-2xl font-black text-white mt-2">
              Ready to Join the Lecture?
            </h2>
            <p className="text-xs text-slate-400">
              Physics JEE Super 30: Angular Momentum & Rolling Motion
            </p>
          </div>

          {/* Camera Preview Box */}
          <div className="relative aspect-video rounded-2xl bg-slate-950 border border-slate-800 overflow-hidden shadow-inner flex items-center justify-center">
            {camOn ? (
              mediaStream ? (
                <video
                  ref={preJoinVideoRef}
                  autoPlay
                  playsInline
                  muted
                  className="w-full h-full object-cover scale-x-[-1]"
                />
              ) : (
                <div className="relative w-full h-full">
                  <img
                    src="https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600&h=400&fit=crop"
                    alt="Camera Stream Preview"
                    className="w-full h-full object-cover"
                  />
                  <div className="absolute top-3 left-3 bg-emerald-600/90 text-white text-[10px] font-bold px-2.5 py-0.5 rounded-md backdrop-blur-xs">
                    Camera Connected (Live Preview)
                  </div>
                </div>
              )
            ) : (
              <div className="flex flex-col items-center justify-center text-slate-500 space-y-2">
                <div className="w-16 h-16 rounded-full bg-slate-900 border border-slate-800 flex items-center justify-center">
                  <VideoOff className="w-8 h-8 text-rose-500" />
                </div>
                <span className="text-xs font-semibold text-slate-400">Your camera is currently off</span>
              </div>
            )}

            {/* Mic Audio Waveform Bar */}
            <div className="absolute bottom-3 left-3 right-3 flex items-center justify-between bg-slate-900/85 backdrop-blur-md px-3 py-1.5 rounded-xl border border-slate-800">
              <div className="flex items-center space-x-2 text-xs">
                {micOn ? (
                  <>
                    <Mic className="w-4 h-4 text-emerald-400" />
                    <span className="text-[11px] font-semibold text-emerald-400">Microphone Active</span>
                  </>
                ) : (
                  <>
                    <MicOff className="w-4 h-4 text-rose-500" />
                    <span className="text-[11px] font-semibold text-rose-400">Microphone Muted</span>
                  </>
                )}
              </div>

              {/* Volume Wave Dots */}
              {micOn && (
                <div className="flex items-center space-x-1">
                  <span className="w-1 h-3 bg-emerald-500 rounded-full animate-bounce" />
                  <span className="w-1 h-4 bg-emerald-400 rounded-full animate-bounce delay-75" />
                  <span className="w-1 h-2 bg-emerald-500 rounded-full animate-bounce delay-150" />
                </div>
              )}
            </div>
          </div>

          {/* Controls: Mute/Unmute & Cam On/Off */}
          <div className="flex items-center justify-center space-x-4">
            <button
              onClick={() => setMicOn(!micOn)}
              className={`flex items-center space-x-2 px-5 py-3 rounded-2xl border text-xs font-bold transition-all ${
                micOn
                  ? 'bg-slate-800 text-slate-100 border-slate-700 hover:bg-slate-750'
                  : 'bg-rose-600/20 text-rose-400 border-rose-500/40 hover:bg-rose-600/30'
              }`}
            >
              {micOn ? <Mic className="w-4 h-4 text-emerald-400" /> : <MicOff className="w-4 h-4 text-rose-500" />}
              <span>{micOn ? 'Mic is On' : 'Unmute Mic'}</span>
            </button>

            <button
              onClick={() => setCamOn(!camOn)}
              className={`flex items-center space-x-2 px-5 py-3 rounded-2xl border text-xs font-bold transition-all ${
                camOn
                  ? 'bg-slate-800 text-slate-100 border-slate-700 hover:bg-slate-750'
                  : 'bg-rose-600/20 text-rose-400 border-rose-500/40 hover:bg-rose-600/30'
              }`}
            >
              {camOn ? <Video className="w-4 h-4 text-emerald-400" /> : <VideoOff className="w-4 h-4 text-rose-500" />}
              <span>{camOn ? 'Camera is On' : 'Turn Camera On'}</span>
            </button>
          </div>

          {/* Enter Meeting Button */}
          <div className="pt-2 flex items-center space-x-3">
            <button
              onClick={onExit}
              className="flex-1 py-3 text-xs font-bold text-slate-400 bg-slate-800 hover:bg-slate-750 hover:text-white rounded-2xl transition-colors"
            >
              Cancel
            </button>
            <button
              onClick={() => setIsPreJoin(false)}
              className="flex-2 py-3 text-xs font-black text-white bg-indigo-600 hover:bg-indigo-500 rounded-2xl shadow-xl flex items-center justify-center space-x-2 transition-all"
            >
              <Play className="w-4 h-4 fill-current" />
              <span>Join Live Classroom Now</span>
            </button>
          </div>
        </div>
      </div>
    );
  }

  // ==================== 2. MAIN LIVE CLASSROOM STAGE ====================
  return (
    <div className="fixed inset-0 z-50 bg-slate-950 text-slate-100 flex flex-col h-screen w-screen overflow-hidden font-sans select-none">
      {/* Hidden System File Input for Local System PDF / PPT Upload */}
      <input
        type="file"
        ref={fileInputRef}
        accept=".pdf,.ppt,.pptx,.txt,.doc,.docx"
        onChange={handleOpenLocalFile}
        className="hidden"
      />

      {/* Top Zoom/Meet Header Bar */}
      <header className="h-14 bg-slate-900 border-b border-slate-800 px-4 flex items-center justify-between shrink-0 z-40">
        <div className="flex items-center space-x-3">
          {/* Live Badge */}
          <span className="inline-flex items-center px-2.5 py-1 rounded-full text-[11px] font-black bg-rose-500/20 text-rose-400 border border-rose-500/30">
            <span className="w-2 h-2 rounded-full bg-rose-500 animate-ping mr-1.5" />
            LIVE
          </span>

          <div className="flex items-center space-x-2">
            <Lock className="w-3.5 h-3.5 text-emerald-400" />
            <h2 className="text-xs sm:text-sm font-bold text-slate-100 truncate max-w-xs sm:max-w-md">
              Physics JEE Super 30: Angular Momentum & Rolling Motion
            </h2>
          </div>

          <span className="hidden md:inline text-xs text-slate-600">|</span>

          {/* Recording Badge & Timer */}
          <div className="hidden md:flex items-center space-x-2 text-xs text-slate-400 bg-slate-800/60 px-2.5 py-1 rounded-lg border border-slate-700/50">
            <span className="w-2 h-2 rounded-full bg-rose-500 animate-pulse" />
            <span className="font-semibold text-rose-400">REC</span>
            <span className="font-mono text-slate-300">{formatTimer(elapsedSeconds)}</span>
          </div>
        </div>

        {/* Right Top Header Actions */}
        <div className="flex items-center space-x-3 text-xs">
          <div className="hidden sm:flex items-center space-x-2 bg-slate-800/80 px-3 py-1.5 rounded-xl border border-slate-700/60 text-slate-300">
            <Users className="w-3.5 h-3.5 text-indigo-400" />
            <span className="font-bold">34 Students Joined</span>
          </div>

          <button
            onClick={() => setIsDockHidden(!isDockHidden)}
            className={`flex items-center space-x-1 px-2.5 py-1.5 text-xs font-bold rounded-xl border transition-all ${
              isDockHidden
                ? 'bg-indigo-600 text-white border-indigo-500 shadow-md'
                : 'bg-slate-800/80 text-slate-300 border-slate-700/60 hover:text-white'
            }`}
            title={isDockHidden ? 'Show Meeting Controls' : 'Hide Meeting Controls'}
          >
            {isDockHidden ? <ChevronUp className="w-3.5 h-3.5" /> : <ChevronDown className="w-3.5 h-3.5" />}
            <span className="hidden sm:inline">{isDockHidden ? 'Show Controls' : 'Hide Controls'}</span>
          </button>

          <button
            onClick={toggleFullscreen}
            className="p-2 text-slate-400 hover:text-white bg-slate-800/80 hover:bg-slate-800 rounded-xl border border-slate-700/60 transition-colors"
            title="Toggle Fullscreen"
          >
            {isFullscreen ? <Minimize2 className="w-4 h-4" /> : <Maximize2 className="w-4 h-4" />}
          </button>

          <button
            onClick={onExit}
            className="flex items-center space-x-1.5 px-3.5 py-1.5 text-xs font-bold text-white bg-rose-600 hover:bg-rose-700 rounded-xl shadow-md transition-colors"
          >
            <PhoneOff className="w-3.5 h-3.5" />
            <span>{isTeacher ? 'End Meeting' : 'Leave'}</span>
          </button>
        </div>
      </header>

      {/* Main Center Body */}
      <div className="flex-1 flex overflow-hidden relative">
        {/* CENTER STAGE VIEWPORT */}
        <div className="flex-1 flex flex-col relative h-full bg-slate-900 overflow-hidden">
          {/* MODE 1: INTERACTIVE WHITEBOARD */}
          {classroomMode === 'whiteboard' && (
            <div className="flex-1 w-full h-full relative">
              <DigitalBoard isTeacher={isTeacher} />
            </div>
          )}

          {/* MODE 2: PRESENT MULTI-PAGE PRESENTATION DOCUMENT (PDF / PPT) */}
          {classroomMode === 'document' && (
            <div className={`flex-1 w-full h-full relative bg-slate-900 p-3 sm:p-4 overflow-auto transition-all duration-300 ${isDockHidden ? 'pb-16' : 'pb-24'}`}>
              <DocumentViewer
                document={currentPresentedDocument}
                onClose={() => setClassroomMode('whiteboard')}
              />
            </div>
          )}

          {/* MODE 3: LIVE SCREEN SHARE (BROWSER TAB / GOOGLE SEARCH PRESENTATION) */}
          {classroomMode === 'screenshare' && (
            <div className={`flex-1 w-full h-full relative bg-slate-950 p-2 sm:p-4 flex flex-col items-center justify-center overflow-hidden transition-all duration-300 ${isDockHidden ? 'pb-16' : 'pb-24'}`}>
              {/* Responsive Live Screen Share Banner (Avoids wrapping into a circular blob on mobile!) */}
              <div className="absolute top-2 sm:top-4 left-1/2 -translate-x-1/2 z-30 w-[95%] max-w-xl bg-slate-900/95 backdrop-blur-md border border-rose-500/60 text-white px-3 sm:px-4 py-2 rounded-xl sm:rounded-full shadow-2xl flex items-center justify-between gap-2">
                <div className="flex items-center space-x-2 truncate">
                  <span className="flex h-2.5 w-2.5 relative shrink-0">
                    <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-rose-400 opacity-75"></span>
                    <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-rose-500"></span>
                  </span>
                  <span className="text-[11px] sm:text-xs font-bold truncate">
                    Screen Share Active: {screenStream ? 'Live Window Feed' : 'Google / Physics Reference'}
                  </span>
                </div>
                <button
                  onClick={handleToggleScreenShare}
                  className="shrink-0 bg-rose-600 hover:bg-rose-500 text-white px-3 py-1 rounded-lg text-xs font-extrabold transition-all shadow-sm active:scale-95"
                >
                  Stop Sharing
                </button>
              </div>

              {screenStream ? (
                <video
                  ref={screenVideoRef}
                  autoPlay
                  playsInline
                  className="w-full h-full object-contain rounded-xl sm:rounded-2xl border border-slate-800 shadow-2xl bg-black"
                />
              ) : (
                /* Interactive Educational Browser Window View */
                <div className="w-full h-full max-w-5xl bg-white border border-slate-300 rounded-2xl shadow-2xl overflow-hidden flex flex-col my-auto text-slate-900">
                  {/* Browser Window Header & Tabs */}
                  <div className="bg-slate-100 px-3 sm:px-4 pt-2 border-b border-slate-300">
                    <div className="flex items-center justify-between pb-2">
                      <div className="flex items-center space-x-2">
                        <div className="w-3 h-3 rounded-full bg-rose-500" />
                        <div className="w-3 h-3 rounded-full bg-amber-500" />
                        <div className="w-3 h-3 rounded-full bg-emerald-500" />
                        <span className="text-xs font-semibold text-slate-500 hidden sm:inline ml-2">Classora Screen Presenter</span>
                      </div>
                      <span className="text-[10px] sm:text-[11px] font-bold text-indigo-700 bg-indigo-50 border border-indigo-200 px-2 py-0.5 rounded-full">
                        Shared Browser Window
                      </span>
                    </div>

                    {/* Browser Tabs */}
                    <div className="flex items-center space-x-1 sm:space-x-2 overflow-x-auto no-scrollbar">
                      <button
                        onClick={() => setScreenShareTab('google')}
                        className={`px-3 py-1.5 rounded-t-lg text-xs font-bold transition-colors whitespace-nowrap flex items-center space-x-1.5 ${
                          screenShareTab === 'google'
                            ? 'bg-white text-indigo-600 border-t-2 border-indigo-600 shadow-xs'
                            : 'text-slate-600 hover:bg-slate-200'
                        }`}
                      >
                        <span>Google Search</span>
                      </button>
                      <button
                        onClick={() => setScreenShareTab('wiki')}
                        className={`px-3 py-1.5 rounded-t-lg text-xs font-bold transition-colors whitespace-nowrap flex items-center space-x-1.5 ${
                          screenShareTab === 'wiki'
                            ? 'bg-white text-indigo-600 border-t-2 border-indigo-600 shadow-xs'
                            : 'text-slate-600 hover:bg-slate-200'
                        }`}
                      >
                        <span>Wikipedia Reference</span>
                      </button>
                      <button
                        onClick={() => setScreenShareTab('simulation')}
                        className={`px-3 py-1.5 rounded-t-lg text-xs font-bold transition-colors whitespace-nowrap flex items-center space-x-1.5 ${
                          screenShareTab === 'simulation'
                            ? 'bg-white text-indigo-600 border-t-2 border-indigo-600 shadow-xs'
                            : 'text-slate-600 hover:bg-slate-200'
                        }`}
                      >
                        <span>Physics Simulation</span>
                      </button>
                    </div>
                  </div>

                  {/* Address Bar */}
                  <div className="bg-white px-3 sm:px-4 py-1.5 border-b border-slate-200 flex items-center space-x-2 text-xs">
                    <span className="text-emerald-600 font-mono text-[11px]">🔒 https://</span>
                    <span className="text-slate-700 font-mono text-[11px] truncate flex-1">
                      {screenShareTab === 'google' && 'www.google.com/search?q=rotational+dynamics+physics+jee'}
                      {screenShareTab === 'wiki' && 'en.wikipedia.org/wiki/Rotational_dynamics'}
                      {screenShareTab === 'simulation' && 'phet.colorado.edu/sims/html/torque-rotation/latest/'}
                    </span>
                  </div>

                  {/* Browser Page Body */}
                  <div className="flex-1 bg-slate-50 p-4 sm:p-6 overflow-y-auto">
                    {screenShareTab === 'google' && (
                      <div className="max-w-2xl mx-auto space-y-4">
                        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-xs flex items-center space-x-3">
                          <span className="text-xl sm:text-2xl font-black text-indigo-600">Google</span>
                          <div className="flex-1 bg-slate-100 border border-slate-200 rounded-full px-4 py-2 text-xs text-slate-800 font-medium truncate">
                            rotational dynamics & torque formulas JEE Advanced
                          </div>
                        </div>

                        <div className="bg-white p-4 sm:p-5 rounded-xl border border-slate-200 shadow-xs space-y-3">
                          <div>
                            <span className="text-[11px] text-slate-500">https://en.wikipedia.org › wiki › Rotational_dynamics</span>
                            <h3 className="text-sm sm:text-base font-bold text-indigo-700 hover:underline cursor-pointer">
                              Rotational Dynamics & Moment of Inertia - Complete Reference
                            </h3>
                            <p className="text-xs text-slate-600 leading-relaxed mt-1">
                              Rotational dynamics analyzes angular velocity (ω), angular acceleration (α), and torque (τ = Iα). When a rigid body rotates about an axis, each particle experiences angular momentum L = Iω.
                            </p>
                          </div>

                          <div className="p-3 bg-indigo-50/70 border border-indigo-100 rounded-lg flex items-center justify-between">
                            <span className="text-xs font-bold text-indigo-900">Key Formula: τ = dL/dt = I · α</span>
                            <span className="text-[10px] font-bold text-indigo-600 bg-white px-2 py-0.5 rounded shadow-xs">Host Highlighting</span>
                          </div>
                        </div>

                        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-xs space-y-2">
                          <span className="text-[11px] text-slate-500">https://physics.stackexchange.com › questions</span>
                          <h4 className="text-xs sm:text-sm font-bold text-indigo-700 hover:underline">
                            Why does static friction do no work in pure rolling motion?
                          </h4>
                          <p className="text-xs text-slate-600 leading-relaxed">
                            In pure rolling, the point of contact between the wheel and surface is instantaneously at rest relative to the ground. Because the displacement at the contact point is zero (ds = 0), work done dW = F · ds = 0.
                          </p>
                        </div>
                      </div>
                    )}

                    {screenShareTab === 'wiki' && (
                      <div className="max-w-2xl mx-auto bg-white p-5 sm:p-6 rounded-xl border border-slate-200 shadow-xs space-y-4">
                        <div className="border-b border-slate-200 pb-3">
                          <h2 className="text-lg font-bold text-slate-900">Angular Momentum & Conservation Laws</h2>
                          <p className="text-xs text-slate-500">From Wikipedia, the free educational encyclopedia</p>
                        </div>
                        <p className="text-xs text-slate-700 leading-relaxed">
                          In physics, angular momentum is the rotational equivalent of linear momentum. It is a conserved quantity — the total angular momentum of a closed system remains constant unless acted upon by an external net torque.
                        </p>
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
                          <div className="p-3 bg-slate-50 rounded-lg border border-slate-200">
                            <p className="font-bold text-slate-800">Point Mass</p>
                            <p className="text-slate-600 mt-0.5">L = r × p = m(r × v)</p>
                          </div>
                          <div className="p-3 bg-slate-50 rounded-lg border border-slate-200">
                            <p className="font-bold text-slate-800">Rigid Body</p>
                            <p className="text-slate-600 mt-0.5">L = I · ω</p>
                          </div>
                        </div>
                      </div>
                    )}

                    {screenShareTab === 'simulation' && (
                      <div className="max-w-2xl mx-auto bg-white p-6 rounded-xl border border-slate-200 shadow-xs text-center space-y-4">
                        <div className="w-16 h-16 mx-auto rounded-2xl bg-indigo-50 border border-indigo-200 flex items-center justify-center text-indigo-600 font-black text-2xl">
                          ⚙️
                        </div>
                        <div>
                          <h3 className="text-base font-bold text-slate-900">Interactive Torque & Rotation Simulation</h3>
                          <p className="text-xs text-slate-600 mt-1 max-w-md mx-auto">
                            Investigate how torque causes an object to rotate. Adjust applied force, moment of inertia, and examine the resulting angular acceleration.
                          </p>
                        </div>
                        <div className="p-4 bg-slate-900 text-white rounded-xl flex items-center justify-around text-xs">
                          <div>
                            <span className="text-slate-400 block text-[10px]">Applied Torque</span>
                            <span className="text-emerald-400 font-mono font-bold text-sm">12.5 N·m</span>
                          </div>
                          <div>
                            <span className="text-slate-400 block text-[10px]">Moment of Inertia</span>
                            <span className="text-amber-400 font-mono font-bold text-sm">2.4 kg·m²</span>
                          </div>
                          <div>
                            <span className="text-slate-400 block text-[10px]">Angular Accel</span>
                            <span className="text-indigo-400 font-mono font-bold text-sm">5.2 rad/s²</span>
                          </div>
                        </div>
                      </div>
                    )}
                  </div>
                </div>
              )}
            </div>
          )}

          {/* ==================== FLOATING VIDEO PiP TILE (BOTTOM RIGHT) ==================== */}
          <div className="absolute bottom-18 sm:bottom-20 right-3 sm:right-6 z-30 flex flex-col items-end space-y-2 pointer-events-auto">
            {/* Student Self-Preview Mini-Tile (Visible when student has camera ON) */}
            {!isTeacher && camOn && (
              <div className="w-28 sm:w-32 aspect-video bg-slate-950 rounded-xl border-2 border-indigo-500 shadow-xl overflow-hidden relative group">
                {mediaStream ? (
                  <video
                    ref={liveVideoRef}
                    autoPlay
                    playsInline
                    muted
                    onLoadedMetadata={(e) => (e.target as HTMLVideoElement).play().catch(() => {})}
                    className="w-full h-full object-cover scale-x-[-1]"
                  />
                ) : (
                  <div className="w-full h-full flex flex-col items-center justify-center bg-slate-800 text-slate-300 text-[10px] font-bold">
                    <span>You (Student)</span>
                  </div>
                )}
                <div className="absolute bottom-1 left-1.5 bg-slate-900/90 text-white text-[9px] font-bold px-1.5 py-0.2 rounded">
                  You
                </div>
              </div>
            )}

            {/* Main Instructor / Self Video Tile */}
            <div className="w-38 sm:w-48 aspect-video bg-slate-900 rounded-xl sm:rounded-2xl border-2 border-emerald-500 shadow-2xl overflow-hidden relative">
              {isTeacher ? (
                /* TEACHER VIEW: Teacher's own camera */
                camOn ? (
                  mediaStream ? (
                    <video
                      ref={liveVideoRef}
                      autoPlay
                      playsInline
                      muted
                      onLoadedMetadata={(e) => (e.target as HTMLVideoElement).play().catch(() => {})}
                      className="w-full h-full object-cover scale-x-[-1]"
                    />
                  ) : (
                    <img
                      src="https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300&h=200&fit=crop"
                      alt="Teacher Feed"
                      className="w-full h-full object-cover"
                    />
                  )
                ) : (
                  <div className="w-full h-full flex flex-col items-center justify-center text-slate-500 p-2 text-center bg-slate-950">
                    <VideoOff className="w-5 h-5 mb-1 text-rose-500" />
                    <span className="text-[10px] font-bold text-slate-400">Camera Off</span>
                  </div>
                )
              ) : (
                /* STUDENT VIEW: Prof. Rajesh Sharma (Live Instructor Feed) */
                <div className="w-full h-full relative bg-slate-950">
                  <img
                    src="https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&h=250&fit=crop"
                    alt="Prof. Rajesh Sharma"
                    className="w-full h-full object-cover"
                  />
                  {/* Active speaking badge */}
                  <div className="absolute top-1.5 right-1.5 flex items-center space-x-1 bg-emerald-500/90 text-white text-[9px] font-bold px-1.5 py-0.5 rounded-full shadow-sm">
                    <span className="w-1.5 h-1.5 rounded-full bg-white animate-ping" />
                    <span>Live</span>
                  </div>
                </div>
              )}

              {/* Presenter Name Badge */}
              <div className="absolute bottom-1.5 left-2 bg-slate-900/85 backdrop-blur-xs text-white text-[10px] font-bold px-2 py-0.5 rounded-md flex items-center space-x-1">
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
                <span className="truncate max-w-[100px] sm:max-w-[140px]">
                  {isTeacher ? 'Prof. Sharma (You)' : 'Prof. Sharma (Host)'}
                </span>
              </div>

              {/* Mic Icon */}
              <div className="absolute top-1.5 left-1.5 p-1 bg-slate-900/80 rounded-md">
                <Mic className="w-3 h-3 text-emerald-400" />
              </div>
            </div>
          </div>

          {/* ==================== ZOOM / MEET BOTTOM CONTROL DOCK BAR ==================== */}
          {!isDockHidden ? (
            <div className="absolute bottom-3 sm:bottom-4 left-0 right-0 sm:left-1/2 sm:-translate-x-1/2 z-40 flex justify-center px-2 pointer-events-none transition-all duration-300">
              <div className="pointer-events-auto bg-slate-900/95 backdrop-blur-xl border border-slate-800 shadow-2xl rounded-2xl px-2 sm:px-4 py-2 sm:py-2.5 flex items-center space-x-1.5 sm:space-x-2.5 text-slate-200 max-w-[98vw] sm:max-w-none overflow-x-auto no-scrollbar">
                {/* Mic Control */}
                <button
                  onClick={() => setMicOn(!micOn)}
                  className={`shrink-0 flex flex-col items-center p-2 rounded-xl border transition-all ${
                    micOn
                      ? 'bg-slate-800 hover:bg-slate-700 text-slate-100 border-slate-700'
                      : 'bg-rose-600/20 text-rose-400 border-rose-500/40 hover:bg-rose-600/30'
                  }`}
                  title={micOn ? 'Mute Microphone' : 'Unmute Microphone'}
                >
                  {micOn ? <Mic className="w-4 h-4 text-emerald-400" /> : <MicOff className="w-4 h-4 text-rose-500" />}
                  <span className="text-[10px] font-semibold mt-1">{micOn ? 'Mute' : 'Unmute'}</span>
                </button>

                {/* Camera Control */}
                <button
                  onClick={() => setCamOn(!camOn)}
                  className={`shrink-0 flex flex-col items-center p-2 rounded-xl border transition-all ${
                    camOn
                      ? 'bg-slate-800 hover:bg-slate-700 text-slate-100 border-slate-700'
                      : 'bg-rose-600/20 text-rose-400 border-rose-500/40 hover:bg-rose-600/30'
                  }`}
                  title={camOn ? 'Stop Camera Video' : 'Start Camera Video'}
                >
                  {camOn ? <Video className="w-4 h-4 text-emerald-400" /> : <VideoOff className="w-4 h-4 text-rose-500" />}
                  <span className="text-[10px] font-semibold mt-1">{camOn ? 'Stop Video' : 'Start Video'}</span>
                </button>

                <div className="shrink-0 h-6 w-px bg-slate-800" />

                {/* TEACHER ONLY PRESENTER CONTROLS */}
                {isTeacher && (
                  <>
                    {/* Whiteboard Switcher Button */}
                    <button
                      onClick={() => setClassroomMode('whiteboard')}
                      className={`shrink-0 flex flex-col items-center p-2 rounded-xl border transition-all ${
                        classroomMode === 'whiteboard'
                          ? 'bg-indigo-600 text-white border-indigo-500 font-bold shadow-sm'
                          : 'bg-slate-800 hover:bg-slate-700 text-slate-200 border-slate-700'
                      }`}
                      title="Interactive Whiteboard"
                    >
                      <Share2 className="w-4 h-4" />
                      <span className="text-[10px] font-semibold mt-1">Whiteboard</span>
                    </button>

                    {/* SCREEN SHARE BUTTON (TEACHER SCREEN / BROWSER TAB SHARE) */}
                    <button
                      onClick={handleToggleScreenShare}
                      className={`shrink-0 flex flex-col items-center p-2 rounded-xl border transition-all ${
                        isScreenSharing || classroomMode === 'screenshare'
                          ? 'bg-emerald-600 text-white border-emerald-500 font-bold shadow-lg animate-pulse'
                          : 'bg-slate-800 hover:bg-slate-700 text-slate-200 border-slate-700'
                      }`}
                      title="Share Screen or Browser Tab (Google search, etc.)"
                    >
                      <Monitor className="w-4 h-4 text-emerald-400" />
                      <span className="text-[10px] font-bold mt-1">
                        {isScreenSharing ? 'Sharing' : 'Screen Share'}
                      </span>
                    </button>

                    {/* OPEN SYSTEM PDF / PPT FILE BUTTON */}
                    <button
                      onClick={() => fileInputRef.current?.click()}
                      className={`shrink-0 flex flex-col items-center p-2 rounded-xl border transition-all ${
                        classroomMode === 'document'
                          ? 'bg-amber-500 text-slate-950 border-amber-400 font-bold shadow-md'
                          : 'bg-slate-800 hover:bg-slate-700 text-slate-200 border-slate-700'
                      }`}
                      title="Open PDF or PPT File from System"
                    >
                      <FolderOpen className="w-4 h-4 text-amber-400" />
                      <span className="text-[10px] font-bold mt-1">Present Material</span>
                    </button>

                    <div className="shrink-0 h-6 w-px bg-slate-800" />
                  </>
                )}

                {/* Student Raise Hand Toggle */}
                {!isTeacher && (
                  <button
                    onClick={() => setHandRaised(!handRaised)}
                    className={`shrink-0 flex flex-col items-center p-2 rounded-xl border transition-all ${
                      handRaised
                        ? 'bg-amber-500/20 text-amber-300 border-amber-500/40 animate-pulse'
                        : 'bg-slate-800 hover:bg-slate-700 text-slate-200 border-slate-700'
                    }`}
                    title="Raise Hand"
                  >
                    <Hand className="w-4 h-4" />
                    <span className="text-[10px] font-semibold mt-1">{handRaised ? 'Lower Hand' : 'Raise Hand'}</span>
                  </button>
                )}

                {/* Doubts / Q&A Button */}
                <button
                  onClick={() => setActivePanel(activePanel === 'doubts' ? null : 'doubts')}
                  className={`shrink-0 flex flex-col items-center p-2 rounded-xl border transition-all relative ${
                    activePanel === 'doubts'
                      ? 'bg-indigo-600 text-white border-indigo-500'
                      : 'bg-slate-800 hover:bg-slate-700 text-slate-200 border-slate-700'
                  }`}
                  title="Q&A Doubts Queue"
                >
                  <HelpCircle className="w-4 h-4" />
                  <span className="text-[10px] font-semibold mt-1">Q&A Doubts</span>
                  {doubts.filter((d) => d.status === 'pending').length > 0 && (
                    <span className="absolute -top-1 -right-1 w-4 h-4 rounded-full bg-rose-500 text-white text-[10px] font-bold flex items-center justify-center">
                      {doubts.filter((d) => d.status === 'pending').length}
                    </span>
                  )}
                </button>

                {/* Participants Roster Button */}
                <button
                  onClick={() => setActivePanel(activePanel === 'roster' ? null : 'roster')}
                  className={`shrink-0 flex flex-col items-center p-2 rounded-xl border transition-all relative ${
                    activePanel === 'roster'
                      ? 'bg-indigo-600 text-white border-indigo-500'
                      : 'bg-slate-800 hover:bg-slate-700 text-slate-200 border-slate-700'
                  }`}
                  title="Participants Roster"
                >
                  <Users className="w-4 h-4" />
                  <span className="text-[10px] font-semibold mt-1">People (34)</span>
                </button>

                {/* In-Call Chat Button */}
                <button
                  onClick={() => setActivePanel(activePanel === 'chat' ? null : 'chat')}
                  className={`shrink-0 flex flex-col items-center p-2 rounded-xl border transition-all relative ${
                    activePanel === 'chat'
                      ? 'bg-indigo-600 text-white border-indigo-500'
                      : 'bg-slate-800 hover:bg-slate-700 text-slate-200 border-slate-700'
                  }`}
                  title="In-Call Chat"
                >
                  <MessageSquare className="w-4 h-4" />
                  <span className="text-[10px] font-semibold mt-1">In-Call Chat</span>
                </button>

                <div className="shrink-0 h-6 w-px bg-slate-800" />

                {/* Leave / End Meeting Red Button */}
                <button
                  onClick={onExit}
                  className="shrink-0 flex items-center space-x-1 px-3 py-2.5 text-xs font-bold text-white bg-rose-600 hover:bg-rose-700 rounded-xl shadow-lg transition-colors active:scale-95"
                >
                  <PhoneOff className="w-4 h-4" />
                  <span>{isTeacher ? 'End Meeting' : 'Leave'}</span>
                </button>

                {/* Prominent Hide Toolbar Button */}
                <button
                  onClick={() => setIsDockHidden(true)}
                  className="shrink-0 flex flex-col items-center p-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 hover:text-white transition-colors border border-slate-700"
                  title="Hide Controls / Fullscreen View"
                >
                  <ChevronDown className="w-4 h-4" />
                  <span className="text-[10px] font-semibold mt-1">Hide</span>
                </button>
              </div>
            </div>
          ) : (
            /* MINIMIZED FLOATING PILL BUTTON TO SHOW MEETING DOCK */
            <button
              onClick={() => setIsDockHidden(false)}
              className="absolute bottom-3 left-1/2 -translate-x-1/2 z-50 bg-slate-900/95 hover:bg-slate-800 backdrop-blur-xl text-white border border-indigo-500/60 px-4 py-2 sm:px-5 sm:py-2.5 rounded-full shadow-2xl flex items-center space-x-2 text-xs font-bold transition-all hover:scale-105 active:scale-95 group"
              title="Click to expand meeting toolbar"
            >
              <ChevronUp className="w-4 h-4 text-indigo-400 group-hover:-translate-y-0.5 transition-transform" />
              <span>Show Toolbar</span>
              <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse ml-1" />
            </button>
          )}
        </div>

        {/* ==================== 1. FULL SCREEN PARTICIPANTS VIEW (Image & User Request) ==================== */}
        {activePanel === 'roster' && (
          <div
            {...panelTouchHandlers}
            className="fixed inset-0 z-50 bg-slate-950/75 backdrop-blur-sm flex flex-col items-center justify-center p-0 sm:p-6 animate-in fade-in duration-200"
          >
            <div className="w-full h-full sm:max-w-4xl sm:max-h-[92vh] bg-white sm:rounded-3xl shadow-2xl flex flex-col overflow-hidden border border-slate-200">
              {/* Full Screen Header (With Safe-Area clearance for punch-hole / notch) */}
              <div className="pt-8 pb-3 sm:py-0 sm:h-16 border-b border-slate-200 px-4 sm:px-6 flex items-center justify-between shrink-0 bg-white">
                <div className="flex items-center space-x-3">
                  <button
                    onClick={() => setActivePanel(null)}
                    className="p-2 -ml-1 rounded-xl hover:bg-slate-100 text-slate-700 hover:text-slate-900 transition-colors flex items-center space-x-1.5"
                    title="Back to Whiteboard"
                  >
                    <ArrowLeft className="w-5 h-5 text-indigo-600" />
                    <span className="text-xs font-bold sm:hidden">Back</span>
                  </button>

                  <div className="flex items-center space-x-2.5">
                    <div className="w-10 h-10 rounded-2xl bg-indigo-50 text-indigo-600 flex items-center justify-center font-bold border border-indigo-100 shadow-xs">
                      <Users className="w-5 h-5" />
                    </div>
                    <div>
                      <div className="flex items-center space-x-2">
                        <h2 className="text-sm sm:text-base font-bold text-slate-900">
                          Class Participants ({participantsList.length})
                        </h2>
                        <span className="w-2.5 h-2.5 rounded-full bg-emerald-500 animate-pulse" />
                      </div>
                      <p className="text-[11px] text-slate-500 hidden sm:block">
                        Active JEE/NEET Batch • Realtime Audio/Video Synced
                      </p>
                    </div>
                  </div>
                </div>

                <div className="flex items-center space-x-2">
                  {isTeacher && (
                    <button
                      onClick={handleMuteAll}
                      className="flex items-center space-x-1.5 px-3 py-1.5 bg-rose-50 text-rose-700 hover:bg-rose-100 border border-rose-200 rounded-xl text-xs font-bold transition-all active:scale-95 shadow-xs"
                      title="Mute all student microphones"
                    >
                      <VolumeX className="w-4 h-4 text-rose-600" />
                      <span>Mute All</span>
                    </button>
                  )}
                  <button
                    onClick={() => setActivePanel(null)}
                    className="p-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-600 hover:text-slate-900 transition-colors"
                    title="Close Participants"
                  >
                    <X className="w-5 h-5" />
                  </button>
                </div>
              </div>

              {/* Search & Filter Bar */}
              <div className="p-3 sm:p-4 bg-slate-50 border-b border-slate-200 flex flex-col sm:flex-row gap-2.5 items-stretch sm:items-center justify-between">
                <div className="relative flex-1">
                  <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
                  <input
                    type="text"
                    value={rosterSearch}
                    onChange={(e) => setRosterSearch(e.target.value)}
                    placeholder="Search participant by name or roll number..."
                    className="w-full text-xs pl-9 pr-4 py-2 bg-white border border-slate-300 rounded-xl text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-indigo-600 focus:border-indigo-600 shadow-xs"
                  />
                </div>

                <div className="flex items-center space-x-1.5 overflow-x-auto no-scrollbar shrink-0">
                  <button
                    onClick={() => setRosterFilter('all')}
                    className={`px-3 py-1.5 rounded-xl text-xs font-bold transition-colors whitespace-nowrap ${
                      rosterFilter === 'all'
                        ? 'bg-indigo-600 text-white shadow-xs'
                        : 'bg-white text-slate-700 border border-slate-200 hover:bg-slate-100'
                    }`}
                  >
                    All ({participantsList.length})
                  </button>
                  <button
                    onClick={() => setRosterFilter('hands')}
                    className={`px-3 py-1.5 rounded-xl text-xs font-bold transition-colors whitespace-nowrap flex items-center space-x-1 ${
                      rosterFilter === 'hands'
                        ? 'bg-amber-500 text-white shadow-xs'
                        : 'bg-white text-slate-700 border border-slate-200 hover:bg-slate-100'
                    }`}
                  >
                    <span>✋ Hands Raised</span>
                    <span className="ml-1 px-1.5 py-0.2 rounded-full text-[10px] bg-amber-100 text-amber-800">
                      {participantsList.filter((p) => p.status === 'Hand Raised').length}
                    </span>
                  </button>
                  <button
                    onClick={() => setRosterFilter('teachers')}
                    className={`px-3 py-1.5 rounded-xl text-xs font-bold transition-colors whitespace-nowrap ${
                      rosterFilter === 'teachers'
                        ? 'bg-indigo-600 text-white shadow-xs'
                        : 'bg-white text-slate-700 border border-slate-200 hover:bg-slate-100'
                    }`}
                  >
                    Faculty (1)
                  </button>
                </div>
              </div>

              {/* Full Screen Participants Scroll Grid */}
              <div className="flex-1 p-3 sm:p-5 overflow-y-auto bg-slate-50/50">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-2.5">
                  {filteredParticipants.map((p) => {
                    const isSelf = p.name.includes(userName) || (isTeacher && p.role === 'teacher');
                    return (
                      <div
                        key={p.id}
                        className={`p-3 sm:p-3.5 rounded-2xl border transition-all flex items-center justify-between shadow-xs ${
                          p.role === 'teacher'
                            ? 'bg-indigo-50/70 border-indigo-200'
                            : p.status === 'Hand Raised'
                            ? 'bg-amber-50/80 border-amber-300 ring-1 ring-amber-300'
                            : 'bg-white border-slate-200/90 hover:border-slate-300'
                        }`}
                      >
                        <div className="flex items-center space-x-3 truncate">
                          <div
                            className={`w-10 h-10 rounded-2xl flex items-center justify-center font-black text-sm shrink-0 border shadow-xs ${
                              p.role === 'teacher'
                                ? 'bg-indigo-600 text-white border-indigo-700'
                                : p.status === 'Hand Raised'
                                ? 'bg-amber-500 text-white border-amber-600'
                                : 'bg-slate-100 text-slate-700 border-slate-200'
                            }`}
                          >
                            {p.name.charAt(0)}
                          </div>

                          <div className="truncate">
                            <div className="flex items-center space-x-1.5 truncate">
                              <span className="font-bold text-xs sm:text-sm text-slate-900 truncate">
                                {p.name}
                              </span>
                              {isSelf && (
                                <span className="bg-slate-200 text-slate-700 text-[9px] font-extrabold px-1.5 py-0.2 rounded">
                                  You
                                </span>
                              )}
                              {p.role === 'teacher' && (
                                <span className="bg-indigo-600 text-white text-[9px] font-extrabold px-1.5 py-0.2 rounded flex items-center space-x-0.5">
                                  <ShieldCheck className="w-2.5 h-2.5" />
                                  <span>Host</span>
                                </span>
                              )}
                            </div>
                            <div className="flex items-center space-x-2 text-[11px] text-slate-500 mt-0.5">
                              <span className="font-mono">{p.rollNo}</span>
                              <span>•</span>
                              <span className="capitalize">{p.role}</span>
                            </div>
                          </div>
                        </div>

                        {/* Status badges & Controls */}
                        <div className="flex items-center space-x-2 shrink-0">
                          {p.status === 'Hand Raised' && (
                            <div className="flex items-center space-x-1">
                              <span className="px-2 py-0.5 rounded-full bg-amber-100 text-amber-800 text-[10px] font-bold border border-amber-300 flex items-center space-x-1 animate-pulse">
                                <Hand className="w-3 h-3 text-amber-600" />
                                <span>Hand</span>
                              </span>
                              {isTeacher && (
                                <button
                                  onClick={() => handleLowerParticipantHand(p.id)}
                                  className="text-[10px] font-bold text-indigo-600 hover:text-indigo-800 underline ml-1"
                                >
                                  Lower
                                </button>
                              )}
                            </div>
                          )}

                          {/* Mic indicator / toggle */}
                          <button
                            onClick={() => isTeacher && p.role === 'student' && handleToggleParticipantMic(p.id)}
                            disabled={!isTeacher || p.role === 'teacher'}
                            className={`p-1.5 rounded-xl border transition-all ${
                              p.mic
                                ? 'bg-emerald-50 text-emerald-600 border-emerald-200 hover:bg-emerald-100'
                                : 'bg-slate-100 text-slate-400 border-slate-200'
                            }`}
                            title={isTeacher && p.role === 'student' ? 'Click to toggle mic' : undefined}
                          >
                            {p.mic ? <Mic className="w-3.5 h-3.5" /> : <MicOff className="w-3.5 h-3.5 text-rose-500" />}
                          </button>

                          {/* Video indicator */}
                          <div
                            className={`p-1.5 rounded-xl border ${
                              p.video
                                ? 'bg-indigo-50 text-indigo-600 border-indigo-200'
                                : 'bg-slate-100 text-slate-400 border-slate-200'
                            }`}
                          >
                            {p.video ? <Video className="w-3.5 h-3.5" /> : <VideoOff className="w-3.5 h-3.5 text-slate-400" />}
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>
          </div>
        )}

        {/* ==================== 2. CHAT & DOUBTS DRAWER (FULL SCREEN ON MOBILE, SLIDE-OVER ON DESKTOP) ==================== */}
        {activePanel && activePanel !== 'roster' && (
          <div
            {...panelTouchHandlers}
            className="fixed inset-0 sm:relative sm:inset-auto w-full sm:w-96 z-50 bg-white border-l border-slate-200 flex flex-col shadow-2xl text-slate-900 animate-in slide-in-from-right duration-200"
          >
            {/* Header with Safe-Area clearance */}
            <div className="pt-8 pb-3 sm:py-0 sm:h-14 border-b border-slate-200 px-4 flex items-center justify-between shrink-0 bg-white shadow-xs">
              <div className="flex items-center space-x-2.5 text-sm font-bold text-slate-900">
                {activePanel === 'chat' && (
                  <div className="w-7 h-7 rounded-lg bg-indigo-50 text-indigo-600 flex items-center justify-center">
                    <MessageSquare className="w-4 h-4" />
                  </div>
                )}
                {activePanel === 'doubts' && (
                  <div className="w-7 h-7 rounded-lg bg-amber-50 text-amber-600 flex items-center justify-center">
                    <HelpCircle className="w-4 h-4" />
                  </div>
                )}
                <span>
                  {activePanel === 'chat' ? 'In-Call Messages' : 'Student Q&A Doubts'}
                </span>
              </div>
              <button
                onClick={() => setActivePanel(null)}
                className="text-xs font-semibold text-slate-600 hover:text-slate-900 px-3 py-1.5 rounded-lg bg-slate-100 hover:bg-slate-200 transition-colors"
              >
                Close
              </button>
            </div>

            {/* In-Call Chat */}
            {activePanel === 'chat' && (
              <div className="flex-1 flex flex-col h-full overflow-hidden bg-slate-50/60">
                <div className="flex-1 p-4 overflow-y-auto space-y-3.5">
                  {chatMessages.map((msg) => {
                    const isSelf = msg.sender === userName;
                    return (
                      <div
                        key={msg.id}
                        className={`flex flex-col text-xs ${isSelf ? 'items-end' : 'items-start'}`}
                      >
                        <div className="flex items-center space-x-1.5 mb-1 px-1">
                          <span className="font-bold text-slate-800">{msg.sender}</span>
                          {msg.role === 'teacher' && (
                            <span className="bg-indigo-100 text-indigo-700 text-[9px] font-extrabold px-1.5 py-0.5 rounded border border-indigo-200">
                              Host
                            </span>
                          )}
                          <span className="text-[10px] text-slate-400">{msg.timestamp}</span>
                        </div>
                        <div
                          className={`p-3 rounded-2xl max-w-[85%] leading-relaxed ${
                            isSelf
                              ? 'bg-indigo-600 text-white rounded-br-xs shadow-sm font-medium'
                              : 'bg-white text-slate-800 rounded-bl-xs border border-slate-200/90 shadow-xs'
                          }`}
                        >
                          {msg.message}
                        </div>
                      </div>
                    );
                  })}
                </div>

                {/* Quick Reaction Chips */}
                <div className="px-3 pt-2 bg-white flex items-center space-x-2 overflow-x-auto no-scrollbar border-t border-slate-100">
                  <span className="text-[10px] text-slate-400 font-semibold shrink-0">Quick React:</span>
                  {['👍', '👏', '❤️', '💡', '🙋‍♂️', '🔥'].map((emoji) => (
                    <button
                      key={emoji}
                      onClick={() => handleQuickReaction(emoji)}
                      className="px-2 py-1 bg-slate-100 hover:bg-indigo-50 hover:border-indigo-300 border border-slate-200 rounded-lg text-xs transition-all active:scale-90"
                    >
                      {emoji}
                    </button>
                  ))}
                </div>

                {/* Message Input Bar */}
                <form onSubmit={handleSendChat} className="p-3 border-t border-slate-200 bg-white flex items-center space-x-2">
                  <input
                    type="text"
                    value={currentChatInput}
                    onChange={(e) => setCurrentChatInput(e.target.value)}
                    placeholder="Send a message to everyone..."
                    className="flex-1 text-xs px-3.5 py-2.5 bg-slate-50 border border-slate-300 rounded-xl text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-indigo-600 focus:bg-white transition-all shadow-xs"
                  />
                  <button
                    type="submit"
                    className="p-2.5 bg-indigo-600 text-white rounded-xl hover:bg-indigo-700 active:scale-95 transition-all shadow-sm"
                  >
                    <Send className="w-3.5 h-3.5" />
                  </button>
                </form>
              </div>
            )}

            {/* Student Q&A Doubts Queue */}
            {activePanel === 'doubts' && (
              <div className="flex-1 flex flex-col h-full overflow-hidden bg-slate-50/60">
                {!isTeacher && (
                  <form onSubmit={handleSubmitDoubt} className="p-4 border-b border-slate-200 bg-white shadow-xs">
                    <label className="block text-xs font-bold text-slate-800 mb-1.5">
                      Ask Doubt from Whiteboard
                    </label>
                    <textarea
                      value={newDoubtText}
                      onChange={(e) => setNewDoubtText(e.target.value)}
                      placeholder="Type your question for the teacher..."
                      rows={2}
                      className="w-full text-xs p-3 bg-slate-50 border border-slate-300 rounded-xl text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-indigo-600 focus:bg-white mb-2.5 resize-none transition-all shadow-xs"
                    />
                    <button
                      type="submit"
                      className="w-full py-2.5 text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-700 active:scale-[0.99] rounded-xl transition-all shadow-sm"
                    >
                      Submit to Teacher
                    </button>
                  </form>
                )}

                <div className="flex-1 p-4 overflow-y-auto space-y-3">
                  {doubts.map((d) => (
                    <div
                      key={d.id}
                      className="bg-white rounded-xl border border-slate-200/90 p-4 shadow-xs text-xs space-y-2.5"
                    >
                      <div className="flex items-center justify-between">
                        <span className="font-bold text-slate-900">{d.studentName}</span>
                        <span className="text-[10px] text-slate-400 font-medium">{d.timestamp}</span>
                      </div>
                      <p className="text-xs text-slate-700 leading-relaxed">{d.doubtText}</p>
                      <div className="flex items-center justify-between pt-2 border-t border-slate-100">
                        <span
                          className={`text-[10px] font-bold px-2.5 py-0.5 rounded-full border ${
                            d.status === 'resolved'
                              ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
                              : 'bg-amber-50 text-amber-700 border-amber-200'
                          }`}
                        >
                          {d.status === 'resolved' ? 'Resolved' : 'Pending Review'}
                        </span>
                        {isTeacher && d.status === 'pending' && (
                          <button
                            onClick={() => handleResolveDoubt(d.id)}
                            className="flex items-center space-x-1 text-xs font-bold text-indigo-600 hover:text-indigo-700 bg-indigo-50 hover:bg-indigo-100 px-2 py-1 rounded-lg border border-indigo-200 transition-colors"
                          >
                            <CheckCircle2 className="w-3.5 h-3.5" />
                            <span>Resolve Doubt</span>
                          </button>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
};
