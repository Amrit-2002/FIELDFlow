import request from 'supertest';
import { createApp } from '../src/app';
import { prisma } from '../src/config/database';
import bcrypt from 'bcryptjs';

const app = createApp();

describe('Sync Engine Batch Processing', () => {
  let authToken: string;
  let testUserId: string;
  let testTaskId: string;

  beforeAll(async () => {
    const passwordHash = await bcrypt.hash('password123', 10);
    const user = await prisma.user.create({
      data: {
        name: 'Sync Engine Tech',
        email: `tech_sync_${Date.now()}@example.com`,
        passwordHash,
        role: 'FIELD_WORKER',
      },
    });
    testUserId = user.id;

    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: user.email, password: 'password123' });
    authToken = loginRes.body.data.accessToken;

    const task = await prisma.task.create({
      data: {
        title: 'Roof Chiller Sensor Calibration',
        description: 'Testing sync queue with multiple offline actions',
        customerName: 'Aero Labs',
        customerPhone: '+1-555-4321',
        address: '55 Skyway Ave',
        latitude: 40.7128,
        longitude: -74.006,
        priority: 'MEDIUM',
        status: 'ASSIGNED',
        scheduledAt: new Date(),
        assignedToId: user.id,
        version: 1,
      },
    });
    testTaskId = task.id;
  });

  afterAll(async () => {
    await prisma.location.deleteMany({ where: { taskId: testTaskId } });
    await prisma.taskNote.deleteMany({ where: { taskId: testTaskId } });
    await prisma.task.deleteMany({ where: { id: testTaskId } });
    await prisma.user.deleteMany({ where: { id: testUserId } });
    await prisma.$disconnect();
  });

  it('POST /api/v1/sync - should atomically process offline batch operations', async () => {
    const syncPayload = {
      operations: [
        {
          id: 'op-status-1',
          operationType: 'UPDATE',
          entityType: 'TASK',
          entityId: testTaskId,
          payload: { status: 'ACCEPTED', version: 1 },
        },
        {
          id: 'op-note-1',
          operationType: 'CREATE',
          entityType: 'NOTE',
          entityId: 'temp-note-id',
          payload: { taskId: testTaskId, content: 'Technician accepted job while in basement without cellular reception.' },
        },
        {
          id: 'op-loc-1',
          operationType: 'CREATE',
          entityType: 'LOCATION',
          entityId: 'temp-loc-id',
          payload: { taskId: testTaskId, latitude: 40.7128, longitude: -74.006, accuracy: 3.5 },
        },
      ],
    };

    const res = await request(app)
      .post('/api/v1/sync')
      .set('Authorization', `Bearer ${authToken}`)
      .send(syncPayload);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.processedCount).toBe(3);
    expect(res.body.data.conflictCount).toBe(0);
    expect(res.body.data.failedCount).toBe(0);

    const statusResult = res.body.data.results.find((r: any) => r.operationId === 'op-status-1');
    expect(statusResult.status).toBe('SYNCED');
    expect(statusResult.data.version).toBe(2);

    const noteResult = res.body.data.results.find((r: any) => r.operationId === 'op-note-1');
    expect(noteResult.status).toBe('SYNCED');

    const locResult = res.body.data.results.find((r: any) => r.operationId === 'op-loc-1');
    expect(locResult.status).toBe('SYNCED');
  });

  it('POST /api/v1/sync - should isolate conflict when an operation has stale version without failing others', async () => {
    const syncPayload = {
      operations: [
        {
          id: 'op-stale-status',
          operationType: 'UPDATE',
          entityType: 'TASK',
          entityId: testTaskId,
          // Server version is now 2 from previous test! Sending version 1 triggers CONFLICT
          payload: { status: 'IN_PROGRESS', version: 1 },
        },
        {
          id: 'op-independent-note',
          operationType: 'CREATE',
          entityType: 'NOTE',
          entityId: 'temp-note-2',
          payload: { taskId: testTaskId, content: 'Routine inspection note.' },
        },
      ],
    };

    const res = await request(app)
      .post('/api/v1/sync')
      .set('Authorization', `Bearer ${authToken}`)
      .send(syncPayload);

    expect(res.status).toBe(200);
    expect(res.body.data.conflictCount).toBe(1);

    const conflictResult = res.body.data.results.find((r: any) => r.operationId === 'op-stale-status');
    expect(conflictResult.status).toBe('CONFLICT');
    expect(conflictResult.error.code).toBe('CONFLICT');

    const noteResult = res.body.data.results.find((r: any) => r.operationId === 'op-independent-note');
    expect(noteResult.status).toBe('SYNCED');
  });
});

