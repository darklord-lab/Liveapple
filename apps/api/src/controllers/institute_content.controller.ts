import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { instituteContentService } from '../services/institute_content.service.js';

const linkPlatformEnum = z.enum(['YOUTUBE', 'TELEGRAM', 'WHATSAPP', 'INSTAGRAM', 'WEBSITE', 'OTHER']);

const createLinkSchema = z.object({
  title: z.string().min(1, 'Title is required').max(100, 'Title is too long'),
  platform: linkPlatformEnum,
  url: z.string().min(1, 'URL is required').max(500, 'URL is too long'),
  icon: z.string().max(50).optional(),
  order: z.number().int().optional(),
  isActive: z.boolean().optional(),
});

const updateLinkSchema = z.object({
  title: z.string().min(1).max(100).optional(),
  platform: linkPlatformEnum.optional(),
  url: z.string().min(1).max(500).optional(),
  icon: z.string().max(50).optional(),
  order: z.number().int().optional(),
  isActive: z.boolean().optional(),
});

const createTestimonialSchema = z.object({
  studentName: z.string().min(2, 'Student name must be at least 2 characters').max(100),
  batchOrExam: z.string().max(100).optional(),
  quote: z.string().min(5, 'Quote must be at least 5 characters').max(1000),
  avatarUrl: z.string().max(500).optional(),
  rating: z.number().int().min(1).max(5).optional(),
  order: z.number().int().optional(),
  isPublished: z.boolean().optional(),
});

const updateTestimonialSchema = z.object({
  studentName: z.string().min(2).max(100).optional(),
  batchOrExam: z.string().max(100).optional(),
  quote: z.string().min(5).max(1000).optional(),
  avatarUrl: z.string().max(500).optional(),
  rating: z.number().int().min(1).max(5).optional(),
  order: z.number().int().optional(),
  isPublished: z.boolean().optional(),
});

const updateBrandingSchema = z.object({
  name: z.string().min(2, 'Name must be at least 2 characters').max(100, 'Name must be at most 100 characters').optional(),
  code: z.string().min(3, 'Code must be at least 3 characters').max(12, 'Code must be at most 12 characters').regex(/^[A-Za-z0-9_-]+$/, 'Code can only contain letters, numbers, hyphens, and underscores').optional(),
  logoUrl: z.string().max(500).optional().nullable(),
  primaryColor: z.string().regex(/^#([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})$/, 'Must be a valid hex color code (e.g. #0A9BE8)').optional(),
  tagline: z.string().max(200).optional().nullable(),
});

export class InstituteContentController {
  /* -------------------------------------------------------------------------- */
  /* LINKS                                                                      */
  /* -------------------------------------------------------------------------- */
  static async getLinks(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const isAdmin = req.user!.role === 'ADMIN';
      const includeInactive = isAdmin && (req.query.all === 'true' || req.query.all === '1');

      const links = await instituteContentService.getLinks(instituteId, includeInactive);

      res.status(200).json({
        status: 'success',
        data: links,
      });
    } catch (err) {
      next(err);
    }
  }

  static async createLink(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const actorId = req.user!.userId;
      const body = createLinkSchema.parse(req.body);

      const link = await instituteContentService.createLink(instituteId, actorId, body);

      res.status(201).json({
        status: 'success',
        data: link,
      });
    } catch (err) {
      next(err);
    }
  }

  static async updateLink(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const linkId = req.params.id;
      const actorId = req.user!.userId;
      const body = updateLinkSchema.parse(req.body);

      const updated = await instituteContentService.updateLink(instituteId, linkId, actorId, body);

      res.status(200).json({
        status: 'success',
        data: updated,
      });
    } catch (err) {
      next(err);
    }
  }

  static async deleteLink(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const linkId = req.params.id;
      const actorId = req.user!.userId;

      const result = await instituteContentService.deleteLink(instituteId, linkId, actorId);

      res.status(200).json({
        status: 'success',
        data: result,
      });
    } catch (err) {
      next(err);
    }
  }

  /* -------------------------------------------------------------------------- */
  /* TESTIMONIALS                                                               */
  /* -------------------------------------------------------------------------- */
  static async getTestimonials(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const isAdmin = req.user!.role === 'ADMIN';
      const includeUnpublished = isAdmin && (req.query.all === 'true' || req.query.all === '1');

      const testimonials = await instituteContentService.getTestimonials(instituteId, includeUnpublished);

      res.status(200).json({
        status: 'success',
        data: testimonials,
      });
    } catch (err) {
      next(err);
    }
  }

  static async createTestimonial(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const actorId = req.user!.userId;
      const body = createTestimonialSchema.parse(req.body);

      const testimonial = await instituteContentService.createTestimonial(instituteId, actorId, body);

      res.status(201).json({
        status: 'success',
        data: testimonial,
      });
    } catch (err) {
      next(err);
    }
  }

  static async updateTestimonial(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const testimonialId = req.params.id;
      const actorId = req.user!.userId;
      const body = updateTestimonialSchema.parse(req.body);

      const updated = await instituteContentService.updateTestimonial(instituteId, testimonialId, actorId, body);

      res.status(200).json({
        status: 'success',
        data: updated,
      });
    } catch (err) {
      next(err);
    }
  }

  static async deleteTestimonial(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const testimonialId = req.params.id;
      const actorId = req.user!.userId;

      const result = await instituteContentService.deleteTestimonial(instituteId, testimonialId, actorId);

      res.status(200).json({
        status: 'success',
        data: result,
      });
    } catch (err) {
      next(err);
    }
  }

  /* -------------------------------------------------------------------------- */
  /* WHITE-LABEL BRANDING & CODE LOOKUP                                         */
  /* -------------------------------------------------------------------------- */
  static async lookupByCode(req: Request, res: Response, next: NextFunction) {
    try {
      const code = req.params.code;
      const result = await instituteContentService.lookupByCode(code);

      res.status(200).json({
        status: 'success',
        data: result,
      });
    } catch (err) {
      next(err);
    }
  }

  static async getBranding(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const branding = await instituteContentService.getBranding(instituteId);

      res.status(200).json({
        status: 'success',
        data: branding,
      });
    } catch (err) {
      next(err);
    }
  }

  static async updateBranding(req: Request, res: Response, next: NextFunction) {
    try {
      const instituteId = req.user!.instituteId;
      const actorId = req.user!.userId;
      const body = updateBrandingSchema.parse(req.body);

      const updated = await instituteContentService.updateBranding(instituteId, actorId, body);

      res.status(200).json({
        status: 'success',
        data: updated,
      });
    } catch (err) {
      next(err);
    }
  }
}
