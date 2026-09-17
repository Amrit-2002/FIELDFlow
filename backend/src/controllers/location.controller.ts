import { Response, NextFunction } from 'express';
import { LocationService } from '../services/location.service';
import { sendSuccess } from '../utils/response';
import { AuthenticatedRequest } from '../middleware/auth.middleware';

export class LocationController {
  static async recordLocation(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const location = await LocationService.recordLocation(req.params.id, req.user!.userId, req.body);
      return sendSuccess(res, location, 'Location recorded successfully', 201);
    } catch (error) {
      next(error);
    }
  }

  static async getLocations(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const locations = await LocationService.getLocationsByTaskId(req.params.id);
      return sendSuccess(res, locations, 'Task locations retrieved');
    } catch (error) {
      next(error);
    }
  }
}
