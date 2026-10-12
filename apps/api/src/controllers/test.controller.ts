import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { TestService } from '../services/test.service.js';

const questionSchema = z.object({
  text: z.string().min(2, 'Question text required'),
  optionA: z.string().min(1, 'Option A required'),
  optionB: z.string().min(1, 'Option B required'),
  optionC: z.string().min(1, 'Option C required'),
  optionD: z.string().min(1, 'Option D required'),
  correctOption: z.enum(['A', 'B', 'C', 'D']),
  marks: z.number().optional(),
  explanation: z.string().optional(),
});

const createTestSchema = z.object({
  batchId: z.string().min(1, 'Batch ID required'),
  title: z.string().min(2, 'Test title required'),
  description: z.string().optional(),
  durationMin: z.number().min(1).optional(),
  scheduledAt: z.string().optional(),
  questions: z.array(questionSchema).min(1, 'At least 1 question required'),
});

const submitAnswersSchema = z.object({
  answers: z.record(z.string()),
});

export class TestController {
  static async createTest(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const teacherId = req.user!.userId;
      const input = createTestSchema.parse(req.body);

      const test = await TestService.createTest(instituteId, teacherId, input);

      res.status(201).json({
        status: 'success',
        data: test,
      });
    } catch (err) {
      next(err);
    }
  }

  static async listTests(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const user = { id: req.user!.userId, role: req.user!.role };
      const batchId = req.query.batchId as string | undefined;

      const tests = await TestService.listTests(instituteId, user, { batchId });

      res.status(200).json({
        status: 'success',
        data: tests,
      });
    } catch (err) {
      next(err);
    }
  }

  static async getTestById(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const user = { id: req.user!.userId, role: req.user!.role };
      const testId = req.params.id;

      const test = await TestService.getTestById(instituteId, user, testId);

      res.status(200).json({
        status: 'success',
        data: test,
      });
    } catch (err) {
      next(err);
    }
  }

  static async startAttempt(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const studentId = req.user!.userId;
      const testId = req.params.id;

      const attempt = await TestService.startTestAttempt(instituteId, studentId, testId);

      res.status(200).json({
        status: 'success',
        data: attempt,
      });
    } catch (err) {
      next(err);
    }
  }

  static async submitAttempt(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const studentId = req.user!.userId;
      const testId = req.params.id;
      const { answers } = submitAnswersSchema.parse(req.body);

      const result = await TestService.submitTestAttempt(instituteId, studentId, testId, {
        answers,
      });

      res.status(200).json({
        status: 'success',
        data: result,
      });
    } catch (err) {
      next(err);
    }
  }

  static async getTestResult(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const user = { id: req.user!.userId, role: req.user!.role };
      const testId = req.params.id;

      const result = await TestService.getTestResult(instituteId, user, testId);

      res.status(200).json({
        status: 'success',
        data: result,
      });
    } catch (err) {
      next(err);
    }
  }
}
