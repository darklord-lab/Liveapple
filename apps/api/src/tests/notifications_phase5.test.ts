import test, { before, after } from 'node:test';
import assert from 'node:assert/strict';
import supertest from 'supertest';
import { createApp } from '../app.js';
import { prisma } from '../utils/prisma.js';
import { SchedulerService } from '../services/scheduler.service.js';

const app = createApp();
const request = supertest(app);

test('Phase 5 — Notifications & Reminders Suite', async (t) => {
  let adminToken: string;
  let teacherToken: string;
  let teacherId: string;
  let enrolledStudentToken: string;
  let enrolledStudentId: string;
  let nonEnrolledStudentToken: string;
  let nonEnrolledStudentId: string;
  let testBatchId: string;
  let liveClassId: string;
  let reminderClassId: string;
  let createdNotificationId: string;

  before(async () => {
    // 1. Clean up existing test data
    await prisma.notification.deleteMany({
      where: {
        institute: { slug: 'apex' },
      },
    });

    await prisma.liveClass.deleteMany({
      where: {
        title: { startsWith: 'P5-' },
      },
    });

    await prisma.batch.deleteMany({
      where: {
        name: { startsWith: 'P5-' },
      },
    });

    // 2. Login Admin
    const adminRes = await request
      .post('/api/v1/auth/login')
      .send({ email: 'admin@apex.edu', password: 'Password@123' });
    adminToken = adminRes.body.accessToken;

    // 3. Login Teacher
    const teacherRes = await request
      .post('/api/v1/auth/login')
      .send({ email: 'teacher1@apex.edu', password: 'Password@123' });
    teacherToken = teacherRes.body.accessToken;
    teacherId = teacherRes.body.user.id;

    // 4. Login Enrolled Student
    const student1Res = await request
      .post('/api/v1/auth/login')
      .send({ email: 'student1@apex.edu', password: 'Password@123' });
    enrolledStudentToken = student1Res.body.accessToken;
    enrolledStudentId = student1Res.body.user.id;

    // 5. Login Non-Enrolled Student
    const student2Res = await request
      .post('/api/v1/auth/login')
      .send({ email: 'student2@apex.edu', password: 'Password@123' });
    nonEnrolledStudentToken = student2Res.body.accessToken;
    nonEnrolledStudentId = student2Res.body.user.id;

    // 6. Teacher creates Batch
    const batchRes = await request
      .post('/api/v1/batches')
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({ name: 'P5-Physics 101', subject: 'Physics' });
    testBatchId = batchRes.body.id;

    // 7. Student 1 enrolls in batch
    await request
      .post('/api/v1/batches/join')
      .set('Authorization', `Bearer ${enrolledStudentToken}`)
      .send({ joinCode: batchRes.body.joinCode });

    // 8. Create LiveClass for testing Live Start notifications
    const liveClassRes = await request
      .post('/api/v1/classes')
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        batchId: testBatchId,
        title: 'P5-Quantum Mechanics Live',
        scheduledAt: new Date(Date.now() + 60000).toISOString(),
      });
    liveClassId = liveClassRes.body.id;
  });

  after(() => {
    SchedulerService.stopReminderScheduler();
  });

  await t.test('POST /api/v1/devices/fcm-token - Register device FCM token', async () => {
    const res = await request
      .post('/api/v1/devices/fcm-token')
      .set('Authorization', `Bearer ${enrolledStudentToken}`)
      .send({
        fcmToken: 'fcm_sample_token_student1_device_xyz123',
      });

    assert.equal(res.status, 200);
    assert.equal(res.body.status, 'success');

    // Verify DB update
    const user = await prisma.user.findUnique({ where: { id: enrolledStudentId } });
    assert.equal(user?.fcmToken, 'fcm_sample_token_student1_device_xyz123');
  });

  await t.test('POST /api/v1/devices/fcm-token - Reject invalid token (<5 chars)', async () => {
    const res = await request
      .post('/api/v1/devices/fcm-token')
      .set('Authorization', `Bearer ${enrolledStudentToken}`)
      .send({
        fcmToken: 'abc',
      });

    assert.equal(res.status, 400);
  });

  await t.test('DELETE /api/v1/devices/fcm-token - Remove FCM token', async () => {
    const res = await request
      .delete('/api/v1/devices/fcm-token')
      .set('Authorization', `Bearer ${enrolledStudentToken}`);

    assert.equal(res.status, 200);

    const user = await prisma.user.findUnique({ where: { id: enrolledStudentId } });
    assert.equal(user?.fcmToken, null);

    // Re-register for subsequent notification testing
    await request
      .post('/api/v1/devices/fcm-token')
      .set('Authorization', `Bearer ${enrolledStudentToken}`)
      .send({
        fcmToken: 'fcm_sample_token_student1_active',
      });
  });

  await t.test('POST /api/v1/classes/:id/start - Trigger multicast and in-app notifications on live start', async () => {
    // Teacher starts live class
    const res = await request
      .post(`/api/v1/classes/${liveClassId}/start`)
      .set('Authorization', `Bearer ${teacherToken}`);

    assert.equal(res.status, 200);
    assert.equal(res.body.status, 'LIVE');

    // Verify enrolled student received a LIVE_START notification in DB
    const studentNotifs = await prisma.notification.findMany({
      where: {
        userId: enrolledStudentId,
        type: 'LIVE_START',
        payload: {
          contains: liveClassId,
        },
      },
    });

    assert.equal(studentNotifs.length, 1);
    const payload = JSON.parse(studentNotifs[0].payload);
    assert.equal(payload.classId, liveClassId);
    assert.equal(payload.deepLink, `/live/${liveClassId}`);
    assert.equal(payload.type, 'LIVE_START');
    createdNotificationId = studentNotifs[0].id;

    // Verify NON-enrolled student did NOT receive the notification for this class
    const nonEnrolledNotifs = await prisma.notification.findMany({
      where: {
        userId: nonEnrolledStudentId,
        type: 'LIVE_START',
        payload: {
          contains: liveClassId,
        },
      },
    });
    assert.equal(nonEnrolledNotifs.length, 0);
  });

  await t.test('GET /api/v1/notifications - List user notifications with unread count', async () => {
    const res = await request
      .get('/api/v1/notifications')
      .set('Authorization', `Bearer ${enrolledStudentToken}`);

    assert.equal(res.status, 200);
    assert.equal(res.body.status, 'success');
    assert.ok(res.body.data.notifications.length >= 1);
    assert.ok(res.body.data.unreadCount >= 1);
    assert.equal(res.body.data.notifications[0].type, 'LIVE_START');
    assert.equal(res.body.data.notifications[0].deepLink, `/live/${liveClassId}`);
  });

  await t.test('PATCH /api/v1/notifications/:id/read - Mark single notification as read', async () => {
    const res = await request
      .patch(`/api/v1/notifications/${createdNotificationId}/read`)
      .set('Authorization', `Bearer ${enrolledStudentToken}`);

    assert.equal(res.status, 200);
    assert.ok(res.body.data.readAt !== null);

    // Verify DB
    const notif = await prisma.notification.findUnique({
      where: { id: createdNotificationId },
    });
    assert.ok(notif?.readAt !== null);
  });

  await t.test('PATCH /api/v1/notifications/read-all - Mark all notifications as read', async () => {
    // Create an unread notification first
    await prisma.notification.create({
      data: {
        instituteId: (await prisma.user.findUnique({ where: { id: enrolledStudentId } }))!.instituteId,
        userId: enrolledStudentId,
        type: 'BATCH_ENROLL',
        payload: JSON.stringify({ title: 'Enrolled', body: 'Welcome to Physics 101' }),
      },
    });

    const res = await request
      .patch('/api/v1/notifications/read-all')
      .set('Authorization', `Bearer ${enrolledStudentToken}`);

    assert.equal(res.status, 200);
    assert.ok(res.body.data.updatedCount >= 1);

    // Verify unread count is now 0
    const listRes = await request
      .get('/api/v1/notifications')
      .set('Authorization', `Bearer ${enrolledStudentToken}`);

    assert.equal(listRes.body.data.unreadCount, 0);
  });

  await t.test('Scheduler: 15-Minute Upcoming Class Reminder Engine', async () => {
    // Create a scheduled class starting exactly 15 minutes from now
    const fifteenMinFromNow = new Date(Date.now() + 15 * 60 * 1000);
    const scheduledClass = await prisma.liveClass.create({
      data: {
        instituteId: (await prisma.user.findUnique({ where: { id: teacherId } }))!.instituteId,
        batchId: testBatchId,
        teacherId: teacherId,
        title: 'P5-Calculus 15M Reminder Class',
        scheduledAt: fifteenMinFromNow,
        status: 'SCHEDULED',
        livekitRoom: `room_test_15m_${Date.now()}`,
      },
    });
    reminderClassId = scheduledClass.id;

    // Run scheduler check
    const result = await SchedulerService.checkAndSendUpcomingClassReminders(new Date());

    assert.ok(result.upcomingCount >= 1);
    assert.ok(result.remindersSent >= 1);

    // Verify REMINDER_15M notification exists in DB for enrolled student and teacher
    const reminders = await prisma.notification.findMany({
      where: {
        type: 'REMINDER_15M',
        payload: {
          contains: reminderClassId,
        },
      },
    });

    assert.ok(reminders.length >= 2); // 1 for teacher, 1 for enrolled student
    const studentReminder = reminders.find((r) => r.userId === enrolledStudentId);
    assert.ok(studentReminder);
    const parsedPayload = JSON.parse(studentReminder!.payload);
    assert.equal(parsedPayload.type, 'REMINDER_15M');
    assert.equal(parsedPayload.deepLink, `/live/${reminderClassId}`);

    // Run scheduler check again -> idempotency / no duplicate reminders sent
    const secondRun = await SchedulerService.checkAndSendUpcomingClassReminders(new Date());
    assert.equal(secondRun.remindersSent, 0);
  });
});
