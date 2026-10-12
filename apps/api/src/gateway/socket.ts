import { Server, Socket } from 'socket.io';
import { verifyAccessToken } from '../utils/jwt.js';
import { prisma } from '../utils/prisma.js';

interface ChatMessage {
  id: string;
  senderId: string;
  senderName: string;
  senderRole: string;
  text: string;
  timestamp: string;
}

interface Poll {
  id: string;
  question: string;
  options: Array<{ id: number; text: string; votes: number }>;
  createdBy: string;
  active: boolean;
  votedUserIds: string[];
}

interface RaisedHand {
  userId: string;
  userName: string;
  userRole: string;
  raisedAt: string;
}

// In-memory room state stores
const roomHandQueues = new Map<string, RaisedHand[]>();
const roomActivePolls = new Map<string, Poll[]>();
const roomBoardGrantedStudents = new Map<string, Set<string>>();
const roomBoardStates = new Map<string, boolean>();
const roomChatHistory = new Map<string, ChatMessage[]>();
const hostDisconnectTimers = new Map<string, NodeJS.Timeout>();

let ioInstance: Server | null = null;

export function getSocketIO(): Server | null {
  return ioInstance;
}

export function emitToUser(userId: string, event: string, data: unknown): void {
  if (ioInstance) {
    ioInstance.to(`user:${userId}`).emit(event, data);
  }
}

export function emitToInstitute(instituteId: string, event: string, data: unknown): void {
  if (ioInstance) {
    ioInstance.to(`institute:${instituteId}`).emit(event, data);
  }
}

