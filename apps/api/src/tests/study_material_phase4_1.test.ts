import test, { before } from 'node:test';
import assert from 'node:assert/strict';
import supertest from 'supertest';
import { createApp } from '../app.js';
import { prisma } from '../utils/prisma.js';

const app = createApp();
const request = supertest(app);

test('Phase 4.1 — Study Material & Storage Adapter Suite', async (t) => {
  let adminToken: string;
  let teacherToken: string;
  let enrolledStudentToken: string;
  let nonEnrolledStudentToken: string;
  let batchId: string;
  let folderId: string;
  let freeMaterialId: string;
  let paidMaterialId: string;

  before(async () => {
    // 1. Clean up previous test artifacts
    await prisma.studyMaterial.deleteMany({ where: { institute: { slug: 'apex' } } });
    await prisma.materialFolder.deleteMany({ where: { institute: { slug: 'apex' } } });
    await prisma.batch.deleteMany({ where: { name: { startsWith: 'P41-' } } });

    // 2. Log in users
    const adminRes = await request
      .post('/api/v1/auth/login')
      .send({ email: 'admin@apex.edu', password: 'Password@123' });
    adminToken = adminRes.body.accessToken;

    const teacherRes = await request
      .post('/api/v1/auth/login')
      .send({ email: 'teacher1@apex.edu', password: 'Password@123' });
    teacherToken = teacherRes.body.accessToken;

    const student1Res = await request
      .post('/api/v1/auth/login')
      .send({ email: 'student1@apex.edu', password: 'Password@123' });
    enrolledStudentToken = student1Res.body.accessToken;

    const student2Res = await request
      .post('/api/v1/auth/login')
      .send({ email: 'student2@apex.edu', password: 'Password@123' });
    nonEnrolledStudentToken = student2Res.body.accessToken;

    // 3. Create test batch
    const batchRes = await request
      .post('/api/v1/batches')
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({ name: 'P41-Modern Physics', subject: 'Physics' });
    batchId = batchRes.body.id;

    // 4. Enroll student1 in this batch
    await request
      .post('/api/v1/batches/join')
      .set('Authorization', `Bearer ${enrolledStudentToken}`)
      .send({ joinCode: batchRes.body.joinCode });
  });

  await t.test('1. Teacher can create a folder inside a batch', async () => {
    const res = await request
      .post(`/api/v1/batches/${batchId}/folders`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({ name: 'Chapter 1: Wave Optics' });

    assert.equal(res.status, 201);
    assert.equal(res.body.status, 'success');
    assert.equal(res.body.data.name, 'Chapter 1: Wave Optics');
    assert.equal(res.body.data.batchId, batchId);
    folderId = res.body.data.id;
  });

  await t.test('2. Student CANNOT create a folder (403 FORBIDDEN)', async () => {
    const res = await request
      .post(`/api/v1/batches/${batchId}/folders`)
      .set('Authorization', `Bearer ${enrolledStudentToken}`)
      .send({ name: 'Hacked Folder' });

    assert.equal(res.status, 403);
  });

  await t.test('3. Teacher can upload a PDF file into the batch and folder', async () => {
    const fakePdfBuffer = Buffer.from('%PDF-1.4 Mock Wave Optics Lecture Notes Content');

    const res = await request
      .post(`/api/v1/batches/${batchId}/materials`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .field('title', 'Wave Optics Formula Sheet')
      .field('description', 'Comprehensive summary of interference & diffraction')
      .field('folderId', folderId)
      .field('isFree', 'false')
      .attach('file', fakePdfBuffer, {
        filename: 'Wave_Optics_Notes.pdf',
        contentType: 'application/pdf',
      });

    assert.equal(res.status, 201);
    assert.equal(res.body.status, 'success');
    assert.equal(res.body.data.title, 'Wave Optics Formula Sheet');
    assert.equal(res.body.data.kind, 'PDF');
    assert.equal(res.body.data.folderId, folderId);
    assert.equal(res.body.data.isFree, false);
    assert.ok(res.body.data.fileKey);
    assert.ok(res.body.data.sizeBytes > 0);
    paidMaterialId = res.body.data.id;
  });

  await t.test('4. Teacher can add an external video link with isFree=true flag', async () => {
    const res = await request
      .post(`/api/v1/batches/${batchId}/materials`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        title: 'Wave Optics Concept Video',
        description: 'Free preview video lecture on Young double slit experiment',
        url: 'https://youtube.com/watch?v=mock_video_optics',
        isFree: true,
      });

    assert.equal(res.status, 201);
    assert.equal(res.body.status, 'success');
    assert.equal(res.body.data.kind, 'VIDEO_LINK');
    assert.equal(res.body.data.isFree, true);
    freeMaterialId = res.body.data.id;
  });

  await t.test('5. Security: Disallowed file types (.exe / .sh) are rejected with 400', async () => {
    const fakeScript = Buffer.from('echo "malicious"');

    const res = await request
      .post(`/api/v1/batches/${batchId}/materials`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .field('title', 'Suspicious Payload')
      .attach('file', fakeScript, {
        filename: 'payload.exe',
        contentType: 'application/x-msdownload',
      });

    assert.equal(res.status, 400);
    assert.equal(res.body.code, 'INVALID_FILE_TYPE');
  });

  await t.test('6. Enrolled student can list all materials in the batch', async () => {
    const res = await request
      .get(`/api/v1/batches/${batchId}/materials`)
      .set('Authorization', `Bearer ${enrolledStudentToken}`);

    assert.equal(res.status, 200);
    assert.equal(res.body.data.isEnrolled, true);
    assert.equal(res.body.data.materials.length, 2);
  });

  await t.test('7. Enrolled student can download the uploaded PDF file', async () => {
    const res = await request
      .get(`/api/v1/materials/${paidMaterialId}/download`)
      .set('Authorization', `Bearer ${enrolledStudentToken}`);

    assert.equal(res.status, 200);
    assert.equal(res.header['content-type'], 'application/pdf');
    assert.ok(res.header['content-disposition'].includes('Wave_Optics_Notes.pdf'));
    assert.ok(res.body.toString().includes('%PDF-1.4 Mock Wave Optics Lecture Notes Content'));
  });

  await t.test('8. Non-enrolled student only sees free preview materials', async () => {
    const res = await request
      .get(`/api/v1/batches/${batchId}/materials`)
      .set('Authorization', `Bearer ${nonEnrolledStudentToken}`);

    assert.equal(res.status, 200);
    assert.equal(res.body.data.isEnrolled, false);
    // Only the free material should be visible
    assert.equal(res.body.data.materials.length, 1);
    assert.equal(res.body.data.materials[0].id, freeMaterialId);
    assert.equal(res.body.data.materials[0].isFree, true);
  });

  await t.test('9. Non-enrolled student CANNOT download paid material (403 FORBIDDEN)', async () => {
    const res = await request
      .get(`/api/v1/materials/${paidMaterialId}/download`)
      .set('Authorization', `Bearer ${nonEnrolledStudentToken}`);

    assert.equal(res.status, 403);
    assert.equal(res.body.code, 'ENROLLMENT_REQUIRED');
  });

  await t.test('10. Teacher can list folders with material counts', async () => {
    const res = await request
      .get(`/api/v1/batches/${batchId}/folders`)
      .set('Authorization', `Bearer ${teacherToken}`);

    assert.equal(res.status, 200);
    assert.ok(res.body.data.length >= 1);
    assert.equal(res.body.data[0].name, 'Chapter 1: Wave Optics');
    assert.equal(res.body.data[0]._count.materials, 1);
  });

  await t.test('11. Teacher can delete a material and it is removed from storage', async () => {
    const res = await request
      .delete(`/api/v1/materials/${paidMaterialId}`)
      .set('Authorization', `Bearer ${teacherToken}`);

    assert.equal(res.status, 200);
    assert.equal(res.body.data.success, true);

    // Verify deleted
    const checkRes = await request
      .get(`/api/v1/materials/${paidMaterialId}/download`)
      .set('Authorization', `Bearer ${enrolledStudentToken}`);
    assert.equal(checkRes.status, 404);
  });

  await t.test('12. Teacher can delete a folder', async () => {
    const res = await request
      .delete(`/api/v1/materials/folders/${folderId}`)
      .set('Authorization', `Bearer ${teacherToken}`);

    assert.equal(res.status, 200);
    assert.equal(res.body.data.success, true);
  });
});
