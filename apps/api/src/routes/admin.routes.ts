import { Router } from 'express';
import { AdminController } from '../controllers/admin.controller.js';
import { authenticate, requireRole } from '../middlewares/auth.js';
import { tenantGuard } from '../middlewares/tenant.js';

const router = Router();

// All admin routes require ADMIN role and institute tenant scoping
router.use(authenticate, tenantGuard, requireRole('ADMIN'));

// Teachers CRUD & Management
router.get('/teachers', AdminController.listTeachers);
router.post('/teachers', AdminController.addTeacher);
router.patch('/teachers/:id', AdminController.updateTeacher);
router.delete('/teachers/:id', AdminController.deleteTeacher);
router.post('/teachers/bulk', AdminController.bulkOnboard);
router.patch('/teachers/:id/status', AdminController.updateTeacherStatus);

// Students Directory & Management
router.get('/students', AdminController.listStudents);
router.post('/students', AdminController.addStudent);

export default router;
