import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { FeeService } from '../services/fee.service.js';

const createFeePlanSchema = z.object({
  name: z.string().min(2, 'Name is required'),
  amount: z.number().min(1, 'Amount must be positive'),
  interval: z.enum(['ONE_TIME', 'MONTHLY', 'YEARLY']).optional(),
  batchId: z.string().optional(),
  description: z.string().optional(),
});

const processPaymentSchema = z.object({
  feePlanId: z.string().optional(),
  amount: z.number().min(1, 'Amount must be positive'),
  paymentMethod: z.enum(['UPI', 'RAZORPAY', 'CASH', 'CARD']).optional(),
});

export class FeeController {
  static async createFeePlan(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const input = createFeePlanSchema.parse(req.body);

      const feePlan = await FeeService.createFeePlan(instituteId, input);

      res.status(201).json({
        status: 'success',
        data: feePlan,
      });
    } catch (err) {
      next(err);
    }
  }

  static async listFeePlans(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const batchId = req.query.batchId as string | undefined;

      const feePlans = await FeeService.listFeePlans(instituteId, { batchId });

      res.status(200).json({
        status: 'success',
        data: feePlans,
      });
    } catch (err) {
      next(err);
    }
  }

  static async processPayment(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const studentId = req.user!.userId;
      const input = processPaymentSchema.parse(req.body);

      const payment = await FeeService.processPayment(instituteId, studentId, input);

      res.status(201).json({
        status: 'success',
        data: payment,
      });
    } catch (err) {
      next(err);
    }
  }

  static async getMyDues(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const studentId = req.user!.userId;

      const dues = await FeeService.getStudentDues(instituteId, studentId);

      res.status(200).json({
        status: 'success',
        data: dues,
      });
    } catch (err) {
      next(err);
    }
  }

  static async getFinancialReport(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;

      const report = await FeeService.getInstituteFinancialReport(instituteId);

      res.status(200).json({
        status: 'success',
        data: report,
      });
    } catch (err) {
      next(err);
    }
  }
}
