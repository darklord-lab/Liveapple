import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import crypto from 'crypto';
import { LiveClassService } from '../services/liveclass.service.js';
import { AppError } from '../errors/AppError.js';
import { getStorageService } from '../services/storage.service.js';
import { prisma } from '../utils/prisma.js';

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
   * POST /api/v1/classes/start-from-slot
   */
  static async startFromSlot(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new AppError('UNAUTHORIZED', 'Authentication required', 401);
      const { slotId, date } = req.body || {};
      if (!slotId) throw new AppError('BAD_REQUEST', 'slotId is required', 400);

      const targetDate = date ? new Date(date) : new Date();
      const liveClass = await LiveClassService.startFromSlot(
        req.user.instituteId,
        req.user,
        slotId,
        targetDate
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

  /**
   * POST /api/v1/classes/:id/slides
   * Uploads PDF slides for real-time presentation
   */
  static async uploadSlides(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new AppError('UNAUTHORIZED', 'Authentication required', 401);
      const classId = req.params.id;
      const file = req.file;

      if (!file) {
        throw new AppError('BAD_REQUEST', 'No file uploaded', 400);
      }

      const fileName = file.originalname || '';
      const isPpt =
        file.mimetype.includes('powerpoint') ||
        file.mimetype.includes('presentationml') ||
        fileName.toLowerCase().endsWith('.ppt') ||
        fileName.toLowerCase().endsWith('.pptx');

      if (isPpt) {
        throw new AppError('BAD_REQUEST', 'PPT ko PDF me export karo ya screen share karo', 400);
      }

      if (file.mimetype !== 'application/pdf' && !fileName.toLowerCase().endsWith('.pdf')) {
        throw new AppError('BAD_REQUEST', 'Only PDF slides are allowed. PPT ko PDF me export karo ya screen share karo', 400);
      }

      if (file.size > 25 * 1024 * 1024) {
        throw new AppError('BAD_REQUEST', 'File exceeds maximum allowed size of 25MB', 400);
      }

      const liveClass = await prisma.liveClass.findFirst({
        where: { id: classId, instituteId: req.user.instituteId },
        include: { batch: true },
      });

      if (!liveClass) {
        throw new AppError('NOT_FOUND', 'Live class not found', 404);
      }

      const teacherId = req.user.userId || req.user.id;
      if (req.user.role === 'TEACHER' && liveClass.teacherId !== teacherId) {
        throw new AppError('FORBIDDEN', 'Only the class teacher can upload slides', 403);
      }

      const storage = getStorageService();
      const storageResult = await storage.put({
        buffer: file.buffer,
        originalname: file.originalname,
        mimetype: file.mimetype || 'application/pdf',
        size: file.size,
      });

      const fileHash = crypto.createHash('sha256').update(file.buffer).digest('hex');
      const pageMatches = file.buffer.toString('binary').match(/\/Type\s*\/Page\b/g);
      const pageCount = (pageMatches && pageMatches.length > 0) ? pageMatches.length : 1;

      res.status(201).json({
        success: true,
        deckId: storageResult.key,
        fileKey: storageResult.key,
        fileHash,
        pageCount,
        streamUrl: `/api/v1/classes/${classId}/slides/${storageResult.key}`,
        data: {
          deckId: storageResult.key,
          fileKey: storageResult.key,
          fileHash,
          pageCount,
          url: `/api/v1/classes/${classId}/slides/${storageResult.key}`,
          fileName: file.originalname,
          fileSize: file.size,
          mimeType: 'application/pdf',
        },
      });
    } catch (err) {
      next(err);
    }
  }

  /**
   * GET /api/v1/classes/:id/slides/:key
   */
  static async downloadSlide(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new AppError('UNAUTHORIZED', 'Authentication required', 401);
      const { id: classId, key } = req.params;

      const liveClass = await prisma.liveClass.findFirst({
        where: { id: classId, instituteId: req.user.instituteId },
      });

      if (!liveClass) {
        throw new AppError('NOT_FOUND', 'Class not found', 404);
      }

      const storage = getStorageService();
      const stream = await storage.getStream(key);

      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', `inline; filename="${key}.pdf"`);
      stream.pipe(res);
    } catch (err) {
      next(err);
    }
  }
}
