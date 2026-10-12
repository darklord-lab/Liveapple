import { describe, it, before } from 'node:test';
import assert from 'node:assert/strict';
import request from 'supertest';
import { createApp } from '../app.js';
import { initializePrisma, prisma } from '../utils/prisma.js';

describe('Admin & Teacher Onboarding Suite (Phase 2)', () => {
  const app = createApp();
  let adminToken: string;
  let teacherToken: string;
  let studentToken: string;

  before(async () => {
    await initializePrisma();

    const adminLogin = await request(app).post('/api/v1/auth/login').send({
      email: 'admin@apex.edu',
      password: 'Password@123',
    });
    adminToken = adminLogin.body.accessToken;

    const teacherLogin = await request(app).post('/api/v1/auth/login').send({
      email: 'teacher1@apex.edu',
      password: 'Password@123',
    });
    teacherToken = teacherLogin.body.accessToken;

    const studentLogin = await request(app).post('/api/v1/auth/login').send({
      email: 'student1@apex.edu',
      password: 'Password@123',
    });
    studentToken = studentLogin.body.accessToken;
  });

  it('GET /api/v1/admin/teachers - should return paginated list of teachers with batch counts', async () => {
    const res = await request(app)
      .get('/api/v1/admin/teachers?page=1&limit=10')
      .set('Authorization', `Bearer ${adminToken}`);

    assert.equal(res.status, 200);
    assert.ok(Array.isArray(res.body.data));
    assert.ok(res.body.pagination);
    assert.ok(res.body.data.length >= 2);
    assert.equal(res.body.data[0].role, 'TEACHER');
  });

  it('GET /api/v1/admin/teachers?search=Rajesh - should filter teachers by search query', async () => {
    const res = await request(app)
      .get('/api/v1/admin/teachers?search=Rajesh')
      .set('Authorization', `Bearer ${adminToken}`);

    assert.equal(res.status, 200);
    assert.equal(res.body.data.length, 1);
    assert.equal(res.body.data[0].email, 'teacher1@apex.edu');
  });

  it('POST /api/v1/admin/teachers - should onboard single teacher with 48h invite code', async () => {
    const email = `new_faculty_${Date.now()}@apex.edu`;
    const res = await request(app)
      .post('/api/v1/admin/teachers')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        name: 'Dr. Vikram Sarabhai',
        email,
        phone: '+91 98765 11111',
      });

    assert.equal(res.status, 201);
    assert.equal(res.body.teacher.name, 'Dr. Vikram Sarabhai');
    assert.equal(res.body.teacher.email, email);
    assert.equal(res.body.teacher.status, 'INVITED');
    assert.ok(res.body.invite.inviteCode, 'Should return 48h invite code');
    assert.ok(res.body.invite.expiresAt);
  });

  it('POST /api/v1/admin/teachers - should reject duplicate active teacher with 409 CONFLICT', async () => {
    const res = await request(app)
      .post('/api/v1/admin/teachers')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        name: 'Prof. Duplicate',
        email: 'teacher1@apex.edu',
      });

    assert.equal(res.status, 409);
    assert.equal(res.body.code, 'CONFLICT');
  });

  it('POST /api/v1/admin/teachers/bulk - should process bulk CSV text and return summary report', async () => {
    const ts = Date.now();
    const csvContent = `Name,Email,Phone
Prof. Anand Kumar,anand_${ts}@apex.edu,+91 98765 22221
Dr. Homi Bhabha,homi_${ts}@apex.edu,+91 98765 22222
Invalid User,not-an-email,+91 98765 22223
Duplicate User,anand_${ts}@apex.edu,+91 98765 22224`;

    const res = await request(app)
      .post('/api/v1/admin/teachers/bulk')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ csvText: csvContent });

    assert.equal(res.status, 200);
    assert.equal(res.body.summary.total, 4);
    assert.equal(res.body.summary.successfulCount, 2);
    assert.equal(res.body.summary.failedCount, 2);
    assert.equal(res.body.successful.length, 2);
    assert.ok(res.body.successful[0].inviteCode);
    assert.equal(res.body.failed.length, 2);
  });

  it('PATCH /api/v1/admin/teachers/:id/status - should suspend teacher and revoke all active refresh tokens', async () => {
    // 1. Create a teacher and log them in
    const email = `suspendable_${Date.now()}@apex.edu`;
    const addRes = await request(app)
      .post('/api/v1/admin/teachers')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        name: 'To Be Suspended',
        email,
      });

    const teacherId = addRes.body.teacher.id;
    const inviteCode = addRes.body.invite.inviteCode;

    // 2. Accept invite & login
    const acceptRes = await request(app)
      .post('/api/v1/auth/accept-invite')
      .send({
        inviteCode,
        password: 'Password@123',
      });

    const teacherRefreshToken = acceptRes.body.refreshToken;

    // 3. Suspend teacher
    const suspendRes = await request(app)
      .patch(`/api/v1/admin/teachers/${teacherId}/status`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ status: 'SUSPENDED' });

    assert.equal(suspendRes.status, 200);
    assert.equal(suspendRes.body.teacher.status, 'SUSPENDED');

    // 4. Verify refresh token rotation fails because session was revoked!
    const refreshRes = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: teacherRefreshToken });

    assert.equal(refreshRes.status, 401);

    // 5. Reactivate teacher
    const reactivateRes = await request(app)
      .patch(`/api/v1/admin/teachers/${teacherId}/status`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ status: 'ACTIVE' });

    assert.equal(reactivateRes.status, 200);
    assert.equal(reactivateRes.body.teacher.status, 'ACTIVE');
  });

  it('Non-admin roles CANNOT access admin endpoints (403 FORBIDDEN)', async () => {
    const teacherAttempt = await request(app)
      .get('/api/v1/admin/teachers')
      .set('Authorization', `Bearer ${teacherToken}`);
    assert.equal(teacherAttempt.status, 403);
    assert.equal(teacherAttempt.body.code, 'FORBIDDEN');

    const studentAttempt = await request(app)
      .get('/api/v1/admin/teachers')
      .set('Authorization', `Bearer ${studentToken}`);
    assert.equal(studentAttempt.status, 403);
    assert.equal(studentAttempt.body.code, 'FORBIDDEN');
  });
});
