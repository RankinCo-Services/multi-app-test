import express, { Request, Response } from 'express';

/**
 * Health router: app DB only. Returns database: 'connected' | 'not connected'
 * for display on the app home/dashboard.
 */
export function createHealthRouter(app: express.Application): express.Router {
  const prisma = app.get('prisma') as import('@prisma/client').PrismaClient;
  type DbStatus = 'connected' | 'not connected';
  const router = express.Router();

  router.get('/', async (_req: Request, res: Response): Promise<void> => {
    try {
      await prisma.$queryRaw`SELECT 1`;
      res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        database: 'connected' as DbStatus,
      });
    } catch {
      res.json({
        status: 'unhealthy',
        timestamp: new Date().toISOString(),
        database: 'not connected' as DbStatus,
      });
    }
  });

  return router;
}
