import React, { useState } from 'react';
import {
  BookOpen,
  Video,
  Calendar,
  Clock,
  Play,
  Download,
  CheckCircle2,
  ChevronRight,
  Search,
  Star,
  User,
  GraduationCap,
  Sparkles,
  LogOut,
  Mail,
  Phone,
  Shield,
  FileText,
  Radio,
  Book,
  File,
  Layers,
  Award,
} from 'lucide-react';
import { initialCourses, initialLiveClasses } from '../../../../api/src/mockData.js';
import { LiveClassroom } from '../../components/classroom/LiveClassroom.js';
import { DocumentViewer, samplePhysicsDocument } from '../../components/document/DocumentViewer.js';
import { useMobileNavigation } from '../../hooks/useMobileNavigation.js';

interface StudentDashboardProps {
  userSession?: any;
  onLogout?: () => void;
}

export const StudentDashboard: React.FC<StudentDashboardProps> = ({ userSession, onLogout }) => {
  // Main Navigation Tabs: 'home' | 'my-learning' | 'profile'
  const [activeTab, setActiveTab] = useState<'home' | 'my-learning' | 'profile'>('home');

  // Sub-tabs in My Learning (Bifurcated Sections - Homework & Online Tests removed as requested)
  const [learningSection, setLearningSection] = useState<'live' | 'courses' | 'notes' | 'recordings'>('live');

  // Live Class State
  const [isInLiveClass, setIsInLiveClass] = useState(false);

  // Active PPT Viewer Toggle inside Notes tab
  const [activePdfViewerDoc, setActivePdfViewerDoc] = useState<any | null>(null);

  // Mobile Back & Gesture Navigation Handler
  useMobileNavigation({
    onBack: () => {
      if (activePdfViewerDoc) {
        setActivePdfViewerDoc(null);
      } else if (isInLiveClass) {
        setIsInLiveClass(false);
      } else if (activeTab !== 'home') {
        setActiveTab('home');
      }
    },
    enabled: isInLiveClass || activePdfViewerDoc !== null || activeTab !== 'home',
  });

  // Filter for Courses
  const [selectedSubjectFilter, setSelectedSubjectFilter] = useState<string>('all');
  const [searchQuery, setSearchQuery] = useState('');

  // Student Profile Data
  const studentProfile = {
    name: userSession?.name || 'Aarav Patel',
    email: userSession?.email || 'aarav.patel@student.classora.com',
    batch: userSession?.batchOrDept || 'Class 12th JEE Masterclass',
    studentId: 'APX-2025-042',
    phone: '+91 98765 43210',
    attendance: '96.4%',
    rank: '#1 / 32 in Physics Batch',
    joinDate: 'August 2025',
  };

  // Real File Download Handler for PDFs and Study Notes
  const handleDownloadPdf = (title: string) => {
    const fileTextContent = `====================================================
CLASSORA ACADEMIC STUDY NOTES & LECTURE SUMMARY
====================================================
Title: ${title}
Course: Class 12th IIT-JEE & Medical Academy
Student: ${studentProfile.name} (${studentProfile.studentId})
Downloaded On: ${new Date().toLocaleString()}

----------------------------------------------------
CHAPTER SYLLABUS & CORE FORMULAS:
----------------------------------------------------
1. Rotational Dynamics: Torque (τ) = I * α
2. Work-Energy Theorem: W_rot = ∫ τ dθ = ΔK_rot
3. Angular Momentum Conservation: L = I * ω
4. Pure Rolling Condition: v_cm = R * ω

Downloaded from Classora Learning Portal.`;

    const blob = new Blob([fileTextContent], { type: 'text/plain;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const downloadAnchor = document.createElement('a');
    downloadAnchor.href = url;
    downloadAnchor.download = `${title.replace(/[^a-zA-Z0-9]/g, '_')}_Notes.txt`;
    document.body.appendChild(downloadAnchor);
    downloadAnchor.click();
    document.body.removeChild(downloadAnchor);
    URL.revokeObjectURL(url);
  };

  // Comprehensive Study Notes & PPT Presentation Material List
  const studyNotesList = [
    {
      id: 'note-01',
      title: 'Rotational Dynamics & Torque Master PPT Presentation Slide Deck',
      subject: 'Physics',
      chapter: 'Chapter 01 - Rotational Motion',
      author: 'Prof. Rajesh Sharma',
      fileSize: '5 Slides (Interactive Deck)',
      type: 'PPT Presentation',
      isPptDeck: true,
    },
    {
      id: 'note-02',
      title: 'Rotational Dynamics Complete Formulas & Theory PDF',
      subject: 'Physics',
      chapter: 'Chapter 01 - Rotational Motion',
      author: 'Prof. Rajesh Sharma',
      fileSize: '4.8 MB',
      type: 'PDF Document',
      isPptDeck: false,
    },
    {
      id: 'note-03',
      title: 'Thermodynamics & Heat Capacity Blackboard Lecture Notes',
      subject: 'Chemistry',
      chapter: 'Chapter 02 - Physical Chemistry',
      author: 'Dr. A. K. Gupta',
      fileSize: '3.2 MB',
      type: 'Whiteboard PDF',
      isPptDeck: false,
    },
    {
      id: 'note-04',
      title: 'Calculus & Vectors Problem Solving Workbook',
      subject: 'Mathematics',
      chapter: 'Chapter 04 - Integral Calculus',
      author: 'Prof. Sunita Verma',
      fileSize: '6.1 MB',
      type: 'Practice PDF',
      isPptDeck: false,
    },
  ];

  // Featured Courses by Top Educators
  const teacherCoursesList = [
    {
      id: 'tc-01',
      title: 'IIT-JEE Physics: Rotational & Fluid Dynamics',
      teacherName: 'Prof. Rajesh Sharma',
      teacherDept: 'Senior Physics Faculty (Ex-IIT Delhi)',
      rating: 4.9,
      studentsCount: '1,240 Enrolled',
      subject: 'Physics',
      cover: 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=600&h=300&fit=crop',
      avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop',
      price: '₹14,999',
    },
    {
      id: 'tc-02',
      title: 'Organic Chemistry & Reaction Mechanisms',
      teacherName: 'Dr. A. K. Gupta',
      teacherDept: 'Head of Chemistry (Ph.D. Organic Chemistry)',
      rating: 4.8,
      studentsCount: '980 Enrolled',
      subject: 'Chemistry',
      cover: 'https://images.unsplash.com/photo-1532187863486-abf9dbad1b69?w=600&h=300&fit=crop',
      avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&h=100&fit=crop',
      price: '₹12,499',
    },
    {
      id: 'tc-03',
      title: 'Advanced Calculus & Vectors for JEE Mains & Adv',
      teacherName: 'Prof. Sunita Verma',
      teacherDept: 'Mathematics Specialist (M.Sc. Gold Medalist)',
      rating: 4.9,
      studentsCount: '1,450 Enrolled',
      subject: 'Mathematics',
      cover: 'https://images.unsplash.com/photo-1509228468518-180dd4864904?w=600&h=300&fit=crop',
      avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=100&h=100&fit=crop',
      price: '₹15,999',
    },
    {
      id: 'tc-04',
      title: 'NEET Biology Masterclass: Human Physiology',
      teacherName: 'Dr. Meenakshi Rao',
      teacherDept: 'Medical Sciences Educator (MBBS)',
      rating: 4.9,
      studentsCount: '1,890 Enrolled',
      subject: 'Biology',
      cover: 'https://images.unsplash.com/photo-1530026405186-ed1f139313f8?w=600&h=300&fit=crop',
      avatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100&h=100&fit=crop',
      price: '₹13,999',
    },
  ];

  if (isInLiveClass) {
    return (
      <LiveClassroom
        role="student"
        userName={studentProfile.name}
        onExit={() => setIsInLiveClass(false)}
      />
    );
  }

  const filteredCourses = teacherCoursesList.filter((c) => {
    const matchesSubject = selectedSubjectFilter === 'all' || c.subject.toLowerCase() === selectedSubjectFilter.toLowerCase();
    const matchesQuery = c.title.toLowerCase().includes(searchQuery.toLowerCase()) || c.teacherName.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesSubject && matchesQuery;
  });

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 flex flex-col font-sans">
      {/* Top Navigation Header */}
      <header className="h-16 bg-white border-b border-slate-200 px-3 sm:px-6 flex items-center justify-between shrink-0 shadow-subtle sticky top-0 z-40 pt-safe">
        <div className="flex items-center space-x-3 sm:space-x-6">
          <div className="flex items-center space-x-2 cursor-pointer" onClick={() => setActiveTab('home')}>
            <div className="w-8 h-8 rounded-xl bg-indigo-600 text-white flex items-center justify-center font-black text-sm shadow-sm">
              C
            </div>
            <span className="text-base font-extrabold text-slate-900 tracking-tight">CLASSORA</span>
          </div>

          {/* Navigation Tabs (Desktop / Tablet) */}
          <nav className="hidden md:flex items-center space-x-1 bg-slate-100 p-1 rounded-xl border border-slate-200">
            <button
              onClick={() => setActiveTab('home')}
              className={`flex items-center space-x-2 px-4 py-1.5 rounded-lg text-xs font-bold transition-all ${
                activeTab === 'home'
                  ? 'bg-white text-indigo-700 shadow-sm'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              <BookOpen className="w-3.5 h-3.5" />
              <span>Home</span>
            </button>

            <button
              onClick={() => setActiveTab('my-learning')}
              className={`flex items-center space-x-2 px-4 py-1.5 rounded-lg text-xs font-bold transition-all ${
                activeTab === 'my-learning'
                  ? 'bg-white text-indigo-700 shadow-sm'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              <Layers className="w-3.5 h-3.5" />
              <span>My Learning Hub</span>
            </button>

            <button
              onClick={() => setActiveTab('profile')}
              className={`flex items-center space-x-2 px-4 py-1.5 rounded-lg text-xs font-bold transition-all ${
                activeTab === 'profile'
                  ? 'bg-white text-indigo-700 shadow-sm'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              <User className="w-3.5 h-3.5" />
              <span>Student Profile</span>
            </button>
          </nav>
        </div>

        {/* Live CTA & User */}
        <div className="flex items-center space-x-2 sm:space-x-4">
          <button
            onClick={() => setIsInLiveClass(true)}
            className="inline-flex items-center space-x-1.5 sm:space-x-2 px-3 sm:px-4 py-1.5 sm:py-2 text-xs font-bold text-white bg-rose-600 hover:bg-rose-700 active:bg-rose-800 rounded-xl shadow-md transition-all active:scale-95"
          >
            <span className="w-2 h-2 rounded-full bg-white animate-pulse" />
            <span className="hidden sm:inline">Join Live Class Now</span>
            <span className="sm:hidden">Join Live</span>
          </button>

          <div className="flex items-center space-x-2 sm:space-x-3 pl-2 sm:pl-3 border-l border-slate-200">
            <div className="flex items-center space-x-2">
              <img
                src="https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=100&h=100&fit=crop"
                alt="Profile"
                className="w-7 h-7 sm:w-8 sm:h-8 rounded-full border border-slate-200"
              />
              <div className="hidden lg:block">
                <span className="text-xs font-bold text-slate-900 block">{studentProfile.name}</span>
                <span className="text-[10px] text-slate-500 block">Class 12th JEE</span>
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

      {/* Main Container */}
      <main className="flex-1 p-3 sm:p-6 max-w-7xl w-full mx-auto space-y-6 pb-24 md:pb-8">
        {/* ==================== HOME TAB ==================== */}
        {activeTab === 'home' && (
          <div className="space-y-8">
            {/* HERO BANNER SECTION */}
            <div className="relative rounded-3xl bg-gradient-to-r from-indigo-900 via-indigo-800 to-purple-900 text-white p-8 sm:p-10 shadow-xl overflow-hidden">
              <div className="absolute right-0 top-0 bottom-0 w-1/2 bg-[url('https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=800&fit=crop')] bg-cover bg-center opacity-15 mix-blend-overlay pointer-events-none" />
              <div className="relative z-10 max-w-2xl space-y-4">
                <div className="inline-flex items-center space-x-2 bg-rose-500/30 border border-rose-400/40 px-3 py-1 rounded-full text-xs font-bold tracking-wide">
                  <span className="w-2 h-2 rounded-full bg-rose-400 animate-ping"></span>
                  <span>LIVE NOW: Physics Angular Momentum & Rolling Motion</span>
                </div>
                <h1 className="text-2xl sm:text-4xl font-black tracking-tight leading-tight">
                  Accelerate Your Rank in JEE & NEET with Live Whiteboard Masterclasses
                </h1>
                <p className="text-xs sm:text-sm text-indigo-100 leading-relaxed">
                  Learn directly from India’s top educators, download high-res blackboard notes, and clear doubts in real time.
                </p>

                {/* Hero Search & Join CTA */}
                <div className="pt-2 flex flex-col sm:flex-row items-stretch sm:items-center gap-3">
                  <div className="relative flex-1">
                    <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                    <input
                      type="text"
                      value={searchQuery}
                      onChange={(e) => setSearchQuery(e.target.value)}
                      placeholder="Search by topic, chapter, or teacher name..."
                      className="w-full text-xs pl-10 pr-4 py-3 bg-white text-slate-900 rounded-xl font-medium focus:outline-none focus:ring-2 focus:ring-indigo-400 shadow-sm"
                    />
                  </div>
                  <button
                    onClick={() => setIsInLiveClass(true)}
                    className="px-6 py-3 text-xs font-bold text-slate-900 bg-white hover:bg-indigo-50 rounded-xl shadow-lg flex items-center justify-center space-x-2 transition-all shrink-0"
                  >
                    <Play className="w-4 h-4 fill-current text-indigo-600" />
                    <span>Enter Live Classroom</span>
                  </button>
                </div>
              </div>
            </div>

            {/* QUICK STATS BAR */}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-card flex items-center space-x-3">
                <div className="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center shrink-0">
                  <CheckCircle2 className="w-5 h-5" />
                </div>
                <div>
                  <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Attendance</span>
                  <span className="text-sm font-black text-slate-900">{studentProfile.attendance}</span>
                </div>
              </div>

              <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-card flex items-center space-x-3">
                <div className="w-10 h-10 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center shrink-0">
                  <BookOpen className="w-5 h-5" />
                </div>
                <div>
                  <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Active Courses</span>
                  <span className="text-sm font-black text-slate-900">3 Courses Enrolled</span>
                </div>
              </div>

              <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-card flex items-center space-x-3">
                <div className="w-10 h-10 rounded-xl bg-purple-50 text-purple-600 flex items-center justify-center shrink-0">
                  <Award className="w-5 h-5" />
                </div>
                <div>
                  <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Institute Rank</span>
                  <span className="text-sm font-black text-slate-900">{studentProfile.rank}</span>
                </div>
              </div>
            </div>

            {/* TODAY'S CLASS SCHEDULE */}
            <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-base font-bold text-slate-900 flex items-center space-x-2">
                  <Clock className="w-5 h-5 text-indigo-600" />
                  <span>Today's Live Timetable</span>
                </h3>
                <span className="text-xs font-bold text-indigo-600 bg-indigo-50 px-3 py-1 rounded-full">
                  2 Classes Today
                </span>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="p-4 rounded-xl border border-indigo-200 bg-indigo-50/50 flex flex-col justify-between space-y-3">
                  <div>
                    <div className="flex items-center justify-between mb-1">
                      <span className="text-xs font-bold text-rose-600 bg-rose-100 px-2.5 py-0.5 rounded flex items-center">
                        <span className="w-1.5 h-1.5 rounded-full bg-rose-500 animate-ping mr-1.5"></span>
                        LIVE NOW (18:30 - 20:00)
                      </span>
                      <span className="text-xs text-slate-500 font-bold">Physics &bull; Ch 01</span>
                    </div>
                    <h4 className="text-sm font-bold text-slate-900 mt-2">Rotational Dynamics & Torque</h4>
                    <p className="text-xs text-slate-600">Prof. Rajesh Sharma &bull; Interactive Whiteboard</p>
                  </div>
                  <button
                    onClick={() => setIsInLiveClass(true)}
                    className="w-full py-2.5 text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg shadow-sm flex items-center justify-center space-x-1.5"
                  >
                    <Play className="w-3.5 h-3.5 fill-current" />
                    <span>Enter Live Classroom</span>
                  </button>
                </div>

                <div className="p-4 rounded-xl border border-slate-200 bg-slate-50 flex flex-col justify-between space-y-3">
                  <div>
                    <div className="flex items-center justify-between mb-1">
                      <span className="text-xs font-bold text-emerald-700 bg-emerald-100 px-2.5 py-0.5 rounded">
                        TOMORROW (10:00 AM)
                      </span>
                      <span className="text-xs text-slate-500 font-bold">Chemistry &bull; Ch 02</span>
                    </div>
                    <h4 className="text-sm font-bold text-slate-900 mt-2">Thermodynamics & Heat Capacity</h4>
                    <p className="text-xs text-slate-600">Dr. A. K. Gupta &bull; Physical Chemistry</p>
                  </div>
                  <button
                    disabled
                    className="w-full py-2.5 text-xs font-bold text-slate-400 bg-slate-200 rounded-lg cursor-not-allowed text-center"
                  >
                    Class Starts Tomorrow
                  </button>
                </div>
              </div>
            </div>

            {/* COURSES FROM DIFFERENT TEACHERS */}
            <div>
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-4">
                <div>
                  <h2 className="text-lg font-black text-slate-900">Explore Courses by Top Educators</h2>
                  <p className="text-xs text-slate-500">Learn from expert faculties across Physics, Chemistry, Maths & Biology.</p>
                </div>

                {/* Subject Filter Pills */}
                <div className="flex items-center space-x-1 bg-white p-1 rounded-xl border border-slate-200 shadow-subtle text-xs font-bold overflow-x-auto max-w-full">
                  {(['all', 'Physics', 'Chemistry', 'Mathematics', 'Biology'] as string[]).map((subj) => (
                    <button
                      key={subj}
                      onClick={() => setSelectedSubjectFilter(subj)}
                      className={`px-3 py-1 rounded-lg capitalize whitespace-nowrap shrink-0 transition-all ${
                        selectedSubjectFilter === subj
                          ? 'bg-indigo-600 text-white shadow-xs'
                          : 'text-slate-600 hover:text-slate-900'
                      }`}
                    >
                      {subj}
                    </button>
                  ))}
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                {filteredCourses.map((course) => (
                  <div
                    key={course.id}
                    className="bg-white rounded-2xl border border-slate-200 shadow-card hover:shadow-elevated transition-all overflow-hidden flex flex-col"
                  >
                    <div className="relative h-40 bg-slate-100 overflow-hidden">
                      <img src={course.cover} alt={course.title} className="w-full h-full object-cover" />
                      <span className="absolute top-3 left-3 bg-slate-900/80 backdrop-blur-xs text-white text-[10px] font-bold px-2.5 py-0.5 rounded-full">
                        {course.subject}
                      </span>
                      <div className="absolute top-3 right-3 bg-white text-slate-900 text-xs font-extrabold px-2.5 py-0.5 rounded-lg shadow-sm">
                        {course.price}
                      </div>
                    </div>

                    <div className="p-4 flex-1 flex flex-col justify-between space-y-3">
                      <div>
                        <h3 className="text-sm font-extrabold text-slate-900 line-clamp-2 leading-snug">
                          {course.title}
                        </h3>
                        {/* Teacher details */}
                        <div className="flex items-center space-x-2.5 mt-3 pt-3 border-t border-slate-100">
                          <img
                            src={course.avatar}
                            alt={course.teacherName}
                            className="w-8 h-8 rounded-full border border-indigo-200"
                          />
                          <div className="overflow-hidden">
                            <h4 className="text-xs font-bold text-slate-800 truncate">{course.teacherName}</h4>
                            <p className="text-[10px] text-slate-500 truncate">{course.teacherDept}</p>
                          </div>
                        </div>
                      </div>

                      <div className="flex items-center justify-between text-xs pt-2">
                        <div className="flex items-center space-x-1 text-amber-500 font-bold">
                          <Star className="w-3.5 h-3.5 fill-current" />
                          <span>{course.rating}</span>
                        </div>
                        <button
                          onClick={() => {
                            setActiveTab('my-learning');
                            setLearningSection('courses');
                          }}
                          className="px-3 py-1.5 text-xs font-bold text-indigo-700 bg-indigo-50 hover:bg-indigo-100 rounded-lg transition-colors"
                        >
                          Enroll Now
                        </button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* ==================== MY LEARNING HUB TAB ==================== */}
        {activeTab === 'my-learning' && (
          <div className="space-y-6">
            {/* TOP BIFURCATION NAVIGATION TABS (HOMEWORK & ONLINE TESTS REMOVED) */}
            <div className="bg-white p-3 rounded-2xl border border-slate-200 shadow-card flex items-center justify-between flex-wrap gap-2">
              <div className="flex items-center space-x-1 overflow-x-auto">
                <button
                  onClick={() => setLearningSection('live')}
                  className={`flex items-center space-x-2 px-4 py-2 rounded-xl text-xs font-bold transition-all ${
                    learningSection === 'live'
                      ? 'bg-rose-600 text-white shadow-sm'
                      : 'text-slate-600 hover:bg-slate-100'
                  }`}
                >
                  <Radio className="w-3.5 h-3.5" />
                  <span>Live Classes</span>
                </button>

                <button
                  onClick={() => setLearningSection('courses')}
                  className={`flex items-center space-x-2 px-4 py-2 rounded-xl text-xs font-bold transition-all ${
                    learningSection === 'courses'
                      ? 'bg-indigo-600 text-white shadow-sm'
                      : 'text-slate-600 hover:bg-slate-100'
                  }`}
                >
                  <Book className="w-3.5 h-3.5" />
                  <span>Enrolled Courses</span>
                </button>

                <button
                  onClick={() => setLearningSection('notes')}
                  className={`flex items-center space-x-2 px-4 py-2 rounded-xl text-xs font-bold transition-all ${
                    learningSection === 'notes'
                      ? 'bg-indigo-600 text-white shadow-sm'
                      : 'text-slate-600 hover:bg-slate-100'
                  }`}
                >
                  <FileText className="w-3.5 h-3.5" />
                  <span>Study Notes & Presentation Slides</span>
                </button>

                <button
                  onClick={() => setLearningSection('recordings')}
                  className={`flex items-center space-x-2 px-4 py-2 rounded-xl text-xs font-bold transition-all ${
                    learningSection === 'recordings'
                      ? 'bg-indigo-600 text-white shadow-sm'
                      : 'text-slate-600 hover:bg-slate-100'
                  }`}
                >
                  <Video className="w-3.5 h-3.5" />
                  <span>Recorded Lectures</span>
                </button>
              </div>
            </div>

            {/* SECTION 1: LIVE CLASSES (WITH SHORT HERO SECTION) */}
            {learningSection === 'live' && (
              <div className="space-y-6">
                {/* SHORT HERO BANNER FOR LIVE CLASSES */}
                <div className="relative rounded-2xl bg-gradient-to-r from-indigo-900 via-indigo-800 to-purple-900 text-white p-6 shadow-lg overflow-hidden flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                  <div className="space-y-1 z-10">
                    <div className="inline-flex items-center space-x-2 bg-indigo-500/30 px-2.5 py-0.5 rounded-full text-[11px] font-bold text-amber-300">
                      <Sparkles className="w-3 h-3" />
                      <span>Welcome back, {studentProfile.name}! 👋</span>
                    </div>
                    <h2 className="text-xl font-black tracking-tight">{studentProfile.batch}</h2>
                    <p className="text-xs text-indigo-200">
                      Stay updated with ongoing live streams, upcoming scheduled lectures, and past sessions.
                    </p>
                  </div>

                  <button
                    onClick={() => setIsInLiveClass(true)}
                    className="px-5 py-3 text-xs font-extrabold text-indigo-950 bg-white hover:bg-indigo-50 rounded-xl shadow-md flex items-center space-x-2 shrink-0 transition-all z-10"
                  >
                    <Play className="w-4 h-4 fill-current text-rose-600" />
                    <span>Enter Live Classroom</span>
                  </button>
                </div>

                {/* LIVE LECTURES LIST CATEGORIZED */}
                <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-6 space-y-6">
                  {/* ONGOING LIVE SESSION */}
                  <div>
                    <h3 className="text-xs font-extrabold text-slate-400 uppercase tracking-wider mb-3 flex items-center space-x-2">
                      <span className="w-2 h-2 rounded-full bg-rose-500 animate-ping"></span>
                      <span>Ongoing Live Stream</span>
                    </h3>
                    {initialLiveClasses.filter(c => c.status === 'live').map((cls) => (
                      <div
                        key={cls.id}
                        className="p-5 rounded-2xl border-2 border-rose-200 bg-rose-50/40 flex flex-col sm:flex-row sm:items-center justify-between gap-4 shadow-subtle"
                      >
                        <div>
                          <div className="flex items-center space-x-2 mb-1">
                            <span className="px-2.5 py-0.5 rounded text-[10px] font-black bg-rose-600 text-white animate-pulse">
                              LIVE NOW
                            </span>
                            <span className="text-xs font-bold text-slate-700">{cls.batch_name}</span>
                          </div>
                          <h4 className="text-base font-extrabold text-slate-900 mt-1">{cls.title}</h4>
                          <p className="text-xs text-slate-600 mt-1">
                            {cls.chapter_name} &bull; Faculty: <span className="font-bold text-slate-800">{cls.teacher_name}</span>
                          </p>
                        </div>

                        <button
                          onClick={() => setIsInLiveClass(true)}
                          className="px-5 py-2.5 text-xs font-extrabold text-white bg-rose-600 hover:bg-rose-700 rounded-xl shadow-md shrink-0 flex items-center space-x-1.5"
                        >
                          <Play className="w-4 h-4 fill-current" />
                          <span>Join Live Room</span>
                        </button>
                      </div>
                    ))}
                  </div>

                  {/* UPCOMING LECTURES */}
                  <div>
                    <h3 className="text-xs font-extrabold text-slate-400 uppercase tracking-wider mb-3 flex items-center space-x-2">
                      <Clock className="w-3.5 h-3.5 text-indigo-600" />
                      <span>Upcoming Scheduled Lectures</span>
                    </h3>
                    <div className="space-y-3">
                      {initialLiveClasses.filter(c => c.status === 'scheduled').map((cls) => (
                        <div
                          key={cls.id}
                          className="p-4 rounded-xl border border-slate-200 bg-slate-50 flex flex-col sm:flex-row sm:items-center justify-between gap-4"
                        >
                          <div>
                            <div className="flex items-center space-x-2 mb-1">
                              <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-indigo-100 text-indigo-800">
                                SCHEDULED
                              </span>
                              <span className="text-xs font-semibold text-slate-500">{cls.batch_name}</span>
                            </div>
                            <h4 className="text-sm font-bold text-slate-900">{cls.title}</h4>
                            <p className="text-xs text-slate-500">{cls.chapter_name} &bull; Taught by {cls.teacher_name}</p>
                          </div>

                          <button
                            onClick={() => setIsInLiveClass(true)}
                            className="px-4 py-2 text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg shadow-sm shrink-0"
                          >
                            Join Room
                          </button>
                        </div>
                      ))}
                    </div>
                  </div>

                  {/* RECENTLY COMPLETED LECTURES */}
                  <div>
                    <h3 className="text-xs font-extrabold text-slate-400 uppercase tracking-wider mb-3 flex items-center space-x-2">
                      <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />
                      <span>Recently Completed Sessions</span>
                    </h3>
                    <div className="space-y-3">
                      {initialLiveClasses.filter(c => c.status === 'completed').map((cls) => (
                        <div
                          key={cls.id}
                          className="p-4 rounded-xl border border-slate-200 bg-slate-50/60 flex flex-col sm:flex-row sm:items-center justify-between gap-4"
                        >
                          <div>
                            <div className="flex items-center space-x-2 mb-1">
                              <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-slate-200 text-slate-700">
                                COMPLETED
                              </span>
                              <span className="text-xs font-semibold text-slate-500">{cls.batch_name}</span>
                            </div>
                            <h4 className="text-sm font-bold text-slate-900">{cls.title}</h4>
                            <p className="text-xs text-slate-500">{cls.chapter_name} &bull; Taught by {cls.teacher_name}</p>
                          </div>

                          <button
                            onClick={() => {
                              setLearningSection('notes');
                              setActivePdfViewerDoc(samplePhysicsDocument);
                            }}
                            className="px-4 py-2 text-xs font-bold text-slate-700 bg-white border border-slate-300 hover:bg-slate-50 rounded-lg shadow-sm shrink-0 flex items-center space-x-1.5"
                          >
                            <FileText className="w-3.5 h-3.5 text-indigo-600" />
                            <span>View Board Slides</span>
                          </button>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* SECTION 2: STUDY NOTES & PPT PRESENTATION SLIDES (COMBINED WITH DOWNLOADS & NEXT/PREV CONTROLS) */}
            {learningSection === 'notes' && (
              <div className="space-y-6">
                {/* ACTIVE PPT PRESENTATION VIEWER IF SELECTED */}
                {activePdfViewerDoc && (
                  <div className="space-y-3">
                    <div className="flex items-center justify-between bg-indigo-900 text-white p-4 rounded-2xl">
                      <div>
                        <span className="text-[10px] font-bold uppercase tracking-wider bg-white/20 px-2 py-0.5 rounded">
                          Interactive PPT Presentation Slide Deck
                        </span>
                        <h3 className="text-base font-bold mt-1">{activePdfViewerDoc.title}</h3>
                      </div>
                      <button
                        onClick={() => setActivePdfViewerDoc(null)}
                        className="px-3 py-1.5 text-xs font-bold text-slate-900 bg-white hover:bg-slate-100 rounded-lg"
                      >
                        Close Slide Deck
                      </button>
                    </div>

                    <DocumentViewer document={activePdfViewerDoc} onClose={() => setActivePdfViewerDoc(null)} />
                  </div>
                )}

                {/* STUDY MATERIAL & DOWNLOADABLE PDFS LIST */}
                <div className="bg-white rounded-2xl border border-slate-200 shadow-card overflow-hidden">
                  <div className="p-5 border-b border-slate-200 flex justify-between items-center">
                    <div>
                      <h3 className="text-base font-bold text-slate-900">Study Materials, Formula Sheets & Presentation Decks</h3>
                      <p className="text-xs text-slate-500">Download PDFs or view interactive PPT presentation slide decks page-by-page.</p>
                    </div>
                    <span className="text-xs font-bold text-indigo-700 bg-indigo-50 px-3 py-1 rounded-lg">
                      {studyNotesList.length} Files Available
                    </span>
                  </div>

                  <div className="divide-y divide-slate-100">
                    {studyNotesList.map((note) => (
                      <div key={note.id} className="p-5 flex flex-col sm:flex-row sm:items-center justify-between gap-4 hover:bg-slate-50 transition-colors">
                        <div className="flex items-center space-x-4">
                          <div className={`w-12 h-12 rounded-xl flex items-center justify-center shrink-0 ${
                            note.isPptDeck ? 'bg-amber-50 text-amber-600' : 'bg-indigo-50 text-indigo-600'
                          }`}>
                            {note.isPptDeck ? <File className="w-6 h-6" /> : <FileText className="w-6 h-6" />}
                          </div>
                          <div>
                            <div className="flex items-center space-x-2">
                              <span className="text-[10px] font-bold text-indigo-600 bg-indigo-50 px-2 py-0.5 rounded">
                                {note.subject} &bull; {note.chapter}
                              </span>
                              {note.isPptDeck && (
                                <span className="text-[10px] font-bold text-amber-700 bg-amber-100 px-2 py-0.5 rounded">
                                  SLIDE DECK
                                </span>
                              )}
                            </div>
                            <h4 className="text-sm font-bold text-slate-900 mt-1">{note.title}</h4>
                            <p className="text-xs text-slate-500">Prepared by {note.author} &bull; {note.fileSize}</p>
                          </div>
                        </div>

                        <div className="flex items-center space-x-3 shrink-0">
                          {note.isPptDeck ? (
                            <button
                              onClick={() => setActivePdfViewerDoc(samplePhysicsDocument)}
                              className="px-4 py-2 text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg shadow-sm flex items-center space-x-1.5"
                            >
                              <FileText className="w-4 h-4" />
                              <span>Open Slide Deck</span>
                            </button>
                          ) : (
                            <button
                              onClick={() => handleDownloadPdf(note.title)}
                              className="px-4 py-2 text-xs font-bold text-indigo-700 bg-indigo-50 hover:bg-indigo-100 rounded-lg flex items-center space-x-1.5 transition-colors"
                            >
                              <Download className="w-4 h-4" />
                              <span>Download PDF</span>
                            </button>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            )}

            {/* SECTION 3: ENROLLED COURSES */}
            {learningSection === 'courses' && (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {initialCourses.map((crs) => (
                  <div key={crs.id} className="bg-white rounded-2xl border border-slate-200 shadow-card overflow-hidden">
                    <div className="relative aspect-video bg-slate-100 overflow-hidden">
                      <img src={crs.cover_image} alt={crs.name} className="w-full h-full object-cover" />
                      <span className="absolute top-3 left-3 bg-emerald-500 text-white text-xs font-bold px-2.5 py-1 rounded-lg shadow-sm">
                        Enrolled & Active
                      </span>
                    </div>
                    <div className="p-5">
                      <h4 className="text-base font-bold text-slate-900 mb-1">{crs.name}</h4>
                      <p className="text-xs text-slate-500 mb-4">{crs.description}</p>
                      <div className="space-y-2 border-t border-slate-100 pt-3">
                        {crs.subjects[0]?.chapters.map((ch) => (
                          <div key={ch.id} className="flex items-center justify-between text-xs py-1">
                            <span className="font-semibold text-slate-700">{ch.order_index}. {ch.name}</span>
                            <button
                              onClick={() => {
                                setLearningSection('notes');
                                setActivePdfViewerDoc(samplePhysicsDocument);
                              }}
                              className="text-indigo-600 hover:text-indigo-800 font-bold flex items-center space-x-1"
                            >
                              <span>View Slides</span>
                              <ChevronRight className="w-3.5 h-3.5" />
                            </button>
                          </div>
                        ))}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}

            {/* SECTION 4: RECORDED LECTURES */}
            {learningSection === 'recordings' && (
              <div className="bg-white rounded-2xl border border-slate-200 shadow-card overflow-hidden">
                <div className="p-5 border-b border-slate-200">
                  <h3 className="text-base font-bold text-slate-900">Recorded Video Lectures & Board Notes</h3>
                  <p className="text-xs text-slate-500">Watch full recorded lectures and download high-resolution blackboard notes PDFs.</p>
                </div>
                <div className="divide-y divide-slate-100">
                  {initialLiveClasses.filter((c) => c.status === 'completed').map((rec) => (
                    <div key={rec.id} className="p-5 flex flex-col sm:flex-row sm:items-center justify-between gap-4 hover:bg-slate-50 transition-colors">
                      <div className="flex items-center space-x-4">
                        <div className="w-12 h-12 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center shrink-0">
                          <Video className="w-6 h-6" />
                        </div>
                        <div>
                          <span className="text-[10px] font-bold text-indigo-600 bg-indigo-50 px-2 py-0.5 rounded">
                            {rec.chapter_name}
                          </span>
                          <h4 className="text-sm font-bold text-slate-900 mt-1">{rec.title}</h4>
                          <p className="text-xs text-slate-500">Duration: 1h 25m &bull; Taught by {rec.teacher_name}</p>
                        </div>
                      </div>
                      <div className="flex items-center space-x-3 shrink-0">
                        <a
                          href={rec.recording_url || '#'}
                          target="_blank"
                          rel="noreferrer"
                          className="px-4 py-2 text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg shadow-sm flex items-center space-x-1.5 transition-colors"
                        >
                          <Play className="w-3.5 h-3.5 fill-current" />
                          <span>Watch Video</span>
                        </a>

                        <button
                          onClick={() => handleDownloadPdf(rec.title)}
                          className="px-4 py-2 text-xs font-bold text-slate-700 bg-slate-100 hover:bg-slate-200 rounded-lg flex items-center space-x-1.5 transition-colors"
                        >
                          <Download className="w-3.5 h-3.5 text-indigo-600" />
                          <span>Download Board PDF</span>
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        )}

        {/* ==================== PROFILE TAB ==================== */}
        {activeTab === 'profile' && (
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {/* Student Bio Card */}
            <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-6 text-center">
              <img
                src="https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=200&h=200&fit=crop"
                alt="Student"
                className="w-24 h-24 rounded-full border-2 border-indigo-500 mx-auto mb-4 p-1 shadow-md"
              />
              <h2 className="text-lg font-black text-slate-900">{studentProfile.name}</h2>
              <span className="inline-block bg-indigo-50 text-indigo-700 text-xs font-bold px-3 py-1 rounded-full border border-indigo-200 mt-1">
                {studentProfile.batch}
              </span>
              <p className="text-xs text-slate-500 mt-2">Student ID: {studentProfile.studentId}</p>

              <div className="mt-6 pt-6 border-t border-slate-100 text-left space-y-3 text-xs">
                <div className="flex items-center text-slate-600">
                  <Mail className="w-4 h-4 mr-2 text-slate-400" />
                  <span>{studentProfile.email}</span>
                </div>
                <div className="flex items-center text-slate-600">
                  <Phone className="w-4 h-4 mr-2 text-slate-400" />
                  <span>{studentProfile.phone}</span>
                </div>
                <div className="flex items-center text-slate-600">
                  <Calendar className="w-4 h-4 mr-2 text-slate-400" />
                  <span>Enrolled Since: {studentProfile.joinDate}</span>
                </div>
              </div>
            </div>

            {/* Academic Dossier */}
            <div className="md:col-span-2 space-y-6">
              <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-6">
                <h3 className="text-base font-bold text-slate-900 mb-4">Academic Performance Overview</h3>

                <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                  <div className="bg-emerald-50 border border-emerald-200 p-4 rounded-xl">
                    <span className="text-[10px] font-bold text-emerald-800 uppercase tracking-wider">Attendance Rate</span>
                    <p className="text-2xl font-black text-emerald-700 mt-1">{studentProfile.attendance}</p>
                    <p className="text-[11px] text-emerald-600 mt-1">27/28 Sessions Attended</p>
                  </div>

                  <div className="bg-indigo-50 border border-indigo-200 p-4 rounded-xl">
                    <span className="text-[10px] font-bold text-indigo-800 uppercase tracking-wider">Institute Standing</span>
                    <p className="text-2xl font-black text-indigo-700 mt-1">{studentProfile.rank}</p>
                    <p className="text-[11px] text-indigo-600 mt-1">Highest MCQ score</p>
                  </div>

                  <div className="bg-purple-50 border border-purple-200 p-4 rounded-xl">
                    <span className="text-[10px] font-bold text-purple-800 uppercase tracking-wider">Active Enrolments</span>
                    <p className="text-2xl font-black text-purple-700 mt-1">3 Courses</p>
                    <p className="text-[11px] text-purple-600 mt-1">Physics, Chem & Maths</p>
                  </div>
                </div>
              </div>

              {/* Account Security Settings */}
              <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-6">
                <h3 className="text-base font-bold text-slate-900 mb-3 flex items-center space-x-2">
                  <Shield className="w-5 h-5 text-indigo-600" />
                  <span>Account Security & Credentials</span>
                </h3>
                <div className="space-y-3 text-xs">
                  <div className="flex items-center justify-between p-3 bg-slate-50 rounded-xl border border-slate-200">
                    <div>
                      <p className="font-bold text-slate-800">2-Factor Authentication (2FA)</p>
                      <p className="text-[11px] text-slate-500">Secured via OTP to registered phone number</p>
                    </div>
                    <span className="px-2.5 py-1 bg-emerald-100 text-emerald-800 font-bold rounded-lg text-[10px]">
                      ENABLED
                    </span>
                  </div>

                  <button className="w-full py-2.5 text-xs font-bold text-slate-700 bg-slate-100 hover:bg-slate-200 rounded-xl transition-colors">
                    Update Password & Security Questions
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}
      </main>

      {/* Native Mobile Bottom Navigation Bar */}
      <div className="md:hidden fixed bottom-0 left-0 right-0 bg-white/95 backdrop-blur-lg border-t border-slate-200 px-4 py-1.5 flex items-center justify-around z-40 shadow-lg pb-safe">
        <button
          onClick={() => setActiveTab('home')}
          className={`flex flex-col items-center py-1 px-3 rounded-xl transition-all ${
            activeTab === 'home' ? 'text-indigo-600 font-bold scale-105' : 'text-slate-500 font-medium'
          }`}
        >
          <BookOpen className="w-5 h-5 mb-0.5" />
          <span className="text-[11px]">Home</span>
        </button>
        <button
          onClick={() => setActiveTab('my-learning')}
          className={`flex flex-col items-center py-1 px-3 rounded-xl transition-all ${
            activeTab === 'my-learning' ? 'text-indigo-600 font-bold scale-105' : 'text-slate-500 font-medium'
          }`}
        >
          <Layers className="w-5 h-5 mb-0.5" />
          <span className="text-[11px]">Learning</span>
        </button>
        <button
          onClick={() => setActiveTab('profile')}
          className={`flex flex-col items-center py-1 px-3 rounded-xl transition-all ${
            activeTab === 'profile' ? 'text-indigo-600 font-bold scale-105' : 'text-slate-500 font-medium'
          }`}
        >
          <User className="w-5 h-5 mb-0.5" />
          <span className="text-[11px]">Profile</span>
        </button>
      </div>
    </div>
  );
};
