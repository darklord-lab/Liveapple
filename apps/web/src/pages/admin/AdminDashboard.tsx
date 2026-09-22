import React, { useState } from 'react';
import {
  LayoutDashboard,
  Users,
  GraduationCap,
  Layers,
  BookOpen,
  Video,
  FileCheck,
  CreditCard,
  Settings,
  Plus,
  Search,
  CheckCircle2,
  AlertCircle,
  Download,
  Calendar,
  MoreVertical,
  ChevronRight,
  Sparkles,
  TrendingUp,
} from 'lucide-react';
import { initialUsers, initialBatches, initialCourses, initialFeeTransactions, initialLiveClasses } from '../../../../api/src/mockData.js';

export const AdminDashboard: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'overview' | 'students' | 'teachers' | 'batches' | 'courses' | 'fees' | 'branding'>('overview');
  const [searchQuery, setSearchQuery] = useState('');

  // Local state for interactive administration
  const [studentsList, setStudentsList] = useState(initialUsers.filter(u => u.role === 'student'));
  const [teachersList, setTeachersList] = useState(initialUsers.filter(u => u.role === 'teacher'));
  const [batchesList, setBatchesList] = useState(initialBatches);
  const [coursesList, setCoursesList] = useState(initialCourses);
  const [transactionsList, setTransactionsList] = useState(initialFeeTransactions);

  // Modals
  const [addStudentModal, setAddStudentModal] = useState(false);
  const [newStudentName, setNewStudentName] = useState('');
  const [newStudentEmail, setNewStudentEmail] = useState('');
  const [newStudentPhone, setNewStudentPhone] = useState('');

  // Quick stats
  const totalStudents = studentsList.length + 58; // Representing institute roster
  const activeTeachers = teachersList.length + 8;
  const liveClassesToday = initialLiveClasses.filter(c => c.status === 'live' || c.status === 'scheduled').length;
  const totalRevenue = transactionsList.reduce((acc, t) => acc + t.amount_paid, 0);

  const handleAddStudent = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newStudentName.trim() || !newStudentEmail.trim()) return;
    const newStudent = {
      id: `usr-s-${Date.now()}`,
      institute_id: 'inst-apex-01',
      name: newStudentName.trim(),
      email: newStudentEmail.trim(),
      phone: newStudentPhone.trim() || '+91 99000 00000',
      role: 'student' as const,
      avatar_url: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100&h=100&fit=crop',
      status: 'active' as const,
      created_at: new Date().toISOString(),
    };
    setStudentsList([newStudent, ...studentsList]);
    setNewStudentName('');
    setNewStudentEmail('');
    setNewStudentPhone('');
    setAddStudentModal(false);
  };

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 flex font-sans">
      {/* Sidebar Navigation (Light Theme) */}
      <aside className="w-64 bg-white border-r border-slate-200 flex flex-col justify-between p-4 shadow-subtle shrink-0">
        <div>
          {/* Institute Branding */}
          <div className="flex items-center space-x-3 pb-6 border-b border-slate-100">
            <div className="w-10 h-10 rounded-xl bg-indigo-600 flex items-center justify-center text-white font-bold text-lg shadow-sm">
              A
            </div>
            <div className="overflow-hidden">
              <h2 className="text-sm font-bold text-slate-900 truncate">Apex Academy</h2>
              <span className="text-[11px] font-semibold text-indigo-600 uppercase tracking-wider block">
                Admin Console
              </span>
            </div>
          </div>

          {/* Navigation Links */}
          <nav className="mt-6 space-y-1">
            <button
              onClick={() => setActiveTab('overview')}
              className={`w-full flex items-center space-x-3 px-3 py-2 rounded-xl text-xs font-semibold transition-colors ${
                activeTab === 'overview'
                  ? 'bg-indigo-50 text-indigo-700'
                  : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900'
              }`}
            >
              <LayoutDashboard className="w-4 h-4" />
              <span>Overview & KPIs</span>
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
              <span>Students Roster</span>
            </button>

            <button
              onClick={() => setActiveTab('teachers')}
              className={`w-full flex items-center space-x-3 px-3 py-2 rounded-xl text-xs font-semibold transition-colors ${
                activeTab === 'teachers'
                  ? 'bg-indigo-50 text-indigo-700'
                  : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900'
              }`}
            >
              <GraduationCap className="w-4 h-4" />
              <span>Faculty & Teachers</span>
            </button>

            <button
              onClick={() => setActiveTab('batches')}
              className={`w-full flex items-center space-x-3 px-3 py-2 rounded-xl text-xs font-semibold transition-colors ${
                activeTab === 'batches'
                  ? 'bg-indigo-50 text-indigo-700'
                  : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900'
              }`}
            >
              <Layers className="w-4 h-4" />
              <span>Batches & Sections</span>
            </button>

            <button
              onClick={() => setActiveTab('courses')}
              className={`w-full flex items-center space-x-3 px-3 py-2 rounded-xl text-xs font-semibold transition-colors ${
                activeTab === 'courses'
                  ? 'bg-indigo-50 text-indigo-700'
                  : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900'
              }`}
            >
              <BookOpen className="w-4 h-4" />
              <span>Courses & Subjects</span>
            </button>

            <button
              onClick={() => setActiveTab('fees')}
              className={`w-full flex items-center space-x-3 px-3 py-2 rounded-xl text-xs font-semibold transition-colors ${
                activeTab === 'fees'
                  ? 'bg-indigo-50 text-indigo-700'
                  : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900'
              }`}
            >
              <CreditCard className="w-4 h-4" />
              <span>Fee Collection & Plans</span>
            </button>

            <button
              onClick={() => setActiveTab('branding')}
              className={`w-full flex items-center space-x-3 px-3 py-2 rounded-xl text-xs font-semibold transition-colors ${
                activeTab === 'branding'
                  ? 'bg-indigo-50 text-indigo-700'
                  : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900'
              }`}
            >
              <Settings className="w-4 h-4" />
              <span>Branding & White-Label</span>
            </button>
          </nav>
        </div>

        {/* Current Plan Indicator */}
        <div className="bg-slate-50 border border-slate-200 rounded-xl p-3">
          <div className="flex items-center justify-between mb-1">
            <span className="text-[10px] font-bold text-slate-500 uppercase tracking-wider">Current Plan</span>
            <span className="text-[10px] font-extrabold text-indigo-600 bg-indigo-50 px-2 py-0.5 rounded">
              PRO TIER
            </span>
          </div>
          <p className="text-xs font-bold text-slate-800">Apex Academy (IIT-JEE)</p>
          <div className="w-full bg-slate-200 h-1.5 rounded-full mt-2 overflow-hidden">
            <div className="bg-indigo-600 h-full rounded-full" style={{ width: '42%' }}></div>
          </div>
          <span className="text-[10px] text-slate-500 mt-1 block">420 of 2,000 Students</span>
        </div>
      </aside>

      {/* Main Content Area */}
      <main className="flex-1 flex flex-col h-screen overflow-y-auto">
        {/* Top Header */}
        <header className="h-16 bg-white border-b border-slate-200 px-6 flex items-center justify-between shrink-0 shadow-subtle">
          <div className="flex items-center space-x-3">
            <h1 className="text-lg font-extrabold text-slate-900 capitalize">
              {activeTab === 'overview' ? 'Academy Overview & Insights' : activeTab}
            </h1>
            <span className="text-xs text-slate-400">|</span>
            <span className="text-xs text-emerald-700 font-semibold bg-emerald-50 px-2.5 py-0.5 rounded-full border border-emerald-200">
              LiveKit & Yjs Connected
            </span>
          </div>

          <div className="flex items-center space-x-4">
            <div className="relative">
              <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                placeholder="Search students, batches, fees..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="text-xs pl-9 pr-4 py-2 bg-slate-50 border border-slate-200 rounded-xl w-64 focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
            </div>

            <div className="flex items-center space-x-2 border-l border-slate-200 pl-4">
              <img
                src="https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&h=100&fit=crop"
                alt="Admin"
                className="w-8 h-8 rounded-full border border-slate-200"
              />
              <div className="text-left hidden sm:block">
                <p className="text-xs font-bold text-slate-800">Dr. V. Sen</p>
                <p className="text-[10px] text-slate-400">Director / Owner</p>
              </div>
            </div>
          </div>
        </header>

        {/* Tab Content */}
        <div className="p-6 space-y-6">
          {/* OVERVIEW TAB */}
          {activeTab === 'overview' && (
            <>
              {/* KPI Cards (Clean Light Theme) */}
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
                <div className="bg-white rounded-2xl p-5 border border-slate-200 shadow-card">
                  <div className="flex items-center justify-between mb-3">
                    <span className="text-xs font-semibold text-slate-500">Total Enrolled</span>
                    <div className="w-8 h-8 rounded-lg bg-indigo-50 text-indigo-600 flex items-center justify-center">
                      <Users className="w-4 h-4" />
                    </div>
                  </div>
                  <div className="text-2xl font-extrabold text-slate-900">{totalStudents}</div>
                  <div className="flex items-center text-xs text-emerald-600 font-medium mt-2">
                    <TrendingUp className="w-3.5 h-3.5 mr-1" />
                    <span>+14% new admissions this month</span>
                  </div>
                </div>

                <div className="bg-white rounded-2xl p-5 border border-slate-200 shadow-card">
                  <div className="flex items-center justify-between mb-3">
                    <span className="text-xs font-semibold text-slate-500">Live Classes Today</span>
                    <div className="w-8 h-8 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center">
                      <Video className="w-4 h-4" />
                    </div>
                  </div>
                  <div className="text-2xl font-extrabold text-slate-900">{liveClassesToday} Sessions</div>
                  <div className="flex items-center text-xs text-slate-500 font-medium mt-2">
                    <span>1 currently streaming &bull; 2 scheduled</span>
                  </div>
                </div>

                <div className="bg-white rounded-2xl p-5 border border-slate-200 shadow-card">
                  <div className="flex items-center justify-between mb-3">
                    <span className="text-xs font-semibold text-slate-500">Monthly Fee Collected</span>
                    <div className="w-8 h-8 rounded-lg bg-indigo-50 text-indigo-600 flex items-center justify-center">
                      <CreditCard className="w-4 h-4" />
                    </div>
                  </div>
                  <div className="text-2xl font-extrabold text-slate-900">₹{totalRevenue.toLocaleString()}</div>
                  <div className="flex items-center text-xs text-emerald-600 font-medium mt-2">
                    <span>94% collection efficiency</span>
                  </div>
                </div>

                <div className="bg-white rounded-2xl p-5 border border-slate-200 shadow-card">
                  <div className="flex items-center justify-between mb-3">
                    <span className="text-xs font-semibold text-slate-500">Avg Attendance</span>
                    <div className="w-8 h-8 rounded-lg bg-amber-50 text-amber-600 flex items-center justify-center">
                      <Calendar className="w-4 h-4" />
                    </div>
                  </div>
                  <div className="text-2xl font-extrabold text-slate-900">91.4%</div>
                  <div className="flex items-center text-xs text-slate-500 font-medium mt-2">
                    <span>Tracked across 4 batches</span>
                  </div>
                </div>
              </div>

              {/* Batches & Ongoing Classes Snapshot */}
              <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                <div className="lg:col-span-2 bg-white rounded-2xl border border-slate-200 shadow-card p-5">
                  <div className="flex items-center justify-between mb-4">
                    <h3 className="text-sm font-bold text-slate-900">Active Batches & Enrollments</h3>
                    <button
                      onClick={() => setActiveTab('batches')}
                      className="text-xs font-semibold text-indigo-600 hover:text-indigo-800"
                    >
                      View All &rarr;
                    </button>
                  </div>
                  <div className="divide-y divide-slate-100">
                    {batchesList.map((batch) => (
                      <div key={batch.id} className="py-3 flex items-center justify-between">
                        <div>
                          <p className="text-xs font-bold text-slate-800">{batch.name}</p>
                          <p className="text-[11px] text-slate-500">{batch.course_name} &bull; {batch.teacher_name}</p>
                        </div>
                        <div className="flex items-center space-x-3">
                          <span className="text-xs font-semibold text-slate-700 bg-slate-100 px-2.5 py-1 rounded-lg">
                            {batch.student_count} Students
                          </span>
                          <span className="text-[10px] font-bold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded border border-emerald-200">
                            Active
                          </span>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Recent Fee Transactions */}
                <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-5">
                  <div className="flex items-center justify-between mb-4">
                    <h3 className="text-sm font-bold text-slate-900">Recent Fee Receipts</h3>
                    <button
                      onClick={() => setActiveTab('fees')}
                      className="text-xs font-semibold text-indigo-600 hover:text-indigo-800"
                    >
                      Manage &rarr;
                    </button>
                  </div>
                  <div className="space-y-3">
                    {transactionsList.slice(0, 3).map((txn) => (
                      <div key={txn.id} className="p-3 bg-slate-50 rounded-xl border border-slate-100 flex items-center justify-between text-xs">
                        <div>
                          <p className="font-bold text-slate-800">{txn.student_name}</p>
                          <p className="text-[10px] text-slate-500">{txn.mode} &bull; {txn.txn_id}</p>
                        </div>
                        <div className="text-right">
                          <p className="font-bold text-slate-900">₹{txn.amount_paid.toLocaleString()}</p>
                          <span className={`text-[10px] font-semibold px-2 py-0.5 rounded-full ${
                            txn.status === 'paid' ? 'bg-emerald-100 text-emerald-800' : 'bg-amber-100 text-amber-800'
                          }`}>
                            {txn.status}
                          </span>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </>
          )}

          {/* STUDENTS TAB */}
          {activeTab === 'students' && (
            <div className="bg-white rounded-2xl border border-slate-200 shadow-card overflow-hidden">
              <div className="p-5 border-b border-slate-200 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div>
                  <h3 className="text-base font-bold text-slate-900">Students Directory</h3>
                  <p className="text-xs text-slate-500">Manage enrolled students, batch assignments, and fee status.</p>
                </div>
                <button
                  onClick={() => setAddStudentModal(true)}
                  className="inline-flex items-center space-x-1.5 px-3.5 py-2 text-xs font-semibold text-white bg-indigo-600 hover:bg-indigo-700 rounded-xl shadow-sm transition-colors"
                >
                  <Plus className="w-4 h-4" />
                  <span>Enroll New Student</span>
                </button>
              </div>

              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs text-slate-600">
                  <thead className="bg-slate-50 text-slate-700 uppercase font-semibold text-[10px] border-b border-slate-200">
                    <tr>
                      <th className="px-6 py-3">Student Name</th>
                      <th className="px-6 py-3">Contact</th>
                      <th className="px-6 py-3">Assigned Batch</th>
                      <th className="px-6 py-3">Fee Status</th>
                      <th className="px-6 py-3">Status</th>
                      <th className="px-6 py-3 text-right">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {studentsList.map((st) => (
                      <tr key={st.id} className="hover:bg-slate-50 transition-colors">
                        <td className="px-6 py-3.5 flex items-center space-x-3">
                          <img src={st.avatar_url} alt="" className="w-8 h-8 rounded-full border border-slate-200" />
                          <div>
                            <p className="font-bold text-slate-900">{st.name}</p>
                            <p className="text-[10px] text-slate-400">{st.email}</p>
                          </div>
                        </td>
                        <td className="px-6 py-3.5">{st.phone}</td>
                        <td className="px-6 py-3.5 font-medium text-slate-800">JEE Super 30 (Batch Alpha)</td>
                        <td className="px-6 py-3.5">
                          <span className="px-2 py-0.5 rounded-full text-[10px] font-semibold bg-emerald-100 text-emerald-800">
                            Clear
                          </span>
                        </td>
                        <td className="px-6 py-3.5">
                          <span className="px-2 py-0.5 rounded-full text-[10px] font-semibold bg-slate-100 text-slate-700">
                            Active
                          </span>
                        </td>
                        <td className="px-6 py-3.5 text-right font-medium">
                          <button className="text-indigo-600 hover:text-indigo-800 mr-3">Edit</button>
                          <button className="text-slate-400 hover:text-slate-600">Details</button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {/* TEACHERS TAB */}
          {activeTab === 'teachers' && (
            <div className="bg-white rounded-2xl border border-slate-200 shadow-card overflow-hidden">
              <div className="p-5 border-b border-slate-200 flex items-center justify-between">
                <div>
                  <h3 className="text-base font-bold text-slate-900">Faculty & Instructors</h3>
                  <p className="text-xs text-slate-500">Teachers with live classroom broadcast privileges.</p>
                </div>
              </div>
              <div className="divide-y divide-slate-100">
                {teachersList.map((t) => (
                  <div key={t.id} className="p-4 flex items-center justify-between hover:bg-slate-50 transition-colors">
                    <div className="flex items-center space-x-3">
                      <img src={t.avatar_url} alt="" className="w-10 h-10 rounded-full border border-slate-200" />
                      <div>
                        <p className="text-sm font-bold text-slate-900">{t.name}</p>
                        <p className="text-xs text-slate-500">{t.email} &bull; Physics Department</p>
                      </div>
                    </div>
                    <div className="flex items-center space-x-3">
                      <span className="text-xs font-semibold bg-indigo-50 text-indigo-700 px-3 py-1 rounded-lg border border-indigo-200">
                        Assigned: JEE Super 30
                      </span>
                      <button className="text-xs font-semibold text-slate-600 hover:text-slate-900">
                        View Schedule
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* BATCHES TAB */}
          {activeTab === 'batches' && (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
              {batchesList.map((b) => (
                <div key={b.id} className="bg-white rounded-2xl border border-slate-200 shadow-card p-5">
                  <div className="flex items-center justify-between mb-3">
                    <span className="text-xs font-bold text-indigo-600 bg-indigo-50 px-2.5 py-0.5 rounded border border-indigo-200">
                      Academic Year 2025-26
                    </span>
                    <span className="text-xs text-slate-400 font-medium">32 Enrolled</span>
                  </div>
                  <h4 className="text-base font-bold text-slate-900 mb-1">{b.name}</h4>
                  <p className="text-xs text-slate-500 mb-4">{b.course_name}</p>
                  <div className="bg-slate-50 p-3 rounded-xl border border-slate-100 flex items-center justify-between text-xs mb-4">
                    <div>
                      <span className="text-slate-400 block text-[10px]">Head Teacher</span>
                      <span className="font-semibold text-slate-800">{b.teacher_name}</span>
                    </div>
                    <div>
                      <span className="text-slate-400 block text-[10px]">Schedule</span>
                      <span className="font-semibold text-slate-800">Mon &bull; Wed &bull; Fri</span>
                    </div>
                  </div>
                  <button className="w-full py-2 text-xs font-semibold text-slate-700 bg-slate-100 hover:bg-slate-200 rounded-lg transition-colors">
                    Manage Batch Students & Timetable
                  </button>
                </div>
              ))}
            </div>
          )}

          {/* FEES TAB */}
          {activeTab === 'fees' && (
            <div className="bg-white rounded-2xl border border-slate-200 shadow-card overflow-hidden">
              <div className="p-5 border-b border-slate-200 flex items-center justify-between">
                <div>
                  <h3 className="text-base font-bold text-slate-900">Fee Ledger & Transactions</h3>
                  <p className="text-xs text-slate-500">Live Razorpay & UPI payment sync with installment tracking.</p>
                </div>
                <button className="flex items-center space-x-1.5 px-3 py-1.5 text-xs font-medium text-slate-700 bg-white border border-slate-300 rounded-lg shadow-subtle hover:bg-slate-50">
                  <Download className="w-3.5 h-3.5" />
                  <span>Export CSV</span>
                </button>
              </div>

              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs text-slate-600">
                  <thead className="bg-slate-50 text-slate-700 uppercase font-semibold text-[10px] border-b border-slate-200">
                    <tr>
                      <th className="px-6 py-3">Receipt / Txn ID</th>
                      <th className="px-6 py-3">Student Name</th>
                      <th className="px-6 py-3">Course Plan</th>
                      <th className="px-6 py-3">Amount Paid</th>
                      <th className="px-6 py-3">Gateway / Mode</th>
                      <th className="px-6 py-3">Status</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {transactionsList.map((t) => (
                      <tr key={t.id} className="hover:bg-slate-50 transition-colors">
                        <td className="px-6 py-3.5 font-mono text-slate-700">{t.txn_id}</td>
                        <td className="px-6 py-3.5 font-bold text-slate-900">{t.student_name}</td>
                        <td className="px-6 py-3.5">{t.course_name}</td>
                        <td className="px-6 py-3.5 font-bold text-slate-900">₹{t.amount_paid.toLocaleString()}</td>
                        <td className="px-6 py-3.5">{t.mode}</td>
                        <td className="px-6 py-3.5">
                          <span
                            className={`px-2.5 py-0.5 rounded-full text-[10px] font-semibold ${
                              t.status === 'paid'
                                ? 'bg-emerald-100 text-emerald-800'
                                : t.status === 'pending'
                                ? 'bg-amber-100 text-amber-800'
                                : 'bg-rose-100 text-rose-800'
                            }`}
                          >
                            {t.status}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {/* BRANDING TAB */}
          {activeTab === 'branding' && (
            <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-6 max-w-2xl">
              <h3 className="text-base font-bold text-slate-900 mb-1">Institute Branding & Theme</h3>
              <p className="text-xs text-slate-500 mb-6">Customize your student portal appearance, logo, and subdomain.</p>
              
              <div className="space-y-4 text-xs">
                <div>
                  <label className="block font-semibold text-slate-700 mb-1">Institute Name</label>
                  <input
                    defaultValue="Apex IIT-JEE & Medical Academy"
                    className="w-full p-2.5 border border-slate-200 rounded-lg focus:ring-2 focus:ring-indigo-500"
                  />
                </div>
                <div>
                  <label className="block font-semibold text-slate-700 mb-1">Custom Domain (Enterprise)</label>
                  <input
                    defaultValue="learn.apexacademy.in"
                    className="w-full p-2.5 border border-slate-200 rounded-lg focus:ring-2 focus:ring-indigo-500"
                  />
                </div>
                <div>
                  <label className="block font-semibold text-slate-700 mb-1">Theme Accent Color</label>
                  <div className="flex items-center space-x-3 mt-2">
                    <div className="w-8 h-8 rounded-full bg-indigo-600 ring-2 ring-indigo-300 ring-offset-2 cursor-pointer" />
                    <div className="w-8 h-8 rounded-full bg-blue-600 cursor-pointer" />
                    <div className="w-8 h-8 rounded-full bg-emerald-600 cursor-pointer" />
                    <div className="w-8 h-8 rounded-full bg-violet-600 cursor-pointer" />
                  </div>
                </div>
                <div className="pt-4">
                  <button className="px-5 py-2.5 font-semibold text-white bg-indigo-600 hover:bg-indigo-700 rounded-xl shadow-sm">
                    Save Branding Changes
                  </button>
                </div>
              </div>
            </div>
          )}
        </div>
      </main>

      {/* Add Student Modal */}
      {addStudentModal && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl shadow-elevated border border-slate-200 p-6 max-w-md w-full">
            <h3 className="text-base font-bold text-slate-900 mb-1">Enroll New Student</h3>
            <p className="text-xs text-slate-500 mb-4">Add student credentials and assign to initial batch.</p>
            <form onSubmit={handleAddStudent} className="space-y-3 text-xs">
              <div>
                <label className="block font-semibold text-slate-700 mb-1">Full Name</label>
                <input
                  required
                  value={newStudentName}
                  onChange={(e) => setNewStudentName(e.target.value)}
                  placeholder="Aarav Sharma"
                  className="w-full p-2.5 border border-slate-200 rounded-lg focus:ring-2 focus:ring-indigo-500"
                />
              </div>
              <div>
                <label className="block font-semibold text-slate-700 mb-1">Email Address</label>
                <input
                  required
                  type="email"
                  value={newStudentEmail}
                  onChange={(e) => setNewStudentEmail(e.target.value)}
                  placeholder="aarav@gmail.com"
                  className="w-full p-2.5 border border-slate-200 rounded-lg focus:ring-2 focus:ring-indigo-500"
                />
              </div>
              <div>
                <label className="block font-semibold text-slate-700 mb-1">WhatsApp / Phone</label>
                <input
                  value={newStudentPhone}
                  onChange={(e) => setNewStudentPhone(e.target.value)}
                  placeholder="+91 98765 43210"
                  className="w-full p-2.5 border border-slate-200 rounded-lg focus:ring-2 focus:ring-indigo-500"
                />
              </div>
              <div className="flex justify-end space-x-2 pt-2">
                <button
                  type="button"
                  onClick={() => setAddStudentModal(false)}
                  className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 font-semibold text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg shadow-sm"
                >
                  Save & Enroll
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
