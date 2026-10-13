import { Router } from 'express';
import authRoutes from './auth.routes.js';
import inviteRoutes from './invite.routes.js';
import adminRoutes from './admin.routes.js';
import batchRoutes from './batch.routes.js';
import timetableRoutes from './timetable.routes.js';
import liveclassRoutes from './liveclass.routes.js';
import deviceRoutes from './device.routes.js';
import notificationRoutes from './notification.routes.js';
import recordingRoutes from './recording.routes.js';
import attendanceRoutes from './attendance.routes.js';
import assignmentRoutes from './assignment.routes.js';
import testRoutes from './test.routes.js';
import feeRoutes from './fee.routes.js';
import materialRoutes from './material.routes.js';
import instituteContentRoutes from './institute_content.routes.js';
import storeRoutes from './store.routes.js';

const router = Router();

router.get('/health', (_req, res) => {
  res.json({
    status: 'ok',
    service: 'Classora 2.0 API & Realtime Gateway',
    version: '2.0.0',
    timestamp: new Date().toISOString(),
  });
});

router.use('/v1/auth', authRoutes);
router.use('/v1/invites', inviteRoutes);
router.use('/v1/admin', adminRoutes);
router.use('/v1/batches', batchRoutes);
router.use('/v1/timetable', timetableRoutes);
router.use('/v1/classes', liveclassRoutes);
router.use('/v1/devices', deviceRoutes);
router.use('/v1/notifications', notificationRoutes);
router.use('/v1/recordings', recordingRoutes);
router.use('/v1/attendance', attendanceRoutes);
router.use('/v1/assignments', assignmentRoutes);
router.use('/v1/tests', testRoutes);
router.use('/v1/fees', feeRoutes);
router.use('/v1/materials', materialRoutes);
router.use('/v1/institute', instituteContentRoutes);
router.use('/v1/store', storeRoutes);

export default router;

