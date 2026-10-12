import { Router } from 'express';
import { RecordingController } from '../controllers/recording.controller.js';
import { authenticate, requireRole } from '../middlewares/auth.js';
import { tenantGuard } from '../middlewares/tenant.js';

const router = Router();

router.use(authenticate, tenantGuard);

router.get('/', RecordingController.listRecordings);
router.post('/', requireRole(['ADMIN', 'TEACHER']), RecordingController.saveRecording);
router.get('/:id', RecordingController.getRecordingById);

export default router;
