import { Router } from 'express';
import { InstituteContentController } from '../controllers/institute_content.controller.js';
import { authenticate, requireRole } from '../middlewares/auth.js';
import { tenantGuard } from '../middlewares/tenant.js';
import { instituteCodeLimiter } from '../middlewares/rateLimiter.js';

const router = Router();

// Public route for first launch & code verification (no auth required, rate limited per RULES.md F.6)
router.get('/lookup/:code', instituteCodeLimiter, InstituteContentController.lookupByCode);

// All subsequent routes require valid auth and tenant scoping
router.use(authenticate, tenantGuard);

/* -------------------------------------------------------------------------- */
/* WHITE-LABEL BRANDING                                                       */
/* -------------------------------------------------------------------------- */
// GET: Accessible by all authenticated roles (Students, Teachers, Admins)
router.get('/branding', InstituteContentController.getBranding);

// Admin-only management endpoint
router.patch('/branding', requireRole('ADMIN'), InstituteContentController.updateBranding);

/* -------------------------------------------------------------------------- */
/* INSTITUTE SOCIAL & CONNECT LINKS                                           */
/* -------------------------------------------------------------------------- */
// GET: Accessible by all authenticated roles (Students, Teachers, Admins)
router.get('/links', InstituteContentController.getLinks);

// Admin-only management endpoints
router.post('/links', requireRole('ADMIN'), InstituteContentController.createLink);
router.patch('/links/:id', requireRole('ADMIN'), InstituteContentController.updateLink);
router.delete('/links/:id', requireRole('ADMIN'), InstituteContentController.deleteLink);

/* -------------------------------------------------------------------------- */
/* STUDENT TESTIMONIALS                                                       */
/* -------------------------------------------------------------------------- */
// GET: Accessible by all authenticated roles (Students, Teachers, Admins)
router.get('/testimonials', InstituteContentController.getTestimonials);

// Admin-only management endpoints
router.post('/testimonials', requireRole('ADMIN'), InstituteContentController.createTestimonial);
router.patch('/testimonials/:id', requireRole('ADMIN'), InstituteContentController.updateTestimonial);
router.delete('/testimonials/:id', requireRole('ADMIN'), InstituteContentController.deleteTestimonial);

export default router;
