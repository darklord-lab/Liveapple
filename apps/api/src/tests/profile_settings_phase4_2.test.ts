import test, { before } from 'node:test';
import assert from 'node:assert/strict';
import supertest from 'supertest';
import { createApp } from '../app.js';
import { prisma } from '../utils/prisma.js';

const app = createApp();
const request = supertest(app);

test('Phase 4.2 — Edit Profile, Avatar Upload & Settings Suite', async (t) => {
  let studentToken: string;
  let teacherToken: string;
  let studentUserId: string;
  let uploadedAvatarKey: string;

  before(async () => {
    // 1. Log in student
    const studentRes = await request
      .post('/api/v1/auth/login')
      .send({ email: 'student1@apex.edu', password: 'Password@123' });
    assert.equal(studentRes.status, 200);
    studentToken = studentRes.body.accessToken;
    studentUserId = studentRes.body.user.id;

    // 2. Log in teacher
    const teacherRes = await request
      .post('/api/v1/auth/login')
      .send({ email: 'teacher1@apex.edu', password: 'Password@123' });
    assert.equal(teacherRes.status, 200);
    teacherToken = teacherRes.body.accessToken;
  });

  await t.test('1. Student updates name and phone number successfully', async () => {
    const res = await request
      .patch('/api/v1/auth/profile')
      .set('Authorization', `Bearer ${studentToken}`)
      .send({
        name: 'Aarav Sharma Updated',
        phone: '+91 9876543210',
      });

    assert.equal(res.status, 200);
    assert.equal(res.body.message, 'Profile updated successfully');
    assert.equal(res.body.user.name, 'Aarav Sharma Updated');
    assert.equal(res.body.user.phone, '+91 9876543210');

    // Verify in database
    const dbUser = await prisma.user.findUnique({ where: { id: studentUserId } });
    assert.equal(dbUser?.name, 'Aarav Sharma Updated');
    assert.equal(dbUser?.phone, '+91 9876543210');
  });

  await t.test('2. Student updates notification preferences', async () => {
    const prefs = {
      reminders: false,
      liveAlerts: true,
      homework: false,
      testAlerts: true,
    };

    const res = await request
      .patch('/api/v1/auth/profile')
      .set('Authorization', `Bearer ${studentToken}`)
      .send({
        notificationPrefs: prefs,
      });

    assert.equal(res.status, 200);
    assert.ok(res.body.user.notificationPrefs);
    const parsedPrefs = JSON.parse(res.body.user.notificationPrefs);
    assert.equal(parsedPrefs.reminders, false);
    assert.equal(parsedPrefs.liveAlerts, true);
    assert.equal(parsedPrefs.homework, false);
    assert.equal(parsedPrefs.testAlerts, true);
  });

  await t.test('3. Rejects invalid name with less than 2 characters (400)', async () => {
    const res = await request
      .patch('/api/v1/auth/profile')
      .set('Authorization', `Bearer ${studentToken}`)
      .send({
        name: 'A',
      });

    assert.equal(res.status, 400);
  });

  await t.test('4. User can upload a profile avatar image (JPEG/PNG)', async () => {
    // 1x1 valid PNG buffer
    const fakePngBuffer = Buffer.from(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
      'base64'
    );

    const res = await request
      .post('/api/v1/auth/avatar')
      .set('Authorization', `Bearer ${studentToken}`)
      .attach('avatar', fakePngBuffer, 'profile.png');

    assert.equal(res.status, 200);
    assert.equal(res.body.message, 'Profile photo updated successfully');
    assert.ok(res.body.avatarUrl);
    assert.ok(res.body.avatarUrl.includes('/v1/auth/avatar/'));

    // Extract key
    uploadedAvatarKey = res.body.avatarUrl.split('/v1/auth/avatar/')[1];
    assert.ok(uploadedAvatarKey);

    // Verify in database
    const dbUser = await prisma.user.findUnique({ where: { id: studentUserId } });
    assert.equal(dbUser?.avatarUrl, res.body.avatarUrl);
  });

  await t.test('5. Avatar image can be streamed via GET /v1/auth/avatar/:key', async () => {
    assert.ok(uploadedAvatarKey, 'Avatar key must exist');

    const res = await request
      .get(`/api/v1/auth/avatar/${uploadedAvatarKey}`);

    assert.equal(res.status, 200);
    assert.equal(res.headers['content-type'], 'image/png');
    assert.ok(res.headers['cache-control']);
    assert.ok(res.body.length > 0 || res.text.length > 0);
  });

  await t.test('6. Rejects disallowed file types for avatar (.exe) with 400', async () => {
    const fakeExeBuffer = Buffer.from('MZ00000000000000');

    const res = await request
      .post('/api/v1/auth/avatar')
      .set('Authorization', `Bearer ${studentToken}`)
      .attach('avatar', fakeExeBuffer, 'virus.exe');

    assert.equal(res.status, 400);
    assert.equal(res.body.code, 'INVALID_FILE_TYPE');
  });

  await t.test('7. GET /api/v1/auth/me returns updated profile details', async () => {
    const res = await request
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${studentToken}`);

    assert.equal(res.status, 200);
    assert.equal(res.body.user.name, 'Aarav Sharma Updated');
    assert.equal(res.body.user.phone, '+91 9876543210');
    assert.ok(res.body.user.avatarUrl);
    assert.ok(res.body.user.notificationPrefs);
  });

  await t.test('8. Security: Unauthenticated requests return 401 UNAUTHORIZED', async () => {
    const patchRes = await request
      .patch('/api/v1/auth/profile')
      .send({ name: 'Hacker' });
    assert.equal(patchRes.status, 401);

    const avatarRes = await request
      .post('/api/v1/auth/avatar');
    assert.equal(avatarRes.status, 401);
  });
});
