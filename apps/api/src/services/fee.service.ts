import { prisma } from '../utils/prisma.js';
import { AppError } from '../errors/AppError.js';
import { logAudit } from './audit.service.js';

export interface CreateFeePlanInput {
  name: string;
  amount: number;
  interval?: 'ONE_TIME' | 'MONTHLY' | 'YEARLY';
  batchId?: string;
  description?: string;
}

export interface CreatePaymentInput {
  feePlanId?: string;
  amount: number;
  paymentMethod?: 'UPI' | 'RAZORPAY' | 'CASH' | 'CARD';
}

export class FeeService {
  /**
   * Admin creates a new fee structure / plan
   */
  static async createFeePlan(instituteId: string, input: CreateFeePlanInput) {
    const { name, amount, interval = 'MONTHLY', batchId, description } = input;

    if (!name || name.trim().length < 2) {
      throw new AppError('BAD_REQUEST', 'Fee plan name is required', 400);
    }
    if (typeof amount !== 'number' || amount <= 0) {
      throw new AppError('BAD_REQUEST', 'Valid positive fee amount is required', 400);
    }

    if (batchId) {
      const batch = await prisma.batch.findFirst({
        where: { id: batchId, instituteId },
      });
      if (!batch) {
        throw new AppError('NOT_FOUND', 'Batch not found', 404);
      }
    }

    const feePlan = await prisma.feePlan.create({
      data: {
        instituteId,
        name: name.trim(),
        amount,
        interval,
        batchId: batchId || null,
        description: description?.trim() || null,
      },
      include: {
        batch: { select: { id: true, name: true, subject: true } },
      },
    });

    return feePlan;
  }

  /**
   * List fee plans in institute
   */
  static async listFeePlans(instituteId: string, query: { batchId?: string } = {}) {
    const feePlans = await prisma.feePlan.findMany({
      where: {
        instituteId,
        ...(query.batchId ? { batchId: query.batchId } : {}),
      },
      orderBy: { createdAt: 'desc' },
      include: {
        batch: { select: { id: true, name: true, subject: true } },
        _count: { select: { payments: true } },
      },
    });

    return feePlans;
  }

  /**
   * Student pays fee (UPI / Razorpay simulation with receipt generation)
   */
  static async processPayment(
    instituteId: string,
    studentId: string,
    input: CreatePaymentInput
  ) {
    const { feePlanId, amount, paymentMethod = 'UPI' } = input;

    if (typeof amount !== 'number' || amount <= 0) {
      throw new AppError('BAD_REQUEST', 'Valid payment amount is required', 400);
    }

    const transactionId = `txn_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`;
    const receiptNo = `REC-${Date.now().toString().slice(-6)}-${Math.floor(100 + Math.random() * 900)}`;

    const payment = await prisma.payment.create({
      data: {
        instituteId,
        studentId,
        feePlanId: feePlanId || null,
        amount,
        paymentMethod,
        status: 'SUCCESS',
        transactionId,
        receiptNo,
        paidAt: new Date(),
      },
      include: {
        feePlan: { select: { id: true, name: true, interval: true } },
        student: { select: { id: true, name: true, email: true } },
      },
    });

    await logAudit({
      instituteId,
      actorId: studentId,
      action: 'PAYMENT_COMPLETED',
      entity: `Payment:${payment.id}`,
      meta: { amount, paymentMethod, transactionId, receiptNo },
    });

    return payment;
  }

  /**
   * Student checks their fee dues and payment history
   */
  static async getStudentDues(instituteId: string, studentId: string) {
    // 1. Find batches enrolled in
    const activeEnrollments = await prisma.enrollment.findMany({
      where: { instituteId, studentId, status: 'ACTIVE' },
      select: { batchId: true },
    });
    const batchIds = activeEnrollments.map((e) => e.batchId);

    // 2. Find fee plans associated with institute or batches
    const applicablePlans = await prisma.feePlan.findMany({
      where: {
        instituteId,
        OR: [{ batchId: null }, { batchId: { in: batchIds } }],
      },
      include: { batch: true },
    });

    // 3. Find payments made by student
    const payments = await prisma.payment.findMany({
      where: { instituteId, studentId },
      orderBy: { paidAt: 'desc' },
      include: { feePlan: true },
    });

    const totalPaid = payments
      .filter((p) => p.status === 'SUCCESS')
      .reduce((acc, curr) => acc + curr.amount, 0);

    const totalDue = applicablePlans.reduce((acc, curr) => acc + curr.amount, 0);

    return {
      totalDue,
      totalPaid,
      outstandingBalance: Math.max(0, totalDue - totalPaid),
      applicablePlans,
      paymentHistory: payments,
    };
  }

  /**
   * Institute financial overview for Admin
   */
  static async getInstituteFinancialReport(instituteId: string) {
    const [totalRevenueResult, paymentsCount, recentPayments] = await Promise.all([
      prisma.payment.aggregate({
        where: { instituteId, status: 'SUCCESS' },
        _sum: { amount: true },
      }),
      prisma.payment.count({
        where: { instituteId, status: 'SUCCESS' },
      }),
      prisma.payment.findMany({
        where: { instituteId },
        orderBy: { paidAt: 'desc' },
        take: 10,
        include: {
          student: { select: { id: true, name: true, email: true } },
          feePlan: { select: { id: true, name: true } },
        },
      }),
    ]);

    return {
      totalRevenue: totalRevenueResult._sum.amount || 0,
      successfulTransactions: paymentsCount,
      recentPayments,
    };
  }
}
