import { describe, it, before } from 'node:test';
import assert from 'node:assert/strict';
import request from 'supertest';
import { createApp } from '../app.js';
import { initializePrisma } from '../utils/prisma.js';

describe('Role-Based Access Control (RBAC) Suite', () => {
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

  it('Admin can view all invites list', async () => {
    const res = await request(app)
      .get('/api/v1/invites')
      .set('Authorization', `Bearer ${adminToken}`);

    assert.equal(res.status, 200);
    assert.ok(Array.isArray(res.body.invites));
  });

  it('Student CANNOT create invites or list invites (403 FORBIDDEN)', async () => {
    const listRes = await request(app)
      .get('/api/v1/invites')
      .set('Authorization', `Bearer ${studentToken}`);

    assert.equal(listRes.status, 403);
    assert.equal(listRes.body.code, 'FORBIDDEN');

    const createRes = await request(app)
      .post('/api/v1/invites')
      .set('Authorization', `Bearer ${studentToken}`)
      .send({ email: 'test@apex.edu', role: 'STUDENT' });

    assert.equal(createRes.status, 403);
    assert.equal(createRes.body.code, 'FORBIDDEN');
  });

  it('Teacher CANNOT invite another TEACHER (only ADMIN can invite teachers)', async () => {
    const res = await request(app)
      .post('/api/v1/invites')
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        email: 'fellowteacher@apex.edu',
        role: 'TEACHER',
      });

    assert.equal(res.status, 403);
    assert.equal(res.body.code, 'FORBIDDEN');
  });

  it('Teacher CAN invite a STUDENT', async () => {
    const res = await request(app)
      .post('/api/v1/invites')
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        email: 'enrolledstudentbyfaculty@apex.edu',
        role: 'STUDENT',
      });

    assert.equal(res.status, 201);
    assert.equal(res.body.role, 'STUDENT');
  });
});
