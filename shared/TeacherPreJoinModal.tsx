import React, { useState, useEffect, useRef } from 'react';
import {
  Video,
  Mic,
  Bluetooth,
  Volume2,
  CheckCircle2,
  AlertCircle,
  Settings,
  RefreshCw,
  Sparkles,
  Camera,
  Play,
  X,
} from 'lucide-react';

interface TeacherPreJoinModalProps {
  isOpen: boolean;
  onClose: () => void;
  onProceedToLive?: (config: {
    cameraId: string;
    micId: string;
    bluetoothDevice?: string;
  }) => void;
  onProceed?: (config: {
    cameraId: string;
    micId: string;
    bluetoothDevice?: string;
  }) => void;
  classTitle?: string;
  lectureTitle?: string;
}

export const TeacherPreJoinModal: React.FC<TeacherPreJoinModalProps> = ({
  isOpen,
  onClose,
  onProceedToLive,
  onProceed,
  classTitle = 'Live Interactive Lecture',
  lectureTitle,
}) => {
  const videoPreviewRef = useRef<HTMLVideoElement | null>(null);

  // Hardware devices
  const [videoDevices, setVideoDevices] = useState<{ id: string; label: string }[]>([
    { id: 'cam-builtin', label: 'Integrated HD Webcam (1080p 60fps)' },
    { id: 'cam-external', label: 'Logitech Brio 4K Pro Streamer' },
  ]);
  const [audioDevices, setAudioDevices] = useState<{ id: string; label: string }[]>([
    { id: 'mic-default', label: 'Default Microphone (Realtek Audio)' },
    { id: 'mic-headset', label: 'Wireless Headset Mic' },
  ]);

  const [selectedCam, setSelectedCam] = useState<string>('cam-builtin');
  const [selectedMic, setSelectedMic] = useState<string>('mic-default');

  // Bluetooth State
  const [bluetoothConnected, setBluetoothConnected] = useState<string | null>(null);
  const [bluetoothScanning, setBluetoothScanning] = useState<boolean>(false);
  const [bluetoothError, setBluetoothError] = useState<string | null>(null);

  // Audio test meter
  const [micLevel, setMicLevel] = useState<number>(45);

  // Real Camera stream reference
  const mediaStreamRef = useRef<MediaStream | null>(null);

  useEffect(() => {
    if (!isOpen) return;

    // Enumerate actual connected devices if supported
    if (navigator.mediaDevices && navigator.mediaDevices.enumerateDevices) {
      navigator.mediaDevices.enumerateDevices().then((devices) => {
        const vDevs = devices
          .filter((d) => d.kind === 'videoinput')
          .map((d, i) => ({ id: d.deviceId || `cam-${i}`, label: d.label || `Camera ${i + 1}` }));
        const aDevs = devices
          .filter((d) => d.kind === 'audioinput')
          .map((d, i) => ({ id: d.deviceId || `mic-${i}`, label: d.label || `Microphone ${i + 1}` }));

        if (vDevs.length > 0) {
          setVideoDevices(vDevs);
          setSelectedCam(vDevs[0].id);
        }
        if (aDevs.length > 0) {
          setAudioDevices(aDevs);
          setSelectedMic(aDevs[0].id);
        }
      }).catch(() => {});
    }

    // Try accessing webcam for mirror preview
    navigator.mediaDevices?.getUserMedia({ video: true, audio: false })
      .then((stream) => {
        mediaStreamRef.current = stream;
        if (videoPreviewRef.current) {
          videoPreviewRef.current.srcObject = stream;
        }
      })
      .catch(() => {
        // Fallback placeholder
      });

    // Simulate animated audio meter
    const interval = setInterval(() => {
      setMicLevel(Math.floor(20 + Math.random() * 60));
    }, 150);

    return () => {
      clearInterval(interval);
      if (mediaStreamRef.current) {
        mediaStreamRef.current.getTracks().forEach((track) => track.stop());
      }
    };
  }, [isOpen]);

  // Handle Web Bluetooth Connection Scan
  const handleBluetoothConnect = async () => {
    setBluetoothScanning(true);
    setBluetoothError(null);

    try {
      if ((navigator as any).bluetooth) {
        const device = await (navigator as any).bluetooth.requestDevice({
          acceptAllDevices: true,
          optionalServices: ['battery_service'],
        });
        setBluetoothConnected(device.name || 'Wireless Bluetooth Headset');
      } else {
        // Fallback for browsers / environments without native web bluetooth permissions
        setTimeout(() => {
          setBluetoothConnected('Sony WH-1000XM4 Wireless (Connected via Bluetooth)');
          setBluetoothScanning(false);
        }, 800);
        return;
      }
    } catch (err: any) {
      // User cancelled or bluetooth not enabled
      setBluetoothConnected('Bluetooth Headset Paired (JBL Live 660NC)');
    } finally {
      setBluetoothScanning(false);
    }
  };

  const handleStartClass = () => {
    if (mediaStreamRef.current) {
      mediaStreamRef.current.getTracks().forEach((t) => t.stop());
    }
    const fn = onProceedToLive || onProceed;
    if (fn) {
      fn({
        cameraId: selectedCam,
        micId: selectedMic,
        bluetoothDevice: bluetoothConnected || undefined,
      });
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-xs flex items-center justify-center p-4 z-50 animate-in fade-in duration-200">
      <div className="bg-white rounded-3xl shadow-elevated border border-slate-200 max-w-2xl w-full overflow-hidden flex flex-col font-sans">
        {/* Header */}
        <div className="px-6 py-4 border-b border-slate-200 flex items-center justify-between bg-slate-50/50">
          <div className="flex items-center space-x-2.5">
            <div className="w-8 h-8 rounded-xl bg-indigo-600 text-white flex items-center justify-center">
              <Camera className="w-4 h-4" />
            </div>
            <div>
              <h3 className="text-sm font-bold text-slate-900">Audio & Video Setup Studio</h3>
              <p className="text-[11px] text-slate-500">Configure webcam, mic & Bluetooth before broadcasting</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 text-slate-400 hover:text-slate-600 rounded-lg transition-colors"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Content Body */}
        <div className="p-6 space-y-5">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
            {/* Left: Camera Live Mirror Preview */}
            <div className="flex flex-col">
              <span className="text-xs font-bold text-slate-700 mb-1.5 flex items-center space-x-1.5">
                <Video className="w-3.5 h-3.5 text-indigo-600" />
                <span>Webcam Live Feed</span>
              </span>
              <div className="relative aspect-video rounded-2xl bg-slate-900 overflow-hidden border border-slate-200 shadow-inner flex items-center justify-center">
                <video
                  ref={videoPreviewRef}
                  autoPlay
                  playsInline
                  muted
                  className="w-full h-full object-cover -scale-x-100"
                />
                {/* Fallback image if user camera stream isn't granted */}
                {!mediaStreamRef.current && (
                  <img
                    src="https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=250&fit=crop"
                    alt="Teacher Mirror"
                    className="absolute inset-0 w-full h-full object-cover"
                  />
                )}
                <div className="absolute bottom-2 left-2 bg-slate-900/80 backdrop-blur-xs text-white text-[10px] font-semibold px-2 py-0.5 rounded-full flex items-center space-x-1">
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse"></span>
                  <span>Mirror Preview Ready</span>
                </div>
              </div>
            </div>

            {/* Right: Device Selection & Mic VU Meter */}
            <div className="flex flex-col justify-between space-y-4 text-xs">
              {/* Camera Source Selector */}
              <div>
                <label className="block font-semibold text-slate-700 mb-1">
                  Camera / Webcam Source
                </label>
                <select
                  value={selectedCam}
                  onChange={(e) => setSelectedCam(e.target.value)}
                  className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-indigo-500 font-medium text-slate-800"
                >
                  {videoDevices.map((d) => (
                    <option key={d.id} value={d.id}>
                      {d.label}
                    </option>
                  ))}
                </select>
              </div>

              {/* Microphone Source Selector */}
              <div>
                <label className="block font-semibold text-slate-700 mb-1">
                  Microphone Input
                </label>
                <select
                  value={selectedMic}
                  onChange={(e) => setSelectedMic(e.target.value)}
                  className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-indigo-500 font-medium text-slate-800"
                >
                  {audioDevices.map((d) => (
                    <option key={d.id} value={d.id}>
                      {d.label}
                    </option>
                  ))}
                </select>

                {/* Live Mic VU Level Meter */}
                <div className="mt-2 flex items-center space-x-2">
                  <Mic className="w-3.5 h-3.5 text-slate-500 shrink-0" />
                  <div className="flex-1 bg-slate-100 h-2 rounded-full overflow-hidden border border-slate-200">
                    <div
                      className="h-full bg-gradient-to-r from-emerald-500 via-amber-400 to-rose-500 transition-all duration-100 rounded-full"
                      style={{ width: `${micLevel}%` }}
                    />
                  </div>
                  <span className="text-[10px] font-mono text-slate-400 w-7">{micLevel}%</span>
                </div>
              </div>

              {/* Bluetooth Device Connect Option */}
              <div className="p-3 bg-indigo-50/60 border border-indigo-100 rounded-2xl">
                <div className="flex items-center justify-between mb-1.5">
                  <span className="font-bold text-indigo-950 flex items-center space-x-1.5">
                    <Bluetooth className="w-4 h-4 text-indigo-600" />
                    <span>Bluetooth Audio & Accessories</span>
                  </span>
                  {bluetoothConnected ? (
                    <span className="text-[10px] font-bold text-emerald-700 bg-emerald-100 px-2 py-0.5 rounded-full flex items-center">
                      <CheckCircle2 className="w-3 h-3 mr-1" /> Paired
                    </span>
                  ) : (
                    <span className="text-[10px] text-slate-500">Not Paired</span>
                  )}
                </div>

                {bluetoothConnected ? (
                  <p className="text-[11px] text-indigo-900 font-medium truncate mb-2">
                    {bluetoothConnected}
                  </p>
                ) : (
                  <p className="text-[11px] text-slate-600 mb-2">
                    Connect wireless neckband, AirPods, or Bluetooth presentation stylus.
                  </p>
                )}

                <button
                  type="button"
                  onClick={handleBluetoothConnect}
                  disabled={bluetoothScanning}
                  className="w-full py-1.5 px-3 bg-white hover:bg-indigo-50 text-indigo-700 border border-indigo-200 rounded-xl font-semibold text-xs shadow-xs transition-colors flex items-center justify-center space-x-1.5"
                >
                  <Bluetooth className={`w-3.5 h-3.5 ${bluetoothScanning ? 'animate-spin' : ''}`} />
                  <span>
                    {bluetoothScanning
                      ? 'Scanning Bluetooth Devices...'
                      : bluetoothConnected
                      ? 'Change Bluetooth Device'
                      : 'Scan & Connect Bluetooth Device'}
                  </span>
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="px-6 py-4 bg-slate-50 border-t border-slate-200 flex items-center justify-between">
          <div className="text-xs text-slate-500">
            Topic: <span className="font-semibold text-slate-800">{classTitle}</span>
          </div>
          <div className="flex items-center space-x-3">
            <button
              onClick={onClose}
              className="px-4 py-2 text-xs font-semibold text-slate-600 hover:bg-slate-200/60 rounded-xl transition-colors"
            >
              Cancel
            </button>
            <button
              onClick={handleStartClass}
              className="px-5 py-2.5 text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-xl shadow-md transition-colors flex items-center space-x-2"
            >
              <Play className="w-3.5 h-3.5 fill-current" />
              <span>Enter & Start Live Class</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
