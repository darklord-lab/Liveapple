import { prisma } from '../utils/prisma.js';
import { hashPassword, verifyPassword, hashToken, generateRandomToken } from '../utils/hash.js';
import { signAccessToken, TokenUserPayload } from '../utils/jwt.js';
import { AppError } from '../errors/AppError.js';
import { env } from '../config/env.js';
import { logAudit } from './audit.service.js';

export interface LoginParams {
  email: string;
  password: string;
  deviceId?: string;
}

export interface AuthResult {
  accessToken: string;
  refreshToken: string;
  user: {
    id: string;
    instituteId: string;
    role: 'ADMIN' | 'TEACHER' | 'STUDENT';
    name: string;
    email: string;
    phone: string | null;
    status: string;
    coachingName?: string | null;
    centreLogo?: string | null;
    centreAddress?: string | null;
    contactPhone?: string | null;
    bio?: string | null;
    subjects?: string | null;
  };
  institute: {
    id: string;
    name: string;
    slug: string;
  };
  teacher?: {
    id: string;
    name: string;
    email: string;
    phone: string | null;
    coachingName: string | null;
    centreLogo: string | null;
    centreAddress: string | null;
    contactPhone: string | null;
    bio: string | null;
    subjects: string | null;
  } | null;
}

export class AuthService {
  /**
   * Login with email and password
   */
  static async login(params: LoginParams): Promise<AuthResult> {
    const email = params.email.toLowerCase().trim();

    const user = await prisma.user.findFirst({
      where: { email },
      include: {
        institute: true,
        creatorTeacher: true,
      },
    });

    if (!user) {
      throw new AppError('UNAUTHORIZED', 'Invalid email or password', 401);
    }

    if (user.status === 'SUSPENDED') {
      throw new AppError('FORBIDDEN', 'Your account has been suspended. Please contact your institute admin.', 403);
    }

    const isValid = await verifyPassword(user.passwordHash, params.password);
    if (!isValid) {
      throw new AppError('UNAUTHORIZED', 'Invalid email or password', 401);
    }

    // 1. Generate Access Token (15m)
    const tokenPayload: TokenUserPayload = {
      userId: user.id,
      instituteId: user.instituteId,
      role: user.role as 'ADMIN' | 'TEACHER' | 'STUDENT',
      email: user.email,
      name: user.name,
    };
    const accessToken = signAccessToken(tokenPayload);

    // 2. Generate and Store Hashed Refresh Token (30 days)
    const rawRefreshToken = generateRandomToken(32);
    const tokenHash = hashToken(rawRefreshToken);
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + env.JWT_REFRESH_EXPIRES_DAYS);

    await prisma.refreshToken.create({
      data: {
        instituteId: user.instituteId,
        userId: user.id,
        tokenHash,
        deviceId: params.deviceId || null,
        expiresAt,
      },
    });

    // 3. Log Audit
    await logAudit({
      instituteId: user.instituteId,
      actorId: user.id,
      action: 'USER_LOGIN',
      entity: 'AUTH',
      meta: { email: user.email, deviceId: params.deviceId },
    });

