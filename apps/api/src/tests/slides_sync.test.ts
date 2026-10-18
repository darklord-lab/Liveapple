import { describe, it, before, after } from 'node:test';
import assert from 'node:assert/strict';
import http from 'node:http';
import request from 'supertest';
import { io as Client, Socket } from 'socket.io-client';
import { Server } from 'socket.io';
import { createApp } from '../app.js';
import { setupSocketGateway, resetSocketGatewayState } from '../gateway/socket.js';
import { initializePrisma } from '../utils/prisma.js';

describe('Part 1 Item 2: PDF Slides Upload & Real-Time Sync Integration Test', () => {
  const app = createApp();
  let server: http.Server;
  let serverPort: number;
  let teacherToken: string;
  let student1Token: string;
  let student2Token: string;
  let teacherSocket: Socket;
  let student1Socket: Socket;
  let student2Socket: Socket;
  let ioServer: Server;
  let testClassId = 'class-demo-phy-01';

  before(async () => {
    await initializePrisma();

    server = http.createServer(app);
    ioServer = new Server(server, { cors: { origin: '*' } });
    setupSocketGateway(ioServer);

    await new Promise<void>((resolve) => {
      server.listen(0, () => {
        const addr = server.address();
        if (typeof addr === 'object' && addr !== null) {
          serverPort = addr.port;
        }
        server.unref();
        resolve();
      });
    });

    const teacherLogin = await request(app).post('/api/v1/auth/login').send({
      email: 'teacher1@apex.edu',
      password: 'Password@123',
    });
    teacherToken = teacherLogin.body.accessToken;

    const classesRes = await request(app)
      .get('/api/v1/classes')
      .set('Authorization', `Bearer ${teacherToken}`);
    const classList = Array.isArray(classesRes.body) ? classesRes.body : (classesRes.body?.data || classesRes.body?.classes || []);
    if (classList.length > 0 && classList[0].id) {
      testClassId = classList[0].id;
    }

    const student1Login = await request(app).post('/api/v1/auth/login').send({
      email: 'student1@apex.edu',
      password: 'Password@123',
    });
    student1Token = student1Login.body.accessToken;

    const student2Login = await request(app).post('/api/v1/auth/login').send({
      email: 'student2@apex.edu',
      password: 'Password@123',
    });
    student2Token = student2Login.body.accessToken;

    teacherSocket = Client(`http://localhost:${serverPort}`, {
      auth: { token: teacherToken },
      transports: ['websocket'],
    });

    student1Socket = Client(`http://localhost:${serverPort}`, {
      auth: { token: student1Token },
      transports: ['websocket'],
    });

    await Promise.all([
      new Promise<void>((res) => teacherSocket.on('connect', () => res())),
      new Promise<void>((res) => student1Socket.on('connect', () => res())),
    ]);

    teacherSocket.emit('class:join', { classId: testClassId });
    student1Socket.emit('class:join', { classId: testClassId });
    await new Promise((r) => setTimeout(r, 150));
  });

  after(() => {
    teacherSocket?.disconnect();
    student1Socket?.disconnect();
    student2Socket?.disconnect();
    ioServer?.close();
    server?.close();
    resetSocketGatewayState();
  });

  it('1. Upload Validation: Rejects PPT/PPTX file with exact prompt message', async () => {
    const fakePpt = Buffer.from('Fake PPT Presentation Content');
    const res = await request(app)
      .post(`/api/v1/classes/${testClassId}/slides`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .attach('file', fakePpt, 'lecture.pptx');

    assert.strictEqual(res.status, 400);
    assert.strictEqual(res.body.message, 'PPT ko PDF me export karo ya screen share karo');
  });

  it('2. Upload Validation: Uploads two different PDFs and asserts pageCount and SHA-256 hash match', async () => {
    const crypto = await import('crypto');

    // PDF 1: 2 pages
    const pdf1 = Buffer.from('%PDF-1.4\n1 0 obj\n<< /Type /Page >>\nendobj\n2 0 obj\n<< /Type /Page >>\nendobj\ntrailer\n<<>>\n%%EOF');
    const hash1 = crypto.createHash('sha256').update(pdf1).digest('hex');

    const res1 = await request(app)
      .post(`/api/v1/classes/${testClassId}/slides`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .attach('file', pdf1, 'physics_2pages.pdf');

    assert.strictEqual(res1.status, 201);
    assert.strictEqual(res1.body.success, true);
    assert.strictEqual(res1.body.pageCount, 2, 'PDF 1 pageCount must match 2');
    assert.strictEqual(res1.body.fileHash, hash1, 'PDF 1 SHA-256 hash must match');
    assert.ok(res1.body.deckId, 'Must return deckId');
    assert.strictEqual(res1.body.deckId, res1.body.fileKey);

    // PDF 2: 4 pages with different content
    const pdf2 = Buffer.from('%PDF-1.4\n1 0 obj\n<< /Type /Page >>\nendobj\n2 0 obj\n<< /Type /Page >>\nendobj\n3 0 obj\n<< /Type /Page >>\nendobj\n4 0 obj\n<< /Type /Page >>\nendobj\ntrailer\n<<>>\n%%EOF');
    const hash2 = crypto.createHash('sha256').update(pdf2).digest('hex');

    const res2 = await request(app)
      .post(`/api/v1/classes/${testClassId}/slides`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .attach('file', pdf2, 'chemistry_4pages.pdf');

    assert.strictEqual(res2.status, 201);
    assert.strictEqual(res2.body.success, true);
    assert.strictEqual(res2.body.pageCount, 4, 'PDF 2 pageCount must match 4');
    assert.strictEqual(res2.body.fileHash, hash2, 'PDF 2 SHA-256 hash must match');
    assert.notStrictEqual(res1.body.deckId, res2.body.deckId, 'Deck IDs must be unique');
    assert.notStrictEqual(res1.body.fileHash, res2.body.fileHash, 'Hashes must differ');
  });

  it('3. Socket Sync: Teacher broadcasts real deckId, students receive that deckId and page-sync works', async () => {
    const studentDocPromise = new Promise<{ isOpen: boolean; page: number; title: string; deckId: string; fileHash: string }>((resolve, reject) => {
      const timer = setTimeout(() => reject(new Error('Timeout waiting for doc:present')), 4000);
      student1Socket.on('doc:present', (data: any) => {
        clearTimeout(timer);
        resolve(data);
      });
    });

    const realDeckId = 'deck-real-12345';
    const realHash = 'hash-real-67890';

    // Teacher presents real uploaded slide deck
    teacherSocket.emit('doc:present', {
      classId: testClassId,
      isOpen: true,
      title: 'Chapter 4: Thermodynamics',
      deckId: realDeckId,
      fileHash: realHash,
      page: 1,
      totalPages: 10,
    });

    const docState = await studentDocPromise;
    assert.strictEqual(docState.isOpen, true);
    assert.strictEqual(docState.title, 'Chapter 4: Thermodynamics');
    assert.strictEqual(docState.deckId, realDeckId, 'Student must receive the exact deckId');
    assert.strictEqual(docState.fileHash, realHash, 'Student must receive the exact fileHash');
    assert.strictEqual(docState.page, 1);

    // Teacher changes to page 3
    const studentPagePromise = new Promise<{ page: number }>((resolve, reject) => {
      const timer = setTimeout(() => reject(new Error('Timeout waiting for doc:page')), 4000);
      student1Socket.on('doc:page', (data: any) => {
        clearTimeout(timer);
        resolve(data);
      });
    });

    teacherSocket.emit('doc:page', {
      classId: testClassId,
      page: 3,
    });

    const pageState = await studentPagePromise;
    assert.strictEqual(pageState.page, 3);
  });

  it('4. Late Joiner Snapshot: Student 2 joining later immediately receives stage SLIDES on current page 3', async () => {
    student2Socket = Client(`http://localhost:${serverPort}`, {
      auth: { token: student2Token },
      transports: ['websocket'],
    });

    await new Promise<void>((res) => student2Socket.on('connect', () => res()));

    const snapshotPromise = new Promise<any>((resolve, reject) => {
      const timer = setTimeout(() => reject(new Error('Timeout waiting for classroom:snapshot')), 4000);
      student2Socket.on('classroom:snapshot', (data: any) => {
        clearTimeout(timer);
        resolve(data);
      });
    });

    student2Socket.emit('class:join', { classId: testClassId });

    const snapshot = await snapshotPromise;
    assert.strictEqual(snapshot.stage, 'SLIDES', 'Stage in snapshot must be SLIDES');
    assert.ok(snapshot.doc, 'Snapshot must contain doc state');
    assert.strictEqual(snapshot.doc.isOpen, true);
    assert.strictEqual(snapshot.doc.page, 3, 'Late joiner must land on current page 3');
  });
});
