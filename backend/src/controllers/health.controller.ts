import { Request, Response } from 'express';
import { sendSuccess } from '../utils/response';

export class HealthController {
  static getHealth(req: Request, res: Response) {
    return sendSuccess(res, {
      status: 'UP',
      service: 'FIELDFlow Backend API',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      version: '1.0.0',
    }, 'Service is healthy');
  }
}
