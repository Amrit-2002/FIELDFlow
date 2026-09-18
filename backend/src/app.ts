import express, { Express, Request, Response, NextFunction } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import path from 'path';
import apiRoutes from './routes';
import { errorHandler } from './middleware/error.middleware';
import { AppError } from './utils/app-error';

export const createApp = (): Express => {
  const app = express();

  // Security & Utility Middlewares
  app.use(helmet());
  app.use(cors({ origin: '*' }));
  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ extended: true, limit: '10mb' }));

  if (process.env.NODE_ENV !== 'test') {
    app.use(morgan('dev'));
  }

  // Static uploads directory
  const uploadsPath = path.resolve(process.cwd(), 'uploads');
  app.use('/uploads', express.static(uploadsPath));

  // Mount API v1
  app.use('/api/v1', apiRoutes);

  // Catch 404
  app.use((req: Request, res: Response, next: NextFunction) => {
    next(AppError.notFound(`Route ${req.method} ${req.originalUrl} not found`, 'ROUTE_NOT_FOUND'));
  });

  // Centralized Error Handling
  app.use(errorHandler);

  return app;
};

