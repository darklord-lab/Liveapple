import { prisma } from '../utils/prisma.js';
import { AppError } from '../errors/AppError.js';
import { logAudit } from './audit.service.js';
import { LiveClassService } from './liveclass.service.js';

export interface CreateSlotInput {
  batchId: string;
  dayOfWeek: number; // 0 (Sunday) to 6 (Saturday)
  startMin: number; // Minutes from midnight (e.g. 540 = 09:00 AM)
  endMin: number; // Minutes from midnight (e.g. 600 = 10:00 AM)
  recurring?: boolean;
}

export interface ListSlotsQuery {
  batchId?: string;
  teacherId?: string;
  dayOfWeek?: number;
}

export class TimetableService {
  /**
   * Helper to format minutes from midnight into HH:MM AM/PM
   */
  static formatMinutes(minutes: number): string {
    const hours = Math.floor(minutes / 60);
    const mins = minutes % 60;
    const ampm = hours >= 12 ? 'PM' : 'AM';
    const formattedHours = hours % 12 === 0 ? 12 : hours % 12;
    const formattedMins = mins < 10 ? `0${mins}` : `${mins}`;
    return `${formattedHours}:${formattedMins} ${ampm}`;
  }

  /**
   * Create a timetable slot with conflict check
   */
  static async createSlot(
    instituteId: string,
    user: { id: string; role: string },
    input: CreateSlotInput
  ) {
    const { batchId, dayOfWeek, startMin, endMin } = input;
    const recurring = input.recurring ?? true;

    // 1. Validation
    if (typeof dayOfWeek !== 'number' || dayOfWeek < 0 || dayOfWeek > 6) {
      throw new AppError('BAD_REQUEST', 'Day of week must be an integer between 0 (Sun) and 6 (Sat)', 400);
    }

    if (typeof startMin !== 'number' || typeof endMin !== 'number' || startMin < 0 || endMin > 1440 || startMin >= endMin) {
      throw new AppError('BAD_REQUEST', 'Invalid time range. startMin must be before endMin and within 0-1440', 400);
    }

    if (endMin - startMin < 15) {
      throw new AppError('BAD_REQUEST', 'Slot duration must be at least 15 minutes', 400);
    }

    // 2. Fetch Batch and verify ownership
    const batch = await prisma.batch.findFirst({
      where: { id: batchId, instituteId },
      include: { teacher: { select: { id: true, name: true, email: true } } },
    });

    if (!batch) {
      throw new AppError('NOT_FOUND', 'Batch not found in this institute', 404);
    }

    if (user.role === 'TEACHER' && batch.teacherId !== user.id) {
      throw new AppError('FORBIDDEN', 'You do not have permission to modify this batch timetable', 403);
    }

    const teacherId = batch.teacherId;

    // 3. Check for Teacher Overlap Conflict (Teacher cannot teach two batches at the same time)
    const teacherConflictingSlots = await prisma.timetableSlot.findMany({
      where: {
        instituteId,
        teacherId,
        dayOfWeek,
        recurring: true,
      },
      include: {
        batch: { select: { id: true, name: true, subject: true } },
      },
    });

    for (const slot of teacherConflictingSlots) {
      const isOverlap = startMin < slot.endMin && endMin > slot.startMin;
      if (isOverlap) {
        const timeStr = `${this.formatMinutes(slot.startMin)} - ${this.formatMinutes(slot.endMin)}`;
        throw new AppError(
          'CONFLICT',
          `Teacher conflict: Teacher ${batch.teacher.name} is already scheduled for batch "${slot.batch.name}" (${slot.batch.subject}) on this day at ${timeStr}`,
          409,
          {
            conflictType: 'TEACHER_OVERLAP',
            conflictingSlot: {
              id: slot.id,
              batchName: slot.batch.name,
              subject: slot.batch.subject,
              timeRange: timeStr,
              startMin: slot.startMin,
              endMin: slot.endMin,
            },
          }
        );
      }
    }

    // 4. Check for Batch Overlap Conflict (Same batch cannot have two classes simultaneously)
    const batchConflictingSlots = await prisma.timetableSlot.findMany({
      where: {
        instituteId,
        batchId,
        dayOfWeek,
        recurring: true,
      },
      include: {
        teacher: { select: { id: true, name: true } },
      },
    });

    for (const slot of batchConflictingSlots) {
      const isOverlap = startMin < slot.endMin && endMin > slot.startMin;
      if (isOverlap) {
        const timeStr = `${this.formatMinutes(slot.startMin)} - ${this.formatMinutes(slot.endMin)}`;
        throw new AppError(
          'CONFLICT',
          `Batch conflict: Batch "${batch.name}" already has a class scheduled at ${timeStr}`,
          409,
          {
            conflictType: 'BATCH_OVERLAP',
            conflictingSlot: {
              id: slot.id,
              teacherName: slot.teacher.name,
              timeRange: timeStr,
              startMin: slot.startMin,
              endMin: slot.endMin,
            },
          }
        );
      }
    }

    // 5. Create Timetable Slot
    const newSlot = await prisma.timetableSlot.create({
      data: {
        instituteId,
        teacherId,
        batchId,
        dayOfWeek,
        startMin,
        endMin,
        recurring,
      },
      include: {
        batch: {
          select: {
            id: true,
            name: true,
            subject: true,
          },
        },
        teacher: {
          select: {
            id: true,
            name: true,
            email: true,
          },
        },
      },
    });

    await logAudit({
      instituteId,
      actorId: user.id,
      action: 'TIMETABLE_SLOT_CREATED',
      entity: `TimetableSlot:${newSlot.id}`,
      meta: { batchId, dayOfWeek, startMin, endMin },
    });

    // Auto-generate upcoming live classes immediately so dashboard and notifications sync in real-time
    try {
      await LiveClassService.generateUpcomingFromSlots(instituteId, teacherId, 7);
    } catch (err) {
      console.warn('[TimetableService] Non-fatal: auto-generating upcoming live classes failed:', err);
    }

    return newSlot;
  }

