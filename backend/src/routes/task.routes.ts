import { Router } from 'express';
import { TaskController } from '../controllers/task.controller';
import { authenticate } from '../middleware/auth.middleware';
import { validateBody, validateQuery } from '../middleware/validate.middleware';
import { createTaskSchema, taskQuerySchema, updateTaskSchema, updateTaskStatusSchema } from '../validators/task.validator';

const router = Router();

router.use(authenticate);

router.get('/', validateQuery(taskQuerySchema), TaskController.getTasks);
router.get('/:id', TaskController.getTaskById);
router.post('/', validateBody(createTaskSchema), TaskController.createTask);
router.patch('/:id', validateBody(updateTaskSchema), TaskController.updateTask);
router.patch('/:id/status', validateBody(updateTaskStatusSchema), TaskController.updateTaskStatus);
router.delete('/:id', TaskController.deleteTask);

export default router;

