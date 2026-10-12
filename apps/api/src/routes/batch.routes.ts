import { Router } from 'express';
import { BatchController } from '../controllers/batch.controller.js';
import { authenticate, requireRole } from '../middlewares/auth.js';
import { tenantGuard } from '../middlewares/tenant.js';

const router = Router();

// All batch routes require authentication and institute tenant scoping
router.use(authenticate, tenantGuard);

// Student join batch with code
router.post('/join', requireRole(['STUDENT']), BatchController.joinBatch);

// List batches (Students see their enrolled batches, Teachers see their own, Admins see all)
router.get('/', BatchController.listBatches);

// Create batch (Admin or Teacher)
router.post('/', requireRole(['ADMIN', 'TEACHER']), BatchController.createBatch);

// Get single batch details
router.get('/:id', BatchController.getBatchById);

// Update batch
router.patch('/:id', requireRole(['ADMIN', 'TEACHER']), BatchController.updateBatch);

// Delete batch
router.delete('/:id', requireRole(['ADMIN', 'TEACHER']), BatchController.deleteBatch);

// Regenerate join code
router.post('/:id/regenerate-code', requireRole(['ADMIN', 'TEACHER']), BatchController.regenerateJoinCode);

// Batch student management
router.get('/:id/students', requireRole(['ADMIN', 'TEACHER']), BatchController.listStudents);
router.post('/:id/students', requireRole(['ADMIN', 'TEACHER']), BatchController.addStudent);
router.post('/:id/students/bulk', requireRole(['ADMIN', 'TEACHER']), BatchController.bulkEnroll);
router.patch('/:id/students/:enrollmentId/status', requireRole(['ADMIN', 'TEACHER']), BatchController.updateEnrollmentStatus);

export default router;