    return {
      accessToken,
      refreshToken: rawRefreshToken,
      tokens: {
        accessToken,
        refreshToken: rawRefreshToken,
      },
      user: {
        id: user.id,
        instituteId: user.instituteId,
        role: user.role as 'ADMIN' | 'TEACHER' | 'STUDENT',
        name: user.name,
        email: user.email,
        phone: user.phone,
        status: user.status,
        coachingName: user.coachingName,
        centreLogo: user.centreLogo,
        centreAddress: user.centreAddress,
        contactPhone: user.contactPhone,
        bio: user.bio,
        subjects: user.subjects,
      },
      institute: {
        id: user.institute.id,
        name: user.institute.name,
        slug: user.institute.slug,
      },
      teacher: user.creatorTeacher
        ? {
            id: user.creatorTeacher.id,
            name: user.creatorTeacher.name,
            email: user.creatorTeacher.email,
            phone: user.creatorTeacher.phone,
            coachingName: user.creatorTeacher.coachingName,
            centreLogo: user.creatorTeacher.centreLogo,
            centreAddress: user.creatorTeacher.centreAddress,
            contactPhone: user.creatorTeacher.contactPhone,
            bio: user.creatorTeacher.bio,
            subjects: user.creatorTeacher.subjects,
          }
        : user.role === 'TEACHER'
        ? {
            id: user.id,
            name: user.name,
            email: user.email,
            phone: user.phone,
            coachingName: user.coachingName,
            centreLogo: user.centreLogo,
            centreAddress: user.centreAddress,
            contactPhone: user.contactPhone,
            bio: user.bio,
            subjects: user.subjects,
          }
        : null,
    };
  }

  /**
   * Refresh Token Rotation with Reuse Detection
   */
  static async refresh(refreshToken: string, deviceId?: string): Promise<{ accessToken: string; refreshToken: string }> {
    if (!refreshToken) {
      throw new AppError('UNAUTHORIZED', 'Refresh token required', 401);
    }

    const tokenHash = hashToken(refreshToken);

    const storedToken = await prisma.refreshToken.findUnique({
      where: { tokenHash },
      include: { user: true },
    });

    // SECURITY: If token is not found or already revoked -> REUSE DETECTED!
    if (!storedToken || storedToken.revokedAt !== null) {
      if (storedToken) {
        // Revoke ALL active refresh tokens for this user across all devices
        await prisma.refreshToken.updateMany({
          where: {
            userId: storedToken.userId,
            revokedAt: null,
          },
          data: {
            revokedAt: new Date(),
          },
        });

        await logAudit({
          instituteId: storedToken.instituteId,
          actorId: storedToken.userId,
          action: 'TOKEN_REUSE_SECURITY_ALERT',
          entity: 'AUTH',
          meta: { tokenHash },
        });
      }

      throw new AppError(
        'TOKEN_REUSED',
        'Security Alert: Compromised refresh token detected. All active sessions have been revoked.',
        401
      );
    }

    // Check expiration
    if (storedToken.expiresAt < new Date()) {
      await prisma.refreshToken.update({
        where: { id: storedToken.id },
        data: { revokedAt: new Date() },
      });
      throw new AppError('TOKEN_EXPIRED', 'Refresh token has expired. Please log in again.', 401);
    }

    // ROTATION: Revoke old token
    await prisma.refreshToken.update({
      where: { id: storedToken.id },
      data: { revokedAt: new Date() },
    });

    // Generate NEW refresh token
    const newRawRefreshToken = generateRandomToken(32);
    const newTokenHash = hashToken(newRawRefreshToken);
    const newExpiresAt = new Date();
    newExpiresAt.setDate(newExpiresAt.getDate() + env.JWT_REFRESH_EXPIRES_DAYS);

    await prisma.refreshToken.create({
      data: {
        instituteId: storedToken.instituteId,
        userId: storedToken.userId,
        tokenHash: newTokenHash,
        deviceId: deviceId || storedToken.deviceId,
        expiresAt: newExpiresAt,
      },
    });

    // Generate NEW Access Token
    const user = storedToken.user;
    const tokenPayload: TokenUserPayload = {
      userId: user.id,
      instituteId: user.instituteId,
      role: user.role as 'ADMIN' | 'TEACHER' | 'STUDENT',
      email: user.email,
      name: user.name,
    };
    const accessToken = signAccessToken(tokenPayload);

    return {
      accessToken,
      refreshToken: newRawRefreshToken,
    };
  }

  /**
   * Logout and revoke refresh token
   */
  static async logout(refreshToken?: string, userId?: string): Promise<void> {
    if (refreshToken) {
      const tokenHash = hashToken(refreshToken);
      await prisma.refreshToken.updateMany({
        where: { tokenHash, revokedAt: null },
        data: { revokedAt: new Date() },
      });
    } else if (userId) {
      await prisma.refreshToken.updateMany({
        where: { userId, revokedAt: null },
        data: { revokedAt: new Date() },
      });
    }
  }

  /**
   * Accept Invite & Set Password
   */
  static async acceptInvite(params: {
    inviteCode: string;
    password: string;
    name?: string;
    phone?: string;
    deviceId?: string;
  }): Promise<AuthResult> {
    const codeHash = hashToken(params.inviteCode.trim());

    const invite = await prisma.invite.findUnique({
      where: { codeHash },
      include: { institute: true },
    });

    if (!invite) {
      throw new AppError('INVALID_INVITE', 'Invite link or code is invalid', 400);
    }

    if (invite.usedAt !== null) {
      throw new AppError('INVITE_ALREADY_USED', 'This invite code has already been used', 400);
    }

    if (invite.expiresAt < new Date()) {
      throw new AppError('INVITE_EXPIRED', 'This invite code has expired (48-hour limit)', 400);
    }

    const email = invite.email?.toLowerCase().trim();
    if (!email) {
      throw new AppError('BAD_REQUEST', 'Invite does not have an associated email', 400);
    }

    // Check if user already exists in this institute
    const existingUser = await prisma.user.findFirst({
      where: { instituteId: invite.instituteId, email },
    });

    const passwordHash = await hashPassword(params.password);
    let user;

    if (existingUser) {
      user = await prisma.user.update({
        where: { id: existingUser.id },
        data: {
          passwordHash,
          name: params.name?.trim() || existingUser.name,
          phone: params.phone?.trim() || existingUser.phone,
          status: 'ACTIVE',
        },
        include: { institute: true },
      });
    } else {
      user = await prisma.user.create({
        data: {
          instituteId: invite.instituteId,
          email,
          role: invite.role,
          name: params.name?.trim() || email.split('@')[0],
          phone: params.phone?.trim() || invite.phone,
          passwordHash,
          status: 'ACTIVE',
        },
        include: { institute: true },
      });
    }

    // Mark invite as used
    await prisma.invite.update({
      where: { id: invite.id },
      data: { usedAt: new Date() },
    });

    // 1. Generate Access Token
    const tokenPayload: TokenUserPayload = {
      userId: user.id,
      instituteId: user.instituteId,
      role: user.role as 'ADMIN' | 'TEACHER' | 'STUDENT',
      email: user.email,
      name: user.name,
    };
    const accessToken = signAccessToken(tokenPayload);

    // 2. Generate Refresh Token
    const rawRefreshToken = generateRandomToken(32);
    const tokenHash = hashToken(rawRefreshToken);
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + env.JWT_REFRESH_EXPIRES_DAYS);

    await prisma.refreshToken.create({
      data: {
        instituteId: user.instituteId,
        userId: user.id,
        tokenHash,
        deviceId: params.deviceId || null,
        expiresAt,
      },
    });

    await logAudit({
      instituteId: user.instituteId,
      actorId: user.id,
      action: 'INVITE_ACCEPTED',
      entity: 'AUTH',
      meta: { inviteId: invite.id, role: invite.role },
    });

    return {
      accessToken,
      refreshToken: rawRefreshToken,
      user: {
        id: user.id,
        instituteId: user.instituteId,
        role: user.role as 'ADMIN' | 'TEACHER' | 'STUDENT',
        name: user.name,
        email: user.email,
        phone: user.phone,
        status: user.status,
      },
      institute: {
        id: user.institute.id,
        name: user.institute.name,
        slug: user.institute.slug,
      },
    };
  }
}
