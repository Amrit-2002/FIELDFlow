import { createApp } from './app';
import { env } from './config/env';
import { connectDatabase, disconnectDatabase } from './config/database';
import { logger } from './utils/logger';

const startServer = async () => {
  await connectDatabase();

  const app = createApp();

  const server = app.listen(env.PORT, '0.0.0.0', () => {
    logger.info(`🚀 FIELDFlow Backend running on http://localhost:${env.PORT}`);
    logger.info(`📡 Healthcheck available at http://localhost:${env.PORT}/api/v1/health`);
  });

  const shutdown = async (signal: string) => {
    logger.info(`Received ${signal}. Shutting down gracefully...`);
    server.close(async () => {
      await disconnectDatabase();
      logger.info('Database disconnected and HTTP server closed.');
      process.exit(0);
    });
  };

  process.on('SIGINT', () => shutdown('SIGINT'));
  process.on('SIGTERM', () => shutdown('SIGTERM'));
};

startServer().catch((err) => {
  logger.error('Failed to start server', { error: err.message, stack: err.stack });
  process.exit(1);
});

