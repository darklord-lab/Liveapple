import { Request, Response, NextFunction } from 'express';
import { verifyAccessToken } from '../utils/jwt.js';
import { AppError } from '../errors/AppError.js';

/**
 * Middleware: Authenticate Bearer JWT
 */
export function authenticate(req: Request, _res: Response, next: NextFunction): void {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw new AppError('UNAUTHORIZED', 'Authentication token required', 401);
  }

  const token = authHeader.substring(7);
  const payload = verifyAccessToken(token);

  req.user = {
    userId: payload.userId,
    id: payload.userId,
    instituteId: payload.instituteId,
    role: payload.role,
    email: payload.email,
    name: payload.name,
  } as any;

  next();
}

/**
 * Middleware: Role-Based Access Control (RBAC)
 */
export function requireRole(...allowedRoles: Array<'ADMIN' | 'TEACHER' | 'STUDENT' | Array<'ADMIN' | 'TEACHER' | 'STUDENT'>>) {
  const flattened = allowedRoles.flat() as Array<'ADMIN' | 'TEACHER' | 'STUDENT'>;
  return (req: Request, _res: Response, next: NextFunction): void => {
    if (!req.user) {
      throw new AppError('UNAUTHORIZED', 'Authentication required', 401);
    }

    if (!flattened.includes(req.user.role)) {
      throw new AppError(
        'FORBIDDEN',
        `Forbidden: Role ${req.user.role} does not have access to this resource`,
        403
      );
    }

    next();
  };
}

