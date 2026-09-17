import { Router } from 'express';
import { LocationController } from '../controllers/location.controller';
import { authenticate } from '../middleware/auth.middleware';
import { validateBody } from '../middleware/validate.middleware';
import { recordLocationSchema } from '../validators/location.validator';

const router = Router({ mergeParams: true });

router.use(authenticate);

router.get('/', LocationController.getLocations);
router.post('/', validateBody(recordLocationSchema), LocationController.recordLocation);

export default router;
