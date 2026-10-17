import { prisma } from '../utils/prisma.js';
import { AppError } from '../errors/AppError.js';
import { logAudit } from './audit.service.js';

export interface QuestionInput {
  text: string;
  optionA: string;
  optionB: string;
  optionC: string;
  optionD: string;
  correctOption: 'A' | 'B' | 'C' | 'D';
  marks?: number;
  explanation?: string;
}

export interface CreateTestInput {
  batchId: string;
  title: string;
  description?: string;
  durationMin?: number;
  scheduledAt?: string | Date;
  questions: QuestionInput[];
}

export class TestService {
  /**
   * Teacher creates a new Computer-Based Test (CBT)
   */
  static async createTest(
    instituteId: string,
    teacherId: string,
    input: CreateTestInput
  ) {
    const { batchId, title, description, durationMin = 30, scheduledAt, questions } = input;

    if (!title || title.trim().length < 2) {
      throw new AppError('BAD_REQUEST', 'Test title is required (min 2 chars)', 400);
    }

    if (!questions || questions.length === 0) {
      throw new AppError('BAD_REQUEST', 'Test must contain at least 1 question', 400);
    }

    const batch = await prisma.batch.findFirst({
      where: { id: batchId, instituteId },
    });

    if (!batch) {
      throw new AppError('NOT_FOUND', 'Batch not found', 404);
    }

    // Validate questions
    let totalMarks = 0;
    questions.forEach((q, idx) => {
      if (!q.text || q.text.trim().length < 2) {
        throw new AppError('BAD_REQUEST', `Question #${idx + 1} text is required`, 400);
      }
      if (!['A', 'B', 'C', 'D'].includes(q.correctOption)) {
        throw new AppError('BAD_REQUEST', `Question #${idx + 1} correctOption must be A, B, C, or D`, 400);
      }
      totalMarks += q.marks || 1;
    });

    // Create Test & Questions in transaction
    const newTest = await prisma.test.create({
      data: {
        instituteId,
        batchId,
        teacherId,
        title: title.trim(),
        description: description?.trim() || null,
        durationMin,
        totalMarks,
        scheduledAt: scheduledAt ? new Date(scheduledAt) : null,
        status: 'PUBLISHED',
        questions: {
          create: questions.map((q, idx) => ({
            instituteId,
            orderNum: idx + 1,
            text: q.text.trim(),
            optionA: q.optionA.trim(),
            optionB: q.optionB.trim(),
            optionC: q.optionC.trim(),
            optionD: q.optionD.trim(),
            correctOption: q.correctOption,
            marks: q.marks || 1,
            explanation: q.explanation?.trim() || null,
          })),
        },
      },
      include: {
        batch: { select: { id: true, name: true, subject: true } },
        questions: {
          select: { id: true, orderNum: true, text: true, marks: true },
        },
      },
    });

    await logAudit({
      instituteId,
      actorId: teacherId,
      action: 'TEST_CREATED',
      entity: `Test:${newTest.id}`,
      meta: { batchId, title, totalMarks, questionsCount: questions.length },
    });

    return newTest;
  }

  /**
   * List tests for batch/user
   */
  static async listTests(
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

    const tests = await prisma.test.findMany({
      where: whereClause,
      orderBy: { createdAt: 'desc' },
      include: {
        batch: { select: { id: true, name: true, subject: true } },
        teacher: { select: { id: true, name: true } },
        _count: { select: { questions: true, attempts: true } },
        attempts: user.role === 'STUDENT' ? {
          where: { studentId: user.id },
          select: { id: true, score: true, totalMarks: true, status: true, submittedAt: true },
        } : false,
      },
    });

    return tests.map((t) => {
      const myAttempt = user.role === 'STUDENT' && Array.isArray(t.attempts) ? t.attempts[0] || null : null;
      return {
        id: t.id,
        title: t.title,
        description: t.description,
        durationMin: t.durationMin,
        totalMarks: t.totalMarks,
        scheduledAt: t.scheduledAt,
        status: t.status,
        batch: t.batch,
        teacher: t.teacher,
        questionsCount: t._count.questions,
        attemptsCount: t._count.attempts,
        myAttempt,
        isAttempted: myAttempt !== null && myAttempt.status === 'EVALUATED',
        createdAt: t.createdAt,
      };
    });
  }

  /**
   * Get single test details
   */
  static async getTestById(
    instituteId: string,
    user: { id: string; role: string },
    testId: string
  ) {
    const test = await prisma.test.findFirst({
      where: { id: testId, instituteId },
      include: {
        batch: true,
        teacher: { select: { id: true, name: true, email: true } },
        questions: {
          orderBy: { orderNum: 'asc' },
        },
        attempts: {
          where: user.role === 'STUDENT' ? { studentId: user.id } : undefined,
          include: {
            student: { select: { id: true, name: true, email: true } },
          },
        },
      },
    });

    if (!test) {
      throw new AppError('NOT_FOUND', 'Test not found', 404);
    }

    const myAttempt = test.attempts.find((a) => a.studentId === user.id);
    const isEvaluated = myAttempt?.status === 'EVALUATED';

    // If student and NOT evaluated, hide correct answers to prevent inspection
    if (user.role === 'STUDENT' && !isEvaluated) {
      return {
        ...test,
        questions: test.questions.map((q) => ({
          id: q.id,
          orderNum: q.orderNum,
          text: q.text,
          optionA: q.optionA,
          optionB: q.optionB,
          optionC: q.optionC,
          optionD: q.optionD,
          marks: q.marks,
        })),
        myAttempt: myAttempt || null,
      };
    }

    return {
      ...test,
      myAttempt: myAttempt || null,
    };
  }

