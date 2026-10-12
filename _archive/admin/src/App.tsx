import React, { useState, useEffect, useMemo } from 'react';
import {
  LayoutDashboard,
  Users,
  GraduationCap,
  Layers,
  Calendar,
  Plus,
  Search,
  CheckCircle2,
  AlertCircle,
  Trash2,
  Edit,
  Filter,
  LogOut,
  ExternalLink,
  TrendingUp,
  Clock,
  BookOpen,
  RefreshCw,
  Phone,
  Mail,
  MapPin,
  Building,
  ShieldCheck,
  X,
} from 'lucide-react';

interface TeacherItem {
  id: string;
  name: string;
  email: string;
  phone?: string | null;
  status: string;
  coachingName?: string | null;
  centreLogo?: string | null;
  centreAddress?: string | null;
  contactPhone?: string | null;
  bio?: string | null;
  subjects?: string | null;
  createdAt?: string;
  _count?: {
    createdStudents?: number;
    batches?: number;
  };
}

interface BatchItem {
  id: string;
  name: string;
  subject?: string | null;
  description?: string | null;
  schedule?: string | null;
  joinCode?: string;
  teacherId?: string;
  teacher?: {
    id: string;
    name: string;
    email?: string;
    coachingName?: string | null;
  };
  _count?: {
    enrollments?: number;
  };
}

interface TimetableSlot {
  id: string;
  dayOfWeek: string;
  startTime: string;
  endTime: string;
  subject: string;
  room?: string | null;
  teacherId?: string;
  batchId?: string;
  teacher?: {
    id: string;
    name: string;
    coachingName?: string | null;
  };
  batch?: {
    id: string;
    name: string;
  };
}

interface StudentItem {
  id: string;
  name: string;
  email: string;
  phone?: string | null;
  status: string;
  creatorTeacherId?: string | null;
  creatorTeacher?: {
    id: string;
    name: string;
    coachingName?: string | null;
  };
  enrollments?: Array<{
    id: string;
    batch?: {
      id: string;
      name: string;
    };
  }>;
}

const API_BASE = '/api/v1';

