import request from 'supertest';
import { createApp } from '../src/app';
import { prisma } from '../src/config/database';
import bcrypt from 'bcryptjs';

const app = createApp();

describe('Task Transitions & Conflict Handling (409)', () => {
  let authToken: string;
  let testUserId: string;
  let testTaskId: string;

  beforeAll(async () => {
    const passwordHash = await bcrypt.hash('password123', 10);
    const user = await prisma.user.create({
      data: {
        name: 'Task Test Tech',
        email: `tech_tasks_${Date.now()}@example.com`,
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
        title: 'Generator Coolant Pump Overhaul',
        description: 'Scheduled coolant loop flushing and impeller replacement',
        customerName: 'Central Data Hub',
        customerPhone: '+1-555-0199',
        address: '100 Powerhouse Road',
        latitude: 37.7749,
        longitude: -122.4194,
        priority: 'HIGH',
        status: 'ASSIGNED',
        scheduledAt: new Date(),
        assignedToId: user.id,
        version: 1,
      },
    });
    testTaskId = task.id;
  });

  afterAll(async () => {
    await prisma.task.deleteMany({ where: { id: testTaskId } });
    await prisma.user.deleteMany({ where: { id: testUserId } });
    await prisma.$disconnect();
  });

  it('PATCH /api/v1/tasks/:id/status - should reject invalid leap from ASSIGNED to COMPLETED', async () => {
    const res = await request(app)
      .patch(`/api/v1/tasks/${testTaskId}/status`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({ status: 'COMPLETED', version: 1 });

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe('INVALID_STATUS_TRANSITION');
  });

  it('PATCH /api/v1/tasks/:id/status - should allow valid transition ASSIGNED -> ACCEPTED and increment version', async () => {
    const res = await request(app)
      .patch(`/api/v1/tasks/${testTaskId}/status`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({ status: 'ACCEPTED', version: 1 });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.status).toBe('ACCEPTED');
    expect(res.body.data.version).toBe(2);
  });

  it('PATCH /api/v1/tasks/:id/status - should return 409 CONFLICT when client sends stale version', async () => {
    // Current server version is 2 now. Sending version 1 should trigger 409 Conflict.
    const res = await request(app)
      .patch(`/api/v1/tasks/${testTaskId}/status`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({ status: 'IN_PROGRESS', version: 1 });

    expect(res.status).toBe(409);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe('CONFLICT');
    expect(res.body.error.details.currentVersion).toBe(2);
    expect(res.body.error.details.expectedVersion).toBe(1);
  });
});