  /**
   * Student starts timed test attempt
   */
  static async startTestAttempt(
    instituteId: string,
    studentId: string,
    testId: string
  ) {
    const test = await prisma.test.findFirst({
      where: { id: testId, instituteId },
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

    if (!test) {
      throw new AppError('NOT_FOUND', 'Test not found', 404);
    }

    if (test.batch.enrollments.length === 0) {
      throw new AppError('FORBIDDEN', 'You must be enrolled in this batch to take the test', 403);
    }

    // Check existing attempt
    const existing = await prisma.testAttempt.findUnique({
      where: {
        instituteId_testId_studentId: {
          instituteId,
          testId,
          studentId,
        },
      },
    });

    if (existing) {
      return existing;
    }

    const attempt = await prisma.testAttempt.create({
      data: {
        instituteId,
        testId,
        studentId,
        startedAt: new Date(),
        totalMarks: test.totalMarks,
        status: 'IN_PROGRESS',
      },
    });

    return attempt;
  }

  /**
   * Student submits test answers & triggers automated scoring
   */
  static async submitTestAttempt(
    instituteId: string,
    studentId: string,
    testId: string,
    input: { answers: Record<string, string> }
  ) {
    const { answers = {} } = input;

    const test = await prisma.test.findFirst({
      where: { id: testId, instituteId },
      include: { questions: true },
    });

    if (!test) {
      throw new AppError('NOT_FOUND', 'Test not found', 404);
    }

    // Automated Scoring
    let score = 0;
    const questionAnalysis = test.questions.map((q) => {
      const studentChoice = answers[q.id]?.toUpperCase();
      const isCorrect = studentChoice === q.correctOption;
      if (isCorrect) {
        score += q.marks;
      }
      return {
        questionId: q.id,
        orderNum: q.orderNum,
        studentChoice: studentChoice || null,
        correctOption: q.correctOption,
        isCorrect,
        marksAwarded: isCorrect ? q.marks : 0,
      };
    });

    const percentage = test.totalMarks > 0 ? Math.round((score / test.totalMarks) * 100) : 0;

    const attempt = await prisma.testAttempt.upsert({
      where: {
        instituteId_testId_studentId: {
          instituteId,
          testId,
          studentId,
        },
      },
      create: {
        instituteId,
        testId,
        studentId,
        score,
        totalMarks: test.totalMarks,
        answers: JSON.stringify(answers),
        status: 'EVALUATED',
        submittedAt: new Date(),
      },
      update: {
        score,
        totalMarks: test.totalMarks,
        answers: JSON.stringify(answers),
        status: 'EVALUATED',
        submittedAt: new Date(),
      },
    });

    await logAudit({
      instituteId,
      actorId: studentId,
      action: 'TEST_SUBMITTED',
      entity: `TestAttempt:${attempt.id}`,
      meta: { testId, score, totalMarks: test.totalMarks, percentage },
    });

    return {
      attemptId: attempt.id,
      score,
      totalMarks: test.totalMarks,
      percentage,
      status: 'EVALUATED',
      questionAnalysis,
    };
  }

  /**
   * Get detailed test result & score breakdown
   */
  static async getTestResult(
    instituteId: string,
    user: { id: string; role: string },
    testId: string
  ) {
    const test = await prisma.test.findFirst({
      where: { id: testId, instituteId },
      include: {
        questions: { orderBy: { orderNum: 'asc' } },
        attempts: {
          where: user.role === 'STUDENT' ? { studentId: user.id } : undefined,
          include: { student: { select: { id: true, name: true, email: true } } },
        },
      },
    });

    if (!test) {
      throw new AppError('NOT_FOUND', 'Test not found', 404);
    }

    return test;
  }

  /**
   * Public: Get sanitized share card details for a test attempt with deep link
   */
  static async getSharedTestScore(attemptId: string) {
    const attempt = await prisma.testAttempt.findUnique({
      where: { id: attemptId },
      include: {
        test: {
          select: {
            id: true,
            title: true,
            durationMin: true,
            totalMarks: true,
            batch: {
              select: {
                id: true,
                name: true,
                subject: true,
              },
            },
          },
        },
        student: {
          select: {
            id: true,
            name: true,
          },
        },
        institute: {
          select: {
            id: true,
            name: true,
            code: true,
            logoUrl: true,
            primaryColor: true,
            tagline: true,
          },
        },
      },
    });

    if (!attempt || !attempt.test) {
      throw new AppError('NOT_FOUND', 'Test score attempt not found', 404);
    }

    const totalMarks = attempt.totalMarks > 0 ? attempt.totalMarks : attempt.test.totalMarks;
    const percentage = totalMarks > 0 ? Math.round((attempt.score / totalMarks) * 100) : 0;
    const instituteCode = attempt.institute.code || (attempt.institute.id.length >= 6 ? attempt.institute.id.substring(0, 6).toUpperCase() : 'APEX01');

    return {
      attemptId: attempt.id,
      testId: attempt.test.id,
      testTitle: attempt.test.title,
      durationMin: attempt.test.durationMin,
      batchName: attempt.test.batch.name,
      subject: attempt.test.batch.subject,
      studentName: attempt.student.name,
      score: attempt.score,
      totalMarks,
      percentage,
      status: attempt.status,
      submittedAt: attempt.submittedAt || attempt.startedAt,
      institute: {
        id: attempt.institute.id,
        name: attempt.institute.name,
        code: instituteCode,
        logoUrl: attempt.institute.logoUrl,
        primaryColor: attempt.institute.primaryColor || '#0A9BE8',
        tagline: attempt.institute.tagline,
      },
      deepLink: `classora://test-result?attemptId=${attempt.id}&code=${instituteCode}`,
      webLink: `https://classora.app/test-result?attemptId=${attempt.id}&code=${instituteCode}`,
    };
  }
}
