import React, { useState } from 'react';
import {
  ChevronLeft,
  ChevronRight,
  ChevronDown,
  ChevronUp,
  FileText,
  Download,
  ZoomIn,
  ZoomOut,
  Maximize2,
  FileCheck,
  CheckCircle2,
  Sparkles,
  Eye,
  EyeOff,
  Layers,
  ExternalLink,
} from 'lucide-react';

export interface DocumentSlide {
  pageNumber: number;
  title: string;
  subtitle?: string;
  content: string[];
  formula?: string;
  diagramUrl?: string;
}

export interface DocumentItem {
  id: string;
  title: string;
  fileName: string;
  author: string;
  totalPages: number;
  fileUrl?: string;
  slides: DocumentSlide[];
}

interface DocumentViewerProps {
  document?: DocumentItem;
  onClose?: () => void;
}

export const samplePhysicsDocument: DocumentItem = {
  id: 'doc-physics-01',
  title: 'Rotational Dynamics & Torque Master Lecture Notes',
  fileName: 'Physics_Rotational_Motion_Lecture_Slides.pdf',
  author: 'Prof. Rajesh Sharma',
  totalPages: 5,
  slides: [
    {
      pageNumber: 1,
      title: 'Page 1: Introduction to Rigid Body Rotation',
      subtitle: 'Chapter 01 - Pure Rotational Mechanics',
      content: [
        '• Rigid Body Definition: A system of particles in which the distance between any two given particles remains invariant.',
        '• Angular Velocity (ω): Rate of change of angular displacement θ with time t. Units: rad/s.',
        '• Relationship between linear velocity v and angular velocity ω: v = r × ω.',
      ],
      formula: 'v = r \\cdot \\omega \\quad \\text{and} \\quad a_t = r \\cdot \\alpha',
      diagramUrl: 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=600&h=350&fit=crop',
    },
    {
      pageNumber: 2,
      title: 'Page 2: Moment of Inertia (I) & Parallel Axis Theorem',
      subtitle: 'Mass Distribution & Rotational Resistance',
      content: [
        '• Moment of Inertia (I) measures resistance to angular acceleration about a fixed axis.',
        '• Discrete system: I = ∑ (m_i * r_i²). Continuous body: I = ∫ r² dm.',
        '• Parallel Axis Theorem: I = I_cm + M * d², where d is distance from center of mass.',
      ],
      formula: 'I = I_{cm} + M d^2 \\quad \\text{and} \\quad I_{perpendicular} = I_x + I_y',
      diagramUrl: 'https://images.unsplash.com/photo-1509228468518-180dd4864904?w=600&h=350&fit=crop',
    },
    {
      pageNumber: 3,
      title: 'Page 3: Torque (τ) & Rotational Work-Energy Theorem',
      subtitle: 'Rotational Analogue of Newton’s Second Law',
      content: [
        '• Torque (τ) is the rotational equivalent of linear force. τ = r × F = r F sin(θ).',
        '• Rotational Form of Newton 2nd Law: Net Torque τ_net = I * α.',
        '• Rotational Kinetic Energy K_rot = (1/2) * I * ω².',
      ],
      formula: '\\tau = I \\alpha \\quad \\text{and} \\quad W_{rot} = \\int \\tau d\\theta = \\Delta K_{rot}',
      diagramUrl: 'https://images.unsplash.com/photo-1518152006812-edab29b069ac?w=600&h=350&fit=crop',
    },
    {
      pageNumber: 4,
      title: 'Page 4: Conservation of Angular Momentum (L)',
      subtitle: 'No External Torque Condition',
      content: [
        '• Angular Momentum (L) = I * ω for a rigid body rotating about a symmetrical axis.',
        '• If net external torque τ_ext = 0, then total angular momentum L remains constant!',
        '• Classic Example: Figure skater pulling in arms decreases I, causing angular velocity ω to increase rapidly.',
      ],
      formula: 'L_i = L_f \\implies I_1 \\omega_1 = I_2 \\omega_2',
      diagramUrl: 'https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=600&h=350&fit=crop',
    },
    {
      pageNumber: 5,
      title: 'Page 5: Pure Rolling Motion on Horizontal Surface',
      subtitle: 'Condition of No Slipping',
      content: [
        '• Pure Rolling occurs when the point of contact with the ground has zero instantaneous velocity.',
        '• Rolling Condition: v_cm = R * ω and a_cm = R * α.',
        '• Total Kinetic Energy = Translational K.E. + Rotational K.E. = (1/2) M v_cm² + (1/2) I_cm ω².',
      ],
      formula: 'K_{total} = \\frac{1}{2} M v_{cm}^2 \\left(1 + \\frac{k^2}{R^2}\\right)',
      diagramUrl: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=600&h=350&fit=crop',
    },
  ],
};

