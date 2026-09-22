import React, { useState, useEffect } from 'react';
import {
  BookOpen,
  Video,
  FileCheck,
  Award,
  CreditCard,
  Play,
  Download,
  Upload,
  CheckCircle2,
  ExternalLink,
  Timer,
  MessageSquare,
  ShieldCheck,
  Smartphone,
  Tablet,
  Laptop,
  LogOut,
  Layers,
  GraduationCap,
  Sparkles,
  Radio,
} from 'lucide-react';
import { StudentPreJoinModal } from '@shared/StudentPreJoinModal';
import { LiveClassroom } from '@shared/LiveClassroom';
import { LoginCard, LoggedInUser } from '@shared/LoginCard';

interface DemoStudent {
  id: string;
  name: string;
  email: string;
  avatarUrl: string;
  batchName: string;
  rollNumber: string;
}

const DEMO_STUDENTS: DemoStudent[] = [
  {
    id: 'usr-student-01',
    name: 'Aarav Patel',
    email: 'student@classora.com',
    avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120&h=120&fit=crop',
    batchName: 'Batch A — Class 12th IIT-JEE Masterclass',
    rollNumber: 'JEE-12-001',
  },
  {
    id: 'usr-student-02',
    name: 'Priya Sharma',
    email: 'priya@classora.com',
    avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=120&h=120&fit=crop',
    batchName: 'Batch B — Class 11th NEET Champions',
    rollNumber: 'NEET-11-001',
  },
  {
    id: 'usr-student-03',
    name: 'Rohan Verma',
    email: 'rohan@classora.com',
    avatarUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=120&h=120&fit=crop',
    batchName: 'Batch A (IIT-JEE) & Batch C (Foundation)',
    rollNumber: 'JEE-12-002',
  },
];

interface LiveClassItem {
  id: string;
  title: string;
  subject: string;
  chapter?: string;
  roomId: string;
  status: string;
  scheduledAt: string;
  batch?: {
    id: string;
    name: string;
  };
  teacher?: {
    name: string;
  };
}

