import { Router } from 'express';
import { AttendanceController } from '../controllers/attendance.controller.js';
import { authenticate, requireRole } from '../middlewares/auth.js';
import { tenantGuard } from '../middlewares/tenant.js';

const router = Router();

router.use(authenticate, tenantGuard);

router.post('/join', AttendanceController.recordJoin);
router.post('/leave', AttendanceController.recordLeave);
router.get('/my-summary', AttendanceController.getMySummary);
router.get('/class/:classId', requireRole(['ADMIN', 'TEACHER']), AttendanceController.getClassRoster);

export default router;
