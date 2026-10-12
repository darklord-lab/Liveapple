import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { AttendanceService } from '../services/attendance.service.js';

const joinClassSchema = z.object({
  classId: z.string().min(1, 'Class ID is required'),
});

export class AttendanceController {
  static async recordJoin(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const studentId = req.user!.userId;
      const { classId } = joinClassSchema.parse(req.body);

      const attendance = await AttendanceService.recordJoin(instituteId, studentId, classId);

      res.status(200).json({
        status: 'success',
        data: attendance,
      });
    } catch (err) {
      next(err);
    }
  }

  static async recordLeave(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const studentId = req.user!.userId;
      const { classId } = joinClassSchema.parse(req.body);

      const attendance = await AttendanceService.recordLeave(instituteId, studentId, classId);

      res.status(200).json({
        status: 'success',
        data: attendance,
      });
    } catch (err) {
      next(err);
    }
  }

  static async getClassRoster(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const user = { id: req.user!.userId, role: req.user!.role };
      const classId = req.params.classId;

      const roster = await AttendanceService.getClassAttendance(instituteId, user, classId);

      res.status(200).json({
        status: 'success',
        data: roster,
      });
    } catch (err) {
      next(err);
    }
  }

  static async getMySummary(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const studentId = req.user!.userId;

      const summary = await AttendanceService.getStudentAttendanceSummary(instituteId, studentId);

      res.status(200).json({
        status: 'success',
        data: summary,
      });
    } catch (err) {
      next(err);
    }
  }
}
