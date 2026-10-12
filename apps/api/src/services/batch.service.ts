import { prisma } from '../utils/prisma.js';
import { generateJoinCode } from '../utils/hash.js';
import { AppError } from '../errors/AppError.js';
import { logAudit } from './audit.service.js';

export interface CreateBatchInput {
  name: string;
  subject: string;
  teacherId?: string; // Optional if created by teacher (inferred from token)
}

export interface UpdateBatchInput {
  name?: string;
  subject?: string;
}

export interface ListBatchesQuery {
  search?: string;
  teacherId?: string;
}

export class BatchService {
  /**
   * Create a new batch with unique join code
   */
  static async createBatch(
    instituteId: string,
    actor: { id: string; role: string },
    input: CreateBatchInput
  ) {
    if (!input.name || input.name.trim().length < 2) {
      throw new AppError('BAD_REQUEST', 'Batch name must be at least 2 characters', 400);
    }
    if (!input.subject || input.subject.trim().length < 2) {
      throw new AppError('BAD_REQUEST', 'Subject must be at least 2 characters', 400);
    }

    // Determine teacherId
    let targetTeacherId = actor.id;
    if (actor.role === 'ADMIN' && input.teacherId) {
      targetTeacherId = input.teacherId;
    }

    // Validate that the assigned teacher belongs to this institute
    const teacher = await prisma.user.findFirst({
      where: {
        id: targetTeacherId,
        instituteId,
        role: { in: ['TEACHER', 'ADMIN'] },
        status: 'ACTIVE',
      },
    });

    if (!teacher) {
      throw new AppError('NOT_FOUND', 'Active teacher not found in this institute', 404);
    }

    // Generate unique join code within institute
    let joinCode = '';
    let isUnique = false;
    for (let attempts = 0; attempts < 5; attempts++) {
      joinCode = generateJoinCode(6);
      const existing = await prisma.batch.findUnique({
        where: {
          instituteId_joinCode: {
            instituteId,
            joinCode,
          },
        },
      });
      if (!existing) {
        isUnique = true;
        break;
      }
    }

    if (!isUnique) {
      joinCode = `${generateJoinCode(4)}${Date.now().toString().slice(-2)}`;
    }

    const batch = await prisma.batch.create({
      data: {
        instituteId,
        teacherId: targetTeacherId,
        name: input.name.trim(),
        subject: input.subject.trim(),
        joinCode,
      },
      include: {
        teacher: {
          select: {
            id: true,
            name: true,
            email: true,
          },
        },
        _count: {
          select: {
            enrollments: true,
            timetableSlots: true,
            liveClasses: true,
          },
        },
      },
    });

    await logAudit({
      instituteId,
      actorId: actor.id,
      action: 'BATCH_CREATED',
      entity: `Batch:${batch.id}`,
      meta: { name: batch.name, subject: batch.subject, joinCode: batch.joinCode },
    });

    return batch;
  }

  /**
   * List batches scoped to user role and tenant
   */
  static async listBatches(
    instituteId: string,
    user: { id: string; role: string },
    query: ListBatchesQuery = {}
  ) {
    const whereClause: any = { instituteId };

    if (user.role === 'STUDENT') {
      const student = await prisma.user.findUnique({
        where: { id: user.id },
        select: { creatorTeacherId: true },
      });
      whereClause.enrollments = {
        some: {
          studentId: user.id,
          status: 'ACTIVE',
        },
      };
      if (student?.creatorTeacherId) {
        whereClause.teacherId = student.creatorTeacherId;
      }
    } else if (user.role === 'TEACHER') {
      // Teacher sees their own batches by default
      whereClause.teacherId = user.id;
    } else if (user.role === 'ADMIN' && query.teacherId) {
      whereClause.teacherId = query.teacherId;
    }

    if (query.search && query.search.trim().length > 0) {
      const search = query.search.trim();
      whereClause.OR = [
        { name: { contains: search } },
        { subject: { contains: search } },
        { joinCode: { contains: search } },
      ];
    }

    const batches = await prisma.batch.findMany({
      where: whereClause,
      orderBy: { createdAt: 'desc' },
      include: {
        teacher: {
          select: {
            id: true,
            name: true,
            email: true,
          },
        },
        _count: {
          select: {
            enrollments: {
              where: { status: 'ACTIVE' },
            },
            timetableSlots: true,
            liveClasses: true,
          },
        },
      },
    });

    return batches;
  }

