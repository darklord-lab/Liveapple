import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { AuthService } from '../services/auth.service.js';
import { prisma } from '../utils/prisma.js';
import { AppError } from '../errors/AppError.js';

const loginSchema = z.object({
  email: z.string().email('Valid email is required'),
  password: z.string().min(6, 'Password must be at least 6 characters'),
  deviceId: z.string().optional(),
});

const refreshSchema = z.object({
  refreshToken: z.string().min(1, 'Refresh token is required'),
  deviceId: z.string().optional(),
});

const acceptInviteSchema = z.object({
  inviteCode: z.string().min(1, 'Invite code is required'),
  password: z.string().min(6, 'Password must be at least 6 characters'),
  email: z.string().email().optional(),
  name: z.string().min(2, 'Name must be at least 2 characters').optional(),
  phone: z.string().optional(),
  deviceId: z.string().optional(),
});

const updateProfileSchema = z.object({
  name: z.string().min(2, 'Name must be at least 2 characters').max(100, 'Name must not exceed 100 characters').optional(),
  phone: z.string().max(25, 'Phone number must not exceed 25 characters').optional().nullable(),
  notificationPrefs: z.union([z.record(z.boolean()), z.string()]).optional(),
});

export class AuthController {
  static async login(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const validated = loginSchema.parse(req.body);
      const result = await AuthService.login(validated);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  static async refresh(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const validated = refreshSchema.parse(req.body);
      const result = await AuthService.refresh(validated.refreshToken, validated.deviceId);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  static async logout(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const refreshToken = req.body.refreshToken as string | undefined;
      const userId = req.user?.userId;
      await AuthService.logout(refreshToken, userId);
      res.status(200).json({ message: 'Logged out successfully' });
    } catch (err) {
      next(err);
    }
  }

  static async acceptInvite(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const validated = acceptInviteSchema.parse(req.body);
      const result = await AuthService.acceptInvite(validated);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  static async me(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) {
        throw new AppError('UNAUTHORIZED', 'Authentication required', 401);
      }

      const user = await prisma.user.findUnique({
        where: { id: req.user.userId },
        include: {
          institute: {
            select: { id: true, name: true, slug: true, code: true, logoUrl: true, primaryColor: true, tagline: true, plan: true },
          },
          creatorTeacher: true,
        },
      });

      if (!user) {
        throw new AppError('NOT_FOUND', 'User record not found', 404);
      }

      res.status(200).json({
        user: {
          id: user.id,
          instituteId: user.instituteId,
          role: user.role,
          name: user.name,
          email: user.email,
          phone: user.phone,
          avatarUrl: user.avatarUrl,
          notificationPrefs: user.notificationPrefs,
          status: user.status,
          coachingName: user.coachingName,
          centreLogo: user.centreLogo,
          centreAddress: user.centreAddress,
          contactPhone: user.contactPhone,
          bio: user.bio,
          subjects: user.subjects,
          institute: user.institute,
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
      });
    } catch (err) {
      next(err);
    }
  }

  static async updateProfile(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) {
        throw new AppError('UNAUTHORIZED', 'Authentication required', 401);
      }
      const validated = updateProfileSchema.parse(req.body);
      const user = await AuthService.updateProfile(req.user.userId, validated);
      res.status(200).json({
        message: 'Profile updated successfully',
        user: {
          id: user.id,
          instituteId: user.instituteId,
          role: user.role,
          name: user.name,
          email: user.email,
          phone: user.phone,
          avatarUrl: user.avatarUrl,
          notificationPrefs: user.notificationPrefs,
          status: user.status,
          coachingName: user.coachingName,
          centreLogo: user.centreLogo,
          centreAddress: user.centreAddress,
          contactPhone: user.contactPhone,
          bio: user.bio,
          subjects: user.subjects,
          institute: user.institute,
        },
      });
    } catch (err) {
      next(err);
    }
  }

  static async uploadAvatar(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) {
        throw new AppError('UNAUTHORIZED', 'Authentication required', 401);
      }
      if (!req.file) {
        throw new AppError('BAD_REQUEST', 'No image file uploaded', 400);
      }

      const file = {
        buffer: req.file.buffer,
        mimetype: req.file.mimetype,
        originalname: req.file.originalname,
        size: req.file.size,
      };

      const result = await AuthService.uploadAvatar(req.user.userId, file);
      res.status(200).json({
        message: 'Profile photo updated successfully',
        avatarUrl: result.avatarUrl,
        user: {
          id: result.user.id,
          instituteId: result.user.instituteId,
          role: result.user.role,
          name: result.user.name,
          email: result.user.email,
          phone: result.user.phone,
          avatarUrl: result.user.avatarUrl,
          notificationPrefs: result.user.notificationPrefs,
          status: result.user.status,
          coachingName: result.user.coachingName,
          centreLogo: result.user.centreLogo,
          centreAddress: result.user.centreAddress,
          contactPhone: result.user.contactPhone,
          bio: result.user.bio,
          subjects: result.user.subjects,
          institute: result.user.institute,
        },
      });
    } catch (err) {
      next(err);
    }
  }

  static async getAvatar(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const key = req.params.key;
      if (!key) {
        throw new AppError('BAD_REQUEST', 'Avatar key is required', 400);
      }
      const { stream, mimeType } = AuthService.getAvatarStream(key);
      res.setHeader('Content-Type', mimeType);
      res.setHeader('Cache-Control', 'public, max-age=86400');
      stream.on('error', (err) => next(err));
      stream.pipe(res);
    } catch (err) {
      next(err);
    }
  }
}