export function App() {
  // Authentication State
  const [token, setToken] = useState<string | null>(() => {
    const saved = localStorage.getItem('classora_admin_token');
    return saved && saved !== 'admin-session' ? saved : null;
  });
  const [adminUser, setAdminUser] = useState<any>(() => {
    const saved = localStorage.getItem('classora_admin_user');
    return saved ? JSON.parse(saved) : null;
  });

  // Login form state
  const [loginEmail, setLoginEmail] = useState('admin@apex.edu');
  const [loginPassword, setLoginPassword] = useState('Password@123');
  const [loginError, setLoginError] = useState<string | null>(null);
  const [isLoggingIn, setIsLoggingIn] = useState(false);

  // Active Tab
  const [activeTab, setActiveTab] = useState<'overview' | 'teachers' | 'batches' | 'timetable' | 'students'>('overview');

  // Global & tab filter states
  const [selectedTeacherFilter, setSelectedTeacherFilter] = useState<string>('all');
  const [selectedDayFilter, setSelectedDayFilter] = useState<string>('all');
  const [searchQuery, setSearchQuery] = useState('');

  // Data collections
  const [teachers, setTeachers] = useState<TeacherItem[]>([]);
  const [batches, setBatches] = useState<BatchItem[]>([]);
  const [timetableSlots, setTimetableSlots] = useState<TimetableSlot[]>([]);
  const [students, setStudents] = useState<StudentItem[]>([]);
  const [isLoadingData, setIsLoadingData] = useState(false);
  const [notification, setNotification] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  // Modals state
  const [showAddTeacherModal, setShowAddTeacherModal] = useState(false);
  const [editingTeacher, setEditingTeacher] = useState<TeacherItem | null>(null);
  const [showAddBatchModal, setShowAddBatchModal] = useState(false);
  const [showAddSlotModal, setShowAddSlotModal] = useState(false);
  const [showAddStudentModal, setShowAddStudentModal] = useState(false);

  // Form states
  const [teacherFormData, setTeacherFormData] = useState({
    name: '',
    email: '',
    phone: '',
    password: 'Password@123',
    coachingName: '',
    centreAddress: '',
    contactPhone: '',
    bio: '',
    subjects: '',
  });

  const [batchFormData, setBatchFormData] = useState({
    name: '',
    subject: '',
    description: '',
    schedule: 'Mon, Wed, Fri 18:00',
    teacherId: '',
  });

  const [slotFormData, setSlotFormData] = useState({
    teacherId: '',
    batchId: '',
    dayOfWeek: 'MONDAY',
    startTime: '10:00',
    endTime: '11:30',
    subject: '',
    room: 'Interactive Studio A',
  });

  const [studentFormData, setStudentFormData] = useState({
    name: '',
    email: '',
    phone: '',
    password: 'Password@123',
    teacherId: '',
    batchId: '',
  });

  const showToast = (message: string, type: 'success' | 'error' = 'success') => {
    setNotification({ message, type });
    setTimeout(() => setNotification(null), 4000);
  };

  // Helper for authenticated API calls
  const apiFetch = async (endpoint: string, options: RequestInit = {}) => {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      ...(options.headers as Record<string, string> || {}),
    };
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }
    const res = await fetch(`${API_BASE}${endpoint}`, {
      ...options,
      headers,
    });
    if (!res.ok) {
      const errorData = await res.json().catch(() => ({}));
      throw new Error(errorData.error?.message || errorData.message || `Request failed with status ${res.status}`);
    }
    return res.json();
  };

  // Login handler
  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoggingIn(true);
    setLoginError(null);
    try {
      const res = await fetch(`${API_BASE}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: loginEmail, password: loginPassword }),
      });
      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.error?.message || data.message || 'Login failed');
      }
      if (data.user?.role !== 'ADMIN') {
        throw new Error('Access denied: Only Super Admin can access this console.');
      }
      const actualToken = data.accessToken || data.tokens?.accessToken || '';
      setToken(actualToken);
      setAdminUser(data.user);
      localStorage.setItem('classora_admin_token', actualToken);
      localStorage.setItem('classora_admin_user', JSON.stringify(data.user));
      showToast(`Welcome back, ${data.user.name}!`);
    } catch (err: any) {
      setLoginError(err.message || 'Login failed');
    } finally {
      setIsLoggingIn(false);
    }
  };

  const handleLogout = () => {
    setToken(null);
    setAdminUser(null);
    localStorage.removeItem('classora_admin_token');
    localStorage.removeItem('classora_admin_user');
  };

  // Fetch all core datasets
  const loadAllData = async () => {
    if (!token) return;
    setIsLoadingData(true);
    try {
      // 1. Fetch Teachers
      const teachersRes = await apiFetch('/admin/teachers');
      const loadedTeachers: TeacherItem[] = teachersRes.teachers || teachersRes.data || [];
      setTeachers(loadedTeachers);

      // Default dropdown values if empty
      if (loadedTeachers.length > 0) {
        setBatchFormData((prev) => ({ ...prev, teacherId: prev.teacherId || loadedTeachers[0].id }));
        setSlotFormData((prev) => ({ ...prev, teacherId: prev.teacherId || loadedTeachers[0].id }));
        setStudentFormData((prev) => ({ ...prev, teacherId: prev.teacherId || loadedTeachers[0].id }));
      }

      // 2. Fetch Batches (Admin sees all)
      const batchesRes = await apiFetch('/batches');
      const loadedBatches: BatchItem[] = batchesRes.batches || batchesRes.data || [];
      setBatches(loadedBatches);
      if (loadedBatches.length > 0) {
        setSlotFormData((prev) => ({ ...prev, batchId: prev.batchId || loadedBatches[0].id }));
        setStudentFormData((prev) => ({ ...prev, batchId: prev.batchId || loadedBatches[0].id }));
      }

      // 3. Fetch Timetable Slots
      const timetableRes = await apiFetch('/timetable');
      setTimetableSlots(timetableRes.slots || timetableRes.data || []);

      // 4. Fetch Students
      const studentsRes = await apiFetch('/admin/students');
      setStudents(studentsRes.students || studentsRes.data || []);
    } catch (err: any) {
      showToast(err.message || 'Failed to load institute data', 'error');
    } finally {
      setIsLoadingData(false);
    }
  };

  // Auto-sync polling every 5s for live multi-user updates
  useEffect(() => {
    if (token && token !== 'admin-session') {
      loadAllData();
      const interval = setInterval(() => {
        loadAllData();
      }, 5000);
      return () => clearInterval(interval);
    }
  }, [token]);

  // Filtered views based on selectedTeacherFilter
  const filteredTeachers = useMemo(() => {
    return teachers.filter((t) => {
      const matchesSearch =
        !searchQuery ||
        t.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        t.email.toLowerCase().includes(searchQuery.toLowerCase()) ||
        (t.coachingName && t.coachingName.toLowerCase().includes(searchQuery.toLowerCase())) ||
        (t.subjects && t.subjects.toLowerCase().includes(searchQuery.toLowerCase()));
      return matchesSearch;
    });
  }, [teachers, searchQuery]);

  const filteredBatches = useMemo(() => {
    return batches.filter((b) => {
      const matchesTeacher = selectedTeacherFilter === 'all' || b.teacherId === selectedTeacherFilter;
      const matchesSearch =
        !searchQuery ||
        b.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        (b.subject && b.subject.toLowerCase().includes(searchQuery.toLowerCase())) ||
        (b.teacher?.name && b.teacher.name.toLowerCase().includes(searchQuery.toLowerCase()));
      return matchesTeacher && matchesSearch;
    });
  }, [batches, selectedTeacherFilter, searchQuery]);

  const filteredSlots = useMemo(() => {
    return timetableSlots.filter((s) => {
      const matchesTeacher = selectedTeacherFilter === 'all' || s.teacherId === selectedTeacherFilter;
      const matchesDay = selectedDayFilter === 'all' || s.dayOfWeek.toUpperCase() === selectedDayFilter.toUpperCase();
      const matchesSearch =
        !searchQuery ||
        s.subject.toLowerCase().includes(searchQuery.toLowerCase()) ||
        (s.batch?.name && s.batch.name.toLowerCase().includes(searchQuery.toLowerCase())) ||
        (s.teacher?.name && s.teacher.name.toLowerCase().includes(searchQuery.toLowerCase()));
      return matchesTeacher && matchesDay && matchesSearch;
    });
  }, [timetableSlots, selectedTeacherFilter, selectedDayFilter, searchQuery]);

  const filteredStudents = useMemo(() => {
    return students.filter((s) => {
      const matchesTeacher = selectedTeacherFilter === 'all' || s.creatorTeacherId === selectedTeacherFilter;
      const matchesSearch =
        !searchQuery ||
        s.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        s.email.toLowerCase().includes(searchQuery.toLowerCase()) ||
        (s.creatorTeacher?.coachingName && s.creatorTeacher.coachingName.toLowerCase().includes(searchQuery.toLowerCase()));
      return matchesTeacher && matchesSearch;
    });
  }, [students, selectedTeacherFilter, searchQuery]);

  // Selected teacher details for header info
  const activeTeacherObject = useMemo(() => {
    if (selectedTeacherFilter === 'all') return null;
    return teachers.find((t) => t.id === selectedTeacherFilter) || null;
  }, [teachers, selectedTeacherFilter]);

  // Actions: Add Teacher
  const handleAddTeacher = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const res = await apiFetch('/admin/teachers', {
        method: 'POST',
        body: JSON.stringify(teacherFormData),
      });
      showToast(`Teacher ${res.teacher?.name || teacherFormData.name} created successfully!`);
      setShowAddTeacherModal(false);
      setTeacherFormData({
        name: '',
        email: '',
        phone: '',
        password: 'Password@123',
        coachingName: '',
        centreAddress: '',
        contactPhone: '',
        bio: '',
        subjects: '',
      });
      loadAllData();
    } catch (err: any) {
      showToast(err.message, 'error');
    }
  };

  // Actions: Edit Teacher
  const handleUpdateTeacher = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingTeacher) return;
    try {
      await apiFetch(`/admin/teachers/${editingTeacher.id}`, {
        method: 'PATCH',
        body: JSON.stringify({
          name: editingTeacher.name,
          email: editingTeacher.email,
          phone: editingTeacher.phone,
          coachingName: editingTeacher.coachingName,
          centreAddress: editingTeacher.centreAddress,
          contactPhone: editingTeacher.contactPhone,
          bio: editingTeacher.bio,
          subjects: editingTeacher.subjects,
          status: editingTeacher.status,
        }),
      });
      showToast(`Teacher profile updated successfully!`);
      setEditingTeacher(null);
      loadAllData();
    } catch (err: any) {
      showToast(err.message, 'error');
    }
  };

  // Actions: Toggle Teacher Status
  const handleToggleTeacherStatus = async (teacher: TeacherItem) => {
    const nextStatus = teacher.status === 'ACTIVE' ? 'SUSPENDED' : 'ACTIVE';
    try {
      await apiFetch(`/admin/teachers/${teacher.id}/status`, {
        method: 'PATCH',
        body: JSON.stringify({ status: nextStatus }),
      });
      showToast(`Teacher status changed to ${nextStatus}`);
      loadAllData();
    } catch (err: any) {
      showToast(err.message, 'error');
    }
  };

  // Actions: Delete Teacher
  const handleDeleteTeacher = async (teacher: TeacherItem) => {
    if (!window.confirm(`Are you sure you want to permanently delete "${teacher.name}"? This will deactivate their access.`)) {
      return;
    }
    try {
      await apiFetch(`/admin/teachers/${teacher.id}`, {
        method: 'DELETE',
      });
      showToast(`Teacher ${teacher.name} deleted.`);
      loadAllData();
    } catch (err: any) {
      showToast(err.message, 'error');
    }
  };

  // Actions: Add Batch
  const handleAddBatch = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await apiFetch('/batches', {
        method: 'POST',
        body: JSON.stringify(batchFormData),
      });
      showToast(`Batch "${batchFormData.name}" created!`);
      setShowAddBatchModal(false);
      setBatchFormData((prev) => ({ ...prev, name: '', subject: '', description: '' }));
      loadAllData();
    } catch (err: any) {
      showToast(err.message, 'error');
    }
  };

  // Actions: Delete Batch
  const handleDeleteBatch = async (batchId: string, batchName: string) => {
    if (!window.confirm(`Delete batch "${batchName}"?`)) return;
    try {
      await apiFetch(`/batches/${batchId}`, { method: 'DELETE' });
      showToast(`Batch deleted.`);
      loadAllData();
    } catch (err: any) {
      showToast(err.message, 'error');
    }
  };

  // Actions: Add Timetable Slot
  const handleAddSlot = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await apiFetch('/timetable', {
        method: 'POST',
        body: JSON.stringify(slotFormData),
      });
      showToast(`Timetable slot added for ${slotFormData.dayOfWeek}!`);
      setShowAddSlotModal(false);
      loadAllData();
    } catch (err: any) {
      showToast(err.message, 'error');
    }
  };

  // Actions: Delete Timetable Slot
  const handleDeleteSlot = async (slotId: string) => {
    if (!window.confirm('Delete this timetable slot?')) return;
    try {
      await apiFetch(`/timetable/${slotId}`, { method: 'DELETE' });
      showToast('Timetable slot removed.');
      loadAllData();
    } catch (err: any) {
      showToast(err.message, 'error');
    }
  };

  // Actions: Add Student
  const handleAddStudent = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await apiFetch('/admin/students', {
        method: 'POST',
        body: JSON.stringify(studentFormData),
      });
      showToast(`Student ${studentFormData.name} enrolled successfully!`);
      setShowAddStudentModal(false);
      setStudentFormData((prev) => ({
        ...prev,
        name: '',
        email: '',
        phone: '',
      }));
      loadAllData();
    } catch (err: any) {
      showToast(err.message, 'error');
    }
  };

  // If not logged in, render the Clean Admin Login Screen
  if (!token || !adminUser) {
    return (
      <div className="min-h-screen bg-slate-900 flex flex-col justify-center items-center p-4 font-sans text-slate-100">
        <div className="mb-6 flex flex-col items-center text-center">
          <div className="w-14 h-14 rounded-2xl bg-indigo-600 flex items-center justify-center text-white font-black text-2xl shadow-xl shadow-indigo-600/30 mb-3 border border-indigo-400/20">
            C
          </div>
          <h1 className="text-2xl font-black text-white tracking-tight">Classora Super Admin</h1>
          <p className="text-xs text-slate-400 mt-1">Multi-Tenant LMS & Coaching Isolation Console</p>
        </div>

        <div className="bg-slate-800/90 border border-slate-700/80 rounded-3xl p-8 max-w-md w-full shadow-2xl backdrop-blur-md">
          <div className="flex items-center space-x-3 pb-5 border-b border-slate-700/60 mb-6">
            <div className="w-10 h-10 rounded-xl bg-indigo-500/20 text-indigo-400 flex items-center justify-center border border-indigo-500/30">
              <ShieldCheck className="w-5 h-5" />
            </div>
            <div>
              <span className="text-[10px] font-black uppercase tracking-wider text-indigo-400 bg-indigo-950/60 px-2 py-0.5 rounded border border-indigo-800/40">
                Institutional Super Admin
              </span>
              <h2 className="text-sm font-bold text-white mt-1">Apex Education Institute</h2>
            </div>
          </div>

          {loginError && (
            <div className="mb-5 p-3 rounded-xl bg-rose-500/10 border border-rose-500/30 text-rose-300 text-xs flex items-center space-x-2">
              <AlertCircle className="w-4 h-4 shrink-0" />
              <span>{loginError}</span>
            </div>
          )}

          <form onSubmit={handleLogin} className="space-y-4 text-xs">
            <div>
              <label className="block text-slate-300 font-semibold mb-1.5">Super Admin Email</label>
              <input
                type="email"
                required
                value={loginEmail}
                onChange={(e) => setLoginEmail(e.target.value)}
                placeholder="admin@apex.edu"
                className="w-full px-3.5 py-2.5 rounded-xl bg-slate-900/80 border border-slate-700 text-slate-100 placeholder-slate-500 focus:outline-none focus:border-indigo-500"
              />
            </div>

            <div>
              <label className="block text-slate-300 font-semibold mb-1.5">Password</label>
              <input
                type="password"
                required
                value={loginPassword}
                onChange={(e) => setLoginPassword(e.target.value)}
                placeholder="••••••••••••"
                className="w-full px-3.5 py-2.5 rounded-xl bg-slate-900/80 border border-slate-700 text-slate-100 placeholder-slate-500 focus:outline-none focus:border-indigo-500"
              />
            </div>

            <button
              type="submit"
              disabled={isLoggingIn}
              className="w-full mt-2 py-3 px-4 rounded-xl font-bold text-white bg-indigo-600 hover:bg-indigo-500 active:scale-[0.99] transition-all shadow-lg shadow-indigo-600/30 flex items-center justify-center space-x-2 disabled:opacity-50"
            >
              {isLoggingIn ? (
                <RefreshCw className="w-4 h-4 animate-spin" />
              ) : (
                <>
                  <ShieldCheck className="w-4 h-4" />
                  <span>Access Admin Console</span>
                </>
              )}
            </button>

            <button
              type="button"
              onClick={() => {
                setLoginEmail('admin@apex.edu');
                setLoginPassword('Password@123');
              }}
              className="w-full py-2 text-slate-400 hover:text-slate-200 text-center text-[11px] underline"
            >
              Autofill Demo Credentials (admin@apex.edu)
            </button>
          </form>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 flex font-sans">
      {/* Toast Notification */}
      {notification && (
        <div
          className={`fixed top-4 right-4 z-50 flex items-center space-x-2 px-4 py-3 rounded-2xl shadow-elevated border text-xs font-semibold animate-in fade-in slide-in-from-top-4 ${
            notification.type === 'success'
              ? 'bg-emerald-50 text-emerald-800 border-emerald-200'
              : 'bg-rose-50 text-rose-800 border-rose-200'
          }`}
        >
          {notification.type === 'success' ? (
            <CheckCircle2 className="w-4 h-4 text-emerald-600" />
          ) : (
            <AlertCircle className="w-4 h-4 text-rose-600" />
          )}
          <span>{notification.message}</span>
        </div>
      )}

      {/* Sidebar Navigation */}
      <aside className="w-64 bg-white border-r border-slate-200 flex flex-col justify-between p-4 shadow-subtle shrink-0">
        <div>
          {/* Logo & Institute Header */}
          <div className="flex items-center space-x-3 pb-6 border-b border-slate-100">
            <div className="w-10 h-10 rounded-2xl bg-indigo-600 flex items-center justify-center text-white font-extrabold text-lg shadow-md shadow-indigo-500/20">
              C
            </div>
            <div>
              <h2 className="text-sm font-extrabold text-slate-900 leading-tight">Apex Academy</h2>
              <span className="text-[10px] font-bold text-indigo-600 uppercase tracking-widest block">
                Super Admin Console
              </span>
            </div>
          </div>

          {/* Navigation Links */}
          <nav className="mt-6 space-y-1.5 text-xs font-semibold">
            <button
              onClick={() => setActiveTab('overview')}
              className={`w-full flex items-center space-x-3 px-3.5 py-2.5 rounded-xl transition-all ${
                activeTab === 'overview'
                  ? 'bg-indigo-50 text-indigo-700 shadow-xs font-bold'
                  : 'text-slate-600 hover:bg-slate-100/70 hover:text-slate-900'
              }`}
            >
              <LayoutDashboard className="w-4 h-4" />
              <span>Overview & KPIs</span>
            </button>

            <button
              onClick={() => setActiveTab('teachers')}
              className={`w-full flex items-center space-x-3 px-3.5 py-2.5 rounded-xl transition-all ${
                activeTab === 'teachers'
                  ? 'bg-indigo-50 text-indigo-700 shadow-xs font-bold'
                  : 'text-slate-600 hover:bg-slate-100/70 hover:text-slate-900'
              }`}
            >
              <GraduationCap className="w-4 h-4" />
              <span>Teachers & Coaching</span>
              <span className="ml-auto text-[10px] font-bold px-1.5 py-0.5 rounded-full bg-slate-100 text-slate-600">
                {teachers.length}
              </span>
            </button>

            <button
              onClick={() => setActiveTab('batches')}
              className={`w-full flex items-center space-x-3 px-3.5 py-2.5 rounded-xl transition-all ${
                activeTab === 'batches'
                  ? 'bg-indigo-50 text-indigo-700 shadow-xs font-bold'
                  : 'text-slate-600 hover:bg-slate-100/70 hover:text-slate-900'
              }`}
            >
              <Layers className="w-4 h-4" />
              <span>Batches & Courses</span>
              <span className="ml-auto text-[10px] font-bold px-1.5 py-0.5 rounded-full bg-slate-100 text-slate-600">
                {batches.length}
              </span>
            </button>

            <button
              onClick={() => setActiveTab('timetable')}
              className={`w-full flex items-center space-x-3 px-3.5 py-2.5 rounded-xl transition-all ${
                activeTab === 'timetable'
                  ? 'bg-indigo-50 text-indigo-700 shadow-xs font-bold'
                  : 'text-slate-600 hover:bg-slate-100/70 hover:text-slate-900'
              }`}
            >
              <Calendar className="w-4 h-4" />
              <span>Timetable Slots</span>
              <span className="ml-auto text-[10px] font-bold px-1.5 py-0.5 rounded-full bg-slate-100 text-slate-600">
                {timetableSlots.length}
              </span>
            </button>

            <button
              onClick={() => setActiveTab('students')}
              className={`w-full flex items-center space-x-3 px-3.5 py-2.5 rounded-xl transition-all ${
                activeTab === 'students'
                  ? 'bg-indigo-50 text-indigo-700 shadow-xs font-bold'
                  : 'text-slate-600 hover:bg-slate-100/70 hover:text-slate-900'
              }`}
            >
              <Users className="w-4 h-4" />
              <span>Students Directory</span>
              <span className="ml-auto text-[10px] font-bold px-1.5 py-0.5 rounded-full bg-slate-100 text-slate-600">
                {students.length}
              </span>
            </button>
          </nav>
        </div>

        {/* Quick App Status & System Info */}
        <div className="space-y-3">
          <div className="bg-slate-50 border border-slate-200/80 rounded-2xl p-3 text-[11px] space-y-2">
            <div className="flex items-center justify-between">
              <span className="font-bold text-slate-500 uppercase tracking-wider text-[9px]">Backend API</span>
              <span className="inline-flex items-center px-1.5 py-0.5 rounded-full text-[9px] font-bold bg-emerald-100 text-emerald-800">
                Live (Port 4000)
              </span>
            </div>
            <div className="flex items-center justify-between text-slate-600">
              <span>Isolation Engine</span>
              <span className="font-bold text-indigo-600">Strict Teacher-Scoping</span>
            </div>
          </div>

          <div className="pt-2 border-t border-slate-100 flex items-center justify-between text-xs">
            <div className="truncate pr-2">
              <p className="font-bold text-slate-900 truncate">{adminUser.name}</p>
              <p className="text-[10px] text-slate-400 truncate">{adminUser.email}</p>
            </div>
            <button
              onClick={handleLogout}
              title="Sign Out"
              className="p-2 text-slate-400 hover:text-rose-600 hover:bg-rose-50 rounded-xl transition-colors shrink-0"
            >
              <LogOut className="w-4 h-4" />
            </button>
          </div>
        </div>
      </aside>

      {/* Main Content Area */}
      <main className="flex-1 flex flex-col h-screen overflow-y-auto">
        {/* Top Header Bar */}
        <header className="h-16 bg-white border-b border-slate-200 px-6 flex items-center justify-between shrink-0 sticky top-0 z-20 shadow-xs">
          <div className="flex items-center space-x-4">
            <h1 className="text-base font-extrabold text-slate-900 capitalize">
              {activeTab === 'overview' && 'Institute Overview & Analytics'}
              {activeTab === 'teachers' && 'Teacher & Coaching Center Profiles'}
              {activeTab === 'batches' && 'Batches & Course Management'}
              {activeTab === 'timetable' && 'Weekly Timetable Slot Manager'}
              {activeTab === 'students' && 'Students Directory & Teacher Assignments'}
            </h1>

            {isLoadingData && (
              <span className="inline-flex items-center text-xs text-indigo-600 font-semibold animate-pulse">
                <RefreshCw className="w-3.5 h-3.5 mr-1 animate-spin" /> Syncing...
              </span>
            )}
          </div>

          {/* Teacher Filter Dropdown (Universal) */}
          <div className="flex items-center space-x-3">
            <div className="flex items-center space-x-2 bg-slate-50 border border-slate-200/90 rounded-xl px-3 py-1.5 text-xs shadow-xs">
              <Filter className="w-3.5 h-3.5 text-indigo-600" />
              <span className="font-semibold text-slate-500 text-[11px]">Filter Teacher:</span>
              <select
                value={selectedTeacherFilter}
                onChange={(e) => setSelectedTeacherFilter(e.target.value)}
                className="bg-transparent font-bold text-slate-800 text-xs focus:outline-none cursor-pointer pr-1"
              >
                <option value="all">All Teachers ({teachers.length})</option>
                {teachers.map((t) => (
                  <option key={t.id} value={t.id}>
                    {t.name} {t.coachingName ? `(${t.coachingName})` : ''}
                  </option>
                ))}
              </select>
            </div>

            <button
              onClick={loadAllData}
              title="Refresh Data"
              className="p-2 text-slate-500 hover:text-indigo-600 hover:bg-indigo-50 rounded-xl border border-slate-200 transition-colors"
            >
              <RefreshCw className="w-4 h-4" />
            </button>
          </div>
        </header>

        {/* Content Body */}
        <div className="p-6 space-y-6">
          {/* Active Teacher Banner if filtered */}
          {activeTeacherObject && (
            <div className="bg-gradient-to-r from-indigo-500/10 via-purple-500/5 to-transparent border border-indigo-200 rounded-2xl p-4 flex items-center justify-between">
              <div className="flex items-center space-x-3">
                <div className="w-10 h-10 rounded-xl bg-indigo-600 text-white font-black flex items-center justify-center text-sm shadow-sm">
                  {activeTeacherObject.name[0]}
                </div>
                <div>
                  <div className="flex items-center space-x-2">
                    <h3 className="font-extrabold text-slate-900 text-sm">{activeTeacherObject.name}</h3>
                    <span className="text-[10px] font-black uppercase px-2 py-0.5 rounded-full bg-indigo-100 text-indigo-800">
                      {activeTeacherObject.coachingName || 'Faculty Profile'}
                    </span>
                  </div>
                  <p className="text-xs text-slate-500 mt-0.5">
                    {activeTeacherObject.subjects || 'General Curriculum'} &bull; {activeTeacherObject.email} &bull; {activeTeacherObject.contactPhone || activeTeacherObject.phone || 'No phone'}
                  </p>
                </div>
              </div>
              <button
                onClick={() => setSelectedTeacherFilter('all')}
                className="text-xs font-bold text-indigo-600 hover:text-indigo-800 hover:underline px-3 py-1.5"
              >
                Clear Filter &times;
              </button>
            </div>
          )}

          {/* TAB 1: OVERVIEW */}
          {activeTab === 'overview' && (
            <div className="space-y-6">
              {/* KPI Cards */}
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
                <div className="bg-white rounded-2xl p-5 border border-slate-200 shadow-card">
                  <div className="flex items-center justify-between text-slate-500 text-xs font-bold">
                    <span>Total Teachers</span>
                    <GraduationCap className="w-4 h-4 text-indigo-500" />
                  </div>
                  <div className="text-2xl font-black text-slate-900 mt-2">{teachers.length}</div>
                  <span className="text-[11px] text-emerald-600 font-semibold flex items-center mt-1">
                    <TrendingUp className="w-3 h-3 mr-1" /> Active Faculty Members
                  </span>
                </div>

                <div className="bg-white rounded-2xl p-5 border border-slate-200 shadow-card">
                  <div className="flex items-center justify-between text-slate-500 text-xs font-bold">
                    <span>Active Batches</span>
                    <Layers className="w-4 h-4 text-indigo-500" />
                  </div>
                  <div className="text-2xl font-black text-slate-900 mt-2">{filteredBatches.length}</div>
                  <span className="text-[11px] text-slate-500 mt-1 block">
                    {selectedTeacherFilter === 'all' ? 'Across all faculty' : 'For selected teacher'}
                  </span>
                </div>

                <div className="bg-white rounded-2xl p-5 border border-slate-200 shadow-card">
                  <div className="flex items-center justify-between text-slate-500 text-xs font-bold">
                    <span>Enrolled Students</span>
                    <Users className="w-4 h-4 text-indigo-500" />
                  </div>
                  <div className="text-2xl font-black text-slate-900 mt-2">{filteredStudents.length}</div>
                  <span className="text-[11px] text-emerald-600 font-semibold mt-1 block">
                    Strictly isolated by teacher
                  </span>
                </div>

                <div className="bg-white rounded-2xl p-5 border border-slate-200 shadow-card">
                  <div className="flex items-center justify-between text-slate-500 text-xs font-bold">
                    <span>Timetable Slots</span>
                    <Calendar className="w-4 h-4 text-indigo-500" />
                  </div>
                  <div className="text-2xl font-black text-slate-900 mt-2">{filteredSlots.length}</div>
                  <span className="text-[11px] text-slate-500 mt-1 block">Scheduled live sessions</span>
                </div>
              </div>

              {/* Batches & Teachers Grid */}
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                {/* Batches Quick View */}
                <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-5">
                  <div className="flex items-center justify-between mb-4">
                    <h3 className="text-sm font-bold text-slate-900">Batches & Courses</h3>
                    <button
                      onClick={() => setActiveTab('batches')}
                      className="text-xs font-bold text-indigo-600 hover:underline"
                    >
                      View All &rarr;
                    </button>
                  </div>
                  <div className="divide-y divide-slate-100 text-xs">
                    {filteredBatches.slice(0, 4).map((b) => (
                      <div key={b.id} className="py-3 flex items-center justify-between">
                        <div>
                          <p className="font-bold text-slate-800">{b.name}</p>
                          <p className="text-slate-500 text-[11px]">
                            {b.teacher?.name || 'Assigned Faculty'} &bull; {b.subject || 'All Subjects'}
                          </p>
                        </div>
                        <span className="font-bold text-indigo-700 bg-indigo-50 px-2.5 py-1 rounded-lg">
                          {b._count?.enrollments || 0} Students
                        </span>
                      </div>
                    ))}
                    {filteredBatches.length === 0 && (
                      <p className="py-4 text-center text-slate-400">No batches found for this view.</p>
                    )}
                  </div>
                </div>

                {/* Faculty & Coaching Branding */}
                <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-5">
                  <div className="flex items-center justify-between mb-4">
                    <h3 className="text-sm font-bold text-slate-900">Faculty & Coaching Centres</h3>
                    <button
                      onClick={() => setActiveTab('teachers')}
                      className="text-xs font-bold text-indigo-600 hover:underline"
                    >
                      Manage &rarr;
                    </button>
                  </div>
                  <div className="divide-y divide-slate-100 text-xs">
                    {teachers.slice(0, 4).map((t) => (
                      <div key={t.id} className="py-3 flex items-center justify-between">
                        <div>
                          <p className="font-bold text-slate-800">{t.name}</p>
                          <p className="text-slate-500 text-[11px]">
                            {t.coachingName || 'Independent Tutor'} &bull; {t.subjects || 'General'}
                          </p>
                        </div>
                        <span className="font-bold text-emerald-700 bg-emerald-50 px-2.5 py-1 rounded-lg text-[10px]">
                          {t._count?.batches || 0} Batches &bull; {t._count?.createdStudents || 0} Students
                        </span>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* TAB 2: TEACHERS MANAGEMENT */}
          {activeTab === 'teachers' && (
            <div className="bg-white rounded-2xl border border-slate-200 shadow-card overflow-hidden">
              <div className="p-5 border-b border-slate-200 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                <div>
                  <h3 className="text-sm font-bold text-slate-900">Teachers & Coaching Institutes</h3>
                  <p className="text-xs text-slate-500">
                    Each teacher operates their own branded classroom and student isolation silo.
                  </p>
                </div>
                <div className="flex items-center space-x-3">
                  <div className="relative">
                    <Search className="w-3.5 h-3.5 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                    <input
                      type="text"
                      placeholder="Search teachers..."
                      value={searchQuery}
                      onChange={(e) => setSearchQuery(e.target.value)}
                      className="pl-8 pr-3 py-1.5 text-xs border border-slate-200 rounded-xl w-48 focus:outline-none focus:border-indigo-500"
                    />
                  </div>
                  <button
                    onClick={() => setShowAddTeacherModal(true)}
                    className="px-3.5 py-2 text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-xl shadow-xs flex items-center space-x-1.5"
                  >
                    <Plus className="w-3.5 h-3.5" />
                    <span>Add New Teacher</span>
                  </button>
                </div>
              </div>

              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs text-slate-600">
                  <thead className="bg-slate-50 text-slate-700 uppercase font-bold text-[10px] border-b border-slate-200">
                    <tr>
                      <th className="px-6 py-3.5">Faculty Name & Email</th>
                      <th className="px-6 py-3.5">Coaching Centre Brand</th>
                      <th className="px-6 py-3.5">Subjects</th>
                      <th className="px-6 py-3.5">Contact Phone</th>
                      <th className="px-6 py-3.5">Workload</th>
                      <th className="px-6 py-3.5">Status</th>
                      <th className="px-6 py-3.5 text-right">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {filteredTeachers.map((t) => (
                      <tr key={t.id} className="hover:bg-slate-50/70 transition-colors">
                        <td className="px-6 py-3.5">
                          <p className="font-bold text-slate-900">{t.name}</p>
                          <p className="text-[11px] text-slate-400">{t.email}</p>
                        </td>
                        <td className="px-6 py-3.5">
                          <span className="font-semibold text-indigo-700 bg-indigo-50/80 px-2.5 py-1 rounded-lg">
                            {t.coachingName || 'Standard Faculty'}
                          </span>
                        </td>
                        <td className="px-6 py-3.5 font-medium">{t.subjects || 'General'}</td>
                        <td className="px-6 py-3.5">{t.contactPhone || t.phone || '—'}</td>
                        <td className="px-6 py-3.5 font-medium">
                          <span className="text-slate-800 font-bold">{t._count?.batches || 0}</span> batches &bull;{' '}
                          <span className="text-slate-800 font-bold">{t._count?.createdStudents || 0}</span> students
                        </td>
                        <td className="px-6 py-3.5">
                          <button
                            onClick={() => handleToggleTeacherStatus(t)}
                            className={`px-2.5 py-0.5 rounded-full text-[10px] font-bold transition-all ${
                              t.status === 'ACTIVE'
                                ? 'bg-emerald-100 text-emerald-800 hover:bg-emerald-200'
                                : 'bg-rose-100 text-rose-800 hover:bg-rose-200'
                            }`}
                          >
                            {t.status}
                          </button>
                        </td>
                        <td className="px-6 py-3.5 text-right space-x-2">
                          <button
                            onClick={() => setEditingTeacher(t)}
                            title="Edit Teacher"
                            className="p-1.5 text-slate-400 hover:text-indigo-600 hover:bg-indigo-50 rounded-lg transition-colors"
                          >
                            <Edit className="w-3.5 h-3.5" />
                          </button>
                          <button
                            onClick={() => handleDeleteTeacher(t)}
                            title="Delete Teacher"
                            className="p-1.5 text-slate-400 hover:text-rose-600 hover:bg-rose-50 rounded-lg transition-colors"
                          >
                            <Trash2 className="w-3.5 h-3.5" />
                          </button>
                        </td>
                      </tr>
                    ))}
                    {filteredTeachers.length === 0 && (
                      <tr>
                        <td colSpan={7} className="text-center py-8 text-slate-400">
                          No teachers match current search.
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {/* TAB 3: BATCHES & COURSES */}
          {activeTab === 'batches' && (
            <div className="space-y-4">
              <div className="bg-white rounded-2xl border border-slate-200 shadow-card p-5 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                <div>
                  <h3 className="text-sm font-bold text-slate-900">Institute Batches & Courses</h3>
                  <p className="text-xs text-slate-500">
                    Courses created under individual faculty members with unique join codes.
                  </p>
                </div>
                <div className="flex items-center space-x-3">
                  <div className="relative">
                    <Search className="w-3.5 h-3.5 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                    <input
                      type="text"
                      placeholder="Search batches..."
                      value={searchQuery}
                      onChange={(e) => setSearchQuery(e.target.value)}
                      className="pl-8 pr-3 py-1.5 text-xs border border-slate-200 rounded-xl w-48 focus:outline-none focus:border-indigo-500"
                    />
                  </div>
                  <button
                    onClick={() => setShowAddBatchModal(true)}
                    className="px-3.5 py-2 text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-xl shadow-xs flex items-center space-x-1.5"
                  >
                    <Plus className="w-3.5 h-3.5" />
                    <span>Create Batch</span>
                  </button>
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
                {filteredBatches.map((b) => (
                  <div key={b.id} className="bg-white rounded-2xl border border-slate-200 shadow-card p-5 flex flex-col justify-between">
                    <div>
                      <div className="flex items-center justify-between">
                        <span className="text-[10px] font-black uppercase text-indigo-700 bg-indigo-50 px-2 py-0.5 rounded">
                          {b.subject || 'Standard Batch'}
                        </span>
                        <button
                          onClick={() => handleDeleteBatch(b.id, b.name)}
                          className="p-1 text-slate-400 hover:text-rose-600 rounded"
                          title="Delete Batch"
                        >
                          <Trash2 className="w-3.5 h-3.5" />
                        </button>
                      </div>

                      <h4 className="text-base font-extrabold text-slate-900 mt-2 mb-1">{b.name}</h4>
                      <p className="text-xs text-slate-500 line-clamp-2 mb-3">{b.description || 'Interactive live classroom batch.'}</p>

                      <div className="bg-slate-50 border border-slate-100 rounded-xl p-2.5 text-xs space-y-1">
                        <p className="text-slate-700 font-semibold flex items-center">
                          <GraduationCap className="w-3.5 h-3.5 mr-1 text-indigo-600" />
                          <span>{b.teacher?.name || 'Faculty Member'}</span>
                        </p>
                        {b.teacher?.coachingName && (
                          <p className="text-[11px] text-slate-500 pl-4">{b.teacher.coachingName}</p>
                        )}
                        <p className="text-slate-600 text-[11px] flex items-center pt-1">
                          <Clock className="w-3 h-3 mr-1 text-slate-400" />
                          <span>{b.schedule || 'Daily Sessions'}</span>
                        </p>
                      </div>
                    </div>

                    <div className="mt-4 pt-3 border-t border-slate-100 flex items-center justify-between text-xs">
                      <span className="font-bold text-slate-800">
                        {b._count?.enrollments || 0} Students Enrolled
                      </span>
                      {b.joinCode && (
                        <span className="font-mono text-[10px] font-bold bg-slate-100 text-slate-700 px-2 py-1 rounded">
                          Code: {b.joinCode}
                        </span>
                      )}
                    </div>
                  </div>
                ))}

                {filteredBatches.length === 0 && (
                  <div className="col-span-full py-12 text-center text-slate-400 bg-white rounded-2xl border border-slate-200">
                    No batches found. Click "+ Create Batch" to add one.
                  </div>
                )}
              </div>
            </div>
          )}

          {/* TAB 4: TIMETABLE SLOTS */}
          {activeTab === 'timetable' && (
            <div className="bg-white rounded-2xl border border-slate-200 shadow-card overflow-hidden">
              <div className="p-5 border-b border-slate-200 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                <div>
                  <h3 className="text-sm font-bold text-slate-900">Weekly Timetable Schedule & Conflict Prevention</h3>
                  <p className="text-xs text-slate-500">
                    Live class slots mapped by faculty and batch with automated overlap validation.
                  </p>
                </div>
                <div className="flex items-center space-x-3">
                  {/* Day filter */}
                  <select
                    value={selectedDayFilter}
                    onChange={(e) => setSelectedDayFilter(e.target.value)}
                    className="px-3 py-1.5 text-xs font-semibold border border-slate-200 rounded-xl bg-slate-50 text-slate-800 focus:outline-none"
                  >
                    <option value="all">All Days</option>
                    <option value="MONDAY">Monday</option>
                    <option value="TUESDAY">Tuesday</option>
                    <option value="WEDNESDAY">Wednesday</option>
                    <option value="THURSDAY">Thursday</option>
                    <option value="FRIDAY">Friday</option>
                    <option value="SATURDAY">Saturday</option>
                    <option value="SUNDAY">Sunday</option>
                  </select>

                  <button
                    onClick={() => setShowAddSlotModal(true)}
                    className="px-3.5 py-2 text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-xl shadow-xs flex items-center space-x-1.5"
                  >
                    <Plus className="w-3.5 h-3.5" />
                    <span>Add Timetable Slot</span>
                  </button>
                </div>
              </div>

              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs text-slate-600">
                  <thead className="bg-slate-50 text-slate-700 uppercase font-bold text-[10px] border-b border-slate-200">
                    <tr>
                      <th className="px-6 py-3.5">Day & Timing</th>
                      <th className="px-6 py-3.5">Subject / Topic</th>
                      <th className="px-6 py-3.5">Assigned Teacher & Coaching</th>
                      <th className="px-6 py-3.5">Target Batch</th>
                      <th className="px-6 py-3.5">Studio / Room</th>
                      <th className="px-6 py-3.5 text-right">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {filteredSlots.map((s) => (
                      <tr key={s.id} className="hover:bg-slate-50/70 transition-colors">
                        <td className="px-6 py-3.5">
                          <span className="font-extrabold text-indigo-700 bg-indigo-50 px-2 py-0.5 rounded text-[10px] block w-fit mb-1">
                            {s.dayOfWeek}
                          </span>
                          <span className="font-mono text-slate-900 font-bold text-xs">
                            {s.startTime} – {s.endTime}
                          </span>
                        </td>
                        <td className="px-6 py-3.5 font-bold text-slate-900">{s.subject}</td>
                        <td className="px-6 py-3.5">
                          <p className="font-bold text-slate-800">{s.teacher?.name || 'Faculty Member'}</p>
                          <p className="text-[10px] text-slate-400">{s.teacher?.coachingName || 'Apex Academy'}</p>
                        </td>
                        <td className="px-6 py-3.5 font-medium">{s.batch?.name || 'Assigned Batch'}</td>
                        <td className="px-6 py-3.5 text-slate-500">{s.room || 'Live Studio'}</td>
                        <td className="px-6 py-3.5 text-right">
                          <button
                            onClick={() => handleDeleteSlot(s.id)}
                            title="Delete Slot"
                            className="p-1.5 text-slate-400 hover:text-rose-600 hover:bg-rose-50 rounded-lg transition-colors"
                          >
                            <Trash2 className="w-3.5 h-3.5" />
                          </button>
                        </td>
                      </tr>
                    ))}
                    {filteredSlots.length === 0 && (
                      <tr>
                        <td colSpan={6} className="text-center py-8 text-slate-400">
                          No timetable slots scheduled for this filter.
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {/* TAB 5: STUDENTS DIRECTORY */}
          {activeTab === 'students' && (
            <div className="bg-white rounded-2xl border border-slate-200 shadow-card overflow-hidden">
              <div className="p-5 border-b border-slate-200 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                <div>
                  <h3 className="text-sm font-bold text-slate-900">Enrolled Students Directory</h3>
                  <p className="text-xs text-slate-500">
                    Students are strictly isolated and linked to their assigned teacher.
                  </p>
                </div>
                <div className="flex items-center space-x-3">
                  <div className="relative">
                    <Search className="w-3.5 h-3.5 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                    <input
                      type="text"
                      placeholder="Search students..."
                      value={searchQuery}
                      onChange={(e) => setSearchQuery(e.target.value)}
                      className="pl-8 pr-3 py-1.5 text-xs border border-slate-200 rounded-xl w-48 focus:outline-none focus:border-indigo-500"
                    />
                  </div>
                  <button
                    onClick={() => setShowAddStudentModal(true)}
                    className="px-3.5 py-2 text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-xl shadow-xs flex items-center space-x-1.5"
                  >
                    <Plus className="w-3.5 h-3.5" />
                    <span>Enroll Student</span>
                  </button>
                </div>
              </div>

              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs text-slate-600">
                  <thead className="bg-slate-50 text-slate-700 uppercase font-bold text-[10px] border-b border-slate-200">
                    <tr>
                      <th className="px-6 py-3.5">Student Name & Contact</th>
                      <th className="px-6 py-3.5">Assigned Teacher</th>
                      <th className="px-6 py-3.5">Teacher Coaching Brand</th>
                      <th className="px-6 py-3.5">Enrolled Batch</th>
                      <th className="px-6 py-3.5">Status</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {filteredStudents.map((s) => (
                      <tr key={s.id} className="hover:bg-slate-50/70 transition-colors">
                        <td className="px-6 py-3.5">
                          <p className="font-bold text-slate-900">{s.name}</p>
                          <p className="text-[11px] text-slate-400">{s.email} &bull; {s.phone || 'No phone'}</p>
                        </td>
                        <td className="px-6 py-3.5 font-bold text-indigo-700">
                          {s.creatorTeacher?.name || 'Institute Direct'}
                        </td>
                        <td className="px-6 py-3.5">
                          <span className="font-semibold text-slate-700 bg-slate-100 px-2 py-0.5 rounded text-[11px]">
                            {s.creatorTeacher?.coachingName || 'General Academy'}
                          </span>
                        </td>
                        <td className="px-6 py-3.5 font-medium">
                          {s.enrollments && s.enrollments.length > 0
                            ? s.enrollments.map((e) => e.batch?.name).filter(Boolean).join(', ')
                            : 'Unassigned Batch'}
                        </td>
                        <td className="px-6 py-3.5">
                          <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-emerald-100 text-emerald-800">
                            {s.status}
                          </span>
                        </td>
                      </tr>
                    ))}
                    {filteredStudents.length === 0 && (
                      <tr>
                        <td colSpan={5} className="text-center py-8 text-slate-400">
                          No students found matching this criteria.
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </div>
      </main>

      {/* MODAL: ADD TEACHER */}
      {showAddTeacherModal && (
        <div className="fixed inset-0 bg-slate-900/50 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-3xl shadow-elevated border border-slate-200 p-6 max-w-lg w-full text-xs">
            <div className="flex items-center justify-between pb-3 border-b border-slate-100 mb-4">
              <div>
                <h3 className="text-sm font-extrabold text-slate-900">Add New Teacher & Coaching Center</h3>
                <p className="text-slate-500 text-[11px]">Creates a separate branded teacher profile with student isolation.</p>
              </div>
              <button onClick={() => setShowAddTeacherModal(false)} className="text-slate-400 hover:text-slate-600">
                <X className="w-4 h-4" />
              </button>
            </div>

            <form onSubmit={handleAddTeacher} className="space-y-3">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-bold text-slate-700 mb-1">Teacher Full Name *</label>
                  <input
                    required
                    value={teacherFormData.name}
                    onChange={(e) => setTeacherFormData({ ...teacherFormData, name: e.target.value })}
                    placeholder="e.g. Prof. Rajesh Sharma"
                    className="w-full p-2.5 border border-slate-200 rounded-xl focus:outline-none focus:border-indigo-500"
                  />
                </div>
                <div>
                  <label className="block font-bold text-slate-700 mb-1">Email Address *</label>
                  <input
                    required
                    type="email"
                    value={teacherFormData.email}
                    onChange={(e) => setTeacherFormData({ ...teacherFormData, email: e.target.value })}
                    placeholder="teacher@apex.edu"
                    className="w-full p-2.5 border border-slate-200 rounded-xl focus:outline-none focus:border-indigo-500"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-bold text-slate-700 mb-1">Default Password</label>
                  <input
                    type="text"
                    value={teacherFormData.password}
                    onChange={(e) => setTeacherFormData({ ...teacherFormData, password: e.target.value })}
                    className="w-full p-2.5 border border-slate-200 rounded-xl focus:outline-none focus:border-indigo-500"
                  />
                </div>
                <div>
                  <label className="block font-bold text-slate-700 mb-1">Teacher Phone</label>
                  <input
                    value={teacherFormData.phone}
                    onChange={(e) => setTeacherFormData({ ...teacherFormData, phone: e.target.value })}
                    placeholder="+91 98765 43210"
                    className="w-full p-2.5 border border-slate-200 rounded-xl focus:outline-none focus:border-indigo-500"
                  />
                </div>
              </div>

              <div className="p-3 bg-indigo-50/50 rounded-2xl border border-indigo-100 space-y-3">
                <span className="text-[10px] font-black uppercase text-indigo-700 tracking-wider block">
                  Coaching Centre Branding
                </span>

                <div>
                  <label className="block font-bold text-slate-700 mb-1">Coaching Centre Name *</label>
                  <input
                    required
                    value={teacherFormData.coachingName}
                    onChange={(e) => setTeacherFormData({ ...teacherFormData, coachingName: e.target.value })}
                    placeholder="e.g. Sharma Physics Academy"
                    className="w-full p-2.5 border border-slate-200 rounded-xl bg-white focus:outline-none focus:border-indigo-500"
                  />
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block font-bold text-slate-700 mb-1">Subjects Taught</label>
                    <input
                      value={teacherFormData.subjects}
                      onChange={(e) => setTeacherFormData({ ...teacherFormData, subjects: e.target.value })}
                      placeholder="e.g. Physics, Mechanics"
                      className="w-full p-2.5 border border-slate-200 rounded-xl bg-white focus:outline-none focus:border-indigo-500"
                    />
                  </div>
                  <div>
                    <label className="block font-bold text-slate-700 mb-1">Centre Contact Phone</label>
                    <input
                      value={teacherFormData.contactPhone}
                      onChange={(e) => setTeacherFormData({ ...teacherFormData, contactPhone: e.target.value })}
                      placeholder="+91 98765 11111"
                      className="w-full p-2.5 border border-slate-200 rounded-xl bg-white focus:outline-none focus:border-indigo-500"
                    />
                  </div>
                </div>

                <div>
                  <label className="block font-bold text-slate-700 mb-1">Centre Address / City</label>
                  <input
                    value={teacherFormData.centreAddress}
                    onChange={(e) => setTeacherFormData({ ...teacherFormData, centreAddress: e.target.value })}
                    placeholder="e.g. Kota, Rajasthan"
                    className="w-full p-2.5 border border-slate-200 rounded-xl bg-white focus:outline-none focus:border-indigo-500"
                  />
                </div>
              </div>

              <div className="flex justify-end space-x-2 pt-3">
                <button
                  type="button"
                  onClick={() => setShowAddTeacherModal(false)}
                  className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-xl font-semibold"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-xl shadow-xs"
                >
                  Save Teacher & Branding
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL: EDIT TEACHER */}
      {editingTeacher && (
        <div className="fixed inset-0 bg-slate-900/50 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-3xl shadow-elevated border border-slate-200 p-6 max-w-lg w-full text-xs">
            <div className="flex items-center justify-between pb-3 border-b border-slate-100 mb-4">
              <div>
                <h3 className="text-sm font-extrabold text-slate-900">Edit Teacher Profile & Branding</h3>
                <p className="text-slate-500 text-[11px]">{editingTeacher.name} ({editingTeacher.email})</p>
              </div>
              <button onClick={() => setEditingTeacher(null)} className="text-slate-400 hover:text-slate-600">
                <X className="w-4 h-4" />
              </button>
            </div>

            <form onSubmit={handleUpdateTeacher} className="space-y-3">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-bold text-slate-700 mb-1">Teacher Name</label>
                  <input
                    required
                    value={editingTeacher.name}
                    onChange={(e) => setEditingTeacher({ ...editingTeacher, name: e.target.value })}
                    className="w-full p-2.5 border border-slate-200 rounded-xl"
                  />
                </div>
                <div>
                  <label className="block font-bold text-slate-700 mb-1">Email</label>
                  <input
                    required
                    value={editingTeacher.email}
                    onChange={(e) => setEditingTeacher({ ...editingTeacher, email: e.target.value })}
                    className="w-full p-2.5 border border-slate-200 rounded-xl"
                  />
                </div>
              </div>

              <div>
                <label className="block font-bold text-slate-700 mb-1">Coaching Centre Name</label>
                <input
                  value={editingTeacher.coachingName || ''}
                  onChange={(e) => setEditingTeacher({ ...editingTeacher, coachingName: e.target.value })}
                  placeholder="e.g. Sharma Physics Academy"
                  className="w-full p-2.5 border border-slate-200 rounded-xl"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-bold text-slate-700 mb-1">Subjects</label>
                  <input
                    value={editingTeacher.subjects || ''}
                    onChange={(e) => setEditingTeacher({ ...editingTeacher, subjects: e.target.value })}
                    className="w-full p-2.5 border border-slate-200 rounded-xl"
                  />
                </div>
                <div>
                  <label className="block font-bold text-slate-700 mb-1">Contact Phone</label>
                  <input
                    value={editingTeacher.contactPhone || ''}
                    onChange={(e) => setEditingTeacher({ ...editingTeacher, contactPhone: e.target.value })}
                    className="w-full p-2.5 border border-slate-200 rounded-xl"
                  />
                </div>
              </div>

              <div>
                <label className="block font-bold text-slate-700 mb-1">Centre Address</label>
                <input
                  value={editingTeacher.centreAddress || ''}
                  onChange={(e) => setEditingTeacher({ ...editingTeacher, centreAddress: e.target.value })}
                  className="w-full p-2.5 border border-slate-200 rounded-xl"
                />
              </div>

              <div className="flex justify-end space-x-2 pt-3">
                <button
                  type="button"
                  onClick={() => setEditingTeacher(null)}
                  className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-xl font-semibold"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-xl shadow-xs"
                >
                  Update Profile
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL: ADD BATCH */}
      {showAddBatchModal && (
        <div className="fixed inset-0 bg-slate-900/50 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-3xl shadow-elevated border border-slate-200 p-6 max-w-md w-full text-xs">
            <div className="flex items-center justify-between pb-3 border-b border-slate-100 mb-4">
              <div>
                <h3 className="text-sm font-extrabold text-slate-900">Create New Batch / Course</h3>
                <p className="text-slate-500 text-[11px]">Select which teacher owns this course.</p>
              </div>
              <button onClick={() => setShowAddBatchModal(false)} className="text-slate-400 hover:text-slate-600">
                <X className="w-4 h-4" />
              </button>
            </div>

            <form onSubmit={handleAddBatch} className="space-y-3">
              <div>
                <label className="block font-bold text-slate-700 mb-1">Assign to Teacher *</label>
                <select
                  required
                  value={batchFormData.teacherId}
                  onChange={(e) => setBatchFormData({ ...batchFormData, teacherId: e.target.value })}
                  className="w-full p-2.5 border border-slate-200 rounded-xl bg-slate-50 font-semibold"
                >
                  {teachers.map((t) => (
                    <option key={t.id} value={t.id}>
                      {t.name} {t.coachingName ? `(${t.coachingName})` : ''}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block font-bold text-slate-700 mb-1">Batch / Course Name *</label>
                <input
                  required
                  value={batchFormData.name}
                  onChange={(e) => setBatchFormData({ ...batchFormData, name: e.target.value })}
                  placeholder="e.g. Class 12th IIT-JEE Advanced Masterclass"
                  className="w-full p-2.5 border border-slate-200 rounded-xl"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-bold text-slate-700 mb-1">Subject</label>
                  <input
                    value={batchFormData.subject}
                    onChange={(e) => setBatchFormData({ ...batchFormData, subject: e.target.value })}
                    placeholder="e.g. Physics"
                    className="w-full p-2.5 border border-slate-200 rounded-xl"
                  />
                </div>
                <div>
                  <label className="block font-bold text-slate-700 mb-1">Schedule Details</label>
                  <input
                    value={batchFormData.schedule}
                    onChange={(e) => setBatchFormData({ ...batchFormData, schedule: e.target.value })}
                    placeholder="Mon, Wed, Fri 18:00"
                    className="w-full p-2.5 border border-slate-200 rounded-xl"
                  />
                </div>
              </div>

              <div>
                <label className="block font-bold text-slate-700 mb-1">Description</label>
                <textarea
                  value={batchFormData.description}
                  onChange={(e) => setBatchFormData({ ...batchFormData, description: e.target.value })}
                  placeholder="Batch description and syllabus coverage..."
                  rows={2}
                  className="w-full p-2.5 border border-slate-200 rounded-xl"
                />
              </div>

              <div className="flex justify-end space-x-2 pt-3">
                <button
                  type="button"
                  onClick={() => setShowAddBatchModal(false)}
                  className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-xl font-semibold"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-xl shadow-xs"
                >
                  Create Batch
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL: ADD TIMETABLE SLOT */}
      {showAddSlotModal && (
        <div className="fixed inset-0 bg-slate-900/50 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-3xl shadow-elevated border border-slate-200 p-6 max-w-md w-full text-xs">
            <div className="flex items-center justify-between pb-3 border-b border-slate-100 mb-4">
              <div>
                <h3 className="text-sm font-extrabold text-slate-900">Schedule Timetable Slot</h3>
                <p className="text-slate-500 text-[11px]">System detects schedule conflicts automatically.</p>
              </div>
              <button onClick={() => setShowAddSlotModal(false)} className="text-slate-400 hover:text-slate-600">
                <X className="w-4 h-4" />
              </button>
            </div>

            <form onSubmit={handleAddSlot} className="space-y-3">
              <div>
                <label className="block font-bold text-slate-700 mb-1">Teacher *</label>
                <select
                  required
                  value={slotFormData.teacherId}
                  onChange={(e) => setSlotFormData({ ...slotFormData, teacherId: e.target.value })}
                  className="w-full p-2.5 border border-slate-200 rounded-xl bg-slate-50 font-semibold"
                >
                  {teachers.map((t) => (
                    <option key={t.id} value={t.id}>
                      {t.name} {t.coachingName ? `(${t.coachingName})` : ''}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block font-bold text-slate-700 mb-1">Target Batch *</label>
                <select
                  required
                  value={slotFormData.batchId}
                  onChange={(e) => setSlotFormData({ ...slotFormData, batchId: e.target.value })}
                  className="w-full p-2.5 border border-slate-200 rounded-xl bg-slate-50 font-semibold"
                >
                  {batches
                    .filter((b) => !slotFormData.teacherId || b.teacherId === slotFormData.teacherId)
                    .map((b) => (
                      <option key={b.id} value={b.id}>
                        {b.name}
                      </option>
                    ))}
                </select>
              </div>

              <div className="grid grid-cols-3 gap-2">
                <div>
                  <label className="block font-bold text-slate-700 mb-1">Day</label>
                  <select
                    value={slotFormData.dayOfWeek}
                    onChange={(e) => setSlotFormData({ ...slotFormData, dayOfWeek: e.target.value })}
                    className="w-full p-2.5 border border-slate-200 rounded-xl bg-slate-50 font-semibold"
                  >
                    <option value="MONDAY">Monday</option>
                    <option value="TUESDAY">Tuesday</option>
                    <option value="WEDNESDAY">Wednesday</option>
                    <option value="THURSDAY">Thursday</option>
                    <option value="FRIDAY">Friday</option>
                    <option value="SATURDAY">Saturday</option>
                    <option value="SUNDAY">Sunday</option>
                  </select>
                </div>
                <div>
                  <label className="block font-bold text-slate-700 mb-1">Start Time</label>
                  <input
                    type="time"
                    required
                    value={slotFormData.startTime}
                    onChange={(e) => setSlotFormData({ ...slotFormData, startTime: e.target.value })}
                    className="w-full p-2 border border-slate-200 rounded-xl"
                  />
                </div>
                <div>
                  <label className="block font-bold text-slate-700 mb-1">End Time</label>
                  <input
                    type="time"
                    required
                    value={slotFormData.endTime}
                    onChange={(e) => setSlotFormData({ ...slotFormData, endTime: e.target.value })}
                    className="w-full p-2 border border-slate-200 rounded-xl"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-bold text-slate-700 mb-1">Subject *</label>
                  <input
                    required
                    value={slotFormData.subject}
                    onChange={(e) => setSlotFormData({ ...slotFormData, subject: e.target.value })}
                    placeholder="e.g. Kinematics & Laws of Motion"
                    className="w-full p-2.5 border border-slate-200 rounded-xl"
                  />
                </div>
                <div>
                  <label className="block font-bold text-slate-700 mb-1">Studio / Room</label>
                  <input
                    value={slotFormData.room}
                    onChange={(e) => setSlotFormData({ ...slotFormData, room: e.target.value })}
                    placeholder="Interactive Studio A"
                    className="w-full p-2.5 border border-slate-200 rounded-xl"
                  />
                </div>
              </div>

              <div className="flex justify-end space-x-2 pt-3">
                <button
                  type="button"
                  onClick={() => setShowAddSlotModal(false)}
                  className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-xl font-semibold"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-xl shadow-xs"
                >
                  Add Timetable Slot
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL: ADD STUDENT */}
      {showAddStudentModal && (
        <div className="fixed inset-0 bg-slate-900/50 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-3xl shadow-elevated border border-slate-200 p-6 max-w-md w-full text-xs">
            <div className="flex items-center justify-between pb-3 border-b border-slate-100 mb-4">
              <div>
                <h3 className="text-sm font-extrabold text-slate-900">Enroll Student & Lock to Teacher</h3>
                <p className="text-slate-500 text-[11px]">Enforces strict data isolation to the assigned faculty member.</p>
              </div>
              <button onClick={() => setShowAddStudentModal(false)} className="text-slate-400 hover:text-slate-600">
                <X className="w-4 h-4" />
              </button>
            </div>

            <form onSubmit={handleAddStudent} className="space-y-3">
              <div>
                <label className="block font-bold text-slate-700 mb-1">Assign to Teacher (Data Silo) *</label>
                <select
                  required
                  value={studentFormData.teacherId}
                  onChange={(e) => setStudentFormData({ ...studentFormData, teacherId: e.target.value })}
                  className="w-full p-2.5 border border-slate-200 rounded-xl bg-slate-50 font-semibold"
                >
                  {teachers.map((t) => (
                    <option key={t.id} value={t.id}>
                      {t.name} {t.coachingName ? `(${t.coachingName})` : ''}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block font-bold text-slate-700 mb-1">Assign to Batch</label>
                <select
                  value={studentFormData.batchId}
                  onChange={(e) => setStudentFormData({ ...studentFormData, batchId: e.target.value })}
                  className="w-full p-2.5 border border-slate-200 rounded-xl bg-slate-50 font-semibold"
                >
                  <option value="">No Initial Batch (Register only)</option>
                  {batches
                    .filter((b) => !studentFormData.teacherId || b.teacherId === studentFormData.teacherId)
                    .map((b) => (
                      <option key={b.id} value={b.id}>
                        {b.name}
                      </option>
                    ))}
                </select>
              </div>

              <div>
                <label className="block font-bold text-slate-700 mb-1">Student Full Name *</label>
                <input
                  required
                  value={studentFormData.name}
                  onChange={(e) => setStudentFormData({ ...studentFormData, name: e.target.value })}
                  placeholder="e.g. Aarav Patel"
                  className="w-full p-2.5 border border-slate-200 rounded-xl"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-bold text-slate-700 mb-1">Email Address *</label>
                  <input
                    required
                    type="email"
                    value={studentFormData.email}
                    onChange={(e) => setStudentFormData({ ...studentFormData, email: e.target.value })}
                    placeholder="student@apex.edu"
                    className="w-full p-2.5 border border-slate-200 rounded-xl"
                  />
                </div>
                <div>
                  <label className="block font-bold text-slate-700 mb-1">Phone Number</label>
                  <input
                    value={studentFormData.phone}
                    onChange={(e) => setStudentFormData({ ...studentFormData, phone: e.target.value })}
                    placeholder="+91 98765 00000"
                    className="w-full p-2.5 border border-slate-200 rounded-xl"
                  />
                </div>
              </div>

              <div className="flex justify-end space-x-2 pt-3">
                <button
                  type="button"
                  onClick={() => setShowAddStudentModal(false)}
                  className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-xl font-semibold"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-xl shadow-xs"
                >
                  Enroll Student
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
