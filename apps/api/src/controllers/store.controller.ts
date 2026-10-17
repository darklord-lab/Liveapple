import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { StoreService } from '../services/store.service.js';

const createOfferingSchema = z.object({
  batchId: z.string().min(1, 'Batch ID is required'),
  price: z.number().min(0.01, 'Price must be positive'),
  mrp: z.number().min(0.01, 'MRP must be positive'),
  title: z.string().optional(),
  description: z.string().optional(),
  thumbnailUrl: z.string().optional(),
  isFeatured: z.boolean().optional(),
  isPublished: z.boolean().optional(),
});

const updateOfferingSchema = z.object({
  price: z.number().min(0.01).optional(),
  mrp: z.number().min(0.01).optional(),
  title: z.string().optional(),
  description: z.string().optional(),
  thumbnailUrl: z.string().optional(),
  isFeatured: z.boolean().optional(),
  isPublished: z.boolean().optional(),
});

const createCouponSchema = z.object({
  code: z.string().min(2, 'Coupon code must be at least 2 characters'),
  discountType: z.enum(['PERCENT', 'FLAT']).optional(),
  discountValue: z.number().min(0.01, 'Discount value must be positive'),
  validTill: z.string().optional(),
  maxUses: z.number().int().positive().optional(),
});

const validateCouponSchema = z.object({
  code: z.string().min(1, 'Coupon code is required'),
  offeringId: z.string().min(1, 'Offering ID is required'),
});

const checkoutSchema = z.object({
  offeringId: z.string().min(1, 'Offering ID is required'),
  couponCode: z.string().optional(),
  paymentMethod: z.enum(['RAZORPAY', 'MOCK', 'UPI']).optional(),
});

const verifyPaymentSchema = z.object({
  orderId: z.string().min(1, 'Order ID is required'),
  paymentId: z.string().min(1, 'Payment ID is required'),
  signature: z.string().min(1, 'Signature is required'),
  offeringId: z.string().min(1, 'Offering ID is required'),
  couponCode: z.string().optional(),
});

const refundSchema = z.object({
  reason: z.string().optional(),
});

export class StoreController {
  // ------------------------------------------
  // OFFERINGS
  // ------------------------------------------
  static async listOfferings(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const studentId = req.user?.role === 'STUDENT' ? req.user.userId : undefined;
      const publishedOnly = req.user?.role !== 'ADMIN';

      const search = req.query.search as string | undefined;
      const batchId = req.query.batchId as string | undefined;
      const isFeatured = req.query.featured !== undefined ? req.query.featured === 'true' : undefined;
      const minPrice = req.query.minPrice ? parseFloat(req.query.minPrice as string) : undefined;
      const maxPrice = req.query.maxPrice ? parseFloat(req.query.maxPrice as string) : undefined;
      const sort = req.query.sort as string | undefined;
      const purchasedFilter = req.query.purchasedFilter as 'ALL' | 'PURCHASED' | 'AVAILABLE' | undefined;

      const offerings = await StoreService.listOfferings(instituteId, {
        search,
        batchId,
        isFeatured,
        minPrice,
        maxPrice,
        sort,
        studentId,
        purchasedFilter,
        publishedOnly,
      });

      res.status(200).json({
        status: 'success',
        data: offerings,
      });
    } catch (err) {
      next(err);
    }
  }

  static async getOffering(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const studentId = req.user?.role === 'STUDENT' ? req.user.userId : undefined;
      const offeringId = req.params.id;

      const offering = await StoreService.getOfferingById(instituteId, offeringId, studentId);

      res.status(200).json({
        status: 'success',
        data: offering,
      });
    } catch (err) {
      next(err);
    }
  }

  static async createOffering(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const input = createOfferingSchema.parse(req.body);

      const offering = await StoreService.createOffering(instituteId, input);

      res.status(201).json({
        status: 'success',
        data: offering,
      });
    } catch (err) {
      next(err);
    }
  }

  static async updateOffering(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const offeringId = req.params.id;
      const input = updateOfferingSchema.parse(req.body);

      const offering = await StoreService.updateOffering(instituteId, offeringId, input);

      res.status(200).json({
        status: 'success',
        data: offering,
      });
    } catch (err) {
      next(err);
    }
  }

  static async deleteOffering(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const offeringId = req.params.id;

      const result = await StoreService.deleteOffering(instituteId, offeringId);

      res.status(200).json({
        status: 'success',
        data: result,
      });
    } catch (err) {
      next(err);
    }
  }

  // ------------------------------------------
  // COUPONS
  // ------------------------------------------
  static async listCoupons(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const coupons = await StoreService.listCoupons(instituteId);

      res.status(200).json({
        status: 'success',
        data: coupons,
      });
    } catch (err) {
      next(err);
    }
  }

  static async createCoupon(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const input = createCouponSchema.parse(req.body);

      const coupon = await StoreService.createCoupon(instituteId, input);

      res.status(201).json({
        status: 'success',
        data: coupon,
      });
    } catch (err) {
      next(err);
    }
  }

  static async validateCoupon(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const { code, offeringId } = validateCouponSchema.parse(req.body);

      const result = await StoreService.validateCoupon(instituteId, code, offeringId);

      res.status(200).json({
        status: 'success',
        data: result,
      });
    } catch (err) {
      next(err);
    }
  }

  // ------------------------------------------
  // CHECKOUT & VERIFY
  // ------------------------------------------
  static async checkout(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const studentId = req.user!.userId;
      const input = checkoutSchema.parse(req.body);

      const result = await StoreService.checkout(instituteId, studentId, input);

      res.status(200).json({
        status: 'success',
        data: result,
      });
    } catch (err) {
      next(err);
    }
  }

  static async verifyPayment(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const studentId = req.user!.userId;
      const input = verifyPaymentSchema.parse(req.body);

      const result = await StoreService.verifyPayment(instituteId, studentId, input);

      res.status(200).json({
        status: 'success',
        data: result,
      });
    } catch (err) {
      next(err);
    }
  }

  static async handleWebhook(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = (req.headers['x-institute-id'] as string) || req.user?.instituteId || '';
      const signature = req.headers['x-razorpay-signature'] as string;
      const rawBody = typeof req.body === 'string' ? req.body : JSON.stringify(req.body);

      const result = await StoreService.handleWebhook(instituteId, rawBody, signature);

      res.status(200).json({
        status: 'success',
        data: result,
      });
    } catch (err) {
      next(err);
    }
  }

  // ------------------------------------------
  // PURCHASES, INVOICES & REFUNDS
  // ------------------------------------------
  static async listPurchases(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const studentId = req.user?.role === 'STUDENT' ? req.user.userId : (req.query.studentId as string | undefined);
      const offeringId = req.query.offeringId as string | undefined;

      const purchases = await StoreService.listPurchases(instituteId, { studentId, offeringId });

      res.status(200).json({
        status: 'success',
        data: purchases,
      });
    } catch (err) {
      next(err);
    }
  }

  static async getInvoice(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const purchaseId = req.params.id;
      const user = { role: req.user!.role, userId: req.user!.userId };

      const invoice = await StoreService.getInvoice(instituteId, purchaseId, user);

      res.status(200).json({
        status: 'success',
        data: invoice,
      });
    } catch (err) {
      next(err);
    }
  }

  static async refundPurchase(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const adminId = req.user!.userId;
      const purchaseId = req.params.id;
      const { reason } = refundSchema.parse(req.body);

      const result = await StoreService.processRefund(instituteId, adminId, purchaseId, reason);

      res.status(200).json({
        status: 'success',
        data: result,
      });
    } catch (err) {
      next(err);
    }
  }
}
