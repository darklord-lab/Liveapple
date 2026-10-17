import test, { before } from 'node:test';
import assert from 'node:assert/strict';
import crypto from 'crypto';
import supertest from 'supertest';
import { createApp } from '../app.js';
import { prisma } from '../utils/prisma.js';
import { env } from '../config/env.js';

const app = createApp();
const request = supertest(app);

test('Phase 6 — Course Store, Coupons, Razorpay & Auto-Enrollment Suite', async (t) => {
  let adminToken: string;
  let teacherToken: string;
  let student1Token: string;
  let student2Token: string;
  let student1Id: string;
  let student2Id: string;
  let instituteId: string;
  let batchId: string;
  let createdOfferingId: string;
  let createdPurchaseId: string;
  let createdCouponCode = 'SAVE20';

  before(async () => {
    // 1. Get institute
    const inst = await prisma.institute.findFirst({ where: { slug: 'apex' } });
    assert.ok(inst);
    instituteId = inst.id;

    // 2. Admin login
    const adminRes = await request
      .post('/api/v1/auth/login')
      .send({ email: 'admin@apex.edu', password: 'Password@123' });
    assert.equal(adminRes.status, 200);
    adminToken = adminRes.body.accessToken;

    // 3. Teacher login
    const teacherRes = await request
      .post('/api/v1/auth/login')
      .send({ email: 'teacher1@apex.edu', password: 'Password@123' });
    assert.equal(teacherRes.status, 200);
    teacherToken = teacherRes.body.accessToken;

    // 4. Student 1 login
    const student1Res = await request
      .post('/api/v1/auth/login')
      .send({ email: 'student1@apex.edu', password: 'Password@123' });
    assert.equal(student1Res.status, 200);
    student1Token = student1Res.body.accessToken;
    student1Id = student1Res.body.user.id;

    // 5. Student 2 login
    const student2Res = await request
      .post('/api/v1/auth/login')
      .send({ email: 'student2@apex.edu', password: 'Password@123' });
    assert.equal(student2Res.status, 200);
    student2Token = student2Res.body.accessToken;
    student2Id = student2Res.body.user.id;

    // 6. Teacher creates an exclusive new course batch for the store
    const batchRes = await request
      .post('/api/v1/batches')
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        name: 'JEE Advanced Masterclass 2026',
        subject: 'Physics',
      });
    assert.equal(batchRes.status, 201);
    batchId = batchRes.body.id || batchRes.body.data?.id;
  });

  await t.test('1. Student CANNOT create a course offering (403 Forbidden)', async () => {
    const res = await request
      .post('/api/v1/store/offerings')
      .set('Authorization', `Bearer ${student1Token}`)
      .send({
        batchId,
        price: 4999,
        mrp: 9999,
      });

    assert.equal(res.status, 403);
  });

  await t.test('2. Admin creates a course offering with discount', async () => {
    const res = await request
      .post('/api/v1/store/offerings')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        batchId,
        title: 'Complete JEE Advanced Physics Masterclass',
        description: 'Full syllabus live lectures, test series, and comprehensive study material',
        price: 4999,
        mrp: 9999,
        isFeatured: true,
        isPublished: true,
      });

    assert.equal(res.status, 201);
    assert.ok(res.body.data.id);
    assert.equal(res.body.data.price, 4999);
    assert.equal(res.body.data.mrp, 9999);
    assert.equal(res.body.data.discountPercent, 50); // 50% discount
    assert.equal(res.body.data.isFeatured, true);

    createdOfferingId = res.body.data.id;
  });

  await t.test('3. Student lists offerings with search & filter (isPurchased = false)', async () => {
    const res = await request
      .get('/api/v1/store/offerings?search=Masterclass&sort=price_desc')
      .set('Authorization', `Bearer ${student1Token}`);

    assert.equal(res.status, 200);
    assert.ok(Array.isArray(res.body.data));
    assert.ok(res.body.data.length >= 1);

    const found = res.body.data.find((o: any) => o.id === createdOfferingId);
    assert.ok(found);
    assert.equal(found.isPurchased, false);
    assert.equal(found.discountPercent, 50);
  });

  await t.test('4. Admin creates a 20% discount coupon', async () => {
    const res = await request
      .post('/api/v1/store/coupons')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        code: createdCouponCode,
        discountType: 'PERCENT',
        discountValue: 20,
        maxUses: 100,
      });

    assert.equal(res.status, 201);
    assert.equal(res.body.data.code, createdCouponCode);
    assert.equal(res.body.data.discountValue, 20);
  });

  await t.test('5. Student validates coupon against offering', async () => {
    const res = await request
      .post('/api/v1/store/coupons/validate')
      .set('Authorization', `Bearer ${student1Token}`)
      .send({
        code: createdCouponCode,
        offeringId: createdOfferingId,
      });

    assert.equal(res.status, 200);
    assert.equal(res.body.data.valid, true);
    assert.equal(res.body.data.originalPrice, 4999);
    // 20% of 4999 = 999.8
    assert.equal(res.body.data.discountAmount, 999.8);
    // 4999 - 999.8 = 3999.2
    assert.equal(res.body.data.finalAmount, 3999.2);
  });

  await t.test('6. Student checkouts offering with coupon -> Auto-enrolls student & creates invoice', async () => {
    const res = await request
      .post('/api/v1/store/checkout')
      .set('Authorization', `Bearer ${student1Token}`)
      .send({
        offeringId: createdOfferingId,
        couponCode: createdCouponCode,
        paymentMethod: 'MOCK',
      });

    assert.equal(res.status, 200);
    assert.equal(res.body.data.status, 'SUCCESS');
    assert.equal(res.body.data.amount, 3999.2);
    assert.ok(res.body.data.invoiceNo);
    assert.ok(res.body.data.purchaseId);
    assert.equal(res.body.data.isEnrolled, true);

    createdPurchaseId = res.body.data.purchaseId;

    // Verify student is now enrolled in the database
    const enrollment = await prisma.enrollment.findUnique({
      where: {
        instituteId_batchId_studentId: {
          instituteId,
          batchId,
          studentId: student1Id,
        },
      },
    });
    assert.ok(enrollment);
    assert.equal(enrollment.status, 'ACTIVE');

    // Verify coupon usage count incremented
    const coupon = await prisma.coupon.findUnique({
      where: {
        instituteId_code: {
          instituteId,
          code: createdCouponCode,
        },
      },
    });
    assert.equal(coupon?.usedCount, 1);
  });

  await t.test('7. Student lists offerings again -> isPurchased is now true', async () => {
    const res = await request
      .get('/api/v1/store/offerings')
      .set('Authorization', `Bearer ${student1Token}`);

    assert.equal(res.status, 200);
    const found = res.body.data.find((o: any) => o.id === createdOfferingId);
    assert.ok(found);
    assert.equal(found.isPurchased, true);
  });

  await t.test('8. Duplicate checkout by enrolled student returns 409 Conflict', async () => {
    const res = await request
      .post('/api/v1/store/checkout')
      .set('Authorization', `Bearer ${student1Token}`)
      .send({
        offeringId: createdOfferingId,
        paymentMethod: 'MOCK',
      });

    assert.equal(res.status, 409);
    assert.match(res.body.message, /already enrolled/i);
  });

  await t.test('9. Student views their purchase invoice breakdown', async () => {
    const res = await request
      .get(`/api/v1/store/purchases/${createdPurchaseId}/invoice`)
      .set('Authorization', `Bearer ${student1Token}`);

    assert.equal(res.status, 200);
    assert.ok(res.body.data.invoiceNo);
    assert.equal(res.body.data.status, 'SUCCESS');
    assert.equal(res.body.data.pricing.basePrice, 4999);
    assert.equal(res.body.data.pricing.discount, 999.8);
    assert.equal(res.body.data.pricing.netPaid, 3999.2);
    assert.equal(res.body.data.pricing.couponCode, createdCouponCode);
    assert.equal(res.body.data.student.id, student1Id);
  });

  await t.test('10. Other student CANNOT view student1 invoice (403 Forbidden)', async () => {
    const res = await request
      .get(`/api/v1/store/purchases/${createdPurchaseId}/invoice`)
      .set('Authorization', `Bearer ${student2Token}`);

    assert.equal(res.status, 403);
  });

  await t.test('11. Razorpay signature verification & verification endpoint', async () => {
    const orderId = 'order_test_998877';
    const paymentId = 'pay_test_112233';
    const secret = env.RAZORPAY_KEY_SECRET;

    // Generate valid HMAC SHA256 signature
    const validSignature = crypto
      .createHmac('sha256', secret)
      .update(`${orderId}|${paymentId}`)
      .digest('hex');

    // Student 2 purchases via verifyPayment
    const res = await request
      .post('/api/v1/store/verify-payment')
      .set('Authorization', `Bearer ${student2Token}`)
      .send({
        orderId,
        paymentId,
        signature: validSignature,
        offeringId: createdOfferingId,
      });

    assert.equal(res.status, 200);
    assert.equal(res.body.data.status, 'SUCCESS');
    assert.equal(res.body.data.isEnrolled, true);

    // Verify student 2 is now also enrolled
    const enrollment = await prisma.enrollment.findUnique({
      where: {
        instituteId_batchId_studentId: {
          instituteId,
          batchId,
          studentId: student2Id,
        },
      },
    });
    assert.ok(enrollment);
    assert.equal(enrollment.status, 'ACTIVE');

    // Test rejection of forged signature
    const forgedRes = await request
      .post('/api/v1/store/verify-payment')
      .set('Authorization', `Bearer ${student2Token}`)
      .send({
        orderId: 'order_fake_123',
        paymentId: 'pay_fake_456',
        signature: 'invalid_forged_signature_hex_value',
        offeringId: createdOfferingId,
      });

    assert.equal(forgedRes.status, 400);
  });

  await t.test('12. Admin processes refund -> Status updated to REFUNDED & enrollment suspended', async () => {
    const res = await request
      .post(`/api/v1/store/purchases/${createdPurchaseId}/refund`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        reason: 'Student requested batch switch within refund window',
      });

    assert.equal(res.status, 200);
    assert.equal(res.body.data.status, 'REFUNDED');
    assert.equal(res.body.data.enrollmentSuspended, true);

    // Verify student 1 enrollment is now suspended
    const enrollment = await prisma.enrollment.findUnique({
      where: {
        instituteId_batchId_studentId: {
          instituteId,
          batchId,
          studentId: student1Id,
        },
      },
    });
    assert.equal(enrollment?.status, 'SUSPENDED');
  });
});
