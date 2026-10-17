import { Router } from 'express';
import multer from 'multer';
import { MaterialController } from '../controllers/material.controller.js';
import { authenticate, requireRole } from '../middlewares/auth.js';
import { tenantGuard } from '../middlewares/tenant.js';

const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 25 * 1024 * 1024, // 25 MB max limit
  },
});

const router = Router();

router.use(authenticate, tenantGuard);

// 1. Download/view specific material
router.get('/:id/download', MaterialController.downloadMaterial);

// 2. Delete specific material
router.delete('/:id', requireRole(['ADMIN', 'TEACHER']), MaterialController.deleteMaterial);

// 3. Delete specific folder
router.delete('/folders/:id', requireRole(['ADMIN', 'TEACHER']), MaterialController.deleteFolder);

export default router;
export { upload };
