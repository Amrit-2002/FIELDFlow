import { Router } from 'express';
import { SyncController } from '../controllers/sync.controller';
import { authenticate } from '../middleware/auth.middleware';
import { validateBody } from '../middleware/validate.middleware';
import { batchSyncSchema } from '../validators/sync.validator';

const router = Router();

router.use(authenticate);

router.post('/', validateBody(batchSyncSchema), SyncController.sync);

export default router;
