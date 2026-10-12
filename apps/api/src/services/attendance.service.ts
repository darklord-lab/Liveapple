import { prisma } from '../utils/prisma.js';
import { AppError } from '../errors/AppError.js';

export class AttendanceService {
  /**
   * Record student joining live class
   */
  static async recordJoin(instituteId: string, studentId: string, classId: string) {
    const liveClass = await prisma.liveClass.findFirst({
      where: { id: classId, instituteId },
      include: {
        batch: {
          include: {
            enrollments: {
              where: { status: 'ACTIVE', studentId },
            },
          },
        },
      },
    });

    if (!liveClass) {
      throw new AppError('NOT_FOUND', 'Live class not found', 404);
    }

    if (liveClass.batch.enrollments.length === 0) {
      throw new AppError('FORBIDDEN', 'Student is not enrolled in this batch', 403);
    }

    // Check if open attendance already exists
    const openAttendance = await prisma.attendance.findFirst({
      where: {
        instituteId,
        liveClassId: classId,
        studentId,
        leftAt: null,
      },
    });

    if (openAttendance) {
      return openAttendance;
    }

    const attendance = await prisma.attendance.create({
      data: {
        instituteId,
        liveClassId: classId,
        studentId,
        joinedAt: new Date(),
        durationMin: 0,
      },
    });

    return attendance;
  }

  /**
   * Record student leaving live class & compute duration
   */
  static async recordLeave(instituteId: string, studentId: string, classId: string) {
    const latestAttendance = await prisma.attendance.findFirst({
      where: {
        instituteId,
        liveClassId: classId,
        studentId,
        leftAt: null,
      },
      orderBy: { joinedAt: 'desc' },
    });

    if (!latestAttendance) {
      return null;
    }

    const now = new Date();
    const durationMin = Math.max(
      1,
      Math.round((now.getTime() - latestAttendance.joinedAt.getTime()) / 60000)
    );

    const updated = await prisma.attendance.update({
      where: { id: latestAttendance.id },
      data: {
        leftAt: now,
        durationMin,
      },
    });

    return updated;
  }

  /**
   * Get attendance roster for a specific live class
   */
  static async getClassAttendance(
    instituteId: string,
    user: { id: string; role: string },
    classId: string
  ) {
    const liveClass = await prisma.liveClass.findFirst({
      where: { id: classId, instituteId },
      include: {
        batch: {
          include: {
            enrollments: {
              where: { status: 'ACTIVE' },
              include: {
                student: { select: { id: true, name: true, email: true, phone: true } },
              },
            },
          },
        },
        attendances: {
          include: {
            student: { select: { id: true, name: true, email: true } },
          },
        },
      },
    });

    if (!liveClass) {
      throw new AppError('NOT_FOUND', 'Live class not found', 404);
    }

    if (user.role === 'TEACHER' && liveClass.teacherId !== user.id) {
      throw new AppError('FORBIDDEN', 'Access denied to class attendance', 403);
    }

    // Build roster with status
    const attendedStudentIds = new Set(liveClass.attendances.map((a) => a.studentId));

    const roster = liveClass.batch.enrollments.map((e) => {
      const studentAttendances = liveClass.attendances.filter((a) => a.studentId === e.studentId);
      const totalDurationMin = studentAttendances.reduce((acc, curr) => acc + curr.durationMin, 0);
      const isPresent = attendedStudentIds.has(e.studentId);

      return {
        student: e.student,
        status: isPresent ? 'PRESENT' : 'ABSENT',
        totalDurationMin,
        sessionsCount: studentAttendances.length,
        firstJoinedAt: studentAttendances[0]?.joinedAt || null,
        lastLeftAt: studentAttendances[studentAttendances.length - 1]?.leftAt || null,
      };
    });

    const presentCount = roster.filter((r) => r.status === 'PRESENT').length;
    const totalEnrolled = roster.length;
    const attendancePercentage = totalEnrolled > 0 ? Math.round((presentCount / totalEnrolled) * 100) : 0;

    return {
      classId: liveClass.id,
      title: liveClass.title,
      scheduledAt: liveClass.scheduledAt,
      totalEnrolled,
      presentCount,
      absentCount: totalEnrolled - presentCount,
      attendancePercentage,
      roster,
    };
  }

  /**
   * Get student's overall attendance summary
   */
  static async getStudentAttendanceSummary(instituteId: string, studentId: string) {
    // Find all batches student is enrolled in
    const enrollments = await prisma.enrollment.findMany({
      where: { instituteId, studentId, status: 'ACTIVE' },
      select: { batchId: true },
    });
    const batchIds = enrollments.map((e) => e.batchId);

    // Find all ended/live classes in these batches
    const totalClasses = await prisma.liveClass.count({
      where: {
        instituteId,
        batchId: { in: batchIds },
        status: { in: ['LIVE', 'ENDED'] },
      },
    });

    // Find distinct classes attended by student
    const attendances = await prisma.attendance.findMany({
      where: {
        instituteId,
        studentId,
      },
      select: { liveClassId: true, durationMin: true },
    });

    const attendedClassIds = new Set(attendances.map((a) => a.liveClassId));
    const attendedCount = attendedClassIds.size;
    const totalMinutesAttended = attendances.reduce((acc, a) => acc + a.durationMin, 0);
    const overallPercentage = totalClasses > 0 ? Math.round((attendedCount / totalClasses) * 100) : 0;

    return {
      totalClasses,
      attendedClasses: attendedCount,
      missedClasses: Math.max(0, totalClasses - attendedCount),
      overallPercentage,
      totalMinutesAttended,
    };
  }
}
