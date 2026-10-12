import { prisma } from '../utils/prisma.js';
import { generateRandomToken, hashToken, hashPassword } from '../utils/hash.js';
import { AppError } from '../errors/AppError.js';
import { env } from '../config/env.js';
import { logAudit } from './audit.service.js';

export interface AddTeacherInput {
  name: string;
  email: string;
  phone?: string;
  password?: string;
  coachingName?: string;
  centreLogo?: string;
  centreAddress?: string;
  contactPhone?: string;
  bio?: string;
  subjects?: string;
}

export interface UpdateTeacherInput {
  name?: string;
  email?: string;
  phone?: string;
  status?: 'ACTIVE' | 'SUSPENDED';
  coachingName?: string;
  centreLogo?: string;
  centreAddress?: string;
  contactPhone?: string;
  bio?: string;
  subjects?: string;
  password?: string;
}

export interface BulkTeacherInputRow {
  name: string;
  email: string;
  phone?: string;
  coachingName?: string;
  subjects?: string;
}

export interface ListTeachersQuery {
  page?: number;
  limit?: number;
  search?: string;
  status?: string;
}

export interface ListStudentsQuery {
  teacherId?: string;
  batchId?: string;
  search?: string;
  page?: number;
  limit?: number;
}

export interface AddStudentInput {
  name: string;
  email: string;
  phone?: string;
  password?: string;
  teacherId?: string;
  batchId?: string;
}

export class AdminService {
  /**
   * List teachers under the institute with pagination, search, and coaching details
   */
  static async listTeachers(instituteId: string, query: ListTeachersQuery) {
    const page = Math.max(1, query.page || 1);
    const limit = Math.min(100, Math.max(1, query.limit || 20));
    const skip = (page - 1) * limit;

    const whereClause: any = {
      instituteId,
      role: 'TEACHER',
    };

    if (query.status && ['ACTIVE', 'INVITED', 'SUSPENDED'].includes(query.status.toUpperCase())) {
      whereClause.status = query.status.toUpperCase();
    }

    if (query.search && query.search.trim().length > 0) {
      const search = query.search.trim();
      whereClause.OR = [
        { name: { contains: search } },
        { email: { contains: search } },
        { phone: { contains: search } },
        { coachingName: { contains: search } },
        { subjects: { contains: search } },
      ];
    }

    const [total, teachers] = await Promise.all([
      prisma.user.count({ where: whereClause }),
      prisma.user.findMany({
        where: whereClause,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        select: {
          id: true,
          instituteId: true,
          name: true,
          email: true,
          phone: true,
          role: true,
          status: true,
          coachingName: true,
          centreLogo: true,
          centreAddress: true,
          contactPhone: true,
          bio: true,
          subjects: true,
          createdAt: true,
          updatedAt: true,
          taughtBatches: {
            select: {
              id: true,
              name: true,
              subject: true,
              joinCode: true,
              _count: { select: { enrollments: true } },
            },
          },
          _count: {
            select: {
              taughtBatches: true,
              taughtClasses: true,
              createdStudents: true,
            },
          },
        },
      }),
    ]);

    return {
      data: teachers,
      teachers,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Onboard a single teacher: creates User (ACTIVE or INVITED) + Coaching Centre Profile
   */
  static async addTeacher(instituteId: string, adminId: string, input: AddTeacherInput) {
    const email = input.email.toLowerCase().trim();
    const name = input.name.trim();
    const phone = input.phone?.trim() || null;

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      throw new AppError('BAD_REQUEST', `Invalid email format: ${email}`, 400);
    }

    // 1. Check if user already exists in this institute
    const existing = await prisma.user.findFirst({
      where: { instituteId, email },
    });

    if (existing) {
      throw new AppError('CONFLICT', `A teacher with email ${email} already exists in this institute`, 409);
    }

    // 2. Generate random 48h invite code if needed
    const rawInviteCode = generateRandomToken(16);
    const codeHash = hashToken(rawInviteCode);
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + env.INVITE_TOKEN_EXPIRES_HOURS);

    // Initial password
    const passwordHash = input.password
      ? await hashPassword(input.password)
      : await hashPassword(generateRandomToken(24));

    const status = input.password ? 'ACTIVE' : 'INVITED';

    // 3. Upsert teacher
    let teacher;
    const teacherData = {
      name,
      phone,
      coachingName: input.coachingName || null,
      centreLogo: input.centreLogo || null,
      centreAddress: input.centreAddress || null,
      contactPhone: input.contactPhone || input.phone || null,
      bio: input.bio || null,
      subjects: input.subjects || null,
      status,
      passwordHash,
    };

    if (existing) {
      teacher = await prisma.user.update({
        where: { id: existing.id },
        data: teacherData,
      });
    } else {
      teacher = await prisma.user.create({
        data: {
          instituteId,
          email,
          role: 'TEACHER',
          ...teacherData,
        },
      });
    }

    // 4. Create Invite record if invited
    let invite = null;
    if (status === 'INVITED') {
      invite = await prisma.invite.create({
        data: {
          instituteId,
          email,
          phone,
          role: 'TEACHER',
          codeHash,
          expiresAt,
        },
      });
    }

    await logAudit({
      instituteId,
      actorId: adminId,
      action: 'TEACHER_ONBOARDED',
      entity: 'USER',
      meta: { teacherId: teacher.id, email, name, status },
    });

    return {
      teacher: {
        id: teacher.id,
        name: teacher.name,
        email: teacher.email,
        phone: teacher.phone,
        status: teacher.status,
        coachingName: teacher.coachingName,
        centreLogo: teacher.centreLogo,
        subjects: teacher.subjects,
      },
      invite: invite
        ? {
            code: rawInviteCode,
            inviteCode: rawInviteCode,
            expiresAt: invite.expiresAt,
          }
        : null,
    };
  }

