import { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';
import { AppError } from '../errors/AppError.js';
import { Prisma } from '@prisma/client';

export function errorHandler(
  err: Error,
  _req: Request,
  res: Response,
  _next: NextFunction
): void {
  // 1. Handled AppError
  if (err instanceof AppError) {
    res.status(err.statusCode).json({
      code: err.code,
      message: err.message,
      ...(err.details ? { details: err.details } : {}),
    });
    return;
  }

  // 2. Zod Validation Error
  if (err instanceof ZodError || (err as any).name === 'ZodError') {
    const issues = (err as any).issues || (err as any).errors || [];
    const fieldErrors = Array.isArray(issues)
      ? issues.map((e: any) => ({
          path: Array.isArray(e.path) ? e.path.join('.') : String(e.path ?? ''),
          message: e.message || 'Invalid value',
        }))
      : [];

    res.status(400).json({
      code: 'BAD_REQUEST',
      message: 'Validation failed',
      details: fieldErrors,
    });
    return;
  }

  // 3. Prisma Known Request Error
  if (err instanceof Prisma.PrismaClientKnownRequestError) {
    if (err.code === 'P2002') {
      res.status(409).json({
        code: 'CONFLICT',
        message: 'A record with this unique field already exists',
        details: err.meta,
      });
      return;
    }
    if (err.code === 'P2025') {
      res.status(404).json({
        code: 'NOT_FOUND',
        message: 'The requested record does not exist',
      });
      return;
    }
  }

  // 4. Fallback Unexpected Server Error
  console.error('[Unhandled Error]:', err);
  res.status(500).json({
    code: 'INTERNAL_SERVER_ERROR',
    message: process.env.NODE_ENV === 'production' ? 'An unexpected server error occurred' : err.message,
  });
}