export function setupSocketGateway(io: Server) {
  ioInstance = io;

  // 1. JWT Authentication Middleware
  io.use((socket, next) => {
    try {
      const token =
        socket.handshake.auth?.token ||
        socket.handshake.headers?.authorization?.replace('Bearer ', '');

      if (!token) {
        return next(new Error('Authentication token required'));
      }

      const decoded = verifyAccessToken(token);
      socket.data.user = decoded;
      next();
    } catch {
      next(new Error('Invalid authentication token'));
    }
  });

  io.on('connection', (socket: Socket) => {
    const user = socket.data.user;
    const isHost = user.role === 'TEACHER' || user.role === 'ADMIN';

    // Automatically join user personal room and institute room for push/realtime updates
    if (user?.userId) {
      socket.join(`user:${user.userId}`);
    }
    if (user?.instituteId) {
      socket.join(`institute:${user.instituteId}`);
    }

    // Join classroom room
    socket.on('class:join', (data: { classId: string }) => {
      const roomKey = `class:${data.classId}`;
      socket.join(roomKey);
      socket.data.currentClassId = data.classId;

      // If host rejoins, cancel any pending abandonment timer
      if (isHost && hostDisconnectTimers.has(data.classId)) {
        clearTimeout(hostDisconnectTimers.get(data.classId)!);
        hostDisconnectTimers.delete(data.classId);
      }

      // Send existing state to joined user
      const hands = roomHandQueues.get(data.classId) || [];
      const polls = roomActivePolls.get(data.classId) || [];
      const chatHistory = roomChatHistory.get(data.classId) || [];
      const isBoardOpen = roomBoardStates.get(data.classId) || false;
      const canDraw = isHost || (roomBoardGrantedStudents.get(data.classId)?.has(user.userId) ?? false);

      socket.emit('hand:queue', { hands });
      socket.emit('poll:list', { polls });
      socket.emit('chat:history', { messages: chatHistory });
      socket.emit('board:state', { isOpen: isBoardOpen, canDraw });

      // Notify others in room
      socket.to(roomKey).emit('peer:joined', {
        userId: user.userId,
        name: user.name,
        role: user.role,
      });
    });

    // Leave classroom room
    socket.on('class:leave', (data: { classId: string }) => {
      const roomKey = `class:${data.classId}`;
      socket.leave(roomKey);
      socket.to(roomKey).emit('peer:left', { userId: user.userId, name: user.name });

      // If host leaves an active room, start 10-minute auto-end timeout
      if (isHost && !hostDisconnectTimers.has(data.classId)) {
        const timer = setTimeout(async () => {
          try {
            await prisma.liveClass.updateMany({
              where: { id: data.classId, status: 'LIVE' },
              data: { status: 'ENDED' },
            });
            io.to(`class:${data.classId}`).emit('class:ended', { reason: 'HOST_TIMEOUT' });
          } catch (err) {
            console.error('Error auto-ending class on host timeout:', err);
          } finally {
            hostDisconnectTimers.delete(data.classId);
          }
        }, 10 * 60 * 1000);
        timer.unref();
        hostDisconnectTimers.set(data.classId, timer);
      }
    });

    /* -------------------------------------------------------------------------- */
    /* DIGITAL WHITEBOARD SYNCHRONIZATION & PERMISSION ENFORCEMENT                */
    /* -------------------------------------------------------------------------- */
    socket.on('whiteboard:draw', (data: { classId: string; stroke: any }) => {
      const canDraw = isHost || (roomBoardGrantedStudents.get(data.classId)?.has(user.userId) ?? false);
      if (!canDraw) return; // Enforce: reject unauthorized draw attempts

      socket.to(`class:${data.classId}`).emit('whiteboard:draw', data.stroke);
    });

    socket.on('whiteboard:clear', (data: { classId: string }) => {
      const canDraw = isHost || (roomBoardGrantedStudents.get(data.classId)?.has(user.userId) ?? false);
      if (!canDraw) return; // Enforce: reject unauthorized clear attempts

      socket.to(`class:${data.classId}`).emit('whiteboard:clear');
    });

    socket.on('whiteboard:cursor', (data: { classId: string; x: number; y: number }) => {
      socket.to(`class:${data.classId}`).emit('whiteboard:cursor', {
        userId: user.userId,
        userName: user.name,
        x: data.x,
        y: data.y,
      });
    });

    // Host toggles board open/close for all students
    socket.on('board:toggle', (data: { classId: string; isOpen: boolean }) => {
      if (!isHost) return;
      roomBoardStates.set(data.classId, data.isOpen);
      io.to(`class:${data.classId}`).emit('board:state', { isOpen: data.isOpen });
    });

    // Host grants student drawing permission
    socket.on('board:permission:grant', (data: { classId: string; studentId: string }) => {
      if (!isHost) return;
      let grantedSet = roomBoardGrantedStudents.get(data.classId);
      if (!grantedSet) {
        grantedSet = new Set<string>();
        roomBoardGrantedStudents.set(data.classId, grantedSet);
      }
      grantedSet.add(data.studentId);
      io.to(`class:${data.classId}`).emit('board:permission', {
        studentId: data.studentId,
        canDraw: true,
      });
    });

    // Host revokes student drawing permission
    socket.on('board:permission:revoke', (data: { classId: string; studentId: string }) => {
      if (!isHost) return;
      const grantedSet = roomBoardGrantedStudents.get(data.classId);
      if (grantedSet) {
        grantedSet.delete(data.studentId);
      }
      io.to(`class:${data.classId}`).emit('board:permission', {
        studentId: data.studentId,
        canDraw: false,
      });
    });

    /* -------------------------------------------------------------------------- */
    /* PARTICIPANT MEDIA STATE BROADCAST (CAM/MIC/SPEAKING)                       */
    /* -------------------------------------------------------------------------- */
    socket.on('media:state', (data: { classId: string; isMicMuted: boolean; isCameraOff: boolean }) => {
      socket.to(`class:${data.classId}`).emit('peer:media:state', {
        userId: user.userId,
        isMicMuted: data.isMicMuted,
        isCameraOff: data.isCameraOff,
      });
    });

    /* -------------------------------------------------------------------------- */
    /* WEBRTC P2P SIGNALING RELAY (FALLBACK / DIRECT SFU STREAMING)               */
    /* -------------------------------------------------------------------------- */
    socket.on('signal:offer', (data: { classId: string; sdp: any; targetUserId?: string }) => {
      if (data.targetUserId) {
        socket.to(`user:${data.targetUserId}`).emit('signal:offer', {
          senderId: user.userId,
          senderName: user.name,
          sdp: data.sdp,
        });
      } else {
        socket.to(`class:${data.classId}`).emit('signal:offer', {
          senderId: user.userId,
          senderName: user.name,
          sdp: data.sdp,
        });
      }
    });

    socket.on('signal:answer', (data: { classId: string; sdp: any; targetUserId?: string }) => {
      if (data.targetUserId) {
        socket.to(`user:${data.targetUserId}`).emit('signal:answer', {
          senderId: user.userId,
          senderName: user.name,
          sdp: data.sdp,
        });
      } else {
        socket.to(`class:${data.classId}`).emit('signal:answer', {
          senderId: user.userId,
          senderName: user.name,
          sdp: data.sdp,
        });
      }
    });

    socket.on('signal:candidate', (data: { classId: string; candidate: any; targetUserId?: string }) => {
      if (data.targetUserId) {
        socket.to(`user:${data.targetUserId}`).emit('signal:candidate', {
          senderId: user.userId,
          candidate: data.candidate,
        });
      } else {
        socket.to(`class:${data.classId}`).emit('signal:candidate', {
          senderId: user.userId,
          candidate: data.candidate,
        });
      }
    });

    /* -------------------------------------------------------------------------- */
    /* IN-CLASS REALTIME CHAT (PERSISTED LAST 50 MESSAGES)                        */
    /* -------------------------------------------------------------------------- */
    socket.on('chat:send', (data: { classId: string; text: string }) => {
      if (!data.text || data.text.trim().length === 0) return;

      const message: ChatMessage = {
        id: `msg_${Date.now()}_${Math.random().toString(36).slice(2, 6)}`,
        senderId: user.userId,
        senderName: user.name,
        senderRole: user.role,
        text: data.text.trim(),
        timestamp: new Date().toISOString(),
      };

      // Persist last 50 messages per class
      const history = roomChatHistory.get(data.classId) || [];
      history.push(message);
      if (history.length > 50) history.shift();
      roomChatHistory.set(data.classId, history);

      io.to(`class:${data.classId}`).emit('chat:message', message);
    });

    /* -------------------------------------------------------------------------- */
    /* HAND RAISE QUEUE                                                           */
    /* -------------------------------------------------------------------------- */
    socket.on('hand:raise', (data: { classId: string }) => {
      const classId = data.classId;
      const current = roomHandQueues.get(classId) || [];

      if (!current.some((h) => h.userId === user.userId)) {
        current.push({
          userId: user.userId,
          userName: user.name,
          userRole: user.role,
          raisedAt: new Date().toISOString(),
        });
        roomHandQueues.set(classId, current);
        io.to(`class:${classId}`).emit('hand:queue', { hands: current });
      }
    });

    socket.on('hand:lower', (data: { classId: string; targetUserId?: string }) => {
      const classId = data.classId;
      let current = roomHandQueues.get(classId) || [];

      // If host lowering a student's hand, or student lowering their own
      const targetId =
        user.role === 'TEACHER' || user.role === 'ADMIN'
          ? data.targetUserId || user.userId
          : user.userId;

      current = current.filter((h) => h.userId !== targetId);
      roomHandQueues.set(classId, current);
      io.to(`class:${classId}`).emit('hand:queue', { hands: current });
    });

    /* -------------------------------------------------------------------------- */
    /* LIVE POLLS                                                                 */
    /* -------------------------------------------------------------------------- */
    socket.on(
      'poll:create',
      (data: { classId: string; question: string; options: string[] }) => {
        if (user.role !== 'TEACHER' && user.role !== 'ADMIN') return;

        const classId = data.classId;
        const newPoll: Poll = {
          id: `poll_${Date.now()}`,
          question: data.question.trim(),
          options: data.options.map((opt, idx) => ({ id: idx, text: opt.trim(), votes: 0 })),
          createdBy: user.name,
          active: true,
          votedUserIds: [],
        };

        const currentPolls = roomActivePolls.get(classId) || [];
        currentPolls.unshift(newPoll);
        roomActivePolls.set(classId, currentPolls);

        io.to(`class:${classId}`).emit('poll:started', newPoll);
      }
    );

    socket.on('poll:vote', (data: { classId: string; pollId: string; optionId: number }) => {
      const classId = data.classId;
      const polls = roomActivePolls.get(classId) || [];
      const poll = polls.find((p) => p.id === data.pollId);

      if (poll && poll.active && !poll.votedUserIds.includes(user.userId)) {
        poll.votedUserIds.push(user.userId);
        const option = poll.options.find((o) => o.id === data.optionId);
        if (option) {
          option.votes += 1;
        }
        io.to(`class:${classId}`).emit('poll:updated', poll);
      }
    });

    socket.on('poll:close', (data: { classId: string; pollId: string }) => {
      if (user.role !== 'TEACHER' && user.role !== 'ADMIN') return;

      const classId = data.classId;
      const polls = roomActivePolls.get(classId) || [];
      const poll = polls.find((p) => p.id === data.pollId);

      if (poll) {
        poll.active = false;
        io.to(`class:${classId}`).emit('poll:ended', poll);
      }
    });

    /* -------------------------------------------------------------------------- */
    /* DOUBTS BOX                                                                 */
    /* -------------------------------------------------------------------------- */
    socket.on('doubt:submit', (data: { classId: string; question: string }) => {
      const doubt = {
        id: `dbt_${Date.now()}`,
        studentId: user.userId,
        studentName: user.name,
        question: data.question.trim(),
        resolved: false,
        timestamp: new Date().toISOString(),
      };

      io.to(`class:${data.classId}`).emit('doubt:new', doubt);
    });

    socket.on('doubt:resolve', (data: { classId: string; doubtId: string }) => {
      if (user.role !== 'TEACHER' && user.role !== 'ADMIN') return;

      io.to(`class:${data.classId}`).emit('doubt:resolved', {
        doubtId: data.doubtId,
        resolvedBy: user.name,
      });
    });

    socket.on('disconnect', () => {
      if (socket.data.currentClassId) {
        const classId = socket.data.currentClassId;
        // Clean up hand raise if student leaves
        let hands = roomHandQueues.get(classId) || [];
        hands = hands.filter((h) => h.userId !== user.userId);
        roomHandQueues.set(classId, hands);
        io.to(`class:${classId}`).emit('hand:queue', { hands });

        // Emit peer:left
        io.to(`class:${classId}`).emit('peer:left', { userId: user.userId, name: user.name });

        // If host disconnected from active class, schedule 10-min timeout
        if (isHost && !hostDisconnectTimers.has(classId)) {
          const timer = setTimeout(async () => {
            try {
              await prisma.liveClass.updateMany({
                where: { id: classId, status: 'LIVE' },
                data: { status: 'ENDED' },
              });
              io.to(`class:${classId}`).emit('class:ended', { reason: 'HOST_TIMEOUT' });
            } catch (err) {
              console.error('Error auto-ending class on host disconnect timeout:', err);
            } finally {
              hostDisconnectTimers.delete(classId);
            }
          }, 10 * 60 * 1000);
          timer.unref();
          hostDisconnectTimers.set(classId, timer);
        }
      }
    });
  });
}

export function resetSocketGatewayState(): void {
  for (const timer of hostDisconnectTimers.values()) {
    clearTimeout(timer);
  }
  hostDisconnectTimers.clear();
  roomHandQueues.clear();
  roomActivePolls.clear();
  roomBoardGrantedStudents.clear();
  roomBoardStates.clear();
  roomChatHistory.clear();
}
