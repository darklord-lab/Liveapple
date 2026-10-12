import { prisma } from '../utils/prisma.js';
import { generateRandomToken, hashToken, hashPassword } from '../utils/hash.js';
import { AppError } from '../errors/AppError.js';
import { env } from '../config/env.js';
import { logAudit } from './audit.service.js';

export interface AddStudentInput {
  name: string;
  email: string;
  phone?: string;
}

export interface BulkEnrollRowResult {
  rowNumber: number;
  name: string;
  email: string;
  phone?: string;
  status: 'ENROLLED' | 'ALREADY_ENROLLED' | 'INVITED' | 'FAILED';
  reason?: string;
  inviteCode?: string;
  inviteUrl?: string;
}

export interface BulkEnrollSummary {
  total: number;
  enrolled: number;
  alreadyEnrolled: number;
  invited: number;
  failed: number;
  rows: BulkEnrollRowResult[];
}

export class EnrollmentService {
  /**
   * Student enrolls into a batch using the batch join code
   */
  static async enrollWithCode(
    instituteId: string,
    studentId: string,
    joinCode: string
  ) {
    if (!joinCode || joinCode.trim().length === 0) {
      throw new AppError('BAD_REQUEST', 'Join code is required', 400);
    }

    const code = joinCode.trim().toUpperCase();

    // Verify batch exists in student's institute
    const batch = await prisma.batch.findFirst({
      where: {
        instituteId,
        joinCode: code,
      },
      include: {
        teacher: { select: { id: true, name: true, email: true } },
      },
    });

    if (!batch) {
      throw new AppError('NOT_FOUND', 'Invalid join code or batch not found', 404);
    }

    // Check if already enrolled
    const existingEnrollment = await prisma.enrollment.findUnique({
      where: {
        instituteId_batchId_studentId: {
          instituteId,
          batchId: batch.id,
          studentId,
        },
      },
    });

    if (existingEnrollment) {
      if (existingEnrollment.status === 'ACTIVE') {
        throw new AppError('CONFLICT', 'You are already actively enrolled in this batch', 409);
      }
      // If was REMOVED or PENDING, reactivate
      const updated = await prisma.enrollment.update({
        where: { id: existingEnrollment.id },
        data: { status: 'ACTIVE' },
      });

      await logAudit({
        instituteId,
        actorId: studentId,
        action: 'STUDENT_RE_ENROLLED',
        entity: `Enrollment:${updated.id}`,
        meta: { batchId: batch.id, batchName: batch.name },
      });

      return {
        enrollment: updated,
        batch,
      };
    }

    // Create fresh active enrollment
    const enrollment = await prisma.enrollment.create({
      data: {
        instituteId,
        batchId: batch.id,
        studentId,
        status: 'ACTIVE',
      },
    });

    await logAudit({
      instituteId,
      actorId: studentId,
      action: 'STUDENT_ENROLLED_VIA_CODE',
      entity: `Enrollment:${enrollment.id}`,
      meta: { batchId: batch.id, batchName: batch.name, joinCode: code },
    });

    return {
      enrollment,
      batch,
    };
  }

