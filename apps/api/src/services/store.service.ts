import crypto from 'crypto';
import { prisma } from '../utils/prisma.js';
import { AppError } from '../errors/AppError.js';
import { env } from '../config/env.js';
import { logAudit } from './audit.service.js';
import { NotificationService } from './notification.service.js';

export interface CreateOfferingInput {
  batchId: string;
  price: number;
  mrp: number;
  title?: string;
  description?: string;
  thumbnailUrl?: string;
  isFeatured?: boolean;
  isPublished?: boolean;
}

export interface UpdateOfferingInput {
  price?: number;
  mrp?: number;
  title?: string;
  description?: string;
  thumbnailUrl?: string;
  isFeatured?: boolean;
  isPublished?: boolean;
}

export interface CreateCouponInput {
  code: string;
  discountType?: 'PERCENT' | 'FLAT';
  discountValue: number;
  validTill?: string | Date;
  maxUses?: number;
}

export interface CheckoutInput {
  offeringId: string;
  couponCode?: string;
  paymentMethod?: 'RAZORPAY' | 'MOCK' | 'UPI';
}

export interface VerifyPaymentInput {
  orderId: string;
  paymentId: string;
  signature: string;
  offeringId: string;
  couponCode?: string;
}

export class StoreService {
  /**
   * Helper: Generate unique invoice number
   */
  private static generateInvoiceNo(): string {
    const year = new Date().getFullYear();
    const random = Math.floor(100000 + Math.random() * 900000);
    return `INV-${year}-${random}`;
  }

