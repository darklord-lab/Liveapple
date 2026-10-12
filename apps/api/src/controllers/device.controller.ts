import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { NotificationService } from '../services/notification.service.js';

const registerFcmSchema = z.object({
  fcmToken: z.string().min(5, 'FCM token must be at least 5 characters'),
  deviceId: z.string().optional(),
});

export class DeviceController {
  static async registerFcmToken(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const userId = req.user!.userId;
      const { fcmToken } = registerFcmSchema.parse(req.body);

      const result = await NotificationService.registerFcmToken(instituteId, userId, fcmToken);

      res.status(200).json({
        status: 'success',
        ...result,
      });
    } catch (err) {
      next(err);
    }
  }

  static async removeFcmToken(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const userId = req.user!.userId;

      const result = await NotificationService.removeFcmToken(instituteId, userId);

      res.status(200).json({
        status: 'success',
        ...result,
      });
    } catch (err) {
      next(err);
    }
  }
}
