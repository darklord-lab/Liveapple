import express, { Request, Response } from 'express';
import http from 'http';
import { Server, Socket } from 'socket.io';
import cors from 'cors';
import { PrismaClient } from '@prisma/client';
import {
  initialAssignments,
  initialTests,
  initialFeePlans,
  initialFeeTransactions,
} from './mockData.js';

const prisma = new PrismaClient();
const app = express();
const server = http.createServer(app);

const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
  },
});

app.use(cors());
app.use(express.json());

// In-memory fallback for fee & test mock records
const assignments = [...initialAssignments];
const tests = [...initialTests];
const feePlans = [...initialFeePlans];
const feeTransactions = [...initialFeeTransactions];

// Digital board pages & interaction state cache
const roomBoardPages: Record<string, any[]> = {};
const roomPolls: Record<string, any> = {};
const roomDoubts: Record<string, any[]> = {};
// Map roomId -> broadcasterSocketId
const roomBroadcasters: Record<string, string> = {};

// Health check
app.get('/api/health', (_req: Request, res: Response) => {
  res.json({
    status: 'ok',
    service: 'Classora API & Real-time Live Gateway',
    version: '2.0.0',
    theme: 'light',
    database: 'Prisma + SQLite (Persistent)',
  });
});

// Tenancy & Institute
app.get('/api/v1/institute', async (_req: Request, res: Response) => {
  try {
    const institute = await prisma.institute.findFirst({
      include: {
        courses: true,
        batches: true,
      },
    });
    res.json({ institute });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Users
app.get('/api/v1/users', async (req: Request, res: Response) => {
  try {
    const role = req.query.role as string;
    const users = await prisma.user.findMany({
      where: role ? { role: role.toUpperCase() } : undefined,
      include: {
        enrollments: {
          include: {
            batch: true,
          },
        },
        taughtBatches: true,
      },
    });
    res.json({ users });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Students with batch details
app.get('/api/v1/students', async (_req: Request, res: Response) => {
  try {
    const students = await prisma.user.findMany({
      where: { role: 'STUDENT' },
      include: {
        enrollments: {
          include: {
            batch: {
              include: {
                course: true,
              },
            },
          },
        },
      },
    });
    res.json({ students });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Teachers
app.get('/api/v1/teachers', async (_req: Request, res: Response) => {
  try {
    const teachers = await prisma.user.findMany({
      where: { role: 'TEACHER' },
      include: {
        taughtBatches: true,
      },
    });
    res.json({ teachers });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Courses
app.get('/api/v1/courses', async (_req: Request, res: Response) => {
  try {
    const courses = await prisma.course.findMany({
      include: {
        batches: true,
      },
    });
    res.json({ courses });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Batches (with enrolled student counts and teacher details)
app.get('/api/v1/batches', async (_req: Request, res: Response) => {
  try {
    const batches = await prisma.batch.findMany({
      include: {
        course: true,
        teacher: true,
        enrollments: {
          include: {
            student: true,
          },
        },
        _count: {
          select: { enrollments: true, liveClasses: true },
        },
      },
    });
    res.json({ batches });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Specific batch with enrolled students
app.get('/api/v1/batches/:id/students', async (req: Request, res: Response) => {
  try {
    const enrollments = await prisma.batchEnrollment.findMany({
      where: { batchId: req.params.id },
      include: {
        student: true,
      },
    });
    res.json({ students: enrollments.map((e) => e.student) });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Live Classes (with Batch filtering and Student filtering)
app.get('/api/v1/live-classes', async (req: Request, res: Response) => {
  try {
    const { batchId, studentId, teacherId, status } = req.query;

    let targetBatchIds: string[] | undefined = undefined;

    if (batchId) {
      targetBatchIds = [String(batchId)];
    } else if (studentId) {
      // Find all batches this student is enrolled in
      const enrollments = await prisma.batchEnrollment.findMany({
        where: { studentId: String(studentId) },
        select: { batchId: true },
      });
      targetBatchIds = enrollments.map((e) => e.batchId);
    }

    const whereClause: any = {};
    if (targetBatchIds) {
      whereClause.batchId = { in: targetBatchIds };
    }
    if (teacherId) {
      whereClause.teacherId = String(teacherId);
    }
    if (status) {
      whereClause.status = String(status).toUpperCase();
    }

    const liveClasses = await prisma.liveClass.findMany({
      where: whereClause,
      include: {
        batch: {
          include: {
            course: true,
            _count: { select: { enrollments: true } },
          },
        },
        teacher: true,
      },
      orderBy: { scheduledAt: 'asc' },
    });

    res.json({ liveClasses });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Schedule a new Live Class (Teacher specifies batch, subject, time)
app.post('/api/v1/live-classes', async (req: Request, res: Response) => {
  try {
    const { batchId, title, subject, chapter, scheduledAt, teacherId } = req.body;

    // Default to first batch & teacher if not supplied
    let actualBatchId = batchId;
    let actualTeacherId = teacherId;

    if (!actualBatchId) {
      const firstBatch = await prisma.batch.findFirst();
      actualBatchId = firstBatch?.id || 'batch-jee-12';
    }

    if (!actualTeacherId) {
      const batch = await prisma.batch.findUnique({ where: { id: actualBatchId } });
      actualTeacherId = batch?.teacherId || 'usr-teacher-01';
    }

    const institute = await prisma.institute.findFirst();
    const roomId = `room-${Date.now()}`;

    const newClass = await prisma.liveClass.create({
      data: {
        instituteId: institute?.id || 'inst-apex-01',
        batchId: actualBatchId,
        teacherId: actualTeacherId,
        title: title || 'Live Interactive Class',
        subject: subject || 'Physics',
        chapter: chapter || 'General Topic',
        roomId,
        status: 'SCHEDULED',
        scheduledAt: scheduledAt ? new Date(scheduledAt) : new Date(),
      },
      include: {
        batch: {
          include: {
            course: true,
            _count: { select: { enrollments: true } },
          },
        },
        teacher: true,
      },
    });

    // Notify all connected clients in real-time
    io.emit('class-scheduled', newClass);

    res.status(201).json({ liveClass: newClass });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Start Live Class
app.post('/api/v1/live-classes/:id/start', async (req: Request, res: Response) => {
  try {
    const cls = await prisma.liveClass.update({
      where: { id: req.params.id },
      data: {
        status: 'LIVE',
        startedAt: new Date(),
      },
      include: {
        batch: true,
        teacher: true,
      },
    });

    io.emit('class-status-changed', { classId: cls.id, status: 'LIVE', roomId: cls.roomId });
    res.json({ liveClass: cls });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// End Live Class
app.post('/api/v1/live-classes/:id/end', async (req: Request, res: Response) => {
  try {
    const cls = await prisma.liveClass.update({
      where: { id: req.params.id },
      data: {
        status: 'COMPLETED',
        endedAt: new Date(),
        recordingUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      },
      include: {
        batch: true,
        teacher: true,
      },
    });

    io.emit('class-status-changed', { classId: cls.id, status: 'COMPLETED', roomId: cls.roomId });
    res.json({ liveClass: cls });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// LMS: Assignments
app.get('/api/v1/assignments', (_req: Request, res: Response) => {
  res.json({ assignments });
});

// LMS: Tests
app.get('/api/v1/tests', (_req: Request, res: Response) => {
  res.json({ tests });
});

// Fees
app.get('/api/v1/fees', (_req: Request, res: Response) => {
  res.json({ feePlans, feeTransactions });
});

// Socket.IO Real-Time Classroom, WebRTC Signaling & Digital Board
io.on('connection', (socket: Socket) => {
  console.log(`[Socket] Client connected: ${socket.id}`);

  socket.on('join-room', async ({ roomId, role, userName, userId }) => {
    socket.join(roomId);
    console.log(`[Socket] ${userName} (${role}) joined room: ${roomId}`);

    if (role === 'teacher' || role === 'TEACHER') {
      roomBroadcasters[roomId] = socket.id;
      // Tell everyone in room teacher is broadcasting
      io.to(roomId).emit('broadcaster-ready', { broadcasterSocketId: socket.id });
    } else {
      // If student joins and broadcaster is already present, notify teacher to send offer
      const broadcasterId = roomBroadcasters[roomId];
      if (broadcasterId) {
        io.to(broadcasterId).emit('webrtc-new-viewer', {
          viewerSocketId: socket.id,
          userName: userName || 'Student',
        });
        socket.emit('broadcaster-ready', { broadcasterSocketId: broadcasterId });
      }
    }

    // Broadcast user joined
    io.to(roomId).emit('user-joined', {
      userId: socket.id,
      userName,
      role,
      joinedAt: new Date().toISOString(),
    });

    // Send existing board state from memory or DB
    if (roomBoardPages[roomId]) {
      socket.emit('board-init', { pages: roomBoardPages[roomId] });
    } else {
      try {
        const savedPages = await prisma.boardPage.findMany({
          where: { roomId },
          orderBy: { pageIndex: 'asc' },
        });
        if (savedPages.length > 0) {
          const parsed = savedPages.map((p) => JSON.parse(p.elementsJson));
          roomBoardPages[roomId] = parsed;
          socket.emit('board-init', { pages: parsed });
        }
      } catch (e) {
        // ignore
      }
    }

    if (roomPolls[roomId]) {
      socket.emit('active-poll', roomPolls[roomId]);
    }

    if (roomDoubts[roomId]) {
      socket.emit('doubt-list', roomDoubts[roomId]);
    }
  });

  // ================= WebRTC Signaling Handlers =================
  // 1. Broadcaster sends SDP offer to specific student viewer
  socket.on('webrtc-offer', ({ targetSocketId, offer }) => {
    socket.to(targetSocketId).emit('webrtc-offer-received', {
      offer,
      broadcasterSocketId: socket.id,
    });
  });

  // 2. Student viewer sends SDP answer back to broadcaster
  socket.on('webrtc-answer', ({ broadcasterSocketId, answer }) => {
    socket.to(broadcasterSocketId).emit('webrtc-answer-received', {
      answer,
      viewerSocketId: socket.id,
    });
  });

  // 3. Exchange ICE candidates
  socket.on('webrtc-ice-candidate', ({ targetSocketId, candidate }) => {
    socket.to(targetSocketId).emit('webrtc-ice-candidate-received', {
      candidate,
      senderSocketId: socket.id,
    });
  });

  // Screen Share signaling
  socket.on('screen-share-started', ({ roomId }) => {
    socket.to(roomId).emit('screen-share-started', { broadcasterSocketId: socket.id });
  });

  socket.on('screen-share-stopped', ({ roomId }) => {
    socket.to(roomId).emit('screen-share-stopped');
  });

  // ================= Digital Board Sync Handlers =================
  socket.on('board-draw-stroke', ({ roomId, stroke }) => {
    socket.to(roomId).emit('board-stroke-received', stroke);
  });

  socket.on('board-sync-page', async ({ roomId, pageIndex, elements }) => {
    if (!roomBoardPages[roomId]) {
      roomBoardPages[roomId] = [];
    }
    roomBoardPages[roomId][pageIndex] = elements;
    socket.to(roomId).emit('board-page-updated', { pageIndex, elements });

    // Persist to database asynchronously
    try {
      await prisma.boardPage.upsert({
        where: {
          roomId_pageIndex: { roomId, pageIndex },
        },
        update: {
          elementsJson: JSON.stringify(elements),
        },
        create: {
          roomId,
          pageIndex,
          elementsJson: JSON.stringify(elements),
        },
      });
    } catch (e) {
      // ignore
    }
  });

  socket.on('board-clear', async ({ roomId, pageIndex }) => {
    if (roomBoardPages[roomId]) {
      roomBoardPages[roomId][pageIndex] = [];
    }
    socket.to(roomId).emit('board-cleared', { pageIndex });

    try {
      await prisma.boardPage.deleteMany({
        where: { roomId, pageIndex },
      });
    } catch (e) {
      // ignore
    }
  });

  // Laser Pointer (ephemeral)
  socket.on('laser-pointer', ({ roomId, x, y, active }) => {
    socket.to(roomId).emit('laser-pointer-moved', { x, y, active });
  });

  // Digital Board Document Layer Sync
  socket.on('board-doc-sync', ({ roomId, pageIndex, docUrl }) => {
    socket.to(roomId).emit('board-doc-updated', { pageIndex, docUrl });
  });

  // ================= Live Classroom Chat & Interactions =================
  socket.on('send-chat', async ({ roomId, sender, message, role }) => {
    const chatMsg = {
      id: `chat-${Date.now()}-${Math.random()}`,
      sender,
      message,
      role,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    };
    io.to(roomId).emit('receive-chat', chatMsg);

    try {
      await prisma.chatMessage.create({
        data: {
          roomId,
          senderName: sender,
          role,
          message,
        },
      });
    } catch (e) {
      // ignore
    }
  });

  // Doubts & Raise Hand
  socket.on('raise-doubt', ({ roomId, studentName, doubtText }) => {
    if (!roomDoubts[roomId]) roomDoubts[roomId] = [];
    const doubt = {
      id: `doubt-${Date.now()}`,
      studentName,
      doubtText,
      status: 'pending',
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    };
    roomDoubts[roomId].push(doubt);
    io.to(roomId).emit('doubt-list', roomDoubts[roomId]);
  });

  socket.on('resolve-doubt', ({ roomId, doubtId }) => {
    if (roomDoubts[roomId]) {
      const d = roomDoubts[roomId].find((item) => item.id === doubtId);
      if (d) d.status = 'resolved';
      io.to(roomId).emit('doubt-list', roomDoubts[roomId]);
    }
  });

  // Live Polls
  socket.on('launch-poll', ({ roomId, question, options }) => {
    const poll = {
      id: `poll-${Date.now()}`,
      question,
      options: options.map((opt: string) => ({ text: opt, votes: 0 })),
      totalVotes: 0,
      active: true,
    };
    roomPolls[roomId] = poll;
    io.to(roomId).emit('active-poll', poll);
  });

  socket.on('vote-poll', ({ roomId, optionIndex }) => {
    const poll = roomPolls[roomId];
    if (poll && poll.active) {
      if (poll.options[optionIndex]) {
        poll.options[optionIndex].votes += 1;
        poll.totalVotes += 1;
        io.to(roomId).emit('active-poll', poll);
      }
    }
  });

  socket.on('close-poll', ({ roomId }) => {
    if (roomPolls[roomId]) {
      roomPolls[roomId].active = false;
      io.to(roomId).emit('active-poll', roomPolls[roomId]);
    }
  });

  socket.on('disconnect', () => {
    // Check if disconnected socket was broadcaster
    for (const [roomId, bId] of Object.entries(roomBroadcasters)) {
      if (bId === socket.id) {
        delete roomBroadcasters[roomId];
        io.to(roomId).emit('broadcaster-left');
        break;
      }
    }
    console.log(`[Socket] Client disconnected: ${socket.id}`);
  });
});

const PORT = process.env.PORT || 4000;
server.listen(PORT, () => {
  console.log(`\n======================================================`);
  console.log(`🚀 Classora API & Real-time Live Gateway running on:`);
  console.log(`   http://localhost:${PORT}`);
  console.log(`   Database: SQLite + Prisma ORM (Persistent)`);
  console.log(`   Design Theme: Pure Light Theme`);
  console.log(`======================================================\n`);
});
