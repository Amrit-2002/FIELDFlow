import { PhotoType } from '@prisma/client';
import { prisma } from '../config/database';
import { AppError } from '../utils/app-error';
import { logger } from '../utils/logger';

export class PhotoService {
  static async getPhotosByTaskId(taskId: string) {
    const task = await prisma.task.findUnique({ where: { id: taskId } });
    if (!task) {
      throw AppError.notFound(`Task with ID ${taskId} not found`, 'TASK_NOT_FOUND');
    }

    return prisma.taskPhoto.findMany({
      where: { taskId },
      orderBy: { createdAt: 'desc' },
      include: {
        user: { select: { id: true, name: true } },
      },
    });
  }

  static async savePhoto(taskId: string, userId: string, url: string, type: PhotoType = PhotoType.ATTACHMENT) {
    const task = await prisma.task.findUnique({ where: { id: taskId } });
    if (!task) {
      throw AppError.notFound(`Task with ID ${taskId} not found`, 'TASK_NOT_FOUND');
    }

    const photo = await prisma.taskPhoto.create({
      data: {
        taskId,
        userId,
        url,
        type,
      },
      include: {
        user: { select: { id: true, name: true } },
      },
    });

    logger.info('Task photo uploaded', { taskId, photoId: photo.id, type });
    return photo;
  }
}

