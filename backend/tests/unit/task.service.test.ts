import { TaskStatus } from '@prisma/client';
import { TaskService } from '../../src/services/task.service';
import { AppError } from '../../src/utils/app-error';

describe('TaskService - Status Transition Unit Tests', () => {
  it('should allow ASSIGNED -> ACCEPTED', () => {
    expect(() => TaskService.validateTransition(TaskStatus.ASSIGNED, TaskStatus.ACCEPTED)).not.toThrow();
  });

  it('should allow ACCEPTED -> IN_PROGRESS', () => {
    expect(() => TaskService.validateTransition(TaskStatus.ACCEPTED, TaskStatus.IN_PROGRESS)).not.toThrow();
  });

  it('should allow IN_PROGRESS -> COMPLETED', () => {
    expect(() => TaskService.validateTransition(TaskStatus.IN_PROGRESS, TaskStatus.COMPLETED)).not.toThrow();
  });

  it('should allow cancelling from ASSIGNED, ACCEPTED, or IN_PROGRESS', () => {
    expect(() => TaskService.validateTransition(TaskStatus.ASSIGNED, TaskStatus.CANCELLED)).not.toThrow();
    expect(() => TaskService.validateTransition(TaskStatus.ACCEPTED, TaskStatus.CANCELLED)).not.toThrow();
    expect(() => TaskService.validateTransition(TaskStatus.IN_PROGRESS, TaskStatus.CANCELLED)).not.toThrow();
  });

  it('should reject invalid transition ASSIGNED -> COMPLETED with AppError', () => {
    expect(() => TaskService.validateTransition(TaskStatus.ASSIGNED, TaskStatus.COMPLETED)).toThrow(AppError);
    try {
      TaskService.validateTransition(TaskStatus.ASSIGNED, TaskStatus.COMPLETED);
    } catch (err: any) {
      expect(err.code).toBe('INVALID_STATUS_TRANSITION');
      expect(err.statusCode).toBe(400);
    }
  });

  it('should reject transitions from terminal state COMPLETED', () => {
    expect(() => TaskService.validateTransition(TaskStatus.COMPLETED, TaskStatus.IN_PROGRESS)).toThrow(AppError);
    expect(() => TaskService.validateTransition(TaskStatus.COMPLETED, TaskStatus.ASSIGNED)).toThrow(AppError);
  });

  it('should reject transitions from terminal state CANCELLED', () => {
    expect(() => TaskService.validateTransition(TaskStatus.CANCELLED, TaskStatus.ASSIGNED)).toThrow(AppError);
    expect(() => TaskService.validateTransition(TaskStatus.CANCELLED, TaskStatus.IN_PROGRESS)).toThrow(AppError);
  });

  it('should allow transition to the same status without throwing', () => {
    expect(() => TaskService.validateTransition(TaskStatus.IN_PROGRESS, TaskStatus.IN_PROGRESS)).not.toThrow();
  });
});

