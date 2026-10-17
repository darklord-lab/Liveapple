import test, { before } from 'node:test';
import assert from 'node:assert/strict';
import supertest from 'supertest';
import { createApp } from '../app.js';
import { prisma } from '../utils/prisma.js';

const app = createApp();
const request = supertest(app);

test('Phase 4.5 — Institute Code & White-Label Branding Suite', async (t) => {
  let adminToken: string;
  let teacherToken: string;
  let studentToken: string;
  let apexInstituteId: string;

  before(async () => {
    // Ensure apex institute has APEX01 code
    const inst = await prisma.institute.findFirst({ where: { slug: 'apex' } });
    if (inst) {
      apexInstituteId = inst.id;
      await prisma.institute.update({
        where: { id: inst.id },
        data: {
          code: 'APEX01',
          primaryColor: '#0A9BE8',
          tagline: 'Premier IIT-JEE & Medical Academy',
        },
      });
    }

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
  /* 1. PUBLIC CODE LOOKUP (FIRST LAUNCH / UNREGISTERED USER)                   */
  /* -------------------------------------------------------------------------- */
  await t.test('1. Public lookup by uppercase institute code returns branding and links', async () => {
    const res = await request.get('/api/v1/institute/lookup/APEX01');
    assert.equal(res.status, 200);
    assert.equal(res.body.status, 'success');
    assert.equal(res.body.data.institute.code, 'APEX01');
    assert.equal(res.body.data.institute.name, 'Apex IIT-JEE & Medical Academy');
    assert.equal(res.body.data.institute.primaryColor, '#0A9BE8');
    assert.ok(Array.isArray(res.body.data.links));
  });

  await t.test('2. Public lookup is case-insensitive and also resolves by slug', async () => {
    const res = await request.get('/api/v1/institute/lookup/apex');
    assert.equal(res.status, 200);
    assert.equal(res.body.status, 'success');
    assert.equal(res.body.data.institute.slug, 'apex');
  });

  await t.test('3. Public lookup with unknown code returns 404 NOT_FOUND', async () => {
    const res = await request.get('/api/v1/institute/lookup/NONEXISTENT999');
    assert.equal(res.status, 404);
  });

  /* -------------------------------------------------------------------------- */
  /* 2. AUTHENTICATED BRANDING RETRIEVAL                                        */
  /* -------------------------------------------------------------------------- */
  await t.test('4. Student can fetch current institute white-label branding', async () => {
    const res = await request
      .get('/api/v1/institute/branding')
      .set('Authorization', `Bearer ${studentToken}`);
    assert.equal(res.status, 200);
    assert.equal(res.body.data.code, 'APEX01');
    assert.equal(res.body.data.primaryColor, '#0A9BE8');
  });

  await t.test('5. Unauthenticated request to /branding returns 401 UNAUTHORIZED', async () => {
    const res = await request.get('/api/v1/institute/branding');
    assert.equal(res.status, 401);
  });

  /* -------------------------------------------------------------------------- */
  /* 3. PERMISSIONS & RBAC GUARDS                                               */
  /* -------------------------------------------------------------------------- */
  await t.test('6. Student CANNOT update institute branding (403 FORBIDDEN)', async () => {
    const res = await request
      .patch('/api/v1/institute/branding')
      .set('Authorization', `Bearer ${studentToken}`)
      .send({ primaryColor: '#FF0000' });
    assert.equal(res.status, 403);
  });

  await t.test('7. Teacher CANNOT update institute branding (403 FORBIDDEN)', async () => {
    const res = await request
      .patch('/api/v1/institute/branding')
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({ primaryColor: '#FF0000' });
    assert.equal(res.status, 403);
  });

  /* -------------------------------------------------------------------------- */
  /* 4. ADMIN BRANDING MUTATION & VALIDATION                                    */
  /* -------------------------------------------------------------------------- */
  await t.test('8. Admin updates branding (name, primaryColor, logoUrl, tagline)', async () => {
    const res = await request
      .patch('/api/v1/institute/branding')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        name: 'Apex Super Academy',
        primaryColor: '#0284C7',
        logoUrl: 'https://example.com/branding/apex-logo.png',
        tagline: 'Leading the Future of IIT & Medical Education',
      });
    assert.equal(res.status, 200);
    assert.equal(res.body.data.name, 'Apex Super Academy');
    assert.equal(res.body.data.primaryColor, '#0284C7');
    assert.equal(res.body.data.logoUrl, 'https://example.com/branding/apex-logo.png');
    assert.equal(res.body.data.tagline, 'Leading the Future of IIT & Medical Education');
  });

  await t.test('9. Rejects invalid hex color format with 400 BAD_REQUEST', async () => {
    const res = await request
      .patch('/api/v1/institute/branding')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ primaryColor: 'rgb(255,0,0)' });
    assert.equal(res.status, 400);
  });

  await t.test('10. Rejects invalid code format with 400 BAD_REQUEST', async () => {
    const res = await request
      .patch('/api/v1/institute/branding')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ code: 'AB' }); // < 3 characters
    assert.equal(res.status, 400);
  });

  await t.test('11. Prevents duplicate code collision across institutes (409 CONFLICT)', async () => {
    // Create a temporary second institute
    const secondInst = await prisma.institute.create({
      data: {
        name: 'Target Institute',
        slug: 'target-inst-unique',
        code: 'TARGET01',
      },
    });

    try {
      // Admin of Apex attempts to set Apex code to TARGET01
      const res = await request
        .patch('/api/v1/institute/branding')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ code: 'TARGET01' });
      assert.equal(res.status, 409);
    } finally {
      await prisma.institute.delete({ where: { id: secondInst.id } });
    }
  });

  await t.test('12. Login and /me return updated branding properties', async () => {
    const meRes = await request
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${adminToken}`);
    assert.equal(meRes.status, 200);
    assert.equal(meRes.body.user.institute.primaryColor, '#0284C7');
    assert.equal(meRes.body.user.institute.code, 'APEX01');

    // Restore apex name and color for subsequent tests
    await request
      .patch('/api/v1/institute/branding')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        name: 'Apex IIT-JEE & Medical Academy',
        primaryColor: '#0A9BE8',
        tagline: 'Premier IIT-JEE & Medical Academy',
      });
  });
});
