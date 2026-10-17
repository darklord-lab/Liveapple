import test, { before } from 'node:test';
import assert from 'node:assert/strict';
import supertest from 'supertest';
import { createApp } from '../app.js';
import { prisma } from '../utils/prisma.js';

const app = createApp();
const request = supertest(app);

test('Phase 4.6 — Share Score & Deep Link Suite', async (t) => {
  let teacherToken: string;
  let studentToken: string;
  let batchId: string;
  let testId: string;
  let attemptId: string;
  let studentName: string;
  let instituteCode: string;

  before(async () => {
    // 1. Get institute and ensure code
    const inst = await prisma.institute.findFirst({ where: { slug: 'apex' } });
    assert.ok(inst);
    instituteCode = inst.code || 'APEX01';

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
    studentName = studentRes.body.user.name;

    // 4. Find batch student is enrolled in
    const enrollment = await prisma.enrollment.findFirst({
      where: { studentId: studentRes.body.user.id, status: 'ACTIVE' },
    });
    assert.ok(enrollment);
    batchId = enrollment.batchId;

    // 5. Teacher creates a test for this batch
    const createTestRes = await request
      .post('/api/v1/tests')
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        batchId,
        title: 'Wave Optics & Thermodynamics CBT Mock',
        description: 'Comprehensive chapter mock test with instant automated scoring',
        durationMin: 20,
        questions: [
          {
            text: 'What is the speed of light in vacuum?',
            optionA: '3 x 10^8 m/s',
            optionB: '2 x 10^8 m/s',
            optionC: '1.5 x 10^8 m/s',
            optionD: '4 x 10^8 m/s',
            correctOption: 'A',
            marks: 4,
          },
          {
            text: 'Which law of thermodynamics defines temperature?',
            optionA: 'Zeroth Law',
            optionB: 'First Law',
            optionC: 'Second Law',
            optionD: 'Third Law',
            correctOption: 'A',
            marks: 4,
          },
        ],
      });
    assert.equal(createTestRes.status, 201);
    testId = createTestRes.body.data.id;

    // 6. Student starts attempt
    const startRes = await request
      .post(`/api/v1/tests/${testId}/start`)
      .set('Authorization', `Bearer ${studentToken}`);
    assert.equal(startRes.status, 200);

    // 7. Student submits answers (Question 1 correct 'A', Question 2 wrong 'B')
    const q1Id = createTestRes.body.data.questions[0].id;
    const q2Id = createTestRes.body.data.questions[1].id;
    const submitRes = await request
      .post(`/api/v1/tests/${testId}/submit`)
      .set('Authorization', `Bearer ${studentToken}`)
      .send({
        answers: {
          [q1Id]: 'A',
          [q2Id]: 'B',
        },
      });
    assert.equal(submitRes.status, 200);
    assert.equal(submitRes.body.data.score, 4);
    assert.equal(submitRes.body.data.totalMarks, 8);
    assert.equal(submitRes.body.data.percentage, 50);
    attemptId = submitRes.body.data.attemptId;
    assert.ok(attemptId);
  });

  /* -------------------------------------------------------------------------- */
  /* 1. PUBLIC TEST SCORE SHARE ENDPOINT                                        */
  /* -------------------------------------------------------------------------- */
  await t.test('1. Public unauthenticated request returns score card details and deep link', async () => {
    // Note: No Authorization header provided!
    const res = await request.get(`/api/v1/tests/share/${attemptId}`);

    assert.equal(res.status, 200);
    assert.equal(res.body.status, 'success');
    const data = res.body.data;

    assert.equal(data.attemptId, attemptId);
    assert.equal(data.testId, testId);
    assert.equal(data.testTitle, 'Wave Optics & Thermodynamics CBT Mock');
    assert.equal(data.studentName, studentName);
    assert.equal(data.score, 4);
    assert.equal(data.totalMarks, 8);
    assert.equal(data.percentage, 50);
    assert.equal(data.status, 'EVALUATED');
    assert.ok(data.submittedAt);

    // Verify white-label institute metadata
    assert.ok(data.institute);
    assert.equal(data.institute.code, instituteCode);
    assert.ok(data.institute.primaryColor);

    // Verify deep link format
    assert.equal(data.deepLink, `classora://test-result?attemptId=${attemptId}&code=${instituteCode}`);
    assert.equal(data.webLink, `https://classora.app/test-result?attemptId=${attemptId}&code=${instituteCode}`);
  });

  /* -------------------------------------------------------------------------- */
  /* 2. SECURITY SANITIZATION                                                   */
  /* -------------------------------------------------------------------------- */
  await t.test('2. Public score card does NOT leak answer keys or raw student credentials', async () => {
    const res = await request.get(`/api/v1/tests/share/${attemptId}`);
    assert.equal(res.status, 200);
    const data = res.body.data;

    assert.equal(data.answers, undefined, 'raw answers object must not be exposed in public card');
    assert.equal(data.password, undefined);
    assert.equal(data.student?.email, undefined, 'student email must not be exposed');
    assert.equal(data.questions, undefined, 'question list with correct options must not be leaked');
  });

  /* -------------------------------------------------------------------------- */
  /* 3. ERROR HANDLING                                                          */
  /* -------------------------------------------------------------------------- */
  await t.test('3. Returns 404 NOT_FOUND for non-existent or invalid attemptId', async () => {
    const res = await request.get('/api/v1/tests/share/non-existent-attempt-cuid');
    assert.equal(res.status, 404);
    assert.equal(res.body.code, 'NOT_FOUND');
  });
});