  /**
   * Helper: Generate unique transaction ID
   */
  private static generateTransactionId(): string {
    return `txn_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
  }

  /**
   * Helper: Verify Razorpay signature using HMAC-SHA256
   */
  static verifyRazorpaySignature(
    orderId: string,
    paymentId: string,
    signature: string,
    secret = env.RAZORPAY_KEY_SECRET
  ): boolean {
    try {
      const generated = crypto
        .createHmac('sha256', secret)
        .update(`${orderId}|${paymentId}`)
        .digest('hex');
      return crypto.timingSafeEqual(Buffer.from(generated), Buffer.from(signature));
    } catch {
      return false;
    }
  }

  /**
   * Helper: Verify Razorpay Webhook signature
   */
  static verifyWebhookSignature(
    rawBody: string | Buffer,
    signature: string,
    secret = env.RAZORPAY_WEBHOOK_SECRET
  ): boolean {
    try {
      const generated = crypto
        .createHmac('sha256', secret)
        .update(rawBody)
        .digest('hex');
      return crypto.timingSafeEqual(Buffer.from(generated), Buffer.from(signature));
    } catch {
      return false;
    }
  }

  // ==========================================
  // 1. OFFERINGS MANAGEMENT
  // ==========================================

  /**
   * Admin creates a new course store offering for a batch
   */
  static async createOffering(instituteId: string, input: CreateOfferingInput) {
    const { batchId, price, mrp, title, description, thumbnailUrl, isFeatured = false, isPublished = true } = input;

    if (!batchId) {
      throw new AppError('BAD_REQUEST', 'Batch ID is required for offering', 400);
    }
    if (typeof price !== 'number' || price <= 0) {
      throw new AppError('BAD_REQUEST', 'Valid positive selling price is required', 400);
    }
    if (typeof mrp !== 'number' || mrp < price) {
      throw new AppError('BAD_REQUEST', 'MRP must be greater than or equal to selling price', 400);
    }

    const batch = await prisma.batch.findFirst({
      where: { id: batchId, instituteId },
    });
    if (!batch) {
      throw new AppError('NOT_FOUND', 'Target batch not found in this institute', 404);
    }

    const offering = await prisma.offering.create({
      data: {
        instituteId,
        batchId,
        title: title?.trim() || batch.name,
        description: description?.trim() || null,
        thumbnailUrl: thumbnailUrl?.trim() || null,
        price,
        mrp,
        isFeatured,
        isPublished,
      },
      include: {
        batch: {
          select: { id: true, name: true, subject: true, teacher: { select: { id: true, name: true } } },
        },
      },
    });

    return {
      ...offering,
      discountPercent: mrp > 0 ? Math.round(((mrp - price) / mrp) * 100) : 0,
    };
  }

  /**
   * List course offerings with search, filter, and sort
   */
  static async listOfferings(
    instituteId: string,
    options: {
      search?: string;
      batchId?: string;
      isFeatured?: boolean;
      minPrice?: number;
      maxPrice?: number;
      sort?: string;
      studentId?: string;
      purchasedFilter?: 'ALL' | 'PURCHASED' | 'AVAILABLE';
      publishedOnly?: boolean;
    } = {}
  ) {
    const {
      search,
      batchId,
      isFeatured,
      minPrice,
      maxPrice,
      sort = 'newest',
      studentId,
      purchasedFilter = 'ALL',
      publishedOnly = true,
    } = options;

    const whereClause: Record<string, unknown> = {
      instituteId,
      ...(publishedOnly ? { isPublished: true } : {}),
      ...(isFeatured !== undefined ? { isFeatured } : {}),
      ...(batchId ? { batchId } : {}),
    };

    if (minPrice !== undefined || maxPrice !== undefined) {
      whereClause.price = {
        ...(minPrice !== undefined ? { gte: minPrice } : {}),
        ...(maxPrice !== undefined ? { lte: maxPrice } : {}),
      };
    }

    if (search && search.trim().length > 0) {
      const q = search.trim();
      whereClause.OR = [
        { title: { contains: q } },
        { description: { contains: q } },
        { batch: { name: { contains: q } } },
        { batch: { subject: { contains: q } } },
      ];
    }

    let orderBy: Record<string, 'asc' | 'desc'> = { createdAt: 'desc' };
    if (sort === 'price_asc') {
      orderBy = { price: 'asc' };
    } else if (sort === 'price_desc') {
      orderBy = { price: 'desc' };
    } else if (sort === 'oldest') {
      orderBy = { createdAt: 'asc' };
    }

    const rawOfferings = await prisma.offering.findMany({
      where: whereClause,
      orderBy,
      include: {
        batch: {
          select: {
            id: true,
            name: true,
            subject: true,
            teacher: { select: { id: true, name: true, avatarUrl: true } },
          },
        },
        _count: {
          select: { purchases: true },
        },
      },
    });

    // Check student enrolled / purchased status if studentId provided
    let enrolledBatchIds = new Set<string>();
    let purchasedOfferingIds = new Set<string>();

    if (studentId) {
      const [enrollments, purchases] = await Promise.all([
        prisma.enrollment.findMany({
          where: { instituteId, studentId, status: 'ACTIVE' },
          select: { batchId: true },
        }),
        prisma.purchase.findMany({
          where: { instituteId, studentId, status: 'SUCCESS' },
          select: { offeringId: true },
        }),
      ]);

      enrolledBatchIds = new Set(enrollments.map((e) => e.batchId));
      purchasedOfferingIds = new Set(purchases.map((p) => p.offeringId));
    }

    const processed = rawOfferings.map((offering) => {
      const isPurchased =
        purchasedOfferingIds.has(offering.id) || enrolledBatchIds.has(offering.batchId);
      const discountPercent =
        offering.mrp > 0 ? Math.round(((offering.mrp - offering.price) / offering.mrp) * 100) : 0;

      return {
        ...offering,
        isPurchased,
        discountPercent,
        totalEnrolled: offering._count.purchases,
      };
    });

    // Filter by purchased status if requested
    if (purchasedFilter === 'PURCHASED') {
      return processed.filter((o) => o.isPurchased);
    } else if (purchasedFilter === 'AVAILABLE') {
      return processed.filter((o) => !o.isPurchased);
    }

    return processed;
  }

  /**
   * Get single offering details by ID
   */
  static async getOfferingById(instituteId: string, offeringId: string, studentId?: string) {
    const offering = await prisma.offering.findFirst({
      where: { id: offeringId, instituteId },
      include: {
        batch: {
          select: {
            id: true,
            name: true,
            subject: true,
            teacher: { select: { id: true, name: true, avatarUrl: true } },
          },
        },
        _count: { select: { purchases: true } },
      },
    });

    if (!offering) {
      throw new AppError('NOT_FOUND', 'Offering not found', 404);
    }

    let isPurchased = false;
    if (studentId) {
      const existing = await prisma.purchase.findFirst({
        where: { instituteId, studentId, offeringId, status: 'SUCCESS' },
      });
      const enrollment = await prisma.enrollment.findFirst({
        where: { instituteId, studentId, batchId: offering.batchId, status: 'ACTIVE' },
      });
      isPurchased = Boolean(existing || enrollment);
    }

    const discountPercent =
      offering.mrp > 0 ? Math.round(((offering.mrp - offering.price) / offering.mrp) * 100) : 0;

    return {
      ...offering,
      isPurchased,
      discountPercent,
      totalEnrolled: offering._count.purchases,
    };
  }

  /**
   * Update offering details (Admin)
   */
  static async updateOffering(instituteId: string, offeringId: string, input: UpdateOfferingInput) {
    const existing = await prisma.offering.findFirst({
      where: { id: offeringId, instituteId },
    });
    if (!existing) {
      throw new AppError('NOT_FOUND', 'Offering not found', 404);
    }

    const price = input.price !== undefined ? input.price : existing.price;
    const mrp = input.mrp !== undefined ? input.mrp : existing.mrp;

    if (price <= 0) {
      throw new AppError('BAD_REQUEST', 'Price must be positive', 400);
    }
    if (mrp < price) {
      throw new AppError('BAD_REQUEST', 'MRP must be greater than or equal to price', 400);
    }

    const updated = await prisma.offering.update({
      where: { id: offeringId },
      data: {
        price,
        mrp,
        title: input.title !== undefined ? input.title.trim() : existing.title,
        description: input.description !== undefined ? input.description?.trim() || null : existing.description,
        thumbnailUrl: input.thumbnailUrl !== undefined ? input.thumbnailUrl?.trim() || null : existing.thumbnailUrl,
        isFeatured: input.isFeatured !== undefined ? input.isFeatured : existing.isFeatured,
        isPublished: input.isPublished !== undefined ? input.isPublished : existing.isPublished,
      },
      include: {
        batch: { select: { id: true, name: true, subject: true } },
      },
    });

    return {
      ...updated,
      discountPercent: mrp > 0 ? Math.round(((mrp - price) / mrp) * 100) : 0,
    };
  }

  /**
   * Delete offering (Admin)
   */
  static async deleteOffering(instituteId: string, offeringId: string) {
    const existing = await prisma.offering.findFirst({
      where: { id: offeringId, instituteId },
    });
    if (!existing) {
      throw new AppError('NOT_FOUND', 'Offering not found', 404);
    }

    await prisma.offering.delete({
      where: { id: offeringId },
    });

    return { success: true, deletedOfferingId: offeringId };
  }

  // ==========================================
  // 2. COUPON MANAGEMENT & VALIDATION
  // ==========================================

  /**
   * Admin creates coupon
   */
  static async createCoupon(instituteId: string, input: CreateCouponInput) {
    const { code, discountType = 'PERCENT', discountValue, validTill, maxUses } = input;

    if (!code || code.trim().length < 2) {
      throw new AppError('BAD_REQUEST', 'Coupon code is required (min 2 chars)', 400);
    }
    if (typeof discountValue !== 'number' || discountValue <= 0) {
      throw new AppError('BAD_REQUEST', 'Discount value must be positive', 400);
    }
    if (discountType === 'PERCENT' && discountValue > 100) {
      throw new AppError('BAD_REQUEST', 'Percentage discount cannot exceed 100%', 400);
    }

    const normalizedCode = code.trim().toUpperCase();

    const existing = await prisma.coupon.findUnique({
      where: {
        instituteId_code: {
          instituteId,
          code: normalizedCode,
        },
      },
    });
    if (existing) {
      throw new AppError('CONFLICT', `Coupon code "${normalizedCode}" already exists`, 409);
    }

    const coupon = await prisma.coupon.create({
      data: {
        instituteId,
        code: normalizedCode,
        discountType,
        discountValue,
        validTill: validTill ? new Date(validTill) : null,
        maxUses: maxUses && maxUses > 0 ? maxUses : null,
      },
    });

    return coupon;
  }

  /**
   * List coupons in institute (Admin)
   */
  static async listCoupons(instituteId: string) {
    return prisma.coupon.findMany({
      where: { instituteId },
      orderBy: { createdAt: 'desc' },
      include: {
        _count: { select: { purchases: true } },
      },
    });
  }

  /**
   * Validate coupon code against offering and compute final payable amount
   */
  static async validateCoupon(instituteId: string, code: string, offeringId: string) {
    if (!code || code.trim().length === 0) {
      throw new AppError('BAD_REQUEST', 'Coupon code is required', 400);
    }
    if (!offeringId) {
      throw new AppError('BAD_REQUEST', 'Offering ID is required', 400);
    }

    const offering = await prisma.offering.findFirst({
      where: { id: offeringId, instituteId },
    });
    if (!offering) {
      throw new AppError('NOT_FOUND', 'Offering not found', 404);
    }

    const normalizedCode = code.trim().toUpperCase();

    const coupon = await prisma.coupon.findUnique({
      where: {
        instituteId_code: {
          instituteId,
          code: normalizedCode,
        },
      },
    });

    if (!coupon || !coupon.isActive) {
      throw new AppError('NOT_FOUND', `Invalid or inactive coupon code "${normalizedCode}"`, 404);
    }

    if (coupon.validTill && new Date() > coupon.validTill) {
      throw new AppError('BAD_REQUEST', `Coupon code "${normalizedCode}" has expired`, 400);
    }

    if (coupon.maxUses !== null && coupon.usedCount >= coupon.maxUses) {
      throw new AppError('BAD_REQUEST', `Coupon code "${normalizedCode}" usage limit reached`, 400);
    }

    let discountAmount = 0;
    if (coupon.discountType === 'PERCENT') {
      discountAmount = Math.round(((offering.price * coupon.discountValue) / 100) * 100) / 100;
      discountAmount = Math.min(discountAmount, offering.price);
    } else {
      discountAmount = Math.min(coupon.discountValue, offering.price);
    }

    const finalAmount = Math.max(0, Math.round((offering.price - discountAmount) * 100) / 100);

    return {
      valid: true,
      coupon: {
        id: coupon.id,
        code: coupon.code,
        discountType: coupon.discountType,
        discountValue: coupon.discountValue,
      },
      originalPrice: offering.price,
      discountAmount,
      finalAmount,
    };
  }

  // ==========================================
  // 3. CHECKOUT, VERIFY & AUTO-ENROLLMENT
  // ==========================================

  /**
   * Student initiates checkout
   * If mock or free course: immediately completes purchase and auto-enrolls student!
   * If Razorpay configured: creates order and returns orderId.
   */
  static async checkout(
    instituteId: string,
    studentId: string,
    input: CheckoutInput
  ) {
    const { offeringId, couponCode, paymentMethod = 'MOCK' } = input;

    const offering = await prisma.offering.findFirst({
      where: { id: offeringId, instituteId },
      include: {
        batch: { select: { id: true, name: true, subject: true } },
      },
    });

    if (!offering || !offering.isPublished) {
      throw new AppError('NOT_FOUND', 'Course offering is not available for purchase', 404);
    }

    // Check if student is already actively enrolled in this batch
    const existingEnrollment = await prisma.enrollment.findUnique({
      where: {
        instituteId_batchId_studentId: {
          instituteId,
          batchId: offering.batchId,
          studentId,
        },
      },
    });
    if (existingEnrollment && existingEnrollment.status === 'ACTIVE') {
      throw new AppError('CONFLICT', `You are already enrolled in batch "${offering.batch.name}"`, 409);
    }

    // Compute coupon discount
    let couponId: string | null = null;
    let discountAmount = 0;
    let finalAmount = offering.price;

    if (couponCode && couponCode.trim().length > 0) {
      const validation = await this.validateCoupon(instituteId, couponCode, offeringId);
      couponId = validation.coupon.id;
      discountAmount = validation.discountAmount;
      finalAmount = validation.finalAmount;
    }

    // If Razorpay requested and configured: create order
    const isRealRazorpay =
      paymentMethod === 'RAZORPAY' &&
      env.RAZORPAY_KEY_ID &&
      env.RAZORPAY_KEY_ID !== 'rzp_test_placeholder' &&
      finalAmount > 0;

    if (isRealRazorpay) {
      const razorpayOrderId = `order_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`;
      return {
        mode: 'RAZORPAY',
        orderId: razorpayOrderId,
        amount: Math.round(finalAmount * 100), // amount in paise
        currency: 'INR',
        keyId: env.RAZORPAY_KEY_ID,
        offering: {
          id: offering.id,
          title: offering.title,
          batchName: offering.batch.name,
        },
        discountAmount,
        finalAmount,
      };
    }

    // Otherwise: Process instant checkout (Mock/Direct)
    const transactionId = this.generateTransactionId();
    const invoiceNo = this.generateInvoiceNo();

    const [purchase] = await prisma.$transaction([
      prisma.purchase.create({
        data: {
          instituteId,
          offeringId,
          studentId,
          amount: finalAmount,
          discount: discountAmount,
          couponId,
          paymentMethod,
          transactionId,
          status: 'SUCCESS',
          invoiceNo,
          purchasedAt: new Date(),
        },
        include: {
          offering: { select: { id: true, title: true, batchId: true } },
          student: { select: { id: true, name: true, email: true } },
        },
      }),
      // Auto-enroll student into the course batch
      prisma.enrollment.upsert({
        where: {
          instituteId_batchId_studentId: {
            instituteId,
            batchId: offering.batchId,
            studentId,
          },
        },
        update: {
          status: 'ACTIVE',
        },
        create: {
          instituteId,
          batchId: offering.batchId,
          studentId,
          status: 'ACTIVE',
        },
      }),
      // Increment coupon usage count if applied
      ...(couponId
        ? [
            prisma.coupon.update({
              where: { id: couponId },
              data: { usedCount: { increment: 1 } },
            }),
          ]
        : []),
    ]);

    // Dispatch in-app notification & emit socket event
    await NotificationService.sendMulticastNotification({
      instituteId,
      userIds: [studentId],
      type: 'BATCH_ENROLL',
      title: '🎉 Course Enrollment Confirmed!',
      body: `You are now enrolled in "${offering.batch.name}". All live classes and study materials are unlocked!`,
      batchId: offering.batchId,
      data: {
        invoiceNo,
        batchId: offering.batchId,
        deepLink: `/batches/${offering.batchId}`,
      },
    });

    await logAudit({
      instituteId,
      actorId: studentId,
      action: 'COURSE_PURCHASED',
      entity: `Purchase:${purchase.id}`,
      meta: { offeringId, amount: finalAmount, invoiceNo, transactionId, batchId: offering.batchId },
    });

    return {
      mode: 'INSTANT',
      status: 'SUCCESS',
      purchaseId: purchase.id,
      invoiceNo,
      transactionId,
      amount: finalAmount,
      discount: discountAmount,
      batchId: offering.batchId,
      batchName: offering.batch.name,
      isEnrolled: true,
    };
  }

  /**
   * Verify Razorpay payment signature and complete enrollment
   */
  static async verifyPayment(
    instituteId: string,
    studentId: string,
    input: VerifyPaymentInput
  ) {
    const { orderId, paymentId, signature, offeringId, couponCode } = input;

    if (!orderId || !paymentId || !signature) {
      throw new AppError('BAD_REQUEST', 'Missing payment verification credentials', 400);
    }

    // Verify HMAC SHA256 signature
    const isValid = this.verifyRazorpaySignature(orderId, paymentId, signature);
    if (!isValid) {
      throw new AppError('BAD_REQUEST', 'Invalid payment signature. Verification failed.', 400);
    }

    const offering = await prisma.offering.findFirst({
      where: { id: offeringId, instituteId },
      include: { batch: { select: { id: true, name: true } } },
    });
    if (!offering) {
      throw new AppError('NOT_FOUND', 'Course offering not found', 404);
    }

    // Calculate amounts
    let couponId: string | null = null;
    let discountAmount = 0;
    let finalAmount = offering.price;

    if (couponCode && couponCode.trim().length > 0) {
      try {
        const validation = await this.validateCoupon(instituteId, couponCode, offeringId);
        couponId = validation.coupon.id;
        discountAmount = validation.discountAmount;
        finalAmount = validation.finalAmount;
      } catch {
        // Fallback to offering price if coupon fails
      }
    }

    const transactionId = paymentId;
    const invoiceNo = this.generateInvoiceNo();

    const [purchase] = await prisma.$transaction([
      prisma.purchase.create({
        data: {
          instituteId,
          offeringId,
          studentId,
          amount: finalAmount,
          discount: discountAmount,
          couponId,
          paymentMethod: 'RAZORPAY',
          transactionId,
          orderId,
          status: 'SUCCESS',
          invoiceNo,
          purchasedAt: new Date(),
        },
      }),
      // Auto-enroll student into batch
      prisma.enrollment.upsert({
        where: {
          instituteId_batchId_studentId: {
            instituteId,
            batchId: offering.batchId,
            studentId,
          },
        },
        update: { status: 'ACTIVE' },
        create: {
          instituteId,
          batchId: offering.batchId,
          studentId,
          status: 'ACTIVE',
        },
      }),
      ...(couponId
        ? [
            prisma.coupon.update({
              where: { id: couponId },
              data: { usedCount: { increment: 1 } },
            }),
          ]
        : []),
    ]);

    await NotificationService.sendMulticastNotification({
      instituteId,
      userIds: [studentId],
      type: 'BATCH_ENROLL',
      title: '🎉 Course Enrollment Confirmed!',
      body: `Payment verified! You are now enrolled in "${offering.batch.name}".`,
      batchId: offering.batchId,
      data: { invoiceNo, deepLink: `/batches/${offering.batchId}` },
    });

    return {
      status: 'SUCCESS',
      purchaseId: purchase.id,
      invoiceNo,
      transactionId,
      amount: finalAmount,
      batchId: offering.batchId,
      batchName: offering.batch.name,
      isEnrolled: true,
    };
  }

  /**
   * Handle Razorpay Webhooks (signature verified)
   */
  static async handleWebhook(instituteId: string, rawBody: string, signature: string) {
    if (!signature) {
      throw new AppError('UNAUTHORIZED', 'Missing webhook signature', 401);
    }

    const isValid = this.verifyWebhookSignature(rawBody, signature);
    if (!isValid) {
      throw new AppError('FORBIDDEN', 'Invalid webhook signature', 403);
    }

    const event = JSON.parse(rawBody);
    const eventType = event.event;

    if (eventType === 'payment.captured' || eventType === 'order.paid') {
      const paymentEntity = event.payload?.payment?.entity;
      const orderId = paymentEntity?.order_id;
      const paymentId = paymentEntity?.id;

      if (orderId && paymentId) {
        // Find existing purchase or mark complete
        const purchase = await prisma.purchase.findFirst({
          where: { orderId, instituteId },
          include: { offering: true },
        });

        if (purchase && purchase.status === 'PENDING') {
          await prisma.$transaction([
            prisma.purchase.update({
              where: { id: purchase.id },
              data: { status: 'SUCCESS' },
            }),
            prisma.enrollment.upsert({
              where: {
                instituteId_batchId_studentId: {
                  instituteId,
                  batchId: purchase.offering.batchId,
                  studentId: purchase.studentId,
                },
              },
              update: { status: 'ACTIVE' },
              create: {
                instituteId,
                batchId: purchase.offering.batchId,
                studentId: purchase.studentId,
                status: 'ACTIVE',
              },
            }),
          ]);
        }
      }
    }

    return { received: true, event: eventType };
  }

  // ==========================================
  // 4. PURCHASES, INVOICES & REFUNDS
  // ==========================================

  /**
   * List purchases for user or institute
   */
  static async listPurchases(
    instituteId: string,
    options: { studentId?: string; offeringId?: string } = {}
  ) {
    const { studentId, offeringId } = options;

    return prisma.purchase.findMany({
      where: {
        instituteId,
        ...(studentId ? { studentId } : {}),
        ...(offeringId ? { offeringId } : {}),
      },
      orderBy: { purchasedAt: 'desc' },
      include: {
        offering: {
          select: {
            id: true,
            title: true,
            price: true,
            mrp: true,
            batch: { select: { id: true, name: true, subject: true } },
          },
        },
        student: { select: { id: true, name: true, email: true, phone: true } },
        coupon: { select: { id: true, code: true, discountType: true, discountValue: true } },
      },
    });
  }

  /**
   * Get detailed invoice breakdown
   */
  static async getInvoice(
    instituteId: string,
    purchaseId: string,
    user: { role: string; userId: string }
  ) {
    const purchase = await prisma.purchase.findFirst({
      where: { id: purchaseId, instituteId },
      include: {
        institute: { select: { id: true, name: true, code: true, logoUrl: true, primaryColor: true } },
        offering: {
          select: {
            id: true,
            title: true,
            price: true,
            mrp: true,
            batch: { select: { id: true, name: true, subject: true } },
          },
        },
        student: { select: { id: true, name: true, email: true, phone: true } },
        coupon: { select: { id: true, code: true, discountType: true, discountValue: true } },
      },
    });

    if (!purchase) {
      throw new AppError('NOT_FOUND', 'Invoice not found', 404);
    }

    // If student, can only view their own invoice
    if (user.role === 'STUDENT' && purchase.studentId !== user.userId) {
      throw new AppError('FORBIDDEN', 'Access denied to this invoice', 403);
    }

    return {
      invoiceNo: purchase.invoiceNo,
      transactionId: purchase.transactionId,
      status: purchase.status,
      purchasedAt: purchase.purchasedAt,
      paymentMethod: purchase.paymentMethod,
      institute: purchase.institute,
      student: purchase.student,
      course: {
        offeringId: purchase.offering.id,
        title: purchase.offering.title,
        batchName: purchase.offering.batch.name,
        subject: purchase.offering.batch.subject,
      },
      pricing: {
        mrp: purchase.offering.mrp,
        basePrice: purchase.offering.price,
        couponCode: purchase.coupon?.code || null,
        discount: purchase.discount,
        netPaid: purchase.amount,
        currency: 'INR',
      },
    };
  }

  /**
   * Process refund for a purchase (Admin only)
   */
  static async processRefund(
    instituteId: string,
    adminId: string,
    purchaseId: string,
    reason?: string
  ) {
    const purchase = await prisma.purchase.findFirst({
      where: { id: purchaseId, instituteId },
      include: { offering: true },
    });

    if (!purchase) {
      throw new AppError('NOT_FOUND', 'Purchase not found', 404);
    }
    if (purchase.status === 'REFUNDED') {
      throw new AppError('BAD_REQUEST', 'Purchase is already refunded', 400);
    }

    const [updatedPurchase] = await prisma.$transaction([
      prisma.purchase.update({
        where: { id: purchaseId },
        data: { status: 'REFUNDED' },
      }),
      // Suspend enrollment
      prisma.enrollment.updateMany({
        where: {
          instituteId,
          batchId: purchase.offering.batchId,
          studentId: purchase.studentId,
        },
        data: { status: 'SUSPENDED' },
      }),
    ]);

    await logAudit({
      instituteId,
      actorId: adminId,
      action: 'COURSE_REFUND_PROCESSED',
      entity: `Purchase:${purchaseId}`,
      meta: { purchaseId, amount: purchase.amount, reason },
    });

    return {
      success: true,
      purchaseId,
      status: 'REFUNDED',
      amountRefunded: purchase.amount,
      enrollmentSuspended: true,
    };
  }
}
