import { describe, it, before } from 'node:test';
import assert from 'node:assert/strict';
import request from 'supertest';
import { createApp } from '../app.js';
import { initializePrisma, prisma } from '../utils/prisma.js';

describe('Phase 3 — Timetable & Enrollment Suite', () => {
  const app = createApp();
  let adminToken: string;
  let teacherToken: string;
  let studentToken: string;
  let createdBatchId: string;
  let createdJoinCode: string;
  let secondBatchId: string;

  before(async () => {
    await initializePrisma();

    // Log in admin
    const adminLogin = await request(app).post('/api/v1/auth/login').send({
      email: 'admin@apex.edu',
      password: 'Password@123',
    });
    adminToken = adminLogin.body.accessToken;

    // Log in teacher1
    const teacherLogin = await request(app).post('/api/v1/auth/login').send({
      email: 'teacher1@apex.edu',
      password: 'Password@123',
    });
    teacherToken = teacherLogin.body.accessToken;

    const teacher = await prisma.user.findFirst({ where: { email: 'teacher1@apex.edu' } });
    if (teacher) {
      await prisma.timetableSlot.deleteMany({ where: { teacherId: teacher.id } });
      await prisma.liveClass.deleteMany({ where: { teacherId: teacher.id } });
    }

    // Log in student1
    const studentLogin = await request(app).post('/api/v1/auth/login').send({
      email: 'student1@apex.edu',
      password: 'Password@123',
    });
    studentToken = studentLogin.body.accessToken;
  });

  /* -------------------------------------------------------------------------- */
  /* 1. BATCH CRUD & PERMISSIONS                                                */
  /* -------------------------------------------------------------------------- */
  describe('Batch Management', () => {
    it('POST /api/v1/batches - Teacher creates a new batch with unique join code', async () => {
      const res = await request(app)
        .post('/api/v1/batches')
        .set('Authorization', `Bearer ${teacherToken}`)
        .send({
          name: `Physics Advanced ${Date.now()}`,
          subject: 'Physics',
        });

      assert.equal(res.status, 201);
      assert.ok(res.body.id);
      assert.ok(res.body.joinCode);
      assert.equal(res.body.subject, 'Physics');
      assert.equal(res.body.teacher.email, 'teacher1@apex.edu');

      createdBatchId = res.body.id;
      createdJoinCode = res.body.joinCode;
    });

    it('POST /api/v1/batches - Student CANNOT create a batch (403 FORBIDDEN)', async () => {
      const res = await request(app)
        .post('/api/v1/batches')
        .set('Authorization', `Bearer ${studentToken}`)
        .send({
          name: 'Hacker Batch',
          subject: 'Exploits',
        });

      assert.equal(res.status, 403);
    });

    it('GET /api/v1/batches - Teacher lists their batches with counts', async () => {
      const res = await request(app)
        .get('/api/v1/batches')
        .set('Authorization', `Bearer ${teacherToken}`);

      assert.equal(res.status, 200);
      assert.ok(Array.isArray(res.body.batches));
      const found = res.body.batches.find((b: any) => b.id === createdBatchId);
      assert.ok(found);
      assert.ok(found._count);
    });

    it('POST /api/v1/batches/:id/regenerate-code - Teacher regenerates join code', async () => {
      const res = await request(app)
        .post(`/api/v1/batches/${createdBatchId}/regenerate-code`)
        .set('Authorization', `Bearer ${teacherToken}`);

      assert.equal(res.status, 200);
      assert.ok(res.body.joinCode);
      createdJoinCode = res.body.joinCode;
    });
  });

  /* -------------------------------------------------------------------------- */
  /* 2. STUDENT ENROLLMENT FLOWS                                                */
  /* -------------------------------------------------------------------------- */
  describe('Student Enrollment & Management', () => {
    it('POST /api/v1/batches/join - Student joins batch using join code', async () => {
      const res = await request(app)
        .post('/api/v1/batches/join')
        .set('Authorization', `Bearer ${studentToken}`)
        .send({
          joinCode: createdJoinCode,
        });

      assert.equal(res.status, 200);
      assert.equal(res.body.enrollment.status, 'ACTIVE');
      assert.equal(res.body.batch.id, createdBatchId);
    });

    it('POST /api/v1/batches/join - Duplicate join attempt returns 409 CONFLICT', async () => {
      const res = await request(app)
        .post('/api/v1/batches/join')
        .set('Authorization', `Bearer ${studentToken}`)
        .send({
          joinCode: createdJoinCode,
        });

      assert.equal(res.status, 409);
      assert.equal(res.body.code, 'CONFLICT');
    });

    it('POST /api/v1/batches/:id/students - Teacher manually adds a student', async () => {
      const email = `direct_student_${Date.now()}@apex.edu`;
      const res = await request(app)
        .post(`/api/v1/batches/${createdBatchId}/students`)
        .set('Authorization', `Bearer ${teacherToken}`)
        .send({
          name: 'Direct Onboarded Student',
          email,
          phone: '+919988776655',
        });

      assert.equal(res.status, 201);
      assert.equal(res.body.student.email, email);
      assert.ok(res.body.inviteCode);
      assert.ok(res.body.inviteUrl);
      assert.equal(res.body.enrollment.status, 'ACTIVE');
    });

    it('POST /api/v1/batches/:id/students/bulk - Teacher bulk enrolls students via CSV text', async () => {
      const csvText = `Name,Email,Phone
Amit Verma,amit_bulk_${Date.now()}@apex.edu,+919876543210
Sneha Roy,sneha_bulk_${Date.now()}@apex.edu,+919876543211
Invalid Student,invalid_email_format,+919876543212`;

      const res = await request(app)
        .post(`/api/v1/batches/${createdBatchId}/students/bulk`)
        .set('Authorization', `Bearer ${teacherToken}`)
        .send({ csvText });

      assert.equal(res.status, 200);
      assert.equal(res.body.total, 3);
      assert.equal(res.body.enrolled, 2);
      assert.equal(res.body.failed, 1);
      assert.equal(res.body.rows[2].status, 'FAILED');
    });

    it('GET /api/v1/batches/:id/students - Teacher lists enrolled students', async () => {
      const res = await request(app)
        .get(`/api/v1/batches/${createdBatchId}/students`)
        .set('Authorization', `Bearer ${teacherToken}`);

      assert.equal(res.status, 200);
      assert.ok(Array.isArray(res.body.students));
      assert.ok(res.body.students.length >= 3);
    });
  });

  /* -------------------------------------------------------------------------- */
  /* 3. TIMETABLE SLOTS & CONFLICT DETECTION                                    */
  /* -------------------------------------------------------------------------- */
  describe('Timetable Slots & Conflict Detection', () => {
    it('POST /api/v1/batches - Create second batch for testing conflict engine', async () => {
      const res = await request(app)
        .post('/api/v1/batches')
        .set('Authorization', `Bearer ${teacherToken}`)
        .send({
          name: `Math Champions ${Date.now()}`,
          subject: 'Mathematics',
        });

      assert.equal(res.status, 201);
      secondBatchId = res.body.id;
    });

    it('POST /api/v1/timetable - Teacher creates a valid recurring slot (Mon 09:00 - 10:00)', async () => {
      const res = await request(app)
        .post('/api/v1/timetable')
        .set('Authorization', `Bearer ${teacherToken}`)
        .send({
          batchId: createdBatchId,
          dayOfWeek: 1, // Monday
          startMin: 540, // 09:00 AM
          endMin: 600, // 10:00 AM
          recurring: true,
        });

      assert.equal(res.status, 201);
      assert.ok(res.body.id);
      assert.equal(res.body.dayOfWeek, 1);
      assert.equal(res.body.startMin, 540);
      assert.equal(res.body.endMin, 600);
    });

    it('POST /api/v1/timetable - Reject overlapping slot for SAME TEACHER on same day (409 CONFLICT)', async () => {
      // Trying to schedule slot on secondBatchId from 09:30 to 10:30 (570 to 630) -> overlaps with 540-600
      const res = await request(app)
        .post('/api/v1/timetable')
        .set('Authorization', `Bearer ${teacherToken}`)
        .send({
          batchId: secondBatchId,
          dayOfWeek: 1, // Monday
          startMin: 570, // 09:30 AM (overlaps!)
          endMin: 630, // 10:30 AM
          recurring: true,
        });

      assert.equal(res.status, 409);
      assert.equal(res.body.code, 'CONFLICT');
      assert.ok(res.body.message.includes('Teacher conflict') || res.body.details?.conflictType === 'TEACHER_OVERLAP');
    });

    it('POST /api/v1/timetable - Reject overlapping slot for SAME BATCH on same day (409 CONFLICT)', async () => {
      // Trying to schedule another slot on createdBatchId from 08:30 to 09:30 (510 to 570) -> overlaps
      const res = await request(app)
        .post('/api/v1/timetable')
        .set('Authorization', `Bearer ${teacherToken}`)
        .send({
          batchId: createdBatchId,
          dayOfWeek: 1,
          startMin: 510,
          endMin: 570,
          recurring: true,
        });

      assert.equal(res.status, 409);
      assert.equal(res.body.code, 'CONFLICT');
    });

    it('POST /api/v1/timetable - Non-overlapping slot succeeds (Mon 10:00 - 11:00)', async () => {
      const res = await request(app)
        .post('/api/v1/timetable')
        .set('Authorization', `Bearer ${teacherToken}`)
        .send({
          batchId: secondBatchId,
          dayOfWeek: 1, // Monday
          startMin: 600, // 10:00 AM (Back-to-back, no overlap!)
          endMin: 660, // 11:00 AM
          recurring: true,
        });

      assert.equal(res.status, 201);
    });

    it('GET /api/v1/timetable - Student only sees slots for enrolled batches', async () => {
      const res = await request(app)
        .get('/api/v1/timetable')
        .set('Authorization', `Bearer ${studentToken}`);

      assert.equal(res.status, 200);
      assert.ok(Array.isArray(res.body.slots));
      // Student is enrolled in createdBatchId, so should see the 09:00 slot
      const hasEnrolledSlot = res.body.slots.some((s: any) => s.batchId === createdBatchId);
      assert.ok(hasEnrolledSlot);
    });
  });

  /* -------------------------------------------------------------------------- */
  /* 4. LIVE CLASS GENERATION & SCHEDULING                                      */
  /* -------------------------------------------------------------------------- */
  describe('LiveClass Management', () => {
    it('POST /api/v1/classes/generate-upcoming - Generate classes from timetable slots', async () => {
      const res = await request(app)
        .post('/api/v1/classes/generate-upcoming')
        .set('Authorization', `Bearer ${teacherToken}`)
        .send({ daysAhead: 7 });

      assert.equal(res.status, 200);
      assert.ok(typeof res.body.generatedCount === 'number');
      assert.ok(Array.isArray(res.body.classes));
    });

    it('POST /api/v1/classes - Teacher schedules a one-off class', async () => {
      const futureDate = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();
      const res = await request(app)
        .post('/api/v1/classes')
        .set('Authorization', `Bearer ${teacherToken}`)
        .send({
          batchId: createdBatchId,
          title: 'Special Doubt Clearing Session',
          scheduledAt: futureDate,
        });

      assert.equal(res.status, 201);
      assert.ok(res.body.id);
      assert.ok(res.body.livekitRoom);
      assert.equal(res.body.status, 'SCHEDULED');
    });

    it('GET /api/v1/classes - Student lists upcoming classes for their batches', async () => {
      const res = await request(app)
        .get('/api/v1/classes')
        .set('Authorization', `Bearer ${studentToken}`);

      assert.equal(res.status, 200);
      assert.ok(Array.isArray(res.body.classes));
      assert.ok(res.body.classes.length > 0);
    });
  });
});
