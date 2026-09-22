import React, { useRef, useState, useEffect, useCallback } from 'react';
import {
  Pen,
  Highlighter,
  Eraser,
  Square,
  Circle,
  ArrowRight,
  Minus,
  Type,
  StickyNote,
  RotateCcw,
  RotateCw,
  Trash2,
  Download,
  ZoomIn,
  ZoomOut,
  Maximize2,
  Grid,
  ChevronLeft,
  ChevronRight,
  Plus,
  Compass,
  Palette,
} from 'lucide-react';

export type ToolType =
  | 'pen'
  | 'highlighter'
  | 'eraser'
  | 'rectangle'
  | 'circle'
  | 'line'
  | 'arrow'
  | 'text'
  | 'note'
  | 'laser';

export type BackgroundStyle = 'blank' | 'grid' | 'dots' | 'ruled';

interface Point {
  x: number;
  y: number;
}

interface BoardElement {
  id: string;
  type: ToolType;
  color: string;
  strokeWidth: number;
  points?: Point[];
  startX?: number;
  startY?: number;
  endX?: number;
  endY?: number;
  text?: string;
  isHighlighter?: boolean;
}

interface DigitalBoardProps {
  isTeacher?: boolean;
  onStrokeBroadcast?: (element: BoardElement) => void;
  onClearBroadcast?: () => void;
  remoteStroke?: BoardElement | null;
  remoteClear?: boolean;
}

const COLOR_PALETTE = [
  { name: 'Dark Slate', value: '#0f172a' },
  { name: 'Indigo Blue', value: '#4f46e5' },
  { name: 'Crimson Red', value: '#dc2626' },
  { name: 'Emerald Green', value: '#16a34a' },
  { name: 'Amber Gold', value: '#d97706' },
  { name: 'Purple', value: '#9333ea' },
];

