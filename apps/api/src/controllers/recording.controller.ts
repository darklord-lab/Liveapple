import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { RecordingService } from '../services/recording.service.js';

const saveRecordingSchema = z.object({
  liveClassId: z.string().min(1, 'Live class ID is required'),
  title: z.string().optional(),
  videoUrl: z.string().url('Valid video URL is required'),
  durationSec: z.number().optional(),
  fileSizeMb: z.number().optional(),
});

export class RecordingController {
  static async saveRecording(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const user = { id: req.user!.userId, role: req.user!.role };
      const input = saveRecordingSchema.parse(req.body);

      const recording = await RecordingService.saveRecording(instituteId, user, input);

      res.status(201).json({
        status: 'success',
        data: recording,
      });
    } catch (err) {
      next(err);
    }
  }

  static async listRecordings(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const user = { id: req.user!.userId, role: req.user!.role };
      const batchId = req.query.batchId as string | undefined;
      const page = req.query.page ? parseInt(req.query.page as string, 10) : 1;
      const limit = req.query.limit ? parseInt(req.query.limit as string, 10) : 20;

      const result = await RecordingService.listRecordings(instituteId, user, {
        batchId,
        page,
        limit,
      });

      res.status(200).json({
        status: 'success',
        data: result,
      });
    } catch (err) {
      next(err);
    }
  }

  static async getRecordingById(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const user = { id: req.user!.userId, role: req.user!.role };
      const recordingId = req.params.id;

      const recording = await RecordingService.getRecordingById(instituteId, user, recordingId);

      res.status(200).json({
        status: 'success',
        data: recording,
      });
    } catch (err) {
      next(err);
    }
  }
}