  /**
   * List timetable slots for the user based on role
   */
  static async listSlots(
    instituteId: string,
    user: { id: string; role: string },
    query: ListSlotsQuery = {}
  ) {
    const whereClause: any = { instituteId };

    if (typeof query.dayOfWeek === 'number') {
      whereClause.dayOfWeek = query.dayOfWeek;
    }

    if (query.batchId) {
      whereClause.batchId = query.batchId;
    }

    if (user.role === 'STUDENT') {
      const student = await prisma.user.findUnique({
        where: { id: user.id },
        select: { creatorTeacherId: true },
      });

      // Find batches where student is actively enrolled and belongs to their assigned teacher
      const activeEnrollments = await prisma.enrollment.findMany({
        where: {
          instituteId,
          studentId: user.id,
          status: 'ACTIVE',
          ...(student?.creatorTeacherId ? { batch: { teacherId: student.creatorTeacherId } } : {}),
        },
        select: { batchId: true },
      });

      const enrolledBatchIds = activeEnrollments.map((e) => e.batchId);
      if (query.batchId) {
        whereClause.batchId = enrolledBatchIds.includes(query.batchId) ? query.batchId : { in: [] };
      } else {
        whereClause.batchId = { in: enrolledBatchIds };
      }
      if (student?.creatorTeacherId) {
        whereClause.teacherId = student.creatorTeacherId;
      }
    } else if (user.role === 'TEACHER') {
      whereClause.teacherId = user.id;
    } else if (user.role === 'ADMIN' && query.teacherId) {
      whereClause.teacherId = query.teacherId;
    }

    const slots = await prisma.timetableSlot.findMany({
      where: whereClause,
      orderBy: [{ dayOfWeek: 'asc' }, { startMin: 'asc' }],
      include: {
        batch: {
          select: {
            id: true,
            name: true,
            subject: true,
            joinCode: true,
          },
        },
        teacher: {
          select: {
            id: true,
            name: true,
            email: true,
          },
        },
      },
    });

    return slots;
  }

  /**
   * Delete a timetable slot
   */
  static async deleteSlot(
    instituteId: string,
    user: { id: string; role: string },
    slotId: string
  ) {
    const slot = await prisma.timetableSlot.findFirst({
      where: { id: slotId, instituteId },
    });

    if (!slot) {
      throw new AppError('NOT_FOUND', 'Timetable slot not found', 404);
    }

    if (user.role === 'TEACHER' && slot.teacherId !== user.id) {
      throw new AppError('FORBIDDEN', 'You do not have permission to delete this slot', 403);
    }

    await prisma.timetableSlot.delete({
      where: { id: slotId },
    });

    await logAudit({
      instituteId,
      actorId: user.id,
      action: 'TIMETABLE_SLOT_DELETED',
      entity: `TimetableSlot:${slotId}`,
      meta: { batchId: slot.batchId, dayOfWeek: slot.dayOfWeek },
    });

    return { success: true };
  }
}
