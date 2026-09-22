import React, { useState, useEffect } from 'react';
import {
  Mic,
  MicOff,
  Video,
  VideoOff,
  Hand,
  MessageSquare,
  BarChart2,
  Users,
  PhoneOff,
  HelpCircle,
  CheckCircle2,
  Send,
  Sparkles,
  AlertCircle,
  Share2,
} from 'lucide-react';
import { DigitalBoard } from '../board/DigitalBoard.js';
import { ChatMessage, ActivePoll, DoubtItem } from '../../types/index.js';

interface LiveClassroomProps {
  role: 'teacher' | 'student';
  userName: string;
  onExit: () => void;
}

export const LiveClassroom: React.FC<LiveClassroomProps> = ({ role, userName, onExit }) => {
  const isTeacher = role === 'teacher';

  // AV State
  const [micOn, setMicOn] = useState(true);
  const [camOn, setCamOn] = useState(true);

  // Panels: 'chat' | 'doubts' | 'polls' | 'roster' | null
  const [activePanel, setActivePanel] = useState<'chat' | 'doubts' | 'polls' | 'roster' | null>('chat');

  // Chat state
  const [chatMessages, setChatMessages] = useState<ChatMessage[]>([
    {
      id: '1',
      sender: 'Prof. Rajesh Sharma',
      message: 'Welcome everyone! Today we will solve rotational dynamics problems.',
      role: 'teacher',
      timestamp: '18:30',
    },
    {
      id: '2',
      sender: 'Priya Singh',
      message: 'Good evening Sir, will we cover conservation of angular momentum today?',
      role: 'student',
      timestamp: '18:31',
    },
    {
      id: '3',
      sender: 'Prof. Rajesh Sharma',
      message: 'Yes Priya, right after solving the rolling disc example on the board.',
      role: 'teacher',
      timestamp: '18:32',
    },
  ]);
  const [currentChatInput, setCurrentChatInput] = useState('');

  // Doubts state
  const [doubts, setDoubts] = useState<DoubtItem[]>([
    {
      id: 'd-1',
      studentName: 'Rohan Verma',
      doubtText: 'Sir, why does static friction do no work in pure rolling?',
      status: 'pending',
      timestamp: '18:33',
    },
    {
      id: 'd-2',
      studentName: 'Aarav Patel',
      doubtText: 'Can you re-explain the torque about the instantaneous axis?',
      status: 'resolved',
      timestamp: '18:31',
    },
  ]);
  const [newDoubtText, setNewDoubtText] = useState('');
  const [handRaised, setHandRaised] = useState(false);

  // Poll state
  const [activePoll, setActivePoll] = useState<ActivePoll | null>({
    id: 'poll-1',
    question: 'What is the acceleration of a ring rolling down an incline of angle θ?',
    options: [
      { text: 'g sin θ / 2', votes: 14 },
      { text: 'g sin θ', votes: 3 },
      { text: '2/3 g sin θ', votes: 5 },
    ],
    totalVotes: 22,
    active: true,
  });
  const [userVoted, setUserVoted] = useState<number | null>(null);

  // Teacher Poll Launcher State
  const [newPollQuestion, setNewPollQuestion] = useState('');
  const [newPollOpt1, setNewPollOpt1] = useState('');
  const [newPollOpt2, setNewPollOpt2] = useState('');

  // Roster
  const participants = [
    { name: 'Prof. Rajesh Sharma (Teacher)', role: 'teacher', status: 'Speaking' },
    { name: 'Aarav Patel', role: 'student', status: 'Attending' },
    { name: 'Priya Singh', role: 'student', status: 'Attending' },
    { name: 'Rohan Verma', role: 'student', status: 'Hand Raised' },
    { name: 'Neha Sharma', role: 'student', status: 'Attending' },
    { name: 'Aditya Mehta', role: 'student', status: 'Attending' },
    { name: 'Sneha Roy', role: 'student', status: 'Attending' },
  ];

  // Send Chat
  const handleSendChat = (e: React.FormEvent) => {
    e.preventDefault();
    if (!currentChatInput.trim()) return;
    const newMsg: ChatMessage = {
      id: `chat-${Date.now()}`,
      sender: userName,
      message: currentChatInput.trim(),
      role: role,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    };
    setChatMessages((prev) => [...prev, newMsg]);
    setCurrentChatInput('');
  };

  // Submit Doubt
  const handleSubmitDoubt = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newDoubtText.trim()) return;
    const newDoubt: DoubtItem = {
      id: `d-${Date.now()}`,
      studentName: userName,
      doubtText: newDoubtText.trim(),
      status: 'pending',
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    };
    setDoubts((prev) => [newDoubt, ...prev]);
    setNewDoubtText('');
  };

  // Resolve Doubt
  const handleResolveDoubt = (id: string) => {
    setDoubts((prev) =>
      prev.map((d) => (d.id === id ? { ...d, status: 'resolved' } : d))
    );
  };

  // Launch Poll (Teacher)
  const handleCreatePoll = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newPollQuestion.trim() || !newPollOpt1.trim() || !newPollOpt2.trim()) return;
    setActivePoll({
      id: `poll-${Date.now()}`,
      question: newPollQuestion.trim(),
      options: [
        { text: newPollOpt1.trim(), votes: 0 },
        { text: newPollOpt2.trim(), votes: 0 },
      ],
      totalVotes: 0,
      active: true,
    });
    setUserVoted(null);
    setNewPollQuestion('');
    setNewPollOpt1('');
    setNewPollOpt2('');
  };

  // Vote Poll (Student)
  const handleVote = (idx: number) => {
    if (userVoted !== null || !activePoll) return;
    setUserVoted(idx);
    setActivePoll((prev) => {
      if (!prev) return null;
      const updatedOpts = [...prev.options];
      updatedOpts[idx].votes += 1;
      return {
        ...prev,
        options: updatedOpts,
        totalVotes: prev.totalVotes + 1,
      };
    });
  };

  return (
    <div className="relative w-full h-[calc(100vh-64px)] flex bg-slate-50 overflow-hidden font-sans">
      {/* Left / Center Area: Synced Whiteboard */}
      <div className="relative flex-1 flex flex-col h-full overflow-hidden">
        {/* Top Class Banner */}
        <div className="h-10 bg-white border-b border-slate-200 px-4 flex items-center justify-between z-10">
          <div className="flex items-center space-x-3">
            <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-semibold bg-rose-50 text-rose-700 border border-rose-200">
              <span className="w-1.5 h-1.5 rounded-full bg-rose-500 animate-pulse mr-1.5" />
              LIVE
            </span>
            <h3 className="text-xs font-semibold text-slate-800">
              Physics JEE Super 30: Angular Momentum & Rolling Motion
            </h3>
            <span className="text-xs text-slate-400">|</span>
            <span className="text-xs text-slate-500">Prof. Rajesh Sharma</span>
          </div>
          <div className="flex items-center space-x-2 text-xs font-medium text-slate-500">
            <Users className="w-3.5 h-3.5 text-indigo-600" />
            <span>34 Students Joined</span>
          </div>
        </div>

        {/* The Digital Board Canvas */}
        <div className="relative flex-1 w-full h-full">
          <DigitalBoard isTeacher={isTeacher} />

          {/* Floating Teacher PiP Video Camera Tile */}
          <div className="absolute top-16 right-4 w-52 bg-white rounded-xl shadow-elevated border border-slate-200 overflow-hidden z-30 transition-all hover:scale-102">
            <div className="relative aspect-video bg-slate-100 flex items-center justify-center overflow-hidden">
              {camOn ? (
                <img
                  src="https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300&h=200&fit=crop"
                  alt="Teacher Feed"
                  className="w-full h-full object-cover"
                />
              ) : (
                <div className="flex flex-col items-center justify-center text-slate-400">
                  <VideoOff className="w-6 h-6 mb-1" />
                  <span className="text-[10px]">Camera Paused</span>
                </div>
              )}
              {/* Teacher badge */}
              <div className="absolute bottom-1.5 left-2 bg-slate-900/80 backdrop-blur-xs text-white text-[10px] font-medium px-2 py-0.5 rounded flex items-center space-x-1">
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-400"></span>
                <span>Prof. Sharma</span>
              </div>
              <div className="absolute bottom-1.5 right-2">
                {micOn ? (
                  <span className="p-1 bg-slate-900/80 rounded text-emerald-400 text-[10px] flex items-center">
                    <Mic className="w-2.5 h-2.5" />
                  </span>
                ) : (
                  <span className="p-1 bg-rose-600 text-white rounded text-[10px] flex items-center">
                    <MicOff className="w-2.5 h-2.5" />
                  </span>
                )}
              </div>
            </div>
          </div>

          {/* Floating Bottom Classroom Action Dock */}
          <div className="absolute bottom-4 left-1/2 -translate-x-1/2 bg-white/95 backdrop-blur-md border border-slate-200 shadow-elevated rounded-2xl px-3 py-2 flex items-center space-x-2 z-30">
            {/* Mic toggle */}
            <button
              onClick={() => setMicOn(!micOn)}
              className={`p-2.5 rounded-xl border transition-colors ${
                micOn
                  ? 'bg-slate-100 hover:bg-slate-200 text-slate-700 border-slate-200'
                  : 'bg-rose-50 text-rose-600 border-rose-200 hover:bg-rose-100'
              }`}
              title={micOn ? 'Mute Mic' : 'Unmute Mic'}
            >
              {micOn ? <Mic className="w-4 h-4" /> : <MicOff className="w-4 h-4" />}
            </button>

            {/* Video toggle */}
            <button
              onClick={() => setCamOn(!camOn)}
              className={`p-2.5 rounded-xl border transition-colors ${
                camOn
                  ? 'bg-slate-100 hover:bg-slate-200 text-slate-700 border-slate-200'
                  : 'bg-rose-50 text-rose-600 border-rose-200 hover:bg-rose-100'
              }`}
              title={camOn ? 'Turn Camera Off' : 'Turn Camera On'}
            >
              {camOn ? <Video className="w-4 h-4" /> : <VideoOff className="w-4 h-4" />}
            </button>

            {/* Student Raise Hand Toggle */}
            {!isTeacher && (
              <button
                onClick={() => setHandRaised(!handRaised)}
                className={`p-2.5 rounded-xl border transition-colors flex items-center space-x-1.5 ${
                  handRaised
                    ? 'bg-amber-100 text-amber-800 border-amber-300'
                    : 'bg-slate-100 hover:bg-slate-200 text-slate-700 border-slate-200'
                }`}
                title="Raise Hand"
              >
                <Hand className={`w-4 h-4 ${handRaised ? 'animate-bounce' : ''}`} />
                <span className="text-xs font-medium hidden sm:inline">
                  {handRaised ? 'Hand Raised' : 'Raise Hand'}
                </span>
              </button>
            )}

            <div className="h-5 w-px bg-slate-200" />

            {/* Panel Switchers */}
            <button
              onClick={() => setActivePanel(activePanel === 'chat' ? null : 'chat')}
              className={`p-2.5 rounded-xl border transition-colors ${
                activePanel === 'chat'
                  ? 'bg-indigo-600 text-white border-indigo-600'
                  : 'bg-slate-100 hover:bg-slate-200 text-slate-700 border-slate-200'
              }`}
              title="Live Chat"
            >
              <MessageSquare className="w-4 h-4" />
            </button>

            <button
              onClick={() => setActivePanel(activePanel === 'doubts' ? null : 'doubts')}
              className={`p-2.5 rounded-xl border transition-colors relative ${
                activePanel === 'doubts'
                  ? 'bg-indigo-600 text-white border-indigo-600'
                  : 'bg-slate-100 hover:bg-slate-200 text-slate-700 border-slate-200'
              }`}
              title="Doubt Queue"
            >
              <HelpCircle className="w-4 h-4" />
              {doubts.filter((d) => d.status === 'pending').length > 0 && (
                <span className="absolute -top-1 -right-1 w-4 h-4 rounded-full bg-rose-500 text-white text-[10px] font-bold flex items-center justify-center">
                  {doubts.filter((d) => d.status === 'pending').length}
                </span>
              )}
            </button>

            <button
              onClick={() => setActivePanel(activePanel === 'polls' ? null : 'polls')}
              className={`p-2.5 rounded-xl border transition-colors ${
                activePanel === 'polls'
                  ? 'bg-indigo-600 text-white border-indigo-600'
                  : 'bg-slate-100 hover:bg-slate-200 text-slate-700 border-slate-200'
              }`}
              title="Live Polls"
            >
              <BarChart2 className="w-4 h-4" />
            </button>

            <button
              onClick={() => setActivePanel(activePanel === 'roster' ? null : 'roster')}
              className={`p-2.5 rounded-xl border transition-colors ${
                activePanel === 'roster'
                  ? 'bg-indigo-600 text-white border-indigo-600'
                  : 'bg-slate-100 hover:bg-slate-200 text-slate-700 border-slate-200'
              }`}
              title="Participants Roster"
            >
              <Users className="w-4 h-4" />
            </button>

            <div className="h-5 w-px bg-slate-200" />

            {/* End / Leave Class Button */}
            <button
              onClick={onExit}
              className="flex items-center space-x-1.5 px-3 py-2 text-xs font-semibold text-white bg-rose-600 hover:bg-rose-700 rounded-xl shadow-sm transition-colors"
            >
              <PhoneOff className="w-3.5 h-3.5" />
              <span>{isTeacher ? 'End Class' : 'Leave'}</span>
            </button>
          </div>
        </div>
      </div>

      {/* Right Drawer: Active Panel (Chat, Doubts, Polls, or Roster) */}
      {activePanel && (
        <div className="w-80 h-full bg-white border-l border-slate-200 flex flex-col shadow-card z-20">
          {/* Header */}
          <div className="h-12 border-b border-slate-200 px-4 flex items-center justify-between">
            <h4 className="text-sm font-semibold text-slate-800 capitalize flex items-center space-x-2">
              {activePanel === 'chat' && (
                <>
                  <MessageSquare className="w-4 h-4 text-indigo-600" />
                  <span>Class Chat</span>
                </>
              )}
              {activePanel === 'doubts' && (
                <>
                  <HelpCircle className="w-4 h-4 text-indigo-600" />
                  <span>Doubt Queue</span>
                </>
              )}
              {activePanel === 'polls' && (
                <>
                  <BarChart2 className="w-4 h-4 text-indigo-600" />
                  <span>Live Poll</span>
                </>
              )}
              {activePanel === 'roster' && (
                <>
                  <Users className="w-4 h-4 text-indigo-600" />
                  <span>Attendance Roster</span>
                </>
              )}
            </h4>
            <button
              onClick={() => setActivePanel(null)}
              className="text-xs text-slate-400 hover:text-slate-600 font-medium"
            >
              Close
            </button>
          </div>

          {/* Panel Body: Chat */}
          {activePanel === 'chat' && (
            <div className="flex-1 flex flex-col h-full overflow-hidden">
              <div className="flex-1 p-3 overflow-y-auto space-y-3">
                {chatMessages.map((msg) => (
                  <div
                    key={msg.id}
                    className={`flex flex-col text-xs ${
                      msg.sender === userName ? 'items-end' : 'items-start'
                    }`}
                  >
                    <div className="flex items-center space-x-1 mb-1">
                      <span className="font-semibold text-slate-700">{msg.sender}</span>
                      {msg.role === 'teacher' && (
                        <span className="bg-indigo-50 text-indigo-700 text-[9px] font-bold px-1.5 py-0.2 rounded border border-indigo-200">
                          Teacher
                        </span>
                      )}
                      <span className="text-[10px] text-slate-400">{msg.timestamp}</span>
                    </div>
                    <div
                      className={`p-2.5 rounded-xl max-w-[85%] leading-relaxed ${
                        msg.sender === userName
                          ? 'bg-indigo-600 text-white rounded-br-xs'
                          : 'bg-slate-100 text-slate-800 rounded-bl-xs border border-slate-200'
                      }`}
                    >
                      {msg.message}
                    </div>
                  </div>
                ))}
              </div>

              <form onSubmit={handleSendChat} className="p-3 border-t border-slate-200 flex items-center space-x-2">
                <input
                  type="text"
                  value={currentChatInput}
                  onChange={(e) => setCurrentChatInput(e.target.value)}
                  placeholder="Ask a question..."
                  className="flex-1 text-xs px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
                <button
                  type="submit"
                  className="p-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors"
                >
                  <Send className="w-3.5 h-3.5" />
                </button>
              </form>
            </div>
          )}

          {/* Panel Body: Doubts */}
          {activePanel === 'doubts' && (
            <div className="flex-1 flex flex-col h-full overflow-hidden">
              {!isTeacher && (
                <form onSubmit={handleSubmitDoubt} className="p-3 border-b border-slate-200">
                  <label className="block text-xs font-semibold text-slate-700 mb-1.5">
                    Ask Doubt from Whiteboard
                  </label>
                  <textarea
                    value={newDoubtText}
                    onChange={(e) => setNewDoubtText(e.target.value)}
                    placeholder="Type your question or equation query..."
                    rows={2}
                    className="w-full text-xs p-2 bg-slate-50 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 mb-2 resize-none"
                  />
                  <button
                    type="submit"
                    className="w-full py-1.5 text-xs font-medium text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg transition-colors"
                  >
                    Submit to Teacher
                  </button>
                </form>
              )}

              <div className="flex-1 p-3 overflow-y-auto space-y-2.5">
                {doubts.map((d) => (
                  <div
                    key={d.id}
                    className={`p-3 rounded-xl border text-xs ${
                      d.status === 'resolved'
                        ? 'bg-emerald-50/60 border-emerald-200 text-slate-700'
                        : 'bg-white border-slate-200 shadow-subtle text-slate-800'
                    }`}
                  >
                    <div className="flex items-center justify-between mb-1.5">
                      <span className="font-semibold text-slate-800">{d.studentName}</span>
                      <span className="text-[10px] text-slate-400">{d.timestamp}</span>
                    </div>
                    <p className="text-xs text-slate-600 mb-2">{d.doubtText}</p>
                    <div className="flex items-center justify-between pt-1 border-t border-slate-100">
                      <span
                        className={`text-[10px] font-semibold px-2 py-0.5 rounded-full ${
                          d.status === 'resolved'
                            ? 'bg-emerald-100 text-emerald-800'
                            : 'bg-amber-100 text-amber-800'
                        }`}
                      >
                        {d.status === 'resolved' ? 'Resolved' : 'Pending Review'}
                      </span>
                      {isTeacher && d.status === 'pending' && (
                        <button
                          onClick={() => handleResolveDoubt(d.id)}
                          className="flex items-center space-x-1 text-[11px] font-medium text-indigo-600 hover:text-indigo-800"
                        >
                          <CheckCircle2 className="w-3 h-3" />
                          <span>Mark Resolved</span>
                        </button>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Panel Body: Polls */}
          {activePanel === 'polls' && (
            <div className="flex-1 p-4 overflow-y-auto space-y-4">
              {activePoll ? (
                <div className="bg-white border border-slate-200 rounded-xl p-4 shadow-subtle">
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-[10px] font-bold uppercase tracking-wider text-indigo-600 bg-indigo-50 px-2 py-0.5 rounded">
                      Active Poll
                    </span>
                    <span className="text-xs text-slate-500 font-medium">
                      {activePoll.totalVotes} Votes
                    </span>
                  </div>
                  <h4 className="text-xs font-semibold text-slate-800 mb-3 leading-snug">
                    {activePoll.question}
                  </h4>
                  <div className="space-y-2">
                    {activePoll.options.map((opt, i) => {
                      const percentage =
                        activePoll.totalVotes > 0
                          ? Math.round((opt.votes / activePoll.totalVotes) * 100)
                          : 0;
                      return (
                        <button
                          key={i}
                          onClick={() => handleVote(i)}
                          disabled={userVoted !== null || isTeacher}
                          className={`w-full text-left p-2.5 rounded-lg border text-xs relative overflow-hidden transition-all ${
                            userVoted === i
                              ? 'border-indigo-500 bg-indigo-50/50 font-semibold'
                              : 'border-slate-200 hover:border-slate-300'
                          }`}
                        >
                          <div
                            className="absolute left-0 top-0 bottom-0 bg-indigo-100/60 transition-all duration-300"
                            style={{ width: `${percentage}%` }}
                          />
                          <div className="relative flex justify-between items-center">
                            <span>{opt.text}</span>
                            <span className="text-slate-500 font-bold">{percentage}%</span>
                          </div>
                        </button>
                      );
                    })}
                  </div>
                  {userVoted !== null && (
                    <p className="text-[10px] text-emerald-600 font-medium mt-2 flex items-center">
                      <CheckCircle2 className="w-3 h-3 mr-1" /> Vote Recorded
                    </p>
                  )}
                </div>
              ) : (
                <p className="text-xs text-slate-500 text-center py-6">No active poll right now.</p>
              )}

              {/* Teacher Create Poll Form */}
              {isTeacher && (
                <form onSubmit={handleCreatePoll} className="border-t border-slate-200 pt-4">
                  <h5 className="text-xs font-semibold text-slate-700 mb-2">Launch Quick Poll</h5>
                  <input
                    type="text"
                    value={newPollQuestion}
                    onChange={(e) => setNewPollQuestion(e.target.value)}
                    placeholder="Poll question..."
                    className="w-full text-xs p-2 border border-slate-200 rounded-lg mb-2 focus:ring-1 focus:ring-indigo-500"
                  />
                  <input
                    type="text"
                    value={newPollOpt1}
                    onChange={(e) => setNewPollOpt1(e.target.value)}
                    placeholder="Option A"
                    className="w-full text-xs p-2 border border-slate-200 rounded-lg mb-2 focus:ring-1 focus:ring-indigo-500"
                  />
                  <input
                    type="text"
                    value={newPollOpt2}
                    onChange={(e) => setNewPollOpt2(e.target.value)}
                    placeholder="Option B"
                    className="w-full text-xs p-2 border border-slate-200 rounded-lg mb-3 focus:ring-1 focus:ring-indigo-500"
                  />
                  <button
                    type="submit"
                    className="w-full py-1.5 text-xs font-semibold text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg shadow-sm"
                  >
                    Broadcast Poll
                  </button>
                </form>
              )}
            </div>
          )}

          {/* Panel Body: Roster */}
          {activePanel === 'roster' && (
            <div className="flex-1 p-3 overflow-y-auto space-y-2">
              {participants.map((p, idx) => (
                <div
                  key={idx}
                  className="flex items-center justify-between p-2 rounded-lg hover:bg-slate-50 border border-slate-100 text-xs"
                >
                  <div className="flex items-center space-x-2">
                    <div className="w-7 h-7 rounded-full bg-indigo-100 text-indigo-700 font-bold flex items-center justify-center text-[10px]">
                      {p.name.charAt(0)}
                    </div>
                    <div>
                      <p className="font-semibold text-slate-800">{p.name}</p>
                      <p className="text-[10px] text-slate-400 capitalize">{p.role}</p>
                    </div>
                  </div>
                  <span
                    className={`text-[10px] font-medium px-2 py-0.5 rounded-full ${
                      p.status === 'Speaking'
                        ? 'bg-emerald-100 text-emerald-800'
                        : p.status === 'Hand Raised'
                        ? 'bg-amber-100 text-amber-800 font-bold animate-pulse'
                        : 'bg-slate-100 text-slate-600'
                    }`}
                  >
                    {p.status}
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
};
