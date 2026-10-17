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

/**
 * Institute code lookup rate limiter (30 req/min per IP) per RULES.md Section F.6
 */
export const instituteCodeLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  validate: { xForwardedForHeader: false },
  handler: (_req, _res, next) => {
    next(new AppError('RATE_LIMIT_EXCEEDED', 'Too many institute code lookup attempts, please wait a minute', 429));
  },
});

/**
 * File upload rate limiter (30 uploads per 10 minutes per IP)
 */
export const uploadLimiter = rateLimit({
  windowMs: 10 * 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  validate: { xForwardedForHeader: false },
  handler: (_req, _res, next) => {
    next(new AppError('RATE_LIMIT_EXCEEDED', 'Upload rate limit exceeded, please wait before uploading more files', 429));
  },
});

