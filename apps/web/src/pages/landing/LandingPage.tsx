import React, { useState } from 'react';
import {
  Sparkles,
  Video,
  PenTool,
  BookOpen,
  Award,
  CreditCard,
  CheckCircle,
  ArrowRight,
  ShieldCheck,
  Zap,
  Users,
  BarChart3,
  Calendar,
  Layers,
  ChevronRight,
} from 'lucide-react';

interface LandingPageProps {
  onNavigateToPortal: (portal: 'admin' | 'teacher' | 'student') => void;
}

export const LandingPage: React.FC<LandingPageProps> = ({ onNavigateToPortal }) => {
  const [demoModalOpen, setDemoModalOpen] = useState(false);
  const [demoSubmitted, setDemoSubmitted] = useState(false);

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 font-sans">
      {/* Top Marketing Bar */}
      <div className="bg-indigo-600 text-white text-xs py-2 px-4 text-center font-medium flex items-center justify-center space-x-2">
        <Sparkles className="w-3.5 h-3.5" />
        <span>Classora 2.0 Live! The Next-Gen Virtual Classroom & Institute Management SaaS.</span>
        <button
          onClick={() => setDemoModalOpen(true)}
          className="underline font-bold hover:text-indigo-100 ml-1"
        >
          Book a live walkthrough &rarr;
        </button>
      </div>

      {/* Navigation Header */}
      <header className="sticky top-0 bg-white/95 backdrop-blur-md border-b border-slate-200 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 rounded-xl bg-indigo-600 flex items-center justify-center text-white font-bold text-xl shadow-md">
              C
            </div>
            <div>
              <span className="text-xl font-extrabold tracking-tight text-slate-900">Classora</span>
              <span className="text-[11px] font-semibold text-indigo-600 uppercase tracking-wider block -mt-1">
                Virtual Classroom SaaS
              </span>
            </div>
          </div>

          {/* Nav Links */}
          <nav className="hidden md:flex items-center space-x-8 text-sm font-semibold text-slate-600">
            <a href="#features" className="hover:text-indigo-600 transition-colors">Features</a>
            <a href="#digital-board" className="hover:text-indigo-600 transition-colors">Digital Board</a>
            <a href="#pricing" className="hover:text-indigo-600 transition-colors">Pricing</a>
            <a href="#architecture" className="hover:text-indigo-600 transition-colors">Tech Stack</a>
          </nav>

          {/* Quick Subdomain Links */}
          <div className="flex items-center space-x-2">
            <button
              onClick={() => onNavigateToPortal('student')}
              className="text-xs font-semibold text-slate-700 hover:text-indigo-600 px-2.5 py-1.5 rounded-lg transition-colors"
            >
              Student Web
            </button>
            <button
              onClick={() => onNavigateToPortal('teacher')}
              className="text-xs font-semibold text-indigo-700 bg-indigo-50 hover:bg-indigo-100 border border-indigo-200 px-3 py-1.5 rounded-lg transition-colors"
            >
              Teacher Console
            </button>
            <button
              onClick={() => onNavigateToPortal('admin')}
              className="text-xs font-semibold text-white bg-indigo-600 hover:bg-indigo-700 px-3 py-1.5 rounded-lg shadow-sm transition-colors"
            >
              Admin Panel
            </button>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <section className="relative pt-16 pb-20 overflow-hidden bg-white border-b border-slate-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-3xl mx-auto">
            <div className="inline-flex items-center space-x-2 px-3 py-1 rounded-full bg-indigo-50 border border-indigo-200 text-indigo-700 text-xs font-semibold mb-6">
              <span className="w-2 h-2 rounded-full bg-indigo-600"></span>
              <span>All-In-One Coaching & School Operating System</span>
            </div>
            <h1 className="text-4xl sm:text-5xl lg:text-6xl font-extrabold text-slate-900 tracking-tight leading-[1.15] mb-6">
              Teach. Stream. Write. <span className="text-indigo-600">Learn.</span>
            </h1>
            <p className="text-lg text-slate-600 leading-relaxed mb-8">
              Empower your institute with ultra-low latency live classes, a real-time collaborative digital whiteboard, automated recordings, attendance, LMS tests, and automated fee collections.
            </p>
            <div className="flex flex-col sm:flex-row items-center justify-center gap-3">
              <button
                onClick={() => onNavigateToPortal('teacher')}
                className="w-full sm:w-auto px-6 py-3.5 rounded-xl font-semibold text-sm text-white bg-indigo-600 hover:bg-indigo-700 shadow-md flex items-center justify-center space-x-2 transition-all"
              >
                <span>Launch Teacher Live Console</span>
                <ArrowRight className="w-4 h-4" />
              </button>
              <button
                onClick={() => onNavigateToPortal('admin')}
                className="w-full sm:w-auto px-6 py-3.5 rounded-xl font-semibold text-sm text-slate-700 bg-slate-100 hover:bg-slate-200 border border-slate-200 flex items-center justify-center space-x-2 transition-all"
              >
                <span>Explore Institute Admin</span>
              </button>
            </div>
          </div>

          {/* Interactive Hero Preview Card (Light Theme) */}
          <div className="mt-14 max-w-5xl mx-auto bg-slate-50 rounded-2xl p-3 border border-slate-200 shadow-elevated">
            <div className="bg-white rounded-xl border border-slate-200 overflow-hidden">
              {/* Fake Window Header */}
              <div className="h-10 bg-slate-100/80 border-b border-slate-200 px-4 flex items-center justify-between">
                <div className="flex items-center space-x-1.5">
                  <div className="w-3 h-3 rounded-full bg-rose-400" />
                  <div className="w-3 h-3 rounded-full bg-amber-400" />
                  <div className="w-3 h-3 rounded-full bg-emerald-400" />
                </div>
                <span className="text-xs font-medium text-slate-500">
                  Classora Virtual Classroom — Live JEE Physics Session
                </span>
                <div className="flex items-center space-x-2">
                  <span className="inline-flex items-center px-2 py-0.5 rounded text-[10px] font-bold bg-rose-100 text-rose-700">
                    <span className="w-1.5 h-1.5 rounded-full bg-rose-600 animate-pulse mr-1"></span>
                    LIVE STREAM
                  </span>
                </div>
              </div>

              {/* Classroom Demo Preview Image / Diagram */}
              <div className="relative p-6 bg-slate-50 grid grid-cols-1 lg:grid-cols-3 gap-4">
                {/* Board preview */}
                <div className="lg:col-span-2 bg-white rounded-xl p-5 border border-slate-200 shadow-subtle min-h-[300px] flex flex-col justify-between">
                  <div className="flex items-center justify-between border-b border-slate-100 pb-3">
                    <div className="flex items-center space-x-2">
                      <PenTool className="w-4 h-4 text-indigo-600" />
                      <span className="text-xs font-bold text-slate-800">Synced Digital Canvas</span>
                    </div>
                    <div className="flex items-center space-x-1 text-[11px] text-slate-400">
                      <span>Tool: Pen (Smooth Bezier)</span>
                      <span>•</span>
                      <span>Page 1/4</span>
                    </div>
                  </div>
                  <div className="my-6 space-y-3">
                    <div className="p-3 bg-indigo-50/50 rounded-lg border border-indigo-100 text-xs font-mono text-indigo-900">
                      &tau; = I &times; &alpha; &nbsp;|&nbsp; L = I &times; &omega; &nbsp;|&nbsp; K_total = &frac12;mv&sup2; + &frac12;I&omega;&sup2;
                    </div>
                    <p className="text-xs text-slate-600">
                      Problem 12: A cylinder of mass M and radius R rolls without slipping down a 30&deg; incline. Calculate instantaneous acceleration at contact point.
                    </p>
                  </div>
                  <div className="flex items-center justify-between pt-3 border-t border-slate-100 text-[11px] text-slate-500">
                    <span>Teacher Laser: (X: 420, Y: 185)</span>
                    <span className="text-emerald-600 font-semibold">&bull; 0ms CRDT Sync Latency</span>
                  </div>
                </div>

                {/* Video PiP & Live Interactions preview */}
                <div className="space-y-4">
                  <div className="bg-white rounded-xl p-3 border border-slate-200 shadow-subtle">
                    <div className="relative aspect-video rounded-lg bg-slate-100 overflow-hidden mb-2">
                      <img
                        src="https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=250&fit=crop"
                        alt="Teacher"
                        className="w-full h-full object-cover"
                      />
                      <span className="absolute bottom-2 left-2 bg-slate-900/80 text-white text-[10px] px-2 py-0.5 rounded font-medium">
                        Prof. Rajesh Sharma
                      </span>
                    </div>
                    <div className="flex justify-around text-xs text-slate-600 pt-1">
                      <span className="flex items-center font-medium text-emerald-600">
                        <Video className="w-3.5 h-3.5 mr-1" /> HD 1080p
                      </span>
                      <span className="flex items-center font-medium text-indigo-600">
                        <Zap className="w-3.5 h-3.5 mr-1" /> LiveKit Cloud
                      </span>
                    </div>
                  </div>

                  <div className="bg-white rounded-xl p-3 border border-slate-200 shadow-subtle text-xs">
                    <div className="font-semibold text-slate-800 mb-2 flex items-center justify-between">
                      <span>Live Doubt Queue</span>
                      <span className="bg-amber-100 text-amber-800 px-1.5 py-0.5 rounded text-[10px]">1 Pending</span>
                    </div>
                    <div className="bg-slate-50 p-2 rounded border border-slate-100">
                      <p className="font-medium text-slate-700">Rohan Verma:</p>
                      <p className="text-slate-500 text-[11px]">Why does static friction do zero work?</p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Feature Highlights Section */}
      <section id="features" className="py-20 bg-slate-50 border-b border-slate-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-2xl mx-auto mb-16">
            <h2 className="text-3xl font-extrabold text-slate-900 mb-3">
              Everything Your Institute Needs in One Unified OS
            </h2>
            <p className="text-slate-600">
              Replace 6 fragmented tools (Zoom, Google Meet, Teachmint, Classplus, Razorpay, Pen drives) with Classora.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            {/* Feature 1 */}
            <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-card hover:shadow-elevated transition-all">
              <div className="w-12 h-12 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center mb-5">
                <Video className="w-6 h-6" />
              </div>
              <h3 className="text-lg font-bold text-slate-900 mb-2">Live Classes + Egress Recording</h3>
              <p className="text-sm text-slate-600 leading-relaxed">
                One-click classroom setup powered by WebRTC. Teacher video PiP with automatic server-side recording direct to cloud storage.
              </p>
            </div>

            {/* Feature 2 */}
            <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-card hover:shadow-elevated transition-all">
              <div className="w-12 h-12 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center mb-5">
                <PenTool className="w-6 h-6" />
              </div>
              <h3 className="text-lg font-bold text-slate-900 mb-2">CRDT Synced Digital Board</h3>
              <p className="text-sm text-slate-600 leading-relaxed">
                High-performance HTML5 canvas with smooth pen, shapes, sticky notes, multi-page notebooks, and Yjs real-time stroke sync.
              </p>
            </div>

            {/* Feature 3 */}
            <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-card hover:shadow-elevated transition-all">
              <div className="w-12 h-12 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center mb-5">
                <Award className="w-6 h-6" />
              </div>
              <h3 className="text-lg font-bold text-slate-900 mb-2">Online Tests & Question Bank</h3>
              <p className="text-sm text-slate-600 leading-relaxed">
                MCQ and numerical tests with timer countdown, negative marking, instant rank generation, and detailed accuracy breakdown.
              </p>
            </div>

            {/* Feature 4 */}
            <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-card hover:shadow-elevated transition-all">
              <div className="w-12 h-12 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center mb-5">
                <BookOpen className="w-6 h-6" />
              </div>
              <h3 className="text-lg font-bold text-slate-900 mb-2">LMS & Assignment Grading</h3>
              <p className="text-sm text-slate-600 leading-relaxed">
                Organize curricula into Course &rarr; Subject &rarr; Chapter. Distribute homework, collect student PDF submissions, and annotate feedback.
              </p>
            </div>

            {/* Feature 5 */}
            <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-card hover:shadow-elevated transition-all">
              <div className="w-12 h-12 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center mb-5">
                <CreditCard className="w-6 h-6" />
              </div>
              <h3 className="text-lg font-bold text-slate-900 mb-2">Automated Fee Collection</h3>
              <p className="text-sm text-slate-600 leading-relaxed">
                Razorpay & UPI checkout, automated installment schedules, overdue reminders on WhatsApp, and downloadable GST fee invoices.
              </p>
            </div>

            {/* Feature 6 */}
            <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-card hover:shadow-elevated transition-all">
              <div className="w-12 h-12 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center mb-5">
                <BarChart3 className="w-6 h-6" />
              </div>
              <h3 className="text-lg font-bold text-slate-900 mb-2">Institute Analytics & Multi-Tenancy</h3>
              <p className="text-sm text-slate-600 leading-relaxed">
                Strict multi-tenant security with isolated databases, student attendance heatmap, teacher performance tracking, and custom branding.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Pricing Section (From Blueprint) */}
      <section id="pricing" className="py-20 bg-white border-b border-slate-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-2xl mx-auto mb-16">
            <span className="text-xs font-bold text-indigo-600 uppercase tracking-wider">Pricing Plans</span>
            <h2 className="text-3xl font-extrabold text-slate-900 mt-2 mb-3">
              Simple, Transparent Plans Built for Scale
            </h2>
            <p className="text-slate-600">
              Start small, scale to thousands of enrolled students without surprise infrastructure bills.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
            {/* Starter */}
            <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-card flex flex-col justify-between">
              <div>
                <h3 className="text-base font-bold text-slate-800">Starter</h3>
                <p className="text-xs text-slate-500 mb-4">For individual teachers</p>
                <div className="text-2xl font-extrabold text-slate-900 mb-4">
                  ₹2,999<span className="text-xs text-slate-500 font-normal">/month</span>
                </div>
                <ul className="space-y-2.5 text-xs text-slate-600 mb-6">
                  <li className="flex items-center"><CheckCircle className="w-4 h-4 text-emerald-500 mr-2" /> Up to 100 students</li>
                  <li className="flex items-center"><CheckCircle className="w-4 h-4 text-emerald-500 mr-2" /> Live interactive classes</li>
                  <li className="flex items-center"><CheckCircle className="w-4 h-4 text-emerald-500 mr-2" /> Digital whiteboard sync</li>
                  <li className="flex items-center"><CheckCircle className="w-4 h-4 text-emerald-500 mr-2" /> Auto class recordings</li>
                  <li className="flex items-center"><CheckCircle className="w-4 h-4 text-emerald-500 mr-2" /> Basic online tests</li>
                </ul>
              </div>
              <button
                onClick={() => setDemoModalOpen(true)}
                className="w-full py-2.5 rounded-xl text-xs font-semibold text-indigo-600 bg-indigo-50 hover:bg-indigo-100 transition-colors"
              >
                Choose Starter
              </button>
            </div>

            {/* Growth */}
            <div className="bg-white rounded-2xl p-6 border-2 border-indigo-600 shadow-elevated relative flex flex-col justify-between">
              <span className="absolute -top-3 left-1/2 -translate-x-1/2 bg-indigo-600 text-white text-[10px] font-bold uppercase tracking-wider px-3 py-0.5 rounded-full">
                Most Popular
              </span>
              <div>
                <h3 className="text-base font-bold text-slate-800">Growth</h3>
                <p className="text-xs text-slate-500 mb-4">For growing coaching centers</p>
                <div className="text-2xl font-extrabold text-slate-900 mb-4">
                  ₹7,999<span className="text-xs text-slate-500 font-normal">/month</span>
                </div>
                <ul className="space-y-2.5 text-xs text-slate-600 mb-6">
                  <li className="flex items-center"><CheckCircle className="w-4 h-4 text-emerald-500 mr-2" /> Up to 500 students</li>
                  <li className="flex items-center"><CheckCircle className="w-4 h-4 text-emerald-500 mr-2" /> Advanced digital board & PDF import</li>
                  <li className="flex items-center"><CheckCircle className="w-4 h-4 text-emerald-500 mr-2" /> Tests, assignments & grading</li>
                  <li className="flex items-center"><CheckCircle className="w-4 h-4 text-emerald-500 mr-2" /> Automated attendance</li>
                  <li className="flex items-center"><CheckCircle className="w-4 h-4 text-emerald-500 mr-2" /> Institute performance analytics</li>
                </ul>
              </div>
              <button
                onClick={() => setDemoModalOpen(true)}
                className="w-full py-2.5 rounded-xl text-xs font-semibold text-white bg-indigo-600 hover:bg-indigo-700 shadow-sm transition-colors"
              >
                Choose Growth
              </button>
            </div>

            {/* Institute Pro */}
            <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-card flex flex-col justify-between">
              <div>
                <h3 className="text-base font-bold text-slate-800">Institute Pro</h3>
                <p className="text-xs text-slate-500 mb-4">For established academies</p>
                <div className="text-2xl font-extrabold text-slate-900 mb-4">
                  ₹14,999<span className="text-xs text-slate-500 font-normal">/month</span>
                </div>
                <ul className="space-y-2.5 text-xs text-slate-600 mb-6">
                  <li className="flex items-center"><CheckCircle className="w-4 h-4 text-emerald-500 mr-2" /> Up to 2,000 students</li>
                  <li className="flex items-center"><CheckCircle className="w-4 h-4 text-emerald-500 mr-2" /> Complete fee management & Razorpay</li>
                  <li className="flex items-center"><CheckCircle className="w-4 h-4 text-emerald-500 mr-2" /> AI lecture notes & summaries</li>
                  <li className="flex items-center"><CheckCircle className="w-4 h-4 text-emerald-500 mr-2" /> Institute branding & custom logo</li>
                  <li className="flex items-center"><CheckCircle className="w-4 h-4 text-emerald-500 mr-2" /> Priority 24/7 SLA support</li>
                </ul>
              </div>
              <button
                onClick={() => setDemoModalOpen(true)}
                className="w-full py-2.5 rounded-xl text-xs font-semibold text-indigo-600 bg-indigo-50 hover:bg-indigo-100 transition-colors"
              >
                Choose Pro
              </button>
            </div>

            {/* Enterprise */}
            <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-card flex flex-col justify-between">
              <div>
                <h3 className="text-base font-bold text-slate-800">Enterprise</h3>
                <p className="text-xs text-slate-500 mb-4">Multi-branch school chains</p>
                <div className="text-2xl font-extrabold text-slate-900 mb-4">
                  Custom
                </div>
                <ul className="space-y-2.5 text-xs text-slate-600 mb-6">
                  <li className="flex items-center"><CheckCircle className="w-4 h-4 text-emerald-500 mr-2" /> Unlimited students & teachers</li>
                  <li className="flex items-center"><CheckCircle className="w-4 h-4 text-emerald-500 mr-2" /> Custom domain & white-label apps</li>
                  <li className="flex items-center"><CheckCircle className="w-4 h-4 text-emerald-500 mr-2" /> Dedicated LiveKit server infra</li>
                  <li className="flex items-center"><CheckCircle className="w-4 h-4 text-emerald-500 mr-2" /> Custom ERP & SIS database sync</li>
                </ul>
              </div>
              <button
                onClick={() => setDemoModalOpen(true)}
                className="w-full py-2.5 rounded-xl text-xs font-semibold text-slate-700 bg-slate-100 hover:bg-slate-200 transition-colors"
              >
                Talk to Sales
              </button>
            </div>
          </div>
        </div>
      </section>

      {/* Book a Demo Modal */}
      {demoModalOpen && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl shadow-elevated border border-slate-200 p-6 max-w-md w-full">
            <h3 className="text-lg font-bold text-slate-900 mb-2">Book a Live Classora Demo</h3>
            <p className="text-xs text-slate-600 mb-4">
              See how our digital board, live class engine, and LMS can streamline your coaching academy.
            </p>

            {demoSubmitted ? (
              <div className="bg-emerald-50 border border-emerald-200 rounded-xl p-4 text-center">
                <CheckCircle className="w-8 h-8 text-emerald-600 mx-auto mb-2" />
                <h4 className="text-sm font-bold text-emerald-900">Demo Scheduled!</h4>
                <p className="text-xs text-emerald-700 mt-1">
                  Our institute success lead will contact you via WhatsApp / email within 15 minutes.
                </p>
                <button
                  onClick={() => {
                    setDemoModalOpen(false);
                    setDemoSubmitted(false);
                  }}
                  className="mt-4 px-4 py-1.5 text-xs font-semibold text-white bg-emerald-600 hover:bg-emerald-700 rounded-lg"
                >
                  Close
                </button>
              </div>
            ) : (
              <form
                onSubmit={(e) => {
                  e.preventDefault();
                  setDemoSubmitted(true);
                }}
                className="space-y-3"
              >
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    Your Name
                  </label>
                  <input
                    required
                    placeholder="Prof. Ramesh Gupta"
                    className="w-full text-xs p-2.5 border border-slate-200 rounded-lg focus:ring-2 focus:ring-indigo-500"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    Institute / Coaching Name
                  </label>
                  <input
                    required
                    placeholder="Apex IIT-JEE Classes"
                    className="w-full text-xs p-2.5 border border-slate-200 rounded-lg focus:ring-2 focus:ring-indigo-500"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    WhatsApp Number
                  </label>
                  <input
                    required
                    placeholder="+91 98765 43210"
                    className="w-full text-xs p-2.5 border border-slate-200 rounded-lg focus:ring-2 focus:ring-indigo-500"
                  />
                </div>
                <div className="flex justify-end space-x-2 pt-2">
                  <button
                    type="button"
                    onClick={() => setDemoModalOpen(false)}
                    className="px-4 py-2 text-xs font-medium text-slate-600 hover:bg-slate-100 rounded-lg"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    className="px-4 py-2 text-xs font-semibold text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg shadow-sm"
                  >
                    Confirm Booking
                  </button>
                </div>
              </form>
            )}
          </div>
        </div>
      )}

      {/* Footer */}
      <footer className="bg-slate-100 border-t border-slate-200 py-12 text-slate-600 text-xs">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex flex-col sm:flex-row justify-between items-center gap-4">
          <div className="flex items-center space-x-2">
            <span className="font-bold text-slate-800 text-sm">Classora</span>
            <span>&copy; {new Date().getFullYear()} Classora Inc. All rights reserved.</span>
          </div>
          <div className="flex items-center space-x-6 font-medium">
            <a href="#features" className="hover:text-slate-900">Privacy Policy</a>
            <a href="#features" className="hover:text-slate-900">Terms of Service</a>
            <a href="#features" className="hover:text-slate-900">Security & Compliance</a>
          </div>
        </div>
      </footer>
    </div>
  );
};
