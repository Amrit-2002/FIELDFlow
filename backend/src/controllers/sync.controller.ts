import { Response, NextFunction } from 'express';
import { SyncService } from '../services/sync.service';
import { sendSuccess } from '../utils/response';
import { AuthenticatedRequest } from '../middleware/auth.middleware';

export class SyncController {
  static async sync(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const summary = await SyncService.processBatchSync(req.user!.userId, req.body);
      return sendSuccess(res, summary, 'Sync operations processed successfully');
    } catch (error) {
      next(error);
    }
  }
}

