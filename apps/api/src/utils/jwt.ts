import jwt, { SignOptions } from 'jsonwebtoken';
import { env } from '../config/env.js';
import { AppError } from '../errors/AppError.js';

export interface TokenUserPayload {
  userId: string;
  id?: string;
  instituteId: string;
  role: 'ADMIN' | 'TEACHER' | 'STUDENT';
  email: string;
  name: string;
}

export interface DecodedAccessToken extends TokenUserPayload {
  iat: number;
  exp: number;
}

/**
 * Signs a 15-minute Access JWT
 */
export function signAccessToken(payload: TokenUserPayload): string {
  payload.id = payload.userId;
  const options: SignOptions = {
    expiresIn: env.JWT_ACCESS_EXPIRES_IN as any,
  };
  return jwt.sign(payload, env.JWT_ACCESS_SECRET, options);
}

/**
 * Verifies and decodes an Access JWT
 */
export function verifyAccessToken(token: string): DecodedAccessToken {
  try {
    const decoded = jwt.verify(token, env.JWT_ACCESS_SECRET) as DecodedAccessToken;
    return decoded;
  } catch (err: any) {
    if (err.name === 'TokenExpiredError') {
      throw new AppError('TOKEN_EXPIRED', 'Access token has expired', 401);
    }
    throw new AppError('UNAUTHORIZED', 'Invalid access token', 401);
  }
}
