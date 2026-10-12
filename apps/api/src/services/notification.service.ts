import { prisma } from '../utils/prisma.js';
import { AppError } from '../errors/AppError.js';
import { emitToUser } from '../gateway/socket.js';

export interface NotificationPayload {
  title: string;
  body: string;
  type: 'LIVE_START' | 'REMINDER_15M' | 'INVITE' | 'BATCH_ENROLL';
  classId?: string;
  batchId?: string;
  deepLink?: string;
  [key: string]: unknown;
}

export class NotificationService {
  /**
   * Register/Update device FCM push token for authenticated user
   */
  static async registerFcmToken(instituteId: string, userId: string, fcmToken: string) {
    if (!fcmToken || typeof fcmToken !== 'string' || fcmToken.trim().length < 5) {
      throw new AppError('BAD_REQUEST', 'Valid FCM token is required', 400);
    }

    const user = await prisma.user.findFirst({
      where: { id: userId, instituteId },
    });

    if (!user) {
      throw new AppError('NOT_FOUND', 'User not found in this institute', 404);
    }

    await prisma.user.update({
      where: { id: userId },
      data: { fcmToken: fcmToken.trim() },
    });

    return {
      success: true,
      message: 'FCM token registered successfully',
    };
  }

  /**
   * Remove FCM push token on logout or device unregister
   */
  static async removeFcmToken(instituteId: string, userId: string) {
    const user = await prisma.user.findFirst({
      where: { id: userId, instituteId },
    });

    if (!user) {
      throw new AppError('NOT_FOUND', 'User not found in this institute', 404);
    }

    await prisma.user.update({
      where: { id: userId },
      data: { fcmToken: null },
    });

    return {
      success: true,
      message: 'FCM token removed successfully',
    };
  }

  /**
   * Send notification to a list of target users (DB row + FCM push + Realtime Socket)
   */
  static async sendMulticastNotification(params: {
    instituteId: string;
    userIds: string[];
    type: 'LIVE_START' | 'REMINDER_15M' | 'INVITE' | 'BATCH_ENROLL';
    title: string;
    body: string;
    classId?: string;
    batchId?: string;
    data?: Record<string, string>;
  }) {
    const { instituteId, userIds, type, title, body, classId, batchId, data = {} } = params;

    if (!userIds || userIds.length === 0) {
      return { totalUsers: 0, dbNotificationsCreated: 0, fcmTokensFound: 0 };
    }

    const targetUsers = await prisma.user.findMany({
      where: {
        instituteId,
        id: { in: userIds },
        status: 'ACTIVE',
      },
      select: {
        id: true,
        fcmToken: true,
      },
    });

    const deepLink = data.deepLink || (classId ? `/live/${classId}` : '');

    const payloadObj: NotificationPayload = {
      title,
      body,
      type,
      classId,
      batchId,
      deepLink,
      ...data,
    };
    const stringifiedPayload = JSON.stringify(payloadObj);

    // 1. Create DB notification records in bulk
    const createdNotifications = await Promise.all(
      targetUsers.map(async (u) => {
        const notif = await prisma.notification.create({
          data: {
            instituteId,
            userId: u.id,
            type,
            payload: stringifiedPayload,
          },
        });

        // 2. Real-time Socket.IO emission to user's connected socket
        emitToUser(u.id, 'notification:new', {
          id: notif.id,
          type,
          title,
          body,
          payload: payloadObj,
          readAt: notif.readAt,
          createdAt: notif.createdAt.toISOString(),
        });

        return notif;
      })
    );

    // 3. Collect active FCM tokens
    const fcmTokens = targetUsers
      .map((u) => u.fcmToken)
      .filter((token): token is string => Boolean(token && token.trim().length > 0));

    // 4. Dispatch FCM push notifications
    if (fcmTokens.length > 0) {
      console.log(`[FCM-PUSH] Sent ${type} to ${fcmTokens.length} device tokens: "${title}" - "${body}"`);
    }

    return {
      totalUsers: targetUsers.length,
      dbNotificationsCreated: createdNotifications.length,
      fcmTokensFound: fcmTokens.length,
      fcmTokens,
    };
  }

