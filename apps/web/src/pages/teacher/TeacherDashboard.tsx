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
} from 'lucide-react';
import { initialLiveClasses, initialAssignments, initialTests, initialUsers } from '../../../../api/src/mockData.js';
import { LiveClassroom } from '../../components/classroom/LiveClassroom.js';

export const TeacherDashboard: React.FC = () => {
  // Navigation tabs
  const [activeTab, setActiveTab] = useState<'schedule' | 'live' | 'assignments' | 'tests' | 'students'>('schedule');

  // Interactive Live Session trigger
  const [isInLiveClass, setIsInLiveClass] = useState(false);

  // Classes state
  const [classesList, setClassesList] = useState(initialLiveClasses);
  const [assignmentsList, setAssignmentsList] = useState(initialAssignments);
  const [testsList, setTestsList] = useState(initialTests);

  // New Class Modal
  const [scheduleModalOpen, setScheduleModalOpen] = useState(false);
  const [newClassTitle, setNewClassTitle] = useState('');
  const [newClassChapter, setNewClassChapter] = useState('Rotational Dynamics');
  const [newClassTime, setNewClassTime] = useState('18:30');

  // Schedule new class
  const handleScheduleClass = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newClassTitle.trim()) return;
    const newCls = {
      id: `live-${Date.now()}`,
      institute_id: 'inst-apex-01',
      batch_id: 'batch-jee-2026',
      batch_name: 'JEE Super 30 (Batch Alpha)',
      teacher_id: 'usr-teacher-01',
      teacher_name: 'Prof. Rajesh Sharma',
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

  // If teacher is currently inside the Live Class Room
  if (isInLiveClass) {
    return (
      <LiveClassroom
        role="teacher"
        userName="Prof. Rajesh Sharma"
        onExit={() => setIsInLiveClass(false)}
      />
    );
  }

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 flex font-sans">
      {/* Teacher Sidebar (Light Theme) */}
      <aside className="w-64 bg-white border-r border-slate-200 flex flex-col justify-between p-4 shadow-subtle shrink-0">
        <div>
          {/* Header */}
          <div className="flex items-center space-x-3 pb-6 border-b border-slate-100">
            <div className="w-10 h-10 rounded-xl bg-indigo-600 flex items-center justify-center text-white font-bold text-lg shadow-sm">
              T
            </div>
            <div className="overflow-hidden">
              <h2 className="text-sm font-bold text-slate-900 truncate">Prof. R. Sharma</h2>
              <span className="text-[11px] font-semibold text-indigo-600 uppercase tracking-wider block">
                Teacher Console
              </span>
            </div>
          </div>

          {/* Nav Items */}
          <nav className="mt-6 space-y-1">
            <button
              onClick={() => setActiveTab('schedule')}
              className={`w-full flex items-center space-x-3 px-3 py-2 rounded-xl text-xs font-semibold transition-colors ${
                activeTab === 'schedule'
                  ? 'bg-indigo-50 text-indigo-700'
                  : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900'
              }`}
            >
              <Calendar className="w-4 h-4" />
              <span>Classes & Schedule</span>
            </button>

            <button
              onClick={() => setActiveTab('assignments')}
              className={`w-full flex items-center space-x-3 px-3 py-2 rounded-xl text-xs font-semibold transition-colors ${
                activeTab === 'assignments'
                  ? 'bg-indigo-50 text-indigo-700'
                  : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900'
              }`}
            >
              <FileCheck className="w-4 h-4" />
              <span>Assignments & Grading</span>
            </button>

            <button
              onClick={() => setActiveTab('tests')}
              className={`w-full flex items-center space-x-3 px-3 py-2 rounded-xl text-xs font-semibold transition-colors ${
                activeTab === 'tests'
                  ? 'bg-indigo-50 text-indigo-700'
                  : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900'
              }`}
            >
              <Award className="w-4 h-4" />
              <span>Online Tests & MCQs</span>
            </button>

            <button
              onClick={() => setActiveTab('students')}
              className={`w-full flex items-center space-x-3 px-3 py-2 rounded-xl text-xs font-semibold transition-colors ${
                activeTab === 'students'
                  ? 'bg-indigo-50 text-indigo-700'
                  : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900'
              }`}
            >
              <Users className="w-4 h-4" />
              <span>My Batch Students</span>
            </button>
          </nav>
        </div>

        {/* Quick Launch Card */}
        <div className="bg-indigo-50 border border-indigo-100 rounded-xl p-3.5">
          <div className="flex items-center space-x-2 text-indigo-700 font-bold text-xs mb-1">
            <span className="w-2 h-2 rounded-full bg-rose-500 animate-ping"></span>
            <span>Live Class Ready</span>
          </div>
          <p className="text-[11px] text-slate-600 mb-3">
            JEE Super 30 session is ready to broadcast with digital whiteboard.
          </p>
          <button
            onClick={() => setIsInLiveClass(true)}
            className="w-full py-2 px-3 text-xs font-semibold text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg shadow-sm flex items-center justify-center space-x-1.5 transition-colors"
          >
            <Play className="w-3.5 h-3.5 fill-current" />
            <span>Go Live Now</span>
          </button>
        </div>
      </aside>

      {/* Main Content Area */}
      <main className="flex-1 flex flex-col h-screen overflow-y-auto">
        {/* Top Bar */}
        <header className="h-16 bg-white border-b border-slate-200 px-6 flex items-center justify-between shrink-0 shadow-subtle">
          <div>
            <h1 className="text-lg font-extrabold text-slate-900">
              {activeTab === 'schedule' && 'My Classes & Timetable'}
              {activeTab === 'assignments' && 'Assignments & Homework Grading'}
              {activeTab === 'tests' && 'Weekly Tests & Assessment Bank'}
              {activeTab === 'students' && 'Enrolled Students Progress'}
            </h1>
            <p className="text-xs text-slate-500">Apex IIT-JEE Academy &bull; Department of Physics</p>
          </div>

          <div className="flex items-center space-x-3">
            <button
              onClick={() => setScheduleModalOpen(true)}
              className="inline-flex items-center space-x-1.5 px-3.5 py-2 text-xs font-semibold text-slate-700 bg-white hover:bg-slate-50 border border-slate-300 rounded-xl shadow-subtle transition-colors"
            >
              <Plus className="w-4 h-4" />
              <span>Schedule Class</span>
            </button>
            <button
              onClick={() => setIsInLiveClass(true)}
              className="inline-flex items-center space-x-1.5 px-4 py-2 text-xs font-semibold text-white bg-indigo-600 hover:bg-indigo-700 rounded-xl shadow-md transition-colors"
            >
              <Video className="w-4 h-4" />
              <span>Start Live Class</span>
            </button>
          </div>
        </header>

        {/* Content Body */}
        <div className="p-6 space-y-6">
          {/* SCHEDULE / CLASSES TAB */}
          {activeTab === 'schedule' && (
            <div className="space-y-6">
              {/* Today's Classes Card */}
              <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-5">
                <div className="flex items-center justify-between mb-4">
                  <h3 className="text-base font-bold text-slate-900 flex items-center space-x-2">
                    <Clock className="w-4 h-4 text-indigo-600" />
                    <span>Today's Sessions</span>
                  </h3>
                  <span className="text-xs font-semibold text-indigo-600 bg-indigo-50 px-2.5 py-0.5 rounded-full">
                    {classesList.length} Scheduled
                  </span>
                </div>

                <div className="space-y-3">
                  {classesList.map((cls) => (
                    <div
                      key={cls.id}
                      className="p-4 rounded-xl border border-slate-200 bg-slate-50/50 hover:bg-slate-50 flex flex-col sm:flex-row sm:items-center justify-between gap-4 transition-all"
                    >
                      <div>
                        <div className="flex items-center space-x-2 mb-1">
                          <span
                            className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                              cls.status === 'live'
                                ? 'bg-rose-100 text-rose-700 animate-pulse'
                                : cls.status === 'completed'
                                ? 'bg-slate-200 text-slate-700'
                                : 'bg-emerald-100 text-emerald-800'
                            }`}
                          >
                            {cls.status === 'live' ? 'LIVE NOW' : cls.status.toUpperCase()}
                          </span>
                          <span className="text-xs font-semibold text-slate-500">
                            {cls.batch_name}
                          </span>
                        </div>
                        <h4 className="text-sm font-bold text-slate-900">{cls.title}</h4>
                        <p className="text-xs text-slate-500">
                          {cls.chapter_name} &bull; Room: {cls.room_id}
                        </p>
                      </div>

                      <div className="flex items-center space-x-3">
                        {cls.status === 'live' || cls.status === 'scheduled' ? (
                          <button
                            onClick={() => setIsInLiveClass(true)}
                            className="px-4 py-2 text-xs font-semibold text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg shadow-sm flex items-center space-x-1.5"
                          >
                            <Play className="w-3.5 h-3.5 fill-current" />
                            <span>Launch Live Console</span>
                          </button>
                        ) : (
                          <a
                            href={cls.recording_url}
                            target="_blank"
                            rel="noreferrer"
                            className="px-3.5 py-1.5 text-xs font-semibold text-slate-700 bg-white hover:bg-slate-50 border border-slate-300 rounded-lg flex items-center space-x-1"
                          >
                            <Video className="w-3.5 h-3.5 text-indigo-600" />
                            <span>Watch Recording</span>
                          </a>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Quick Teacher Metrics */}
              <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
                <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-5">
                  <span className="text-xs font-semibold text-slate-500">Total Classes Taught</span>
                  <div className="text-2xl font-extrabold text-slate-900 mt-1">128 Lectures</div>
                  <p className="text-[11px] text-slate-500 mt-1">192 hours of synced whiteboard notes</p>
                </div>
                <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-5">
                  <span className="text-xs font-semibold text-slate-500">Pending Homework Grading</span>
                  <div className="text-2xl font-extrabold text-amber-600 mt-1">17 Submissions</div>
                  <p className="text-[11px] text-slate-500 mt-1">Batch: JEE Super 30</p>
                </div>
                <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-5">
                  <span className="text-xs font-semibold text-slate-500">Avg Class Attendance</span>
                  <div className="text-2xl font-extrabold text-emerald-600 mt-1">94.8%</div>
                  <p className="text-[11px] text-slate-500 mt-1">32 active students present</p>
                </div>
              </div>
            </div>
          )}

          {/* ASSIGNMENTS TAB */}
          {activeTab === 'assignments' && (
            <div className="bg-white rounded-2xl border border-slate-200 shadow-card overflow-hidden">
              <div className="p-5 border-b border-slate-200 flex items-center justify-between">
                <div>
                  <h3 className="text-base font-bold text-slate-900">Homework & Assignment Tracker</h3>
                  <p className="text-xs text-slate-500">Distribute problem sheets, grade student submissions, and record marks.</p>
                </div>
                <button className="inline-flex items-center space-x-1.5 px-3.5 py-2 text-xs font-semibold text-white bg-indigo-600 hover:bg-indigo-700 rounded-xl shadow-sm">
                  <Plus className="w-4 h-4" />
                  <span>Create Assignment</span>
                </button>
              </div>

              <div className="divide-y divide-slate-100">
                {assignmentsList.map((asg) => (
                  <div key={asg.id} className="p-5 flex flex-col sm:flex-row sm:items-center justify-between gap-4 hover:bg-slate-50 transition-colors">
                    <div>
                      <div className="flex items-center space-x-2 mb-1">
                        <span className="text-xs font-semibold text-indigo-600 bg-indigo-50 px-2.5 py-0.5 rounded">
                          {asg.chapter_name}
                        </span>
                        <span className="text-xs text-slate-400">Due: Sep 12, 2026</span>
                      </div>
                      <h4 className="text-sm font-bold text-slate-900">{asg.title}</h4>
                      <p className="text-xs text-slate-500 mt-1">{asg.description}</p>
                    </div>

                    <div className="flex items-center space-x-4">
                      <div className="text-right">
                        <p className="text-xs font-bold text-slate-800">{asg.total_submissions} Submitted</p>
                        <p className="text-[10px] text-amber-600 font-semibold">{asg.pending_grading} Need Grading</p>
                      </div>
                      <button className="px-3.5 py-2 text-xs font-semibold text-indigo-600 bg-indigo-50 hover:bg-indigo-100 rounded-lg transition-colors">
                        Review & Grade
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* TESTS TAB */}
          {activeTab === 'tests' && (
            <div className="bg-white rounded-2xl border border-slate-200 shadow-card overflow-hidden">
              <div className="p-5 border-b border-slate-200 flex items-center justify-between">
                <div>
                  <h3 className="text-base font-bold text-slate-900">Online Assessment & Question Bank</h3>
                  <p className="text-xs text-slate-500">Timed MCQ tests with negative marking and instant leaderboards.</p>
                </div>
                <button className="inline-flex items-center space-x-1.5 px-3.5 py-2 text-xs font-semibold text-white bg-indigo-600 hover:bg-indigo-700 rounded-xl shadow-sm">
                  <Plus className="w-4 h-4" />
                  <span>Build New Test</span>
                </button>
              </div>

              <div className="p-5 space-y-4">
                {testsList.map((test) => (
                  <div key={test.id} className="p-4 rounded-xl border border-slate-200 bg-slate-50">
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-[10px] font-bold uppercase tracking-wider text-emerald-700 bg-emerald-100 px-2 py-0.5 rounded">
                        {test.status}
                      </span>
                      <span className="text-xs text-slate-500 font-medium">
                        Duration: {test.duration_min} Mins &bull; Total: {test.total_marks} Marks
                      </span>
                    </div>
                    <h4 className="text-sm font-bold text-slate-900 mb-1">{test.title}</h4>
                    <p className="text-xs text-slate-500 mb-3">
                      {test.subject_name} &bull; Negative Marking: -{test.negative_marking} mark per wrong answer
                    </p>
                    <div className="flex items-center space-x-3 text-xs">
                      <span className="font-semibold text-slate-700">Questions: {test.questions.length} MCQs</span>
                      <button className="font-semibold text-indigo-600 hover:text-indigo-800">
                        View Question Bank
                      </button>
                      <button className="font-semibold text-indigo-600 hover:text-indigo-800">
                        Live Leaderboard
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* STUDENTS TAB */}
          {activeTab === 'students' && (
            <div className="bg-white rounded-2xl border border-slate-200 shadow-card overflow-hidden">
              <div className="p-5 border-b border-slate-200">
                <h3 className="text-base font-bold text-slate-900">Enrolled Students (JEE Super 30)</h3>
                <p className="text-xs text-slate-500">Track individual attendance, test scores, and doubt history.</p>
              </div>
              <div className="divide-y divide-slate-100">
                {initialUsers.filter(u => u.role === 'student').map((s) => (
                  <div key={s.id} className="p-4 flex items-center justify-between hover:bg-slate-50 transition-colors">
                    <div className="flex items-center space-x-3">
                      <img src={s.avatar_url} alt="" className="w-10 h-10 rounded-full border border-slate-200" />
                      <div>
                        <p className="text-sm font-bold text-slate-900">{s.name}</p>
                        <p className="text-xs text-slate-500">{s.email}</p>
                      </div>
                    </div>
                    <div className="flex items-center space-x-4 text-xs">
                      <div className="text-right">
                        <span className="font-bold text-slate-800 block">Attendance: 96%</span>
                        <span className="text-[10px] text-emerald-600 font-semibold">Test Rank #1</span>
                      </div>
                      <button className="px-3 py-1.5 font-semibold text-slate-700 bg-slate-100 hover:bg-slate-200 rounded-lg">
                        Performance Dossier
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      </main>

      {/* Schedule Class Modal */}
      {scheduleModalOpen && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl shadow-elevated border border-slate-200 p-6 max-w-md w-full">
            <h3 className="text-base font-bold text-slate-900 mb-1">Schedule Live Class</h3>
            <p className="text-xs text-slate-500 mb-4">Set up a real-time classroom with integrated digital whiteboard.</p>
            <form onSubmit={handleScheduleClass} className="space-y-3 text-xs">
              <div>
                <label className="block font-semibold text-slate-700 mb-1">Class Topic / Lecture Title</label>
                <input
                  required
                  value={newClassTitle}
                  onChange={(e) => setNewClassTitle(e.target.value)}
                  placeholder="e.g. Rolling Motion & Conservation of Angular Momentum"
                  className="w-full p-2.5 border border-slate-200 rounded-lg focus:ring-2 focus:ring-indigo-500"
                />
              </div>
              <div>
                <label className="block font-semibold text-slate-700 mb-1">Chapter / Unit</label>
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
    </div>
  );
};
