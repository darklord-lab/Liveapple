import { prisma } from '../utils/prisma.js';

export interface AuditLogParams {
  instituteId: string;
  actorId: string;
  action: string;
  entity: string;
  meta?: Record<string, unknown>;
}

export async function logAudit(params: AuditLogParams): Promise<void> {
  try {
    await prisma.auditLog.create({
      data: {
        instituteId: params.instituteId,
        actorId: params.actorId,
        action: params.action,
        entity: params.entity,
        meta: params.meta ? JSON.stringify(params.meta) : null,
      },
    });
  } catch (error) {
    console.error('[Audit Log Failure]:', error);
  }
}
