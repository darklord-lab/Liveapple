import { describe, it, before } from 'node:test';
import assert from 'node:assert/strict';
import request from 'supertest';
import { createApp } from '../app.js';
import { initializePrisma } from '../utils/prisma.js';

describe('Tenant Isolation & Cross-Tenant Guard Suite', () => {
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

  it('Should forbid client from accessing another institute by spoofing instituteId', async () => {
    const res = await request(app)
      .post('/api/v1/invites')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        instituteId: 'inst-malicious-spoofed-tenant-999',
        email: 'victim@other.edu',
        role: 'STUDENT',
      });

    assert.equal(res.status, 403);
    assert.equal(res.body.code, 'FORBIDDEN');
  });
});
