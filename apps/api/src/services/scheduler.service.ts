import { prisma } from '../utils/prisma.js';
import { NotificationService } from './notification.service.js';

let schedulerInterval: NodeJS.Timeout | null = null;

export class SchedulerService {
  /**
   * Scan for classes starting in ~15 minutes and dispatch reminder push notifications
   */
  static async checkAndSendUpcomingClassReminders(referenceTime: Date = new Date()) {
    // Window: 10 minutes to 20 minutes from reference time (center is 15 minutes)
    const windowStart = new Date(referenceTime.getTime() + 10 * 60 * 1000);
    const windowEnd = new Date(referenceTime.getTime() + 20 * 60 * 1000);

    const upcomingClasses = await prisma.liveClass.findMany({
      where: {
        status: 'SCHEDULED',
        scheduledAt: {
          gte: windowStart,
          lte: windowEnd,
        },
      },
      include: {
        batch: true,
        teacher: true,
      },
    });

    let remindersSent = 0;

    for (const liveClass of upcomingClasses) {
      // Check if a 15m reminder notification was already created for this class
      const existingReminder = await prisma.notification.findFirst({
        where: {
          instituteId: liveClass.instituteId,
          type: 'REMINDER_15M',
          payload: {
            contains: liveClass.id,
          },
        },
      });

      if (!existingReminder) {
        await NotificationService.notifyClassReminder15m(liveClass.instituteId, liveClass.id);
        remindersSent++;
      }
    }

    return {
      upcomingCount: upcomingClasses.length,
      remindersSent,
    };
  }

  /**
   * Start recurring background scheduler
   */
  static startReminderScheduler(intervalMs = 60000) {
    if (schedulerInterval) {
      clearInterval(schedulerInterval);
    }

    console.log(`[SCHEDULER] 15-Minute Class Reminder service started (interval: ${intervalMs}ms)`);

    schedulerInterval = setInterval(() => {
      SchedulerService.checkAndSendUpcomingClassReminders().catch((err) => {
        console.error('[SCHEDULER-ERROR] Error checking class reminders:', err);
      });
    }, intervalMs);

    // Run initial scan immediately
    SchedulerService.checkAndSendUpcomingClassReminders().catch((err) => {
      console.error('[SCHEDULER-ERROR] Initial reminder scan failed:', err);
    });
  }

  /**
   * Stop recurring background scheduler (for clean shutdown / tests)
   */
  static stopReminderScheduler() {
    if (schedulerInterval) {
      clearInterval(schedulerInterval);
      schedulerInterval = null;
      console.log('[SCHEDULER] Class reminder scheduler stopped');
    }
  }
}
