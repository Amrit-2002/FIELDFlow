import { z } from 'zod';

export const syncOperationSchema = z.object({
  id: z.string(),
  operationType: z.enum(['CREATE', 'UPDATE', 'DELETE']),
  entityType: z.enum(['TASK', 'NOTE', 'PHOTO', 'LOCATION']),
  entityId: z.string(),
  payload: z.record(z.any()),
  clientTimestamp: z.string().optional(),
});

export const batchSyncSchema = z.object({
  operations: z.array(syncOperationSchema).min(1, 'At least one sync operation must be provided'),
});

export type SyncOperationItem = z.infer<typeof syncOperationSchema>;
export type BatchSyncInput = z.infer<typeof batchSyncSchema>;

