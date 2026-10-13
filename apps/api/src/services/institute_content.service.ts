import { prisma } from '../utils/prisma.js';
import { AppError } from '../errors/AppError.js';
import { logAudit } from './audit.service.js';

export interface CreateLinkDto {
  title: string;
  platform: string; // "YOUTUBE" | "TELEGRAM" | "WHATSAPP" | "INSTAGRAM" | "WEBSITE" | "OTHER"
  url: string;
  icon?: string;
  order?: number;
  isActive?: boolean;
}

export interface UpdateLinkDto {
  title?: string;
  platform?: string;
  url?: string;
  icon?: string;
  order?: number;
  isActive?: boolean;
}

export interface CreateTestimonialDto {
  studentName: string;
  batchOrExam?: string;
  quote: string;
  avatarUrl?: string;
  rating?: number;
  order?: number;
  isPublished?: boolean;
}

export interface UpdateTestimonialDto {
  studentName?: string;
  batchOrExam?: string;
  quote?: string;
  avatarUrl?: string;
  rating?: number;
  order?: number;
  isPublished?: boolean;
}

export class InstituteContentService {
  /* -------------------------------------------------------------------------- */
  /* INSTITUTE SOCIAL / CONNECT LINKS                                           */
  /* -------------------------------------------------------------------------- */
  async getLinks(instituteId: string, includeInactive: boolean = false) {
    return prisma.instituteLink.findMany({
      where: {
        instituteId,
        ...(includeInactive ? {} : { isActive: true }),
      },
      orderBy: [{ order: 'asc' }, { createdAt: 'asc' }],
    });
  }

  async createLink(instituteId: string, actorId: string, data: CreateLinkDto) {
    const link = await prisma.instituteLink.create({
      data: {
        instituteId,
        title: data.title.trim(),
        platform: data.platform.toUpperCase().trim(),
        url: data.url.trim(),
        icon: data.icon?.trim() || null,
        order: data.order ?? 0,
        isActive: data.isActive ?? true,
      },
    });

    await logAudit({
      instituteId,
      actorId,
      action: 'INSTITUTE_LINK_CREATED',
      entity: `InstituteLink:${link.id}`,
      meta: { title: link.title, platform: link.platform, url: link.url },
    });

    return link;
  }

  async updateLink(instituteId: string, linkId: string, actorId: string, data: UpdateLinkDto) {
    const existing = await prisma.instituteLink.findFirst({
      where: { id: linkId, instituteId },
    });

    if (!existing) {
      throw new AppError('Institute link not found', 404, 'NOT_FOUND');
    }

    const updated = await prisma.instituteLink.update({
      where: { id: linkId },
      data: {
        ...(data.title !== undefined ? { title: data.title.trim() } : {}),
        ...(data.platform !== undefined ? { platform: data.platform.toUpperCase().trim() } : {}),
        ...(data.url !== undefined ? { url: data.url.trim() } : {}),
        ...(data.icon !== undefined ? { icon: data.icon ? data.icon.trim() : null } : {}),
        ...(data.order !== undefined ? { order: data.order } : {}),
        ...(data.isActive !== undefined ? { isActive: data.isActive } : {}),
      },
    });

    await logAudit({
      instituteId,
      actorId,
      action: 'INSTITUTE_LINK_UPDATED',
      entity: `InstituteLink:${linkId}`,
      meta: { changes: data },
    });

    return updated;
  }

  async deleteLink(instituteId: string, linkId: string, actorId: string) {
    const existing = await prisma.instituteLink.findFirst({
      where: { id: linkId, instituteId },
    });

    if (!existing) {
      throw new AppError('Institute link not found', 404, 'NOT_FOUND');
    }

    await prisma.instituteLink.delete({
      where: { id: linkId },
    });

    await logAudit({
      instituteId,
      actorId,
      action: 'INSTITUTE_LINK_DELETED',
      entity: `InstituteLink:${linkId}`,
      meta: { title: existing.title, platform: existing.platform },
    });

    return { success: true, message: 'Institute link deleted successfully' };
  }

  /* -------------------------------------------------------------------------- */
  /* STUDENT TESTIMONIALS                                                       */
  /* -------------------------------------------------------------------------- */
  async getTestimonials(instituteId: string, includeUnpublished: boolean = false) {
    return prisma.testimonial.findMany({
      where: {
        instituteId,
        ...(includeUnpublished ? {} : { isPublished: true }),
      },
      orderBy: [{ order: 'asc' }, { createdAt: 'desc' }],
    });
  }

  async createTestimonial(instituteId: string, actorId: string, data: CreateTestimonialDto) {
    const testimonial = await prisma.testimonial.create({
      data: {
        instituteId,
        studentName: data.studentName.trim(),
        batchOrExam: data.batchOrExam?.trim() || null,
        quote: data.quote.trim(),
        avatarUrl: data.avatarUrl?.trim() || null,
        rating: Math.min(5, Math.max(1, data.rating ?? 5)),
        order: data.order ?? 0,
        isPublished: data.isPublished ?? true,
      },
    });

    await logAudit({
      instituteId,
      actorId,
      action: 'TESTIMONIAL_CREATED',
      entity: `Testimonial:${testimonial.id}`,
      meta: { studentName: testimonial.studentName, rating: testimonial.rating },
    });

    return testimonial;
  }

  async updateTestimonial(instituteId: string, testimonialId: string, actorId: string, data: UpdateTestimonialDto) {
    const existing = await prisma.testimonial.findFirst({
      where: { id: testimonialId, instituteId },
    });

    if (!existing) {
      throw new AppError('Testimonial not found', 404, 'NOT_FOUND');
    }

    const updated = await prisma.testimonial.update({
      where: { id: testimonialId },
      data: {
        ...(data.studentName !== undefined ? { studentName: data.studentName.trim() } : {}),
        ...(data.batchOrExam !== undefined ? { batchOrExam: data.batchOrExam ? data.batchOrExam.trim() : null } : {}),
        ...(data.quote !== undefined ? { quote: data.quote.trim() } : {}),
        ...(data.avatarUrl !== undefined ? { avatarUrl: data.avatarUrl ? data.avatarUrl.trim() : null } : {}),
        ...(data.rating !== undefined ? { rating: Math.min(5, Math.max(1, data.rating)) } : {}),
        ...(data.order !== undefined ? { order: data.order } : {}),
        ...(data.isPublished !== undefined ? { isPublished: data.isPublished } : {}),
      },
    });

    await logAudit({
      instituteId,
      actorId,
      action: 'TESTIMONIAL_UPDATED',
      entity: `Testimonial:${testimonialId}`,
      meta: { changes: data },
    });

    return updated;
  }

  async deleteTestimonial(instituteId: string, testimonialId: string, actorId: string) {
    const existing = await prisma.testimonial.findFirst({
      where: { id: testimonialId, instituteId },
    });

    if (!existing) {
      throw new AppError('Testimonial not found', 404, 'NOT_FOUND');
    }

    await prisma.testimonial.delete({
      where: { id: testimonialId },
    });

    await logAudit({
      instituteId,
      actorId,
      action: 'TESTIMONIAL_DELETED',
      entity: `Testimonial:${testimonialId}`,
      meta: { studentName: existing.studentName },
    });

    return { success: true, message: 'Testimonial deleted successfully' };
  }
}

export const instituteContentService = new InstituteContentService();