  /**
   * Update teacher profile, coaching info, and status
   */
  static async updateTeacher(
    instituteId: string,
    adminId: string,
    teacherId: string,
    input: UpdateTeacherInput
  ) {
    const teacher = await prisma.user.findFirst({
      where: { id: teacherId, instituteId, role: 'TEACHER' },
    });

    if (!teacher) {
      throw new AppError('NOT_FOUND', 'Teacher not found in your institute', 404);
    }

    const updateData: any = {};
    if (input.name) updateData.name = input.name.trim();
    if (input.phone !== undefined) updateData.phone = input.phone?.trim() || null;
    if (input.status) updateData.status = input.status;
    if (input.coachingName !== undefined) updateData.coachingName = input.coachingName;
    if (input.centreLogo !== undefined) updateData.centreLogo = input.centreLogo;
    if (input.centreAddress !== undefined) updateData.centreAddress = input.centreAddress;
    if (input.contactPhone !== undefined) updateData.contactPhone = input.contactPhone;
    if (input.bio !== undefined) updateData.bio = input.bio;
    if (input.subjects !== undefined) updateData.subjects = input.subjects;
    if (input.password) {
      updateData.passwordHash = await hashPassword(input.password);
    }

    const updated = await prisma.user.update({
      where: { id: teacher.id },
      data: updateData,
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        role: true,
        status: true,
        coachingName: true,
        centreLogo: true,
        centreAddress: true,
        contactPhone: true,
        bio: true,
        subjects: true,
        updatedAt: true,
      },
    });

    if (input.status === 'SUSPENDED') {
      await prisma.refreshToken.updateMany({
        where: { userId: teacher.id, revokedAt: null },
        data: { revokedAt: new Date() },
      });
    }

    await logAudit({
      instituteId,
      actorId: adminId,
      action: 'TEACHER_UPDATED',
      entity: 'USER',
      meta: { teacherId: teacher.id, updates: input },
    });

