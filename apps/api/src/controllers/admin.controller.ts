import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { AdminService } from '../services/admin.service.js';
import { AppError } from '../errors/AppError.js';

const addTeacherSchema = z.object({
  name: z.string().min(2, 'Teacher name must be at least 2 characters'),
  email: z.string().email('Valid email is required'),
  phone: z.string().optional(),
  password: z.string().min(6).optional(),
  coachingName: z.string().optional(),
  centreLogo: z.string().optional(),
  centreAddress: z.string().optional(),
  contactPhone: z.string().optional(),
  bio: z.string().optional(),
  subjects: z.string().optional(),
});

const updateTeacherSchema = z.object({
  name: z.string().min(2).optional(),
  email: z.string().email().optional(),
  phone: z.string().optional(),
  status: z.enum(['ACTIVE', 'SUSPENDED']).optional(),
  coachingName: z.string().optional(),
  centreLogo: z.string().optional(),
  centreAddress: z.string().optional(),
  contactPhone: z.string().optional(),
  bio: z.string().optional(),
  subjects: z.string().optional(),
  password: z.string().min(6).optional(),
});

const bulkTeachersSchema = z.object({
  teachers: z
    .array(
      z.object({
        name: z.string().min(1, 'Name is required'),
        email: z.string().email('Valid email is required'),
        phone: z.string().optional(),
        coachingName: z.string().optional(),
        subjects: z.string().optional(),
      })
    )
    .optional(),
  csvText: z.string().optional(),
});

const updateStatusSchema = z.object({
  status: z.enum(['ACTIVE', 'SUSPENDED']),
});

const addStudentSchema = z.object({
  name: z.string().min(2, 'Student name must be at least 2 characters'),
  email: z.string().email('Valid email is required'),
  phone: z.string().optional(),
  password: z.string().min(6).optional(),
  teacherId: z.string().optional(),
  batchId: z.string().optional(),
});

export class AdminController {
  /**
   * GET /api/v1/admin/teachers
   */
  static async listTeachers(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new AppError('UNAUTHORIZED', 'Authentication required', 401);

      const page = req.query.page ? parseInt(req.query.page as string, 10) : 1;
      const limit = req.query.limit ? parseInt(req.query.limit as string, 10) : 50;
      const search = req.query.search as string | undefined;
      const status = req.query.status as string | undefined;

      const result = await AdminService.listTeachers(req.user.instituteId, {
        page,
        limit,
        search,
        status,
      });

      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  /**
   * POST /api/v1/admin/teachers
   */
  static async addTeacher(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new AppError('UNAUTHORIZED', 'Authentication required', 401);

      const validated = addTeacherSchema.parse(req.body);
      const result = await AdminService.addTeacher(req.user.instituteId, req.user.userId, validated);

      res.status(201).json(result);
    } catch (err) {
      next(err);
    }
  }

  /**
   * PATCH /api/v1/admin/teachers/:id
   */
  static async updateTeacher(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new AppError('UNAUTHORIZED', 'Authentication required', 401);

      const teacherId = req.params.id;
      const validated = updateTeacherSchema.parse(req.body);
      const result = await AdminService.updateTeacher(
        req.user.instituteId,
        req.user.userId,
        teacherId,
        validated
      );

      res.status(200).json({ teacher: result });
    } catch (err) {
      next(err);
    }
  }

  /**
   * DELETE /api/v1/admin/teachers/:id
   */
  static async deleteTeacher(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new AppError('UNAUTHORIZED', 'Authentication required', 401);

      const teacherId = req.params.id;
      const result = await AdminService.deleteTeacher(
        req.user.instituteId,
        req.user.userId,
        teacherId
      );

      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  /**
   * POST /api/v1/admin/teachers/bulk
   */
  static async bulkOnboard(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new AppError('UNAUTHORIZED', 'Authentication required', 401);

      const validated = bulkTeachersSchema.parse(req.body);

      let rows: Array<{ name: string; email: string; phone?: string; coachingName?: string; subjects?: string }> = [];

      if (validated.teachers && validated.teachers.length > 0) {
        rows = validated.teachers;
      } else if (validated.csvText && validated.csvText.trim().length > 0) {
        const lines = validated.csvText.trim().split(/\r?\n/);
        for (let i = 0; i < lines.length; i++) {
          const line = lines[i].trim();
          if (!line) continue;

          if (i === 0 && line.toLowerCase().includes('name') && line.toLowerCase().includes('email')) {
            continue;
          }

          const parts = line.split(',').map((p) => p.trim());
          if (parts.length >= 2) {
            rows.push({
              name: parts[0],
              email: parts[1],
              phone: parts[2] || undefined,
            });
          }
        }
      } else {
        throw new AppError('BAD_REQUEST', 'Provide either "teachers" array or "csvText" string', 400);
      }

      const result = await AdminService.bulkOnboard(
        req.user.instituteId,
        req.user.userId,
        rows
      );

      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  /**
   * PATCH /api/v1/admin/teachers/:id/status
   */
  static async updateTeacherStatus(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new AppError('UNAUTHORIZED', 'Authentication required', 401);

      const teacherId = req.params.id;
      if (!teacherId) throw new AppError('BAD_REQUEST', 'Teacher ID is required', 400);

      const validated = updateStatusSchema.parse(req.body);
      const result = await AdminService.updateTeacherStatus(
        req.user.instituteId,
        req.user.userId,
        teacherId,
        validated.status
      );

      res.status(200).json({ teacher: result });
    } catch (err) {
      next(err);
    }
  }

  /**
   * GET /api/v1/admin/students
   */
  static async listStudents(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new AppError('UNAUTHORIZED', 'Authentication required', 401);

      const teacherId = req.query.teacherId as string | undefined;
      const batchId = req.query.batchId as string | undefined;
      const search = req.query.search as string | undefined;
      const page = req.query.page ? parseInt(req.query.page as string, 10) : 1;
      const limit = req.query.limit ? parseInt(req.query.limit as string, 10) : 50;

      const result = await AdminService.listStudents(req.user.instituteId, {
        teacherId,
        batchId,
        search,
        page,
        limit,
      });

      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  /**
   * POST /api/v1/admin/students
   */
  static async addStudent(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new AppError('UNAUTHORIZED', 'Authentication required', 401);

      const validated = addStudentSchema.parse(req.body);
      const student = await AdminService.addStudent(
        req.user.instituteId,
        req.user.userId,
        validated
      );

      res.status(201).json({ student });
    } catch (err) {
      next(err);
    }
  }
}
