import React, { useState, useEffect } from 'react';
import {
  Calendar,
  Video,
  FileCheck,
  Award,
  Users,
  Plus,
  Play,
  Clock,
  ExternalLink,
  Bluetooth,
  Camera,
  CheckCircle,
  LogOut,
  Sparkles,
  Layers,
  GraduationCap,
} from 'lucide-react';
import { TeacherPreJoinModal } from '@shared/TeacherPreJoinModal';
import { LiveClassroom } from '@shared/LiveClassroom';
import { LoginCard, LoggedInUser } from '@shared/LoginCard';

interface BatchItem {
  id: string;
  name: string;
  course: { name: string };
  enrollments?: Array<{
    id: string;
    rollNumber: string;
    student: {
      id: string;
      name: string;
      email: string;
      phone?: string;
      avatarUrl?: string;
    };
  }>;
  _count?: { enrollments: number };
}

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
}

export function App() {
  const [currentUser, setCurrentUser] = useState<LoggedInUser | null>({
    name: 'Prof. Rajesh Sharma',
    email: 'teacher@apex.edu',
    role: 'teacher',
  });
  const [activeTab, setActiveTab] = useState<'schedule' | 'students' | 'assignments' | 'tests'>('schedule');

  // Database State
  const [batches, setBatches] = useState<BatchItem[]>([]);
  const [liveClasses, setLiveClasses] = useState<LiveClassItem[]>([]);
  const [selectedBatchId, setSelectedBatchId] = useState<string>('');

  // Pre-join & Live state
  const [preJoinOpen, setPreJoinOpen] = useState(false);
  const [activeClassToStart, setActiveClassToStart] = useState<LiveClassItem | null>(null);
  const [isInLiveClass, setIsInLiveClass] = useState(false);
  const [hardwareConfig, setHardwareConfig] = useState<any>(null);

  // Schedule modal state
  const [scheduleModal, setScheduleModal] = useState(false);
  const [modalBatchId, setModalBatchId] = useState('');
  const [modalTitle, setModalTitle] = useState('');
  const [modalSubject, setModalSubject] = useState('Physics');
  const [modalChapter, setModalChapter] = useState('Electrodynamics & Magnetism');
  const [modalTime, setModalTime] = useState('');

  // Fetch batches & classes from real DB
  const loadData = async () => {
    try {
      const [batchesRes, classesRes] = await Promise.all([
        fetch('http://localhost:4000/api/v1/batches'),
        fetch('http://localhost:4000/api/v1/live-classes'),
      ]);
      const batchesData = await batchesRes.json();
      const classesData = await classesRes.json();

      if (batchesData.batches) {
        setBatches(batchesData.batches);
        if (!selectedBatchId && batchesData.batches.length > 0) {
          setSelectedBatchId(batchesData.batches[0].id);
          setModalBatchId(batchesData.batches[0].id);
        }
      }
      if (classesData.liveClasses) {
        setLiveClasses(classesData.liveClasses);
      }
    } catch (e) {
      console.error('Error fetching data from API:', e);
    }
  };

  useEffect(() => {
    loadData();
    const interval = setInterval(loadData, 5000);
    return () => clearInterval(interval);
  }, []);

  const handleLaunchPreJoin = (cls: LiveClassItem) => {
    setActiveClassToStart(cls);
    setPreJoinOpen(true);
  };

  const handleProceedLive = async (config: any) => {
    setHardwareConfig(config);
    setPreJoinOpen(false);

    if (activeClassToStart) {
      try {
        await fetch(`http://localhost:4000/api/v1/live-classes/${activeClassToStart.id}/start`, {
          method: 'POST',
        });
        loadData();
      } catch (e) {
        console.error('Error starting live class:', e);
      }
    }
    setIsInLiveClass(true);
  };

  const handleEndLiveClass = async () => {
    if (activeClassToStart) {
      try {
        await fetch(`http://localhost:4000/api/v1/live-classes/${activeClassToStart.id}/end`, {
          method: 'POST',
        });
        loadData();
      } catch (e) {
        console.error('Error ending live class:', e);
      }
    }
    setIsInLiveClass(false);
    setActiveClassToStart(null);
  };

  const handleCreateLiveClass = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!modalTitle.trim() || !modalBatchId) return;

    try {
      const res = await fetch('http://localhost:4000/api/v1/live-classes', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          batchId: modalBatchId,
          title: modalTitle.trim(),
          subject: modalSubject.trim(),
          chapter: modalChapter.trim(),
          teacherId: 'usr-teacher-01',
          scheduledAt: modalTime ? new Date(modalTime).toISOString() : new Date().toISOString(),
        }),
      });
      if (res.ok) {
        setModalTitle('');
        setScheduleModal(false);
        loadData();
      }
    } catch (e) {
      console.error('Failed to schedule class:', e);
    }
  };

  // If in active classroom
  const activeClass = activeClassToStart || liveClasses[0] || {
    id: 'live-class-01',
    title: 'Electromagnetic Induction & Faraday’s Laws',
    subject: 'Physics',
    chapter: 'Electrodynamics — Unit 4',
    roomId: 'room-jee-101',
    status: 'LIVE',
    scheduledAt: new Date().toISOString(),
    batch: { id: 'batch-jee-12', name: 'Batch A — Class 12th IIT-JEE Masterclass' },
  };

  if (isInLiveClass) {
    return (
      <div className="h-screen flex flex-col bg-white">
        <header className="h-12 bg-white border-b border-slate-200 px-4 flex items-center justify-between shadow-subtle shrink-0">
          <div className="flex items-center space-x-2">
            <span className="w-2.5 h-2.5 rounded-full bg-rose-500 animate-ping" />
            <span className="text-xs font-black text-slate-900 tracking-wider uppercase">
              Teacher Broadcasting Live &bull; {activeClass.batch?.name || 'Classroom'}
            </span>
          </div>
          <button
            onClick={handleEndLiveClass}
            className="text-xs font-bold text-rose-600 bg-rose-50 hover:bg-rose-100 px-3 py-1.5 rounded-xl border border-rose-200 transition-colors"
          >
            End Live Broadcast & Return
          </button>
        </header>
        <div className="flex-1 overflow-hidden">
          <LiveClassroom
            role="teacher"
            userName={currentUser?.name || 'Prof. Rajesh Sharma'}
            classInfo={{
              id: activeClass.id,
              title: activeClass.title,
              subject: activeClass.subject,
              chapter: activeClass.chapter,
              batchName: activeClass.batch?.name,
              teacherName: currentUser?.name || 'Prof. Rajesh Sharma',
              roomId: activeClass.roomId,
            }}
            hardwareConfig={hardwareConfig}
            onExit={handleEndLiveClass}
          />
        </div>
      </div>
    );
  }

  if (!currentUser) {
    return (
      <LoginCard
        role="teacher"
        portalName="Teacher Broadcasting Studio"
        portNumber={3002}
        defaultEmail="teacher@apex.edu"
        defaultName="Prof. Rajesh Sharma (Faculty)"
        onLoginSuccess={(user) => setCurrentUser(user)}
      />
    );
  }

  const selectedBatch = batches.find((b) => b.id === selectedBatchId) || batches[0];
  const modalBatchObj = batches.find((b) => b.id === modalBatchId);

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 flex font-sans">
      {/* Sidebar */}
      <aside className="w-64 bg-white border-r border-slate-200 flex flex-col justify-between p-4 shadow-subtle shrink-0">
        <div>
          <div className="flex items-center space-x-3 pb-6 border-b border-slate-100">
            <div className="w-10 h-10 rounded-xl bg-indigo-600 flex items-center justify-center text-white font-bold text-lg shadow-sm">
              T
            </div>
            <div>
              <h2 className="text-sm font-bold text-slate-900">{currentUser.name}</h2>
              <span className="text-[10px] font-bold text-indigo-600 uppercase tracking-widest block">
                teacher.classora.com (Port 3002)
              </span>
            </div>
          </div>

          <nav className="mt-6 space-y-1 text-xs font-semibold">
            <button
              onClick={() => setActiveTab('schedule')}
              className={`w-full flex items-center space-x-3 px-3 py-2.5 rounded-xl transition-colors ${
                activeTab === 'schedule' ? 'bg-indigo-50 text-indigo-700' : 'text-slate-600 hover:bg-slate-50'
              }`}
            >
              <Calendar className="w-4 h-4" />
              <span>Classes & Schedule</span>
            </button>

            <button
              onClick={() => setActiveTab('students')}
              className={`w-full flex items-center space-x-3 px-3 py-2.5 rounded-xl transition-colors ${
                activeTab === 'students' ? 'bg-indigo-50 text-indigo-700' : 'text-slate-600 hover:bg-slate-50'
              }`}
            >
              <Users className="w-4 h-4" />
              <span>Batches & Students</span>
            </button>

            <button
              onClick={() => setActiveTab('assignments')}
              className={`w-full flex items-center space-x-3 px-3 py-2.5 rounded-xl transition-colors ${
                activeTab === 'assignments' ? 'bg-indigo-50 text-indigo-700' : 'text-slate-600 hover:bg-slate-50'
              }`}
            >
              <FileCheck className="w-4 h-4" />
              <span>Assignments & Grading</span>
            </button>

            <button
              onClick={() => setActiveTab('tests')}
              className={`w-full flex items-center space-x-3 px-3 py-2.5 rounded-xl transition-colors ${
                activeTab === 'tests' ? 'bg-indigo-50 text-indigo-700' : 'text-slate-600 hover:bg-slate-50'
              }`}
            >
              <Award className="w-4 h-4" />
              <span>Test & Question Bank</span>
            </button>
          </nav>
        </div>

        {/* Studio Hardware Card */}
        <div className="bg-gradient-to-br from-indigo-50 to-primary-100/50 border border-indigo-200 rounded-2xl p-4">
          <div className="flex items-center space-x-2 text-indigo-900 font-bold text-xs mb-1">
            <Camera className="w-4 h-4 text-indigo-600" />
            <span>Studio Hardware Ready</span>
          </div>
          <p className="text-[11px] text-slate-600 mb-3">
            Webcam, Bluetooth audio, and production whiteboard with pen size control.
          </p>
          <button
            onClick={() => {
              if (liveClasses.length > 0) handleLaunchPreJoin(liveClasses[0]);
            }}
            className="w-full py-2.5 text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-xl shadow-sm flex items-center justify-center space-x-2 transition-all"
          >
            <Play className="w-3.5 h-3.5 fill-current" />
            <span>Quick Studio Launch</span>
          </button>
        </div>
      </aside>

      {/* Main Area */}
      <main className="flex-1 flex flex-col h-screen overflow-y-auto">
        <header className="h-16 bg-white border-b border-slate-200 px-6 flex items-center justify-between shrink-0 shadow-subtle">
          <div>
            <h1 className="text-base font-extrabold text-slate-900">
              Teacher Broadcasting Studio & Schedule
            </h1>
            <p className="text-xs text-slate-500">Apex IIT-JEE & Medical Academy &bull; Faculty Console</p>
          </div>

          <div className="flex items-center space-x-3">
            <button
              onClick={() => setScheduleModal(true)}
              className="px-3.5 py-2 text-xs font-bold text-slate-700 bg-white hover:bg-slate-50 border border-slate-300 rounded-xl shadow-xs flex items-center space-x-1.5 transition-all"
            >
              <Plus className="w-4 h-4 text-indigo-600" />
              <span>Schedule Live Class</span>
            </button>

            <button
              onClick={() => {
                if (liveClasses.length > 0) handleLaunchPreJoin(liveClasses[0]);
              }}
              className="px-4 py-2 text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-xl shadow-sm flex items-center space-x-1.5 transition-all"
            >
              <Video className="w-4 h-4" />
              <span>Start Live Broadcast</span>
            </button>

            <div className="h-6 w-px bg-slate-200" />

            <div className="text-right hidden sm:block">
              <p className="text-xs font-bold text-slate-800">{currentUser.name}</p>
              <p className="text-[10px] text-slate-400">{currentUser.email}</p>
            </div>

            <button
              onClick={() => setCurrentUser(null)}
              className="p-2 text-slate-400 hover:text-rose-600 hover:bg-rose-50 rounded-xl transition-colors"
              title="Sign Out"
            >
              <LogOut className="w-4 h-4" />
            </button>
          </div>
        </header>

        {/* Main Content Area */}
        <div className="p-6 space-y-6">
          {activeTab === 'schedule' && (
            <div className="space-y-5">
              <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-5">
                <div className="flex items-center justify-between mb-4">
                  <div>
                    <h3 className="text-sm font-bold text-slate-900 flex items-center space-x-2">
                      <Clock className="w-4 h-4 text-indigo-600" />
                      <span>Live Scheduled Lectures ({liveClasses.length})</span>
                    </h3>
                    <p className="text-xs text-slate-500 mt-0.5">
                      Each class is linked to a specific Batch and synchronizes to students in real-time.
                    </p>
                  </div>
                  <button
                    onClick={() => setScheduleModal(true)}
                    className="text-xs font-bold text-indigo-600 hover:text-indigo-700 flex items-center space-x-1"
                  >
                    <Plus className="w-3.5 h-3.5" />
                    <span>New Schedule</span>
                  </button>
                </div>

                <div className="space-y-3">
                  {liveClasses.length === 0 ? (
                    <div className="text-center py-10 text-slate-400 text-xs">
                      No live classes scheduled yet. Click "Schedule Live Class" above to create one.
                    </div>
                  ) : (
                    liveClasses.map((cls) => (
                      <div
                        key={cls.id}
                        className="p-4 rounded-xl border border-slate-200 bg-slate-50/60 hover:bg-slate-50 flex flex-col sm:flex-row sm:items-center justify-between gap-4 transition-all"
                      >
                        <div>
                          <div className="flex items-center space-x-2 mb-1">
                            <span
                              className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                                cls.status === 'LIVE'
                                  ? 'bg-rose-100 text-rose-800 border border-rose-200 animate-pulse'
                                  : 'bg-indigo-100 text-indigo-800'
                              }`}
                            >
                              {cls.status === 'LIVE' ? '🔴 BROADCASTING LIVE' : 'READY TO GO LIVE'}
                            </span>
                            <span className="text-xs text-indigo-700 font-bold bg-indigo-50 px-2 py-0.5 rounded border border-indigo-100">
                              {cls.batch?.name || 'Class 12th IIT-JEE'}
                            </span>
                            <span className="text-xs text-slate-500 font-medium">&bull; {cls.subject}</span>
                          </div>
                          <h4 className="text-sm font-bold text-slate-900">{cls.title}</h4>
                          <p className="text-xs text-slate-500">
                            {cls.chapter ? `${cls.chapter} &bull; ` : ''}
                            Scheduled: {new Date(cls.scheduledAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}, Today
                          </p>
                        </div>

                        <button
                          onClick={() => handleLaunchPreJoin(cls)}
                          className="px-4 py-2 text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-xl shadow-xs flex items-center space-x-1.5 shrink-0 transition-all"
                        >
                          <Play className="w-3.5 h-3.5 fill-current" />
                          <span>{cls.status === 'LIVE' ? 'Enter Studio' : 'Go Live Now'}</span>
                        </button>
                      </div>
                    ))
                  )}
                </div>
              </div>

              {/* Hardware Features Overview */}
              <div className="grid grid-cols-1 md:grid-cols-3 gap-5 text-xs">
                <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-card">
                  <div className="w-9 h-9 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center mb-3">
                    <Camera className="w-5 h-5" />
                  </div>
                  <h4 className="font-bold text-slate-900 text-sm mb-1">Webcam & Camera Selector</h4>
                  <p className="text-slate-500">
                    Switch between built-in webcam and external USB streaming cameras with live mirror preview.
                  </p>
                </div>

                <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-card">
                  <div className="w-9 h-9 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center mb-3">
                    <Bluetooth className="w-5 h-5" />
                  </div>
                  <h4 className="font-bold text-slate-900 text-sm mb-1">Bluetooth Audio & Headsets</h4>
                  <p className="text-slate-500">
                    Scan and pair wireless Bluetooth mics or AirPods directly via Web Bluetooth API.
                  </p>
                </div>

                <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-card">
                  <div className="w-9 h-9 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center mb-3">
                    <CheckCircle className="w-5 h-5" />
                  </div>
                  <h4 className="font-bold text-slate-900 text-sm mb-1">Production Digital Board</h4>
                  <p className="text-slate-500">
                    Pen slider (1-40px), photo drops, PDF document background, and multi-tool sync.
                  </p>
                </div>
              </div>
            </div>
          )}

          {/* Students & Batches Tab */}
          {activeTab === 'students' && (
            <div className="space-y-6">
              {/* Batch Selector Pills */}
              <div className="bg-white rounded-2xl border border-slate-200 p-4 shadow-card">
                <h3 className="text-xs font-bold text-slate-500 uppercase tracking-wider mb-3">
                  Select Institute Batch
                </h3>
                <div className="flex flex-wrap gap-2">
                  {batches.map((batch) => (
                    <button
                      key={batch.id}
                      onClick={() => setSelectedBatchId(batch.id)}
                      className={`px-4 py-2 rounded-xl text-xs font-bold border transition-all ${
                        selectedBatchId === batch.id
                          ? 'bg-indigo-600 text-white border-indigo-600 shadow-sm'
                          : 'bg-slate-50 text-slate-700 border-slate-200 hover:bg-slate-100'
                      }`}
                    >
                      {batch.name} ({batch.enrollments?.length || 0} Students)
                    </button>
                  ))}
                </div>
              </div>

              {/* Students in Selected Batch */}
              {selectedBatch && (
                <div className="bg-white rounded-2xl border border-slate-200 p-5 shadow-card">
                  <div className="flex items-center justify-between mb-4">
                    <div>
                      <h3 className="text-sm font-bold text-slate-900">
                        Enrolled Students &bull; {selectedBatch.name}
                      </h3>
                      <p className="text-xs text-slate-500">
                        Course: {selectedBatch.course?.name} &bull; Total Enrolled: {selectedBatch.enrollments?.length || 0}
                      </p>
                    </div>
                  </div>

                  <div className="divide-y divide-slate-100">
                    {selectedBatch.enrollments && selectedBatch.enrollments.length > 0 ? (
                      selectedBatch.enrollments.map((enrollment) => (
                        <div key={enrollment.id} className="py-3 flex items-center justify-between">
                          <div className="flex items-center space-x-3">
                            <img
                              src={enrollment.student.avatarUrl || 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100&h=100&fit=crop'}
                              alt={enrollment.student.name}
                              className="w-10 h-10 rounded-full border border-slate-200 object-cover"
                            />
                            <div>
                              <h4 className="text-xs font-bold text-slate-900">{enrollment.student.name}</h4>
                              <p className="text-[11px] text-slate-500">
                                Roll: {enrollment.rollNumber || 'N/A'} &bull; {enrollment.student.email}
                              </p>
                            </div>
                          </div>
                          <span className="px-2.5 py-1 text-[10px] font-bold text-emerald-700 bg-emerald-50 rounded-full border border-emerald-200">
                            Active Enrolled
                          </span>
                        </div>
                      ))
                    ) : (
                      <div className="py-8 text-center text-slate-400 text-xs">
                        No students enrolled in this batch yet.
                      </div>
                    )}
                  </div>
                </div>
              )}
            </div>
          )}

          {activeTab === 'assignments' && (
            <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-5">
              <h3 className="text-sm font-bold text-slate-900 mb-2">Assignments & Homework Bank</h3>
              <p className="text-xs text-slate-500 mb-4">Create problem sheets and grade student PDF submissions.</p>
              <div className="p-4 rounded-xl border border-slate-100 bg-slate-50 flex items-center justify-between">
                <div>
                  <span className="text-[10px] font-bold text-indigo-700 bg-indigo-50 px-2 py-0.5 rounded">Batch A (JEE 12th)</span>
                  <h4 className="text-xs font-bold text-slate-800 mt-1">Electromagnetic Induction - Problem Set 01</h4>
                  <p className="text-[11px] text-slate-500">Due: In 3 Days &bull; 2 Submissions pending grading</p>
                </div>
                <button className="px-3 py-1.5 bg-indigo-600 text-white font-bold text-xs rounded-lg hover:bg-indigo-700">
                  Grade Submissions
                </button>
              </div>
            </div>
          )}

          {activeTab === 'tests' && (
            <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-5">
              <h3 className="text-sm font-bold text-slate-900 mb-2">Test & Quiz Creator</h3>
              <p className="text-xs text-slate-500 mb-4">Conduct live mock tests and evaluate student ranks.</p>
              <div className="p-4 rounded-xl border border-slate-100 bg-slate-50 flex items-center justify-between">
                <div>
                  <span className="text-[10px] font-bold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded">Scheduled Test</span>
                  <h4 className="text-xs font-bold text-slate-800 mt-1">Full Syllabus Physics Mock Test - 04</h4>
                  <p className="text-[11px] text-slate-500">30 Questions &bull; 180 Mins &bull; Negative Marking (+4/-1)</p>
                </div>
                <button className="px-3 py-1.5 bg-indigo-600 text-white font-bold text-xs rounded-lg hover:bg-indigo-700">
                  View Analytics
                </button>
              </div>
            </div>
          )}
        </div>
      </main>

      {/* Schedule Live Class Modal with Batch Selector */}
      {scheduleModal && (
        <div className="fixed inset-0 bg-slate-900/40 backdrop-blur-xs flex items-center justify-center p-4 z-50 animate-in fade-in duration-150">
          <div className="bg-white rounded-2xl shadow-elevated border border-slate-200 max-w-md w-full p-6">
            <div className="flex items-center justify-between pb-4 border-b border-slate-100 mb-4">
              <div>
                <h3 className="text-sm font-bold text-slate-900">Schedule Live Class</h3>
                <p className="text-xs text-slate-500">Select batch to broadcast directly to enrolled students</p>
              </div>
              <button onClick={() => setScheduleModal(false)} className="text-slate-400 hover:text-slate-600 text-sm font-bold">
                ✕
              </button>
            </div>

            <form onSubmit={handleCreateLiveClass} className="space-y-4">
              {/* Batch Selector */}
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">
                  Select Target Batch *
                </label>
                <select
                  value={modalBatchId}
                  onChange={(e) => setModalBatchId(e.target.value)}
                  className="w-full text-xs p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-indigo-500 font-semibold"
                >
                  {batches.map((batch) => (
                    <option key={batch.id} value={batch.id}>
                      {batch.name} ({batch.enrollments?.length || 0} students)
                    </option>
                  ))}
                </select>
                {modalBatchObj && (
                  <p className="text-[11px] text-indigo-600 font-semibold mt-1">
                    ✓ {modalBatchObj.enrollments?.length || 0} students enrolled in this batch will be notified.
                  </p>
                )}
              </div>

              {/* Title */}
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">Class Title *</label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Wave Optics & Young's Double Slit Experiment"
                  value={modalTitle}
                  onChange={(e) => setModalTitle(e.target.value)}
                  className="w-full text-xs p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-indigo-500"
                />
              </div>

              {/* Subject & Chapter */}
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">Subject</label>
                  <input
                    type="text"
                    value={modalSubject}
                    onChange={(e) => setModalSubject(e.target.value)}
                    className="w-full text-xs p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-indigo-500"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">Chapter</label>
                  <input
                    type="text"
                    value={modalChapter}
                    onChange={(e) => setModalChapter(e.target.value)}
                    className="w-full text-xs p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-indigo-500"
                  />
                </div>
              </div>

              {/* Time */}
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">Scheduled Time (Leave empty for Now)</label>
                <input
                  type="datetime-local"
                  value={modalTime}
                  onChange={(e) => setModalTime(e.target.value)}
                  className="w-full text-xs p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:border-indigo-500"
                />
              </div>

              <div className="pt-2 flex justify-end space-x-2">
                <button
                  type="button"
                  onClick={() => setScheduleModal(false)}
                  className="px-4 py-2 text-xs font-bold text-slate-600 hover:bg-slate-100 rounded-xl"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-xl shadow-xs"
                >
                  Confirm & Schedule
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Pre-Join Hardware Setup Modal */}
      {preJoinOpen && (
        <TeacherPreJoinModal
          isOpen={preJoinOpen}
          classTitle={activeClassToStart?.title || activeClass.title}
          onClose={() => setPreJoinOpen(false)}
          onProceedToLive={handleProceedLive}
          onProceed={handleProceedLive}
        />
      )}
    </div>
  );
}

export default App;
