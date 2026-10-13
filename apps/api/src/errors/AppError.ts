export type ErrorCode =
  | 'BAD_REQUEST'
  | 'UNAUTHORIZED'
  | 'FORBIDDEN'
  | 'NOT_FOUND'
  | 'CONFLICT'
  | 'UNPROCESSABLE_ENTITY'
  | 'RATE_LIMIT_EXCEEDED'
  | 'ACCOUNT_LOCKED'
  | 'INVALID_INVITE'
  | 'INVITE_EXPIRED'
  | 'INVITE_ALREADY_USED'
  | 'TOKEN_EXPIRED'
  | 'TOKEN_REUSED'
  | 'INVALID_FILE_TYPE'
  | 'FILE_TOO_LARGE'
  | 'ENROLLMENT_REQUIRED'
  | 'INTERNAL_SERVER_ERROR';

export class AppError extends Error {
  public readonly code: ErrorCode;
  public readonly statusCode: number;
  public readonly details?: unknown;

  constructor(code: ErrorCode, message: string, statusCode: number = 400, details?: unknown) {
    super(message);
    this.name = 'AppError';
    this.code = code;
    this.statusCode = statusCode;
    this.details = details;
    Object.setPrototypeOf(this, new.target.prototype);
  }

  static badRequest(message: string, details?: unknown): AppError {
    return new AppError('BAD_REQUEST', message, 400, details);
  }

  static unauthorized(message: string = 'Authentication required'): AppError {
    return new AppError('UNAUTHORIZED', message, 401);
  }

  static forbidden(message: string = 'Access denied'): AppError {
    return new AppError('FORBIDDEN', message, 403);
  }

  static notFound(message: string = 'Resource not found'): AppError {
    return new AppError('NOT_FOUND', message, 404);
  }

  static conflict(message: string): AppError {
    return new AppError('CONFLICT', message, 409);
  }

  static rateLimit(message: string = 'Too many requests, please try again later'): AppError {
    return new AppError('RATE_LIMIT_EXCEEDED', message, 429);
  }

  static accountLocked(message: string = 'Account is temporarily locked due to multiple failed login attempts'): AppError {
    return new AppError('ACCOUNT_LOCKED', message, 423);
  }

  static internal(message: string = 'Internal server error'): AppError {
    return new AppError('INTERNAL_SERVER_ERROR', message, 500);
  }
}