export const DocumentViewer: React.FC<DocumentViewerProps> = ({
  document = samplePhysicsDocument,
  onClose,
}) => {
  const [currentPage, setCurrentPage] = useState(1);
  const [zoomLevel, setZoomLevel] = useState(100);
  const [viewMode, setViewMode] = useState<'pdf' | 'slides'>('slides');
  const [isNavHidden, setIsNavHidden] = useState(false);

  const totalPages = document.totalPages || (document.slides?.length ? document.slides.length : 10);
  const currentSlide = document.slides?.[currentPage - 1] || document.slides?.[0];

  const handleNextPage = () => {
    if (currentPage < totalPages) {
      setCurrentPage((prev) => prev + 1);
    }
  };

  const handlePrevPage = () => {
    if (currentPage > 1) {
      setCurrentPage((prev) => prev - 1);
    }
  };

  const handleDownload = (e: React.MouseEvent) => {
    e.preventDefault();
    if (document.fileUrl) {
      const a = window.document.createElement('a');
      a.href = document.fileUrl;
      a.download = document.fileName || 'document.pdf';
      window.document.body.appendChild(a);
      a.click();
      window.document.body.removeChild(a);
    } else {
      alert(`Downloading ${document.fileName}...`);
    }
  };

  return (
    <div className="bg-white rounded-2xl border border-slate-200 shadow-card flex flex-col overflow-hidden font-sans h-full w-full">
      {/* Document Header Bar */}
      <div className="min-h-14 py-2 bg-slate-900 text-white px-3 sm:px-5 flex items-center justify-between shrink-0 border-b border-slate-800 gap-2 flex-wrap sm:flex-nowrap">
        <div className="flex items-center space-x-2.5 sm:space-x-3 overflow-hidden min-w-0">
          <div className="w-8 h-8 rounded-lg bg-indigo-500/20 text-indigo-400 flex items-center justify-center shrink-0 border border-indigo-500/30">
            <FileText className="w-4 h-4" />
          </div>
          <div className="overflow-hidden min-w-0">
            <h3 className="text-xs sm:text-sm font-bold truncate text-white">{document.title}</h3>
            <p className="text-[10px] sm:text-[11px] text-slate-400 truncate">
              {document.fileName} &bull; Uploaded by {document.author}
            </p>
          </div>
        </div>

        {/* Top View Mode & Actions */}
        <div className="flex items-center space-x-2 sm:space-x-3 shrink-0 ml-auto">
          {/* Switcher if fileUrl is available */}
          {document.fileUrl && (
            <div className="flex items-center bg-slate-800 p-0.5 rounded-lg border border-slate-700 text-xs">
              <button
                onClick={() => setViewMode('slides')}
                className={`px-2.5 py-1 rounded-md text-xs font-bold transition-all ${
                  viewMode === 'slides'
                    ? 'bg-indigo-600 text-white shadow-sm'
                    : 'text-slate-400 hover:text-white'
                }`}
              >
                Slide View
              </button>
              <button
                onClick={() => setViewMode('pdf')}
                className={`px-2.5 py-1 rounded-md text-xs font-bold transition-all ${
                  viewMode === 'pdf'
                    ? 'bg-indigo-600 text-white shadow-sm'
                    : 'text-slate-400 hover:text-white'
                }`}
              >
                PDF View
              </button>
            </div>
          )}

          {/* Zoom controls for Slide View */}
          <div className="hidden sm:flex items-center space-x-1 bg-slate-800 px-2 py-1 rounded-lg border border-slate-700 text-xs">
            <button
              onClick={() => setZoomLevel((z) => Math.max(75, z - 15))}
              className="p-1 hover:text-indigo-400 transition-colors"
              title="Zoom Out"
            >
              <ZoomOut className="w-3.5 h-3.5" />
            </button>
            <span className="px-1 text-[11px] font-semibold text-slate-300">{zoomLevel}%</span>
            <button
              onClick={() => setZoomLevel((z) => Math.min(150, z + 15))}
              className="p-1 hover:text-indigo-400 transition-colors"
              title="Zoom In"
            >
              <ZoomIn className="w-3.5 h-3.5" />
            </button>
          </div>

          <button
            onClick={handleDownload}
            className="px-3 py-1.5 text-xs font-semibold bg-indigo-600 hover:bg-indigo-500 text-white rounded-lg flex items-center space-x-1.5 transition-colors shadow-sm"
          >
            <Download className="w-3.5 h-3.5" />
            <span className="hidden sm:inline">Download</span>
          </button>

          {onClose && (
            <button
              onClick={onClose}
              className="text-xs text-slate-400 hover:text-white px-2.5 py-1.5 font-bold rounded-lg hover:bg-slate-800 transition-colors"
            >
              Close
            </button>
          )}
        </div>
      </div>

      {/* Main View Area */}
      <div className="relative flex-1 bg-slate-900 p-3 sm:p-4 flex flex-col items-center justify-center min-h-[420px] overflow-auto select-none">
        {viewMode === 'pdf' && document.fileUrl ? (
          /* PDF EMBEDDED VIEWER WITH MOBILE FALLBACK */
          <div className="w-full h-full min-h-[480px] bg-slate-950 rounded-xl overflow-hidden shadow-2xl border border-slate-800 flex flex-col relative p-2 sm:p-4">
            <div className="bg-slate-900/90 border border-indigo-500/30 rounded-xl p-3 mb-3 flex items-center justify-between flex-wrap gap-2 text-xs text-slate-300">
              <div className="flex items-center space-x-2">
                <FileCheck className="w-4 h-4 text-emerald-400" />
                <span>Viewing: <strong className="text-white">{document.fileName}</strong></span>
              </div>
              <button
                onClick={() => setViewMode('slides')}
                className="px-3 py-1 bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-bold rounded-lg transition-colors"
              >
                Switch to Interactive Slide Deck
              </button>
            </div>
            <div className="flex-1 w-full rounded-xl overflow-hidden bg-white shadow-inner relative flex flex-col items-center justify-center">
              <iframe
                src={`${document.fileUrl}#toolbar=1&navpanes=0`}
                title={document.title}
                className="w-full h-full min-h-[420px] border-0 rounded-xl bg-white"
              />
            </div>
          </div>
        ) : (
          /* SLIDE PRESENTATION DECK (ALWAYS VISIBLE & INTERACTIVE ON BOTH MOBILE AND DESKTOP) */
          <div
            className="w-full max-w-3xl bg-white rounded-2xl border border-slate-200 shadow-xl p-6 sm:p-8 transition-all duration-300 my-auto"
            style={{ transform: `scale(${zoomLevel / 100})`, transformOrigin: 'top center' }}
          >
            {/* Header of Slide */}
            <div className="flex justify-between items-start pb-4 border-b border-slate-100 mb-6">
              <div>
                <span className="text-[10px] font-extrabold uppercase tracking-wider bg-indigo-50 text-indigo-700 px-2.5 py-0.5 rounded-full border border-indigo-200">
                  {currentSlide?.subtitle || 'Presentation Slide'}
                </span>
                <h2 className="text-xl font-extrabold text-slate-900 mt-2">{currentSlide?.title || `Page ${currentPage}`}</h2>
              </div>
              <span className="text-xs font-bold text-slate-400 bg-slate-100 px-3 py-1 rounded-lg">
                Page {currentPage} / {totalPages}
              </span>
            </div>

            {/* Body Content */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 items-center">
              <div className="space-y-3">
                {currentSlide?.content?.map((point, i) => (
                  <p key={i} className="text-xs text-slate-700 leading-relaxed font-medium">
                    {point}
                  </p>
                ))}

                {currentSlide?.formula && (
                  <div className="mt-4 p-3 bg-indigo-50/70 border border-indigo-200 rounded-xl">
                    <span className="text-[10px] font-bold text-indigo-700 uppercase tracking-wider block mb-1">
                      Key Equation / Formula
                    </span>
                    <code className="text-xs font-mono font-bold text-indigo-950 block">
                      {currentSlide.formula}
                    </code>
                  </div>
                )}
              </div>

              {currentSlide?.diagramUrl && (
                <div className="relative rounded-xl overflow-hidden border border-slate-200 shadow-subtle group">
                  <img
                    src={currentSlide.diagramUrl}
                    alt={currentSlide.title}
                    className="w-full h-48 object-cover group-hover:scale-105 transition-transform duration-500"
                  />
                  <div className="absolute bottom-2 left-2 bg-slate-900/80 backdrop-blur-xs text-white text-[10px] font-semibold px-2 py-0.5 rounded">
                    Fig {currentPage}.1 — Illustrated Board Diagram
                  </div>
                </div>
              )}
            </div>
          </div>
        )}
      </div>

      {/* BOTTOM SLIDE NAVIGATION BAR (SLIDE VIEW ONLY) */}
      {viewMode === 'slides' && (!isNavHidden ? (
        <div className="h-16 bg-slate-900 border-t border-slate-800 px-4 sm:px-6 flex items-center justify-between shrink-0 shadow-2xl z-20 text-slate-200 transition-all duration-300">
          <div className="hidden sm:flex items-center space-x-2">
            <span className="text-xs font-bold text-slate-200">Slide Controls:</span>
            <span className="text-[11px] text-slate-400">
              Flip pages or jump directly
            </span>
          </div>

          {/* Center Page Selector & Next/Previous Buttons */}
          <div className="flex items-center space-x-3 bg-slate-800/90 p-1.5 rounded-xl border border-slate-700/80">
            <button
              onClick={handlePrevPage}
              disabled={currentPage === 1}
              className={`flex items-center space-x-1.5 px-3 sm:px-4 py-1.5 rounded-lg text-xs font-bold transition-all ${
                currentPage === 1
                  ? 'bg-slate-800 text-slate-600 cursor-not-allowed border border-slate-700/50'
                  : 'bg-slate-700 text-slate-100 hover:bg-indigo-600 hover:text-white shadow-sm border border-slate-600'
              }`}
            >
              <ChevronLeft className="w-4 h-4" />
              <span className="hidden sm:inline">Prev</span>
            </button>

            <div className="flex items-center space-x-1 px-2">
              <span className="text-sm font-extrabold text-indigo-400">{currentPage}</span>
              <span className="text-xs text-slate-500 font-semibold">/</span>
              <span className="text-xs font-bold text-slate-400">{totalPages}</span>
            </div>

            <button
              onClick={handleNextPage}
              disabled={currentPage === totalPages}
              className={`flex items-center space-x-1.5 px-3 sm:px-4 py-1.5 rounded-lg text-xs font-bold transition-all ${
                currentPage === totalPages
                  ? 'bg-slate-800 text-slate-600 cursor-not-allowed border border-slate-700/50'
                  : 'bg-indigo-600 text-white shadow-md hover:bg-indigo-500 active:bg-indigo-700'
              }`}
            >
              <span className="hidden sm:inline">Next</span>
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>

          {/* Right actions: Quick Jump & Hide Nav Toggle */}
          <div className="flex items-center space-x-3">
            <div className="hidden md:flex items-center space-x-2">
              <span className="text-xs text-slate-400 font-medium">Jump:</span>
              <select
                value={currentPage}
                onChange={(e) => setCurrentPage(Number(e.target.value))}
                className="text-xs font-bold text-slate-200 bg-slate-800 border border-slate-700 rounded-lg px-2.5 py-1.5 focus:ring-2 focus:ring-indigo-500"
              >
                {Array.from({ length: totalPages }, (_, i) => i + 1).map((pg) => (
                  <option key={pg} value={pg}>
                    Page {pg} {document.slides?.[pg - 1]?.title ? `: ${document.slides[pg - 1].title.substring(0, 18)}...` : ''}
                  </option>
                ))}
              </select>
            </div>

            <button
              onClick={() => setIsNavHidden(true)}
              className="p-2 text-slate-400 hover:text-white rounded-lg bg-slate-800 hover:bg-slate-750 transition-colors border border-slate-700"
              title="Hide Slide Navigation Bar"
            >
              <ChevronDown className="w-4 h-4" />
            </button>
          </div>
        </div>
      ) : (
        /* MINIMIZED TRIGGER BUTTON FOR SLIDE NAV */
        <div className="h-8 bg-slate-900/90 border-t border-slate-800 px-4 flex items-center justify-end shrink-0 z-20">
          <button
            onClick={() => setIsNavHidden(false)}
            className="flex items-center space-x-1.5 text-[11px] font-bold text-indigo-400 hover:text-indigo-300 bg-slate-800 px-3 py-1 rounded-full border border-slate-700 transition-colors"
          >
            <ChevronUp className="w-3.5 h-3.5" />
            <span>Show Slide Controls</span>
          </button>
        </div>
      ))}
    </div>
  );
};

