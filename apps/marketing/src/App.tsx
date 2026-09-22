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
  ExternalLink,
  Laptop,
  Check,
} from 'lucide-react';

export function App() {
  const [demoModalOpen, setDemoModalOpen] = useState(false);
  const [demoSubmitted, setDemoSubmitted] = useState(false);

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 font-sans">
      {/* Top Banner */}
      <div className="bg-indigo-600 text-white text-xs py-2 px-4 text-center font-semibold flex items-center justify-center space-x-2">
        <Sparkles className="w-3.5 h-3.5" />
        <span>Classora 2.0 is Live on Local Ports! Separate standalone applications running independently.</span>
        <button
          onClick={() => setDemoModalOpen(true)}
          className="underline font-bold hover:text-indigo-100 ml-1"
        >
          Book Live Demo &rarr;
        </button>
      </div>

      {/* Header */}
      <header className="sticky top-0 bg-white/95 backdrop-blur-md border-b border-slate-200 z-50 shadow-subtle">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 rounded-xl bg-indigo-600 flex items-center justify-center text-white font-black text-xl shadow-md">
              C
            </div>
            <div>
              <span className="text-xl font-extrabold tracking-tight text-slate-900">Classora</span>
              <span className="text-[10px] font-bold text-indigo-600 uppercase tracking-widest block -mt-1">
                classora.com (Port 3000)
              </span>
            </div>
          </div>

          <nav className="hidden md:flex items-center space-x-8 text-xs font-bold text-slate-600">
            <a href="#features" className="hover:text-indigo-600 transition-colors">Platform</a>
            <a href="#teacher-studio" className="hover:text-indigo-600 transition-colors">Teacher Studio</a>
            <a href="#student-portal" className="hover:text-indigo-600 transition-colors">Student App</a>
            <a href="#pricing" className="hover:text-indigo-600 transition-colors">Pricing</a>
          </nav>

          {/* Links to Separate App Ports */}
          <div className="flex items-center space-x-2">
            <a
              href="http://localhost:3003"
              target="_blank"
              rel="noreferrer"
              className="text-xs font-bold text-slate-700 hover:text-indigo-600 px-3 py-2 rounded-xl hover:bg-slate-100 transition-colors flex items-center space-x-1"
            >
              <span>Student (3003)</span>
              <ExternalLink className="w-3 h-3" />
            </a>

            <a
              href="http://localhost:3002"
              target="_blank"
              rel="noreferrer"
              className="text-xs font-bold text-indigo-700 bg-indigo-50 hover:bg-indigo-100 border border-indigo-200 px-3 py-2 rounded-xl transition-colors flex items-center space-x-1"
            >
              <span>Teacher (3002)</span>
              <ExternalLink className="w-3 h-3" />
            </a>

            <a
              href="http://localhost:3001"
              target="_blank"
              rel="noreferrer"
              className="text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-700 px-3.5 py-2 rounded-xl shadow-sm transition-colors flex items-center space-x-1"
            >
              <span>Admin (3001)</span>
              <ExternalLink className="w-3 h-3" />
            </a>
          </div>
        </div>
      </header>

      {/* Hero Section with AI-Generated Image */}
      <section className="pt-12 pb-16 bg-white border-b border-slate-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-3xl mx-auto mb-10">
            <div className="inline-flex items-center space-x-2 px-3 py-1 rounded-full bg-indigo-50 border border-indigo-200 text-indigo-700 text-xs font-bold mb-4">
              <span className="w-2 h-2 rounded-full bg-indigo-600 animate-pulse"></span>
              <span>Ultra-Low Latency Interactive Classroom OS</span>
            </div>
            <h1 className="text-4xl sm:text-5xl lg:text-6xl font-black text-slate-900 tracking-tight leading-[1.12] mb-5">
              Teach. Stream. Write. <span className="text-indigo-600">Learn.</span>
            </h1>
            <p className="text-base sm:text-lg text-slate-600 leading-relaxed max-w-2xl mx-auto mb-8">
              Transform your coaching institute into a digital powerhouse. Collaborative digital whiteboard with photo/document import, live teacher webcam & Bluetooth headset streaming, online MCQ tests, and automated fee collections.
            </p>
            <div className="flex flex-col sm:flex-row items-center justify-center gap-3">
              <a
                href="http://localhost:3002"
                className="w-full sm:w-auto px-6 py-3.5 rounded-xl font-bold text-xs text-white bg-indigo-600 hover:bg-indigo-700 shadow-md flex items-center justify-center space-x-2 transition-all"
              >
                <span>Launch Teacher Studio (Port 3002)</span>
                <ArrowRight className="w-4 h-4" />
              </a>
              <a
                href="http://localhost:3001"
                className="w-full sm:w-auto px-6 py-3.5 rounded-xl font-bold text-xs text-slate-700 bg-slate-100 hover:bg-slate-200 border border-slate-200 flex items-center justify-center space-x-2 transition-all"
              >
                <span>Open Admin Portal (Port 3001)</span>
              </a>
            </div>
          </div>

          {/* AI-Generated Main Classroom Hero Visual Asset */}
          <div className="relative rounded-3xl overflow-hidden border-2 border-slate-200 shadow-elevated max-w-5xl mx-auto">
            <img
              src="/assets/hero.jpg"
              alt="Classora Smart Digital Classroom with Students and Whiteboard"
              className="w-full h-auto object-cover max-h-[520px]"
            />
            <div className="absolute bottom-4 left-4 right-4 bg-white/95 backdrop-blur-md p-4 rounded-2xl border border-slate-200/90 shadow-lg flex flex-col sm:flex-row sm:items-center justify-between gap-3">
              <div className="flex items-center space-x-3">
                <div className="w-3 h-3 rounded-full bg-emerald-500 animate-ping" />
                <div>
                  <h4 className="text-xs font-bold text-slate-900">Real-Time Classroom Collaboration</h4>
                  <p className="text-[11px] text-slate-500">LiveKit WebRTC + Yjs CRDT whiteboard synchronization</p>
                </div>
              </div>
              <div className="flex items-center space-x-2 text-xs font-bold text-indigo-700">
                <span className="bg-indigo-50 px-2.5 py-1 rounded-lg border border-indigo-100">4K Crisp Board</span>
                <span className="bg-emerald-50 text-emerald-700 px-2.5 py-1 rounded-lg border border-emerald-100">0ms Input Lag</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Teacher Live Studio & Hardware Spotlight with Generated Asset */}
      <section id="teacher-studio" className="py-20 bg-slate-50 border-b border-slate-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
            <div>
              <span className="text-xs font-extrabold text-indigo-600 uppercase tracking-wider">
                Teacher Broadcasting Studio
              </span>
              <h2 className="text-3xl sm:text-4xl font-extrabold text-slate-900 mt-2 mb-4">
                Hardware Device Hub with Webcam & Bluetooth Integration
              </h2>
              <p className="text-sm text-slate-600 leading-relaxed mb-6">
                Teachers get a dedicated pre-broadcast console to test camera mirrors, select USB webcams, connect wireless Bluetooth neckbands or AirPods, and calibrate mic levels before going live.
              </p>

              <div className="space-y-3.5 text-xs text-slate-700">
                <div className="flex items-start space-x-3 p-3 bg-white rounded-xl border border-slate-200 shadow-subtle">
                  <CheckCircle className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                  <div>
                    <strong className="block text-slate-900">Webcam & Camera Device Enumeration:</strong>
                    Seamlessly switch between internal laptop webcams, external 4K stream cams, and document cameras.
                  </div>
                </div>

                <div className="flex items-start space-x-3 p-3 bg-white rounded-xl border border-slate-200 shadow-subtle">
                  <CheckCircle className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                  <div>
                    <strong className="block text-slate-900">Bluetooth Device Pairing:</strong>
                    Web Bluetooth scanning connects wireless headphones and wireless drawing styluses effortlessly.
                  </div>
                </div>

                <div className="flex items-start space-x-3 p-3 bg-white rounded-xl border border-slate-200 shadow-subtle">
                  <CheckCircle className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                  <div>
                    <strong className="block text-slate-900">Production Digital Board:</strong>
                    Granular pen size sliders (1px-40px), insert photos and PDF documents directly on the board to annotate on top.
                  </div>
                </div>
              </div>

              <div className="mt-8">
                <a
                  href="http://localhost:3002"
                  className="inline-flex items-center space-x-2 px-6 py-3 rounded-xl font-bold text-xs text-white bg-indigo-600 hover:bg-indigo-700 shadow-md transition-all"
                >
                  <span>Open Teacher Console (Port 3002)</span>
                  <ExternalLink className="w-4 h-4" />
                </a>
              </div>
            </div>

            {/* AI Generated Teacher Studio Asset */}
            <div className="rounded-3xl overflow-hidden border-2 border-slate-200 shadow-elevated bg-white p-2">
              <img
                src="/assets/teacher_studio.jpg"
                alt="Teacher in Studio with Bluetooth Headset and Whiteboard"
                className="w-full h-auto rounded-2xl object-cover"
              />
            </div>
          </div>
        </div>
      </section>

      {/* Student Learning Experience with Generated Asset */}
      <section id="student-portal" className="py-20 bg-white border-b border-slate-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
            {/* AI Generated Student Asset */}
            <div className="order-2 lg:order-1 rounded-3xl overflow-hidden border-2 border-slate-200 shadow-elevated bg-slate-50 p-2">
              <img
                src="/assets/student_study.jpg"
                alt="Student studying with tablet, laptop and digital notes"
                className="w-full h-auto rounded-2xl object-cover"
              />
            </div>

            <div className="order-1 lg:order-2">
              <span className="text-xs font-extrabold text-indigo-600 uppercase tracking-wider">
                Student Learning Portal
              </span>
              <h2 className="text-3xl sm:text-4xl font-extrabold text-slate-900 mt-2 mb-4">
                Responsive on Phones, Tablets & Laptops
              </h2>
              <p className="text-sm text-slate-600 leading-relaxed mb-6">
                Students access live lectures, participate in chat discussions, raise doubts directly from whiteboard steps, take timed online MCQ tests, and submit homework assignments from any device.
              </p>

              <div className="space-y-3.5 text-xs text-slate-700">
                <div className="flex items-start space-x-3 p-3 bg-slate-50 rounded-xl border border-slate-200">
                  <CheckCircle className="w-4 h-4 text-indigo-600 shrink-0 mt-0.5" />
                  <div>
                    <strong className="block text-slate-900">Pre-Join Device Permissions:</strong>
                    Quick permission modal asking for camera and mic access with instant fallback to listener/chat-only mode.
                  </div>
                </div>

                <div className="flex items-start space-x-3 p-3 bg-slate-50 rounded-xl border border-slate-200">
                  <CheckCircle className="w-4 h-4 text-indigo-600 shrink-0 mt-0.5" />
                  <div>
                    <strong className="block text-slate-900">Full Live Chat & Doubt Queue:</strong>
                    Ask doubts anytime without interrupting the teacher's flow.
                  </div>
                </div>

                <div className="flex items-start space-x-3 p-3 bg-slate-50 rounded-xl border border-slate-200">
                  <CheckCircle className="w-4 h-4 text-indigo-600 shrink-0 mt-0.5" />
                  <div>
                    <strong className="block text-slate-900">Automated Fee Checkout:</strong>
                    Integrated Razorpay UPI & card payment gateway with downloadable GST receipts.
                  </div>
                </div>
              </div>

              <div className="mt-8">
                <a
                  href="http://localhost:3003"
                  className="inline-flex items-center space-x-2 px-6 py-3 rounded-xl font-bold text-xs text-white bg-indigo-600 hover:bg-indigo-700 shadow-md transition-all"
                >
                  <span>Open Student Portal (Port 3003)</span>
                  <ExternalLink className="w-4 h-4" />
                </a>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Pricing Section */}
      <section id="pricing" className="py-20 bg-slate-50 border-b border-slate-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-2xl mx-auto mb-14">
            <span className="text-xs font-bold text-indigo-600 uppercase tracking-wider">Pricing Plans</span>
            <h2 className="text-3xl font-extrabold text-slate-900 mt-2 mb-3">
              Simple, Transparent Plans Built for Scale
            </h2>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
            <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-card">
              <h3 className="text-base font-bold text-slate-800">Starter</h3>
              <p className="text-xs text-slate-500 mb-4">Individual teachers</p>
              <div className="text-2xl font-extrabold text-slate-900 mb-4">
                ₹2,999<span className="text-xs text-slate-500 font-normal">/mo</span>
              </div>
              <ul className="space-y-2 text-xs text-slate-600 mb-6">
                <li className="flex items-center"><Check className="w-3.5 h-3.5 text-emerald-500 mr-2" /> 100 students</li>
                <li className="flex items-center"><Check className="w-3.5 h-3.5 text-emerald-500 mr-2" /> Live interactive classes</li>
                <li className="flex items-center"><Check className="w-3.5 h-3.5 text-emerald-500 mr-2" /> Digital board sync</li>
              </ul>
              <button onClick={() => setDemoModalOpen(true)} className="w-full py-2 rounded-xl text-xs font-bold text-indigo-600 bg-indigo-50 hover:bg-indigo-100">
                Choose Starter
              </button>
            </div>

            <div className="bg-white rounded-2xl p-6 border-2 border-indigo-600 shadow-elevated relative">
              <span className="absolute -top-3 left-1/2 -translate-x-1/2 bg-indigo-600 text-white text-[10px] font-bold uppercase tracking-wider px-3 py-0.5 rounded-full">
                Most Popular
              </span>
              <h3 className="text-base font-bold text-slate-800">Growth</h3>
              <p className="text-xs text-slate-500 mb-4">Growing coaching institutes</p>
              <div className="text-2xl font-extrabold text-slate-900 mb-4">
                ₹7,999<span className="text-xs text-slate-500 font-normal">/mo</span>
              </div>
              <ul className="space-y-2 text-xs text-slate-600 mb-6">
                <li className="flex items-center"><Check className="w-3.5 h-3.5 text-emerald-500 mr-2" /> 500 students</li>
                <li className="flex items-center"><Check className="w-3.5 h-3.5 text-emerald-500 mr-2" /> Advanced board & PDF import</li>
                <li className="flex items-center"><Check className="w-3.5 h-3.5 text-emerald-500 mr-2" /> Online tests & LMS</li>
              </ul>
              <button onClick={() => setDemoModalOpen(true)} className="w-full py-2 rounded-xl text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-700">
                Choose Growth
              </button>
            </div>

            <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-card">
              <h3 className="text-base font-bold text-slate-800">Institute Pro</h3>
              <p className="text-xs text-slate-500 mb-4">Large academies</p>
              <div className="text-2xl font-extrabold text-slate-900 mb-4">
                ₹14,999<span className="text-xs text-slate-500 font-normal">/mo</span>
              </div>
              <ul className="space-y-2 text-xs text-slate-600 mb-6">
                <li className="flex items-center"><Check className="w-3.5 h-3.5 text-emerald-500 mr-2" /> 2,000 students</li>
                <li className="flex items-center"><Check className="w-3.5 h-3.5 text-emerald-500 mr-2" /> Complete fee management</li>
                <li className="flex items-center"><Check className="w-3.5 h-3.5 text-emerald-500 mr-2" /> Branding & white label</li>
              </ul>
              <button onClick={() => setDemoModalOpen(true)} className="w-full py-2 rounded-xl text-xs font-bold text-indigo-600 bg-indigo-50 hover:bg-indigo-100">
                Choose Pro
              </button>
            </div>

            <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-card">
              <h3 className="text-base font-bold text-slate-800">Enterprise</h3>
              <p className="text-xs text-slate-500 mb-4">School chains & colleges</p>
              <div className="text-2xl font-extrabold text-slate-900 mb-4">Custom</div>
              <ul className="space-y-2 text-xs text-slate-600 mb-6">
                <li className="flex items-center"><Check className="w-3.5 h-3.5 text-emerald-500 mr-2" /> Unlimited students</li>
                <li className="flex items-center"><Check className="w-3.5 h-3.5 text-emerald-500 mr-2" /> Dedicated servers</li>
                <li className="flex items-center"><Check className="w-3.5 h-3.5 text-emerald-500 mr-2" /> 24/7 SLA Support</li>
              </ul>
              <button onClick={() => setDemoModalOpen(true)} className="w-full py-2 rounded-xl text-xs font-bold text-slate-700 bg-slate-100 hover:bg-slate-200">
                Contact Sales
              </button>
            </div>
          </div>
        </div>
      </section>

      {/* Book a Demo Modal */}
      {demoModalOpen && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl shadow-elevated border border-slate-200 p-6 max-w-md w-full">
            <h3 className="text-lg font-bold text-slate-900 mb-1">Book Classora Live Walkthrough</h3>
            <p className="text-xs text-slate-500 mb-4">See how the digital board and live class engine work together.</p>
            {demoSubmitted ? (
              <div className="bg-emerald-50 border border-emerald-200 rounded-xl p-4 text-center">
                <CheckCircle className="w-8 h-8 text-emerald-600 mx-auto mb-2" />
                <h4 className="text-sm font-bold text-emerald-900">Demo Scheduled!</h4>
                <p className="text-xs text-emerald-700 mt-1">Our team will connect with you in 15 minutes.</p>
                <button
                  onClick={() => { setDemoModalOpen(false); setDemoSubmitted(false); }}
                  className="mt-4 px-4 py-1.5 text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-700 rounded-lg"
                >
                  Close
                </button>
              </div>
            ) : (
              <form onSubmit={(e) => { e.preventDefault(); setDemoSubmitted(true); }} className="space-y-3 text-xs">
                <div>
                  <label className="block font-semibold text-slate-700 mb-1">Your Name</label>
                  <input required placeholder="Prof. Rajesh Sharma" className="w-full p-2.5 border border-slate-200 rounded-lg" />
                </div>
                <div>
                  <label className="block font-semibold text-slate-700 mb-1">Institute Name</label>
                  <input required placeholder="Apex Academy" className="w-full p-2.5 border border-slate-200 rounded-lg" />
                </div>
                <div>
                  <label className="block font-semibold text-slate-700 mb-1">WhatsApp Number</label>
                  <input required placeholder="+91 98765 43210" className="w-full p-2.5 border border-slate-200 rounded-lg" />
                </div>
                <div className="flex justify-end space-x-2 pt-2">
                  <button type="button" onClick={() => setDemoModalOpen(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg">
                    Cancel
                  </button>
                  <button type="submit" className="px-4 py-2 font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg shadow-sm">
                    Confirm Booking
                  </button>
                </div>
              </form>
            )}
          </div>
        </div>
      )}

      {/* Footer */}
      <footer className="bg-slate-100 border-t border-slate-200 py-8 text-slate-600 text-xs text-center">
        <p>&copy; {new Date().getFullYear()} Classora Inc. All rights reserved. &bull; Pure Light Theme</p>
      </footer>
    </div>
  );
}

export default App;
