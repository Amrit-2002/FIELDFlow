import { Router } from 'express';
import { PhotoController } from '../controllers/photo.controller';
import { authenticate } from '../middleware/auth.middleware';
import { upload } from '../middleware/upload.middleware';

const router = Router({ mergeParams: true });

router.use(authenticate);

router.get('/', PhotoController.getPhotos);
router.post('/', upload.single('photo'), PhotoController.uploadPhoto);

export default router;
