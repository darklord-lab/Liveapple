import express, { Express } from 'express';
import helmet from 'helmet';
import cors from 'cors';
import path from 'path';
import fs from 'fs';
import { env } from './config/env.js';
import { errorHandler } from './middlewares/errorHandler.js';
import { apiLimiter } from './middlewares/rateLimiter.js';
import routes from './routes/index.js';
import { AppError } from './errors/AppError.js';

export function createApp(): Express {
  const app = express();

  // Trust first proxy (Cloudflare tunnel, reverse proxies)
  app.set('trust proxy', 1);

  // 1. Security Headers
  app.use(helmet({ contentSecurityPolicy: false }));

  // 2. CORS Allowlist
  const allowedOrigins = env.CORS_ORIGINS.split(',').map((o) => o.trim());
  app.use(
    cors({
      origin: (origin, callback) => {
        // Allow mobile apps, postman, and localhost without origin header
        if (!origin || allowedOrigins.includes(origin) || env.NODE_ENV !== 'production') {
          callback(null, true);
        } else {
          callback(new AppError('FORBIDDEN', 'Blocked by CORS policy', 403));
        }
      },
      credentials: true,
      methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization', 'X-Device-Id'],
    })
  );

  // 3. Body parsers
  app.use(express.json({ limit: '5mb' }));
  app.use(express.urlencoded({ extended: true, limit: '5mb' }));

  // 4. General API Rate Limiting (exclude health checks)
  app.use('/api', (req, res, next) => {
    if (req.path === '/health') return next();
    return apiLimiter(req, res, next);
  });

  // 5. API Routes
  app.use('/api', routes);

  // 6. Serve Web Admin Console
  const candidatePaths = [
    path.resolve(process.cwd(), 'admin-dist'),
    path.resolve(process.cwd(), '../admin-dist'),
    path.resolve(process.cwd(), '../../_archive/admin/dist'),
    path.resolve(process.cwd(), '../_archive/admin/dist'),
    path.resolve(process.cwd(), '_archive/admin/dist'),
  ];
  const adminDist = candidatePaths.find((p) => fs.existsSync(p));
  if (adminDist) {
    app.use('/admin', express.static(adminDist));
    app.get('/admin', (_req, res) => {
      res.redirect('/admin/');
    });
    app.get('/admin/*', (_req, res) => {
      res.sendFile(path.join(adminDist, 'index.html'));
    });
  }

  // 7. 404 Catch-All
  app.use((_req, _res, next) => {
    next(new AppError('NOT_FOUND', 'The requested resource was not found on this server', 404));
  });

  // 8. Global Error Handler
  app.use(errorHandler);

  return app;
}

export default createApp;
