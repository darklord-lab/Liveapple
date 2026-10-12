import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { AssignmentService } from '../services/assignment.service.js';

const createAssignmentSchema = z.object({
  batchId: z.string().min(1, 'Batch ID is required'),
  title: z.string().min(2, 'Title is required'),
  description: z.string().min(2, 'Description is required'),
  dueDate: z.string().min(1, 'Due date is required'),
  attachmentUrl: z.string().optional(),
  maxMarks: z.number().optional(),
});

const submitAssignmentSchema = z.object({
  fileUrl: z.string().min(3, 'File URL is required'),
});

const gradeSubmissionSchema = z.object({
  marksObtained: z.number().min(0, 'Marks must be positive'),
  feedback: z.string().optional(),
});

export class AssignmentController {
  static async createAssignment(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const teacherId = req.user!.userId;
      const input = createAssignmentSchema.parse(req.body);

      const assignment = await AssignmentService.createAssignment(instituteId, teacherId, input);

      res.status(201).json({
        status: 'success',
        data: assignment,
      });
    } catch (err) {
      next(err);
    }
  }

  static async listAssignments(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const user = { id: req.user!.userId, role: req.user!.role };
      const batchId = req.query.batchId as string | undefined;

      const assignments = await AssignmentService.listAssignments(instituteId, user, { batchId });

      res.status(200).json({
        status: 'success',
        data: assignments,
      });
    } catch (err) {
      next(err);
    }
  }

  static async getAssignmentById(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const user = { id: req.user!.userId, role: req.user!.role };
      const assignmentId = req.params.id;

      const assignment = await AssignmentService.getAssignmentById(instituteId, user, assignmentId);

      res.status(200).json({
        status: 'success',
        data: assignment,
      });
    } catch (err) {
      next(err);
    }
  }

  static async submitAssignment(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const studentId = req.user!.userId;
      const assignmentId = req.params.id;
      const input = submitAssignmentSchema.parse(req.body);

      const submission = await AssignmentService.submitAssignment(
        instituteId,
        studentId,
        assignmentId,
        input
      );

      res.status(201).json({
        status: 'success',
        data: submission,
      });
    } catch (err) {
      next(err);
    }
  }

  static async gradeSubmission(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const teacherId = req.user!.userId;
      const submissionId = req.params.submissionId;
      const input = gradeSubmissionSchema.parse(req.body);

      const updated = await AssignmentService.gradeSubmission(
        instituteId,
        teacherId,
        submissionId,
        input
      );

      res.status(200).json({
        status: 'success',
        data: updated,
      });
    } catch (err) {
      next(err);
    }
  }
}
