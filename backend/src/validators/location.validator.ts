import { z } from 'zod';

export const recordLocationSchema = z.object({
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
  accuracy: z.number().default(0),
  timestamp: z.string().datetime().optional(),
});

export type RecordLocationInput = z.infer<typeof recordLocationSchema>;
