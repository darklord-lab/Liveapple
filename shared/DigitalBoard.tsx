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
  Image as ImageIcon,
  FileText,
  ChevronLeft,
  ChevronRight,
  Plus,
  Compass,
  Sliders,
  Maximize2,
  Upload,
  X,
  MousePointer,
  Hand,
  Scissors,
  Move,
} from 'lucide-react';
import { renderPdfPages } from './pdfHelper';

export type ToolType =
  | 'select'
  | 'pen'
  | 'highlighter'
  | 'eraser'
  | 'rectangle'
  | 'circle'
  | 'line'
  | 'arrow'
  | 'text'
  | 'note'
  | 'laser'
  | 'image'
  | 'pan'
  | 'snip';

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
  imageDataUrl?: string;
  imageWidth?: number;
  imageHeight?: number;
}

export interface DigitalBoardProps {
  isTeacher?: boolean;
  roomId?: string;
  socket?: any;
  onStrokeBroadcast?: (element: BoardElement) => void;
  onClearBroadcast?: () => void;
}

const COLOR_PALETTE = [
  { name: 'Dark Slate', value: '#0f172a' },
  { name: 'Academic Indigo', value: '#4f46e5' },
  { name: 'Crimson Red', value: '#dc2626' },
  { name: 'Emerald Green', value: '#16a34a' },
  { name: 'Amber Gold', value: '#d97706' },
  { name: 'Deep Purple', value: '#9333ea' },
];

const PRESET_SIZES = [
  { label: 'Fine', size: 2 },
  { label: 'Normal', size: 4 },
  { label: 'Medium', size: 8 },
  { label: 'Bold', size: 16 },
  { label: 'Marker', size: 28 },
];

