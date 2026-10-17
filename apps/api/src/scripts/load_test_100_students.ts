/**
 * Classora 2.0 — Load & Scalability Benchmark Test
 * Scenario: 100 Concurrent Students Joining 1 Live Classroom Session
 * Validates: Token signing throughput, DB concurrency, attendance record throughput, latency percentiles
 */

import { PrismaClient } from '@prisma/client';
import { AccessToken } from 'livekit-server-sdk';
import argon2 from 'argon2';

const prisma = new PrismaClient();

interface BenchmarkMetric {
  name: string;
  totalOperations: number;
  durationMs: number;
  opsPerSec: number;
  p50Ms: number;
  p95Ms: number;
  p99Ms: number;
}

function calculatePercentiles(latencies: number[]): { p50: number; p95: number; p99: number } {
  const sorted = [...latencies].sort((a, b) => a - b);
  const p50 = sorted[Math.floor(sorted.length * 0.5)] || 0;
  const p95 = sorted[Math.floor(sorted.length * 0.95)] || 0;
  const p99 = sorted[Math.floor(sorted.length * 0.99)] || 0;
  return { p50: Number(p50.toFixed(2)), p95: Number(p95.toFixed(2)), p99: Number(p99.toFixed(2)) };
}

async function runLoadBenchmark() {
  console.log('===============================================================');
  console.log(' CLASSORA 2.0 — HIGH-CONCURRENCY LOAD TEST (100 STUDENTS / CLASS)');
  console.log('===============================================================\n');

  const benchmarkSlug = `loadtest-${Date.now()}`;
  const STUDENT_COUNT = 100;

  // 1. Setup Benchmark Environment
  console.log(`[1/5] Setting up isolated benchmark institute (${benchmarkSlug})...`);
  const institute = await prisma.institute.create({
    data: {
      name: 'Load Benchmark Academy',
      slug: benchmarkSlug,
      plan: 'ENTERPRISE',
    },
  });

  const pwdHash = await argon2.hash('Password123!', { type: argon2.argon2id });

  const teacher = await prisma.user.create({
    data: {
      instituteId: institute.id,
      name: 'Prof. Load Tester',
      email: `prof-${Date.now()}@loadtest.classora.com`,
      role: 'TEACHER',
      passwordHash: pwdHash,
    },
  });

  const batch = await prisma.batch.create({
    data: {
      instituteId: institute.id,
      teacherId: teacher.id,
      name: 'Quantum Scale 100',
      subject: 'Distributed Systems',
      joinCode: 'LOAD10',
    },
  });

  const liveClass = await prisma.liveClass.create({
    data: {
      instituteId: institute.id,
      batchId: batch.id,
      teacherId: teacher.id,
      title: 'Mega Concurrency Live Lecture',
      scheduledAt: new Date(),
      status: 'LIVE',
      livekitRoom: `class_${institute.id}_${batch.id}_${Date.now()}`,
    },
  });

  console.log(`✓ Setup complete: LiveClass ID = ${liveClass.id}, Room = ${liveClass.livekitRoom}\n`);

  // 2. Concurrently Create 100 Students & Enrollments
  console.log(`[2/5] Benchmarking concurrent DB insertion of ${STUDENT_COUNT} students + enrollments...`);
  const studentIds: string[] = [];
  const enrollLatencies: number[] = [];
  const startEnrollTime = Date.now();

  await Promise.all(
    Array.from({ length: STUDENT_COUNT }).map(async (_, idx) => {
      const opStart = performance.now();
      const student = await prisma.user.create({
        data: {
          instituteId: institute.id,
          name: `Student Benchmark #${idx + 1}`,
          email: `student_${idx + 1}_${Date.now()}@loadtest.classora.com`,
          role: 'STUDENT',
          passwordHash: pwdHash,
        },
      });

      await prisma.enrollment.create({
        data: {
          instituteId: institute.id,
          batchId: batch.id,
          studentId: student.id,
          status: 'ACTIVE',
        },
      });
      const opEnd = performance.now();
      enrollLatencies.push(opEnd - opStart);
      studentIds.push(student.id);
    })
  );

  const totalEnrollDuration = Date.now() - startEnrollTime;
  const enrollPct = calculatePercentiles(enrollLatencies);

  console.log(`✓ Enrolled 100 students in ${totalEnrollDuration}ms (${(STUDENT_COUNT / (totalEnrollDuration / 1000)).toFixed(1)} ops/sec)`);
  console.log(`  Latency -> P50: ${enrollPct.p50}ms | P95: ${enrollPct.p95}ms | P99: ${enrollPct.p99}ms\n`);

  // 3. Benchmark Concurrently Signing 100 LiveKit JWT Subscriber Tokens
  console.log(`[3/5] Benchmarking concurrent generation of ${STUDENT_COUNT} LiveKit signed tokens...`);
  const apiKey = process.env.LIVEKIT_API_KEY || 'devkey';
  const apiSecret = process.env.LIVEKIT_API_SECRET || 'secret_which_is_at_least_32_characters_long_for_security';

  const tokenLatencies: number[] = [];
  const startTokenTime = Date.now();

  const generatedTokens = await Promise.all(
    studentIds.map(async (studentId, idx) => {
      const opStart = performance.now();
      const at = new AccessToken(apiKey, apiSecret, {
        identity: studentId,
        name: `Student Benchmark #${idx + 1}`,
        ttl: '2h',
        metadata: JSON.stringify({
          role: 'STUDENT',
          instituteId: institute.id,
        }),
      });

      at.addGrant({
        room: liveClass.livekitRoom,
        roomJoin: true,
        canPublish: false,
        canPublishData: true,
        canSubscribe: true,
      });

      const jwt = await at.toJwt();
      const opEnd = performance.now();
      tokenLatencies.push(opEnd - opStart);
      return jwt;
    })
  );

  const totalTokenDuration = Date.now() - startTokenTime;
  const tokenPct = calculatePercentiles(tokenLatencies);

  console.log(`✓ Generated 100 signed LiveKit JWTs in ${totalTokenDuration}ms (${(STUDENT_COUNT / (totalTokenDuration / 1000)).toFixed(1)} tokens/sec)`);
  console.log(`  Latency -> P50: ${tokenPct.p50}ms | P95: ${tokenPct.p95}ms | P99: ${tokenPct.p99}ms\n`);

  // 4. Benchmark Concurrent Attendance Join Recording
  console.log(`[4/5] Benchmarking concurrent attendance log creation for ${STUDENT_COUNT} joins...`);
  const attendanceLatencies: number[] = [];
  const startAttendanceTime = Date.now();

  await Promise.all(
    studentIds.map(async (studentId) => {
      const opStart = performance.now();
      await prisma.attendance.create({
        data: {
          instituteId: institute.id,
          liveClassId: liveClass.id,
          studentId: studentId,
          joinedAt: new Date(),
        },
      });
      const opEnd = performance.now();
      attendanceLatencies.push(opEnd - opStart);
    })
  );

  const totalAttendanceDuration = Date.now() - startAttendanceTime;
  const attendancePct = calculatePercentiles(attendanceLatencies);

  console.log(`✓ Logged 100 student attendances in ${totalAttendanceDuration}ms (${(STUDENT_COUNT / (totalAttendanceDuration / 1000)).toFixed(1)} ops/sec)`);
  console.log(`  Latency -> P50: ${attendancePct.p50}ms | P95: ${attendancePct.p95}ms | P99: ${attendancePct.p99}ms\n`);

  // 5. Cleanup Test Artifacts
  console.log(`[5/5] Cleaning up benchmark institute...`);
  await prisma.attendance.deleteMany({ where: { liveClassId: liveClass.id } });
  await prisma.liveClass.deleteMany({ where: { instituteId: institute.id } });
  await prisma.enrollment.deleteMany({ where: { instituteId: institute.id } });
  await prisma.batch.deleteMany({ where: { instituteId: institute.id } });
  await prisma.user.deleteMany({ where: { instituteId: institute.id } });
  await prisma.institute.delete({ where: { id: institute.id } });
  console.log(`✓ Cleanup complete.\n`);

  // Final Summary Table
  console.log('===============================================================');
  console.log('                    LOAD TEST RESULTS SUMMARY                  ');
  console.log('===============================================================');
  console.table([
    {
      Metric: 'Student Onboard & Enroll (100 concurrent)',
      'Total (ms)': totalEnrollDuration,
      'Throughput (ops/s)': Number((STUDENT_COUNT / (totalEnrollDuration / 1000)).toFixed(1)),
      'P50 (ms)': enrollPct.p50,
      'P95 (ms)': enrollPct.p95,
      'P99 (ms)': enrollPct.p99,
    },
    {
      Metric: 'LiveKit JWT Token Signing (100 concurrent)',
      'Total (ms)': totalTokenDuration,
      'Throughput (ops/s)': Number((STUDENT_COUNT / (totalTokenDuration / 1000)).toFixed(1)),
      'P50 (ms)': tokenPct.p50,
      'P95 (ms)': tokenPct.p95,
      'P99 (ms)': tokenPct.p99,
    },
    {
      Metric: 'Live Attendance Ingestion (100 concurrent)',
      'Total (ms)': totalAttendanceDuration,
      'Throughput (ops/s)': Number((STUDENT_COUNT / (totalAttendanceDuration / 1000)).toFixed(1)),
      'P50 (ms)': attendancePct.p50,
      'P95 (ms)': attendancePct.p95,
      'P99 (ms)': attendancePct.p99,
    },
  ]);
  console.log('===============================================================\n');
}

runLoadBenchmark()
  .catch((err) => {
    console.error('Benchmark failed:', err);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