export const DigitalBoard: React.FC<DigitalBoardProps> = ({
  isTeacher = true,
  onStrokeBroadcast,
  onClearBroadcast,
  remoteStroke,
  remoteClear,
}) => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const containerRef = useRef<HTMLDivElement | null>(null);

  // Board state
  const [currentPage, setCurrentPage] = useState<number>(0);
  const [pages, setPages] = useState<BoardElement[][]>([[]]);
  const [history, setHistory] = useState<BoardElement[][][]>([[[]]]);
  const [historyIndex, setHistoryIndex] = useState<number[]>([0]);

  // Active Tool Configuration
  const [activeTool, setActiveTool] = useState<ToolType>('pen');
  const [color, setColor] = useState<string>('#0f172a');
  const [strokeWidth, setStrokeWidth] = useState<number>(3);
  const [backgroundStyle, setBackgroundStyle] = useState<BackgroundStyle>('grid');
  const [zoom, setZoom] = useState<number>(1);
  const [pan, setPan] = useState<Point>({ x: 0, y: 0 });

  // Interaction State
  const [isDrawing, setIsDrawing] = useState<boolean>(false);
  const [currentElement, setCurrentElement] = useState<BoardElement | null>(null);
  const [laserPos, setLaserPos] = useState<Point | null>(null);

  // Text / Sticky Note Prompt Modal
  const [textModalOpen, setTextModalOpen] = useState(false);
  const [noteContent, setNoteContent] = useState('');
  const [noteClickPos, setNoteClickPos] = useState<Point>({ x: 100, y: 100 });

  // Redraw canvas
  const redraw = useCallback(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    // Reset transform & clear
    ctx.setTransform(1, 0, 0, 1, 0, 0);
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // Apply Zoom & Pan
    ctx.translate(pan.x, pan.y);
    ctx.scale(zoom, zoom);

    const elementsToRender = pages[currentPage] || [];

    // Render each saved element
    elementsToRender.forEach((el) => {
      ctx.save();
      ctx.strokeStyle = el.color;
      ctx.fillStyle = el.color;
      ctx.lineWidth = el.strokeWidth;
      ctx.lineCap = 'round';
      ctx.lineJoin = 'round';

      if (el.isHighlighter) {
        ctx.globalAlpha = 0.35;
      }

      if (el.type === 'eraser' && el.points && el.points.length > 0) {
        ctx.strokeStyle = '#ffffff';
        ctx.lineWidth = el.strokeWidth * 3;
        ctx.beginPath();
        ctx.moveTo(el.points[0].x, el.points[0].y);
        for (let i = 1; i < el.points.length; i++) {
          ctx.lineTo(el.points[i].x, el.points[i].y);
        }
        ctx.stroke();
      } else if ((el.type === 'pen' || el.type === 'highlighter') && el.points && el.points.length > 0) {
        ctx.beginPath();
        ctx.moveTo(el.points[0].x, el.points[0].y);
        for (let i = 1; i < el.points.length; i++) {
          ctx.lineTo(el.points[i].x, el.points[i].y);
        }
        ctx.stroke();
      } else if (el.type === 'rectangle' && el.startX !== undefined && el.startY !== undefined && el.endX !== undefined && el.endY !== undefined) {
        ctx.strokeRect(
          Math.min(el.startX, el.endX),
          Math.min(el.startY, el.endY),
          Math.abs(el.endX - el.startX),
          Math.abs(el.endY - el.startY)
        );
      } else if (el.type === 'circle' && el.startX !== undefined && el.startY !== undefined && el.endX !== undefined && el.endY !== undefined) {
        const radiusX = Math.abs(el.endX - el.startX) / 2;
        const radiusY = Math.abs(el.endY - el.startY) / 2;
        const centerX = Math.min(el.startX, el.endX) + radiusX;
        const centerY = Math.min(el.startY, el.endY) + radiusY;
        ctx.beginPath();
        ctx.ellipse(centerX, centerY, radiusX, radiusY, 0, 0, Math.PI * 2);
        ctx.stroke();
      } else if (el.type === 'line' && el.startX !== undefined && el.startY !== undefined && el.endX !== undefined && el.endY !== undefined) {
        ctx.beginPath();
        ctx.moveTo(el.startX, el.startY);
        ctx.lineTo(el.endX, el.endY);
        ctx.stroke();
      } else if (el.type === 'arrow' && el.startX !== undefined && el.startY !== undefined && el.endX !== undefined && el.endY !== undefined) {
        ctx.beginPath();
        ctx.moveTo(el.startX, el.startY);
        ctx.lineTo(el.endX, el.endY);
        ctx.stroke();

        // Arrowhead
        const angle = Math.atan2(el.endY - el.startY, el.endX - el.startX);
        const headLen = 14;
        ctx.beginPath();
        ctx.moveTo(el.endX, el.endY);
        ctx.lineTo(
          el.endX - headLen * Math.cos(angle - Math.PI / 6),
          el.endY - headLen * Math.sin(angle - Math.PI / 6)
        );
        ctx.moveTo(el.endX, el.endY);
        ctx.lineTo(
          el.endX - headLen * Math.cos(angle + Math.PI / 6),
          el.endY - headLen * Math.sin(angle + Math.PI / 6)
        );
        ctx.stroke();
      } else if (el.type === 'text' && el.text && el.startX !== undefined && el.startY !== undefined) {
        ctx.font = '600 18px Inter, sans-serif';
        ctx.fillText(el.text, el.startX, el.startY);
      } else if (el.type === 'note' && el.text && el.startX !== undefined && el.startY !== undefined) {
        // Light yellow sticky note
        ctx.fillStyle = '#fef3c7';
        ctx.strokeStyle = '#f59e0b';
        ctx.lineWidth = 1.5;
        const width = 160;
        const height = 100;
        ctx.fillRect(el.startX, el.startY, width, height);
        ctx.strokeRect(el.startX, el.startY, width, height);

        ctx.fillStyle = '#78350f';
        ctx.font = '500 14px Inter, sans-serif';
        const words = el.text.split(' ');
        let line = '';
        let yOffset = el.startY + 24;
        for (let n = 0; n < words.length; n++) {
          const testLine = line + words[n] + ' ';
          const metrics = ctx.measureText(testLine);
          if (metrics.width > width - 16 && n > 0) {
            ctx.fillText(line, el.startX + 8, yOffset);
            line = words[n] + ' ';
            yOffset += 18;
          } else {
            line = testLine;
          }
        }
        ctx.fillText(line, el.startX + 8, yOffset);
      }

      ctx.restore();
    });

    // Render active drawing stroke preview
    if (currentElement) {
      ctx.save();
      ctx.strokeStyle = currentElement.color;
      ctx.fillStyle = currentElement.color;
      ctx.lineWidth = currentElement.strokeWidth;
      ctx.lineCap = 'round';
      ctx.lineJoin = 'round';

      if (currentElement.isHighlighter) {
        ctx.globalAlpha = 0.35;
      }

      if (currentElement.type === 'eraser' && currentElement.points) {
        ctx.strokeStyle = '#ffffff';
        ctx.lineWidth = currentElement.strokeWidth * 3;
        ctx.beginPath();
        ctx.moveTo(currentElement.points[0].x, currentElement.points[0].y);
        for (let i = 1; i < currentElement.points.length; i++) {
          ctx.lineTo(currentElement.points[i].x, currentElement.points[i].y);
        }
        ctx.stroke();
      } else if (
        (currentElement.type === 'pen' || currentElement.type === 'highlighter') &&
        currentElement.points &&
        currentElement.points.length > 0
      ) {
        ctx.beginPath();
        ctx.moveTo(currentElement.points[0].x, currentElement.points[0].y);
        for (let i = 1; i < currentElement.points.length; i++) {
          ctx.lineTo(currentElement.points[i].x, currentElement.points[i].y);
        }
        ctx.stroke();
      } else if (
        currentElement.type === 'rectangle' &&
        currentElement.startX !== undefined &&
        currentElement.startY !== undefined &&
        currentElement.endX !== undefined &&
        currentElement.endY !== undefined
      ) {
        ctx.strokeRect(
          Math.min(currentElement.startX, currentElement.endX),
          Math.min(currentElement.startY, currentElement.endY),
          Math.abs(currentElement.endX - currentElement.startX),
          Math.abs(currentElement.endY - currentElement.startY)
        );
      } else if (
        currentElement.type === 'circle' &&
        currentElement.startX !== undefined &&
        currentElement.startY !== undefined &&
        currentElement.endX !== undefined &&
        currentElement.endY !== undefined
      ) {
        const radiusX = Math.abs(currentElement.endX - currentElement.startX) / 2;
        const radiusY = Math.abs(currentElement.endY - currentElement.startY) / 2;
        const centerX = Math.min(currentElement.startX, currentElement.endX) + radiusX;
        const centerY = Math.min(currentElement.startY, currentElement.endY) + radiusY;
        ctx.beginPath();
        ctx.ellipse(centerX, centerY, radiusX, radiusY, 0, 0, Math.PI * 2);
        ctx.stroke();
      } else if (
        currentElement.type === 'line' &&
        currentElement.startX !== undefined &&
        currentElement.startY !== undefined &&
        currentElement.endX !== undefined &&
        currentElement.endY !== undefined
      ) {
        ctx.beginPath();
        ctx.moveTo(currentElement.startX, currentElement.startY);
        ctx.lineTo(currentElement.endX, currentElement.endY);
        ctx.stroke();
      } else if (
        currentElement.type === 'arrow' &&
        currentElement.startX !== undefined &&
        currentElement.startY !== undefined &&
        currentElement.endX !== undefined &&
        currentElement.endY !== undefined
      ) {
        ctx.beginPath();
        ctx.moveTo(currentElement.startX, currentElement.startY);
        ctx.lineTo(currentElement.endX, currentElement.endY);
        ctx.stroke();
      }

      ctx.restore();
    }

    // Laser pointer dot (Teacher only or synced)
    if (laserPos) {
      ctx.save();
      ctx.fillStyle = '#ef4444';
      ctx.shadowColor = '#ef4444';
      ctx.shadowBlur = 10;
      ctx.beginPath();
      ctx.arc(laserPos.x, laserPos.y, 6, 0, Math.PI * 2);
      ctx.fill();
      ctx.restore();
    }
  }, [pages, currentPage, pan, zoom, currentElement, laserPos]);

  // Handle Resize
  useEffect(() => {
    const handleResize = () => {
      if (containerRef.current && canvasRef.current) {
        const rect = containerRef.current.getBoundingClientRect();
        canvasRef.current.width = rect.width;
        canvasRef.current.height = rect.height;
        redraw();
      }
    };
    handleResize();
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, [redraw]);

  // Redraw when elements or pages change
  useEffect(() => {
    redraw();
  }, [redraw]);

  // Handle remote stroke incoming from socket
  useEffect(() => {
    if (remoteStroke) {
      setPages((prev) => {
        const updated = [...prev];
        if (!updated[currentPage]) updated[currentPage] = [];
        updated[currentPage] = [...updated[currentPage], remoteStroke];
        return updated;
      });
    }
  }, [remoteStroke, currentPage]);

  // Handle remote clear
  useEffect(() => {
    if (remoteClear) {
      setPages((prev) => {
        const updated = [...prev];
        updated[currentPage] = [];
        return updated;
      });
    }
  }, [remoteClear, currentPage]);

  // Coordinate helper mapping screen to canvas space
  const getCanvasPoint = (e: React.MouseEvent<HTMLCanvasElement>): Point => {
    const canvas = canvasRef.current;
    if (!canvas) return { x: 0, y: 0 };
    const rect = canvas.getBoundingClientRect();
    const screenX = e.clientX - rect.left;
    const screenY = e.clientY - rect.top;

    return {
      x: (screenX - pan.x) / zoom,
      y: (screenY - pan.y) / zoom,
    };
  };

  // Mouse Handlers
  const handleMouseDown = (e: React.MouseEvent<HTMLCanvasElement>) => {
    if (!isTeacher && activeTool !== 'laser') return; // Read-only for students unless authorized
    const pt = getCanvasPoint(e);

    if (activeTool === 'laser') {
      setLaserPos(pt);
      return;
    }

    if (activeTool === 'text' || activeTool === 'note') {
      setNoteClickPos(pt);
      setTextModalOpen(true);
      return;
    }

    setIsDrawing(true);
    const newEl: BoardElement = {
      id: `el-${Date.now()}`,
      type: activeTool,
      color: activeTool === 'highlighter' ? '#fde047' : color,
      strokeWidth: activeTool === 'highlighter' ? strokeWidth * 4 : strokeWidth,
      isHighlighter: activeTool === 'highlighter',
      startX: pt.x,
      startY: pt.y,
      endX: pt.x,
      endY: pt.y,
      points: [pt],
    };
    setCurrentElement(newEl);
  };

  const handleMouseMove = (e: React.MouseEvent<HTMLCanvasElement>) => {
    const pt = getCanvasPoint(e);

    if (activeTool === 'laser') {
      setLaserPos(pt);
      redraw();
      return;
    }

    if (!isDrawing || !currentElement) return;

    if (currentElement.type === 'pen' || currentElement.type === 'highlighter' || currentElement.type === 'eraser') {
      setCurrentElement((prev) => {
        if (!prev || !prev.points) return prev;
        return {
          ...prev,
          points: [...prev.points, pt],
        };
      });
    } else {
      // Shapes
      setCurrentElement((prev) => {
        if (!prev) return prev;
        return {
          ...prev,
          endX: pt.x,
          endY: pt.y,
        };
      });
    }
  };

  const handleMouseUp = () => {
    if (activeTool === 'laser') {
      setLaserPos(null);
      redraw();
      return;
    }

    if (!isDrawing || !currentElement) return;
    setIsDrawing(false);

    // Commit element to page
    const updatedPage = [...(pages[currentPage] || []), currentElement];
    setPages((prev) => {
      const next = [...prev];
      next[currentPage] = updatedPage;
      return next;
    });

    // Save Undo History
    const curHistory = history[currentPage] || [];
    const curIndex = historyIndex[currentPage] || 0;
    const newHist = [...curHistory.slice(0, curIndex + 1), updatedPage];
    setHistory((prev) => {
      const next = [...prev];
      next[currentPage] = newHist;
      return next;
    });
    setHistoryIndex((prev) => {
      const next = [...prev];
      next[currentPage] = newHist.length - 1;
      return next;
    });

    // Broadcast to students/peers
    if (onStrokeBroadcast) {
      onStrokeBroadcast(currentElement);
    }

    setCurrentElement(null);
  };

  // Add text or sticky note
  const submitTextNote = () => {
    if (!noteContent.trim()) {
      setTextModalOpen(false);
      return;
    }

    const newEl: BoardElement = {
      id: `el-${Date.now()}`,
      type: activeTool === 'note' ? 'note' : 'text',
      color: activeTool === 'note' ? '#78350f' : color,
      strokeWidth: 1,
      startX: noteClickPos.x,
      startY: noteClickPos.y,
      text: noteContent,
    };

    const updatedPage = [...(pages[currentPage] || []), newEl];
    setPages((prev) => {
      const next = [...prev];
      next[currentPage] = updatedPage;
      return next;
    });

    if (onStrokeBroadcast) {
      onStrokeBroadcast(newEl);
    }

    setNoteContent('');
    setTextModalOpen(false);
  };

  // Undo / Redo
  const handleUndo = () => {
    const curIndex = historyIndex[currentPage] || 0;
    const curHist = history[currentPage] || [];
    if (curIndex > 0) {
      const newIndex = curIndex - 1;
      setHistoryIndex((prev) => {
        const next = [...prev];
        next[currentPage] = newIndex;
        return next;
      });
      setPages((prev) => {
        const next = [...prev];
        next[currentPage] = curHist[newIndex];
        return next;
      });
    }
  };

  const handleRedo = () => {
    const curIndex = historyIndex[currentPage] || 0;
    const curHist = history[currentPage] || [];
    if (curIndex < curHist.length - 1) {
      const newIndex = curIndex + 1;
      setHistoryIndex((prev) => {
        const next = [...prev];
        next[currentPage] = newIndex;
        return next;
      });
      setPages((prev) => {
        const next = [...prev];
        next[currentPage] = curHist[newIndex];
        return next;
      });
    }
  };

  // Clear Canvas
  const handleClear = () => {
    if (confirm('Clear current board page?')) {
      setPages((prev) => {
        const next = [...prev];
        next[currentPage] = [];
        return next;
      });
      if (onClearBroadcast) {
        onClearBroadcast();
      }
    }
  };

  // Export board as PNG
  const handleExportPNG = () => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const url = canvas.toDataURL('image/png');
    const a = document.createElement('a');
    a.href = url;
    a.download = `Classora-Board-Page-${currentPage + 1}.png`;
    a.click();
  };

  // Pagination
  const addNewPage = () => {
    setPages((prev) => [...prev, []]);
    setHistory((prev) => [...prev, [[]]]);
    setHistoryIndex((prev) => [...prev, 0]);
    setCurrentPage(pages.length);
  };

  return (
    <div className="relative w-full h-full flex flex-col bg-slate-100 select-none overflow-hidden font-sans">
      {/* Top Bar: Page navigation, grid pattern, zoom, undo/redo, export */}
      <div className="h-12 bg-white border-b border-slate-200 px-4 flex items-center justify-between shadow-subtle z-20">
        <div className="flex items-center space-x-3">
          <div className="flex items-center bg-slate-100 rounded-lg p-0.5 border border-slate-200">
            <button
              onClick={() => setCurrentPage((p) => Math.max(0, p - 1))}
              disabled={currentPage === 0}
              className="p-1 hover:bg-white rounded text-slate-700 disabled:opacity-30 transition-colors"
              title="Previous Page"
            >
              <ChevronLeft className="w-4 h-4" />
            </button>
            <span className="px-2 text-xs font-semibold text-slate-700">
              Page {currentPage + 1} of {pages.length}
            </span>
            <button
              onClick={() => setCurrentPage((p) => Math.min(pages.length - 1, p + 1))}
              disabled={currentPage === pages.length - 1}
              className="p-1 hover:bg-white rounded text-slate-700 disabled:opacity-30 transition-colors"
              title="Next Page"
            >
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>

          {isTeacher && (
            <button
              onClick={addNewPage}
              className="flex items-center space-x-1 px-2.5 py-1 text-xs font-medium text-indigo-600 bg-indigo-50 hover:bg-indigo-100 rounded-md border border-indigo-200 transition-colors"
            >
              <Plus className="w-3.5 h-3.5" />
              <span>New Page</span>
            </button>
          )}

          <div className="h-4 w-px bg-slate-200" />

          {/* Background Pattern Picker */}
          <div className="flex items-center space-x-1 bg-slate-100 p-0.5 rounded-lg border border-slate-200">
            {(['blank', 'grid', 'dots', 'ruled'] as BackgroundStyle[]).map((bg) => (
              <button
                key={bg}
                onClick={() => setBackgroundStyle(bg)}
                className={`px-2 py-0.5 text-xs font-medium capitalize rounded transition-colors ${
                  backgroundStyle === bg ? 'bg-white text-indigo-600 shadow-sm' : 'text-slate-600 hover:text-slate-900'
                }`}
              >
                {bg}
              </button>
            ))}
          </div>
        </div>

        {/* Center: Brand Indicator */}
        <div className="hidden md:flex items-center space-x-2 text-xs text-slate-500 font-medium">
          <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
          <span>Classora Interactive Whiteboard</span>
        </div>

        {/* Right Actions: Undo/Redo, Zoom, Export */}
        <div className="flex items-center space-x-2">
          {isTeacher && (
            <div className="flex items-center space-x-1 border-r border-slate-200 pr-2">
              <button
                onClick={handleUndo}
                className="p-1.5 text-slate-600 hover:bg-slate-100 rounded-md transition-colors"
                title="Undo (Ctrl+Z)"
              >
                <RotateCcw className="w-4 h-4" />
              </button>
              <button
                onClick={handleRedo}
                className="p-1.5 text-slate-600 hover:bg-slate-100 rounded-md transition-colors"
                title="Redo (Ctrl+Y)"
              >
                <RotateCw className="w-4 h-4" />
              </button>
              <button
                onClick={handleClear}
                className="p-1.5 text-rose-600 hover:bg-rose-50 rounded-md transition-colors"
                title="Clear Page"
              >
                <Trash2 className="w-4 h-4" />
              </button>
            </div>
          )}

          {/* Zoom Controls */}
          <div className="flex items-center bg-slate-100 rounded-lg p-0.5 border border-slate-200">
            <button
              onClick={() => setZoom((z) => Math.max(0.5, Number((z - 0.1).toFixed(1))))}
              className="p-1 text-slate-600 hover:bg-white rounded transition-colors"
              title="Zoom Out"
            >
              <ZoomOut className="w-3.5 h-3.5" />
            </button>
            <span className="px-1.5 text-xs font-semibold text-slate-700 w-12 text-center">
              {Math.round(zoom * 100)}%
            </span>
            <button
              onClick={() => setZoom((z) => Math.min(2.5, Number((z + 0.1).toFixed(1))))}
              className="p-1 text-slate-600 hover:bg-white rounded transition-colors"
              title="Zoom In"
            >
              <ZoomIn className="w-3.5 h-3.5" />
            </button>
          </div>

          <button
            onClick={handleExportPNG}
            className="flex items-center space-x-1 px-2.5 py-1 text-xs font-medium text-slate-700 bg-white hover:bg-slate-50 border border-slate-300 rounded-md shadow-sm transition-colors"
            title="Download PNG notes"
          >
            <Download className="w-3.5 h-3.5" />
            <span className="hidden sm:inline">Export</span>
          </button>
        </div>
      </div>

      {/* Main Canvas Area */}
      <div
        ref={containerRef}
        className={`relative flex-1 w-full h-full overflow-hidden bg-white cursor-crosshair ${
          backgroundStyle === 'grid'
            ? 'board-pattern-grid'
            : backgroundStyle === 'dots'
            ? 'board-pattern-dots'
            : backgroundStyle === 'ruled'
            ? 'board-pattern-ruled'
            : 'bg-white'
        }`}
      >
        <canvas
          ref={canvasRef}
          onMouseDown={handleMouseDown}
          onMouseMove={handleMouseMove}
          onMouseUp={handleMouseUp}
          onMouseLeave={handleMouseUp}
          className="absolute inset-0 w-full h-full"
        />

        {/* Floating Tooldock (Teacher Console) */}
        {isTeacher && (
          <div className="absolute left-4 top-1/2 -translate-y-1/2 bg-white/95 backdrop-blur-md border border-slate-200/80 rounded-2xl shadow-elevated p-2 flex flex-col space-y-2 z-30">
            {/* Main Drawing Tools */}
            <div className="flex flex-col space-y-1">
              <button
                onClick={() => setActiveTool('pen')}
                className={`p-2 rounded-xl transition-all ${
                  activeTool === 'pen'
                    ? 'bg-indigo-600 text-white shadow-sm ring-2 ring-indigo-200'
                    : 'text-slate-600 hover:bg-slate-100'
                }`}
                title="Pen Tool"
              >
                <Pen className="w-4 h-4" />
              </button>

              <button
                onClick={() => setActiveTool('highlighter')}
                className={`p-2 rounded-xl transition-all ${
                  activeTool === 'highlighter'
                    ? 'bg-amber-500 text-white shadow-sm ring-2 ring-amber-200'
                    : 'text-slate-600 hover:bg-slate-100'
                }`}
                title="Highlighter"
              >
                <Highlighter className="w-4 h-4" />
              </button>

              <button
                onClick={() => setActiveTool('eraser')}
                className={`p-2 rounded-xl transition-all ${
                  activeTool === 'eraser'
                    ? 'bg-rose-500 text-white shadow-sm ring-2 ring-rose-200'
                    : 'text-slate-600 hover:bg-slate-100'
                }`}
                title="Eraser"
              >
                <Eraser className="w-4 h-4" />
              </button>
            </div>

            <div className="h-px bg-slate-200 mx-1" />

            {/* Shape Tools */}
            <div className="flex flex-col space-y-1">
              <button
                onClick={() => setActiveTool('rectangle')}
                className={`p-2 rounded-xl transition-all ${
                  activeTool === 'rectangle' ? 'bg-indigo-600 text-white' : 'text-slate-600 hover:bg-slate-100'
                }`}
                title="Rectangle"
              >
                <Square className="w-4 h-4" />
              </button>
              <button
                onClick={() => setActiveTool('circle')}
                className={`p-2 rounded-xl transition-all ${
                  activeTool === 'circle' ? 'bg-indigo-600 text-white' : 'text-slate-600 hover:bg-slate-100'
                }`}
                title="Circle"
              >
                <Circle className="w-4 h-4" />
              </button>
              <button
                onClick={() => setActiveTool('arrow')}
                className={`p-2 rounded-xl transition-all ${
                  activeTool === 'arrow' ? 'bg-indigo-600 text-white' : 'text-slate-600 hover:bg-slate-100'
                }`}
                title="Arrow"
              >
                <ArrowRight className="w-4 h-4" />
              </button>
              <button
                onClick={() => setActiveTool('line')}
                className={`p-2 rounded-xl transition-all ${
                  activeTool === 'line' ? 'bg-indigo-600 text-white' : 'text-slate-600 hover:bg-slate-100'
                }`}
                title="Straight Line"
              >
                <Minus className="w-4 h-4" />
              </button>
            </div>

            <div className="h-px bg-slate-200 mx-1" />

            {/* Annotations */}
            <div className="flex flex-col space-y-1">
              <button
                onClick={() => setActiveTool('text')}
                className={`p-2 rounded-xl transition-all ${
                  activeTool === 'text' ? 'bg-indigo-600 text-white' : 'text-slate-600 hover:bg-slate-100'
                }`}
                title="Text Box"
              >
                <Type className="w-4 h-4" />
              </button>
              <button
                onClick={() => setActiveTool('note')}
                className={`p-2 rounded-xl transition-all ${
                  activeTool === 'note' ? 'bg-amber-400 text-amber-900' : 'text-slate-600 hover:bg-slate-100'
                }`}
                title="Sticky Note"
              >
                <StickyNote className="w-4 h-4" />
              </button>
              <button
                onClick={() => setActiveTool('laser')}
                className={`p-2 rounded-xl transition-all ${
                  activeTool === 'laser' ? 'bg-red-500 text-white animate-pulse' : 'text-slate-600 hover:bg-slate-100'
                }`}
                title="Laser Pointer"
              >
                <Compass className="w-4 h-4" />
              </button>
            </div>

            <div className="h-px bg-slate-200 mx-1" />

            {/* Color Palette Picker */}
            <div className="flex flex-col items-center space-y-1.5 py-1">
              {COLOR_PALETTE.slice(0, 4).map((c) => (
                <button
                  key={c.value}
                  onClick={() => setColor(c.value)}
                  style={{ backgroundColor: c.value }}
                  className={`w-5 h-5 rounded-full transition-transform ${
                    color === c.value ? 'scale-125 ring-2 ring-indigo-400 ring-offset-2' : 'hover:scale-110'
                  }`}
                  title={c.name}
                />
              ))}
            </div>

            {/* Stroke Thickness Picker */}
            <div className="pt-1 flex flex-col items-center space-y-1">
              {[2, 4, 8].map((w) => (
                <button
                  key={w}
                  onClick={() => setStrokeWidth(w)}
                  className={`w-6 h-6 flex items-center justify-center rounded-lg ${
                    strokeWidth === w ? 'bg-slate-200 text-indigo-700 font-bold' : 'text-slate-500 hover:bg-slate-100'
                  }`}
                >
                  <div
                    className="rounded-full bg-slate-700"
                    style={{ width: `${w + 2}px`, height: `${w + 2}px` }}
                  />
                </button>
              ))}
            </div>
          </div>
        )}

        {/* Text / Note Input Dialog */}
        {textModalOpen && (
          <div className="absolute inset-0 bg-black/20 backdrop-blur-xs flex items-center justify-center z-40">
            <div className="bg-white rounded-xl shadow-elevated border border-slate-200 p-5 w-80">
              <h4 className="text-sm font-semibold text-slate-800 mb-2">
                {activeTool === 'note' ? 'Add Sticky Note' : 'Add Text'}
              </h4>
              <textarea
                value={noteContent}
                onChange={(e) => setNoteContent(e.target.value)}
                placeholder="Type your notes or formulas here..."
                rows={3}
                autoFocus
                className="w-full text-sm p-2.5 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 mb-3 resize-none"
              />
              <div className="flex justify-end space-x-2">
                <button
                  onClick={() => setTextModalOpen(false)}
                  className="px-3 py-1.5 text-xs font-medium text-slate-600 hover:bg-slate-100 rounded-lg"
                >
                  Cancel
                </button>
                <button
                  onClick={submitTextNote}
                  className="px-3 py-1.5 text-xs font-medium text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg"
                >
                  Insert on Board
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
