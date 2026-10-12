import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { BatchService } from '../services/batch.service.js';
import { EnrollmentService } from '../services/enrollment.service.js';
import { AppError } from '../errors/AppError.js';

const createBatchSchema = z.object({
  name: z.string().min(2, 'Batch name must be at least 2 characters'),
  subject: z.string().min(2, 'Subject must be at least 2 characters'),
  teacherId: z.string().optional(),
});

const updateBatchSchema = z.object({
  name: z.string().min(2).optional(),
  subject: z.string().min(2).optional(),
});

const joinBatchSchema = z.object({
  joinCode: z.string().min(3, 'Join code must be at least 3 characters'),
});

const addStudentSchema = z.object({
  name: z.string().min(2, 'Student name must be at least 2 characters'),
  email: z.string().email('Valid email is required'),
  phone: z.string().optional(),
});

const bulkStudentsSchema = z.object({
  students: z
    .array(
      z.object({
        name: z.string().min(1, 'Name is required'),
        email: z.string().email('Valid email is required'),
        phone: z.string().optional(),
      })
    )
    .optional(),
  csvText: z.string().optional(),
});

const updateEnrollmentStatusSchema = z.object({
  status: z.enum(['ACTIVE', 'REMOVED', 'PENDING']),
});

export class BatchController {
  /**
   * GET /api/v1/batches
   */
  static async listBatches(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new AppError('UNAUTHORIZED', 'Authentication required', 401);

      const search = req.query.search as string | undefined;
      const teacherId = req.query.teacherId as string | undefined;

      const batches = await BatchService.listBatches(req.user.instituteId, req.user, {
        search,
        teacherId,
      });

      res.status(200).json({ batches });
    } catch (err) {
      next(err);
    }
  }

  /**
   * POST /api/v1/batches
   */
  static async createBatch(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new AppError('UNAUTHORIZED', 'Authentication required', 401);

      const parsed = createBatchSchema.parse(req.body);
      const batch = await BatchService.createBatch(req.user.instituteId, req.user, parsed);

      res.status(201).json(batch);
    } catch (err) {
      next(err);
    }
  }

  /**
   * GET /api/v1/batches/:id
   */
  static async getBatchById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new AppError('UNAUTHORIZED', 'Authentication required', 401);

      const batch = await BatchService.getBatchById(
        req.user.instituteId,
        req.user,
        req.params.id
      );

      res.status(200).json(batch);
    } catch (err) {
      next(err);
    }
  }

  /**
   * PATCH /api/v1/batches/:id
   */
  static async updateBatch(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new AppError('UNAUTHORIZED', 'Authentication required', 401);

      const parsed = updateBatchSchema.parse(req.body);
      const batch = await BatchService.updateBatch(
        req.user.instituteId,
        req.user,
        req.params.id,
        parsed
      );

      res.status(200).json(batch);
    } catch (err) {
      next(err);
    }
  }

  /**
   * DELETE /api/v1/batches/:id
   */
  static async deleteBatch(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new AppError('UNAUTHORIZED', 'Authentication required', 401);

      const result = await BatchService.deleteBatch(
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
   * POST /api/v1/batches/:id/regenerate-code
   */
  static async regenerateJoinCode(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new AppError('UNAUTHORIZED', 'Authentication required', 401);

      const batch = await BatchService.regenerateJoinCode(
        req.user.instituteId,
        req.user,
        req.params.id
      );

      res.status(200).json(batch);
    } catch (err) {
      next(err);
    }
  }

  /**
   * POST /api/v1/batches/join
   * Student enrolls with batch code
   */
  static async joinBatch(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new AppError('UNAUTHORIZED', 'Authentication required', 401);

      const parsed = joinBatchSchema.parse(req.body);
      const result = await EnrollmentService.enrollWithCode(
        req.user.instituteId,
        req.user.id,
        parsed.joinCode
      );

      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  /**
   * GET /api/v1/batches/:id/students
   */
  static async listStudents(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new AppError('UNAUTHORIZED', 'Authentication required', 401);

      const status = req.query.status as string | undefined;
      const students = await EnrollmentService.listEnrollments(
        req.user.instituteId,
        req.user,
        req.params.id,
        status
      );

      res.status(200).json({ students });
    } catch (err) {
      next(err);
    }
  }

  /**
   * POST /api/v1/batches/:id/students
   */
  static async addStudent(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new AppError('UNAUTHORIZED', 'Authentication required', 401);

      const parsed = addStudentSchema.parse(req.body);
      const result = await EnrollmentService.addStudentDirect(
        req.user.instituteId,
        req.user.id,
        req.params.id,
        parsed
      );

      res.status(201).json(result);
    } catch (err) {
      next(err);
    }
  }

  /**
   * POST /api/v1/batches/:id/students/bulk
   */
  static async bulkEnroll(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new AppError('UNAUTHORIZED', 'Authentication required', 401);

      const parsed = bulkStudentsSchema.parse(req.body);
      const source = parsed.csvText || parsed.students;

      if (!source) {
        throw new AppError('BAD_REQUEST', 'Provide either "students" array or "csvText"', 400);
      }

      const result = await EnrollmentService.bulkEnrollStudents(
        req.user.instituteId,
        req.user.id,
        req.params.id,
        source
      );

      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  /**
   * PATCH /api/v1/batches/:id/students/:enrollmentId/status
   */
  static async updateEnrollmentStatus(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new AppError('UNAUTHORIZED', 'Authentication required', 401);

      const parsed = updateEnrollmentStatusSchema.parse(req.body);
      const result = await EnrollmentService.updateEnrollmentStatus(
        req.user.instituteId,
        req.user,
        req.params.id,
        req.params.enrollmentId,
        parsed.status
      );

      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }
}
