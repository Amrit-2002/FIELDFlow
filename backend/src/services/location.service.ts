import { prisma } from '../config/database';
import { AppError } from '../utils/app-error';
import { RecordLocationInput } from '../validators/location.validator';
import { logger } from '../utils/logger';

export class LocationService {
  static async recordLocation(taskId: string, userId: string, input: RecordLocationInput) {
    const task = await prisma.task.findUnique({ where: { id: taskId } });
    if (!task) {
      throw AppError.notFound(`Task with ID ${taskId} not found`, 'TASK_NOT_FOUND');
    }

    const location = await prisma.location.create({
      data: {
        taskId,
        userId,
        latitude: input.latitude,
        longitude: input.longitude,
        accuracy: input.accuracy || 0,
        timestamp: input.timestamp ? new Date(input.timestamp) : new Date(),
      },
    });

    logger.info('Technician location recorded', { taskId, userId, latitude: input.latitude, longitude: input.longitude });
    return location;
  }

  static async getLocationsByTaskId(taskId: string) {
    const task = await prisma.task.findUnique({ where: { id: taskId } });
    if (!task) {
      throw AppError.notFound(`Task with ID ${taskId} not found`, 'TASK_NOT_FOUND');
    }

    return prisma.location.findMany({
      where: { taskId },
      orderBy: { timestamp: 'desc' },
      include: {
        user: { select: { id: true, name: true } },
      },
    });
  }
}
