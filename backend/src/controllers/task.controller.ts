import { Response, NextFunction } from 'express';
import { TaskService } from '../services/task.service';
import { sendSuccess, sendPaginated } from '../utils/response';
import { AuthenticatedRequest } from '../middleware/auth.middleware';

export class TaskController {
  static async getTasks(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const result = await TaskService.getTasks(req.query as any, req.user?.userId, req.user?.role);
      return sendPaginated(res, result.items, result.page, result.limit, result.total, 'Tasks retrieved successfully');
    } catch (error) {
      next(error);
    }
  }

  static async getTaskById(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const task = await TaskService.getTaskById(req.params.id);
      return sendSuccess(res, task, 'Task details retrieved successfully');
    } catch (error) {
      next(error);
    }
  }

  static async createTask(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const task = await TaskService.createTask(req.body);
      return sendSuccess(res, task, 'Task created successfully', 201);
    } catch (error) {
      next(error);
    }
  }

  static async updateTask(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const task = await TaskService.updateTask(req.params.id, req.body);
      return sendSuccess(res, task, 'Task updated successfully');
    } catch (error) {
      next(error);
    }
  }

  static async updateTaskStatus(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const task = await TaskService.updateTaskStatus(req.params.id, req.body, req.user?.userId);
      return sendSuccess(res, task, 'Task status updated successfully');
    } catch (error) {
      next(error);
    }
  }

  static async deleteTask(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const result = await TaskService.deleteTask(req.params.id);
      return sendSuccess(res, result, 'Task deleted successfully');
    } catch (error) {
      next(error);
    }
  }
}

