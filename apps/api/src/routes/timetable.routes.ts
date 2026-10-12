import { Router } from 'express';
import { TimetableController } from '../controllers/timetable.controller.js';
import { authenticate, requireRole } from '../middlewares/auth.js';
import { tenantGuard } from '../middlewares/tenant.js';

const router = Router();

// All timetable routes require authentication and institute tenant scoping
router.use(authenticate, tenantGuard);

// List slots (Student sees enrolled batch slots, Teacher sees their own, Admin sees all)
router.get('/', TimetableController.listSlots);

// Create timetable slot (Admin or Teacher)
router.post('/', requireRole(['ADMIN', 'TEACHER']), TimetableController.createSlot);

// Delete timetable slot (Admin or Teacher)
router.delete('/:id', requireRole(['ADMIN', 'TEACHER']), TimetableController.deleteSlot);

export default router;
