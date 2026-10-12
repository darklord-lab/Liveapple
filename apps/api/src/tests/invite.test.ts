import { describe, it, before } from 'node:test';
import assert from 'node:assert/strict';
import request from 'supertest';
import { createApp } from '../app.js';
import { initializePrisma, prisma } from '../utils/prisma.js';
import { hashToken } from '../utils/hash.js';

describe('Invite Flow & Security Suite', () => {
  const app = createApp();
  let adminToken: string;

  before(async () => {
    await initializePrisma();
    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({
        email: 'admin@apex.edu',
        password: 'Password@123',
      });
    adminToken = loginRes.body.accessToken;
  });

  it('POST /api/v1/invites - Admin can generate a 48h teacher invite', async () => {
    const email = `newteacher_${Date.now()}@apex.edu`;
    const res = await request(app)
      .post('/api/v1/invites')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        email,
        role: 'TEACHER',
      });

    assert.equal(res.status, 201);
    assert.ok(res.body.inviteCode, 'Should return plain invite code');
    assert.equal(res.body.role, 'TEACHER');
    assert.equal(res.body.email, email);
  });

  it('GET /api/v1/invites/validate/:code - Should validate an active invite code', async () => {
    const email = `newstudent_${Date.now()}@apex.edu`;
    // 1. Create invite
    const inviteRes = await request(app)
      .post('/api/v1/invites')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        email,
        role: 'STUDENT',
      });

    const code = inviteRes.body.inviteCode;

    // 2. Validate
    const valRes = await request(app).get(`/api/v1/invites/validate/${code}`);
    assert.equal(valRes.status, 200);
    assert.equal(valRes.body.valid, true);
    assert.equal(valRes.body.role, 'STUDENT');
  });

  it('POST /api/v1/auth/accept-invite - User can accept invite, set password, and log in', async () => {
    const email = `invitedstudent_${Date.now()}@apex.edu`;
    // 1. Create invite
    const inviteRes = await request(app)
      .post('/api/v1/invites')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        email,
        role: 'STUDENT',
      });

    const code = inviteRes.body.inviteCode;

    // 2. Accept invite & set password
    const acceptRes = await request(app)
      .post('/api/v1/auth/accept-invite')
      .send({
        inviteCode: code,
        name: 'Invited Student Name',
        password: 'NewSecurePassword@123',
      });

    assert.equal(acceptRes.status, 200);
    assert.ok(acceptRes.body.accessToken);
    assert.equal(acceptRes.body.user.email, email);
    assert.equal(acceptRes.body.user.role, 'STUDENT');

    // 3. Trying to accept again MUST fail with INVITE_ALREADY_USED
    const reuseRes = await request(app)
      .post('/api/v1/auth/accept-invite')
      .send({
        inviteCode: code,
        password: 'AnotherPassword@123',
      });

    assert.equal(reuseRes.status, 400);
    assert.equal(reuseRes.body.code, 'INVITE_ALREADY_USED');
  });

  it('POST /api/v1/auth/accept-invite - Should reject expired invite (> 48h)', async () => {
    // 1. Create expired invite directly in DB
    const expiredCode = `expired_code_${Date.now()}`;
    const institute = await prisma.institute.findFirst();

    await prisma.invite.create({
      data: {
        instituteId: institute!.id,
        email: `expireduser_${Date.now()}@apex.edu`,
        role: 'STUDENT',
        codeHash: hashToken(expiredCode),
        expiresAt: new Date(Date.now() - 3600 * 1000), // 1 hour ago
      },
    });

    // 2. Attempt to accept
    const res = await request(app)
      .post('/api/v1/auth/accept-invite')
      .send({
        inviteCode: expiredCode,
        password: 'Password@123',
      });

    assert.equal(res.status, 400);
    assert.equal(res.body.code, 'INVITE_EXPIRED');
  });
});
