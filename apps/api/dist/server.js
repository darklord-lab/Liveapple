"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const http_1 = __importDefault(require("http"));
const socket_io_1 = require("socket.io");
const app_js_1 = require("./app.js");
const env_js_1 = require("./config/env.js");
const prisma_js_1 = require("./utils/prisma.js");
const socket_js_1 = require("./gateway/socket.js");
const scheduler_service_js_1 = require("./services/scheduler.service.js");
async function bootstrap() {
    await (0, prisma_js_1.initializePrisma)();
    const app = (0, app_js_1.createApp)();
    const server = http_1.default.createServer(app);
    const io = new socket_io_1.Server(server, {
        cors: {
            origin: '*',
            methods: ['GET', 'POST'],
        },
    });
    // Setup Realtime Gateway (Whiteboard, Chat, Polls, Hand Raise, Doubts)
    (0, socket_js_1.setupSocketGateway)(io);
    // Start 15-minute upcoming class reminder scheduler
    scheduler_service_js_1.SchedulerService.startReminderScheduler(60000);
    const PORT = env_js_1.env.PORT;
    server.listen(PORT, () => {
        console.log(`\n======================================================`);
        console.log(`🚀 Classora 2.0 API & Security Gateway running on:`);
        console.log(`   http://localhost:${PORT}`);
        console.log(`   Environment: ${env_js_1.env.NODE_ENV}`);
        console.log(`   Database: SQLite + Prisma ORM (WAL + FK ON)`);
        console.log(`   LiveKit SFU Configured: ${env_js_1.env.LIVEKIT_URL}`);
        console.log(`======================================================\n`);
    });
}
bootstrap().catch((err) => {
    console.error('Fatal Server Bootstrap Error:', err);
    process.exit(1);
});
