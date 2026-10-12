import { prisma } from '../utils/prisma.js';
import { AppError } from '../errors/AppError.js';
import { logAudit } from './audit.service.js';

export interface SaveRecordingInput {
  liveClassId: string;
  title?: string;
  videoUrl: string;
  durationSec?: number;
  fileSizeMb?: number;
}

export class RecordingService {
  /**
   * Save or register a completed class recording
   */
  static async saveRecording(
    instituteId: string,
    user: { id: string; role: string },
    input: SaveRecordingInput
  ) {
    const { liveClassId, videoUrl, durationSec = 0, fileSizeMb = 0.0 } = input;

    if (!videoUrl || !videoUrl.startsWith('http')) {
      throw new AppError('BAD_REQUEST', 'Valid recording video URL is required', 400);
    }

    let targetLiveClassId = liveClassId;
    let liveClass = await prisma.liveClass.findFirst({
      where: { id: targetLiveClassId, instituteId },
      include: { batch: true },
    });

    if (!liveClass) {
      const batch = await prisma.batch.findFirst({
        where: { id: targetLiveClassId, instituteId },
      });
      if (batch) {
        liveClass = await prisma.liveClass.create({
          data: {
            instituteId,
            batchId: batch.id,
            teacherId: user.id,
            title: input.title || `${batch.name} - Lecture Recording`,
            scheduledAt: new Date(),
            status: 'COMPLETED',
            livekitRoom: `rec-${batch.id}-${Date.now()}`,
          },
          include: { batch: true },
        });
        targetLiveClassId = liveClass.id;
      }
    }

    if (!liveClass) {
      throw new AppError('NOT_FOUND', 'Live class or batch not found in this institute', 404);
    }

    if (user.role === 'TEACHER' && liveClass.teacherId !== user.id) {
      throw new AppError('FORBIDDEN', 'Only the assigned teacher or admin can save recording', 403);
    }

    const title = input.title || `${liveClass.title} (Recording)`;

    const recording = await prisma.recording.create({
      data: {
        instituteId,
        liveClassId: targetLiveClassId,
        title,
        videoUrl,
        durationSec,
        fileSizeMb,
      },
      include: {
        liveClass: {
          select: { id: true, title: true, batchId: true, scheduledAt: true },
        },
      },
    });

    // Update live class recordingUrl
    await prisma.liveClass.update({
      where: { id: targetLiveClassId },
      data: { recordingUrl: videoUrl, status: 'ENDED' },
    });

    await logAudit({
      instituteId,
      actorId: user.id,
      action: 'RECORDING_SAVED',
      entity: `Recording:${recording.id}`,
      meta: { liveClassId, title, durationSec },
    });

    return recording;
  }

  /**
   * List recordings accessible to user
   */
  static async listRecordings(
    instituteId: string,
    user: { id: string; role: string },
    query: { batchId?: string; page?: number; limit?: number } = {}
  ) {
    const page = Math.max(1, query.page || 1);
    const limit = Math.min(100, Math.max(1, query.limit || 20));
    const skip = (page - 1) * limit;

    let whereClause: any = { instituteId };

    if (query.batchId) {
      whereClause.liveClass = { batchId: query.batchId };
    }

    if (user.role === 'TEACHER') {
      whereClause.liveClass = {
        ...(whereClause.liveClass || {}),
        teacherId: user.id,
      };
    } else if (user.role === 'STUDENT') {
      // Find batches where student is actively enrolled
      const activeEnrollments = await prisma.enrollment.findMany({
        where: { instituteId, studentId: user.id, status: 'ACTIVE' },
        select: { batchId: true },
      });
      const batchIds = activeEnrollments.map((e) => e.batchId);

      whereClause.liveClass = {
        ...(whereClause.liveClass || {}),
        batchId: { in: batchIds },
      };
    }

    const [total, recordings] = await Promise.all([
      prisma.recording.count({ where: whereClause }),
      prisma.recording.findMany({
        where: whereClause,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
        include: {
          liveClass: {
            select: {
              id: true,
              title: true,
              scheduledAt: true,
              batch: { select: { id: true, name: true, subject: true } },
              teacher: { select: { id: true, name: true } },
            },
          },
        },
      }),
    ]);

    return {
      recordings,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  /**
   * Get single recording details
   */
  static async getRecordingById(
    instituteId: string,
    user: { id: string; role: string },
    recordingId: string
  ) {
    const recording = await prisma.recording.findFirst({
      where: { id: recordingId, instituteId },
      include: {
        liveClass: {
          include: {
            batch: {
              include: {
                enrollments: {
                  where: { status: 'ACTIVE' },
                },
              },
            },
            teacher: { select: { id: true, name: true } },
          },
        },
      },
    });

    if (!recording) {
      throw new AppError('NOT_FOUND', 'Recording not found', 404);
    }

    if (user.role === 'STUDENT') {
      const isEnrolled = recording.liveClass.batch.enrollments.some((e) => e.studentId === user.id);
      if (!isEnrolled) {
        throw new AppError('FORBIDDEN', 'You do not have access to this recording', 403);
      }
    }

    return recording;
  }
}
