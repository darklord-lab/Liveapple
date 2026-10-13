import test, { before } from 'node:test';
import assert from 'node:assert/strict';
import supertest from 'supertest';
import { createApp } from '../app.js';
import { prisma } from '../utils/prisma.js';

const app = createApp();
const request = supertest(app);

test('Phase 4.4 — Institute Links & Student Testimonials Suite', async (t) => {
  let adminToken: string;
  let teacherToken: string;
  let studentToken: string;
  let testLinkId: string;
  let testTestimonialId: string;

  before(async () => {
    // 1. Log in admin
    const adminRes = await request
      .post('/api/v1/auth/login')
      .send({ email: 'admin@apex.edu', password: 'Password@123' });
    assert.equal(adminRes.status, 200);
    adminToken = adminRes.body.accessToken;

    // 2. Log in teacher
    const teacherRes = await request
      .post('/api/v1/auth/login')
      .send({ email: 'teacher1@apex.edu', password: 'Password@123' });
    assert.equal(teacherRes.status, 200);
    teacherToken = teacherRes.body.accessToken;

    // 3. Log in student
    const studentRes = await request
      .post('/api/v1/auth/login')
      .send({ email: 'student1@apex.edu', password: 'Password@123' });
    assert.equal(studentRes.status, 200);
    studentToken = studentRes.body.accessToken;
  });

  /* -------------------------------------------------------------------------- */
  /* INSTITUTE LINKS TESTS                                                      */
  /* -------------------------------------------------------------------------- */
  await t.test('1. Admin creates YouTube, Telegram, and WhatsApp links', async () => {
    const res = await request
      .post('/api/v1/institute/links')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        title: 'Official YouTube Channel',
        platform: 'YOUTUBE',
        url: 'https://youtube.com/@classora',
        order: 1,
      });

    assert.equal(res.status, 201);
    assert.equal(res.body.status, 'success');
    assert.equal(res.body.data.title, 'Official YouTube Channel');
    assert.equal(res.body.data.platform, 'YOUTUBE');
    assert.equal(res.body.data.url, 'https://youtube.com/@classora');
    assert.equal(res.body.data.isActive, true);
    testLinkId = res.body.data.id;

    // Create Telegram link
    const telegramRes = await request
      .post('/api/v1/institute/links')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        title: 'Student Telegram Group',
        platform: 'TELEGRAM',
        url: 'https://t.me/classorastudents',
        order: 2,
      });
    assert.equal(telegramRes.status, 201);
  });

  await t.test('2. Student can fetch active institute links', async () => {
    const res = await request
      .get('/api/v1/institute/links')
      .set('Authorization', `Bearer ${studentToken}`);

    assert.equal(res.status, 200);
    assert.equal(res.body.status, 'success');
    assert(Array.isArray(res.body.data));
    assert(res.body.data.length >= 2);
    const platforms = res.body.data.map((l: any) => l.platform);
    assert(platforms.includes('YOUTUBE'));
    assert(platforms.includes('TELEGRAM'));
  });

  await t.test('3. Student CANNOT create an institute link (403 FORBIDDEN)', async () => {
    const res = await request
      .post('/api/v1/institute/links')
      .set('Authorization', `Bearer ${studentToken}`)
      .send({
        title: 'Hacked Link',
        platform: 'WEBSITE',
        url: 'https://malicious.com',
      });

    assert.equal(res.status, 403);
  });

  await t.test('4. Admin can update a link (URL, order, isActive)', async () => {
    const res = await request
      .patch(`/api/v1/institute/links/${testLinkId}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        url: 'https://youtube.com/@classora_official',
        isActive: false,
      });

    assert.equal(res.status, 200);
    assert.equal(res.body.data.url, 'https://youtube.com/@classora_official');
    assert.equal(res.body.data.isActive, false);
  });

  await t.test('5. Non-admin does not see inactive links; admin with ?all=true sees all', async () => {
    // Student view
    const studentRes = await request
      .get('/api/v1/institute/links')
      .set('Authorization', `Bearer ${studentToken}`);
    assert.equal(studentRes.status, 200);
    const studentLinkIds = studentRes.body.data.map((l: any) => l.id);
    assert(!studentLinkIds.includes(testLinkId), 'Inactive link should be hidden from student');

    // Admin view with ?all=true
    const adminRes = await request
      .get('/api/v1/institute/links?all=true')
      .set('Authorization', `Bearer ${adminToken}`);
    assert.equal(adminRes.status, 200);
    const adminLinkIds = adminRes.body.data.map((l: any) => l.id);
    assert(adminLinkIds.includes(testLinkId), 'Inactive link should be visible to admin with ?all=true');
  });

  await t.test('6. Student CANNOT delete a link (403 FORBIDDEN)', async () => {
    const res = await request
      .delete(`/api/v1/institute/links/${testLinkId}`)
      .set('Authorization', `Bearer ${studentToken}`);

    assert.equal(res.status, 403);
  });

  await t.test('7. Admin can delete a link', async () => {
    const res = await request
      .delete(`/api/v1/institute/links/${testLinkId}`)
      .set('Authorization', `Bearer ${adminToken}`);

    assert.equal(res.status, 200);
    assert.equal(res.body.data.success, true);

    // Verify deleted in DB
    const deleted = await prisma.instituteLink.findUnique({ where: { id: testLinkId } });
    assert.equal(deleted, null);
  });

  /* -------------------------------------------------------------------------- */
  /* TESTIMONIALS TESTS                                                         */
  /* -------------------------------------------------------------------------- */
  await t.test('8. Admin creates a student testimonial', async () => {
    const res = await request
      .post('/api/v1/institute/testimonials')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        studentName: 'Priya Verma',
        batchOrExam: 'JEE Advanced Rank 142',
        quote: 'Classora live classes and digital whiteboard explanations helped me clear all concepts crystal-clear!',
        rating: 5,
        order: 1,
        isPublished: true,
      });

    assert.equal(res.status, 201);
    assert.equal(res.body.data.studentName, 'Priya Verma');
    assert.equal(res.body.data.batchOrExam, 'JEE Advanced Rank 142');
    assert.equal(res.body.data.rating, 5);
    assert.equal(res.body.data.isPublished, true);
    testTestimonialId = res.body.data.id;
  });

  await t.test('9. Student can fetch published testimonials', async () => {
    const res = await request
      .get('/api/v1/institute/testimonials')
      .set('Authorization', `Bearer ${studentToken}`);

    assert.equal(res.status, 200);
    assert(Array.isArray(res.body.data));
    assert(res.body.data.length >= 1);
    assert.equal(res.body.data[0].studentName, 'Priya Verma');
  });

  await t.test('10. Student CANNOT create a testimonial (403 FORBIDDEN)', async () => {
    const res = await request
      .post('/api/v1/institute/testimonials')
      .set('Authorization', `Bearer ${studentToken}`)
      .send({
        studentName: 'Impostor',
        quote: 'Fake testimonial text here',
      });

    assert.equal(res.status, 403);
  });

  await t.test('11. Admin can update a testimonial (quote, rating, isPublished)', async () => {
    const res = await request
      .patch(`/api/v1/institute/testimonials/${testTestimonialId}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        rating: 4,
        isPublished: false,
      });

    assert.equal(res.status, 200);
    assert.equal(res.body.data.rating, 4);
    assert.equal(res.body.data.isPublished, false);
  });

  await t.test('12. Non-admin does not see unpublished testimonials', async () => {
    const res = await request
      .get('/api/v1/institute/testimonials')
      .set('Authorization', `Bearer ${studentToken}`);

    assert.equal(res.status, 200);
    const ids = res.body.data.map((t: any) => t.id);
    assert(!ids.includes(testTestimonialId));
  });

  await t.test('13. Admin can delete a testimonial', async () => {
    const res = await request
      .delete(`/api/v1/institute/testimonials/${testTestimonialId}`)
      .set('Authorization', `Bearer ${adminToken}`);

    assert.equal(res.status, 200);
    assert.equal(res.body.data.success, true);

    const deleted = await prisma.testimonial.findUnique({ where: { id: testTestimonialId } });
    assert.equal(deleted, null);
  });

  await t.test('14. Unauthenticated requests return 401 UNAUTHORIZED', async () => {
    const linksRes = await request.get('/api/v1/institute/links');
    assert.equal(linksRes.status, 401);

    const testRes = await request.get('/api/v1/institute/testimonials');
    assert.equal(testRes.status, 401);
  });
});
