"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const http_1 = __importDefault(require("http"));
const socket_io_1 = require("socket.io");
const cors_1 = __importDefault(require("cors"));
const mockData_js_1 = require("./mockData.js");
const app = (0, express_1.default)();
const server = http_1.default.createServer(app);
const io = new socket_io_1.Server(server, {
    cors: {
        origin: '*',
        methods: ['GET', 'POST'],
    },
});
app.use((0, cors_1.default)());
app.use(express_1.default.json());
// In-memory data store for live state
const institutes = [...mockData_js_1.initialInstitutes];
const users = [...mockData_js_1.initialUsers];
const courses = [...mockData_js_1.initialCourses];
const batches = [...mockData_js_1.initialBatches];
const liveClasses = [...mockData_js_1.initialLiveClasses];
const assignments = [...mockData_js_1.initialAssignments];
const tests = [...mockData_js_1.initialTests];
const feePlans = [...mockData_js_1.initialFeePlans];
const feeTransactions = [...mockData_js_1.initialFeeTransactions];
// Digital board pages state per room
const roomBoardPages = {};
const roomPolls = {};
const roomDoubts = {};
// Health check
app.get('/api/health', (_req, res) => {
    res.json({
        status: 'ok',
        service: 'Classora API & Real-time Live Gateway',
        version: '2.0.0',
        theme: 'light',
    });
});
// Tenancy & Institute
app.get('/api/v1/institute', (_req, res) => {
    res.json({ institute: institutes[0] });
});
// Users
app.get('/api/v1/users', (req, res) => {
    const role = req.query.role;
    if (role) {
        return res.json({ users: users.filter((u) => u.role === role) });
    }
    res.json({ users });
});
app.post('/api/v1/users', (req, res) => {
    const newUser = {
        id: `usr-${Date.now()}`,
        institute_id: 'inst-apex-01',
        name: req.body.name || 'New User',
        email: req.body.email || `user${Date.now()}@apex.edu`,
        phone: req.body.phone || '+91 99999 00000',
        role: req.body.role || 'student',
        avatar_url: req.body.avatar_url || 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100&h=100&fit=crop',
        status: 'active',
        created_at: new Date().toISOString(),
    };
    users.push(newUser);
    res.status(201).json({ user: newUser });
});
// Courses & Batches
app.get('/api/v1/courses', (_req, res) => {
    res.json({ courses });
});
app.get('/api/v1/batches', (_req, res) => {
    res.json({ batches });
});
app.post('/api/v1/batches', (req, res) => {
    const newBatch = {
        id: `batch-${Date.now()}`,
        institute_id: 'inst-apex-01',
        name: req.body.name,
        course_id: req.body.course_id || courses[0].id,
        course_name: req.body.course_name || courses[0].name,
        teacher_name: req.body.teacher_name || 'Prof. Rajesh Sharma',
        student_count: 0,
        start_date: req.body.start_date || new Date().toISOString().split('T')[0],
        end_date: req.body.end_date || '2026-12-31',
    };
    batches.push(newBatch);
    res.status(201).json({ batch: newBatch });
});
// Live Classes
app.get('/api/v1/live-classes', (_req, res) => {
    res.json({ liveClasses });
});
app.post('/api/v1/live-classes', (req, res) => {
    const newClass = {
        id: `live-${Date.now()}`,
        institute_id: 'inst-apex-01',
        batch_id: req.body.batch_id || batches[0].id,
        batch_name: req.body.batch_name || batches[0].name,
        teacher_id: req.body.teacher_id || 'usr-teacher-01',
        teacher_name: req.body.teacher_name || 'Prof. Rajesh Sharma',
        subject_name: req.body.subject_name || 'Physics',
        chapter_id: req.body.chapter_id || 'ch-01',
        chapter_name: req.body.chapter_name || 'General Physics',
        title: req.body.title || 'Live Interactive Lecture',
        scheduled_at: req.body.scheduled_at || new Date().toISOString(),
        room_id: `room-${Date.now()}`,
        status: 'scheduled',
    };
    liveClasses.unshift(newClass);
    res.status(201).json({ liveClass: newClass });
});
app.post('/api/v1/live-classes/:id/start', (req, res) => {
    const cls = liveClasses.find((c) => c.id === req.params.id);
    if (!cls)
        return res.status(404).json({ error: 'Class not found' });
    cls.status = 'live';
    cls.started_at = new Date().toISOString();
    res.json({ liveClass: cls, token: `simulated-livekit-token-teacher-${cls.id}` });
});
app.post('/api/v1/live-classes/:id/end', (req, res) => {
    const cls = liveClasses.find((c) => c.id === req.params.id);
    if (!cls)
        return res.status(404).json({ error: 'Class not found' });
    cls.status = 'completed';
    cls.ended_at = new Date().toISOString();
    cls.duration_sec = 3600;
    cls.recording_url = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
    res.json({ liveClass: cls });
});
// LMS: Assignments
app.get('/api/v1/assignments', (_req, res) => {
    res.json({ assignments });
});
app.post('/api/v1/assignments', (req, res) => {
    const newAsg = {
        id: `asg-${Date.now()}`,
        institute_id: 'inst-apex-01',
        chapter_id: 'ch-01',
        chapter_name: req.body.chapter_name || 'Physics',
        subject_name: 'Physics',
        teacher_id: 'usr-teacher-01',
        title: req.body.title || 'Weekly Homework Problem Set',
        description: req.body.description || 'Solve problems and upload PDF.',
        due_date: req.body.due_date || new Date(Date.now() + 86400000 * 3).toISOString(),
        total_submissions: 0,
        pending_grading: 0,
    };
    assignments.unshift(newAsg);
    res.status(201).json({ assignment: newAsg });
});
// LMS: Tests
app.get('/api/v1/tests', (_req, res) => {
    res.json({ tests });
});
// Fees
app.get('/api/v1/fees', (_req, res) => {
    res.json({ feePlans, feeTransactions });
});
app.post('/api/v1/fees/pay', (req, res) => {
    const { student_id, amount } = req.body;
    const txn = {
        id: `pay_${Date.now()}`,
        institute_id: 'inst-apex-01',
        fee_plan_id: 'fee-plan-01',
        student_id: student_id || 'usr-student-01',
        student_name: 'Aarav Patel',
        course_name: 'Class 12th — IIT-JEE Masterclass',
        amount_paid: Number(amount) || 20000,
        total_amount: 65000,
        mode: 'Razorpay',
        txn_id: `rzp_${Math.random().toString(36).substring(2, 10).toUpperCase()}`,
        status: 'paid',
        paid_at: new Date().toISOString(),
    };
    feeTransactions.unshift(txn);
    res.json({ success: true, transaction: txn });
});
// Socket.IO Real-Time Classroom & Digital Board Handlers
io.on('connection', (socket) => {
    console.log(`[Socket] Client connected: ${socket.id}`);
    socket.on('join-room', ({ roomId, role, userName }) => {
        socket.join(roomId);
        console.log(`[Socket] ${userName} (${role}) joined room: ${roomId}`);
        // Broadcast user joined
        io.to(roomId).emit('user-joined', {
            userId: socket.id,
            userName,
            role,
            joinedAt: new Date().toISOString(),
        });
        // Send existing board state if exists
        if (roomBoardPages[roomId]) {
            socket.emit('board-init', { pages: roomBoardPages[roomId] });
        }
        if (roomPolls[roomId]) {
            socket.emit('active-poll', roomPolls[roomId]);
        }
        if (roomDoubts[roomId]) {
            socket.emit('doubt-list', roomDoubts[roomId]);
        }
    });
    // Digital Board real-time stroke/shape sync
    socket.on('board-draw-stroke', ({ roomId, stroke }) => {
        socket.to(roomId).emit('board-stroke-received', stroke);
    });
    socket.on('board-sync-page', ({ roomId, pageIndex, elements }) => {
        if (!roomBoardPages[roomId]) {
            roomBoardPages[roomId] = [];
        }
        roomBoardPages[roomId][pageIndex] = elements;
        socket.to(roomId).emit('board-page-updated', { pageIndex, elements });
    });
    socket.on('board-clear', ({ roomId, pageIndex }) => {
        if (roomBoardPages[roomId]) {
            roomBoardPages[roomId][pageIndex] = [];
        }
        socket.to(roomId).emit('board-cleared', { pageIndex });
    });
    // Laser Pointer (ephemeral)
    socket.on('laser-pointer', ({ roomId, x, y, active }) => {
        socket.to(roomId).emit('laser-pointer-moved', { x, y, active });
    });
    // Live Chat
    socket.on('send-chat', ({ roomId, sender, message, role }) => {
        const chatMsg = {
            id: `chat-${Date.now()}-${Math.random()}`,
            sender,
            message,
            role,
            timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
        };
        io.to(roomId).emit('receive-chat', chatMsg);
    });
    // Doubts & Raise Hand
    socket.on('raise-doubt', ({ roomId, studentName, doubtText }) => {
        if (!roomDoubts[roomId])
            roomDoubts[roomId] = [];
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
            if (d)
                d.status = 'resolved';
            io.to(roomId).emit('doubt-list', roomDoubts[roomId]);
        }
    });
    // Live Polls
    socket.on('launch-poll', ({ roomId, question, options }) => {
        const poll = {
            id: `poll-${Date.now()}`,
            question,
            options: options.map((opt) => ({ text: opt, votes: 0 })),
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
        console.log(`[Socket] Client disconnected: ${socket.id}`);
    });
});
const PORT = process.env.PORT || 4000;
server.listen(PORT, () => {
    console.log(`\n======================================================`);
    console.log(`🚀 Classora API & Real-time Live Gateway running on:`);
    console.log(`   http://localhost:${PORT}`);
    console.log(`   Design Theme: Pure Light Theme`);
    console.log(`======================================================\n`);
});