export const DigitalBoard: React.FC<DigitalBoardProps> = ({
  isTeacher = true,
  roomId,
  socket,
  onStrokeBroadcast,
  onClearBroadcast,
}) => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const containerRef = useRef<HTMLDivElement | null>(null);
  const fileInputRef = useRef<HTMLInputElement | null>(null);
  const docInputRef = useRef<HTMLInputElement | null>(null);

  // Loaded images cache
  const imageCacheRef = useRef<Map<string, HTMLImageElement>>(new Map());

  // Board Page State
  const [currentPage, setCurrentPage] = useState<number>(0);
  const [pages, setPages] = useState<BoardElement[][]>([[]]);
  const [history, setHistory] = useState<BoardElement[][][]>([[[]]]);
  const [historyIndex, setHistoryIndex] = useState<number[]>([0]);

  // Document background layers per page
  const [documentLayers, setDocumentLayers] = useState<Record<number, string>>({});
  const [docLoading, setDocLoading] = useState<boolean>(false);

  // Tool Configuration
  const [activeTool, setActiveTool] = useState<ToolType>('pen');
  const [color, setColor] = useState<string>('#0f172a');
  const [strokeWidth, setStrokeWidth] = useState<number>(4);
  const [backgroundStyle, setBackgroundStyle] = useState<BackgroundStyle>('grid');
  const [zoom, setZoom] = useState<number>(1);
  const [pan, setPan] = useState<Point>({ x: 0, y: 0 });

  // Floating Pen Settings Popover
  const [penSettingsOpen, setPenSettingsOpen] = useState<boolean>(false);

  // Interactive Drawing & Selection State
  const [isDrawing, setIsDrawing] = useState<boolean>(false);
  const [currentElement, setCurrentElement] = useState<BoardElement | null>(null);
  const [laserPos, setLaserPos] = useState<Point | null>(null);

  // Move & Resize Image Elements
  const [selectedElementId, setSelectedElementId] = useState<string | null>(null);
  const [isDraggingElement, setIsDraggingElement] = useState<boolean>(false);
  const [isResizingElement, setIsResizingElement] = useState<boolean>(false);
  const [dragOffset, setDragOffset] = useState<Point>({ x: 0, y: 0 });
  const [resizeHandle, setResizeHandle] = useState<string | null>(null);

  // Pan Canvas State
  const [isPanning, setIsPanning] = useState<boolean>(false);
  const [panStart, setPanStart] = useState<Point>({ x: 0, y: 0 });

  // PDF / Document Snip & Cut State
  const [snipStart, setSnipStart] = useState<Point | null>(null);
  const [snipCurrent, setSnipCurrent] = useState<Point | null>(null);

  // Text / Sticky Note Prompt Modal
  const [textModalOpen, setTextModalOpen] = useState(false);
  const [noteContent, setNoteContent] = useState('');
  const [noteClickPos, setNoteClickPos] = useState<Point>({ x: 100, y: 100 });

  // Helper to load or fetch cached image
  const getCachedImage = useCallback((url: string): HTMLImageElement => {
    let img = imageCacheRef.current.get(url);
    if (!img) {
      img = new Image();
      img.src = url;
      img.onload = () => redraw();
      imageCacheRef.current.set(url, img);
    }
    return img;
  }, []);

  // Redraw Canvas
  const redraw = useCallback(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    ctx.setTransform(1, 0, 0, 1, 0, 0);
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    ctx.translate(pan.x, pan.y);
    ctx.scale(zoom, zoom);

    // If active page has an underlying uploaded document / PDF slide background
    const docBgUrl = documentLayers[currentPage];
    if (docBgUrl) {
      const docImg = getCachedImage(docBgUrl);
      if (docImg.complete && docImg.naturalWidth > 0) {
        ctx.save();
        ctx.globalAlpha = 0.95;
        const maxW = canvas.width / zoom;
        const scale = Math.min(maxW / docImg.naturalWidth, 1.2);
        const w = docImg.naturalWidth * scale;
        const h = docImg.naturalHeight * scale;
        ctx.drawImage(docImg, 40, 40, w, h);
        // Border around document
        ctx.strokeStyle = '#cbd5e1';
        ctx.lineWidth = 1;
        ctx.strokeRect(40, 40, w, h);
        ctx.restore();
      }
    }

    const elementsToRender = pages[currentPage] || [];

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

      if (el.type === 'image' && el.imageDataUrl && el.startX !== undefined && el.startY !== undefined) {
        const img = getCachedImage(el.imageDataUrl);
        if (img.complete && img.naturalWidth > 0) {
          const w = el.imageWidth || img.naturalWidth;
          const h = el.imageHeight || img.naturalHeight;
          ctx.drawImage(img, el.startX, el.startY, w, h);
          ctx.strokeStyle = '#94a3b8';
          ctx.lineWidth = 1;
          ctx.strokeRect(el.startX, el.startY, w, h);
        }
      } else if (el.type === 'eraser' && el.points && el.points.length > 0) {
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

        const angle = Math.atan2(el.endY - el.startY, el.endX - el.startX);
        const headLen = 14 + el.strokeWidth;
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
        ctx.fillStyle = '#fef3c7';
        ctx.strokeStyle = '#f59e0b';
        ctx.lineWidth = 1.5;
        const width = 170;
        const height = 110;
        ctx.fillRect(el.startX, el.startY, width, height);
        ctx.strokeRect(el.startX, el.startY, width, height);

        ctx.fillStyle = '#78350f';
        ctx.font = '500 13px Inter, sans-serif';
        const words = el.text.split(' ');
        let line = '';
        let yOffset = el.startY + 22;
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

    // Preview Current Stroke
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
      } else if ((currentElement.type === 'pen' || currentElement.type === 'highlighter') && currentElement.points) {
        ctx.beginPath();
        ctx.moveTo(currentElement.points[0].x, currentElement.points[0].y);
        for (let i = 1; i < currentElement.points.length; i++) {
          ctx.lineTo(currentElement.points[i].x, currentElement.points[i].y);
        }
        ctx.stroke();
      } else if (currentElement.type === 'rectangle' && currentElement.startX !== undefined && currentElement.startY !== undefined && currentElement.endX !== undefined && currentElement.endY !== undefined) {
        ctx.strokeRect(
          Math.min(currentElement.startX, currentElement.endX),
          Math.min(currentElement.startY, currentElement.endY),
          Math.abs(currentElement.endX - currentElement.startX),
          Math.abs(currentElement.endY - currentElement.startY)
        );
      } else if (currentElement.type === 'circle' && currentElement.startX !== undefined && currentElement.startY !== undefined && currentElement.endX !== undefined && currentElement.endY !== undefined) {
        const radiusX = Math.abs(currentElement.endX - currentElement.startX) / 2;
        const radiusY = Math.abs(currentElement.endY - currentElement.startY) / 2;
        const centerX = Math.min(currentElement.startX, currentElement.endX) + radiusX;
        const centerY = Math.min(currentElement.startY, currentElement.endY) + radiusY;
        ctx.beginPath();
        ctx.ellipse(centerX, centerY, radiusX, radiusY, 0, 0, Math.PI * 2);
        ctx.stroke();
      } else if (currentElement.type === 'line' && currentElement.startX !== undefined && currentElement.startY !== undefined && currentElement.endX !== undefined && currentElement.endY !== undefined) {
        ctx.beginPath();
        ctx.moveTo(currentElement.startX, currentElement.startY);
        ctx.lineTo(currentElement.endX, currentElement.endY);
        ctx.stroke();
      } else if (currentElement.type === 'arrow' && currentElement.startX !== undefined && currentElement.startY !== undefined && currentElement.endX !== undefined && currentElement.endY !== undefined) {
        ctx.beginPath();
        ctx.moveTo(currentElement.startX, currentElement.startY);
        ctx.lineTo(currentElement.endX, currentElement.endY);
        ctx.stroke();
      }

      ctx.restore();
    }

    // Laser pointer
    if (laserPos) {
      ctx.save();
      ctx.fillStyle = '#ef4444';
      ctx.shadowColor = '#ef4444';
      ctx.shadowBlur = 12;
      ctx.beginPath();
      ctx.arc(laserPos.x, laserPos.y, 6, 0, Math.PI * 2);
      ctx.fill();
      ctx.restore();
    }

    // Render Selection Box & Resize Handles on active image
    if (selectedElementId && activeTool === 'select') {
      const sel = elementsToRender.find((el) => el.id === selectedElementId && el.type === 'image');
      if (sel && sel.startX !== undefined && sel.startY !== undefined) {
        const w = sel.imageWidth || 300;
        const h = sel.imageHeight || 200;
        ctx.save();
        ctx.strokeStyle = '#2563eb';
        ctx.lineWidth = 2 / zoom;
        ctx.setLineDash([5 / zoom, 3 / zoom]);
        ctx.strokeRect(sel.startX, sel.startY, w, h);
        ctx.setLineDash([]);

        // 4 corner handles
        const handleSize = 8 / zoom;
        const corners = [
          { x: sel.startX, y: sel.startY },
          { x: sel.startX + w, y: sel.startY },
          { x: sel.startX, y: sel.startY + h },
          { x: sel.startX + w, y: sel.startY + h },
        ];

        corners.forEach((c) => {
          ctx.fillStyle = '#ffffff';
          ctx.strokeStyle = '#2563eb';
          ctx.lineWidth = 2 / zoom;
          ctx.fillRect(c.x - handleSize / 2, c.y - handleSize / 2, handleSize, handleSize);
          ctx.strokeRect(c.x - handleSize / 2, c.y - handleSize / 2, handleSize, handleSize);
        });

        // Close / Delete badge icon on top right
        ctx.fillStyle = '#ef4444';
        ctx.beginPath();
        ctx.arc(sel.startX + w, sel.startY, 9 / zoom, 0, Math.PI * 2);
        ctx.fill();
        ctx.strokeStyle = '#ffffff';
        ctx.lineWidth = 1.8 / zoom;
        ctx.beginPath();
        const d = 4 / zoom;
        ctx.moveTo(sel.startX + w - d, sel.startY - d);
        ctx.lineTo(sel.startX + w + d, sel.startY + d);
        ctx.moveTo(sel.startX + w + d, sel.startY - d);
        ctx.lineTo(sel.startX + w - d, sel.startY + d);
        ctx.stroke();

        ctx.restore();
      }
    }

    // Render Snip Crop Box
    if (snipStart && snipCurrent && activeTool === 'snip') {
      ctx.save();
      const sx = Math.min(snipStart.x, snipCurrent.x);
      const sy = Math.min(snipStart.y, snipCurrent.y);
      const sw = Math.abs(snipCurrent.x - snipStart.x);
      const sh = Math.abs(snipCurrent.y - snipStart.y);
      ctx.strokeStyle = '#dc2626';
      ctx.lineWidth = 2 / zoom;
      ctx.setLineDash([6 / zoom, 4 / zoom]);
      ctx.strokeRect(sx, sy, sw, sh);
      ctx.fillStyle = 'rgba(239, 68, 68, 0.12)';
      ctx.fillRect(sx, sy, sw, sh);
      ctx.restore();
    }
  }, [pages, currentPage, pan, zoom, currentElement, laserPos, documentLayers, getCachedImage, selectedElementId, snipStart, snipCurrent, activeTool]);

  // Window Resize
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

  useEffect(() => {
    redraw();
  }, [redraw]);

  // Mouse Wheel Zoom
  useEffect(() => {
    const el = containerRef.current;
    if (!el) return;
    const handleWheel = (e: WheelEvent) => {
      if (e.ctrlKey || activeTool === 'pan') {
        e.preventDefault();
        const delta = e.deltaY < 0 ? 0.1 : -0.1;
        setZoom((z) => Math.min(3, Math.max(0.4, Number((z + delta).toFixed(1)))));
      }
    };
    el.addEventListener('wheel', handleWheel, { passive: false });
    return () => el.removeEventListener('wheel', handleWheel);
  }, [activeTool]);

  // Real-time synchronization over Socket.IO
  useEffect(() => {
    if (!socket) return;

    const handleStroke = (stroke: BoardElement) => {
      setPages((prev) => {
        const next = [...prev];
        next[currentPage] = [...(next[currentPage] || []), stroke];
        return next;
      });
    };

    const handlePageUpdated = ({ pageIndex, elements }: { pageIndex: number; elements: BoardElement[] }) => {
      setPages((prev) => {
        const next = [...prev];
        next[pageIndex] = elements;
        return next;
      });
    };

    const handleBoardCleared = ({ pageIndex }: { pageIndex: number }) => {
      setPages((prev) => {
        const next = [...prev];
        next[pageIndex] = [];
        return next;
      });
    };

    const handleBoardInit = ({ pages: initialPages }: { pages: BoardElement[][] }) => {
      if (initialPages && initialPages.length > 0) {
        setPages(initialPages);
      }
    };

    const handleLaser = ({ x, y, active }: { x: number; y: number; active: boolean }) => {
      if (active) {
        setLaserPos({ x, y });
      } else {
        setLaserPos(null);
      }
    };

    const handleDocUpdated = ({ pageIndex, docUrl }: { pageIndex: number; docUrl?: string }) => {
      setDocumentLayers((prev) => {
        const next = { ...prev };
        if (docUrl) {
          next[pageIndex] = docUrl;
        } else {
          delete next[pageIndex];
        }
        return next;
      });
      redraw();
    };

    socket.on('board-stroke-received', handleStroke);
    socket.on('board-page-updated', handlePageUpdated);
    socket.on('board-cleared', handleBoardCleared);
    socket.on('board-init', handleBoardInit);
    socket.on('laser-pointer-moved', handleLaser);
    socket.on('board-doc-updated', handleDocUpdated);

    return () => {
      socket.off('board-stroke-received', handleStroke);
      socket.off('board-page-updated', handlePageUpdated);
      socket.off('board-cleared', handleBoardCleared);
      socket.off('board-init', handleBoardInit);
      socket.off('laser-pointer-moved', handleLaser);
      socket.off('board-doc-updated', handleDocUpdated);
    };
  }, [socket, currentPage, redraw]);

  // Coordinate helper
  const getCanvasPoint = (e: React.MouseEvent<HTMLCanvasElement>): Point => {
    const canvas = canvasRef.current;
    if (!canvas) return { x: 0, y: 0 };
    const rect = canvas.getBoundingClientRect();
    return {
      x: (e.clientX - rect.left - pan.x) / zoom,
      y: (e.clientY - rect.top - pan.y) / zoom,
    };
  };

  // PDF / Canvas Snipping Crop Handler
  const completeSnipCrop = (start: Point, end: Point) => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const sx = Math.min(start.x, end.x);
    const sy = Math.min(start.y, end.y);
    const sw = Math.abs(end.x - start.x);
    const sh = Math.abs(end.y - start.y);

    if (sw < 20 || sh < 20) {
      setSnipStart(null);
      setSnipCurrent(null);
      redraw();
      return;
    }

    // Convert canvas internal coordinates to screen pixel viewport coordinates
    const screenX = Math.max(0, sx * zoom + pan.x);
    const screenY = Math.max(0, sy * zoom + pan.y);
    const screenW = Math.min(canvas.width - screenX, sw * zoom);
    const screenH = Math.min(canvas.height - screenY, sh * zoom);

    if (screenW <= 10 || screenH <= 10) {
      setSnipStart(null);
      setSnipCurrent(null);
      redraw();
      return;
    }

    const offCanvas = document.createElement('canvas');
    offCanvas.width = screenW;
    offCanvas.height = screenH;
    const offCtx = offCanvas.getContext('2d');
    if (!offCtx) {
      setSnipStart(null);
      setSnipCurrent(null);
      return;
    }

    // Capture the cropped portion directly from the rendered whiteboard canvas
    offCtx.drawImage(
      canvas,
      screenX,
      screenY,
      screenW,
      screenH,
      0,
      0,
      screenW,
      screenH
    );

    const croppedDataUrl = offCanvas.toDataURL('image/png');

    // Create a new draggable and resizable snippet element placed on the board
    const newEl: BoardElement = {
      id: `snip-${Date.now()}`,
      type: 'image',
      color: '#000000',
      strokeWidth: 1,
      startX: sx + 20,
      startY: sy + 20,
      imageDataUrl: croppedDataUrl,
      imageWidth: sw,
      imageHeight: sh,
    };

    const updatedPage = [...(pages[currentPage] || []), newEl];
    setPages((prev) => {
      const next = [...prev];
      next[currentPage] = updatedPage;
      return next;
    });

    // History tracking
    setHistory((prev) => {
      const next = [...prev];
      const curHist = (next[currentPage] || []).slice(0, (historyIndex[currentPage] ?? 0) + 1);
      next[currentPage] = [...curHist, updatedPage];
      return next;
    });
    setHistoryIndex((prev) => {
      const next = [...prev];
      next[currentPage] = (next[currentPage] ?? 0) + 1;
      return next;
    });

    if (socket && roomId) {
      socket.emit('board-draw-stroke', { roomId, stroke: newEl });
      socket.emit('board-sync-page', { roomId, pageIndex: currentPage, elements: updatedPage });
    }

    // Automatically select the new snippet and switch to select/move tool
    setSnipStart(null);
    setSnipCurrent(null);
    setSelectedElementId(newEl.id);
    setActiveTool('select');
    redraw();
  };

  // Mouse Handlers
  const handleMouseDown = (e: React.MouseEvent<HTMLCanvasElement>) => {
    if (!isTeacher && activeTool !== 'laser') return;
    const pt = getCanvasPoint(e);

    if (activeTool === 'pan') {
      setIsPanning(true);
      setPanStart({ x: e.clientX - pan.x, y: e.clientY - pan.y });
      return;
    }

    if (activeTool === 'snip') {
      setSnipStart(pt);
      setSnipCurrent(pt);
      return;
    }

    if (activeTool === 'select') {
      const curPageElements = pages[currentPage] || [];
      const handleSize = 14 / zoom;

      // 1. If an element is already selected, check if clicked on its delete icon or corner handles
      if (selectedElementId) {
        const selEl = curPageElements.find((el) => el.id === selectedElementId && el.type === 'image');
        if (selEl && selEl.startX !== undefined && selEl.startY !== undefined) {
          const w = selEl.imageWidth || 300;
          const h = selEl.imageHeight || 200;

          // Check delete button (top right circle)
          const delX = selEl.startX + w;
          const delY = selEl.startY;
          if (Math.hypot(pt.x - delX, pt.y - delY) < 18 / zoom) {
            const updated = curPageElements.filter((el) => el.id !== selEl.id);
            setPages((prev) => {
              const next = [...prev];
              next[currentPage] = updated;
              return next;
            });
            setSelectedElementId(null);
            if (socket && roomId) {
              socket.emit('board-sync-page', { roomId, pageIndex: currentPage, elements: updated });
            }
            redraw();
            return;
          }

          // Check bottom-right handle
          if (Math.abs(pt.x - (selEl.startX + w)) < handleSize && Math.abs(pt.y - (selEl.startY + h)) < handleSize) {
            setIsResizingElement(true);
            setResizeHandle('se');
            return;
          }
          // Check bottom-left handle
          if (Math.abs(pt.x - selEl.startX) < handleSize && Math.abs(pt.y - (selEl.startY + h)) < handleSize) {
            setIsResizingElement(true);
            setResizeHandle('sw');
            return;
          }
          // Check top-right handle
          if (Math.abs(pt.x - (selEl.startX + w)) < handleSize && Math.abs(pt.y - selEl.startY) < handleSize) {
            setIsResizingElement(true);
            setResizeHandle('ne');
            return;
          }
          // Check top-left handle
          if (Math.abs(pt.x - selEl.startX) < handleSize && Math.abs(pt.y - selEl.startY) < handleSize) {
            setIsResizingElement(true);
            setResizeHandle('nw');
            return;
          }
        }
      }

      // 2. Hit-test against images on the current page (reverse order: top-most first)
      let foundId: string | null = null;
      for (let i = curPageElements.length - 1; i >= 0; i--) {
        const el = curPageElements[i];
        if (el.type === 'image' && el.startX !== undefined && el.startY !== undefined) {
          const w = el.imageWidth || 300;
          const h = el.imageHeight || 200;
          if (pt.x >= el.startX && pt.x <= el.startX + w && pt.y >= el.startY && pt.y <= el.startY + h) {
            foundId = el.id;
            setDragOffset({ x: pt.x - el.startX, y: pt.y - el.startY });
            setIsDraggingElement(true);
            break;
          }
        }
      }

      setSelectedElementId(foundId);
      redraw();
      return;
    }

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
      strokeWidth: activeTool === 'highlighter' ? Math.max(strokeWidth * 3, 14) : strokeWidth,
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

    if (activeTool === 'pan' && isPanning) {
      setPan({
        x: e.clientX - panStart.x,
        y: e.clientY - panStart.y,
      });
      redraw();
      return;
    }

    if (activeTool === 'snip' && snipStart) {
      setSnipCurrent(pt);
      redraw();
      return;
    }

    if (activeTool === 'select') {
      if (isDraggingElement && selectedElementId) {
        setPages((prev) => {
          const cur = prev[currentPage] || [];
          const next = cur.map((el) => {
            if (el.id === selectedElementId && el.type === 'image') {
              return {
                ...el,
                startX: Math.round(pt.x - dragOffset.x),
                startY: Math.round(pt.y - dragOffset.y),
              };
            }
            return el;
          });
          const res = [...prev];
          res[currentPage] = next;
          return res;
        });
        redraw();
        return;
      }

      if (isResizingElement && selectedElementId && resizeHandle) {
        setPages((prev) => {
          const cur = prev[currentPage] || [];
          const next = cur.map((el) => {
            if (el.id === selectedElementId && el.type === 'image' && el.startX !== undefined && el.startY !== undefined) {
              let newW = el.imageWidth || 300;
              let newH = el.imageHeight || 200;
              let newX = el.startX;
              let newY = el.startY;

              if (resizeHandle === 'se') {
                newW = Math.max(50, pt.x - el.startX);
                newH = Math.max(40, pt.y - el.startY);
              } else if (resizeHandle === 'sw') {
                const right = el.startX + (el.imageWidth || 300);
                newW = Math.max(50, right - pt.x);
                newX = right - newW;
                newH = Math.max(40, pt.y - el.startY);
              } else if (resizeHandle === 'ne') {
                const bottom = el.startY + (el.imageHeight || 200);
                newW = Math.max(50, pt.x - el.startX);
                newH = Math.max(40, bottom - pt.y);
                newY = bottom - newH;
              } else if (resizeHandle === 'nw') {
                const right = el.startX + (el.imageWidth || 300);
                const bottom = el.startY + (el.imageHeight || 200);
                newW = Math.max(50, right - pt.x);
                newH = Math.max(40, bottom - pt.y);
                newX = right - newW;
                newY = bottom - newH;
              }

              return {
                ...el,
                startX: Math.round(newX),
                startY: Math.round(newY),
                imageWidth: Math.round(newW),
                imageHeight: Math.round(newH),
              };
            }
            return el;
          });
          const res = [...prev];
          res[currentPage] = next;
          return res;
        });
        redraw();
        return;
      }
      return;
    }

    if (activeTool === 'laser') {
      setLaserPos(pt);
      redraw();
      if (socket && roomId) {
        socket.emit('laser-pointer', { roomId, x: pt.x, y: pt.y, active: true });
      }
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
    if (activeTool === 'pan') {
      setIsPanning(false);
      return;
    }

    if (activeTool === 'snip' && snipStart && snipCurrent) {
      completeSnipCrop(snipStart, snipCurrent);
      return;
    }

    if (activeTool === 'select') {
      if (isDraggingElement || isResizingElement) {
        setIsDraggingElement(false);
        setIsResizingElement(false);
        setResizeHandle(null);

        // Update history and sync over socket
        const updatedPage = pages[currentPage] || [];
        setHistory((prev) => {
          const next = [...prev];
          const curHist = (next[currentPage] || []).slice(0, (historyIndex[currentPage] ?? 0) + 1);
          next[currentPage] = [...curHist, updatedPage];
          return next;
        });
        setHistoryIndex((prev) => {
          const next = [...prev];
          next[currentPage] = (next[currentPage] ?? 0) + 1;
          return next;
        });

        if (socket && roomId) {
          socket.emit('board-sync-page', { roomId, pageIndex: currentPage, elements: updatedPage });
        }
        redraw();
      }
      return;
    }

    if (activeTool === 'laser') {
      setLaserPos(null);
      redraw();
      if (socket && roomId) {
        socket.emit('laser-pointer', { roomId, x: 0, y: 0, active: false });
      }
      return;
    }

    if (!isDrawing || !currentElement) return;
    setIsDrawing(false);

    const updatedPage = [...(pages[currentPage] || []), currentElement];
    setPages((prev) => {
      const next = [...prev];
      next[currentPage] = updatedPage;
      return next;
    });

    // History tracking
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

    if (onStrokeBroadcast) onStrokeBroadcast(currentElement);
    if (socket && roomId) {
      socket.emit('board-draw-stroke', { roomId, stroke: currentElement });
      socket.emit('board-sync-page', { roomId, pageIndex: currentPage, elements: updatedPage });
    }
    setCurrentElement(null);
  };

  // Image Upload Handler
  const handleImageUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = (event) => {
      const url = event.target?.result as string;
      const img = new Image();
      img.src = url;
      img.onload = () => {
        const aspect = img.naturalWidth / img.naturalHeight;
        const targetWidth = Math.min(380, img.naturalWidth);
        const targetHeight = targetWidth / aspect;

        const newEl: BoardElement = {
          id: `img-${Date.now()}`,
          type: 'image',
          color: '#000000',
          strokeWidth: 1,
          startX: 80,
          startY: 80,
          imageDataUrl: url,
          imageWidth: targetWidth,
          imageHeight: targetHeight,
        };

        const updatedPage = [...(pages[currentPage] || []), newEl];
        setPages((prev) => {
          const next = [...prev];
          next[currentPage] = updatedPage;
          return next;
        });

        // Add to history
        setHistory((prev) => {
          const next = [...prev];
          const curHist = (next[currentPage] || []).slice(0, (historyIndex[currentPage] ?? 0) + 1);
          next[currentPage] = [...curHist, updatedPage];
          return next;
        });
        setHistoryIndex((prev) => {
          const next = [...prev];
          next[currentPage] = (next[currentPage] ?? 0) + 1;
          return next;
        });

        if (socket && roomId) {
          socket.emit('board-draw-stroke', { roomId, stroke: newEl });
          socket.emit('board-sync-page', { roomId, pageIndex: currentPage, elements: updatedPage });
        }
        redraw();
      };
    };
    reader.readAsDataURL(file);
    e.target.value = '';
  };

  // Document / PDF Page Upload Handler
  const handleDocumentUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    if (file.type === 'application/pdf' || file.name.toLowerCase().endsWith('.pdf')) {
      setDocLoading(true);
      try {
        const renderedPages = await renderPdfPages(file);
        if (renderedPages.length > 0) {
          setDocumentLayers((prev) => {
            const next = { ...prev };
            next[currentPage] = renderedPages[0];
            for (let i = 1; i < renderedPages.length; i++) {
              next[currentPage + i] = renderedPages[i];
            }
            return next;
          });

          if (renderedPages.length > 1) {
            setPages((prev) => {
              const next = [...prev];
              for (let i = 1; i < renderedPages.length; i++) {
                if (!next[currentPage + i]) next.push([]);
              }
              return next;
            });
          }

          if (socket && roomId) {
            socket.emit('board-doc-sync', { roomId, pageIndex: currentPage, docUrl: renderedPages[0] });
            for (let i = 1; i < renderedPages.length; i++) {
              socket.emit('board-doc-sync', { roomId, pageIndex: currentPage + i, docUrl: renderedPages[i] });
            }
          }
          redraw();
        }
      } catch (err) {
        console.error('Failed to parse PDF:', err);
        alert('Could not render PDF. Please ensure file is a valid PDF document.');
      } finally {
        setDocLoading(false);
      }
    } else {
      const reader = new FileReader();
      reader.onload = (event) => {
        const url = event.target?.result as string;
        setDocumentLayers((prev) => ({ ...prev, [currentPage]: url }));
        if (socket && roomId) {
          socket.emit('board-doc-sync', { roomId, pageIndex: currentPage, docUrl: url });
        }
        redraw();
      };
      reader.readAsDataURL(file);
    }
    e.target.value = '';
  };

  // Remove Document Layer from current page
  const handleRemoveDocument = () => {
    setDocumentLayers((prev) => {
      const next = { ...prev };
      delete next[currentPage];
      return next;
    });
    if (socket && roomId) {
      socket.emit('board-doc-sync', { roomId, pageIndex: currentPage, docUrl: null });
    }
    redraw();
  };

  // Remove Latest Image from current page
  const handleRemoveLatestImage = () => {
    const curElements = pages[currentPage] || [];
    const lastImageIndex = curElements.map((el) => el.type).lastIndexOf('image');
    if (lastImageIndex !== -1) {
      const updated = curElements.filter((_, idx) => idx !== lastImageIndex);
      setPages((prev) => {
        const next = [...prev];
        next[currentPage] = updated;
        return next;
      });
      if (socket && roomId) {
        socket.emit('board-sync-page', { roomId, pageIndex: currentPage, elements: updated });
      }
      redraw();
    }
  };

  // Submit Text / Note
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

  // Clear
  const handleClear = () => {
    if (confirm('Clear all strokes and images on this board page?')) {
      setPages((prev) => {
        const next = [...prev];
        next[currentPage] = [];
        return next;
      });
      setDocumentLayers((prev) => {
        const next = { ...prev };
        delete next[currentPage];
        return next;
      });
      if (onClearBroadcast) onClearBroadcast();
      if (socket && roomId) {
        socket.emit('board-clear', { roomId, pageIndex: currentPage });
      }
    }
  };

  // Export
  const handleExportPNG = () => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const url = canvas.toDataURL('image/png');
    const a = document.createElement('a');
    a.href = url;
    a.download = `Classora-Blackboard-Page-${currentPage + 1}.png`;
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
      {/* Hidden File Inputs */}
      <input
        ref={fileInputRef}
        type="file"
        accept="image/*"
        onChange={handleImageUpload}
        className="hidden"
      />
      <input
        ref={docInputRef}
        type="file"
        accept="image/*,.pdf,application/pdf"
        onChange={handleDocumentUpload}
        className="hidden"
      />

      {/* Top Bar: Pagination, Grid, Media insertion, Zoom, Undo/Redo, Export */}
      <div className="h-12 bg-white border-b border-slate-200 px-3 sm:px-4 flex items-center justify-between shadow-subtle z-20">
        <div className="flex items-center space-x-2 sm:space-x-3">
          {/* Pagination */}
          <div className="flex items-center bg-slate-100 rounded-lg p-0.5 border border-slate-200">
            <button
              onClick={() => setCurrentPage((p) => Math.max(0, p - 1))}
              disabled={currentPage === 0}
              className="p-1 hover:bg-white rounded text-slate-700 disabled:opacity-30 transition-colors"
              title="Previous Page"
            >
              <ChevronLeft className="w-4 h-4" />
            </button>
            <span className="px-2 text-xs font-semibold text-slate-700 whitespace-nowrap">
              Page {currentPage + 1} / {pages.length}
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
              <span className="hidden md:inline">New Page</span>
            </button>
          )}

          <div className="h-4 w-px bg-slate-200 hidden sm:block" />

          {/* Insert Photo & Document Buttons */}
          {isTeacher && (
            <div className="flex items-center space-x-1.5">
              <button
                onClick={() => fileInputRef.current?.click()}
                className="flex items-center space-x-1 px-2.5 py-1 text-xs font-semibold text-slate-700 bg-white hover:bg-slate-50 border border-slate-300 rounded-md shadow-xs transition-colors"
                title="Insert Photo / Diagram on Board"
              >
                <ImageIcon className="w-3.5 h-3.5 text-indigo-600" />
                <span className="hidden lg:inline">Add Photo</span>
              </button>

              <button
                onClick={() => docInputRef.current?.click()}
                disabled={docLoading}
                className="flex items-center space-x-1 px-2.5 py-1 text-xs font-semibold text-slate-700 bg-white hover:bg-slate-50 border border-slate-300 rounded-md shadow-xs transition-colors disabled:opacity-60"
                title="Insert Document / PDF Page as Annotation Layer"
              >
                {docLoading ? (
                  <span className="w-3.5 h-3.5 border-2 border-indigo-600 border-t-transparent rounded-full animate-spin" />
                ) : (
                  <FileText className="w-3.5 h-3.5 text-emerald-600" />
                )}
                <span className="hidden lg:inline">{docLoading ? 'Rendering PDF...' : 'Add Document'}</span>
              </button>

              {/* Remove Photo button if image is on the board */}
              {(pages[currentPage] || []).some((el) => el.type === 'image') && (
                <button
                  onClick={handleRemoveLatestImage}
                  className="flex items-center space-x-1 px-2 py-1 text-xs font-bold text-amber-700 bg-amber-50 hover:bg-amber-100 border border-amber-300 rounded-md shadow-xs transition-colors"
                  title="Remove uploaded photo from this page"
                >
                  <X className="w-3.5 h-3.5" />
                  <span>Remove Photo</span>
                </button>
              )}

              {/* Remove Document button if document layer is present */}
              {documentLayers[currentPage] && (
                <button
                  onClick={handleRemoveDocument}
                  className="flex items-center space-x-1 px-2 py-1 text-xs font-bold text-rose-700 bg-rose-50 hover:bg-rose-100 border border-rose-300 rounded-md shadow-xs transition-colors"
                  title="Remove document layer from this page"
                >
                  <X className="w-3.5 h-3.5" />
                  <span>Remove Doc</span>
                </button>
              )}
            </div>
          )}

          <div className="h-4 w-px bg-slate-200 hidden sm:block" />

          {/* Background Style Switcher */}
          <div className="hidden sm:flex items-center space-x-1 bg-slate-100 p-0.5 rounded-lg border border-slate-200">
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

        {/* Right Actions: Pen Size quick indicator, Undo/Redo, Zoom, Export */}
        <div className="flex items-center space-x-2">
          {isTeacher && (
            <div className="flex items-center space-x-1 border-r border-slate-200 pr-2">
              <button
                onClick={handleUndo}
                className="p-1.5 text-slate-600 hover:bg-slate-100 rounded-md"
                title="Undo (Ctrl+Z)"
              >
                <RotateCcw className="w-4 h-4" />
              </button>
              <button
                onClick={handleRedo}
                className="p-1.5 text-slate-600 hover:bg-slate-100 rounded-md"
                title="Redo (Ctrl+Y)"
              >
                <RotateCw className="w-4 h-4" />
              </button>
              <button
                onClick={handleClear}
                className="p-1.5 text-rose-600 hover:bg-rose-50 rounded-md"
                title="Clear Page"
              >
                <Trash2 className="w-4 h-4" />
              </button>
            </div>
          )}

          {/* Zoom Controls */}
          <div className="flex items-center bg-slate-100 rounded-lg p-0.5 border border-slate-200 shadow-2xs">
            <button
              onClick={() => setZoom((z) => Math.max(0.4, Number((z - 0.1).toFixed(1))))}
              className="p-1 text-slate-600 hover:bg-white rounded transition-colors"
              title="Zoom Out"
            >
              <ZoomOut className="w-3.5 h-3.5" />
            </button>
            <button
              onClick={() => {
                setZoom(1);
                setPan({ x: 0, y: 0 });
              }}
              className="px-1.5 py-0.5 text-xs font-bold text-indigo-600 hover:bg-white rounded transition-colors"
              title="Click to Reset Zoom to 100%"
            >
              {Math.round(zoom * 100)}%
            </button>
            <button
              onClick={() => setZoom((z) => Math.min(3, Number((z + 0.1).toFixed(1))))}
              className="p-1 text-slate-600 hover:bg-white rounded transition-colors"
              title="Zoom In"
            >
              <ZoomIn className="w-3.5 h-3.5" />
            </button>
          </div>

          <button
            onClick={handleExportPNG}
            className="flex items-center space-x-1 px-2.5 py-1 text-xs font-semibold text-slate-700 bg-white hover:bg-slate-50 border border-slate-300 rounded-md shadow-xs transition-colors"
            title="Download Notes PNG"
          >
            <Download className="w-3.5 h-3.5" />
            <span className="hidden sm:inline">Export</span>
          </button>
        </div>
      </div>

      {/* Canvas Area */}
      <div
        ref={containerRef}
        className={`relative flex-1 w-full h-full overflow-hidden bg-white select-none ${
          activeTool === 'select'
            ? isDraggingElement
              ? 'cursor-grabbing'
              : 'cursor-default'
            : activeTool === 'pan'
            ? isPanning
              ? 'cursor-grabbing'
              : 'cursor-grab'
            : activeTool === 'snip'
            ? 'cursor-crosshair'
            : 'cursor-crosshair'
        } ${
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

        {/* Floating Tool Dock (Teacher) */}
        {isTeacher && (
          <div className="absolute left-3 top-1/2 -translate-y-1/2 bg-white/95 backdrop-blur-md border border-slate-200/90 rounded-2xl shadow-elevated p-2 flex flex-col space-y-1.5 z-30">
            {/* Selection & Snip Tools */}
            <div className="flex flex-col space-y-1">
              <button
                onClick={() => setActiveTool('select')}
                className={`p-2 rounded-xl transition-all ${
                  activeTool === 'select'
                    ? 'bg-indigo-600 text-white shadow-sm ring-2 ring-indigo-200'
                    : 'text-slate-600 hover:bg-slate-100'
                }`}
                title="Select & Move Image / Snippet"
              >
                <MousePointer className="w-4 h-4" />
              </button>

              <button
                onClick={() => setActiveTool('pan')}
                className={`p-2 rounded-xl transition-all ${
                  activeTool === 'pan'
                    ? 'bg-indigo-600 text-white shadow-sm ring-2 ring-indigo-200'
                    : 'text-slate-600 hover:bg-slate-100'
                }`}
                title="Pan / Hand Tool (Drag Canvas When Zoomed)"
              >
                <Hand className="w-4 h-4" />
              </button>

              <button
                onClick={() => setActiveTool('snip')}
                className={`p-2 rounded-xl transition-all ${
                  activeTool === 'snip'
                    ? 'bg-rose-600 text-white shadow-sm ring-2 ring-rose-200 animate-pulse'
                    : 'text-slate-600 hover:bg-slate-100'
                }`}
                title="Snip / Cut Question Tool (Drag Box Over PDF to Cut into Draggable Sticker)"
              >
                <Scissors className="w-4 h-4" />
              </button>
            </div>

            <div className="h-px bg-slate-200 mx-1" />

            {/* Drawing Tools */}
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

            {/* Shapes */}
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
                title="Line"
              >
                <Minus className="w-4 h-4" />
              </button>
            </div>

            <div className="h-px bg-slate-200 mx-1" />

            {/* Text & Notes & Laser */}
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

            {/* Granular Pen Thickness Trigger & Slider Popover */}
            <div className="relative flex flex-col items-center">
              <button
                onClick={() => setPenSettingsOpen(!penSettingsOpen)}
                className={`p-2 rounded-xl transition-colors relative ${
                  penSettingsOpen ? 'bg-indigo-100 text-indigo-700' : 'text-slate-600 hover:bg-slate-100'
                }`}
                title="Pen Size Slider & Thickness Settings"
              >
                <Sliders className="w-4 h-4" />
                <span className="text-[9px] font-extrabold block text-center leading-none mt-0.5">
                  {strokeWidth}px
                </span>
              </button>

              {/* Popover slider menu */}
              {penSettingsOpen && (
                <div className="absolute left-full ml-3 top-0 bg-white rounded-2xl shadow-elevated border border-slate-200 p-3.5 w-60 z-50 animate-in fade-in zoom-in-95">
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-xs font-bold text-slate-800">Pen Thickness</span>
                    <span className="text-xs font-mono font-bold text-indigo-600 bg-indigo-50 px-2 py-0.5 rounded">
                      {strokeWidth} px
                    </span>
                  </div>

                  {/* Visual Brush Size Preview */}
                  <div className="h-10 bg-slate-50 rounded-xl border border-slate-200 flex items-center justify-center mb-3">
                    <div
                      className="rounded-full transition-all"
                      style={{
                        width: `${Math.max(strokeWidth, 2)}px`,
                        height: `${Math.max(strokeWidth, 2)}px`,
                        backgroundColor: color,
                      }}
                    />
                  </div>

                  {/* Slider Control */}
                  <input
                    type="range"
                    min="1"
                    max="40"
                    value={strokeWidth}
                    onChange={(e) => setStrokeWidth(Number(e.target.value))}
                    className="w-full h-1.5 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-indigo-600 mb-3"
                  />

                  {/* Quick Presets */}
                  <div className="grid grid-cols-5 gap-1 pt-1 border-t border-slate-100">
                    {PRESET_SIZES.map((preset) => (
                      <button
                        key={preset.size}
                        onClick={() => setStrokeWidth(preset.size)}
                        className={`text-[10px] py-1 rounded font-semibold transition-colors ${
                          strokeWidth === preset.size
                            ? 'bg-indigo-600 text-white'
                            : 'bg-slate-100 hover:bg-slate-200 text-slate-700'
                        }`}
                      >
                        {preset.size}p
                      </button>
                    ))}
                  </div>
                </div>
              )}
            </div>

            <div className="h-px bg-slate-200 mx-1" />

            {/* Colors */}
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
          </div>
        )}

        {/* Text / Note Input Modal */}
        {textModalOpen && (
          <div className="absolute inset-0 bg-black/20 backdrop-blur-xs flex items-center justify-center z-40">
            <div className="bg-white rounded-xl shadow-elevated border border-slate-200 p-5 w-80">
              <h4 className="text-sm font-semibold text-slate-800 mb-2">
                {activeTool === 'note' ? 'Add Sticky Note' : 'Add Text Box'}
              </h4>
              <textarea
                value={noteContent}
                onChange={(e) => setNoteContent(e.target.value)}
                placeholder="Type formula or notes here..."
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
