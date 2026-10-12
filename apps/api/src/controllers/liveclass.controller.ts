import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { LiveClassService } from '../services/liveclass.service.js';
import { AppError } from '../errors/AppError.js';

const createClassSchema = z.object({
  batchId: z.string().min(1, 'Batch ID is required'),
  title: z.string().min(2, 'Class title must be at least 2 characters'),
  scheduledAt: z.string().min(1, 'Scheduled date/time is required'),
});

const generateUpcomingSchema = z.object({
  daysAhead: z.number().int().min(1).max(30).optional(),
});

const removeParticipantSchema = z.object({
  participantId: z.string().min(1, 'Participant ID is required'),
});

export class LiveClassController {
  /**
   * GET /api/v1/classes
   */
  static async listClasses(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new AppError('UNAUTHORIZED', 'Authentication required', 401);

      const batchId = req.query.batchId as string | undefined;
      const status = req.query.status as string | undefined;
      const fromDate = req.query.fromDate as string | undefined;
      const toDate = req.query.toDate as string | undefined;

      const classes = await LiveClassService.listClasses(req.user.instituteId, req.user, {
        batchId,
        status,
        fromDate,
        toDate,
      });

      res.status(200).json({ classes });
    } catch (err) {
      next(err);
    }
  }

  /**
   * POST /api/v1/classes
   */
  static async createClass(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new AppError('UNAUTHORIZED', 'Authentication required', 401);

      const parsed = createClassSchema.parse(req.body);
      const liveClass = await LiveClassService.createClass(
        req.user.instituteId,
        req.user,
        parsed
      );

      res.status(201).json(liveClass);
    } catch (err) {
      next(err);
    }
  }

  /**
   * POST /api/v1/classes/generate-upcoming
   */
  static async generateUpcoming(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new AppError('UNAUTHORIZED', 'Authentication required', 401);

      const parsed = generateUpcomingSchema.parse(req.body || {});
      const teacherId = req.user.id || req.user.userId;
      const result = await LiveClassService.generateUpcomingFromSlots(
        req.user.instituteId,
        teacherId,
        parsed.daysAhead || 7
      );

      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  /**
   * GET /api/v1/classes/:id
   */
  static async getClassById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new AppError('UNAUTHORIZED', 'Authentication required', 401);

      const liveClass = await LiveClassService.getClassById(
        req.user.instituteId,
        req.user,
        req.params.id
      );

      res.status(200).json(liveClass);
    } catch (err) {
      next(err);
    }
  }

  /**
   * POST /api/v1/classes/:id/start
   */
  static async startClass(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new AppError('UNAUTHORIZED', 'Authentication required', 401);

      const liveClass = await LiveClassService.startClass(
        req.user.instituteId,
        req.user,
        req.params.id
      );

      res.status(200).json(liveClass);
    } catch (err) {
      next(err);
    }
  }

  /**
   * POST /api/v1/classes/:id/token
   * Generates signed LiveKit token for user to join room
   */
  static async getToken(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new AppError('UNAUTHORIZED', 'Authentication required', 401);

      const result = await LiveClassService.generateParticipantToken(
        req.user.instituteId,
        req.user as any,
        req.params.id
      );

      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  /**
   * POST /api/v1/classes/:id/end
   */
  static async endClass(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new AppError('UNAUTHORIZED', 'Authentication required', 401);

      const result = await LiveClassService.endClass(
        req.user.instituteId,
        req.user,
        req.params.id
      );

      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  /**
   * POST /api/v1/classes/:id/host/mute-all
   */
  static async muteAll(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new AppError('UNAUTHORIZED', 'Authentication required', 401);

      const result = await LiveClassService.hostMuteAll(
        req.user.instituteId,
        req.user,
        req.params.id
      );

      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  /**
   * POST /api/v1/classes/:id/host/remove-participant
   */
  static async removeParticipant(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new AppError('UNAUTHORIZED', 'Authentication required', 401);

      const parsed = removeParticipantSchema.parse(req.body);
      const result = await LiveClassService.hostRemoveParticipant(
        req.user.instituteId,
        req.user,
        req.params.id,
        parsed.participantId
      );

      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }
}
