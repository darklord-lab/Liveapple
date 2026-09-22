import React, { useState } from 'react';
import {
  Video,
  Mic,
  MessageSquare,
  ShieldCheck,
  Smartphone,
  Tablet,
  Laptop,
  CheckCircle2,
  X,
  Play,
} from 'lucide-react';

interface StudentPreJoinModalProps {
  isOpen: boolean;
  onClose: () => void;
  onJoin?: (mode: { enableCamera: boolean; enableMic: boolean }) => void;
  onProceed?: (mode: { enableCamera: boolean; enableMic: boolean }) => void;
  lectureTitle?: string;
  classTitle?: string;
}

export const StudentPreJoinModal: React.FC<StudentPreJoinModalProps> = ({
  isOpen,
  onClose,
  onJoin,
  onProceed,
  lectureTitle,
  classTitle,
}) => {
  const displayTitle = lectureTitle || classTitle || 'Physics: Rotational Dynamics & Torque';
  const handleProceed = (mode: { enableCamera: boolean; enableMic: boolean }) => {
    const fn = onJoin || onProceed;
    if (fn) fn(mode);
  };
  const [cameraPerm, setCameraPerm] = useState(true);
  const [micPerm, setMicPerm] = useState(true);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-xs flex items-center justify-center p-4 z-50 animate-in fade-in duration-200">
      <div className="bg-white rounded-3xl shadow-elevated border border-slate-200 max-w-md w-full overflow-hidden flex flex-col font-sans">
        {/* Header */}
        <div className="px-6 py-4 border-b border-slate-200 flex items-center justify-between bg-slate-50/50">
          <div className="flex items-center space-x-2.5">
            <div className="w-8 h-8 rounded-xl bg-indigo-600 text-white flex items-center justify-center">
              <ShieldCheck className="w-4 h-4" />
            </div>
            <div>
              <h3 className="text-sm font-bold text-slate-900">Classroom Permissions</h3>
              <p className="text-[11px] text-slate-500">Device access for live participation</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 text-slate-400 hover:text-slate-600 rounded-lg"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Body */}
        <div className="p-6 space-y-4 text-xs">
          {/* Device Indicator */}
          <div className="flex items-center justify-center space-x-4 py-2 text-slate-500 bg-slate-50 rounded-2xl border border-slate-100">
            <span className="flex items-center space-x-1"><Smartphone className="w-4 h-4" /> <span>Phone</span></span>
            <span>&bull;</span>
            <span className="flex items-center space-x-1"><Tablet className="w-4 h-4" /> <span>Tablet</span></span>
            <span>&bull;</span>
            <span className="flex items-center space-x-1"><Laptop className="w-4 h-4" /> <span>Laptop</span></span>
          </div>

          <div className="space-y-3">
            <div className="p-3.5 rounded-2xl border border-slate-200 bg-white flex items-center justify-between">
              <div className="flex items-center space-x-3">
                <div className="w-8 h-8 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center">
                  <Video className="w-4 h-4" />
                </div>
                <div>
                  <h4 className="font-bold text-slate-800">Camera Access</h4>
                  <p className="text-[11px] text-slate-500">Allow teacher to see you when called on</p>
                </div>
              </div>
              <input
                type="checkbox"
                checked={cameraPerm}
                onChange={(e) => setCameraPerm(e.target.checked)}
                className="w-4 h-4 rounded text-indigo-600 focus:ring-indigo-500 cursor-pointer"
              />
            </div>

            <div className="p-3.5 rounded-2xl border border-slate-200 bg-white flex items-center justify-between">
              <div className="flex items-center space-x-3">
                <div className="w-8 h-8 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
                  <Mic className="w-4 h-4" />
                </div>
                <div>
                  <h4 className="font-bold text-slate-800">Microphone Access</h4>
                  <p className="text-[11px] text-slate-500">Unmute to speak when you raise hand</p>
                </div>
              </div>
              <input
                type="checkbox"
                checked={micPerm}
                onChange={(e) => setMicPerm(e.target.checked)}
                className="w-4 h-4 rounded text-indigo-600 focus:ring-indigo-500 cursor-pointer"
              />
            </div>

            <div className="p-3.5 rounded-2xl border border-indigo-100 bg-indigo-50/50 flex items-center space-x-3">
              <div className="w-8 h-8 rounded-xl bg-indigo-600 text-white flex items-center justify-center shrink-0">
                <MessageSquare className="w-4 h-4" />
              </div>
              <div>
                <h4 className="font-bold text-indigo-950">Live Chat & Doubts Always Enabled</h4>
                <p className="text-[11px] text-indigo-700">You can type questions and take polls at any time.</p>
              </div>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="px-6 py-4 bg-slate-50 border-t border-slate-200 flex flex-col sm:flex-row items-center justify-end gap-2">
          <button
            onClick={() => handleProceed({ enableCamera: false, enableMic: false })}
            className="w-full sm:w-auto px-4 py-2 text-xs font-semibold text-slate-600 hover:bg-slate-200/60 rounded-xl transition-colors text-center"
          >
            Join Chat / Listen Only
          </button>
          <button
            onClick={() => handleProceed({ enableCamera: cameraPerm, enableMic: micPerm })}
            className="w-full sm:w-auto px-5 py-2.5 text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-xl shadow-md transition-colors flex items-center justify-center space-x-1.5"
          >
            <Play className="w-3.5 h-3.5 fill-current" />
            <span>Enter Classroom</span>
          </button>
        </div>
      </div>
    </div>
  );
};
