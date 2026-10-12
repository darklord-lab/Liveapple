import { Request, Response, NextFunction } from 'express';
import { AppError } from '../errors/AppError.js';

/**
 * Middleware: Enforces tenant isolation.
 * Guarantees req.user exists and provides a helper for services.
 */
export function tenantGuard(req: Request, _res: Response, next: NextFunction): void {
  if (!req.user || !req.user.instituteId) {
    throw new AppError('UNAUTHORIZED', 'Tenant context missing or invalid', 401);
  }

  // If a client tries to pass an explicit instituteId in query/body, verify it matches token
  const queryTenant = req.query.instituteId as string | undefined;
  const bodyTenant = req.body?.instituteId as string | undefined;

  if (queryTenant && queryTenant !== req.user.instituteId) {
    throw new AppError('FORBIDDEN', 'Cross-tenant access prohibited', 403);
  }

  if (bodyTenant && bodyTenant !== req.user.instituteId) {
    throw new AppError('FORBIDDEN', 'Cross-tenant access prohibited', 403);
  }

  next();
}