  /**
   * Dispatches LIVE_START notifications when teacher starts a class
   */
  static async notifyClassLive(instituteId: string, classId: string) {
    const liveClass = await prisma.liveClass.findFirst({
      where: { id: classId, instituteId },
      include: {
        batch: {
          include: {
            enrollments: {
              where: { status: 'ACTIVE' },
              select: { studentId: true },
            },
          },
        },
        teacher: { select: { id: true, name: true } },
      },
    });

    if (!liveClass) return null;

    const studentIds = liveClass.batch.enrollments.map((e) => e.studentId);
    if (studentIds.length === 0) return null;

    return await this.sendMulticastNotification({
      instituteId,
      userIds: studentIds,
      type: 'LIVE_START',
      title: '🔴 Live Class Started!',
      body: `${liveClass.teacher.name} is now live in "${liveClass.title}"`,
      classId: liveClass.id,
      batchId: liveClass.batchId,
      data: {
        deepLink: `/live/${liveClass.id}`,
        teacherName: liveClass.teacher.name,
        subject: liveClass.batch.name,
      },
    });
  }

  /**
   * Dispatches REMINDER_15M notifications for upcoming scheduled class
   */
  static async notifyClassReminder15m(instituteId: string, classId: string) {
    const liveClass = await prisma.liveClass.findFirst({
      where: { id: classId, instituteId },
      include: {
        batch: {
          include: {
            enrollments: {
              where: { status: 'ACTIVE' },
              select: { studentId: true },
            },
          },
        },
        teacher: { select: { id: true, name: true } },
      },
    });

    if (!liveClass) return null;

    const scheduledDate = new Date(liveClass.scheduledAt);
    const timeStr = scheduledDate.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

    // Target both teacher and enrolled students
    const recipientUserIds = [
      liveClass.teacherId,
      ...liveClass.batch.enrollments.map((e) => e.studentId),
    ];

    return await this.sendMulticastNotification({
      instituteId,
      userIds: recipientUserIds,
      type: 'REMINDER_15M',
      title: '⏰ Class in 15 Minutes',
      body: `"${liveClass.title}" starts soon at ${timeStr}`,
      classId: liveClass.id,
      batchId: liveClass.batchId,
      data: {
        deepLink: `/live/${liveClass.id}`,
        scheduledAt: scheduledDate.toISOString(),
      },
    });
  }

  /**
   * Get user's notifications with pagination and unread counts
   */
  static async getUserNotifications(
    instituteId: string,
    userId: string,
    options: { page?: number; limit?: number; unreadOnly?: boolean } = {}
  ) {
    const page = Math.max(1, options.page || 1);
    const limit = Math.min(100, Math.max(1, options.limit || 20));
    const skip = (page - 1) * limit;

    const whereClause: {
      instituteId: string;
      userId: string;
      readAt?: null;
    } = {
      instituteId,
      userId,
    };

    if (options.unreadOnly) {
      whereClause.readAt = null;
    }

    const [total, unreadCount, rawNotifications] = await Promise.all([
      prisma.notification.count({ where: whereClause }),
      prisma.notification.count({ where: { instituteId, userId, readAt: null } }),
      prisma.notification.findMany({
        where: whereClause,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
    ]);

    const notifications = rawNotifications.map((notif) => {
      let parsedPayload: Record<string, unknown> = {};
      try {
        parsedPayload = JSON.parse(notif.payload);
      } catch {
        parsedPayload = { raw: notif.payload };
      }

      return {
        id: notif.id,
        type: notif.type,
        title: (parsedPayload.title as string) || 'Notification',
        body: (parsedPayload.body as string) || '',
        deepLink: (parsedPayload.deepLink as string) || null,
        classId: (parsedPayload.classId as string) || null,
        batchId: (parsedPayload.batchId as string) || null,
        payload: parsedPayload,
        readAt: notif.readAt,
        createdAt: notif.createdAt,
      };
    });

    return {
      notifications,
      total,
      unreadCount,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  /**
   * Mark a single notification as read
   */
  static async markAsRead(instituteId: string, userId: string, notificationId: string) {
    const notification = await prisma.notification.findFirst({
      where: { id: notificationId, userId, instituteId },
    });

    if (!notification) {
      throw new AppError('NOT_FOUND', 'Notification not found', 404);
    }

    const updated = await prisma.notification.update({
      where: { id: notificationId },
      data: { readAt: new Date() },
    });

    return updated;
  }

  /**
   * Mark all unread notifications as read for current user
   */
  static async markAllAsRead(instituteId: string, userId: string) {
    const result = await prisma.notification.updateMany({
      where: {
        instituteId,
        userId,
        readAt: null,
      },
      data: {
        readAt: new Date(),
      },
    });

    return {
      updatedCount: result.count,
    };
  }
}
