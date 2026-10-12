import React, { useState } from 'react';
import {
  ShieldCheck,
  Lock,
  Mail,
  GraduationCap,
  UserCheck,
  ArrowRight,
  Sparkles,
  CheckCircle2,
  KeyRound,
} from 'lucide-react';

export interface UserSession {
  id: string;
  name: string;
  email: string;
  role: 'student' | 'teacher' | 'admin';
  avatar?: string;
  batchOrDept?: string;
}

interface LoginPageProps {
  onLoginSuccess: (user: UserSession) => void;
}

export const LoginPage: React.FC<LoginPageProps> = ({ onLoginSuccess }) => {
  const [selectedRole, setSelectedRole] = useState<'student' | 'teacher'>('student');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [errorMessage, setErrorMessage] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  // Demo accounts
  const demoStudent: UserSession = {
    id: 'usr-student-01',
    name: 'Aarav Patel',
    email: 'aarav.patel@student.classora.com',
    role: 'student',
    avatar: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=100&h=100&fit=crop',
    batchOrDept: 'Class 12th JEE Masterclass',
  };

  const demoTeacher: UserSession = {
    id: 'usr-teacher-01',
    name: 'Prof. Rajesh Sharma',
    email: 'rajesh.sharma@teacher.classora.com',
    role: 'teacher',
    avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop',
    batchOrDept: 'Department of Physics',
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage('');
    setIsLoading(true);

    setTimeout(() => {
      setIsLoading(false);
      if (selectedRole === 'student') {
        onLoginSuccess({
          ...demoStudent,
          email: email || demoStudent.email,
        });
      } else {
        onLoginSuccess({
          ...demoTeacher,
          email: email || demoTeacher.email,
        });
      }
    }, 400);
  };

  const handleQuickDemoLogin = (role: 'student' | 'teacher') => {
    if (role === 'student') {
      onLoginSuccess(demoStudent);
    } else {
      onLoginSuccess(demoTeacher);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-indigo-950 to-slate-900 text-slate-100 flex items-center justify-center p-3 sm:p-6 font-sans relative overflow-x-hidden pt-safe pb-safe">
      {/* Background Decorative Glow */}
      <div className="absolute top-1/4 left-1/2 -translate-x-1/2 -translate-y-1/2 w-96 h-96 bg-indigo-600/20 blur-3xl rounded-full pointer-events-none" />
      <div className="absolute bottom-10 right-10 w-72 h-72 bg-purple-600/15 blur-3xl rounded-full pointer-events-none" />

      <div className="w-full max-w-md bg-white text-slate-900 rounded-2xl sm:rounded-3xl shadow-2xl border border-slate-100/20 p-5 sm:p-8 relative z-10 backdrop-blur-md my-auto">
        {/* Header Logo */}
        <div className="text-center mb-8">
          <div className="w-14 h-14 rounded-2xl bg-indigo-600 text-white flex items-center justify-center mx-auto mb-3 shadow-lg shadow-indigo-500/30">
            <span className="font-extrabold text-2xl tracking-tighter">C</span>
          </div>
          <h1 className="text-2xl font-black text-slate-900 tracking-tight">CLASSORA</h1>
          <p className="text-xs text-slate-500 font-medium mt-1">
            Unified Live Learning & Digital Classroom Portal
          </p>
        </div>

        {/* Role Selector Switch */}
        <div className="flex bg-slate-100 p-1.5 rounded-2xl border border-slate-200 mb-6">
          <button
            type="button"
            onClick={() => {
              setSelectedRole('student');
              setEmail('aarav.patel@student.classora.com');
            }}
            className={`flex-1 flex items-center justify-center space-x-2 py-2.5 rounded-xl text-xs font-bold transition-all ${
              selectedRole === 'student'
                ? 'bg-white text-indigo-700 shadow-md'
                : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            <UserCheck className="w-4 h-4" />
            <span>Student Portal</span>
          </button>

          <button
            type="button"
            onClick={() => {
              setSelectedRole('teacher');
              setEmail('rajesh.sharma@teacher.classora.com');
            }}
            className={`flex-1 flex items-center justify-center space-x-2 py-2.5 rounded-xl text-xs font-bold transition-all ${
              selectedRole === 'teacher'
                ? 'bg-white text-indigo-700 shadow-md'
                : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            <GraduationCap className="w-4 h-4" />
            <span>Teacher Console</span>
          </button>
        </div>

        {/* Secure Form */}
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-bold text-slate-700 mb-1.5">
              {selectedRole === 'student' ? 'Student ID / Registered Email' : 'Teacher ID / Work Email'}
            </label>
            <div className="relative">
              <Mail className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder={selectedRole === 'student' ? 'aarav.patel@student.classora.com' : 'rajesh.sharma@teacher.classora.com'}
                className="w-full text-xs pl-10 pr-4 py-3 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:bg-white text-slate-900 font-medium transition-all"
              />
            </div>
          </div>

          <div>
            <div className="flex justify-between items-center mb-1.5">
              <label className="block text-xs font-bold text-slate-700">Account Password</label>
              <button
                type="button"
                onClick={() => {
                  setEmail('');
                  setPassword('');
                }}
                className="text-[11px] font-bold text-rose-600 hover:text-rose-800 transition-colors"
              >
                Clear Fields
              </button>
            </div>
            <div className="relative">
              <Lock className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Enter your password..."
                className="w-full text-xs pl-10 pr-4 py-3 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:bg-white text-slate-900 font-medium transition-all"
              />
            </div>
          </div>

          {errorMessage && (
            <p className="text-xs text-rose-600 font-semibold bg-rose-50 p-2.5 rounded-lg text-center">
              {errorMessage}
            </p>
          )}

          <button
            type="submit"
            disabled={isLoading}
            className="w-full py-3 px-4 text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-700 active:bg-indigo-800 rounded-xl shadow-lg shadow-indigo-600/20 flex items-center justify-center space-x-2 transition-all"
          >
            {isLoading ? (
              <span className="animate-pulse">Authenticating Securely...</span>
            ) : (
              <>
                <span>Secure Sign In</span>
                <ArrowRight className="w-4 h-4" />
              </>
            )}
          </button>
        </form>

        {/* Quick Demo Login Preset Buttons */}
        <div className="mt-6 pt-5 border-t border-slate-100">
          <p className="text-[11px] font-bold text-slate-400 uppercase tracking-wider text-center mb-3">
            Instant One-Click Demo Login
          </p>
          <div className="grid grid-cols-2 gap-2">
            <button
              onClick={() => handleQuickDemoLogin('student')}
              className="py-2.5 px-3 rounded-xl border border-indigo-200 bg-indigo-50/70 hover:bg-indigo-100 text-indigo-900 text-xs font-bold flex items-center justify-center space-x-1.5 transition-colors"
            >
              <UserCheck className="w-3.5 h-3.5 text-indigo-600" />
              <span>Demo Student</span>
            </button>
            <button
              onClick={() => handleQuickDemoLogin('teacher')}
              className="py-2.5 px-3 rounded-xl border border-purple-200 bg-purple-50/70 hover:bg-purple-100 text-purple-900 text-xs font-bold flex items-center justify-center space-x-1.5 transition-colors"
            >
              <GraduationCap className="w-3.5 h-3.5 text-purple-600" />
              <span>Demo Teacher</span>
            </button>
          </div>
        </div>

        {/* Security Footer */}
        <div className="mt-6 flex items-center justify-center space-x-1.5 text-[11px] text-slate-400 font-medium">
          <ShieldCheck className="w-4 h-4 text-emerald-500" />
          <span>256-Bit SSL Encrypted Session</span>
        </div>
      </div>
    </div>
  );
};
