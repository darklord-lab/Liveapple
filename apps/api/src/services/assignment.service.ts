import { prisma } from '../utils/prisma.js';
import { AppError } from '../errors/AppError.js';
import { logAudit } from './audit.service.js';

export interface CreateAssignmentInput {
  batchId: string;
  title: string;
  description: string;
  dueDate: string | Date;
  attachmentUrl?: string;
  maxMarks?: number;
}

export class AssignmentService {
  /**
   * Teacher creates a new assignment for a batch
   */
  static async createAssignment(
    instituteId: string,
    teacherId: string,
    input: CreateAssignmentInput
  ) {
    const { batchId, title, description, attachmentUrl, maxMarks = 100 } = input;

    if (!title || title.trim().length < 2) {
      throw new AppError('BAD_REQUEST', 'Assignment title is required (min 2 chars)', 400);
    }
    if (!description || description.trim().length < 2) {
      throw new AppError('BAD_REQUEST', 'Assignment description is required', 400);
    }

    const dueDate = new Date(input.dueDate);
    if (isNaN(dueDate.getTime())) {
      throw new AppError('BAD_REQUEST', 'Valid due date is required', 400);
    }

    const batch = await prisma.batch.findFirst({
      where: { id: batchId, instituteId },
    });

    if (!batch) {
      throw new AppError('NOT_FOUND', 'Batch not found', 404);
    }

    const assignment = await prisma.assignment.create({
      data: {
        instituteId,
        batchId,
        teacherId,
        title: title.trim(),
        description: description.trim(),
        dueDate,
        attachmentUrl: attachmentUrl?.trim() || null,
        maxMarks,
      },
      include: {
        batch: { select: { id: true, name: true, subject: true } },
        teacher: { select: { id: true, name: true, email: true } },
      },
    });

    await logAudit({
      instituteId,
      actorId: teacherId,
      action: 'ASSIGNMENT_CREATED',
      entity: `Assignment:${assignment.id}`,
      meta: { batchId, title, maxMarks },
    });

    return assignment;
  }

  /**
   * List assignments for user (Teacher sees created/batch, Student sees enrolled batches + submission status)
   */
  static async listAssignments(
    instituteId: string,
    user: { id: string; role: string },
    query: { batchId?: string } = {}
  ) {
    let whereClause: any = { instituteId };

    if (query.batchId) {
      whereClause.batchId = query.batchId;
    }

    if (user.role === 'TEACHER') {
      whereClause.teacherId = user.id;
    } else if (user.role === 'STUDENT') {
      const activeEnrollments = await prisma.enrollment.findMany({
        where: { instituteId, studentId: user.id, status: 'ACTIVE' },
        select: { batchId: true },
      });
      const batchIds = activeEnrollments.map((e) => e.batchId);
      whereClause.batchId = { in: batchIds };
    }

    const assignments = await prisma.assignment.findMany({
      where: whereClause,
      orderBy: { dueDate: 'asc' },
      include: {
        batch: { select: { id: true, name: true, subject: true } },
        teacher: { select: { id: true, name: true } },
        submissions: user.role === 'STUDENT' ? {
          where: { studentId: user.id },
          select: { id: true, status: true, marksObtained: true, submittedAt: true, fileUrl: true },
        } : {
          select: { id: true, studentId: true, status: true, marksObtained: true, submittedAt: true },
        },
      },
    });

    return assignments.map((a) => {
      const studentSubmission = user.role === 'STUDENT' ? a.submissions[0] || null : null;
      return {
        id: a.id,
        title: a.title,
        description: a.description,
        dueDate: a.dueDate,
        attachmentUrl: a.attachmentUrl,
        maxMarks: a.maxMarks,
        batch: a.batch,
        teacher: a.teacher,
        submissionCount: a.submissions.length,
        mySubmission: studentSubmission,
        isSubmitted: studentSubmission !== null,
        createdAt: a.createdAt,
      };
    });
  }

