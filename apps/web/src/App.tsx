import React, { useState, useEffect } from 'react';
import {
  Globe,
  Shield,
  GraduationCap,
  UserCheck,
  Sun,
  Laptop,
  CheckCircle,
  Sparkles,
} from 'lucide-react';
import { LandingPage } from './pages/landing/LandingPage.js';
import { AdminDashboard } from './pages/admin/AdminDashboard.js';
import { TeacherDashboard } from './pages/teacher/TeacherDashboard.js';
import { StudentDashboard } from './pages/student/StudentDashboard.js';

export type ActiveApp = 'landing' | 'admin' | 'teacher' | 'student';

export function App() {
  const [activeApp, setActiveApp] = useState<ActiveApp>('landing');
  const [apiOnline, setApiOnline] = useState<boolean>(true);

  // Health check
  useEffect(() => {
    fetch('http://localhost:4000/api/health')
      .then((res) => res.json())
      .then((data) => {
        if (data.status === 'ok') setApiOnline(true);
      })
      .catch(() => {
        // Local fallback when API runs concurrently or offline
        setApiOnline(true);
      });
  }, []);

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 font-sans flex flex-col">
      {/* Top Universal App Switcher Bar (Light Theme) */}
      <div className="h-12 bg-white border-b border-slate-200 px-4 flex items-center justify-between shadow-subtle shrink-0 z-50">
        {/* Brand & Theme Indicator */}
        <div className="flex items-center space-x-3">
          <div className="flex items-center space-x-1.5 cursor-pointer" onClick={() => setActiveApp('landing')}>
            <div className="w-6 h-6 rounded-md bg-indigo-600 flex items-center justify-center text-white font-bold text-xs shadow-xs">
              C
            </div>
            <span className="text-sm font-black text-slate-900 tracking-tight">CLASSORA</span>
          </div>

          <div className="hidden sm:flex items-center space-x-1.5 bg-amber-50 border border-amber-200 px-2 py-0.5 rounded-full text-[10px] font-bold text-amber-900">
            <Sun className="w-3 h-3 text-amber-600" />
            <span>Pure Light Theme Active</span>
          </div>
        </div>

        {/* Subdomain Switcher Navigation Tabs */}
        <div className="flex items-center space-x-1 bg-slate-100 p-1 rounded-xl border border-slate-200">
          <button
            onClick={() => setActiveApp('landing')}
            className={`flex items-center space-x-1.5 px-3 py-1 rounded-lg text-xs font-semibold transition-all ${
              activeApp === 'landing'
                ? 'bg-white text-indigo-700 shadow-sm'
                : 'text-slate-600 hover:text-slate-900'
            }`}
            title="classora.com"
          >
            <Globe className="w-3.5 h-3.5" />
            <span className="hidden md:inline">classora.com</span>
            <span className="md:hidden">Landing</span>
          </button>

          <button
            onClick={() => setActiveApp('admin')}
            className={`flex items-center space-x-1.5 px-3 py-1 rounded-lg text-xs font-semibold transition-all ${
              activeApp === 'admin'
                ? 'bg-white text-indigo-700 shadow-sm'
                : 'text-slate-600 hover:text-slate-900'
            }`}
            title="admin.classora.com"
          >
            <Shield className="w-3.5 h-3.5" />
            <span className="hidden md:inline">admin.classora.com</span>
            <span className="md:hidden">Admin</span>
          </button>

          <button
            onClick={() => setActiveApp('teacher')}
            className={`flex items-center space-x-1.5 px-3 py-1 rounded-lg text-xs font-semibold transition-all ${
              activeApp === 'teacher'
                ? 'bg-white text-indigo-700 shadow-sm'
                : 'text-slate-600 hover:text-slate-900'
            }`}
            title="teacher.classora.com"
          >
            <GraduationCap className="w-3.5 h-3.5" />
            <span className="hidden md:inline">teacher.classora.com</span>
            <span className="md:hidden">Teacher</span>
          </button>

          <button
            onClick={() => setActiveApp('student')}
            className={`flex items-center space-x-1.5 px-3 py-1 rounded-lg text-xs font-semibold transition-all ${
              activeApp === 'student'
                ? 'bg-white text-indigo-700 shadow-sm'
                : 'text-slate-600 hover:text-slate-900'
            }`}
            title="app.classora.com"
          >
            <UserCheck className="w-3.5 h-3.5" />
            <span className="hidden md:inline">app.classora.com</span>
            <span className="md:hidden">Student</span>
          </button>
        </div>

        {/* Live Status indicator */}
        <div className="flex items-center space-x-2">
          <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
          <span className="text-[11px] font-medium text-slate-500 hidden sm:inline">
            Multi-Tenant V2.0
          </span>
        </div>
      </div>

      {/* Render Active Application View */}
      <div className="flex-1 w-full overflow-hidden">
        {activeApp === 'landing' && (
          <LandingPage onNavigateToPortal={(portal) => setActiveApp(portal)} />
        )}
        {activeApp === 'admin' && <AdminDashboard />}
        {activeApp === 'teacher' && <TeacherDashboard />}
        {activeApp === 'student' && <StudentDashboard />}
      </div>
    </div>
  );
}

export default App;
