import { Router } from 'express';
import { InviteController } from '../controllers/invite.controller.js';
import { authenticate, requireRole } from '../middlewares/auth.js';
import { tenantGuard } from '../middlewares/tenant.js';

const router = Router();

// Public validation endpoint for invite codes (used by Flutter before accepting)
router.get('/validate/:code', InviteController.validateInvite);

// Authenticated endpoints
router.post(
  '/',
  authenticate,
  tenantGuard,
  requireRole('ADMIN', 'TEACHER'),
  InviteController.createInvite
);

router.get(
  '/',
  authenticate,
  tenantGuard,
  requireRole('ADMIN'),
  InviteController.listInvites
);

export default router;
