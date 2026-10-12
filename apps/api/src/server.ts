import http from 'http';
import { Server } from 'socket.io';
import { createApp } from './app.js';
import { env } from './config/env.js';
import { initializePrisma } from './utils/prisma.js';

import { setupSocketGateway } from './gateway/socket.js';
import { SchedulerService } from './services/scheduler.service.js';

async function bootstrap() {
  await initializePrisma();

  const app = createApp();
  const server = http.createServer(app);

  const io = new Server(server, {
    cors: {
      origin: '*',
      methods: ['GET', 'POST'],
    },
  });

  // Setup Realtime Gateway (Whiteboard, Chat, Polls, Hand Raise, Doubts)
  setupSocketGateway(io);

  // Start 15-minute upcoming class reminder scheduler
  SchedulerService.startReminderScheduler(60000);

  const PORT = env.PORT;
  server.listen(PORT, () => {
    console.log(`\n======================================================`);
    console.log(`🚀 Classora 2.0 API & Security Gateway running on:`);
    console.log(`   http://localhost:${PORT}`);
    console.log(`   Environment: ${env.NODE_ENV}`);
    console.log(`   Database: SQLite + Prisma ORM (WAL + FK ON)`);
    console.log(`   LiveKit SFU Configured: ${env.LIVEKIT_URL}`);
    console.log(`======================================================\n`);
  });
}

bootstrap().catch((err) => {
  console.error('Fatal Server Bootstrap Error:', err);
  process.exit(1);
});
