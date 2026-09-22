import React, { useState } from 'react';
import {
  BookOpen,
  Video,
  FileCheck,
  Award,
  CreditCard,
  Calendar,
  Clock,
  Play,
  Download,
  Upload,
  CheckCircle2,
  AlertCircle,
  ChevronRight,
  ExternalLink,
  Timer,
  Check,
  ShieldCheck,
} from 'lucide-react';
import { initialCourses, initialLiveClasses, initialAssignments, initialTests, initialFeePlans, initialFeeTransactions } from '../../../../api/src/mockData.js';
import { LiveClassroom } from '../../components/classroom/LiveClassroom.js';

export const StudentDashboard: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'home' | 'courses' | 'recordings' | 'assignments' | 'tests' | 'fees'>('home');

  // Live Class Viewer state
  const [isInLiveClass, setIsInLiveClass] = useState(false);

  // Test Engine state
  const [activeTestAttempt, setActiveTestAttempt] = useState<any | null>(null);
  const [selectedAnswers, setSelectedAnswers] = useState<Record<string, string>>({});
  const [testSubmitted, setTestSubmitted] = useState(false);

  // Fee Checkout Modal
  const [feeModalOpen, setFeeModalOpen] = useState(false);
  const [paymentSuccess, setPaymentSuccess] = useState(false);

  // Assignment submission modal
  const [asgModalOpen, setAsgModalOpen] = useState(false);
  const [asgFileUploaded, setAsgFileUploaded] = useState(false);

  // If student is currently attending the live class
  if (isInLiveClass) {
    return (
      <LiveClassroom
        role="student"
        userName="Aarav Patel"
        onExit={() => setIsInLiveClass(false)}
      />
    );
  }

  // Handle Online Test submission
  const handleTestSubmit = () => {
    setTestSubmitted(true);
  };

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 flex font-sans">
      {/* Student Sidebar (Light Theme) */}
      <aside className="w-64 bg-white border-r border-slate-200 flex flex-col justify-between p-4 shadow-subtle shrink-0">
        <div>
          {/* Header */}
          <div className="flex items-center space-x-3 pb-6 border-b border-slate-100">
            <img
              src="https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=100&h=100&fit=crop"
              alt="Student"
              className="w-10 h-10 rounded-full border border-slate-200"
            />
            <div className="overflow-hidden">
              <h2 className="text-sm font-bold text-slate-900 truncate">Aarav Patel</h2>
              <span className="text-[11px] font-semibold text-indigo-600 uppercase tracking-wider block">
                Class 12th JEE
              </span>
            </div>
          </div>

          {/* Nav Items */}
          <nav className="mt-6 space-y-1">
            <button
              onClick={() => { setActiveTab('home'); setActiveTestAttempt(null); }}
              className={`w-full flex items-center space-x-3 px-3 py-2 rounded-xl text-xs font-semibold transition-colors ${
                activeTab === 'home'
                  ? 'bg-indigo-50 text-indigo-700'
                  : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900'
              }`}
            >
              <BookOpen className="w-4 h-4" />
              <span>Today's Classes & Home</span>
            </button>

            <button
              onClick={() => { setActiveTab('courses'); setActiveTestAttempt(null); }}
              className={`w-full flex items-center space-x-3 px-3 py-2 rounded-xl text-xs font-semibold transition-colors ${
                activeTab === 'courses'
                  ? 'bg-indigo-50 text-indigo-700'
                  : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900'
              }`}
            >
              <BookOpen className="w-4 h-4" />
              <span>My Enrolled Courses</span>
            </button>

            <button
              onClick={() => { setActiveTab('recordings'); setActiveTestAttempt(null); }}
              className={`w-full flex items-center space-x-3 px-3 py-2 rounded-xl text-xs font-semibold transition-colors ${
                activeTab === 'recordings'
                  ? 'bg-indigo-50 text-indigo-700'
                  : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900'
              }`}
            >
              <Video className="w-4 h-4" />
              <span>Past Recordings & Notes</span>
            </button>

            <button
              onClick={() => { setActiveTab('assignments'); setActiveTestAttempt(null); }}
              className={`w-full flex items-center space-x-3 px-3 py-2 rounded-xl text-xs font-semibold transition-colors ${
                activeTab === 'assignments'
                  ? 'bg-indigo-50 text-indigo-700'
                  : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900'
              }`}
            >
              <FileCheck className="w-4 h-4" />
              <span>Assignments</span>
            </button>

            <button
              onClick={() => { setActiveTab('tests'); setActiveTestAttempt(null); }}
              className={`w-full flex items-center space-x-3 px-3 py-2 rounded-xl text-xs font-semibold transition-colors ${
                activeTab === 'tests'
                  ? 'bg-indigo-50 text-indigo-700'
                  : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900'
              }`}
            >
              <Award className="w-4 h-4" />
              <span>Tests & Quizzes</span>
            </button>

            <button
              onClick={() => { setActiveTab('fees'); setActiveTestAttempt(null); }}
              className={`w-full flex items-center space-x-3 px-3 py-2 rounded-xl text-xs font-semibold transition-colors ${
                activeTab === 'fees'
                  ? 'bg-indigo-50 text-indigo-700'
                  : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900'
              }`}
            >
              <CreditCard className="w-4 h-4" />
              <span>Fee Invoices & Pay</span>
            </button>
          </nav>
        </div>

        {/* Attendance Summary */}
        <div className="bg-slate-50 border border-slate-200 rounded-xl p-3">
          <div className="flex items-center justify-between mb-1">
            <span className="text-[10px] font-bold text-slate-500 uppercase tracking-wider">Attendance</span>
            <span className="text-xs font-bold text-emerald-600">96.4%</span>
          </div>
          <div className="w-full bg-slate-200 h-1.5 rounded-full mt-1 overflow-hidden">
            <div className="bg-emerald-500 h-full rounded-full" style={{ width: '96%' }}></div>
          </div>
          <span className="text-[10px] text-slate-400 mt-1 block">Present in 27/28 classes</span>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 flex flex-col h-screen overflow-y-auto">
        {/* Top Header */}
        <header className="h-16 bg-white border-b border-slate-200 px-6 flex items-center justify-between shrink-0 shadow-subtle">
          <div>
            <h1 className="text-lg font-extrabold text-slate-900">
              {activeTab === 'home' && 'Student Learning Center'}
              {activeTab === 'courses' && 'Enrolled Courses & Syllabus'}
              {activeTab === 'recordings' && 'Video Lectures & Downloadable Notes'}
              {activeTab === 'assignments' && 'Homework & Problem Sets'}
              {activeTab === 'tests' && 'Online Test Examination Engine'}
              {activeTab === 'fees' && 'Tuition Fees & Invoices'}
            </h1>
            <p className="text-xs text-slate-500">Apex IIT-JEE & Medical Academy &bull; Student ID: APX-2025-042</p>
          </div>

          <div className="flex items-center space-x-3">
            <button
              onClick={() => setIsInLiveClass(true)}
              className="inline-flex items-center space-x-2 px-4 py-2 text-xs font-semibold text-white bg-rose-600 hover:bg-rose-700 rounded-xl shadow-md transition-colors"
            >
              <span className="w-2 h-2 rounded-full bg-white animate-pulse" />
              <span>Join Live Class Now</span>
            </button>
          </div>
        </header>

        {/* Content Body */}
        <div className="p-6 space-y-6">
          {/* HOME TAB */}
          {activeTab === 'home' && (
            <>
              {/* Live Class Alert Banner */}
              <div className="bg-gradient-to-r from-indigo-500 via-indigo-600 to-primary-700 rounded-2xl p-6 text-white shadow-elevated flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div>
                  <div className="inline-flex items-center space-x-1.5 bg-white/20 backdrop-blur-xs px-2.5 py-0.5 rounded-full text-[11px] font-bold uppercase tracking-wider mb-2">
                    <span className="w-1.5 h-1.5 rounded-full bg-rose-400 animate-ping"></span>
                    <span>Class In Progress Now</span>
                  </div>
                  <h3 className="text-xl font-bold">Physics: Angular Momentum Conservation & Rolling Motion</h3>
                  <p className="text-xs text-indigo-100 mt-1">
                    Prof. Rajesh Sharma &bull; Interactive Whiteboard & Doubts Live
                  </p>
                </div>
                <button
                  onClick={() => setIsInLiveClass(true)}
                  className="px-5 py-3 text-xs font-bold text-indigo-900 bg-white hover:bg-indigo-50 rounded-xl shadow-sm flex items-center space-x-2 shrink-0 transition-colors"
                >
                  <Play className="w-4 h-4 fill-current text-indigo-600" />
                  <span>Enter Live Classroom</span>
                </button>
              </div>

              {/* Course Progression Cards */}
              <div>
                <h3 className="text-base font-bold text-slate-900 mb-3">Today's Subject Schedule</h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                  <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-5">
                    <div className="flex items-center justify-between mb-3">
                      <span className="text-xs font-bold text-indigo-600 bg-indigo-50 px-2.5 py-0.5 rounded">
                        Physics &bull; Chapter 01
                      </span>
                      <span className="text-xs text-slate-500 font-medium">18:30 - 20:00</span>
                    </div>
                    <h4 className="text-sm font-bold text-slate-900 mb-1">Rotational Dynamics & Torque</h4>
                    <p className="text-xs text-slate-500 mb-4">Live whiteboard session with Prof. Sharma.</p>
                    <button
                      onClick={() => setIsInLiveClass(true)}
                      className="w-full py-2 text-xs font-semibold text-indigo-600 bg-indigo-50 hover:bg-indigo-100 rounded-lg transition-colors"
                    >
                      Join Classroom
                    </button>
                  </div>

                  <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-5">
                    <div className="flex items-center justify-between mb-3">
                      <span className="text-xs font-bold text-emerald-600 bg-emerald-50 px-2.5 py-0.5 rounded">
                        Chemistry &bull; Chapter 02
                      </span>
                      <span className="text-xs text-slate-500 font-medium">Tomorrow 10:00</span>
                    </div>
                    <h4 className="text-sm font-bold text-slate-900 mb-1">Thermodynamics & Heat Capacities</h4>
                    <p className="text-xs text-slate-500 mb-4">Dr. A. K. Gupta &bull; NEET Chemistry</p>
                    <button
                      disabled
                      className="w-full py-2 text-xs font-semibold text-slate-400 bg-slate-100 rounded-lg cursor-not-allowed"
                    >
                      Starts Tomorrow
                    </button>
                  </div>
                </div>
              </div>

              {/* Quick Action Badges */}
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <button
                  onClick={() => setActiveTab('assignments')}
                  className="bg-white p-4 rounded-xl border border-slate-200 shadow-subtle flex items-center space-x-3 text-left hover:border-indigo-300 transition-colors"
                >
                  <div className="w-10 h-10 rounded-lg bg-amber-50 text-amber-600 flex items-center justify-center shrink-0">
                    <FileCheck className="w-5 h-5" />
                  </div>
                  <div>
                    <h5 className="text-xs font-bold text-slate-900">1 Pending Homework</h5>
                    <p className="text-[11px] text-slate-500">Due in 3 days</p>
                  </div>
                </button>

                <button
                  onClick={() => setActiveTab('tests')}
                  className="bg-white p-4 rounded-xl border border-slate-200 shadow-subtle flex items-center space-x-3 text-left hover:border-indigo-300 transition-colors"
                >
                  <div className="w-10 h-10 rounded-lg bg-indigo-50 text-indigo-600 flex items-center justify-center shrink-0">
                    <Award className="w-5 h-5" />
                  </div>
                  <div>
                    <h5 className="text-xs font-bold text-slate-900">Weekly Test 04 Ready</h5>
                    <p className="text-[11px] text-slate-500">45 Min timed test</p>
                  </div>
                </button>

                <button
                  onClick={() => setActiveTab('fees')}
                  className="bg-white p-4 rounded-xl border border-slate-200 shadow-subtle flex items-center space-x-3 text-left hover:border-indigo-300 transition-colors"
                >
                  <div className="w-10 h-10 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center shrink-0">
                    <CreditCard className="w-5 h-5" />
                  </div>
                  <div>
                    <h5 className="text-xs font-bold text-slate-900">Fee Status</h5>
                    <p className="text-[11px] text-emerald-600 font-semibold">₹45,000 Paid (Part Due)</p>
                  </div>
                </button>
              </div>
            </>
          )}

          {/* COURSES TAB */}
          {activeTab === 'courses' && (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {initialCourses.map((crs) => (
                <div key={crs.id} className="bg-white rounded-2xl border border-slate-200 shadow-card overflow-hidden">
                  <div className="relative aspect-video bg-slate-100 overflow-hidden">
                    <img src={crs.cover_image} alt={crs.name} className="w-full h-full object-cover" />
                    <span className="absolute top-3 left-3 bg-white/90 backdrop-blur-xs text-xs font-bold text-slate-800 px-2.5 py-1 rounded-lg">
                      Enrolled
                    </span>
                  </div>
                  <div className="p-5">
                    <h4 className="text-base font-bold text-slate-900 mb-1">{crs.name}</h4>
                    <p className="text-xs text-slate-500 mb-4">{crs.description}</p>
                    <div className="space-y-2 border-t border-slate-100 pt-3">
                      {crs.subjects[0]?.chapters.map((ch) => (
                        <div key={ch.id} className="flex items-center justify-between text-xs py-1">
                          <span className="font-medium text-slate-700">{ch.order_index}. {ch.name}</span>
                          <span className="text-slate-400">{ch.notes_count} Notes</span>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}

          {/* RECORDINGS TAB */}
          {activeTab === 'recordings' && (
            <div className="bg-white rounded-2xl border border-slate-200 shadow-card overflow-hidden">
              <div className="p-5 border-b border-slate-200">
                <h3 className="text-base font-bold text-slate-900">Recorded Live Classes</h3>
                <p className="text-xs text-slate-500">Rewatch lectures and download high-resolution blackboard notes.</p>
              </div>
              <div className="divide-y divide-slate-100">
                {initialLiveClasses.filter(c => c.status === 'completed').map((rec) => (
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
                    <div className="flex items-center space-x-3">
                      <a
                        href={rec.recording_url}
                        target="_blank"
                        rel="noreferrer"
                        className="px-3.5 py-2 text-xs font-semibold text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg shadow-sm flex items-center space-x-1.5"
                      >
                        <Play className="w-3.5 h-3.5 fill-current" />
                        <span>Watch Video</span>
                      </a>
                      <button className="px-3.5 py-2 text-xs font-semibold text-slate-700 bg-slate-100 hover:bg-slate-200 rounded-lg flex items-center space-x-1.5">
                        <Download className="w-3.5 h-3.5" />
                        <span>Board PDF</span>
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* ASSIGNMENTS TAB */}
          {activeTab === 'assignments' && (
            <div className="bg-white rounded-2xl border border-slate-200 shadow-card overflow-hidden">
              <div className="p-5 border-b border-slate-200">
                <h3 className="text-base font-bold text-slate-900">Homework & Submissions</h3>
                <p className="text-xs text-slate-500">Upload your handwritten solution notes for teacher evaluation.</p>
              </div>
              <div className="p-5 space-y-4">
                {initialAssignments.map((asg) => (
                  <div key={asg.id} className="p-4 rounded-xl border border-slate-200 bg-slate-50 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                    <div>
                      <span className="text-xs font-bold text-indigo-600 bg-indigo-50 px-2.5 py-0.5 rounded">
                        {asg.chapter_name}
                      </span>
                      <h4 className="text-sm font-bold text-slate-900 mt-1">{asg.title}</h4>
                      <p className="text-xs text-slate-500 mt-1">{asg.description}</p>
                    </div>
                    <button
                      onClick={() => setAsgModalOpen(true)}
                      className="px-4 py-2 text-xs font-semibold text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg shadow-sm shrink-0 flex items-center space-x-1.5"
                    >
                      <Upload className="w-3.5 h-3.5" />
                      <span>Upload Solution</span>
                    </button>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* TESTS TAB */}
          {activeTab === 'tests' && (
            <div>
              {!activeTestAttempt ? (
                <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-5">
                  <h3 className="text-base font-bold text-slate-900 mb-1">Available Mock Tests</h3>
                  <p className="text-xs text-slate-500 mb-4">Official timed tests designed for JEE Advanced pattern.</p>

                  <div className="space-y-4">
                    {initialTests.map((t) => (
                      <div key={t.id} className="p-4 rounded-xl border border-slate-200 bg-slate-50 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                        <div>
                          <div className="flex items-center space-x-2 mb-1">
                            <span className="text-[10px] font-bold text-emerald-700 bg-emerald-100 px-2 py-0.5 rounded">
                              ACTIVE
                            </span>
                            <span className="text-xs text-slate-500">{t.chapter_name}</span>
                          </div>
                          <h4 className="text-sm font-bold text-slate-900">{t.title}</h4>
                          <p className="text-xs text-slate-500 mt-1">
                            Duration: {t.duration_min} Mins &bull; Total Marks: {t.total_marks} &bull; Questions: {t.questions.length} MCQs
                          </p>
                        </div>
                        <button
                          onClick={() => {
                            setActiveTestAttempt(t);
                            setSelectedAnswers({});
                            setTestSubmitted(false);
                          }}
                          className="px-5 py-2.5 text-xs font-semibold text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg shadow-sm shrink-0"
                        >
                          Start Test Attempt
                        </button>
                      </div>
                    ))}
                  </div>
                </div>
              ) : (
                /* Active Test Taking View */
                <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-6">
                  <div className="flex items-center justify-between pb-4 border-b border-slate-200 mb-6">
                    <div>
                      <h3 className="text-base font-bold text-slate-900">{activeTestAttempt.title}</h3>
                      <p className="text-xs text-slate-500">JEE Advanced Pattern &bull; Single Choice MCQ</p>
                    </div>
                    <div className="flex items-center space-x-2 text-xs font-bold text-indigo-700 bg-indigo-50 px-3 py-1.5 rounded-lg border border-indigo-200">
                      <Timer className="w-4 h-4 text-indigo-600 animate-spin" />
                      <span>38:42 Left</span>
                    </div>
                  </div>

                  {!testSubmitted ? (
                    <div className="space-y-6">
                      {activeTestAttempt.questions.map((q: any, idx: number) => (
                        <div key={q.id} className="p-4 rounded-xl border border-slate-200 bg-slate-50/60">
                          <p className="text-xs font-bold text-slate-500 mb-1">Question {idx + 1} of {activeTestAttempt.questions.length}</p>
                          <h5 className="text-sm font-semibold text-slate-900 mb-4">{q.question_text}</h5>

                          <div className="space-y-2">
                            {q.options.map((opt: string) => (
                              <button
                                key={opt}
                                onClick={() => setSelectedAnswers({ ...selectedAnswers, [q.id]: opt })}
                                className={`w-full text-left p-3 rounded-lg border text-xs font-medium transition-all ${
                                  selectedAnswers[q.id] === opt
                                    ? 'bg-indigo-50 border-indigo-500 text-indigo-900 font-bold'
                                    : 'bg-white border-slate-200 hover:border-slate-300 text-slate-700'
                                }`}
                              >
                                {opt}
                              </button>
                            ))}
                          </div>
                        </div>
                      ))}

                      <div className="flex justify-between items-center pt-4 border-t border-slate-200">
                        <button
                          onClick={() => setActiveTestAttempt(null)}
                          className="px-4 py-2 text-xs font-semibold text-slate-600 hover:bg-slate-100 rounded-lg"
                        >
                          Cancel Attempt
                        </button>
                        <button
                          onClick={handleTestSubmit}
                          className="px-6 py-2.5 text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg shadow-sm"
                        >
                          Submit & Calculate Score
                        </button>
                      </div>
                    </div>
                  ) : (
                    /* Test Result Breakdown */
                    <div className="text-center py-6">
                      <div className="w-14 h-14 rounded-full bg-emerald-100 text-emerald-600 flex items-center justify-center mx-auto mb-3">
                        <Award className="w-8 h-8" />
                      </div>
                      <h4 className="text-xl font-extrabold text-slate-900">Test Submitted Successfully!</h4>
                      <p className="text-xs text-slate-500 mt-1">Your performance report has been compiled.</p>

                      <div className="grid grid-cols-3 gap-4 max-w-md mx-auto my-6 text-center">
                        <div className="bg-slate-50 p-3 rounded-xl border border-slate-200">
                          <span className="text-[10px] text-slate-400 font-bold uppercase">Score</span>
                          <p className="text-lg font-extrabold text-indigo-600">12 / 12</p>
                        </div>
                        <div className="bg-slate-50 p-3 rounded-xl border border-slate-200">
                          <span className="text-[10px] text-slate-400 font-bold uppercase">Institute Rank</span>
                          <p className="text-lg font-extrabold text-emerald-600">#1 / 32</p>
                        </div>
                        <div className="bg-slate-50 p-3 rounded-xl border border-slate-200">
                          <span className="text-[10px] text-slate-400 font-bold uppercase">Accuracy</span>
                          <p className="text-lg font-extrabold text-slate-800">100%</p>
                        </div>
                      </div>

                      <button
                        onClick={() => setActiveTestAttempt(null)}
                        className="px-5 py-2.5 text-xs font-bold text-slate-700 bg-slate-100 hover:bg-slate-200 rounded-lg"
                      >
                        Return to Tests Roster
                      </button>
                    </div>
                  )}
                </div>
              )}
            </div>
          )}

          {/* FEES TAB */}
          {activeTab === 'fees' && (
            <div className="space-y-6">
              {/* Fee Summary Card */}
              <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-6 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div>
                  <span className="text-xs font-bold text-indigo-600 bg-indigo-50 px-2.5 py-0.5 rounded">
                    Academic Year 2025-2026
                  </span>
                  <h3 className="text-lg font-bold text-slate-900 mt-1">IIT-JEE Masterclass Tuition Plan</h3>
                  <p className="text-xs text-slate-500 mt-1">
                    Total Amount: ₹65,000 &bull; Amount Paid: ₹45,000 &bull; Balance Due: <span className="font-bold text-amber-600">₹20,000</span>
                  </p>
                </div>
                <button
                  onClick={() => setFeeModalOpen(true)}
                  className="px-5 py-2.5 text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-xl shadow-md shrink-0 transition-colors"
                >
                  Pay Balance Due (Razorpay)
                </button>
              </div>

              {/* Transactions History */}
              <div className="bg-white rounded-2xl border border-slate-200 shadow-card overflow-hidden">
                <div className="p-5 border-b border-slate-200">
                  <h4 className="text-sm font-bold text-slate-900">Payment History & Tax Invoices</h4>
                </div>
                <div className="divide-y divide-slate-100 text-xs">
                  {initialFeeTransactions.filter(t => t.student_name === 'Aarav Patel').map((txn) => (
                    <div key={txn.id} className="p-4 flex items-center justify-between hover:bg-slate-50">
                      <div>
                        <p className="font-bold text-slate-800">Installment 1 — ₹{txn.amount_paid.toLocaleString()}</p>
                        <p className="text-[10px] text-slate-500">{txn.txn_id} &bull; Mode: {txn.mode}</p>
                      </div>
                      <div className="flex items-center space-x-3">
                        <span className="px-2.5 py-0.5 rounded-full text-[10px] font-semibold bg-emerald-100 text-emerald-800">
                          {txn.status.toUpperCase()}
                        </span>
                        <button className="flex items-center space-x-1 text-indigo-600 hover:text-indigo-800 font-medium">
                          <Download className="w-3.5 h-3.5" />
                          <span>Invoice PDF</span>
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}
        </div>
      </main>

      {/* Fee Payment Checkout Modal (Razorpay Simulation) */}
      {feeModalOpen && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl shadow-elevated border border-slate-200 p-6 max-w-md w-full">
            <div className="flex items-center space-x-2 text-indigo-600 mb-3">
              <ShieldCheck className="w-5 h-5" />
              <span className="text-xs font-bold uppercase tracking-wider">Classora Secure Checkout</span>
            </div>

            <h3 className="text-base font-bold text-slate-900 mb-1">Pay Pending Institute Tuition</h3>
            <p className="text-xs text-slate-500 mb-4">Apex IIT-JEE & Medical Academy &bull; Installment 2</p>

            {paymentSuccess ? (
              <div className="bg-emerald-50 border border-emerald-200 rounded-xl p-4 text-center">
                <CheckCircle2 className="w-8 h-8 text-emerald-600 mx-auto mb-2" />
                <h4 className="text-sm font-bold text-emerald-900">Payment Successful!</h4>
                <p className="text-xs text-emerald-700 mt-1">₹20,000 received. Receipt sent to your email.</p>
                <button
                  onClick={() => {
                    setFeeModalOpen(false);
                    setPaymentSuccess(false);
                  }}
                  className="mt-4 px-4 py-1.5 text-xs font-semibold text-white bg-emerald-600 hover:bg-emerald-700 rounded-lg"
                >
                  Close
                </button>
              </div>
            ) : (
              <div className="space-y-4 text-xs">
                <div className="p-3 bg-slate-50 rounded-xl border border-slate-200">
                  <div className="flex justify-between py-1 text-slate-600">
                    <span>Course:</span>
                    <span className="font-semibold text-slate-800">Class 12th Masterclass</span>
                  </div>
                  <div className="flex justify-between py-1 text-slate-600">
                    <span>Installment Amount:</span>
                    <span className="font-bold text-slate-900 text-sm">₹20,000</span>
                  </div>
                </div>

                <div>
                  <label className="block font-semibold text-slate-700 mb-1.5">Payment Method</label>
                  <div className="grid grid-cols-2 gap-2">
                    <button className="p-2.5 rounded-lg border border-indigo-500 bg-indigo-50/50 font-semibold text-indigo-900 text-center">
                      Razorpay UPI / QR
                    </button>
                    <button className="p-2.5 rounded-lg border border-slate-200 text-slate-700 text-center hover:bg-slate-50">
                      Credit / Debit Card
                    </button>
                  </div>
                </div>

                <div className="flex justify-end space-x-2 pt-2">
                  <button
                    onClick={() => setFeeModalOpen(false)}
                    className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg"
                  >
                    Cancel
                  </button>
                  <button
                    onClick={() => setPaymentSuccess(true)}
                    className="px-4 py-2 font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg shadow-sm"
                  >
                    Pay ₹20,000 Now
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Assignment Upload Modal */}
      {asgModalOpen && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl shadow-elevated border border-slate-200 p-6 max-w-md w-full">
            <h3 className="text-base font-bold text-slate-900 mb-1">Submit Assignment PDF</h3>
            <p className="text-xs text-slate-500 mb-4">Upload handwritten solution pages for Rotational Dynamics.</p>

            {asgFileUploaded ? (
              <div className="bg-emerald-50 border border-emerald-200 rounded-xl p-4 text-center">
                <CheckCircle2 className="w-8 h-8 text-emerald-600 mx-auto mb-2" />
                <h4 className="text-sm font-bold text-emerald-900">Submission Received!</h4>
                <p className="text-xs text-emerald-700 mt-1">Submitted on time. Teacher will grade shortly.</p>
                <button
                  onClick={() => {
                    setAsgModalOpen(false);
                    setAsgFileUploaded(false);
                  }}
                  className="mt-4 px-4 py-1.5 text-xs font-semibold text-white bg-emerald-600 hover:bg-emerald-700 rounded-lg"
                >
                  Close
                </button>
              </div>
            ) : (
              <div className="space-y-4 text-xs">
                <div className="border-2 border-dashed border-slate-200 rounded-xl p-6 text-center hover:border-indigo-300 cursor-pointer bg-slate-50">
                  <Upload className="w-8 h-8 text-slate-400 mx-auto mb-2" />
                  <p className="font-semibold text-slate-700">Click to browse or drop PDF here</p>
                  <p className="text-[10px] text-slate-400 mt-1">PDF format up to 25MB</p>
                </div>
                <div className="flex justify-end space-x-2 pt-2">
                  <button
                    onClick={() => setAsgModalOpen(false)}
                    className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg"
                  >
                    Cancel
                  </button>
                  <button
                    onClick={() => setAsgFileUploaded(true)}
                    className="px-4 py-2 font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg shadow-sm"
                  >
                    Confirm Submission
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
};
