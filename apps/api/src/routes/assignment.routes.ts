import { Router } from 'express';
import { AssignmentController } from '../controllers/assignment.controller.js';
import { authenticate, requireRole } from '../middlewares/auth.js';
import { tenantGuard } from '../middlewares/tenant.js';

const router = Router();

router.use(authenticate, tenantGuard);

router.get('/', AssignmentController.listAssignments);
router.post('/', requireRole(['ADMIN', 'TEACHER']), AssignmentController.createAssignment);
router.get('/:id', AssignmentController.getAssignmentById);
router.post('/:id/submit', requireRole(['STUDENT']), AssignmentController.submitAssignment);
router.patch('/submissions/:submissionId/grade', requireRole(['ADMIN', 'TEACHER']), AssignmentController.gradeSubmission);

export default router;
