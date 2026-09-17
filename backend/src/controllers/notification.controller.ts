import { Response, NextFunction } from 'express';
import { NotificationService } from '../services/notification.service';
import { sendSuccess } from '../utils/response';
import { AuthenticatedRequest } from '../middleware/auth.middleware';

export class NotificationController {
  static async getNotifications(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const notifications = await NotificationService.getNotificationsByUserId(req.user!.userId);
      return sendSuccess(res, notifications, 'Notifications retrieved');
    } catch (error) {
      next(error);
    }
  }

  static async markAsRead(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const updated = await NotificationService.markAsRead(req.params.id, req.user!.userId);
      return sendSuccess(res, updated, 'Notification marked as read');
    } catch (error) {
      next(error);
    }
  }
}
