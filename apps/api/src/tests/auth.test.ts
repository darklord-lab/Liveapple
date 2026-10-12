import { describe, it, before } from 'node:test';
import assert from 'node:assert/strict';
import request from 'supertest';
import { createApp } from '../app.js';
import { initializePrisma, prisma } from '../utils/prisma.js';

describe('Auth & Security Suite', () => {
  const app = createApp();

  before(async () => {
    await initializePrisma();
  });

  it('POST /api/v1/auth/login - should authenticate admin and return access + refresh tokens', async () => {
    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({
        email: 'admin@apex.edu',
        password: 'Password@123',
      });

    assert.equal(res.status, 200);
    assert.ok(res.body.accessToken, 'Should return accessToken');
    assert.ok(res.body.refreshToken, 'Should return refreshToken');
    assert.equal(res.body.user.role, 'ADMIN');
    assert.equal(res.body.user.email, 'admin@apex.edu');
    assert.equal(res.body.institute.slug, 'apex');
  });

  it('POST /api/v1/auth/login - should reject invalid password with 401 UNAUTHORIZED', async () => {
    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({
        email: 'admin@apex.edu',
        password: 'WrongPassword!',
      });

    assert.equal(res.status, 401);
    assert.equal(res.body.code, 'UNAUTHORIZED');
  });

  it('POST /api/v1/auth/refresh - should rotate refresh token and issue new token pair', async () => {
    // 1. Login
    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({
        email: 'teacher1@apex.edu',
        password: 'Password@123',
      });

    const oldRefreshToken = loginRes.body.refreshToken;

    // 2. Refresh
    const refreshRes = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: oldRefreshToken });

    assert.equal(refreshRes.status, 200);
    assert.ok(refreshRes.body.accessToken);
    assert.ok(refreshRes.body.refreshToken);
    assert.notEqual(refreshRes.body.refreshToken, oldRefreshToken, 'Refresh token must rotate');

    // 3. REUSE DETECTION: Re-using oldRefreshToken MUST trigger TOKEN_REUSED
    const reuseRes = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: oldRefreshToken });

    assert.equal(reuseRes.status, 401);
    assert.equal(reuseRes.body.code, 'TOKEN_REUSED');

    // 4. And the newRefreshToken should ALSO be revoked because reuse was detected!
    const subsequentRes = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: refreshRes.body.refreshToken });

    assert.equal(subsequentRes.status, 401);
    assert.equal(subsequentRes.body.code, 'TOKEN_REUSED');
  });

  it('GET /api/v1/auth/me - should return authenticated user profile from token', async () => {
    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({
        email: 'student1@apex.edu',
        password: 'Password@123',
      });

    const token = loginRes.body.accessToken;

    const meRes = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${token}`);

    assert.equal(meRes.status, 200);
    assert.equal(meRes.body.user.role, 'STUDENT');
    assert.equal(meRes.body.user.email, 'student1@apex.edu');
  });

  it('POST /api/v1/auth/logout - should revoke refresh token', async () => {
    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({
        email: 'student2@apex.edu',
        password: 'Password@123',
      });

    const refreshToken = loginRes.body.refreshToken;

    const logoutRes = await request(app)
      .post('/api/v1/auth/logout')
      .send({ refreshToken });

    assert.equal(logoutRes.status, 200);

    // Refresh with logged out token should fail
    const refreshRes = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken });

    assert.equal(refreshRes.status, 401);
  });
});
