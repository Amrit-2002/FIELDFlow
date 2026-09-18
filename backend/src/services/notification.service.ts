import { prisma } from '../config/database';
import { AppError } from '../utils/app-error';

export class NotificationService {
  static async getNotificationsByUserId(userId: string) {
    return prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  static async markAsRead(id: string, userId: string) {
    const notification = await prisma.notification.findUnique({ where: { id } });
    if (!notification) {
      throw AppError.notFound(`Notification with ID ${id} not found`, 'NOTIFICATION_NOT_FOUND');
    }

    if (notification.userId !== userId) {
      throw AppError.forbidden('Access denied');
    }

    return prisma.notification.update({
      where: { id },
      data: { read: true },
    });
  }

  static async createNotification(userId: string, title: string, body: string, type: string = 'SYSTEM') {
    return prisma.notification.create({
      data: {
        userId,
        title,
        body,
        type,
        read: false,
      },
    });
  }
}