  /**
   * Get single batch details with schedule and students
   */
  static async getBatchById(
    instituteId: string,
    user: { id: string; role: string },
    batchId: string
  ) {
    const batch = await prisma.batch.findFirst({
      where: {
        id: batchId,
        instituteId,
      },
      include: {
        teacher: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
          },
        },
        timetableSlots: {
          orderBy: [{ dayOfWeek: 'asc' }, { startMin: 'asc' }],
        },
        enrollments: {
          include: {
            student: {
              select: {
                id: true,
                name: true,
                email: true,
                phone: true,
                status: true,
              },
            },
          },
          orderBy: { enrolledAt: 'desc' },
        },
        liveClasses: {
          where: {
            status: { in: ['SCHEDULED', 'LIVE'] },
          },
          orderBy: { scheduledAt: 'asc' },
          take: 5,
        },
      },
    });

    if (!batch) {
      throw new AppError('NOT_FOUND', 'Batch not found', 404);
    }

    // Role verification
    if (user.role === 'STUDENT') {
      const student = await prisma.user.findUnique({
        where: { id: user.id },
        select: { creatorTeacherId: true },
      });
      if (student?.creatorTeacherId && batch.teacherId !== student.creatorTeacherId) {
        throw new AppError('FORBIDDEN', 'You do not have access to courses from other teachers', 403);
      }
      const isEnrolled = batch.enrollments.some(
        (e) => e.studentId === user.id && e.status === 'ACTIVE'
      );
      if (!isEnrolled) {
        throw new AppError('FORBIDDEN', 'You are not enrolled in this batch', 403);
      }
    } else if (user.role === 'TEACHER' && batch.teacherId !== user.id) {
      throw new AppError('FORBIDDEN', 'You do not own this batch', 403);
    }

    return batch;
  }

  /**
   * Update batch info
   */
  static async updateBatch(
    instituteId: string,
    user: { id: string; role: string },
    batchId: string,
    input: UpdateBatchInput
  ) {
    const existing = await prisma.batch.findFirst({
      where: { id: batchId, instituteId },
    });

    if (!existing) {
      throw new AppError('NOT_FOUND', 'Batch not found', 404);
    }

    if (user.role === 'TEACHER' && existing.teacherId !== user.id) {
      throw new AppError('FORBIDDEN', 'You do not own this batch', 403);
    }

    const updated = await prisma.batch.update({
      where: { id: batchId },
      data: {
        ...(input.name ? { name: input.name.trim() } : {}),
        ...(input.subject ? { subject: input.subject.trim() } : {}),
      },
      include: {
        teacher: { select: { id: true, name: true, email: true } },
      },
    });

    await logAudit({
      instituteId,
      actorId: user.id,
      action: 'BATCH_UPDATED',
      entity: `Batch:${batchId}`,
      meta: input,
    });

    return updated;
  }

  /**
   * Delete batch
   */
  static async deleteBatch(
    instituteId: string,
    user: { id: string; role: string },
    batchId: string
  ) {
    const existing = await prisma.batch.findFirst({
      where: { id: batchId, instituteId },
    });

    if (!existing) {
      throw new AppError('NOT_FOUND', 'Batch not found', 404);
    }

    if (user.role === 'TEACHER' && existing.teacherId !== user.id) {
      throw new AppError('FORBIDDEN', 'You do not own this batch', 403);
    }

    await prisma.batch.delete({
      where: { id: batchId },
    });

    await logAudit({
      instituteId,
      actorId: user.id,
      action: 'BATCH_DELETED',
      entity: `Batch:${batchId}`,
      meta: { name: existing.name },
    });

    return { success: true };
  }

  /**
   * Regenerate batch join code
   */
  static async regenerateJoinCode(
    instituteId: string,
    user: { id: string; role: string },
    batchId: string
  ) {
    const existing = await prisma.batch.findFirst({
      where: { id: batchId, instituteId },
    });

    if (!existing) {
      throw new AppError('NOT_FOUND', 'Batch not found', 404);
    }

    if (user.role === 'TEACHER' && existing.teacherId !== user.id) {
      throw new AppError('FORBIDDEN', 'You do not own this batch', 403);
    }

    const newCode = generateJoinCode(6);
    const updated = await prisma.batch.update({
      where: { id: batchId },
      data: { joinCode: newCode },
    });

    await logAudit({
      instituteId,
      actorId: user.id,
      action: 'BATCH_JOIN_CODE_REGENERATED',
      entity: `Batch:${batchId}`,
      meta: { newCode },
    });

    return updated;
  }
}
