import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { TimetableService } from '../services/timetable.service.js';
import { AppError } from '../errors/AppError.js';

const createSlotSchema = z.object({
  batchId: z.string().min(1, 'Batch ID is required'),
  dayOfWeek: z.number().int().min(0).max(6, 'Day of week must be between 0 (Sun) and 6 (Sat)'),
  startMin: z.number().int().min(0).max(1440, 'startMin must be between 0 and 1440'),
  endMin: z.number().int().min(0).max(1440, 'endMin must be between 0 and 1440'),
  recurring: z.boolean().optional(),
});

export class TimetableController {
  /**
   * GET /api/v1/timetable
   */
  static async listSlots(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new AppError('UNAUTHORIZED', 'Authentication required', 401);

      const batchId = req.query.batchId as string | undefined;
      const teacherId = req.query.teacherId as string | undefined;
      const dayOfWeek = req.query.dayOfWeek !== undefined ? parseInt(req.query.dayOfWeek as string, 10) : undefined;

      const slots = await TimetableService.listSlots(req.user.instituteId, req.user, {
        batchId,
        teacherId,
        dayOfWeek,
      });

      res.status(200).json({ slots });
    } catch (err) {
      next(err);
    }
  }

  /**
   * POST /api/v1/timetable
   */
  static async createSlot(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new AppError('UNAUTHORIZED', 'Authentication required', 401);

      const parsed = createSlotSchema.parse(req.body);
      const slot = await TimetableService.createSlot(
        req.user.instituteId,
        req.user,
        parsed
      );

      res.status(201).json(slot);
    } catch (err) {
      next(err);
    }
  }

  /**
   * DELETE /api/v1/timetable/:id
   */
  static async deleteSlot(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new AppError('UNAUTHORIZED', 'Authentication required', 401);

      const result = await TimetableService.deleteSlot(
        req.user.instituteId,
        req.user,
        req.params.id
      );

      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }
}
