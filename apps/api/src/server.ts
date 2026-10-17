import http from 'http';
import { Server } from 'socket.io';
import { createApp } from './app.js';
import { env, validateLiveKitOnStartup } from './config/env.js';
import { initializePrisma } from './utils/prisma.js';

import { setupSocketGateway } from './gateway/socket.js';
import { SchedulerService } from './services/scheduler.service.js';

/**
 * Self-ping keep-alive: prevents Render free tier from sleeping.
 * Sends a GET /api/health request to itself every 60 seconds.
 * Only runs in production when APP_URL env var is set.
 */
function startKeepAlive(appUrl: string) {
  const healthUrl = `${appUrl.replace(/\/$/, '')}/api/health`;
  console.log(`[KeepAlive] 🟢 Self-ping active → ${healthUrl} (every 60s)`);

  setInterval(async () => {
    try {
      const res = await fetch(healthUrl, { signal: AbortSignal.timeout(10000) });
      if (res.ok) {
        console.log(`[KeepAlive] ✅ Ping OK (${new Date().toISOString()})`);
      } else {
        console.warn(`[KeepAlive] ⚠️ Ping responded ${res.status}`);
      }
    } catch (err: any) {
      console.warn(`[KeepAlive] ❌ Ping failed: ${err?.message ?? err}`);
    }
  }, 60_000); // every 60 seconds
}

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
    validateLiveKitOnStartup();
    console.log(`[Config] Risky flags: FORCE_DEMO_RESET=${process.env.FORCE_DEMO_RESET === 'true'}, ALLOW_DESTRUCTIVE_DEMO_RESET=${process.env.ALLOW_DESTRUCTIVE_DEMO_RESET === 'true'}, ALLOW_DEMO_USERS=${process.env.ALLOW_DEMO_USERS === 'true'}`);
    console.log(`======================================================\n`);

    // Start self-ping keep-alive only in production when APP_URL is configured
    if (env.NODE_ENV === 'production' && env.APP_URL) {
      startKeepAlive(env.APP_URL);
    }
  });
}

bootstrap().catch((err) => {
  console.error('Fatal Server Bootstrap Error:', err);
  process.exit(1);
});
