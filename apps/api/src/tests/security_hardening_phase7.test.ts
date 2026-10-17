import test, { before } from 'node:test';
import assert from 'node:assert/strict';
import supertest from 'supertest';
import argon2 from 'argon2';
import { createApp } from '../app.js';
import { prisma } from '../utils/prisma.js';
import {
  validateUpload,
  LocalStorageService,
  S3StorageService,
  SAFE_KEY_REGEX,
  MAX_MATERIAL_SIZE_BYTES,
  MATERIAL_MIME_MAP,
} from '../services/storage.service.js';

const app = createApp();
const request = supertest(app);

test('Stage 7 — Security Hardening, Upload Fuzzing & Tenant Isolation Suite', async (t) => {
  let apexTeacherToken: string;
  let apexStudentToken: string;
  let apexBatchId: string;
  let apexInstituteId: string;

  let quantumTeacherToken: string;
  let quantumStudentToken: string;
  let quantumBatchId: string;
  let quantumInstituteId: string;

  before(async () => {
    // 1. Fetch Apex institute
    const apex = await prisma.institute.findFirst({ where: { slug: 'apex' } });
    assert.ok(apex, 'Apex institute must exist');
    apexInstituteId = apex.id;

    // 2. Upsert second institute 'quantum' for multi-tenant isolation testing
    const quantum = await prisma.institute.upsert({
      where: { slug: 'quantum' },
      update: {},
      create: {
        id: 'inst-quantum-01',
        name: 'Quantum Physics Academy',
        slug: 'quantum',
        code: 'QUANT01',
        primaryColor: '#6C5CE7',
        tagline: 'Advanced Theoretical Physics',
        plan: 'STANDARD',
      },
    });
    quantumInstituteId = quantum.id;

    // Default password hash
    const defaultPasswordHash = await argon2.hash('Password@123', {
      type: argon2.argon2id,
      memoryCost: 65536,
      timeCost: 3,
      parallelism: 4,
    });

    // 3. Create or find Quantum teacher and student
    let qTeacher = await prisma.user.findFirst({
      where: { instituteId: quantumInstituteId, email: 'teacher1@quantum.edu' },
    });
    if (!qTeacher) {
      qTeacher = await prisma.user.create({
        data: {
          instituteId: quantumInstituteId,
          email: 'teacher1@quantum.edu',
          passwordHash: defaultPasswordHash,
          name: 'Quantum Teacher',
          role: 'TEACHER',
          status: 'ACTIVE',
        },
      });
    }

    let qStudent = await prisma.user.findFirst({
      where: { instituteId: quantumInstituteId, email: 'student1@quantum.edu' },
    });
    if (!qStudent) {
      qStudent = await prisma.user.create({
        data: {
          instituteId: quantumInstituteId,
          email: 'student1@quantum.edu',
          passwordHash: defaultPasswordHash,
          name: 'Quantum Student',
          role: 'STUDENT',
          status: 'ACTIVE',
        },
      });
    }

    let qBatch = await prisma.batch.findFirst({
      where: { instituteId: quantumInstituteId },
    });
    if (!qBatch) {
      qBatch = await prisma.batch.create({
        data: {
          instituteId: quantumInstituteId,
          name: 'Quantum Mechanics 101',
          subject: 'Physics',
          joinCode: 'QM101-JOIN',
          teacherId: qTeacher.id,
        },
      });
    }
    quantumBatchId = qBatch.id;


    // 4. Login Apex teacher and student
    const apexTeacherRes = await request
      .post('/api/v1/auth/login')
      .send({ email: 'teacher1@apex.edu', password: 'Password@123' });
    assert.equal(apexTeacherRes.status, 200);
    apexTeacherToken = apexTeacherRes.body.accessToken;

    const apexStudentRes = await request
      .post('/api/v1/auth/login')
      .send({ email: 'student1@apex.edu', password: 'Password@123' });
    assert.equal(apexStudentRes.status, 200);
    apexStudentToken = apexStudentRes.body.accessToken;

    // 5. Login Quantum teacher and student
    const quantumTeacherRes = await request
      .post('/api/v1/auth/login')
      .send({ email: 'teacher1@quantum.edu', password: 'Password@123' });
    assert.equal(quantumTeacherRes.status, 200);
    quantumTeacherToken = quantumTeacherRes.body.accessToken;

    const quantumStudentRes = await request
      .post('/api/v1/auth/login')
      .send({ email: 'student1@quantum.edu', password: 'Password@123' });
    assert.equal(quantumStudentRes.status, 200);
    quantumStudentToken = quantumStudentRes.body.accessToken;

    // 6. Apex batch
    const apexBatch = await prisma.batch.findFirst({
      where: { instituteId: apexInstituteId },
    });
    assert.ok(apexBatch, 'Apex batch must exist');
    apexBatchId = apexBatch.id;
  });


  /* -------------------------------------------------------------------------- */
  /* 1. UPLOAD FUZZING & INJECTION TESTS                                        */
  /* -------------------------------------------------------------------------- */
  await t.test('Upload Fuzz: Rejects executable files with spoofed MIME', async () => {
    assert.throws(
      () =>
        validateUpload(
          {
            buffer: Buffer.from('MZ... executable payload'),
            mimetype: 'application/pdf', // spoofed MIME
            originalname: 'trojan_payload.exe',
            size: 1024,
          },
          MAX_MATERIAL_SIZE_BYTES,
          MATERIAL_MIME_MAP
        ),
      (err: any) => err.statusCode === 400 && err.code === 'INVALID_FILE_TYPE'
    );
  });

  await t.test('Upload Fuzz: Rejects double extension evasion (e.g. doc.pdf.exe, image.png.php)', async () => {
    const maliciousNames = [
      'syllabus.pdf.exe',
      'assignment.docx.php',
      'notes.pdf.sh',
      'photo.jpg.bat',
      'script.png.cmd',
      'payload.pdf.js',
    ];

    for (const name of maliciousNames) {
      assert.throws(
        () =>
          validateUpload(
            {
              buffer: Buffer.from('malicious script code'),
              mimetype: 'application/pdf',
              originalname: name,
              size: 512,
            },
            MAX_MATERIAL_SIZE_BYTES,
            MATERIAL_MIME_MAP
          ),
        (err: any) => err.statusCode === 400 && err.code === 'INVALID_FILE_TYPE'
      );
    }
  });

  await t.test('Upload Fuzz: Rejects null-byte injection in filename', async () => {
    assert.throws(
      () =>
        validateUpload(
          {
            buffer: Buffer.from('test data'),
            mimetype: 'application/pdf',
            originalname: 'assignment.pdf\0.exe',
            size: 512,
          },
          MAX_MATERIAL_SIZE_BYTES,
          MATERIAL_MIME_MAP
        ),
      (err: any) => err.statusCode === 400 && err.code === 'INVALID_FILE_TYPE'
    );
  });

  await t.test('Upload Fuzz: Rejects directory traversal in filename', async () => {
    assert.throws(
      () =>
        validateUpload(
          {
            buffer: Buffer.from('traversal payload'),
            mimetype: 'application/pdf',
            originalname: '../../etc/passwd',
            size: 512,
          },
          MAX_MATERIAL_SIZE_BYTES,
          MATERIAL_MIME_MAP
        ),
      (err: any) => err.statusCode === 400 && err.code === 'BAD_REQUEST'
    );
  });

  await t.test('Upload Fuzz: Rejects SVG files to prevent stored XSS scripts', async () => {
    assert.throws(
      () =>
        validateUpload(
          {
            buffer: Buffer.from('<svg><script>alert(1)</script></svg>'),
            mimetype: 'image/svg+xml',
            originalname: 'vector_logo.svg',
            size: 256,
          },
          MAX_MATERIAL_SIZE_BYTES,
          MATERIAL_MIME_MAP
        ),
      (err: any) => err.statusCode === 400 && err.code === 'INVALID_FILE_TYPE'
    );
  });

  await t.test('Upload Fuzz: Rejects oversized files (> 25MB)', async () => {
    assert.throws(
      () =>
        validateUpload(
          {
            buffer: Buffer.alloc(10),
            mimetype: 'application/pdf',
            originalname: 'huge_book.pdf',
            size: 26 * 1024 * 1024, // 26MB
          },
          MAX_MATERIAL_SIZE_BYTES,
          MATERIAL_MIME_MAP
        ),
      (err: any) => err.statusCode === 400 && err.code === 'FILE_TOO_LARGE'
    );
  });

  /* -------------------------------------------------------------------------- */
  /* 2. STORAGE KEY PATH TRAVERSAL DEFENSE                                      */
  /* -------------------------------------------------------------------------- */
  await t.test('Storage Key: Rejects path traversal and malformed keys', () => {
    const localStorage = new LocalStorageService();
    const maliciousKeys = [
      '../../etc/passwd',
      '..\\..\\windows\\system32\\calc.exe',
      'valid-id.pdf/../../etc',
      'invalid-extension',
      'key-with-null\0.pdf',
      'key-with-space .pdf',
    ];

    for (const key of maliciousKeys) {
      assert.throws(
        () => localStorage.getStream(key),
        (err: any) => err.statusCode === 400 && err.code === 'BAD_REQUEST'
      );
    }
  });

  await t.test('Storage Key: Valid regex only accepts safe UUID filenames', () => {
    assert.equal(SAFE_KEY_REGEX.test('a1b2c3d4-e5f6-7890-abcd-ef1234567890.pdf'), true);
    assert.equal(SAFE_KEY_REGEX.test('random_key_123.jpg'), true);
    assert.equal(SAFE_KEY_REGEX.test('../test.pdf'), false);
    assert.equal(SAFE_KEY_REGEX.test('test/nested.pdf'), false);
    assert.equal(SAFE_KEY_REGEX.test('test\\nested.pdf'), false);
    assert.equal(SAFE_KEY_REGEX.test('file'), false);
  });

  /* -------------------------------------------------------------------------- */
  /* 3. MULTI-TENANT ISOLATION (RULES.md Section F.1 & F.2)                     */
  /* -------------------------------------------------------------------------- */
  await t.test('Tenant Isolation: Teacher in Apex uploads material, student in Quantum cannot access (404)', async () => {
    // 1. Apex teacher creates study material
    const uploadRes = await request
      .post(`/api/v1/batches/${apexBatchId}/materials`)
      .set('Authorization', `Bearer ${apexTeacherToken}`)
      .field('title', 'Apex Physics Thermodynamics Notes')
      .field('isFree', 'true')
      .attach('file', Buffer.from('%PDF-1.4 test study notes body'), {
        filename: 'Apex_Physics.pdf',
        contentType: 'application/pdf',
      });

    assert.equal(uploadRes.status, 201);
    const materialId = uploadRes.body.data.id;
    assert.ok(materialId);

    // 2. Quantum student attempts to download Apex material
    // MUST return 404 per RULES.md F.2 (Never leak existence with 403)
    const crossDownloadRes = await request
      .get(`/api/v1/materials/${materialId}/download`)
      .set('Authorization', `Bearer ${quantumStudentToken}`);

    assert.equal(
      crossDownloadRes.status,
      404,
      'Cross-tenant download must return 404 to prevent resource enumeration'
    );
  });

  await t.test('Tenant Isolation: Apex user cannot access Quantum batch data (404)', async () => {
    const crossBatchRes = await request
      .get(`/api/v1/batches/${quantumBatchId}`)
      .set('Authorization', `Bearer ${apexStudentToken}`);

    assert.equal(crossBatchRes.status, 404);
  });

  await t.test('Tenant Isolation: Quantum teacher cannot delete Apex folder or material (404)', async () => {
    // 1. Create folder in Apex
    const createFolderRes = await request
      .post(`/api/v1/batches/${apexBatchId}/folders`)
      .set('Authorization', `Bearer ${apexTeacherToken}`)
      .send({ name: 'Apex Secure Folder' });

    assert.equal(createFolderRes.status, 201);
    const folderId = createFolderRes.body.data.id;

    // 2. Quantum teacher attempts to delete Apex folder
    const crossDeleteRes = await request
      .delete(`/api/v1/materials/folders/${folderId}`)
      .set('Authorization', `Bearer ${quantumTeacherToken}`);

    assert.equal(crossDeleteRes.status, 404);
  });

  /* -------------------------------------------------------------------------- */
  /* 4. RATE LIMITING HEADERS & CHECKS (RULES.md Section F.6)                   */
  /* -------------------------------------------------------------------------- */
  await t.test('Rate Limiter: Public institute lookup includes rate limit headers (30 req/min)', async () => {
    const res = await request.get('/api/v1/institute/lookup/APEX01');
    assert.equal(res.status, 200);
    // express-rate-limit standard headers
    const limitHeader = res.headers['ratelimit-limit'];
    assert.ok(limitHeader, 'RateLimit-Limit header must be present');
    assert.equal(limitHeader, '30');
  });

  await t.test('Rate Limiter: Auth endpoints enforce 20 requests per 15m window', async () => {
    const res = await request
      .post('/api/v1/auth/login')
      .send({ email: 'teacher1@apex.edu', password: 'Password@123' });
    assert.equal(res.status, 200);
    const limitHeader = res.headers['ratelimit-limit'];
    assert.ok(limitHeader, 'RateLimit-Limit header must be present');
    assert.equal(limitHeader, '20');
  });

  /* -------------------------------------------------------------------------- */
  /* 5. CLOUDFLARE R2 / S3 STORAGE ADAPTER VERIFICATION                        */
  /* -------------------------------------------------------------------------- */
  await t.test('S3 / Cloudflare R2 Adapter: Validates upload and implements StorageService interface', async () => {
    const s3Service = new S3StorageService({
      endpoint: 'https://demo-account.r2.cloudflarestorage.com',
      bucket: 'classora-materials',
      accessKeyId: 'test-key',
      secretAccessKey: 'test-secret',
    });

    // 1. Upload validation happens correctly
    const putResult = await s3Service.put({
      buffer: Buffer.from('%PDF-1.4 test content'),
      mimetype: 'application/pdf',
      originalname: 's3_test_notes.pdf',
      size: 50,
    });

    assert.ok(putResult.key);
    assert.ok(putResult.key.endsWith('.pdf'));
    assert.equal(putResult.sizeBytes, 50);

    // 2. Traversal protection on S3 key
    await assert.rejects(
      async () => await s3Service.getStream('../../etc/passwd'),
      (err: any) => err.statusCode === 400
    );
  });
});
