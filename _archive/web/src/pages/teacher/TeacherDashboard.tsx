import React, { useState } from 'react';
import {
  Calendar,
  Video,
  PenTool,
  BookOpen,
  FileCheck,
  Users,
  Award,
  Plus,
  Play,
  Clock,
  CheckCircle,
  AlertCircle,
  Upload,
  ArrowRight,
  ExternalLink,
  ChevronRight,
  UserPlus,
  FileText,
  User,
  LogOut,
  Mail,
  Phone,
  Shield,
  Sparkles,
  CheckCircle2,
  Download,
  FolderOpen,
} from 'lucide-react';
import { initialLiveClasses, initialAssignments, initialTests, initialUsers } from '../../../../api/src/mockData.js';
import { LiveClassroom } from '../../components/classroom/LiveClassroom.js';
import { DocumentViewer, samplePhysicsDocument } from '../../components/document/DocumentViewer.js';
import { useMobileNavigation } from '../../hooks/useMobileNavigation.js';

interface TeacherDashboardProps {
  userSession?: any;
  onLogout?: () => void;
}

export const TeacherDashboard: React.FC<TeacherDashboardProps> = ({ userSession, onLogout }) => {
  // Main Top Navigation tabs: 'home' | 'my-classes' | 'notes' | 'add-students' | 'profile'
  const [activeTab, setActiveTab] = useState<'home' | 'my-classes' | 'notes' | 'add-students' | 'profile'>('home');

  // Sub-tabs inside My Classes (original project features)
  const [classSubTab, setClassSubTab] = useState<'schedule' | 'assignments' | 'tests' | 'students'>('schedule');

  // Interactive Live Session trigger
  const [isInLiveClass, setIsInLiveClass] = useState(false);

  // New Class Modal
  const [scheduleModalOpen, setScheduleModalOpen] = useState(false);
  const [newClassTitle, setNewClassTitle] = useState('');
  const [newClassChapter, setNewClassChapter] = useState('Rotational Dynamics');
  const [newClassTime, setNewClassTime] = useState('18:30');

  // Add Student Form State
  const [addStudentModalOpen, setAddStudentModalOpen] = useState(false);

  // Mobile Back & Motion Gesture Navigation Handler
  useMobileNavigation({
    onBack: () => {
      if (scheduleModalOpen) {
        setScheduleModalOpen(false);
      } else if (addStudentModalOpen) {
        setAddStudentModalOpen(false);
      } else if (isInLiveClass) {
        setIsInLiveClass(false);
      } else if (activeTab !== 'home') {
        setActiveTab('home');
      }
    },
    enabled: isInLiveClass || scheduleModalOpen || addStudentModalOpen || activeTab !== 'home',
  });

  // State
  const [classesList, setClassesList] = useState(initialLiveClasses);
  const [assignmentsList, setAssignmentsList] = useState(initialAssignments);
  const [testsList, setTestsList] = useState(initialTests);
  const [studentsList, setStudentsList] = useState(initialUsers.filter((u) => u.role === 'student'));

  const [studentNameInput, setStudentNameInput] = useState('');
  const [studentEmailInput, setStudentEmailInput] = useState('');
  const [studentPhoneInput, setStudentPhoneInput] = useState('');
  const [studentBatchInput, setStudentBatchInput] = useState('JEE Super 30 (Batch Alpha)');
  const [studentAddedSuccess, setStudentAddedSuccess] = useState(false);

  // Teacher Profile Data
  const teacherProfile = {
    name: userSession?.name || 'Prof. Rajesh Sharma',
    email: userSession?.email || 'rajesh.sharma@teacher.classora.com',
    department: userSession?.batchOrDept || 'Department of Physics',
    teacherId: 'TCH-PHYS-01',
    phone: '+91 98123 45678',
    totalClasses: 128,
    activeStudents: studentsList.length + 30,
    experience: '14+ Years in IIT-JEE Coaching',
  };

  // Schedule new class handler
  const handleScheduleClass = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newClassTitle.trim()) return;
    const newCls = {
      id: `live-${Date.now()}`,
      institute_id: 'inst-apex-01',
      batch_id: 'batch-jee-2026',
      batch_name: 'JEE Super 30 (Batch Alpha)',
      teacher_id: 'usr-teacher-01',
      teacher_name: teacherProfile.name,
      subject_name: 'Physics',
      chapter_id: 'ch-01',
      chapter_name: newClassChapter,
      title: newClassTitle.trim(),
      scheduled_at: `2026-09-10T${newClassTime}:00Z`,
      room_id: `room-${Date.now()}`,
      status: 'scheduled' as const,
    };
    setClassesList([newCls, ...classesList]);
    setNewClassTitle('');
    setScheduleModalOpen(false);
  };

  // Add Student Handler
  const handleAddStudent = (e: React.FormEvent) => {
    e.preventDefault();
    if (!studentNameInput.trim() || !studentEmailInput.trim()) return;

    const newStudent = {
      id: `usr-student-${Date.now()}`,
      institute_id: 'inst-apex-01',
      name: studentNameInput.trim(),
      email: studentEmailInput.trim(),
      phone: studentPhoneInput.trim() || '+91 98000 11122',
      role: 'student' as const,
      avatar_url: `https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&h=100&fit=crop`,
      status: 'active' as const,
      created_at: new Date().toISOString(),
    };

    setStudentsList([newStudent, ...studentsList]);
    setStudentAddedSuccess(true);
  };

  if (isInLiveClass) {
    return (
      <LiveClassroom
        role="teacher"
        userName={teacherProfile.name}
        onExit={() => setIsInLiveClass(false)}
      />
    );
  }

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 flex flex-col font-sans">
      {/* Top Navigation Header */}
      <header className="h-16 bg-white border-b border-slate-200 px-3 sm:px-6 flex items-center justify-between shrink-0 shadow-subtle sticky top-0 z-40 pt-safe">
        <div className="flex items-center space-x-3 sm:space-x-6">
          <div className="flex items-center space-x-2">
            <div className="w-8 h-8 rounded-xl bg-indigo-600 text-white flex items-center justify-center font-black text-sm shadow-sm">
              C
            </div>
            <span className="text-base font-extrabold text-slate-900 tracking-tight">CLASSORA</span>
          </div>

          {/* Main Navigation Tabs (Desktop) */}
          <nav className="hidden lg:flex items-center space-x-1 bg-slate-100 p-1 rounded-xl border border-slate-200">
            <button
              onClick={() => setActiveTab('home')}
              className={`flex items-center space-x-2 px-3.5 py-1.5 rounded-lg text-xs font-bold transition-all ${
                activeTab === 'home'
                  ? 'bg-white text-indigo-700 shadow-sm'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              <BookOpen className="w-3.5 h-3.5" />
              <span>Home</span>
            </button>

            <button
              onClick={() => setActiveTab('my-classes')}
              className={`flex items-center space-x-2 px-3.5 py-1.5 rounded-lg text-xs font-bold transition-all ${
                activeTab === 'my-classes'
                  ? 'bg-white text-indigo-700 shadow-sm'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              <Calendar className="w-3.5 h-3.5" />
              <span>My Classes</span>
            </button>

            {/* DEDICATED SEPARATE BUTTON FOR NOTES & STUDY MATERIAL */}
            <button
              onClick={() => setActiveTab('notes')}
              className={`flex items-center space-x-2 px-3.5 py-1.5 rounded-lg text-xs font-bold transition-all ${
                activeTab === 'notes'
                  ? 'bg-indigo-600 text-white shadow-sm'
                  : 'text-indigo-700 bg-indigo-50 hover:bg-indigo-100'
              }`}
            >
              <FileText className="w-3.5 h-3.5" />
              <span>Notes & PPT Slides</span>
            </button>

            <button
              onClick={() => {
                setActiveTab('add-students');
                setAddStudentModalOpen(true);
              }}
              className={`flex items-center space-x-2 px-3.5 py-1.5 rounded-lg text-xs font-bold transition-all ${
                activeTab === 'add-students'
                  ? 'bg-emerald-600 text-white shadow-sm'
                  : 'text-emerald-800 bg-emerald-50 hover:bg-emerald-100'
              }`}
            >
              <UserPlus className="w-3.5 h-3.5" />
              <span>+ Add Students</span>
            </button>

            <button
              onClick={() => setActiveTab('profile')}
              className={`flex items-center space-x-2 px-3.5 py-1.5 rounded-lg text-xs font-bold transition-all ${
                activeTab === 'profile'
                  ? 'bg-white text-indigo-700 shadow-sm'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              <User className="w-3.5 h-3.5" />
              <span>Profile</span>
            </button>
          </nav>
        </div>

        {/* Live Broadcast Trigger & Profile */}
        <div className="flex items-center space-x-2 sm:space-x-3">
          <button
            onClick={() => setIsInLiveClass(true)}
            className="inline-flex items-center space-x-1.5 sm:space-x-2 px-3 sm:px-4 py-1.5 sm:py-2 text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-700 active:bg-indigo-800 rounded-xl shadow-md transition-all active:scale-95"
          >
            <Video className="w-4 h-4" />
            <span className="hidden sm:inline">Start Live Class Now</span>
            <span className="sm:hidden">Start Live</span>
          </button>

          <div className="flex items-center space-x-2 sm:space-x-3 pl-2 sm:pl-3 border-l border-slate-200">
            <div className="flex items-center space-x-2">
              <img
                src="https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop"
                alt="Teacher Avatar"
                className="w-7 h-7 sm:w-8 sm:h-8 rounded-full border border-indigo-300"
              />
              <div className="hidden xl:block">
                <span className="text-xs font-bold text-slate-900 block">{teacherProfile.name}</span>
                <span className="text-[10px] text-slate-500 block">Faculty Account</span>
              </div>
            </div>

            {onLogout && (
              <button
                onClick={onLogout}
                className="p-1.5 sm:p-2 text-slate-400 hover:text-rose-600 hover:bg-rose-50 rounded-lg transition-colors"
                title="Sign Out"
              >
                <LogOut className="w-4 h-4" />
              </button>
            )}
          </div>
        </div>
      </header>

      {/* Main Body */}
      <main className="flex-1 p-3 sm:p-6 max-w-7xl w-full mx-auto space-y-6 pb-24 lg:pb-8">
        {/* ==================== 1. HOME TAB (MATCHES STUDENT HOME LAYOUT) ==================== */}
        {activeTab === 'home' && (
          <div className="space-y-8">
            {/* HERO SECTION WITH WELCOME & COURSE NAME */}
            <div className="relative rounded-3xl bg-gradient-to-r from-slate-900 via-indigo-950 to-slate-900 text-white p-8 sm:p-10 shadow-xl overflow-hidden">
              <div className="absolute right-0 top-0 bottom-0 w-1/2 bg-[url('https://images.unsplash.com/photo-1509228468518-180dd4864904?w=800&fit=crop')] bg-cover bg-center opacity-15 mix-blend-overlay pointer-events-none" />
              <div className="relative z-10 max-w-2xl space-y-4">
                <div className="inline-flex items-center space-x-2 bg-indigo-500/20 border border-indigo-400/30 px-3 py-1 rounded-full text-xs font-bold tracking-wide">
                  <Sparkles className="w-3.5 h-3.5 text-amber-300" />
                  <span>Welcome Back, {teacherProfile.name}!</span>
                </div>
                <h1 className="text-2xl sm:text-4xl font-black tracking-tight leading-tight">
                  JEE Super 30 &bull; Advanced Physics Mastery Batch
                </h1>
                <p className="text-xs sm:text-sm text-slate-300 leading-relaxed">
                  Manage live interactive lectures, grade homework, build online MCQ tests, and review multi-page PDF & PPT slides for your enrolled students.
                </p>

                {/* Hero Action Buttons */}
                <div className="pt-2 flex flex-wrap items-center gap-3">
                  <button
                    onClick={() => setIsInLiveClass(true)}
                    className="px-5 py-2.5 text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-500 rounded-xl shadow-lg flex items-center space-x-2 transition-all"
                  >
                    <Play className="w-4 h-4 fill-current" />
                    <span>Launch Live Whiteboard Class</span>
                  </button>

                  <button
                    onClick={() => setActiveTab('notes')}
                    className="px-5 py-2.5 text-xs font-bold text-slate-900 bg-amber-400 hover:bg-amber-300 rounded-xl shadow-md flex items-center space-x-2 transition-all"
                  >
                    <FileText className="w-4 h-4 text-slate-900" />
                    <span>Open PPT & Notes Console</span>
                  </button>

                  <button
                    onClick={() => {
                      setActiveTab('add-students');
                      setAddStudentModalOpen(true);
                    }}
                    className="px-5 py-2.5 text-xs font-bold text-slate-900 bg-white hover:bg-slate-100 rounded-xl shadow-md flex items-center space-x-2 transition-all"
                  >
                    <UserPlus className="w-4 h-4 text-indigo-600" />
                    <span>+ Enroll Student</span>
                  </button>
                </div>
              </div>
            </div>

            {/* Quick Metrics Cards */}
            <div className="grid grid-cols-1 md:grid-cols-4 gap-5">
              <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-5">
                <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">Total Delivered Sessions</span>
                <div className="text-2xl font-black text-slate-900 mt-1">{teacherProfile.totalClasses} Lectures</div>
                <p className="text-[11px] text-slate-500 mt-1">192 hours broadcasted</p>
              </div>

              <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-5">
                <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">Enrolled Batch Students</span>
                <div className="text-2xl font-black text-indigo-600 mt-1">{studentsList.length} Students</div>
                <p className="text-[11px] text-indigo-700 font-semibold mt-1">JEE Super 30 Alpha</p>
              </div>

              <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-5">
                <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">Homework Submissions</span>
                <div className="text-2xl font-black text-amber-600 mt-1">17 Pending</div>
                <p className="text-[11px] text-slate-500 mt-1">Rotational Dynamics HW</p>
              </div>

              <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-5">
                <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">Average Attendance</span>
                <div className="text-2xl font-black text-emerald-600 mt-1">94.8%</div>
                <p className="text-[11px] text-slate-500 mt-1">Live class participation</p>
              </div>
            </div>

            {/* Today's Scheduled Live Timetable */}
            <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-base font-bold text-slate-900 flex items-center space-x-2">
                  <Clock className="w-5 h-5 text-indigo-600" />
                  <span>Today's Live Timetable</span>
                </h3>
                <button
                  onClick={() => setScheduleModalOpen(true)}
                  className="px-3.5 py-1.5 text-xs font-bold text-indigo-700 bg-indigo-50 hover:bg-indigo-100 rounded-lg transition-colors flex items-center space-x-1"
                >
                  <Plus className="w-4 h-4" />
                  <span>Schedule Lecture</span>
                </button>
              </div>

              <div className="space-y-3">
                {classesList.map((cls) => (
                  <div
                    key={cls.id}
                    className="p-4 rounded-xl border border-slate-200 bg-slate-50/60 hover:bg-slate-50 flex flex-col sm:flex-row sm:items-center justify-between gap-4 transition-all"
                  >
                    <div>
                      <div className="flex items-center space-x-2 mb-1">
                        <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-emerald-100 text-emerald-800">
                          {cls.status.toUpperCase()}
                        </span>
                        <span className="text-xs font-bold text-slate-600">{cls.batch_name}</span>
                      </div>
                      <h4 className="text-sm font-bold text-slate-900">{cls.title}</h4>
                      <p className="text-xs text-slate-500">{cls.chapter_name} &bull; Room ID: {cls.room_id}</p>
                    </div>

                    <button
                      onClick={() => setIsInLiveClass(true)}
                      className="px-4 py-2 text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg shadow-sm flex items-center space-x-1.5 shrink-0"
                    >
                      <Play className="w-3.5 h-3.5 fill-current" />
                      <span>Start Live Lecture</span>
                    </button>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* ==================== 2. MY CLASSES TAB (ORIGINAL PROJECT DASHBOARD FEATURES) ==================== */}
        {activeTab === 'my-classes' && (
          <div className="space-y-6">
            {/* Sub-navigation bar inside My Classes */}
            <div className="flex flex-wrap items-center justify-between gap-3 bg-white p-3 rounded-2xl border border-slate-200 shadow-subtle">
              <div className="flex items-center space-x-1">
                <button
                  onClick={() => setClassSubTab('schedule')}
                  className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${
                    classSubTab === 'schedule'
                      ? 'bg-indigo-600 text-white shadow-sm'
                      : 'text-slate-600 hover:bg-slate-100'
                  }`}
                >
                  Live Classes & Timetable
                </button>

                <button
                  onClick={() => setClassSubTab('assignments')}
                  className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${
                    classSubTab === 'assignments'
                      ? 'bg-indigo-600 text-white shadow-sm'
                      : 'text-slate-600 hover:bg-slate-100'
                  }`}
                >
                  Assignments & Grading
                </button>

                <button
                  onClick={() => setClassSubTab('tests')}
                  className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${
                    classSubTab === 'tests'
                      ? 'bg-indigo-600 text-white shadow-sm'
                      : 'text-slate-600 hover:bg-slate-100'
                  }`}
                >
                  Online Test Builder
                </button>

                <button
                  onClick={() => setClassSubTab('students')}
                  className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${
                    classSubTab === 'students'
                      ? 'bg-indigo-600 text-white shadow-sm'
                      : 'text-slate-600 hover:bg-slate-100'
                  }`}
                >
                  Enrolled Students Batch
                </button>
              </div>

              <button
                onClick={() => setScheduleModalOpen(true)}
                className="px-4 py-2 text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-xl shadow-sm flex items-center space-x-1.5"
              >
                <Plus className="w-4 h-4" />
                <span>+ Schedule New Lecture</span>
              </button>
            </div>

            {/* LIVE CLASSES & TIMETABLE SUB-TAB */}
            {classSubTab === 'schedule' && (
              <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-6 space-y-4">
                <div className="flex items-center justify-between pb-3 border-b border-slate-100">
                  <h3 className="text-base font-bold text-slate-900">Live Lectures Roster & Schedule</h3>
                  <span className="text-xs text-slate-500">Batch: JEE Super 30 Alpha</span>
                </div>

                <div className="space-y-3">
                  {classesList.map((cls) => (
                    <div
                      key={cls.id}
                      className="p-4 rounded-xl border border-slate-200 bg-slate-50 flex items-center justify-between hover:border-indigo-200 transition-all"
                    >
                      <div>
                        <div className="flex items-center space-x-2">
                          <span className="text-[10px] font-bold bg-indigo-100 text-indigo-800 px-2 py-0.5 rounded">
                            {cls.batch_name}
                          </span>
                          <span className="text-xs font-semibold text-slate-500">Room: {cls.room_id}</span>
                        </div>
                        <h4 className="text-sm font-bold text-slate-900 mt-1">{cls.title}</h4>
                        <p className="text-xs text-slate-500">{cls.chapter_name}</p>
                      </div>

                      <div className="flex items-center space-x-2">
                        <button
                          onClick={() => setIsInLiveClass(true)}
                          className="px-4 py-2 text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg shadow-sm flex items-center space-x-1"
                        >
                          <Play className="w-3.5 h-3.5 fill-current" />
                          <span>Go Live Now</span>
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* ASSIGNMENTS & GRADING SUB-TAB */}
            {classSubTab === 'assignments' && (
              <div className="bg-white rounded-2xl border border-slate-200 shadow-card overflow-hidden">
                <div className="p-5 border-b border-slate-200 flex items-center justify-between">
                  <h3 className="text-base font-bold text-slate-900">Homework & Assignment Evaluation</h3>
                  <button className="px-3.5 py-1.5 text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg">
                    + Create Assignment
                  </button>
                </div>
                <div className="divide-y divide-slate-100">
                  {assignmentsList.map((asg) => (
                    <div key={asg.id} className="p-5 flex items-center justify-between">
                      <div>
                        <span className="text-xs font-bold text-indigo-600 bg-indigo-50 px-2 py-0.5 rounded">
                          {asg.chapter_name}
                        </span>
                        <h4 className="text-sm font-bold text-slate-900 mt-1">{asg.title}</h4>
                        <p className="text-xs text-slate-500">{asg.description}</p>
                      </div>
                      <button className="px-4 py-2 text-xs font-bold text-indigo-700 bg-indigo-50 hover:bg-indigo-100 rounded-lg">
                        Grade Submissions (17 Pending)
                      </button>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* ONLINE TEST BUILDER SUB-TAB */}
            {classSubTab === 'tests' && (
              <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-6">
                <div className="flex items-center justify-between mb-4 pb-3 border-b border-slate-100">
                  <h3 className="text-base font-bold text-slate-900">Question Bank & Test Builder</h3>
                  <button className="px-3.5 py-1.5 text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg">
                    + Create Online Test
                  </button>
                </div>
                <div className="space-y-4">
                  {testsList.map((t) => (
                    <div key={t.id} className="p-4 rounded-xl border border-slate-200 bg-slate-50 flex items-center justify-between">
                      <div>
                        <h4 className="text-sm font-bold text-slate-900">{t.title}</h4>
                        <p className="text-xs text-slate-500">Duration: {t.duration_min} Mins &bull; Total Marks: {t.total_marks}</p>
                      </div>
                      <button className="px-4 py-2 text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg">
                        Manage MCQs & Answer Key
                      </button>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* ENROLLED STUDENTS SUB-TAB */}
            {classSubTab === 'students' && (
              <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-6">
                <div className="flex items-center justify-between mb-4 pb-3 border-b border-slate-100">
                  <h3 className="text-base font-bold text-slate-900">Enrolled Batch Roster</h3>
                  <button
                    onClick={() => {
                      setActiveTab('add-students');
                      setAddStudentModalOpen(true);
                    }}
                    className="px-3.5 py-1.5 text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-700 rounded-lg flex items-center space-x-1"
                  >
                    <UserPlus className="w-3.5 h-3.5" />
                    <span>+ Add Student</span>
                  </button>
                </div>

                <div className="divide-y divide-slate-100">
                  {studentsList.map((student) => (
                    <div key={student.id} className="py-3 flex items-center justify-between">
                      <div className="flex items-center space-x-3">
                        <img src={student.avatar_url} alt="" className="w-8 h-8 rounded-full" />
                        <div>
                          <p className="text-xs font-bold text-slate-900">{student.name}</p>
                          <p className="text-[11px] text-slate-500">{student.email}</p>
                        </div>
                      </div>
                      <span className="px-2.5 py-1 bg-emerald-50 text-emerald-700 text-[10px] font-bold rounded-full border border-emerald-200">
                        Active Enrolled
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        )}

        {/* ==================== 3. SEPARATE DEDICATED BUTTON TAB: NOTES & PPT SLIDES ==================== */}
        {activeTab === 'notes' && (
          <div className="space-y-6">
            <div className="bg-gradient-to-r from-amber-500 via-amber-600 to-amber-700 text-white rounded-2xl p-6 shadow-md flex flex-col sm:flex-row sm:items-center justify-between gap-4">
              <div>
                <div className="flex items-center space-x-2 text-amber-100 mb-1">
                  <FileText className="w-5 h-5" />
                  <span className="text-xs font-black uppercase tracking-wider">Dedicated Study Notes & PPT Module</span>
                </div>
                <h2 className="text-xl font-black">Multi-Page Presentation & PDF Documents Console</h2>
                <p className="text-xs text-amber-100 mt-1">
                  Click bottom toolbar buttons (Next / Prev Page) to switch document pages cleanly.
                </p>
              </div>

              <div className="flex items-center space-x-2 shrink-0">
                <button
                  onClick={() => {
                    const samplePdfContent = "%PDF-1.4\n1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\ntrailer\n<< /Root 1 0 R >>\n%%EOF";
                    const blob = new Blob([samplePdfContent], { type: 'application/pdf' });
                    const url = URL.createObjectURL(blob);
                    const link = document.createElement('a');
                    link.href = url;
                    link.download = 'Physics_Rotational_Dynamics_Notes.pdf';
                    document.body.appendChild(link);
                    link.click();
                    document.body.removeChild(link);
                    URL.revokeObjectURL(url);
                  }}
                  className="px-4 py-2.5 text-xs font-bold text-slate-900 bg-white hover:bg-slate-100 rounded-xl shadow-sm flex items-center space-x-1.5"
                >
                  <Download className="w-4 h-4 text-amber-700" />
                  <span>Download Sample PDF Notes</span>
                </button>
              </div>
            </div>

            {/* Document / PPT Presentation Viewer */}
            <DocumentViewer document={samplePhysicsDocument} />
          </div>
        )}

        {/* ==================== 4. ADD STUDENTS TAB ==================== */}
        {activeTab === 'add-students' && (
          <div className="space-y-6">
            <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-6">
              <div className="flex items-center justify-between pb-4 border-b border-slate-100 mb-6">
                <div>
                  <h2 className="text-lg font-black text-slate-900 flex items-center space-x-2">
                    <UserPlus className="w-5 h-5 text-indigo-600" />
                    <span>Batch Student Roster & Enrolments</span>
                  </h2>
                  <p className="text-xs text-slate-500 mt-1">
                    Manage enrolled candidates and add new students to your batch.
                  </p>
                </div>

                <button
                  onClick={() => {
                    setStudentAddedSuccess(false);
                    setAddStudentModalOpen(true);
                  }}
                  className="px-5 py-2.5 text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-700 rounded-xl shadow-md flex items-center space-x-2 transition-all"
                >
                  <UserPlus className="w-4 h-4" />
                  <span>+ Enroll Candidate</span>
                </button>
              </div>

              {/* Enrolled Students List */}
              <div className="divide-y divide-slate-100">
                {studentsList.map((student) => (
                  <div
                    key={student.id}
                    className="p-4 flex flex-col sm:flex-row sm:items-center justify-between gap-4 hover:bg-slate-50 transition-colors rounded-xl"
                  >
                    <div className="flex items-center space-x-3">
                      <img
                        src={student.avatar_url}
                        alt=""
                        className="w-10 h-10 rounded-full border border-slate-200"
                      />
                      <div>
                        <p className="text-sm font-bold text-slate-900">{student.name}</p>
                        <p className="text-xs text-slate-500">{student.email} &bull; {student.phone}</p>
                      </div>
                    </div>

                    <div className="flex items-center space-x-3 text-xs">
                      <span className="px-3 py-1 bg-emerald-50 text-emerald-700 font-bold rounded-full border border-emerald-200">
                        ENROLLED
                      </span>
                      <button className="px-3 py-1.5 font-bold text-slate-700 bg-slate-100 hover:bg-slate-200 rounded-lg">
                        View Student Progress
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* ==================== 5. PROFILE TAB ==================== */}
        {activeTab === 'profile' && (
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {/* Bio Card */}
            <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-6 text-center">
              <img
                src="https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&h=200&fit=crop"
                alt="Teacher"
                className="w-24 h-24 rounded-full border-2 border-indigo-500 mx-auto mb-4 p-1 shadow-md"
              />
              <h2 className="text-lg font-black text-slate-900">{teacherProfile.name}</h2>
              <span className="inline-block bg-indigo-50 text-indigo-700 text-xs font-bold px-3 py-1 rounded-full border border-indigo-200 mt-1">
                {teacherProfile.department}
              </span>
              <p className="text-xs text-slate-500 mt-2">Faculty ID: {teacherProfile.teacherId}</p>

              <div className="mt-6 pt-6 border-t border-slate-100 text-left space-y-3 text-xs">
                <div className="flex items-center text-slate-600">
                  <Mail className="w-4 h-4 mr-2 text-slate-400" />
                  <span>{teacherProfile.email}</span>
                </div>
                <div className="flex items-center text-slate-600">
                  <Phone className="w-4 h-4 mr-2 text-slate-400" />
                  <span>{teacherProfile.phone}</span>
                </div>
                <div className="flex items-center text-slate-600">
                  <Award className="w-4 h-4 mr-2 text-slate-400" />
                  <span>{teacherProfile.experience}</span>
                </div>
              </div>
            </div>

            {/* Details */}
            <div className="md:col-span-2 space-y-6">
              <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-6">
                <h3 className="text-base font-bold text-slate-900 mb-4">Faculty Stats & Course Portfolio</h3>

                <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                  <div className="bg-indigo-50 border border-indigo-200 p-4 rounded-xl">
                    <span className="text-[10px] font-bold text-indigo-800 uppercase tracking-wider">Total Delivered Lectures</span>
                    <p className="text-2xl font-black text-indigo-700 mt-1">{teacherProfile.totalClasses}</p>
                    <p className="text-[11px] text-indigo-600 mt-1">Whiteboard Sessions</p>
                  </div>

                  <div className="bg-emerald-50 border border-emerald-200 p-4 rounded-xl">
                    <span className="text-[10px] font-bold text-emerald-800 uppercase tracking-wider">Active Students</span>
                    <p className="text-2xl font-black text-emerald-700 mt-1">{studentsList.length}</p>
                    <p className="text-[11px] text-emerald-600 mt-1">JEE Super 30 Batch</p>
                  </div>

                  <div className="bg-purple-50 border border-purple-200 p-4 rounded-xl">
                    <span className="text-[10px] font-bold text-purple-800 uppercase tracking-wider">Rating</span>
                    <p className="text-2xl font-black text-purple-700 mt-1">4.9 / 5.0</p>
                    <p className="text-[11px] text-purple-600 mt-1">Student Feedback</p>
                  </div>
                </div>
              </div>

              {/* Security */}
              <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-6">
                <h3 className="text-base font-bold text-slate-900 mb-3 flex items-center space-x-2">
                  <Shield className="w-5 h-5 text-indigo-600" />
                  <span>Faculty Security & Access Controls</span>
                </h3>
                <div className="space-y-3 text-xs">
                  <div className="flex items-center justify-between p-3 bg-slate-50 rounded-xl border border-slate-200">
                    <div>
                      <p className="font-bold text-slate-800">Faculty Privileges</p>
                      <p className="text-[11px] text-slate-500">Live Whiteboard Broadcast, Student Enrolment, Homework Grading</p>
                    </div>
                    <span className="px-2.5 py-1 bg-emerald-100 text-emerald-800 font-bold rounded-lg text-[10px]">
                      FULL PRIVILEGES
                    </span>
                  </div>

                  <button className="w-full py-2.5 text-xs font-bold text-slate-700 bg-slate-100 hover:bg-slate-200 rounded-xl transition-colors">
                    Update Faculty Security Settings
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}
      </main>

      {/* Schedule Class Modal */}
      {scheduleModalOpen && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl shadow-elevated border border-slate-200 p-6 max-w-md w-full">
            <h3 className="text-base font-bold text-slate-900 mb-1">Schedule Live Lecture</h3>
            <p className="text-xs text-slate-500 mb-4">Set up a real-time lecture with integrated interactive whiteboard.</p>
            <form onSubmit={handleScheduleClass} className="space-y-3 text-xs">
              <div>
                <label className="block font-semibold text-slate-700 mb-1">Lecture Topic / Title</label>
                <input
                  required
                  value={newClassTitle}
                  onChange={(e) => setNewClassTitle(e.target.value)}
                  placeholder="e.g. Rolling Motion & Conservation of Angular Momentum"
                  className="w-full p-2.5 border border-slate-200 rounded-lg focus:ring-2 focus:ring-indigo-500"
                />
              </div>
              <div>
                <label className="block font-semibold text-slate-700 mb-1">Chapter / Subject Unit</label>
                <select
                  value={newClassChapter}
                  onChange={(e) => setNewClassChapter(e.target.value)}
                  className="w-full p-2.5 border border-slate-200 rounded-lg focus:ring-2 focus:ring-indigo-500"
                >
                  <option>Rotational Dynamics & Torque</option>
                  <option>Electrostatics & Gauss Law</option>
                  <option>Electromagnetic Induction</option>
                </select>
              </div>
              <div>
                <label className="block font-semibold text-slate-700 mb-1">Scheduled Time (IST)</label>
                <input
                  type="time"
                  value={newClassTime}
                  onChange={(e) => setNewClassTime(e.target.value)}
                  className="w-full p-2.5 border border-slate-200 rounded-lg focus:ring-2 focus:ring-indigo-500"
                />
              </div>
              <div className="flex justify-end space-x-2 pt-2">
                <button
                  type="button"
                  onClick={() => setScheduleModalOpen(false)}
                  className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 font-semibold text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg shadow-sm"
                >
                  Save & Notify Batch
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ADD STUDENT MODAL FOR TEACHER */}
      {addStudentModalOpen && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl shadow-elevated border border-slate-200 p-6 max-w-md w-full">
            <div className="flex items-center space-x-2 text-emerald-600 mb-2">
              <UserPlus className="w-5 h-5" />
              <span className="text-xs font-bold uppercase tracking-wider">Teacher Console &bull; Enroll Candidate</span>
            </div>

            <h3 className="text-base font-bold text-slate-900 mb-1">Add Student to Batch</h3>
            <p className="text-xs text-slate-500 mb-4">
              Enter student details to grant instant access to live classes and study materials.
            </p>

            {studentAddedSuccess ? (
              <div className="bg-emerald-50 border border-emerald-200 rounded-xl p-4 text-center">
                <CheckCircle2 className="w-8 h-8 text-emerald-600 mx-auto mb-2" />
                <h4 className="text-sm font-bold text-emerald-900">Student Enrolled Successfully!</h4>
                <p className="text-xs text-emerald-700 mt-1">
                  Invitation link sent to {studentEmailInput}. Enrolled in {studentBatchInput}.
                </p>
                <button
                  onClick={() => {
                    setAddStudentModalOpen(false);
                    setStudentAddedSuccess(false);
                    setStudentNameInput('');
                    setStudentEmailInput('');
                    setStudentPhoneInput('');
                  }}
                  className="mt-4 px-4 py-2 text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-700 rounded-lg"
                >
                  Done
                </button>
              </div>
            ) : (
              <form onSubmit={handleAddStudent} className="space-y-3 text-xs">
                <div>
                  <label className="block font-bold text-slate-700 mb-1">Student Full Name</label>
                  <input
                    required
                    type="text"
                    value={studentNameInput}
                    onChange={(e) => setStudentNameInput(e.target.value)}
                    placeholder="e.g. Vikram Singh"
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-lg focus:ring-2 focus:ring-indigo-500 text-slate-900"
                  />
                </div>

                <div>
                  <label className="block font-bold text-slate-700 mb-1">Registered Email Address</label>
                  <input
                    required
                    type="email"
                    value={studentEmailInput}
                    onChange={(e) => setStudentEmailInput(e.target.value)}
                    placeholder="e.g. vikram.singh@student.classora.com"
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-lg focus:ring-2 focus:ring-indigo-500 text-slate-900"
                  />
                </div>

                <div>
                  <label className="block font-bold text-slate-700 mb-1">Mobile Phone Number</label>
                  <input
                    type="tel"
                    value={studentPhoneInput}
                    onChange={(e) => setStudentPhoneInput(e.target.value)}
                    placeholder="+91 98765 00000"
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-lg focus:ring-2 focus:ring-indigo-500 text-slate-900"
                  />
                </div>

                <div>
                  <label className="block font-bold text-slate-700 mb-1">Target Batch</label>
                  <select
                    value={studentBatchInput}
                    onChange={(e) => setStudentBatchInput(e.target.value)}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-lg focus:ring-2 focus:ring-indigo-500 text-slate-900 font-medium"
                  >
                    <option>JEE Super 30 (Batch Alpha)</option>
                    <option>NEET Medical Achievers (Batch Beta)</option>
                    <option>Class 11th Foundation Physics</option>
                  </select>
                </div>

                <div className="flex justify-end space-x-2 pt-3">
                  <button
                    type="button"
                    onClick={() => setAddStudentModalOpen(false)}
                    className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    className="px-4 py-2 font-bold text-white bg-emerald-600 hover:bg-emerald-700 rounded-lg shadow-sm"
                  >
                    Enroll Student Now
                  </button>
                </div>
              </form>
            )}
          </div>
        </div>
      )}

      {/* Native Mobile Bottom Navigation Bar for Teacher */}
      <div className="lg:hidden fixed bottom-0 left-0 right-0 bg-white/95 backdrop-blur-lg border-t border-slate-200 px-2 py-1.5 flex items-center justify-around z-40 shadow-lg pb-safe">
        <button
          onClick={() => setActiveTab('home')}
          className={`flex flex-col items-center py-1 px-2.5 rounded-xl transition-all ${
            activeTab === 'home' ? 'text-indigo-600 font-bold scale-105' : 'text-slate-500 font-medium'
          }`}
        >
          <BookOpen className="w-5 h-5 mb-0.5" />
          <span className="text-[10px]">Home</span>
        </button>
        <button
          onClick={() => setActiveTab('my-classes')}
          className={`flex flex-col items-center py-1 px-2.5 rounded-xl transition-all ${
            activeTab === 'my-classes' ? 'text-indigo-600 font-bold scale-105' : 'text-slate-500 font-medium'
          }`}
        >
          <Calendar className="w-5 h-5 mb-0.5" />
          <span className="text-[10px]">Classes</span>
        </button>
        <button
          onClick={() => setActiveTab('notes')}
          className={`flex flex-col items-center py-1 px-2.5 rounded-xl transition-all ${
            activeTab === 'notes' ? 'text-indigo-600 font-bold scale-105' : 'text-slate-500 font-medium'
          }`}
        >
          <FileText className="w-5 h-5 mb-0.5" />
          <span className="text-[10px]">Notes</span>
        </button>
        <button
          onClick={() => {
            setActiveTab('add-students');
            setAddStudentModalOpen(true);
          }}
          className={`flex flex-col items-center py-1 px-2.5 rounded-xl transition-all ${
            activeTab === 'add-students' ? 'text-emerald-600 font-bold scale-105' : 'text-slate-500 font-medium'
          }`}
        >
          <UserPlus className="w-5 h-5 mb-0.5" />
          <span className="text-[10px]">+Enroll</span>
        </button>
        <button
          onClick={() => setActiveTab('profile')}
          className={`flex flex-col items-center py-1 px-2.5 rounded-xl transition-all ${
            activeTab === 'profile' ? 'text-indigo-600 font-bold scale-105' : 'text-slate-500 font-medium'
          }`}
        >
          <User className="w-5 h-5 mb-0.5" />
          <span className="text-[10px]">Profile</span>
        </button>
      </div>
    </div>
  );
};
