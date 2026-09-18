import { Router } from 'express';
import authRoutes from './auth.routes';
import taskRoutes from './task.routes';
import noteRoutes from './note.routes';
import photoRoutes from './photo.routes';
import locationRoutes from './location.routes';
import syncRoutes from './sync.routes';
import notificationRoutes from './notification.routes';
import healthRoutes from './health.routes';

const router = Router();

router.use('/auth', authRoutes);
router.use('/tasks', taskRoutes);
router.use('/tasks/:id/notes', noteRoutes);
router.use('/tasks/:id/photos', photoRoutes);
router.use('/tasks/:id/locations', locationRoutes);
router.use('/tasks/:id/location', locationRoutes); // alias for singular
router.use('/sync', syncRoutes);
router.use('/notifications', notificationRoutes);
router.use('/health', healthRoutes);

export default router;

