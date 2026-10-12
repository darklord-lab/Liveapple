import argon2 from 'argon2';
import crypto from 'crypto';

/**
 * Hash password with argon2id per security rules
 */
export async function hashPassword(password: string): Promise<string> {
  return argon2.hash(password, {
    type: argon2.argon2id,
    memoryCost: 65536,
    timeCost: 3,
    parallelism: 4,
  });
}

/**
 * Verify password against argon2 hash
 */
export async function verifyPassword(hash: string, plain: string): Promise<boolean> {
  try {
    return await argon2.verify(hash, plain);
  } catch {
    return false;
  }
}

/**
 * SHA-256 hash for storing refresh tokens and invite codes in database
 */
export function hashToken(token: string): string {
  return crypto.createHash('sha256').update(token).digest('hex');
}

/**
 * Generate secure random 128-bit hex token (for invites and refresh tokens)
 */
export function generateRandomToken(bytes: number = 32): string {
  return crypto.randomBytes(bytes).toString('hex');
}

/**
 * Generate clean human-readable join code (e.g. "PHY782", "MTH491")
 */
export function generateJoinCode(length: number = 6): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let result = '';
  const randomBytes = crypto.randomBytes(length);
  for (let i = 0; i < length; i++) {
    result += chars[randomBytes[i] % chars.length];
  }
  return result;
}

