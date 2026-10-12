import rateLimit from 'express-rate-limit';
import { AppError } from '../errors/AppError.js';

/**
 * Strict rate limiter for Authentication endpoints (Login, Invite Acceptance)
 * Allows max 20 requests per 15 minutes per IP
 */
export const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  validate: { xForwardedForHeader: false },
  handler: (_req, _res, next) => {
    next(new AppError('RATE_LIMIT_EXCEEDED', 'Too many authentication attempts, please try again after 15 minutes', 429));
  },
});

/**
 * General API rate limiter (100 req/min)
 */
export const apiLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  validate: { xForwardedForHeader: false },
  handler: (_req, _res, next) => {
    next(new AppError('RATE_LIMIT_EXCEEDED', 'Too many requests, please slow down', 429));
  },
});
