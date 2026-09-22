import React, { useState } from 'react';
import {
  ShieldCheck,
  GraduationCap,
  UserCheck,
  Lock,
  Mail,
  Building,
  ArrowRight,
  Eye,
  EyeOff,
  Sparkles,
  CheckCircle2,
} from 'lucide-react';

export interface LoggedInUser {
  id: string;
  name: string;
  email: string;
  role: 'admin' | 'teacher' | 'student';
  instituteName: string;
  avatarUrl?: string;
}

interface LoginCardProps {
  role: 'admin' | 'teacher' | 'student';
  portalName: string;
  portNumber: number;
  defaultEmail: string;
  defaultName: string;
  onLoginSuccess: (user: LoggedInUser) => void;
}

export const LoginCard: React.FC<LoginCardProps> = ({
  role,
  portalName,
  portNumber,
  defaultEmail,
  defaultName,
  onLoginSuccess,
}) => {
  const [instituteCode, setInstituteCode] = useState('apex-academy');
  const [email, setEmail] = useState(defaultEmail);
  const [password, setPassword] = useState('pass1234');
  const [showPassword, setShowPassword] = useState(false);
  const [rememberMe, setRememberMe] = useState(true);
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setTimeout(() => {
      setIsLoading(false);
      onLoginSuccess({
        id: `usr-${role}-01`,
        name: defaultName,
        email: email,
        role: role,
        instituteName: 'Apex IIT-JEE & Medical Academy',
      });
    }, 400);
  };

  const handleQuickDemoLogin = () => {
    setEmail(defaultEmail);
    setPassword('pass1234');
    onLoginSuccess({
      id: `usr-${role}-01`,
      name: defaultName,
      email: defaultEmail,
      role: role,
      instituteName: 'Apex IIT-JEE & Medical Academy',
    });
  };

  return (
    <div className="min-h-screen bg-slate-50 flex flex-col justify-center items-center p-4 font-sans selection:bg-indigo-100">
      {/* Top Brand Logo */}
      <div className="mb-6 flex flex-col items-center text-center">
        <div className="w-12 h-12 rounded-2xl bg-indigo-600 flex items-center justify-center text-white font-black text-2xl shadow-md mb-2">
          C
        </div>
        <h1 className="text-xl font-extrabold text-slate-900 tracking-tight">Classora Cloud</h1>
        <p className="text-xs text-slate-500 font-medium">Virtual Classroom + Institute Management SaaS</p>
      </div>

      {/* Main Login Card (Pure Light Theme) */}
      <div className="bg-white rounded-3xl shadow-elevated border border-slate-200 p-8 max-w-md w-full animate-in fade-in zoom-in-95 duration-200">
        {/* Role Badge */}
        <div className="flex items-center justify-between pb-4 border-b border-slate-100 mb-6">
          <div>
            <span className="text-[10px] font-extrabold tracking-wider uppercase text-indigo-600 bg-indigo-50 px-2.5 py-0.5 rounded-full border border-indigo-200">
              Port {portNumber} &bull; {role.toUpperCase()} PORTAL
            </span>
            <h2 className="text-base font-bold text-slate-900 mt-1">{portalName}</h2>
          </div>
          <div className="w-10 h-10 rounded-2xl bg-indigo-50 text-indigo-600 flex items-center justify-center">
            {role === 'admin' && <ShieldCheck className="w-5 h-5" />}
            {role === 'teacher' && <GraduationCap className="w-5 h-5" />}
            {role === 'student' && <UserCheck className="w-5 h-5" />}
          </div>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="space-y-4 text-xs">
          {/* Institute Code (For student and admin) */}
          {role !== 'teacher' && (
            <div>
              <label className="block font-bold text-slate-700 mb-1">Institute Slug / Code</label>
              <div className="relative">
                <Building className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                <input
                  type="text"
                  required
                  value={instituteCode}
                  onChange={(e) => setInstituteCode(e.target.value)}
                  placeholder="e.g. apex-academy"
                  className="w-full pl-9 pr-3 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-indigo-500 font-medium text-slate-800"
                />
              </div>
            </div>
          )}

          {/* Email / Username */}
          <div>
            <label className="block font-bold text-slate-700 mb-1">Registered Email or Phone</label>
            <div className="relative">
              <Mail className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="name@apex.edu"
                className="w-full pl-9 pr-3 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-indigo-500 font-medium text-slate-800"
              />
            </div>
          </div>

          {/* Password */}
          <div>
            <label className="block font-bold text-slate-700 mb-1">Password</label>
            <div className="relative">
              <Lock className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                type={showPassword ? 'text' : 'password'}
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full pl-9 pr-10 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-indigo-500 font-medium text-slate-800"
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
              >
                {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
              </button>
            </div>
          </div>

          {/* Remember me & Forgot Password */}
          <div className="flex items-center justify-between pt-1">
            <label className="flex items-center space-x-2 cursor-pointer">
              <input
                type="checkbox"
                checked={rememberMe}
                onChange={(e) => setRememberMe(e.target.checked)}
                className="w-3.5 h-3.5 rounded text-indigo-600 focus:ring-indigo-500"
              />
              <span className="text-slate-600 font-medium">Keep me signed in</span>
            </label>
            <a href="#forgot" className="text-indigo-600 font-bold hover:underline">
              Forgot password?
            </a>
          </div>

          {/* Submit button */}
          <button
            type="submit"
            disabled={isLoading}
            className="w-full py-3 bg-indigo-600 hover:bg-indigo-700 text-white font-bold rounded-xl shadow-sm transition-colors flex items-center justify-center space-x-2 mt-2"
          >
            <span>{isLoading ? 'Signing In...' : 'Sign In to Dashboard'}</span>
            <ArrowRight className="w-4 h-4" />
          </button>
        </form>

        {/* 1-Click Quick Demo Login Button */}
        <div className="mt-5 pt-4 border-t border-slate-100">
          <button
            type="button"
            onClick={handleQuickDemoLogin}
            className="w-full py-2.5 px-3 bg-indigo-50 hover:bg-indigo-100 text-indigo-700 font-bold rounded-xl border border-indigo-200 transition-colors flex items-center justify-center space-x-2 text-xs"
          >
            <Sparkles className="w-3.5 h-3.5" />
            <span>1-Click Quick Demo Login as {defaultName}</span>
          </button>
        </div>
      </div>

      {/* Footer info */}
      <p className="mt-6 text-xs text-slate-400 text-center">
        Powered by Classora Multi-Tenant Engine &bull; Strictly Isolated Institute Data
      </p>
    </div>
  );
};
