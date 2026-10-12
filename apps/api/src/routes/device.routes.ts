import { Router } from 'express';
import { DeviceController } from '../controllers/device.controller.js';
import { authenticate } from '../middlewares/auth.js';
import { tenantGuard } from '../middlewares/tenant.js';

const router = Router();

// All device routes require authentication & tenant context
router.use(authenticate, tenantGuard);

router.post('/fcm-token', DeviceController.registerFcmToken);
router.delete('/fcm-token', DeviceController.removeFcmToken);

export default router;
