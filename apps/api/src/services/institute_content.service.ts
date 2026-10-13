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

export interface UpdateBrandingDto {
  name?: string;
  code?: string;
  logoUrl?: string;
  primaryColor?: string;
  tagline?: string;
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
      throw new AppError('NOT_FOUND', 'Testimonial not found', 404);
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

  /* -------------------------------------------------------------------------- */
  /* INSTITUTE WHITE-LABEL BRANDING & CODE LOOKUP                               */
  /* -------------------------------------------------------------------------- */
  async lookupByCode(codeOrSlug: string) {
    const raw = (codeOrSlug || '').trim();
    if (!raw) {
      throw new AppError('BAD_REQUEST', 'Institute code is required', 400);
    }
    const codeUpper = raw.toUpperCase();
    const slugLower = raw.toLowerCase();

    const institute = await prisma.institute.findFirst({
      where: {
        OR: [
          { code: codeUpper },
          { slug: slugLower },
          { id: raw },
        ],
      },
      select: {
        id: true,
        name: true,
        slug: true,
        code: true,
        logoUrl: true,
        primaryColor: true,
        tagline: true,
        plan: true,
      },
    });

    if (!institute) {
      throw new AppError('NOT_FOUND', `Institute not found for code: ${codeUpper}`, 404);
    }

    const links = await prisma.instituteLink.findMany({
      where: { instituteId: institute.id, isActive: true },
      orderBy: [{ order: 'asc' }, { createdAt: 'asc' }],
    });

    return {
      institute,
      links,
    };
  }

  async getBranding(instituteId: string) {
    const institute = await prisma.institute.findUnique({
      where: { id: instituteId },
      select: {
        id: true,
        name: true,
        slug: true,
        code: true,
        logoUrl: true,
        primaryColor: true,
        tagline: true,
        plan: true,
      },
    });

    if (!institute) {
      throw new AppError('NOT_FOUND', 'Institute not found', 404);
    }

    return institute;
  }

  async updateBranding(instituteId: string, actorId: string, data: UpdateBrandingDto) {
    const institute = await prisma.institute.findUnique({
      where: { id: instituteId },
    });

    if (!institute) {
      throw new AppError('NOT_FOUND', 'Institute not found', 404);
    }

    let codeToSet: string | undefined = undefined;
    if (data.code !== undefined) {
      const trimmedCode = data.code.trim().toUpperCase();
      if (trimmedCode.length < 3 || trimmedCode.length > 12) {
        throw new AppError('BAD_REQUEST', 'Institute code must be between 3 and 12 characters', 400);
      }
      if (!/^[A-Z0-9_-]+$/.test(trimmedCode)) {
        throw new AppError('BAD_REQUEST', 'Institute code can only contain letters, numbers, hyphens, and underscores', 400);
      }

      // Check conflict
      const existing = await prisma.institute.findFirst({
        where: {
          code: trimmedCode,
          NOT: { id: instituteId },
        },
      });
      if (existing) {
        throw new AppError('CONFLICT', `Institute code '${trimmedCode}' is already in use by another institute`, 409);
      }
      codeToSet = trimmedCode;
    }

    let colorToSet: string | undefined = undefined;
    if (data.primaryColor !== undefined) {
      const trimmedColor = data.primaryColor.trim();
      if (!/^#([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})$/.test(trimmedColor)) {
        throw new AppError('BAD_REQUEST', 'Primary color must be a valid hex color (e.g. #0A9BE8)', 400);
      }
      colorToSet = trimmedColor;
    }

    const updated = await prisma.institute.update({
      where: { id: instituteId },
      data: {
        ...(data.name !== undefined ? { name: data.name.trim() } : {}),
        ...(codeToSet !== undefined ? { code: codeToSet } : {}),
        ...(data.logoUrl !== undefined ? { logoUrl: data.logoUrl ? data.logoUrl.trim() : null } : {}),
        ...(colorToSet !== undefined ? { primaryColor: colorToSet } : {}),
        ...(data.tagline !== undefined ? { tagline: data.tagline ? data.tagline.trim() : null } : {}),
      },
      select: {
        id: true,
        name: true,
        slug: true,
        code: true,
        logoUrl: true,
        primaryColor: true,
        tagline: true,
        plan: true,
      },
    });

    await logAudit({
      instituteId,
      actorId,
      action: 'INSTITUTE_BRANDING_UPDATED',
      entity: `Institute:${instituteId}`,
      meta: { changes: data },
    });

    return updated;
  }
}

export const instituteContentService = new InstituteContentService();