  /**
   * List students enrolled in a batch
   */
  static async listEnrollments(
    instituteId: string,
    user: { id: string; role: string },
    batchId: string,
    statusFilter?: string
  ) {
    const batch = await prisma.batch.findFirst({
      where: { id: batchId, instituteId },
    });

    if (!batch) {
      throw new AppError('NOT_FOUND', 'Batch not found', 404);
    }

    if (user.role === 'TEACHER' && batch.teacherId !== user.id) {
      throw new AppError('FORBIDDEN', 'You do not own this batch', 403);
    }

    const whereClause: any = {
      instituteId,
      batchId,
    };

    if (statusFilter && ['ACTIVE', 'PENDING', 'REMOVED'].includes(statusFilter.toUpperCase())) {
      whereClause.status = statusFilter.toUpperCase();
    }

    const enrollments = await prisma.enrollment.findMany({
      where: whereClause,
      orderBy: { enrolledAt: 'desc' },
      include: {
        student: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
            status: true,
            createdAt: true,
          },
        },
      },
    });

    return enrollments;
  }

  /**
   * Directly add a single student to a batch (and onboard if new)
   */
  static async addStudentDirect(
    instituteId: string,
    actorId: string,
    batchId: string,
    input: AddStudentInput
  ) {
    const batch = await prisma.batch.findFirst({
      where: { id: batchId, instituteId },
    });

    if (!batch) {
      throw new AppError('NOT_FOUND', 'Batch not found', 404);
    }

    const email = input.email.trim().toLowerCase();
    const name = input.name.trim();

    if (!email || !name) {
      throw new AppError('BAD_REQUEST', 'Student name and valid email are required', 400);
    }

    // Find or create student user in this institute
    let student = await prisma.user.findUnique({
      where: {
        instituteId_email: {
          instituteId,
          email,
        },
      },
    });

    let inviteCode: string | undefined;
    let inviteUrl: string | undefined;

    if (!student) {
      // Create student with INVITED status
      const dummyPassword = await hashPassword(generateRandomToken(16));
      student = await prisma.user.create({
        data: {
          instituteId,
          role: 'STUDENT',
          name,
          email,
          phone: input.phone?.trim() || null,
          passwordHash: dummyPassword,
          status: 'INVITED',
        },
      });

      // Generate 48h invite
      inviteCode = generateRandomToken(16);
      const codeHash = hashToken(inviteCode);
      const expiresAt = new Date(Date.now() + 48 * 60 * 60 * 1000);

      await prisma.invite.create({
        data: {
          instituteId,
          email,
          phone: input.phone?.trim() || null,
          role: 'STUDENT',
          codeHash,
          expiresAt,
        },
      });

      inviteUrl = `${env.APP_URL}/accept-invite?code=${inviteCode}`;
    }

    // Upsert enrollment
    const existingEnrollment = await prisma.enrollment.findUnique({
      where: {
        instituteId_batchId_studentId: {
          instituteId,
          batchId,
          studentId: student.id,
        },
      },
    });

    let enrollment;
    if (existingEnrollment) {
      if (existingEnrollment.status === 'ACTIVE') {
        throw new AppError('CONFLICT', 'Student is already actively enrolled in this batch', 409);
      }
      enrollment = await prisma.enrollment.update({
        where: { id: existingEnrollment.id },
        data: { status: 'ACTIVE' },
      });
    } else {
      enrollment = await prisma.enrollment.create({
        data: {
          instituteId,
          batchId,
          studentId: student.id,
          status: 'ACTIVE',
        },
      });
    }

    await logAudit({
      instituteId,
      actorId,
      action: 'STUDENT_ADDED_TO_BATCH',
      entity: `Enrollment:${enrollment.id}`,
      meta: { batchId, studentId: student.id, email },
    });

    return {
      enrollment,
      student: {
        id: student.id,
        name: student.name,
        email: student.email,
        phone: student.phone,
        status: student.status,
      },
      inviteCode,
      inviteUrl,
    };
  }

  /**
   * Bulk enroll students from CSV text or parsed rows
   */
  static async bulkEnrollStudents(
    instituteId: string,
    actorId: string,
    batchId: string,
    csvContentOrRows: string | AddStudentInput[]
  ): Promise<BulkEnrollSummary> {
    const batch = await prisma.batch.findFirst({
      where: { id: batchId, instituteId },
    });

    if (!batch) {
      throw new AppError('NOT_FOUND', 'Batch not found', 404);
    }

    let rows: AddStudentInput[] = [];

    if (typeof csvContentOrRows === 'string') {
      const lines = csvContentOrRows
        .split('\n')
        .map((l) => l.trim())
        .filter((l) => l.length > 0);

      for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        if (i === 0 && line.toLowerCase().includes('email')) {
          continue; // Skip header
        }
        const parts = line.split(',').map((p) => p.trim().replace(/^["']|["']$/g, ''));
        if (parts.length >= 2) {
          rows.push({
            name: parts[0],
            email: parts[1],
            phone: parts[2] || undefined,
          });
        }
      }
    } else if (Array.isArray(csvContentOrRows)) {
      rows = csvContentOrRows;
    }

    if (rows.length === 0) {
      throw new AppError('BAD_REQUEST', 'No valid student records provided', 400);
    }

    if (rows.length > 500) {
      throw new AppError('BAD_REQUEST', 'Maximum 500 students can be enrolled in one batch', 400);
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    const results: BulkEnrollRowResult[] = [];
    let enrolledCount = 0;
    let alreadyEnrolledCount = 0;
    let invitedCount = 0;
    let failedCount = 0;

    for (let index = 0; index < rows.length; index++) {
      const row = rows[index];
      const rowNum = index + 1;
      const email = row.email?.trim().toLowerCase();
      const name = row.name?.trim();

      if (!name || name.length < 2) {
        results.push({
          rowNumber: rowNum,
          name: name || 'N/A',
          email: email || 'N/A',
          phone: row.phone,
          status: 'FAILED',
          reason: 'Invalid or missing name',
        });
        failedCount++;
        continue;
      }

      if (!email || !emailRegex.test(email)) {
        results.push({
          rowNumber: rowNum,
          name,
          email: email || 'N/A',
          phone: row.phone,
          status: 'FAILED',
          reason: 'Invalid email address format',
        });
        failedCount++;
        continue;
      }

      try {
        let student = await prisma.user.findUnique({
          where: {
            instituteId_email: { instituteId, email },
          },
        });

        let inviteCode: string | undefined;
        let inviteUrl: string | undefined;

        if (!student) {
          // Create student
          const dummyPassword = await hashPassword(generateRandomToken(16));
          student = await prisma.user.create({
            data: {
              instituteId,
              role: 'STUDENT',
              name,
              email,
              phone: row.phone?.trim() || null,
              passwordHash: dummyPassword,
              status: 'INVITED',
            },
          });

          // Generate invite
          inviteCode = generateRandomToken(16);
          const codeHash = hashToken(inviteCode);
          const expiresAt = new Date(Date.now() + 48 * 60 * 60 * 1000);

          await prisma.invite.create({
            data: {
              instituteId,
              email,
              phone: row.phone?.trim() || null,
              role: 'STUDENT',
              codeHash,
              expiresAt,
            },
          });

          inviteUrl = `${env.APP_URL}/accept-invite?code=${inviteCode}`;
          invitedCount++;
        }

        const existingEnrollment = await prisma.enrollment.findUnique({
          where: {
            instituteId_batchId_studentId: {
              instituteId,
              batchId,
              studentId: student.id,
            },
          },
        });

        if (existingEnrollment && existingEnrollment.status === 'ACTIVE') {
          results.push({
            rowNumber: rowNum,
            name,
            email,
            phone: row.phone,
            status: 'ALREADY_ENROLLED',
            reason: 'Student is already active in this batch',
          });
          alreadyEnrolledCount++;
        } else {
          if (existingEnrollment) {
            await prisma.enrollment.update({
              where: { id: existingEnrollment.id },
              data: { status: 'ACTIVE' },
            });
          } else {
            await prisma.enrollment.create({
              data: {
                instituteId,
                batchId,
                studentId: student.id,
                status: 'ACTIVE',
              },
            });
          }

          results.push({
            rowNumber: rowNum,
            name,
            email,
            phone: row.phone,
            status: inviteCode ? 'INVITED' : 'ENROLLED',
            inviteCode,
            inviteUrl,
          });
          enrolledCount++;
        }
      } catch (err: any) {
        results.push({
          rowNumber: rowNum,
          name,
          email,
          phone: row.phone,
          status: 'FAILED',
          reason: err.message || 'Database error processing student',
        });
        failedCount++;
      }
    }

    await logAudit({
      instituteId,
      actorId,
      action: 'BATCH_BULK_ENROLLMENT',
      entity: `Batch:${batchId}`,
      meta: { total: rows.length, enrolledCount, alreadyEnrolledCount, invitedCount, failedCount },
    });

    return {
      total: rows.length,
      enrolled: enrolledCount,
      alreadyEnrolled: alreadyEnrolledCount,
      invited: invitedCount,
      failed: failedCount,
      rows: results,
    };
  }

  /**
   * Update enrollment status (e.g. REMOVED or ACTIVE)
   */
  static async updateEnrollmentStatus(
    instituteId: string,
    user: { id: string; role: string },
    batchId: string,
    enrollmentId: string,
    status: 'ACTIVE' | 'REMOVED' | 'PENDING'
  ) {
    const batch = await prisma.batch.findFirst({
      where: { id: batchId, instituteId },
    });

    if (!batch) {
      throw new AppError('NOT_FOUND', 'Batch not found', 404);
    }

    if (user.role === 'TEACHER' && batch.teacherId !== user.id) {
      throw new AppError('FORBIDDEN', 'You do not own this batch', 403);
    }

    const enrollment = await prisma.enrollment.findFirst({
      where: { id: enrollmentId, instituteId, batchId },
    });

    if (!enrollment) {
      throw new AppError('NOT_FOUND', 'Enrollment record not found', 404);
    }

    const updated = await prisma.enrollment.update({
      where: { id: enrollmentId },
      data: { status },
      include: {
        student: { select: { id: true, name: true, email: true } },
      },
    });

    await logAudit({
      instituteId,
      actorId: user.id,
      action: 'ENROLLMENT_STATUS_UPDATED',
      entity: `Enrollment:${enrollmentId}`,
      meta: { batchId, newStatus: status },
    });

    return updated;
  }
}