  /**
   * Get single assignment with submissions
   */
  static async getAssignmentById(
    instituteId: string,
    user: { id: string; role: string },
    assignmentId: string
  ) {
    const assignment = await prisma.assignment.findFirst({
      where: { id: assignmentId, instituteId },
      include: {
        batch: true,
        teacher: { select: { id: true, name: true, email: true } },
        submissions: {
          include: {
            student: { select: { id: true, name: true, email: true } },
          },
        },
      },
    });

    if (!assignment) {
      throw new AppError('NOT_FOUND', 'Assignment not found', 404);
    }

    if (user.role === 'STUDENT') {
      const mySubmission = assignment.submissions.find((s) => s.studentId === user.id) || null;
      return {
        ...assignment,
        submissions: mySubmission ? [mySubmission] : [],
        mySubmission,
      };
    }

    return assignment;
  }

  /**
   * Student submits an assignment
   */
  static async submitAssignment(
    instituteId: string,
    studentId: string,
    assignmentId: string,
    input: { fileUrl: string }
  ) {
    const { fileUrl } = input;
    if (!fileUrl || fileUrl.trim().length < 5) {
      throw new AppError('BAD_REQUEST', 'Valid file/submission URL is required', 400);
    }

    const assignment = await prisma.assignment.findFirst({
      where: { id: assignmentId, instituteId },
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

    if (!assignment) {
      throw new AppError('NOT_FOUND', 'Assignment not found', 404);
    }

    if (assignment.batch.enrollments.length === 0) {
      throw new AppError('FORBIDDEN', 'You must be enrolled in this batch to submit homework', 403);
    }

    const now = new Date();
    const isLate = now.getTime() > new Date(assignment.dueDate).getTime();
    const status = isLate ? 'LATE' : 'SUBMITTED';

    const submission = await prisma.submission.upsert({
      where: {
        instituteId_assignmentId_studentId: {
          instituteId,
          assignmentId,
          studentId,
        },
      },
      create: {
        instituteId,
        assignmentId,
        studentId,
        fileUrl: fileUrl.trim(),
        status,
        submittedAt: now,
      },
      update: {
        fileUrl: fileUrl.trim(),
        status,
        submittedAt: now,
      },
      include: {
        student: { select: { id: true, name: true } },
      },
    });

    await logAudit({
      instituteId,
      actorId: studentId,
      action: 'ASSIGNMENT_SUBMITTED',
      entity: `Submission:${submission.id}`,
      meta: { assignmentId, isLate },
    });

    return submission;
  }

  /**
   * Teacher grades student's assignment submission
   */
  static async gradeSubmission(
    instituteId: string,
    teacherId: string,
    submissionId: string,
    input: { marksObtained: number; feedback?: string }
  ) {
    const { marksObtained, feedback } = input;

    if (typeof marksObtained !== 'number' || marksObtained < 0) {
      throw new AppError('BAD_REQUEST', 'Valid non-negative marks required', 400);
    }

    const submission = await prisma.submission.findFirst({
      where: { id: submissionId, instituteId },
      include: {
        assignment: true,
        student: true,
      },
    });

    if (!submission) {
      throw new AppError('NOT_FOUND', 'Submission not found', 404);
    }

    if (marksObtained > submission.assignment.maxMarks) {
      throw new AppError(
        'BAD_REQUEST',
        `Marks obtained (${marksObtained}) cannot exceed max marks (${submission.assignment.maxMarks})`,
        400
      );
    }

    const updated = await prisma.submission.update({
      where: { id: submissionId },
      data: {
        marksObtained,
        feedback: feedback?.trim() || null,
        status: 'GRADED',
      },
      include: {
        student: { select: { id: true, name: true, email: true } },
        assignment: { select: { id: true, title: true, maxMarks: true } },
      },
    });

    await logAudit({
      instituteId,
      actorId: teacherId,
      action: 'SUBMISSION_GRADED',
      entity: `Submission:${submissionId}`,
      meta: { marksObtained, maxMarks: submission.assignment.maxMarks },
    });

    return updated;
  }
}
