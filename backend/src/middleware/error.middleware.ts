import { Request, Response, NextFunction } from 'express';
import { AppError } from '../utils/app-error';
import { sendError } from '../utils/response';
import { logger } from '../utils/logger';

export const errorHandler = (err: Error, req: Request, res: Response, next: NextFunction): void => {
  if (err instanceof AppError) {
    logger.warn(`Operational error: ${err.message}`, {
      statusCode: err.statusCode,
      code: err.code,
      path: req.originalUrl,
      method: req.method,
      details: err.details,
    });

    sendError(res, err.statusCode, err.code, err.message, err.details);
    return;
  }

  // Unhandled error
  logger.error(`Unhandled error: ${err.message}`, {
    stack: err.stack,
    path: req.originalUrl,
    method: req.method,
  });

  const message = process.env.NODE_ENV === 'production' ? 'Internal server error' : err.message;
  sendError(res, 500, 'INTERNAL_SERVER_ERROR', message);
};
