import { Router } from 'express';
import { InstituteContentController } from '../controllers/institute_content.controller.js';
import { authenticate, requireRole } from '../middlewares/auth.js';
import { tenantGuard } from '../middlewares/tenant.js';

const router = Router();

// 1. All routes require valid auth and tenant scoping
router.use(authenticate, tenantGuard);

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
