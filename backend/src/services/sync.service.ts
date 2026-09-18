import { TaskStatus } from '@prisma/client';
import { prisma } from '../config/database';
import { BatchSyncInput, SyncOperationItem } from '../validators/sync.validator';
import { TaskService } from './task.service';
import { logger } from '../utils/logger';

export interface SyncResultItem {
  operationId: string;
  status: 'SYNCED' | 'CONFLICT' | 'FAILED';
  entityType: string;
  entityId: string;
  data?: any;
  error?: {
    code: string;
    message: string;
    details?: any;
  };
}

export class SyncService {
  static async processBatchSync(userId: string, input: BatchSyncInput): Promise<{ results: SyncResultItem[]; processedCount: number; conflictCount: number; failedCount: number }> {
    const results: SyncResultItem[] = [];
    let conflictCount = 0;
    let failedCount = 0;

    logger.info(`Starting batch sync for user ${userId} with ${input.operations.length} operations`);

    for (const op of input.operations) {
      try {
        const result = await this.processSingleOperation(userId, op);
        results.push(result);
        if (result.status === 'CONFLICT') conflictCount++;
        if (result.status === 'FAILED') failedCount++;
      } catch (err: any) {
        logger.error(`Failed to process sync operation ${op.id}`, { error: err.message, op });
        failedCount++;
        results.push({
          operationId: op.id,
          status: 'FAILED',
          entityType: op.entityType,
          entityId: op.entityId,
          error: {
            code: err.code || 'SYNC_PROCESSING_ERROR',
            message: err.message || 'Unknown error occurred while processing operation',
          },
        });
      }
    }

    logger.info(`Completed batch sync: ${results.length} processed, ${conflictCount} conflicts, ${failedCount} failures`);

    return {
      results,
      processedCount: results.length,
      conflictCount,
      failedCount,
    };
  }

  private static async processSingleOperation(userId: string, op: SyncOperationItem): Promise<SyncResultItem> {
    const { id: operationId, operationType, entityType, entityId, payload } = op;

    switch (entityType) {
      case 'TASK': {
        if (operationType === 'UPDATE') {
          const existing = await prisma.task.findUnique({ where: { id: entityId } });
          if (!existing) {
            return {
              operationId,
              status: 'FAILED',
              entityType,
              entityId,
              error: { code: 'TASK_NOT_FOUND', message: `Task ${entityId} not found on server` },
            };
          }

          // Optimistic Concurrency Check:
          const clientVersion = payload.version;
          if (clientVersion !== undefined && clientVersion !== existing.version) {
            return {
              operationId,
              status: 'CONFLICT',
              entityType,
              entityId,
              data: existing,
              error: {
                code: 'CONFLICT',
                message: `Server version is ${existing.version}, but client submitted version ${clientVersion}`,
                details: {
                  serverVersion: existing.version,
                  clientVersion,
                  serverStatus: existing.status,
                },
              },
            };
          }

          // Check status transition if status is being updated
          if (payload.status && payload.status !== existing.status) {
            try {
              TaskService.validateTransition(existing.status, payload.status as TaskStatus);
            } catch (transitionErr: any) {
              return {
                operationId,
                status: 'FAILED',
                entityType,
                entityId,
                error: {
                  code: 'INVALID_STATUS_TRANSITION',
                  message: transitionErr.message,
                },
              };
            }
          }

          // Apply update
          const updated = await prisma.task.update({
            where: { id: entityId },
            data: {
              ...(payload.status ? { status: payload.status as TaskStatus } : {}),
              ...(payload.description ? { description: payload.description } : {}),
              ...(payload.title ? { title: payload.title } : {}),
              version: existing.version + 1,
            },
            include: {
              assignedTo: { select: { id: true, name: true, email: true } },
            },
          });

          return {
            operationId,
            status: 'SYNCED',
            entityType,
            entityId,
            data: updated,
          };
        }
        break;
      }

      case 'NOTE': {
        if (operationType === 'CREATE') {
          const taskId = payload.taskId || entityId;
          const task = await prisma.task.findUnique({ where: { id: taskId } });
          if (!task) {
            return {
              operationId,
              status: 'FAILED',
              entityType,
              entityId,
              error: { code: 'TASK_NOT_FOUND', message: `Target task ${taskId} not found` },
            };
          }

          const note = await prisma.taskNote.create({
            data: {
              taskId,
              userId,
              content: payload.content || '',
              ...(payload.createdAt ? { createdAt: new Date(payload.createdAt) } : {}),
            },
            include: { user: { select: { id: true, name: true } } },
          });

          return {
            operationId,
            status: 'SYNCED',
            entityType,
            entityId: note.id,
            data: note,
          };
        }
        break;
      }

      case 'LOCATION': {
        if (operationType === 'CREATE') {
          const taskId = payload.taskId;
          const location = await prisma.location.create({
            data: {
              taskId: taskId || null,
              userId,
              latitude: Number(payload.latitude),
              longitude: Number(payload.longitude),
              accuracy: Number(payload.accuracy || 0),
              timestamp: payload.timestamp ? new Date(payload.timestamp) : new Date(),
            },
          });

          return {
            operationId,
            status: 'SYNCED',
            entityType,
            entityId: location.id,
            data: location,
          };
        }
        break;
      }

      case 'PHOTO': {
        if (operationType === 'CREATE') {
          const taskId = payload.taskId || entityId;
          const photo = await prisma.taskPhoto.create({
            data: {
              taskId,
              userId,
              url: payload.url || '',
              type: payload.type || 'ATTACHMENT',
            },
          });

          return {
            operationId,
            status: 'SYNCED',
            entityType,
            entityId: photo.id,
            data: photo,
          };
        }
        break;
      }
    }

    return {
      operationId,
      status: 'FAILED',
      entityType,
      entityId,
      error: {
        code: 'UNSUPPORTED_OPERATION',
        message: `Unsupported operation ${operationType} on ${entityType}`,
      },
    };
  }
}

