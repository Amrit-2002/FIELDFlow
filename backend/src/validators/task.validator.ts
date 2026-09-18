import { z } from 'zod';

export const taskStatusEnum = z.enum(['ASSIGNED', 'ACCEPTED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED']);
export const priorityEnum = z.enum(['LOW', 'MEDIUM', 'HIGH', 'URGENT']);

export const createTaskSchema = z.object({
  title: z.string().min(3, 'Title must be at least 3 characters'),
  description: z.string().min(5, 'Description must be at least 5 characters'),
  customerName: z.string().min(2, 'Customer name is required'),
  customerPhone: z.string().min(5, 'Valid customer phone is required'),
  address: z.string().min(5, 'Address is required'),
  latitude: z.number(),
  longitude: z.number(),
  priority: priorityEnum.default('MEDIUM'),
  scheduledAt: z.string().datetime({ message: 'Valid scheduledAt ISO date is required' }).or(z.string()),
  assignedToId: z.string().uuid().optional().nullable(),
});

export const updateTaskSchema = createTaskSchema.partial().extend({
  version: z.number().int().positive().optional(),
});

export const updateTaskStatusSchema = z.object({
  status: taskStatusEnum,
  version: z.number().int().positive({ message: 'Current version is required for optimistic concurrency' }),
  latitude: z.number().optional(),
  longitude: z.number().optional(),
});

export const taskQuerySchema = z.object({
  page: z.string().optional().transform((val) => (val ? Math.max(1, parseInt(val, 10)) : 1)),
  limit: z.string().optional().transform((val) => (val ? Math.min(100, Math.max(1, parseInt(val, 10))) : 20)),
  status: taskStatusEnum.optional(),
  priority: priorityEnum.optional(),
  search: z.string().optional(),
  assignedToId: z.string().optional(),
});

export type CreateTaskInput = z.infer<typeof createTaskSchema>;
export type UpdateTaskInput = z.infer<typeof updateTaskSchema>;
export type UpdateTaskStatusInput = z.infer<typeof updateTaskStatusSchema>;
export type TaskQueryInput = z.infer<typeof taskQuerySchema>;

