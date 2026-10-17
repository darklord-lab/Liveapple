import { describe, it, before } from 'node:test';
import assert from 'node:assert/strict';
import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../app.js';
import { initializePrisma, prisma } from '../utils/prisma.js';
import { env } from '../config/env.js';

describe('Phase 4 — Live Class & LiveKit SFU Suite', () => {
  const app = createApp();
  let adminToken: string;
  let teacherToken: string;
  let studentToken: string;
  let nonEnrolledStudentToken: string;
  let testClassId: string;
  let testBatchId: string;

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

    // Log in student1
    const studentLogin = await request(app).post('/api/v1/auth/login').send({
      email: 'student1@apex.edu',
      password: 'Password@123',
    });
    studentToken = studentLogin.body.accessToken;

    // Log in student2 (non-enrolled)
    const student2Login = await request(app).post('/api/v1/auth/login').send({
      email: 'student2@apex.edu',
      password: 'Password@123',
    });
    nonEnrolledStudentToken = student2Login.body.accessToken;

    // Create a dedicated test batch
    const batchRes = await request(app)
      .post('/api/v1/batches')
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        name: `Live Test Batch ${Date.now()}`,
        subject: 'Advanced Physics',
      });
    testBatchId = batchRes.body.id;

    // Enroll student1
    await request(app)
      .post('/api/v1/batches/join')
      .set('Authorization', `Bearer ${studentToken}`)
      .send({ joinCode: batchRes.body.joinCode });

    // Create a scheduled live class
    const classRes = await request(app)
      .post('/api/v1/classes')
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        batchId: testBatchId,
        title: 'Quantum Mechanics Live Stream',
        scheduledAt: new Date(Date.now() + 60 * 60 * 1000).toISOString(),
      });
    testClassId = classRes.body.id;
  });

  it('POST /api/v1/classes/:id/start - Student CANNOT start a class (403 FORBIDDEN)', async () => {
    const res = await request(app)
      .post(`/api/v1/classes/${testClassId}/start`)
      .set('Authorization', `Bearer ${studentToken}`);

    assert.equal(res.status, 403);
  });

  it('POST /api/v1/classes/:id/start - Teacher starts live class -> status LIVE', async () => {
    const res = await request(app)
      .post(`/api/v1/classes/${testClassId}/start`)
      .set('Authorization', `Bearer ${teacherToken}`);

    assert.equal(res.status, 200);
    assert.equal(res.body.status, 'LIVE');
    assert.ok(res.body.livekitRoom);
  });

  it('POST /api/v1/classes/:id/token - Teacher obtains signed LiveKit host token', async () => {
    const res = await request(app)
      .post(`/api/v1/classes/${testClassId}/token`)
      .set('Authorization', `Bearer ${teacherToken}`);

    assert.equal(res.status, 200);
    assert.ok(res.body.token);
    assert.equal(res.body.isHost, true);
    assert.ok(res.body.serverUrl);

    // Decode token to verify LiveKit video grants
    const decoded: any = jwt.decode(res.body.token);
    assert.ok(decoded.video);
    assert.equal(decoded.video.roomAdmin, true);
    assert.equal(decoded.video.canPublish, true);
  });

  it('POST /api/v1/classes/:id/token - Enrolled student obtains signed LiveKit subscriber token', async () => {
    const res = await request(app)
      .post(`/api/v1/classes/${testClassId}/token`)
      .set('Authorization', `Bearer ${studentToken}`);

    assert.equal(res.status, 200);
    assert.ok(res.body.token);
    assert.equal(res.body.isHost, false);

    const decoded: any = jwt.decode(res.body.token);
    assert.ok(decoded.video);
    assert.equal(decoded.video.canSubscribe, true);
    assert.equal(decoded.video.canPublish, false);
  });

  it('POST /api/v1/classes/:id/token - Non-enrolled student is rejected (403 FORBIDDEN)', async () => {
    const res = await request(app)
      .post(`/api/v1/classes/${testClassId}/token`)
      .set('Authorization', `Bearer ${nonEnrolledStudentToken}`);

    assert.equal(res.status, 403);
    assert.equal(res.body.code, 'FORBIDDEN');
  });

  it('POST /api/v1/classes/:id/host/mute-all - Host can mute all participants', async () => {
    const res = await request(app)
      .post(`/api/v1/classes/${testClassId}/host/mute-all`)
      .set('Authorization', `Bearer ${teacherToken}`);

    assert.equal(res.status, 200);
    assert.equal(res.body.success, true);
  });

  it('POST /api/v1/classes/:id/host/mute-all - Student CANNOT execute host controls (403 FORBIDDEN)', async () => {
    const res = await request(app)
      .post(`/api/v1/classes/${testClassId}/host/mute-all`)
      .set('Authorization', `Bearer ${studentToken}`);

    assert.equal(res.status, 403);
  });

  it('POST /api/v1/classes/:id/host/remove-participant - Host can remove participant', async () => {
    const res = await request(app)
      .post(`/api/v1/classes/${testClassId}/host/remove-participant`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({ participantId: 'dummy-student-id' });

    assert.equal(res.status, 200);
    assert.equal(res.body.success, true);
  });

  it('POST /api/v1/classes/:id/end - Teacher ends live class -> status ENDED', async () => {
    const res = await request(app)
      .post(`/api/v1/classes/${testClassId}/end`)
      .set('Authorization', `Bearer ${teacherToken}`);

    assert.equal(res.status, 200);
    assert.equal(res.body.status, 'ENDED');
  });

  describe('LiveKit Env Hardening & Degraded Mode Suite', () => {
    it('GET /api/health - includes livekit status without leaking secrets', async () => {
      const res = await request(app).get('/api/health');
      assert.equal(res.status, 200);
      assert.equal(res.body.status, 'ok');
      assert.ok(res.body.livekit);
      assert.equal(typeof res.body.livekit.configured, 'boolean');
      assert.equal(typeof res.body.livekit.urlIsWss, 'boolean');
      assert.equal(typeof res.body.livekit.usingDefaultKeys, 'boolean');
      // Verify no secrets leaked
      assert.equal((res.body.livekit as any).apiKey, undefined);
      assert.equal((res.body.livekit as any).apiSecret, undefined);
      assert.equal((res.body.livekit as any).secret, undefined);
    });

    it('Production mode: rejects dead localhost URL with 503 LIVEKIT_NOT_CONFIGURED', async () => {
      const prevNodeEnv = env.NODE_ENV;
      const prevUrl = env.LIVEKIT_URL;
      const prevKey = env.LIVEKIT_API_KEY;
      const prevSecret = env.LIVEKIT_API_SECRET;

      try {
        (env as any).NODE_ENV = 'production';
        (env as any).LIVEKIT_URL = 'http://localhost:7880';
        (env as any).LIVEKIT_API_KEY = 'valid_key_12345';
        (env as any).LIVEKIT_API_SECRET = 'valid_secret_12345_secure_key';

        const healthRes = await request(app).get('/api/health');
        assert.equal(healthRes.body.livekit.configured, false);
        assert.equal(healthRes.body.livekit.urlIsWss, false);

        const tokenRes = await request(app)
          .post(`/api/v1/classes/${testClassId}/token`)
          .set('Authorization', `Bearer ${teacherToken}`);

        assert.equal(tokenRes.status, 503);
        assert.equal(tokenRes.body.code, 'LIVEKIT_NOT_CONFIGURED');
        assert.equal(tokenRes.body.message, 'Video server abhi set nahi hua');
      } finally {
        (env as any).NODE_ENV = prevNodeEnv;
        (env as any).LIVEKIT_URL = prevUrl;
        (env as any).LIVEKIT_API_KEY = prevKey;
        (env as any).LIVEKIT_API_SECRET = prevSecret;
      }
    });

    it('Production mode: rejects default keys (devkey/secret) even with wss URL', async () => {
      const prevNodeEnv = env.NODE_ENV;
      const prevUrl = env.LIVEKIT_URL;
      const prevKey = env.LIVEKIT_API_KEY;
      const prevSecret = env.LIVEKIT_API_SECRET;

      try {
        (env as any).NODE_ENV = 'production';
        (env as any).LIVEKIT_URL = 'wss://liveapple.livekit.cloud';
        (env as any).LIVEKIT_API_KEY = 'devkey';
        (env as any).LIVEKIT_API_SECRET = 'secret';

        const healthRes = await request(app).get('/api/health');
        assert.equal(healthRes.body.livekit.configured, false);
        assert.equal(healthRes.body.livekit.usingDefaultKeys, true);

        const tokenRes = await request(app)
          .post(`/api/v1/classes/${testClassId}/token`)
          .set('Authorization', `Bearer ${teacherToken}`);

        assert.equal(tokenRes.status, 503);
        assert.equal(tokenRes.body.code, 'LIVEKIT_NOT_CONFIGURED');
      } finally {
        (env as any).NODE_ENV = prevNodeEnv;
        (env as any).LIVEKIT_URL = prevUrl;
        (env as any).LIVEKIT_API_KEY = prevKey;
        (env as any).LIVEKIT_API_SECRET = prevSecret;
      }
    });

    it('Production mode: succeeds when valid wss URL and non-default keys are provided', async () => {
      const prevNodeEnv = env.NODE_ENV;
      const prevUrl = env.LIVEKIT_URL;
      const prevKey = env.LIVEKIT_API_KEY;
      const prevSecret = env.LIVEKIT_API_SECRET;

      try {
        (env as any).NODE_ENV = 'production';
        (env as any).LIVEKIT_URL = 'wss://liveapple-prod.livekit.cloud';
        (env as any).LIVEKIT_API_KEY = 'APIprod_valid_key_999';
        (env as any).LIVEKIT_API_SECRET = 'SECRET_valid_secure_secret_prod_888';

        const healthRes = await request(app).get('/api/health');
        assert.equal(healthRes.body.livekit.configured, true);
        assert.equal(healthRes.body.livekit.urlIsWss, true);
        assert.equal(healthRes.body.livekit.usingDefaultKeys, false);
        assert.equal(healthRes.body.livekit.urlHost, 'liveapple-prod.livekit.cloud');

        const tokenRes = await request(app)
          .post(`/api/v1/classes/${testClassId}/token`)
          .set('Authorization', `Bearer ${teacherToken}`);

        assert.equal(tokenRes.status, 200);
        assert.ok(tokenRes.body.token);
        assert.equal(tokenRes.body.serverUrl, 'wss://liveapple-prod.livekit.cloud');
      } finally {
        (env as any).NODE_ENV = prevNodeEnv;
        (env as any).LIVEKIT_URL = prevUrl;
        (env as any).LIVEKIT_API_KEY = prevKey;
        (env as any).LIVEKIT_API_SECRET = prevSecret;
      }
    });

    it('Degraded mode does NOT crash other routes: login and timetable continue to work', async () => {
      const prevNodeEnv = env.NODE_ENV;
      const prevUrl = env.LIVEKIT_URL;
      const prevKey = env.LIVEKIT_API_KEY;
      const prevSecret = env.LIVEKIT_API_SECRET;

      try {
        (env as any).NODE_ENV = 'production';
        (env as any).LIVEKIT_URL = 'http://localhost:7880';
        (env as any).LIVEKIT_API_KEY = 'devkey';
        (env as any).LIVEKIT_API_SECRET = 'secret';

        // Login still works
        const loginRes = await request(app).post('/api/v1/auth/login').send({
          email: 'teacher1@apex.edu',
          password: 'Password@123',
        });
        assert.equal(loginRes.status, 200);
        assert.ok(loginRes.body.accessToken);

        // Timetable still works
        const timetableRes = await request(app)
          .get('/api/v1/timetable')
          .set('Authorization', `Bearer ${teacherToken}`);
        assert.equal(timetableRes.status, 200);

        // Batches still work
        const batchesRes = await request(app)
          .get('/api/v1/batches')
          .set('Authorization', `Bearer ${teacherToken}`);
        assert.equal(batchesRes.status, 200);
      } finally {
        (env as any).NODE_ENV = prevNodeEnv;
        (env as any).LIVEKIT_URL = prevUrl;
        (env as any).LIVEKIT_API_KEY = prevKey;
        (env as any).LIVEKIT_API_SECRET = prevSecret;
      }
    });
  });
});

