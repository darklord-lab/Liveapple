import { Router } from 'express';
import { NotificationController } from '../controllers/notification.controller.js';
import { authenticate } from '../middlewares/auth.js';
import { tenantGuard } from '../middlewares/tenant.js';

const router = Router();

// All notification routes require authentication & tenant context
router.use(authenticate, tenantGuard);

router.get('/', NotificationController.listNotifications);
router.patch('/read-all', NotificationController.markAllAsRead);
router.patch('/:id/read', NotificationController.markAsRead);

export default router;
