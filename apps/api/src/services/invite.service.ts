import { prisma } from '../utils/prisma.js';
import { generateRandomToken, hashToken } from '../utils/hash.js';
import { env } from '../config/env.js';
import { AppError } from '../errors/AppError.js';
import { logAudit } from './audit.service.js';

export interface CreateInviteParams {
  instituteId: string;
  actorId: string;
  email?: string;
  phone?: string;
  role: 'TEACHER' | 'STUDENT';
}

export class InviteService {
  /**
   * Create an Invite with 48h expiration and hashed one-time code
   */
  static async createInvite(params: CreateInviteParams) {
    const email = params.email?.toLowerCase().trim();
    const phone = params.phone?.trim();

    if (!email && !phone) {
      throw new AppError('BAD_REQUEST', 'Either email or phone is required for an invite', 400);
    }

    // Check if user already exists
    if (email) {
      const existingUser = await prisma.user.findFirst({
        where: { instituteId: params.instituteId, email },
      });
      if (existingUser && existingUser.status === 'ACTIVE') {
        throw new AppError('CONFLICT', `User with email ${email} is already active in this institute`, 409);
      }
    }

    const rawCode = generateRandomToken(16); // 32 hex chars
    const codeHash = hashToken(rawCode);

    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + env.INVITE_TOKEN_EXPIRES_HOURS);

    const invite = await prisma.invite.create({
      data: {
        instituteId: params.instituteId,
        email: email || null,
        phone: phone || null,
        role: params.role,
        codeHash,
        expiresAt,
      },
      include: {
        institute: true,
      },
    });

    await logAudit({
      instituteId: params.instituteId,
      actorId: params.actorId,
      action: 'INVITE_CREATED',
      entity: 'INVITE',
      meta: { inviteId: invite.id, email, role: params.role },
    });

    return {
      inviteId: invite.id,
      inviteCode: rawCode,
      email: invite.email,
      phone: invite.phone,
      role: invite.role,
      instituteName: invite.institute.name,
      expiresAt: invite.expiresAt,
    };
  }

  /**
   * Validate an invite code
   */
  static async validateInvite(rawCode: string) {
    const codeHash = hashToken(rawCode.trim());

    const invite = await prisma.invite.findUnique({
      where: { codeHash },
      include: { institute: true },
    });

    if (!invite) {
      throw new AppError('INVALID_INVITE', 'Invite code is invalid', 400);
    }

    if (invite.usedAt !== null) {
      throw new AppError('INVITE_ALREADY_USED', 'This invite code has already been used', 400);
    }

    if (invite.expiresAt < new Date()) {
      throw new AppError('INVITE_EXPIRED', 'This invite code has expired', 400);
    }

    return {
      valid: true,
      email: invite.email,
      phone: invite.phone,
      role: invite.role,
      instituteName: invite.institute.name,
      expiresAt: invite.expiresAt,
    };
  }

  /**
   * List pending invites for an institute
   */
  static async listInvites(instituteId: string) {
    return prisma.invite.findMany({
      where: { instituteId },
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        email: true,
        phone: true,
        role: true,
        expiresAt: true,
        usedAt: true,
        createdAt: true,
      },
    });
  }
}
