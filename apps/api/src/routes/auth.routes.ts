import { Router } from 'express';
import multer from 'multer';
import { AuthController } from '../controllers/auth.controller.js';
import { authenticate } from '../middlewares/auth.js';
import { authLimiter, uploadLimiter } from '../middlewares/rateLimiter.js';

const avatarUpload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB max avatar size
  },
});

const router = Router();

router.post('/login', authLimiter, AuthController.login);
router.post('/refresh', AuthController.refresh);
router.post('/logout', AuthController.logout);
router.post('/accept-invite', authLimiter, AuthController.acceptInvite);
router.get('/me', authenticate, AuthController.me);

// Profile and Avatar management (Stage 4.2)
router.patch('/profile', authenticate, AuthController.updateProfile);
router.post('/avatar', authenticate, uploadLimiter, avatarUpload.single('avatar'), AuthController.uploadAvatar);
router.get('/avatar/:key', AuthController.getAvatar);

export default router;