export function App() {
  const [currentUser, setCurrentUser] = useState<LoggedInUser | null>({
    name: 'Aarav Patel',
    email: 'student@classora.com',
    role: 'student',
  });
  const [activeStudent, setActiveStudent] = useState<DemoStudent>(DEMO_STUDENTS[0]);
  const [activeTab, setActiveTab] = useState<'home' | 'courses' | 'recordings' | 'assignments' | 'tests' | 'fees'>('home');

  // DB Live classes filtered for this student's batch
  const [studentClasses, setStudentClasses] = useState<LiveClassItem[]>([]);
  const [selectedClassToJoin, setSelectedClassToJoin] = useState<LiveClassItem | null>(null);

  // Pre-join & Classroom state
  const [preJoinModalOpen, setPreJoinModalOpen] = useState(false);
  const [isInLiveClass, setIsInLiveClass] = useState(false);

  // Test state
  const [activeTest, setActiveTest] = useState(false);
  const [selectedAnswers, setSelectedAnswers] = useState<Record<number, string>>({});
  const [testSubmitted, setTestSubmitted] = useState(false);

  // Fee modal
  const [feeModalOpen, setFeeModalOpen] = useState(false);
  const [paymentSuccess, setPaymentSuccess] = useState(false);

  // Assignment upload
  const [asgSubmitted, setAsgSubmitted] = useState(false);

  // Load live classes for current student's batch
  const loadStudentClasses = async () => {
    try {
      const res = await fetch(`http://localhost:4000/api/v1/live-classes?studentId=${activeStudent.id}`);
      const data = await res.json();
      if (data.liveClasses) {
        setStudentClasses(data.liveClasses);
      }
    } catch (e) {
      console.error('Error fetching student live classes:', e);
    }
  };

  useEffect(() => {
    loadStudentClasses();
    const interval = setInterval(loadStudentClasses, 4000);
    return () => clearInterval(interval);
  }, [activeStudent]);

  const handleSwitchStudent = (st: DemoStudent) => {
    setActiveStudent(st);
    setCurrentUser({
      name: st.name,
      email: st.email,
      role: 'student',
    });
  };

  const handleLaunchJoin = (cls: LiveClassItem) => {
    setSelectedClassToJoin(cls);
    setPreJoinModalOpen(true);
  };

  const handleProceedJoin = (_mode: { enableCamera: boolean; enableMic: boolean }) => {
    setPreJoinModalOpen(false);
    setIsInLiveClass(true);
  };

  const activeClass = selectedClassToJoin || studentClasses[0] || {
    id: 'live-class-01',
    title: 'Electromagnetic Induction & Faraday’s Laws',
    subject: 'Physics',
    chapter: 'Electrodynamics — Unit 4',
    roomId: 'room-jee-101',
    status: 'LIVE',
    scheduledAt: new Date().toISOString(),
    batch: { id: 'batch-jee-12', name: activeStudent.batchName },
    teacher: { name: 'Prof. Rajesh Sharma' },
  };

  if (isInLiveClass) {
    return (
      <div className="h-screen flex flex-col bg-white">
        <header className="h-12 bg-white border-b border-slate-200 px-4 flex items-center justify-between shadow-subtle shrink-0">
          <div className="flex items-center space-x-2">
            <span className="w-2.5 h-2.5 rounded-full bg-rose-500 animate-ping" />
            <span className="text-xs font-black text-slate-900 tracking-wider uppercase">
              Attending Live &bull; {activeClass.title} ({activeClass.batch?.name || activeStudent.batchName})
            </span>
          </div>
          <button
            onClick={() => setIsInLiveClass(false)}
            className="text-xs font-bold text-rose-600 bg-rose-50 hover:bg-rose-100 px-3 py-1.5 rounded-xl border border-rose-200 transition-colors"
          >
            Leave Classroom
          </button>
        </header>
        <div className="flex-1 overflow-hidden">
          <LiveClassroom
            role="student"
            userName={activeStudent.name}
            classInfo={{
              id: activeClass.id,
              title: activeClass.title,
              subject: activeClass.subject,
              chapter: activeClass.chapter,
              batchName: activeClass.batch?.name || activeStudent.batchName,
              teacherName: activeClass.teacher?.name || 'Prof. Rajesh Sharma',
              roomId: activeClass.roomId,
            }}
            onExit={() => setIsInLiveClass(false)}
          />
        </div>
      </div>
    );
  }

  if (!currentUser) {
    return (
      <LoginCard
        role="student"
        portalName="Student Learning Portal"
        portNumber={3003}
        defaultEmail="student@classora.com"
        defaultName="Aarav Patel (Class 12th)"
        onLoginSuccess={(user) => {
          setCurrentUser(user);
          const matched = DEMO_STUDENTS.find((s) => s.email === user.email) || DEMO_STUDENTS[0];
          setActiveStudent(matched);
        }}
      />
    );
  }

  // Check if any class is currently live
  const activeLiveClass = studentClasses.find((c) => c.status === 'LIVE');

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 flex font-sans">
      {/* Sidebar - responsive */}
      <aside className="w-64 bg-white border-r border-slate-200 flex flex-col justify-between p-4 shadow-subtle shrink-0 hidden md:flex">
        <div>
          <div className="flex items-center space-x-3 pb-6 border-b border-slate-100">
            <img
              src={activeStudent.avatarUrl}
              alt="Student"
              className="w-10 h-10 rounded-full border border-slate-200 object-cover"
            />
            <div className="truncate">
              <h2 className="text-sm font-bold text-slate-900 truncate">{activeStudent.name}</h2>
              <span className="text-[10px] font-bold text-indigo-600 uppercase tracking-widest block truncate">
                Roll: {activeStudent.rollNumber}
              </span>
            </div>
          </div>

          <div className="mt-3 py-2 px-3 bg-indigo-50/70 rounded-xl border border-indigo-100">
            <p className="text-[10px] font-bold uppercase text-indigo-700">Enrolled Batch:</p>
            <p className="text-xs font-semibold text-slate-800 truncate mt-0.5">{activeStudent.batchName}</p>
          </div>

          <nav className="mt-5 space-y-1 text-xs font-semibold">
            <button
              onClick={() => setActiveTab('home')}
              className={`w-full flex items-center space-x-3 px-3 py-2.5 rounded-xl transition-colors ${
                activeTab === 'home' ? 'bg-indigo-50 text-indigo-700' : 'text-slate-600 hover:bg-slate-50'
              }`}
            >
              <BookOpen className="w-4 h-4" />
              <span>Today's Classes & Home</span>
            </button>

            <button
              onClick={() => setActiveTab('courses')}
              className={`w-full flex items-center space-x-3 px-3 py-2.5 rounded-xl transition-colors ${
                activeTab === 'courses' ? 'bg-indigo-50 text-indigo-700' : 'text-slate-600 hover:bg-slate-50'
              }`}
            >
              <Layers className="w-4 h-4" />
              <span>My Enrolled Courses</span>
            </button>

            <button
              onClick={() => setActiveTab('recordings')}
              className={`w-full flex items-center space-x-3 px-3 py-2.5 rounded-xl transition-colors ${
                activeTab === 'recordings' ? 'bg-indigo-50 text-indigo-700' : 'text-slate-600 hover:bg-slate-50'
              }`}
            >
              <Video className="w-4 h-4" />
              <span>Past Class Recordings</span>
            </button>

            <button
              onClick={() => setActiveTab('assignments')}
              className={`w-full flex items-center space-x-3 px-3 py-2.5 rounded-xl transition-colors ${
                activeTab === 'assignments' ? 'bg-indigo-50 text-indigo-700' : 'text-slate-600 hover:bg-slate-50'
              }`}
            >
              <FileCheck className="w-4 h-4" />
              <span>Assignments & PDF</span>
            </button>

            <button
              onClick={() => setActiveTab('tests')}
              className={`w-full flex items-center space-x-3 px-3 py-2.5 rounded-xl transition-colors ${
                activeTab === 'tests' ? 'bg-indigo-50 text-indigo-700' : 'text-slate-600 hover:bg-slate-50'
              }`}
            >
              <Award className="w-4 h-4" />
              <span>Mock Tests & Ranks</span>
            </button>

            <button
              onClick={() => setActiveTab('fees')}
              className={`w-full flex items-center space-x-3 px-3 py-2.5 rounded-xl transition-colors ${
                activeTab === 'fees' ? 'bg-indigo-50 text-indigo-700' : 'text-slate-600 hover:bg-slate-50'
              }`}
            >
              <CreditCard className="w-4 h-4" />
              <span>Fees & Invoices</span>
            </button>
          </nav>
        </div>

        {/* Live Device Readiness Badge */}
        <div className="bg-slate-100 p-3 rounded-2xl border border-slate-200 text-xs">
          <div className="flex items-center space-x-1.5 text-slate-800 font-bold mb-1">
            <Smartphone className="w-3.5 h-3.5 text-indigo-600" />
            <span>Device Optimized</span>
          </div>
          <p className="text-[11px] text-slate-500">
            Works across Android, iPhone, iPad, Windows, and Mac.
          </p>
        </div>
      </aside>

      {/* Main Area */}
      <main className="flex-1 flex flex-col h-screen overflow-y-auto">
        <header className="h-16 bg-white border-b border-slate-200 px-6 flex items-center justify-between shrink-0 shadow-subtle">
          <div>
            <h1 className="text-base font-extrabold text-slate-900">
              Student Learning Portal &bull; {activeStudent.name}
            </h1>
            <p className="text-xs text-slate-500">Apex IIT-JEE & Medical Academy &bull; app.classora.com (Port 3003)</p>
          </div>

          <div className="flex items-center space-x-3">
            {/* Student Switcher for Client Demo */}
            <div className="flex items-center space-x-1.5 bg-slate-100 p-1 rounded-xl border border-slate-200">
              <span className="text-[10px] font-bold text-slate-500 uppercase px-2">Demo Student:</span>
              {DEMO_STUDENTS.map((st) => (
                <button
                  key={st.id}
                  onClick={() => handleSwitchStudent(st)}
                  className={`px-2.5 py-1 text-xs font-bold rounded-lg transition-all ${
                    activeStudent.id === st.id
                      ? 'bg-indigo-600 text-white shadow-xs'
                      : 'text-slate-700 hover:bg-white'
                  }`}
                >
                  {st.name.split(' ')[0]}
                </button>
              ))}
            </div>

            <div className="h-6 w-px bg-slate-200" />

            <button
              onClick={() => setCurrentUser(null)}
              className="p-2 text-slate-400 hover:text-rose-600 hover:bg-rose-50 rounded-xl transition-colors"
              title="Sign Out"
            >
              <LogOut className="w-4 h-4" />
            </button>
          </div>
        </header>

        {/* Content Area */}
        <div className="p-6 space-y-6">
          {activeTab === 'home' && (
            <div className="space-y-6">
              {/* Pulsing Live Banner if class is LIVE right now */}
              {activeLiveClass && (
                <div className="bg-gradient-to-r from-rose-500 via-rose-600 to-indigo-600 rounded-2xl p-5 text-white shadow-elevated flex flex-col sm:flex-row items-center justify-between gap-4 animate-in fade-in duration-300">
                  <div className="flex items-center space-x-3">
                    <span className="relative flex h-4 w-4">
                      <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-white opacity-75"></span>
                      <span className="relative inline-flex rounded-full h-4 w-4 bg-white"></span>
                    </span>
                    <div>
                      <div className="flex items-center space-x-2">
                        <span className="px-2 py-0.5 bg-white/20 backdrop-blur-xs text-white text-[10px] font-black rounded uppercase tracking-wider">
                          Broadcast Live Now
                        </span>
                        <span className="text-xs text-rose-100 font-bold">
                          {activeLiveClass.batch?.name || activeStudent.batchName}
                        </span>
                      </div>
                      <h3 className="text-base font-extrabold mt-1">{activeLiveClass.title}</h3>
                      <p className="text-xs text-rose-100">
                        Faculty: {activeLiveClass.teacher?.name || 'Prof. Rajesh Sharma'} &bull; Digital Whiteboard & Real-Time Chat Ready
                      </p>
                    </div>
                  </div>

                  <button
                    onClick={() => handleLaunchJoin(activeLiveClass)}
                    className="px-5 py-2.5 bg-white text-rose-600 font-extrabold text-xs rounded-xl shadow-lg hover:bg-rose-50 flex items-center space-x-2 transition-all hover:scale-105 shrink-0"
                  >
                    <Play className="w-4 h-4 fill-current" />
                    <span>Join Live Classroom</span>
                  </button>
                </div>
              )}

              {/* Scheduled Classes for Student's Batch */}
              <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-5">
                <div className="flex items-center justify-between mb-4">
                  <div>
                    <h3 className="text-sm font-bold text-slate-900 flex items-center space-x-2">
                      <Timer className="w-4 h-4 text-indigo-600" />
                      <span>Classes Scheduled for Your Batch ({studentClasses.length})</span>
                    </h3>
                    <p className="text-xs text-slate-500 mt-0.5">
                      Only lectures for <strong className="text-indigo-600">{activeStudent.batchName}</strong> are displayed.
                    </p>
                  </div>
                </div>

                <div className="space-y-3">
                  {studentClasses.length === 0 ? (
                    <div className="text-center py-10 text-slate-400 text-xs">
                      No live classes currently scheduled for this batch. Switch student or have Teacher schedule a class on Port 3002.
                    </div>
                  ) : (
                    studentClasses.map((cls) => (
                      <div
                        key={cls.id}
                        className={`p-4 rounded-xl border flex flex-col sm:flex-row sm:items-center justify-between gap-4 transition-all ${
                          cls.status === 'LIVE'
                            ? 'bg-rose-50/60 border-rose-300 shadow-subtle'
                            : 'bg-slate-50/60 border-slate-200'
                        }`}
                      >
                        <div>
                          <div className="flex items-center space-x-2 mb-1">
                            <span
                              className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                                cls.status === 'LIVE'
                                  ? 'bg-rose-100 text-rose-800 animate-pulse'
                                  : 'bg-indigo-100 text-indigo-800'
                              }`}
                            >
                              {cls.status === 'LIVE' ? '🔴 LIVE NOW' : 'SCHEDULED'}
                            </span>
                            <span className="text-xs text-slate-700 font-bold">{cls.subject}</span>
                            <span className="text-xs text-slate-400">&bull; {cls.chapter || 'Unit 1'}</span>
                          </div>
                          <h4 className="text-sm font-bold text-slate-900">{cls.title}</h4>
                          <p className="text-xs text-slate-500">
                            Faculty: {cls.teacher?.name || 'Prof. Rajesh Sharma'} &bull; Scheduled:{' '}
                            {new Date(cls.scheduledAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}, Today
                          </p>
                        </div>

                        <button
                          onClick={() => handleLaunchJoin(cls)}
                          className={`px-4 py-2 text-xs font-bold rounded-xl shadow-xs flex items-center space-x-1.5 shrink-0 transition-all ${
                            cls.status === 'LIVE'
                              ? 'bg-rose-600 hover:bg-rose-700 text-white animate-bounce'
                              : 'bg-indigo-600 hover:bg-indigo-700 text-white'
                          }`}
                        >
                          <Play className="w-3.5 h-3.5 fill-current" />
                          <span>{cls.status === 'LIVE' ? 'Join Live Now' : 'Join Classroom'}</span>
                        </button>
                      </div>
                    ))
                  )}
                </div>
              </div>

              {/* Multi-Device Support Info Card */}
              <div className="bg-white rounded-2xl border border-slate-200 p-5 shadow-card">
                <h3 className="text-xs font-bold text-slate-500 uppercase tracking-wider mb-3">
                  Cross-Platform Multi-Device Architecture
                </h3>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div className="p-4 rounded-xl border border-slate-100 bg-slate-50 flex items-start space-x-3">
                    <Smartphone className="w-6 h-6 text-indigo-600 shrink-0 mt-0.5" />
                    <div>
                      <h4 className="text-xs font-bold text-slate-900">Mobile Phone View</h4>
                      <p className="text-[11px] text-slate-500 mt-1">
                        Touch stylus support, floating video overlay, and portrait live chat drawer.
                      </p>
                    </div>
                  </div>

                  <div className="p-4 rounded-xl border border-slate-100 bg-slate-50 flex items-start space-x-3">
                    <Tablet className="w-6 h-6 text-indigo-600 shrink-0 mt-0.5" />
                    <div>
                      <h4 className="text-xs font-bold text-slate-900">iPad & Android Tablets</h4>
                      <p className="text-[11px] text-slate-500 mt-1">
                        Full-screen interactive digital board with Apple Pencil and stylus palm rejection.
                      </p>
                    </div>
                  </div>

                  <div className="p-4 rounded-xl border border-slate-100 bg-slate-50 flex items-start space-x-3">
                    <Laptop className="w-6 h-6 text-indigo-600 shrink-0 mt-0.5" />
                    <div>
                      <h4 className="text-xs font-bold text-slate-900">Laptop & Web Browsers</h4>
                      <p className="text-[11px] text-slate-500 mt-1">
                        High-definition 1080p stream with side-by-side doubts, polls, and live board notes download.
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}

          {activeTab === 'courses' && (
            <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-5">
              <h3 className="text-sm font-bold text-slate-900 mb-1">My Enrolled Course & Syllabus</h3>
              <p className="text-xs text-slate-500 mb-4">{activeStudent.batchName}</p>
              <div className="p-4 rounded-xl border border-slate-100 bg-slate-50 space-y-2">
                <div className="flex justify-between items-center text-xs">
                  <span className="font-bold text-slate-800">Syllabus Completion Progress</span>
                  <span className="font-extrabold text-indigo-600">68%</span>
                </div>
                <div className="w-full bg-slate-200 h-2 rounded-full overflow-hidden">
                  <div className="bg-indigo-600 h-2 rounded-full" style={{ width: '68%' }} />
                </div>
              </div>
            </div>
          )}

          {activeTab === 'recordings' && (
            <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-5">
              <h3 className="text-sm font-bold text-slate-900 mb-1">Past Classroom Recordings</h3>
              <p className="text-xs text-slate-500 mb-4">Watch recorded sessions with synchronized lecture notes.</p>
              <div className="p-4 rounded-xl border border-slate-100 bg-slate-50 flex items-center justify-between">
                <div>
                  <h4 className="text-xs font-bold text-slate-800">Physics: Laws of Motion & Friction Analysis</h4>
                  <p className="text-[11px] text-slate-500">Duration: 1h 24m &bull; Recorded Yesterday</p>
                </div>
                <a
                  href="https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
                  target="_blank"
                  rel="noreferrer"
                  className="px-3 py-1.5 bg-indigo-600 text-white font-bold text-xs rounded-lg hover:bg-indigo-700 flex items-center space-x-1"
                >
                  <Play className="w-3.5 h-3.5 fill-current" />
                  <span>Watch Recording</span>
                </a>
              </div>
            </div>
          )}

          {activeTab === 'assignments' && (
            <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-5">
              <h3 className="text-sm font-bold text-slate-900 mb-1">Homework & Problem Sheets</h3>
              <p className="text-xs text-slate-500 mb-4">Upload handwritten notes or PDF solutions for grading.</p>
              <div className="p-4 rounded-xl border border-slate-100 bg-slate-50 flex items-center justify-between">
                <div>
                  <span className="text-[10px] font-bold text-indigo-700 bg-indigo-50 px-2 py-0.5 rounded">Due in 3 Days</span>
                  <h4 className="text-xs font-bold text-slate-800 mt-1">Electromagnetic Induction Problem Set 01</h4>
                  <p className="text-[11px] text-slate-500">Total Marks: 50 &bull; Submitted: {asgSubmitted ? 'Yes (Under Review)' : 'Pending'}</p>
                </div>
                {asgSubmitted ? (
                  <span className="inline-flex items-center text-xs font-bold text-emerald-600 bg-emerald-50 px-3 py-1.5 rounded-xl border border-emerald-200">
                    <CheckCircle2 className="w-4 h-4 mr-1" /> Submitted
                  </span>
                ) : (
                  <button
                    onClick={() => setAsgSubmitted(true)}
                    className="px-3.5 py-2 bg-indigo-600 text-white font-bold text-xs rounded-xl hover:bg-indigo-700 flex items-center space-x-1.5"
                  >
                    <Upload className="w-3.5 h-3.5" />
                    <span>Upload PDF Solution</span>
                  </button>
                )}
              </div>
            </div>
          )}

          {activeTab === 'tests' && (
            <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-5">
              <h3 className="text-sm font-bold text-slate-900 mb-1">Online CBT Mock Tests</h3>
              <p className="text-xs text-slate-500 mb-4">NTA-pattern testing engine with live timer and negative marking.</p>
              <div className="p-4 rounded-xl border border-slate-100 bg-slate-50 flex items-center justify-between">
                <div>
                  <span className="text-[10px] font-bold text-rose-700 bg-rose-50 px-2 py-0.5 rounded">Live Test Active</span>
                  <h4 className="text-xs font-bold text-slate-800 mt-1">Full Syllabus Physics Mock Test - 04</h4>
                  <p className="text-[11px] text-slate-500">30 Questions &bull; 180 Mins &bull; Total Marks: 120</p>
                </div>
                <button
                  onClick={() => setActiveTest(true)}
                  className="px-4 py-2 bg-indigo-600 text-white font-bold text-xs rounded-xl hover:bg-indigo-700"
                >
                  Start Test
                </button>
              </div>
            </div>
          )}

          {activeTab === 'fees' && (
            <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-5">
              <h3 className="text-sm font-bold text-slate-900 mb-1">Fee Installments & Receipts</h3>
              <p className="text-xs text-slate-500 mb-4">Institute billing records & Razorpay integration.</p>
              <div className="p-4 rounded-xl border border-slate-100 bg-slate-50 flex items-center justify-between">
                <div>
                  <span className="text-[10px] font-bold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded">Installment 1 of 3</span>
                  <h4 className="text-xs font-bold text-slate-800 mt-1">IIT-JEE Masterclass Annual Tuition Fee</h4>
                  <p className="text-[11px] text-slate-500">Amount: ₹25,000 &bull; Status: {paymentSuccess ? 'Paid' : 'Pending'}</p>
                </div>
                {paymentSuccess ? (
                  <span className="inline-flex items-center text-xs font-bold text-emerald-600 bg-emerald-50 px-3 py-1.5 rounded-xl border border-emerald-200">
                    <CheckCircle2 className="w-4 h-4 mr-1" /> Paid (Receipt #RZP-9821)
                  </span>
                ) : (
                  <button
                    onClick={() => setPaymentSuccess(true)}
                    className="px-4 py-2 bg-emerald-600 text-white font-bold text-xs rounded-xl hover:bg-emerald-700 shadow-xs"
                  >
                    Pay ₹25,000 Now
                  </button>
                )}
              </div>
            </div>
          )}
        </div>
      </main>

      {/* Student Pre-Join Permissions Modal */}
      {preJoinModalOpen && (
        <StudentPreJoinModal
          isOpen={preJoinModalOpen}
          classTitle={selectedClassToJoin?.title || activeClass.title}
          lectureTitle={selectedClassToJoin?.title || activeClass.title}
          onClose={() => setPreJoinModalOpen(false)}
          onJoin={handleProceedJoin}
          onProceed={handleProceedJoin}
        />
      )}
    </div>
  );
}

export default App;
