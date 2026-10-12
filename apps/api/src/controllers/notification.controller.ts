import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { NotificationService } from '../services/notification.service.js';

const listQuerySchema = z.object({
  page: z.string().optional().transform((val) => (val ? parseInt(val, 10) : 1)),
  limit: z.string().optional().transform((val) => (val ? parseInt(val, 10) : 20)),
  unreadOnly: z.string().optional().transform((val) => val === 'true'),
});

export class NotificationController {
  static async listNotifications(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const userId = req.user!.userId;
      const query = listQuerySchema.parse(req.query);

      const result = await NotificationService.getUserNotifications(instituteId, userId, query);

      res.status(200).json({
        status: 'success',
        data: result,
      });
    } catch (err) {
      next(err);
    }
  }

  static async markAsRead(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const userId = req.user!.userId;
      const notificationId = req.params.id;

      const updated = await NotificationService.markAsRead(instituteId, userId, notificationId);

      res.status(200).json({
        status: 'success',
        data: updated,
      });
    } catch (err) {
      next(err);
    }
  }

  static async markAllAsRead(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const userId = req.user!.userId;

      const result = await NotificationService.markAllAsRead(instituteId, userId);

      res.status(200).json({
        status: 'success',
        data: result,
      });
    } catch (err) {
      next(err);
    }
  }
}
