import { TaskStatus, Priority, Prisma } from '@prisma/client';
import { prisma } from '../config/database';
import { AppError } from '../utils/app-error';
import { CreateTaskInput, TaskQueryInput, UpdateTaskInput, UpdateTaskStatusInput } from '../validators/task.validator';
import { logger } from '../utils/logger';

// Valid status transitions map
const VALID_TRANSITIONS: Record<TaskStatus, TaskStatus[]> = {
  ASSIGNED: [TaskStatus.ACCEPTED, TaskStatus.CANCELLED],
  ACCEPTED: [TaskStatus.IN_PROGRESS, TaskStatus.CANCELLED],
  IN_PROGRESS: [TaskStatus.COMPLETED, TaskStatus.CANCELLED],
  COMPLETED: [],
  CANCELLED: [],
};

export class TaskService {
  static validateTransition(currentStatus: TaskStatus, newStatus: TaskStatus): void {
    if (currentStatus === newStatus) return;

    const allowed = VALID_TRANSITIONS[currentStatus];
    if (!allowed || !allowed.includes(newStatus)) {
      throw AppError.badRequest(
        `Invalid status transition from ${currentStatus} to ${newStatus}. Allowed transitions: ${allowed?.join(', ') || 'None'}`,
        'INVALID_STATUS_TRANSITION'
      );
    }
  }

  static async getTasks(query: TaskQueryInput, currentUserId?: string, userRole?: string) {
    const { page = 1, limit = 20, status, priority, search, assignedToId } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.TaskWhereInput = {};

    // Filter by assigned user if not admin or if explicitly requested
    if (userRole === 'FIELD_WORKER' && currentUserId) {
      where.assignedToId = currentUserId;
    } else if (assignedToId) {
      where.assignedToId = assignedToId;
    }

    if (status) {
      where.status = status as TaskStatus;
    }

    if (priority) {
      where.priority = priority as Priority;
    }

    if (search && search.trim()) {
      const searchTerm = search.trim();
      where.OR = [
        { title: { contains: searchTerm, mode: 'insensitive' } },
        { description: { contains: searchTerm, mode: 'insensitive' } },
        { customerName: { contains: searchTerm, mode: 'insensitive' } },
        { address: { contains: searchTerm, mode: 'insensitive' } },
      ];
    }

    const [tasks, total] = await Promise.all([
      prisma.task.findMany({
        where,
        skip,
        take: limit,
        orderBy: [{ scheduledAt: 'asc' }, { createdAt: 'desc' }],
        include: {
          assignedTo: {
            select: { id: true, name: true, email: true },
          },
          _count: {
            select: { notes: true, photos: true, locations: true },
          },
        },
      }),
      prisma.task.count({ where }),
    ]);

    return {
      items: tasks,
      page,
      limit,
      total,
    };
  }

  static async getTaskById(id: string) {
    const task = await prisma.task.findUnique({
      where: { id },
      include: {
        assignedTo: {
          select: { id: true, name: true, email: true },
        },
        notes: {
          include: { user: { select: { id: true, name: true } } },
          orderBy: { createdAt: 'desc' },
        },
        photos: {
          orderBy: { createdAt: 'desc' },
        },
        locations: {
          orderBy: { timestamp: 'desc' },
          take: 5,
        },
      },
    });

    if (!task) {
      throw AppError.notFound(`Task with ID ${id} not found`, 'TASK_NOT_FOUND');
    }

    return task;
  }

  static async createTask(input: CreateTaskInput) {
    const task = await prisma.task.create({
      data: {
        title: input.title,
        description: input.description,
        customerName: input.customerName,
        customerPhone: input.customerPhone,
        address: input.address,
        latitude: input.latitude,
        longitude: input.longitude,
        priority: input.priority,
        scheduledAt: new Date(input.scheduledAt),
        assignedToId: input.assignedToId || null,
        version: 1,
      },
      include: {
        assignedTo: {
          select: { id: true, name: true, email: true },
        },
      },
    });

    logger.info('Task created successfully', { taskId: task.id, title: task.title });
    return task;
  }

  static async updateTask(id: string, input: UpdateTaskInput) {
    const existing = await prisma.task.findUnique({ where: { id } });
    if (!existing) {
      throw AppError.notFound(`Task with ID ${id} not found`, 'TASK_NOT_FOUND');
    }

    // Optimistic locking check if version was supplied
    if (input.version !== undefined && input.version !== existing.version) {
      logger.warn('Task version conflict on update', {
        taskId: id,
        expectedVersion: input.version,
        currentVersion: existing.version,
      });
      throw AppError.conflict('Task was modified by another user or process', 'CONFLICT', {
        serverTask: existing,
        expectedVersion: input.version,
        currentVersion: existing.version,
      });
    }

    const { version, scheduledAt, ...rest } = input;

    const updated = await prisma.task.update({
      where: { id },
      data: {
        ...rest,
        ...(scheduledAt ? { scheduledAt: new Date(scheduledAt) } : {}),
        version: existing.version + 1,
      },
      include: {
        assignedTo: { select: { id: true, name: true, email: true } },
      },
    });

    logger.info('Task updated successfully', { taskId: id, newVersion: updated.version });
    return updated;
  }

  static async updateTaskStatus(id: string, input: UpdateTaskStatusInput, userId?: string) {
    const existing = await prisma.task.findUnique({ where: { id } });
    if (!existing) {
      throw AppError.notFound(`Task with ID ${id} not found`, 'TASK_NOT_FOUND');
    }

    // 1. Validate status transition
    TaskService.validateTransition(existing.status, input.status);

    // 2. Optimistic Concurrency Version Check
    if (input.version !== existing.version) {
      logger.warn('Task status update conflict detected', {
        taskId: id,
        clientVersion: input.version,
        serverVersion: existing.version,
        attemptedStatus: input.status,
      });
      throw AppError.conflict('Task has been updated on the server. Please resolve conflict.', 'CONFLICT', {
        serverTask: existing,
        expectedVersion: input.version,
        currentVersion: existing.version,
      });
    }

    // 3. Update task status and increment version atomically
    const updated = await prisma.$transaction(async (tx) => {
      const task = await tx.task.update({
        where: { id },
        data: {
          status: input.status,
          version: existing.version + 1,
        },
        include: {
          assignedTo: { select: { id: true, name: true, email: true } },
        },
      });

      // Optionally record location if provided with status change
      if (input.latitude !== undefined && input.longitude !== undefined && userId) {
        await tx.location.create({
          data: {
            taskId: id,
            userId,
            latitude: input.latitude,
            longitude: input.longitude,
            accuracy: 0,
            timestamp: new Date(),
          },
        });
      }

      return task;
    });

    logger.info('Task status transitioned successfully', {
      taskId: id,
      from: existing.status,
      to: updated.status,
      newVersion: updated.version,
    });

    return updated;
  }

  static async deleteTask(id: string) {
    const existing = await prisma.task.findUnique({ where: { id } });
    if (!existing) {
      throw AppError.notFound(`Task with ID ${id} not found`, 'TASK_NOT_FOUND');
    }

    await prisma.task.delete({ where: { id } });
    logger.info('Task deleted successfully', { taskId: id });
    return { id };
  }
}
