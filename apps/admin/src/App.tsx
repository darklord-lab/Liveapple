import React, { useState, useEffect } from 'react';
import {
  LayoutDashboard,
  Users,
  GraduationCap,
  Layers,
  BookOpen,
  CreditCard,
  Settings,
  Plus,
  Search,
  CheckCircle2,
  Download,
  Calendar,
  ExternalLink,
  TrendingUp,
  Video,
  LogOut,
} from 'lucide-react';
import { LoginCard, LoggedInUser } from '@shared/LoginCard';

export function App() {
  const [currentUser, setCurrentUser] = useState<LoggedInUser | null>(null);
  const [activeTab, setActiveTab] = useState<'overview' | 'students' | 'teachers' | 'batches' | 'fees' | 'branding'>('overview');
  const [searchQuery, setSearchQuery] = useState('');

  const [students, setStudents] = useState<any[]>([
    { id: '1', name: 'Aarav Patel', email: 'student@classora.com', phone: '+91 98765 43210', batch: 'Batch A — Class 12th IIT-JEE Masterclass', fee: 'Clear', status: 'Active' },
    { id: '2', name: 'Priya Sharma', email: 'priya@classora.com', phone: '+91 98765 43211', batch: 'Batch B — Class 11th NEET Champions', fee: 'Clear', status: 'Active' },
    { id: '3', name: 'Rohan Verma', email: 'rohan@classora.com', phone: '+91 98765 43212', batch: 'Batch A — Class 12th IIT-JEE Masterclass', fee: 'Due ₹20,000', status: 'Active' },
  ]);

  const [teachers, setTeachers] = useState<any[]>([
    { id: 't1', name: 'Prof. Rajesh Sharma', email: 'teacher@classora.com', dept: 'Physics', batch: 'Batch A — Class 12th IIT-JEE Masterclass' },
    { id: 't2', name: 'Dr. Kavita Rao', email: 'kavita@classora.com', dept: 'Biology', batch: 'Batch B — Class 11th NEET Champions' },
  ]);

  const [batches, setBatches] = useState<any[]>([
    { id: 'b1', name: 'Batch A — Class 12th IIT-JEE Masterclass', students: 2, teacher: 'Prof. Rajesh Sharma', timing: 'Mon, Wed, Fri 18:30' },
    { id: 'b2', name: 'Batch B — Class 11th NEET Champions', students: 2, teacher: 'Dr. Kavita Rao', timing: 'Tue, Thu, Sat 10:00' },
    { id: 'b3', name: 'Batch C — Class 10th Board & NTSE', students: 0, teacher: 'Prof. Rajesh Sharma', timing: 'Daily 16:00' },
  ]);

  // Load from DB
  useEffect(() => {
    const fetchDb = async () => {
      try {
        const [batchesRes, studentsRes] = await Promise.all([
          fetch('http://localhost:4000/api/v1/batches'),
          fetch('http://localhost:4000/api/v1/students'),
        ]);
        const bData = await batchesRes.json();
        const sData = await studentsRes.json();

        if (bData.batches) {
          setBatches(
            bData.batches.map((b: any) => ({
              id: b.id,
              name: b.name,
              students: b.enrollments?.length || 0,
              teacher: b.teacher?.name || 'Prof. Rajesh Sharma',
              timing: 'Daily Interactive Live',
            }))
          );
        }

        if (sData.students) {
          setStudents(
            sData.students.map((s: any) => ({
              id: s.id,
              name: s.name,
              email: s.email,
              phone: s.phone || '+91 98765 00000',
              batch: s.enrollments?.[0]?.batch?.name || 'General Batch',
              fee: 'Active Enrolled',
              status: 'Active',
            }))
          );
        }
      } catch (e) {
        // use fallback
      }
    };
    fetchDb();
  }, []);

  const [transactions, setTransactions] = useState([
    { id: 'pay_01', student: 'Aarav Patel', amount: 45000, mode: 'Razorpay', status: 'Paid', date: '2025-06-15' },
    { id: 'pay_02', student: 'Priya Singh', amount: 65000, mode: 'UPI', status: 'Paid', date: '2025-05-10' },
    { id: 'pay_03', student: 'Rohan Verma', amount: 20000, mode: 'Razorpay Pending', status: 'Due', date: '2025-09-12' },
  ]);

  const [enrollModal, setEnrollModal] = useState(false);
  const [newStudentName, setNewStudentName] = useState('');
  const [newStudentEmail, setNewStudentEmail] = useState('');
  const [newStudentPhone, setNewStudentPhone] = useState('');

  const handleEnroll = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newStudentName || !newStudentEmail) return;
    const newS = {
      id: `s-${Date.now()}`,
      name: newStudentName,
      email: newStudentEmail,
      phone: newStudentPhone || '+91 99000 00000',
      batch: 'JEE Super 30',
      fee: 'Pending',
      status: 'Active',
    };
    setStudents([newS, ...students]);
    setNewStudentName('');
    setNewStudentEmail('');
    setNewStudentPhone('');
    setEnrollModal(false);
  };

  if (!currentUser) {
    return (
      <LoginCard
        role="admin"
        portalName="Institute Admin Console"
        portNumber={3001}
        defaultEmail="admin@apex.edu"
        defaultName="Dr. Vikramaditya Sen (Director)"
        onLoginSuccess={(user) => setCurrentUser(user)}
      />
    );
  }

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 flex font-sans">
      {/* Sidebar */}
      <aside className="w-64 bg-white border-r border-slate-200 flex flex-col justify-between p-4 shadow-subtle shrink-0">
        <div>
          <div className="flex items-center space-x-3 pb-6 border-b border-slate-100">
            <div className="w-10 h-10 rounded-xl bg-indigo-600 flex items-center justify-center text-white font-bold text-lg shadow-sm">
              A
            </div>
            <div>
              <h2 className="text-sm font-bold text-slate-900">Apex Academy</h2>
              <span className="text-[10px] font-bold text-indigo-600 uppercase tracking-widest block">
                Admin Panel (Port 3001)
              </span>
            </div>
          </div>

          <nav className="mt-6 space-y-1 text-xs font-semibold">
            <button
              onClick={() => setActiveTab('overview')}
              className={`w-full flex items-center space-x-3 px-3 py-2.5 rounded-xl transition-colors ${
                activeTab === 'overview' ? 'bg-indigo-50 text-indigo-700' : 'text-slate-600 hover:bg-slate-50'
              }`}
            >
              <LayoutDashboard className="w-4 h-4" />
              <span>Overview & KPIs</span>
            </button>

            <button
              onClick={() => setActiveTab('students')}
              className={`w-full flex items-center space-x-3 px-3 py-2.5 rounded-xl transition-colors ${
                activeTab === 'students' ? 'bg-indigo-50 text-indigo-700' : 'text-slate-600 hover:bg-slate-50'
              }`}
            >
              <Users className="w-4 h-4" />
              <span>Students Roster</span>
            </button>

            <button
              onClick={() => setActiveTab('teachers')}
              className={`w-full flex items-center space-x-3 px-3 py-2.5 rounded-xl transition-colors ${
                activeTab === 'teachers' ? 'bg-indigo-50 text-indigo-700' : 'text-slate-600 hover:bg-slate-50'
              }`}
            >
              <GraduationCap className="w-4 h-4" />
              <span>Faculty & Teachers</span>
            </button>

            <button
              onClick={() => setActiveTab('batches')}
              className={`w-full flex items-center space-x-3 px-3 py-2.5 rounded-xl transition-colors ${
                activeTab === 'batches' ? 'bg-indigo-50 text-indigo-700' : 'text-slate-600 hover:bg-slate-50'
              }`}
            >
              <Layers className="w-4 h-4" />
              <span>Batches & Timetable</span>
            </button>

            <button
              onClick={() => setActiveTab('fees')}
              className={`w-full flex items-center space-x-3 px-3 py-2.5 rounded-xl transition-colors ${
                activeTab === 'fees' ? 'bg-indigo-50 text-indigo-700' : 'text-slate-600 hover:bg-slate-50'
              }`}
            >
              <CreditCard className="w-4 h-4" />
              <span>Fee Collection & Ledger</span>
            </button>

            <button
              onClick={() => setActiveTab('branding')}
              className={`w-full flex items-center space-x-3 px-3 py-2.5 rounded-xl transition-colors ${
                activeTab === 'branding' ? 'bg-indigo-50 text-indigo-700' : 'text-slate-600 hover:bg-slate-50'
              }`}
            >
              <Settings className="w-4 h-4" />
              <span>Branding & White-Label</span>
            </button>
          </nav>
        </div>

        {/* Quick App Links */}
        <div className="bg-slate-50 border border-slate-200 rounded-2xl p-3 text-[11px] space-y-1.5">
          <span className="font-bold text-slate-500 uppercase tracking-wider block text-[10px]">Open Other Portals:</span>
          <a href="http://localhost:3000" target="_blank" rel="noreferrer" className="flex items-center justify-between text-indigo-600 hover:underline">
            <span>Marketing Site (3000)</span>
            <ExternalLink className="w-3 h-3" />
          </a>
          <a href="http://localhost:3002" target="_blank" rel="noreferrer" className="flex items-center justify-between text-indigo-600 hover:underline">
            <span>Teacher Studio (3002)</span>
            <ExternalLink className="w-3 h-3" />
          </a>
          <a href="http://localhost:3003" target="_blank" rel="noreferrer" className="flex items-center justify-between text-indigo-600 hover:underline">
            <span>Student App (3003)</span>
            <ExternalLink className="w-3 h-3" />
          </a>
        </div>
      </aside>

      {/* Main Area */}
      <main className="flex-1 flex flex-col h-screen overflow-y-auto">
        <header className="h-16 bg-white border-b border-slate-200 px-6 flex items-center justify-between shrink-0 shadow-subtle">
          <div className="flex items-center space-x-3">
            <h1 className="text-base font-extrabold text-slate-900 capitalize">
              {activeTab === 'overview' ? 'Institute Administration & Live Analytics' : activeTab}
            </h1>
          </div>

          <div className="flex items-center space-x-3">
            <button
              onClick={() => setEnrollModal(true)}
              className="px-3.5 py-2 text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-xl shadow-sm flex items-center space-x-1.5"
            >
              <Plus className="w-4 h-4" />
              <span>Enroll Student</span>
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

        <div className="p-6 space-y-6">
          {/* OVERVIEW TAB */}
          {activeTab === 'overview' && (
            <div className="space-y-6">
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
                <div className="bg-white rounded-2xl p-5 border border-slate-200 shadow-card">
                  <span className="text-xs font-bold text-slate-500">Total Students</span>
                  <div className="text-2xl font-black text-slate-900 mt-1">420</div>
                  <span className="text-[11px] text-emerald-600 font-semibold flex items-center mt-1">
                    <TrendingUp className="w-3 h-3 mr-1" /> +14 new this month
                  </span>
                </div>

                <div className="bg-white rounded-2xl p-5 border border-slate-200 shadow-card">
                  <span className="text-xs font-bold text-slate-500">Active Teachers</span>
                  <div className="text-2xl font-black text-slate-900 mt-1">12</div>
                  <span className="text-[11px] text-slate-500 mt-1 block">Full-time faculty</span>
                </div>

                <div className="bg-white rounded-2xl p-5 border border-slate-200 shadow-card">
                  <span className="text-xs font-bold text-slate-500">Monthly Revenue</span>
                  <div className="text-2xl font-black text-slate-900 mt-1">₹1,30,000</div>
                  <span className="text-[11px] text-emerald-600 font-semibold mt-1 block">Razorpay + UPI</span>
                </div>

                <div className="bg-white rounded-2xl p-5 border border-slate-200 shadow-card">
                  <span className="text-xs font-bold text-slate-500">Avg Attendance</span>
                  <div className="text-2xl font-black text-slate-900 mt-1">94.2%</div>
                  <span className="text-[11px] text-slate-500 mt-1 block">Across all batches</span>
                </div>
              </div>

              {/* Batches Table */}
              <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-5">
                <h3 className="text-sm font-bold text-slate-900 mb-3">Active Batches Overview</h3>
                <div className="divide-y divide-slate-100 text-xs">
                  {batches.map((b) => (
                    <div key={b.id} className="py-3 flex items-center justify-between">
                      <div>
                        <p className="font-bold text-slate-800">{b.name}</p>
                        <p className="text-slate-500 text-[11px]">{b.teacher} &bull; {b.timing}</p>
                      </div>
                      <span className="font-bold text-indigo-700 bg-indigo-50 px-2.5 py-1 rounded-lg">
                        {b.students} Students
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* STUDENTS TAB */}
          {activeTab === 'students' && (
            <div className="bg-white rounded-2xl border border-slate-200 shadow-card overflow-hidden">
              <div className="p-5 border-b border-slate-200 flex items-center justify-between">
                <div>
                  <h3 className="text-sm font-bold text-slate-900">Enrolled Students</h3>
                  <p className="text-xs text-slate-500">All registered students under your institute</p>
                </div>
                <button
                  onClick={() => setEnrollModal(true)}
                  className="px-3 py-1.5 text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg shadow-sm"
                >
                  + Enroll Student
                </button>
              </div>
              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs text-slate-600">
                  <thead className="bg-slate-50 text-slate-700 uppercase font-bold text-[10px] border-b border-slate-200">
                    <tr>
                      <th className="px-6 py-3">Name</th>
                      <th className="px-6 py-3">Contact</th>
                      <th className="px-6 py-3">Batch</th>
                      <th className="px-6 py-3">Fee Status</th>
                      <th className="px-6 py-3">Status</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {students.map((s) => (
                      <tr key={s.id} className="hover:bg-slate-50">
                        <td className="px-6 py-3.5 font-bold text-slate-900">{s.name}</td>
                        <td className="px-6 py-3.5">{s.phone}</td>
                        <td className="px-6 py-3.5 font-medium">{s.batch}</td>
                        <td className="px-6 py-3.5">
                          <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold ${
                            s.fee === 'Clear' ? 'bg-emerald-100 text-emerald-800' : 'bg-amber-100 text-amber-800'
                          }`}>
                            {s.fee}
                          </span>
                        </td>
                        <td className="px-6 py-3.5">
                          <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-slate-100 text-slate-700">
                            {s.status}
                          </span>
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
            <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-5">
              <h3 className="text-sm font-bold text-slate-900 mb-3">Faculty & Instructors</h3>
              <div className="divide-y divide-slate-100 text-xs">
                {teachers.map((t) => (
                  <div key={t.id} className="py-3 flex items-center justify-between">
                    <div>
                      <p className="font-bold text-slate-800 text-sm">{t.name}</p>
                      <p className="text-slate-500">{t.email} &bull; {t.dept}</p>
                    </div>
                    <span className="font-semibold text-slate-700 bg-slate-100 px-3 py-1 rounded-lg">
                      {t.batch}
                    </span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* BATCHES TAB */}
          {activeTab === 'batches' && (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
              {batches.map((b) => (
                <div key={b.id} className="bg-white rounded-2xl border border-slate-200 shadow-card p-5">
                  <span className="text-[10px] font-bold text-indigo-600 bg-indigo-50 px-2 py-0.5 rounded">
                    Batch Active
                  </span>
                  <h4 className="text-base font-bold text-slate-900 mt-2 mb-1">{b.name}</h4>
                  <p className="text-xs text-slate-500 mb-3">Head: {b.teacher}</p>
                  <p className="text-xs font-semibold text-slate-700">Schedule: {b.timing}</p>
                  <div className="mt-4 pt-3 border-t border-slate-100 flex justify-between items-center text-xs">
                    <span className="font-bold text-slate-900">{b.students} Enrolled</span>
                    <button className="text-indigo-600 font-bold hover:underline">Manage Timetable</button>
                  </div>
                </div>
              ))}
            </div>
          )}

          {/* FEES TAB */}
          {activeTab === 'fees' && (
            <div className="bg-white rounded-2xl border border-slate-200 shadow-card overflow-hidden">
              <div className="p-5 border-b border-slate-200 flex items-center justify-between">
                <div>
                  <h3 className="text-sm font-bold text-slate-900">Fee Transactions</h3>
                  <p className="text-xs text-slate-500">Live payment reconciliations from Razorpay and UPI</p>
                </div>
              </div>
              <div className="divide-y divide-slate-100 text-xs">
                {transactions.map((tx) => (
                  <div key={tx.id} className="p-4 flex items-center justify-between hover:bg-slate-50">
                    <div>
                      <p className="font-bold text-slate-800">{tx.student}</p>
                      <p className="text-[10px] text-slate-400">{tx.id} &bull; {tx.mode}</p>
                    </div>
                    <div className="text-right">
                      <p className="font-black text-slate-900">₹{tx.amount.toLocaleString()}</p>
                      <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${
                        tx.status === 'Paid' ? 'bg-emerald-100 text-emerald-800' : 'bg-amber-100 text-amber-800'
                      }`}>
                        {tx.status}
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* BRANDING TAB */}
          {activeTab === 'branding' && (
            <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-6 max-w-xl text-xs space-y-4">
              <h3 className="text-sm font-bold text-slate-900">Institute Branding</h3>
              <div>
                <label className="block font-semibold text-slate-700 mb-1">Institute Display Name</label>
                <input defaultValue="Apex IIT-JEE & Medical Academy" className="w-full p-2.5 border border-slate-200 rounded-xl" />
              </div>
              <div>
                <label className="block font-semibold text-slate-700 mb-1">Custom Domain</label>
                <input defaultValue="learn.apexacademy.in" className="w-full p-2.5 border border-slate-200 rounded-xl" />
              </div>
              <button className="px-5 py-2.5 font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-xl">
                Save Branding
              </button>
            </div>
          )}
        </div>
      </main>

      {/* Enroll Modal */}
      {enrollModal && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl shadow-elevated border border-slate-200 p-6 max-w-md w-full text-xs">
            <h3 className="text-sm font-bold text-slate-900 mb-1">Enroll New Student</h3>
            <p className="text-slate-500 mb-4">Register student into the academy database.</p>
            <form onSubmit={handleEnroll} className="space-y-3">
              <div>
                <label className="block font-semibold text-slate-700 mb-1">Full Name</label>
                <input required value={newStudentName} onChange={(e) => setNewStudentName(e.target.value)} placeholder="Student Name" className="w-full p-2.5 border border-slate-200 rounded-xl" />
              </div>
              <div>
                <label className="block font-semibold text-slate-700 mb-1">Email</label>
                <input required type="email" value={newStudentEmail} onChange={(e) => setNewStudentEmail(e.target.value)} placeholder="email@gmail.com" className="w-full p-2.5 border border-slate-200 rounded-xl" />
              </div>
              <div>
                <label className="block font-semibold text-slate-700 mb-1">Phone</label>
                <input value={newStudentPhone} onChange={(e) => setNewStudentPhone(e.target.value)} placeholder="+91 98765 43210" className="w-full p-2.5 border border-slate-200 rounded-xl" />
              </div>
              <div className="flex justify-end space-x-2 pt-2">
                <button type="button" onClick={() => setEnrollModal(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-xl">
                  Cancel
                </button>
                <button type="submit" className="px-4 py-2 font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-xl">
                  Enroll
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

export default App;
