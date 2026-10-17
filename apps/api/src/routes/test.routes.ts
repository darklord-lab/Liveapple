import { Router } from 'express';
import { TestController } from '../controllers/test.controller.js';
import { authenticate, requireRole } from '../middlewares/auth.js';
import { tenantGuard } from '../middlewares/tenant.js';

const router = Router();

// Public: View shared score card & deep link preview (no login required)
router.get('/share/:attemptId', TestController.getSharedScore);

router.use(authenticate, tenantGuard);

router.get('/', TestController.listTests);
router.post('/', requireRole(['ADMIN', 'TEACHER']), TestController.createTest);
router.get('/:id', TestController.getTestById);
router.post('/:id/start', requireRole(['STUDENT']), TestController.startAttempt);
router.post('/:id/submit', requireRole(['STUDENT']), TestController.submitAttempt);
router.get('/:id/result', TestController.getTestResult);

export default router;