    return updated;
  }

  /**
   * Delete a teacher (or cascade cleanup)
   */
  static async deleteTeacher(instituteId: string, adminId: string, teacherId: string) {
    const teacher = await prisma.user.findFirst({
      where: { id: teacherId, instituteId, role: 'TEACHER' },
    });

    if (!teacher) {
      throw new AppError('NOT_FOUND', 'Teacher not found in your institute', 404);
    }

    // Revoke refresh tokens first
    await prisma.refreshToken.deleteMany({
      where: { userId: teacher.id },
    });

    // Delete teacher
    await prisma.user.delete({
      where: { id: teacher.id },
    });

    await logAudit({
      instituteId,
      actorId: adminId,
      action: 'TEACHER_DELETED',
      entity: 'USER',
      meta: { teacherId, name: teacher.name, email: teacher.email },
    });

    return { success: true, message: `Teacher ${teacher.name} deleted successfully` };
  }

  /**
   * Bulk Onboard Teachers from CSV
   */
  static async bulkOnboard(instituteId: string, adminId: string, rawTeachers: BulkTeacherInputRow[]) {
    const successful = [];
    const failed = [];

    for (const item of rawTeachers) {
      try {
        if (!item.name || !item.email) {
          failed.push({ item, error: 'Missing required fields (name, email)' });
          continue;
        }
        const res = await this.addTeacher(instituteId, adminId, {
          name: item.name,
          email: item.email,
          phone: item.phone,
          coachingName: item.coachingName,
          subjects: item.subjects,
        });
        successful.push({
          ...res,
          teacher: res.teacher,
          invite: res.invite,
          inviteCode: res.invite?.inviteCode || res.invite?.code,
        });
      } catch (err: any) {
        failed.push({ item, error: err.message || 'Failed to onboard' });
      }
    }

    return {
      summary: {
        total: rawTeachers.length,
        succeeded: successful.length,
        successfulCount: successful.length,
        failed: failed.length,
        failedCount: failed.length,
      },
      successful,
      failed,
    };
  }

  /**
   * Suspend or Reactivate a teacher
   */
  static async updateTeacherStatus(
    instituteId: string,
    adminId: string,
    teacherId: string,
    newStatus: 'ACTIVE' | 'SUSPENDED'
  ) {
    return this.updateTeacher(instituteId, adminId, teacherId, { status: newStatus });
  }

  /**
   * List all students across the institute with Teacher, Batch, and Search filters
   */
  static async listStudents(instituteId: string, query: ListStudentsQuery) {
    const page = Math.max(1, query.page || 1);
    const limit = Math.min(100, Math.max(1, query.limit || 50));
    const skip = (page - 1) * limit;

    const whereClause: any = {
      instituteId,
      role: 'STUDENT',
    };

    if (query.teacherId) {
      whereClause.creatorTeacherId = query.teacherId;
    }

    if (query.batchId) {
      whereClause.enrollments = {
        some: { batchId: query.batchId, status: 'ACTIVE' },
      };
    }

    if (query.search && query.search.trim().length > 0) {
      const search = query.search.trim();
      whereClause.OR = [
        { name: { contains: search } },
        { email: { contains: search } },
        { phone: { contains: search } },
      ];
    }

    const [total, students] = await Promise.all([
      prisma.user.count({ where: whereClause }),
      prisma.user.findMany({
        where: whereClause,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        select: {
          id: true,
          name: true,
          email: true,
          phone: true,
          status: true,
          createdAt: true,
          creatorTeacher: {
            select: {
              id: true,
              name: true,
              email: true,
              coachingName: true,
            },
          },
          enrollments: {
            where: { status: 'ACTIVE' },
            select: {
              id: true,
              enrolledAt: true,
              batch: {
                select: {
                  id: true,
                  name: true,
                  subject: true,
                  teacher: { select: { id: true, name: true } },
                },
              },
            },
          },
        },
      }),
    ]);

    return {
      data: students,
      students,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Add a student directly under a specific teacher & batch
   */
  static async addStudent(instituteId: string, adminId: string, input: AddStudentInput) {
    const email = input.email.toLowerCase().trim();
    const name = input.name.trim();
    const phone = input.phone?.trim() || null;

    const existing = await prisma.user.findFirst({
      where: { instituteId, email },
    });

    if (existing) {
      throw new AppError('CONFLICT', `Student with email ${email} already exists`, 409);
    }

    const defaultPassword = input.password || 'Student@123';
    const passwordHash = await hashPassword(defaultPassword);

    const student = await prisma.user.create({
      data: {
        instituteId,
        name,
        email,
        phone,
        role: 'STUDENT',
        status: 'ACTIVE',
        passwordHash,
        creatorTeacherId: input.teacherId || null,
      },
    });

    if (input.batchId) {
      await prisma.enrollment.create({
        data: {
          instituteId,
          batchId: input.batchId,
          studentId: student.id,
          status: 'ACTIVE',
        },
      });
    }

    await logAudit({
      instituteId,
      actorId: adminId,
      action: 'STUDENT_CREATED',
      entity: 'USER',
      meta: { studentId: student.id, email, teacherId: input.teacherId, batchId: input.batchId },
    });

    return student;
  }
}
