import { Router } from 'express';
import { AuthController } from '../controllers/auth.controller.js';
import { authenticate } from '../middlewares/auth.js';
import { authLimiter } from '../middlewares/rateLimiter.js';

const router = Router();

router.post('/login', authLimiter, AuthController.login);
router.post('/refresh', AuthController.refresh);
router.post('/logout', AuthController.logout);
router.post('/accept-invite', authLimiter, AuthController.acceptInvite);
router.get('/me', authenticate, AuthController.me);

export default router;
