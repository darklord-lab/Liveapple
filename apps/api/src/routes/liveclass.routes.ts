import { Router } from 'express';
import { LiveClassController } from '../controllers/liveclass.controller.js';
import { authenticate, requireRole } from '../middlewares/auth.js';
import { tenantGuard } from '../middlewares/tenant.js';

const router = Router();

// All class routes require authentication and institute tenant scoping
router.use(authenticate, tenantGuard);

// List classes
router.get('/', LiveClassController.listClasses);

// Create single scheduled class (Admin or Teacher)
router.post('/', requireRole(['ADMIN', 'TEACHER']), LiveClassController.createClass);

// Auto-generate upcoming classes from recurring timetable slots (Admin or Teacher)
router.post('/generate-upcoming', requireRole(['ADMIN', 'TEACHER']), LiveClassController.generateUpcoming);

// Get single class details
router.get('/:id', LiveClassController.getClassById);

// Teacher starts live class
router.post('/:id/start', requireRole(['ADMIN', 'TEACHER']), LiveClassController.startClass);

// Generate signed LiveKit token to join room (Teacher, Admin, or enrolled Student)
router.post('/:id/token', LiveClassController.getToken);

// Teacher ends live class
router.post('/:id/end', requireRole(['ADMIN', 'TEACHER']), LiveClassController.endClass);

// Host controls
router.post('/:id/host/mute-all', requireRole(['ADMIN', 'TEACHER']), LiveClassController.muteAll);
router.post('/:id/host/remove-participant', requireRole(['ADMIN', 'TEACHER']), LiveClassController.removeParticipant);

export default router;
