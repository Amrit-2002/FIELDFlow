import { Response, NextFunction } from 'express';
import { PhotoType } from '@prisma/client';
import { PhotoService } from '../services/photo.service';
import { sendSuccess } from '../utils/response';
import { AuthenticatedRequest } from '../middleware/auth.middleware';
import { AppError } from '../utils/app-error';

export class PhotoController {
  static async getPhotos(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const photos = await PhotoService.getPhotosByTaskId(req.params.id);
      return sendSuccess(res, photos, 'Task photos retrieved');
    } catch (error) {
      next(error);
    }
  }

  static async uploadPhoto(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      let photoUrl = '';
      const photoType: PhotoType = (req.body.type as PhotoType) || PhotoType.ATTACHMENT;

      if (req.file) {
        photoUrl = `/uploads/${req.file.filename}`;
      } else if (req.body.url) {
        photoUrl = req.body.url;
      } else {
        throw AppError.badRequest('Photo file or URL is required');
      }

      const photo = await PhotoService.savePhoto(req.params.id, req.user!.userId, photoUrl, photoType);
      return sendSuccess(res, photo, 'Photo saved successfully', 201);
    } catch (error) {
      next(error);
    }
  }
}

