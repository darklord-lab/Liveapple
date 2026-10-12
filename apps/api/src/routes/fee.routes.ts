import { Router } from 'express';
import { FeeController } from '../controllers/fee.controller.js';
import { authenticate, requireRole } from '../middlewares/auth.js';
import { tenantGuard } from '../middlewares/tenant.js';

const router = Router();

router.use(authenticate, tenantGuard);

router.get('/plans', FeeController.listFeePlans);
router.post('/plans', requireRole(['ADMIN']), FeeController.createFeePlan);
router.post('/pay', requireRole(['STUDENT']), FeeController.processPayment);
router.get('/my-dues', requireRole(['STUDENT']), FeeController.getMyDues);
router.get('/reports', requireRole(['ADMIN']), FeeController.getFinancialReport);

export default router;
