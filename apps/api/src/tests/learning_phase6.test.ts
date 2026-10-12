import test, { before } from 'node:test';
import assert from 'node:assert/strict';
import supertest from 'supertest';
import { createApp } from '../app.js';
import { prisma } from '../utils/prisma.js';

const app = createApp();
const request = supertest(app);

test('Phase 6 — Learning Modules Suite (Recordings, Attendance, Assignments, Tests CBT, Fees)', async (t) => {
  let adminToken: string;
  let teacherToken: string;
  let teacherId: string;
  let studentToken: string;
  let studentId: string;
  let batchId: string;
  let liveClassId: string;
  let recordingId: string;
  let assignmentId: string;
  let submissionId: string;
  let testId: string;
  let feePlanId: string;

  before(async () => {
    // 1. Clean up test artifacts
    await prisma.payment.deleteMany({ where: { institute: { slug: 'apex' } } });
    await prisma.feePlan.deleteMany({ where: { institute: { slug: 'apex' } } });
    await prisma.testAttempt.deleteMany({ where: { institute: { slug: 'apex' } } });
    await prisma.question.deleteMany({ where: { institute: { slug: 'apex' } } });
    await prisma.test.deleteMany({ where: { institute: { slug: 'apex' } } });
    await prisma.submission.deleteMany({ where: { institute: { slug: 'apex' } } });
    await prisma.assignment.deleteMany({ where: { institute: { slug: 'apex' } } });
    await prisma.recording.deleteMany({ where: { institute: { slug: 'apex' } } });
    await prisma.attendance.deleteMany({ where: { institute: { slug: 'apex' } } });
    await prisma.liveClass.deleteMany({ where: { title: { startsWith: 'P6-' } } });
    await prisma.batch.deleteMany({ where: { name: { startsWith: 'P6-' } } });

    // 2. Logins
    const adminRes = await request
      .post('/api/v1/auth/login')
      .send({ email: 'admin@apex.edu', password: 'Password@123' });
    adminToken = adminRes.body.accessToken;

    const teacherRes = await request
      .post('/api/v1/auth/login')
      .send({ email: 'teacher1@apex.edu', password: 'Password@123' });
    teacherToken = teacherRes.body.accessToken;
    teacherId = teacherRes.body.user.id;

    const studentRes = await request
      .post('/api/v1/auth/login')
      .send({ email: 'student1@apex.edu', password: 'Password@123' });
    studentToken = studentRes.body.accessToken;
    studentId = studentRes.body.user.id;

    // 3. Setup batch & student enrollment
    const batchRes = await request
      .post('/api/v1/batches')
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({ name: 'P6-Organic Chemistry', subject: 'Chemistry' });
    batchId = batchRes.body.id;

    await request
      .post('/api/v1/batches/join')
      .set('Authorization', `Bearer ${studentToken}`)
      .send({ joinCode: batchRes.body.joinCode });

    // 4. Create live class
    const classRes = await request
      .post('/api/v1/classes')
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        batchId,
        title: 'P6-Hydrocarbons Class',
        scheduledAt: new Date().toISOString(),
      });
    liveClassId = classRes.body.id;
  });

  /* -------------------------------------------------------------------------- */
  /* 1. RECORDING LIBRARY                                                       */
  /* -------------------------------------------------------------------------- */
  await t.test('POST /api/v1/recordings - Save class recording with playback metadata', async () => {
    const res = await request
      .post('/api/v1/recordings')
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        liveClassId,
        title: 'Hydrocarbons Complete Lecture',
        videoUrl: 'https://cdn.classora.edu/recordings/hydrocarbons_session1.mp4',
        durationSec: 3600,
        fileSizeMb: 450.5,
      });

    assert.equal(res.status, 201);
    assert.equal(res.body.status, 'success');
    assert.ok(res.body.data.id);
    assert.equal(res.body.data.durationSec, 3600);
    recordingId = res.body.data.id;

    // Verify LiveClass has updated recordingUrl
    const updatedClass = await prisma.liveClass.findUnique({ where: { id: liveClassId } });
    assert.equal(updatedClass?.recordingUrl, 'https://cdn.classora.edu/recordings/hydrocarbons_session1.mp4');
    assert.equal(updatedClass?.status, 'ENDED');
  });

  await t.test('GET /api/v1/recordings - Student lists batch recordings', async () => {
    const res = await request
      .get('/api/v1/recordings')
      .set('Authorization', `Bearer ${studentToken}`);

    assert.equal(res.status, 200);
    assert.ok(res.body.data.recordings.length >= 1);
    assert.equal(res.body.data.recordings[0].videoUrl, 'https://cdn.classora.edu/recordings/hydrocarbons_session1.mp4');
  });

  /* -------------------------------------------------------------------------- */
  /* 2. AUTOMATED ATTENDANCE                                                    */
  /* -------------------------------------------------------------------------- */
  await t.test('POST /api/v1/attendance/join & leave - Auto capture student attendance duration', async () => {
    // Join
    const joinRes = await request
      .post('/api/v1/attendance/join')
      .set('Authorization', `Bearer ${studentToken}`)
      .send({ classId: liveClassId });

    assert.equal(joinRes.status, 200);
    assert.ok(joinRes.body.data.id);
    assert.equal(joinRes.body.data.studentId, studentId);

    // Leave
    const leaveRes = await request
      .post('/api/v1/attendance/leave')
      .set('Authorization', `Bearer ${studentToken}`)
      .send({ classId: liveClassId });

    assert.equal(leaveRes.status, 200);
    assert.ok(leaveRes.body.data.leftAt !== null);

    // Teacher inspects class roster
    const rosterRes = await request
      .get(`/api/v1/attendance/class/${liveClassId}`)
      .set('Authorization', `Bearer ${teacherToken}`);

    assert.equal(rosterRes.status, 200);
    assert.equal(rosterRes.body.data.presentCount, 1);
    assert.equal(rosterRes.body.data.attendancePercentage, 100);
  });

  await t.test('GET /api/v1/attendance/my-summary - Student views attendance overview', async () => {
    const res = await request
      .get('/api/v1/attendance/my-summary')
      .set('Authorization', `Bearer ${studentToken}`);

    assert.equal(res.status, 200);
    assert.ok(res.body.data.attendedClasses >= 1);
    assert.ok(res.body.data.overallPercentage >= 0);
  });

  /* -------------------------------------------------------------------------- */
  /* 3. ASSIGNMENTS & GRADING                                                   */
  /* -------------------------------------------------------------------------- */
  await t.test('POST /api/v1/assignments - Teacher creates assignment for batch', async () => {
    const futureDate = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString();
    const res = await request
      .post('/api/v1/assignments')
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        batchId,
        title: 'Alkanes & Alkenes Worksheet #1',
        description: 'Complete questions 1 to 25 from chapter 4',
        dueDate: futureDate,
        maxMarks: 50,
      });

    assert.equal(res.status, 201);
    assert.ok(res.body.data.id);
    assert.equal(res.body.data.maxMarks, 50);
    assignmentId = res.body.data.id;
  });

  await t.test('POST /api/v1/assignments/:id/submit - Student submits homework', async () => {
    const res = await request
      .post(`/api/v1/assignments/${assignmentId}/submit`)
      .set('Authorization', `Bearer ${studentToken}`)
      .send({
        fileUrl: 'https://cdn.classora.edu/submissions/student1_alkanes_hw.pdf',
      });

    assert.equal(res.status, 201);
    assert.equal(res.body.data.status, 'SUBMITTED');
    submissionId = res.body.data.id;
  });

  await t.test('PATCH /api/v1/assignments/submissions/:id/grade - Teacher grades submission', async () => {
    const res = await request
      .patch(`/api/v1/assignments/submissions/${submissionId}/grade`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        marksObtained: 48,
        feedback: 'Excellent mechanism diagrams and clear explanation!',
      });

    assert.equal(res.status, 200);
    assert.equal(res.body.data.marksObtained, 48);
    assert.equal(res.body.data.status, 'GRADED');
  });

  /* -------------------------------------------------------------------------- */
  /* 4. CBT TESTS & AUTOMATED EVALUATION                                        */
  /* -------------------------------------------------------------------------- */
  await t.test('POST /api/v1/tests - Teacher creates CBT quiz with 3 MCQs', async () => {
    const res = await request
      .post('/api/v1/tests')
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        batchId,
        title: 'Organic Chemistry Mid-Term CBT',
        description: '3 Questions, 15 Minutes',
        durationMin: 15,
        questions: [
          {
            text: 'What is the hybridization of carbon in methane (CH4)?',
            optionA: 'sp',
            optionB: 'sp2',
            optionC: 'sp3',
            optionD: 'dsp2',
            correctOption: 'C',
            marks: 2,
            explanation: 'Methane has 4 single sigma bonds arranged tetrahedrally, hence sp3.',
          },
          {
            text: 'Which of the following is an aromatic compound?',
            optionA: 'Cyclohexane',
            optionB: 'Benzene',
            optionC: 'Propane',
            optionD: 'Butene',
            correctOption: 'B',
            marks: 3,
            explanation: 'Benzene follows Huckels rule with 6 pi electrons.',
          },
          {
            text: 'General formula of alkanes is:',
            optionA: 'CnH2n+2',
            optionB: 'CnH2n',
            optionC: 'CnH2n-2',
            optionD: 'CnHn',
            correctOption: 'A',
            marks: 5,
            explanation: 'Alkanes are saturated hydrocarbons with formula CnH2n+2.',
          },
        ],
      });

    assert.equal(res.status, 201);
    assert.ok(res.body.data.id);
    assert.equal(res.body.data.totalMarks, 10);
    testId = res.body.data.id;
  });

  await t.test('POST /api/v1/tests/:id/start & submit - Student takes test and receives auto-graded score', async () => {
    // 1. Start test attempt
    const startRes = await request
      .post(`/api/v1/tests/${testId}/start`)
      .set('Authorization', `Bearer ${studentToken}`);

    assert.equal(startRes.status, 200);
    assert.equal(startRes.body.data.status, 'IN_PROGRESS');

    // 2. Fetch test questions (verify answers are hidden from student)
    const testDetailsRes = await request
      .get(`/api/v1/tests/${testId}`)
      .set('Authorization', `Bearer ${studentToken}`);

    assert.equal(testDetailsRes.status, 200);
    const questions = testDetailsRes.body.data.questions;
    assert.equal(questions.length, 3);
    assert.equal(questions[0].correctOption, undefined); // Hidden from student!

    // 3. Submit answers (Q1: C (Correct), Q2: B (Correct), Q3: B (Wrong, correct is A))
    const q1Id = questions[0].id;
    const q2Id = questions[1].id;
    const q3Id = questions[2].id;

    const submitRes = await request
      .post(`/api/v1/tests/${testId}/submit`)
      .set('Authorization', `Bearer ${studentToken}`)
      .send({
        answers: {
          [q1Id]: 'C',
          [q2Id]: 'B',
          [q3Id]: 'B',
        },
      });

    assert.equal(submitRes.status, 200);
    assert.equal(submitRes.body.data.score, 5); // 2 + 3 = 5 out of 10
    assert.equal(submitRes.body.data.totalMarks, 10);
    assert.equal(submitRes.body.data.percentage, 50);
    assert.equal(submitRes.body.data.status, 'EVALUATED');
  });

  /* -------------------------------------------------------------------------- */
  /* 5. FEES & PAYMENTS                                                         */
  /* -------------------------------------------------------------------------- */
  await t.test('POST /api/v1/fees/plans - Admin creates fee plan', async () => {
    const res = await request
      .post('/api/v1/fees/plans')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        name: 'Chemistry Advanced Batch Fee',
        amount: 2500,
        interval: 'MONTHLY',
        batchId,
        description: 'Monthly tuition fee for Grade 12 Organic Chemistry',
      });

    assert.equal(res.status, 201);
    assert.ok(res.body.data.id);
    assert.equal(res.body.data.amount, 2500);
    feePlanId = res.body.data.id;
  });

  await t.test('POST /api/v1/fees/pay - Student pays fee and receives receipt', async () => {
    const res = await request
      .post('/api/v1/fees/pay')
      .set('Authorization', `Bearer ${studentToken}`)
      .send({
        feePlanId,
        amount: 2500,
        paymentMethod: 'UPI',
      });

    assert.equal(res.status, 201);
    assert.ok(res.body.data.transactionId);
    assert.ok(res.body.data.receiptNo);
    assert.equal(res.body.data.status, 'SUCCESS');
    assert.equal(res.body.data.amount, 2500);
  });

  await t.test('GET /api/v1/fees/reports - Admin views collection revenue', async () => {
    const res = await request
      .get('/api/v1/fees/reports')
      .set('Authorization', `Bearer ${adminToken}`);

    assert.equal(res.status, 200);
    assert.ok(res.body.data.totalRevenue >= 2500);
    assert.ok(res.body.data.successfulTransactions >= 1);
  });
});
