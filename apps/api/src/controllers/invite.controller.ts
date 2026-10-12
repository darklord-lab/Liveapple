import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { InviteService } from '../services/invite.service.js';
import { AppError } from '../errors/AppError.js';

const createInviteSchema = z.object({
  email: z.string().email('Valid email is required').optional(),
  phone: z.string().optional(),
  role: z.enum(['TEACHER', 'STUDENT']),
});

export class InviteController {
  static async createInvite(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) {
        throw new AppError('UNAUTHORIZED', 'Authentication required', 401);
      }

      const validated = createInviteSchema.parse(req.body);

      // Authorization rule: Teachers can only invite Students; Admins can invite Teachers and Students
      if (req.user.role === 'TEACHER' && validated.role !== 'STUDENT') {
        throw new AppError('FORBIDDEN', 'Teachers can only invite students', 403);
      }

      const result = await InviteService.createInvite({
        instituteId: req.user.instituteId,
        actorId: req.user.userId,
        email: validated.email,
        phone: validated.phone,
        role: validated.role,
      });

      res.status(201).json(result);
    } catch (err) {
      next(err);
    }
  }

  static async validateInvite(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const code = (req.params.code || req.query.code || req.body.code) as string;
      if (!code) {
        throw new AppError('BAD_REQUEST', 'Invite code is required', 400);
      }

      const result = await InviteService.validateInvite(code);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  static async listInvites(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) {
        throw new AppError('UNAUTHORIZED', 'Authentication required', 401);
      }

      const invites = await InviteService.listInvites(req.user.instituteId);
      res.status(200).json({ invites });
    } catch (err) {
      next(err);
    }
  }
}
