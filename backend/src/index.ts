import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';
import { PrismaClient } from '@prisma/client';
import { createHealthRouter } from './routes/health';

dotenv.config();

const app = express();
const PORT = Number(process.env.PORT) || 3000;
const prisma = new PrismaClient();

app.use(
  helmet({
    contentSecurityPolicy: false,
  })
);
app.use(
  cors({
    origin: process.env.FRONTEND_URL || '*',
    credentials: true,
  })
);
app.use(express.json());

app.set('prisma', prisma);

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.use('/api/health', createHealthRouter(app));

app.listen(PORT, () => {
  console.log(`[beacon-app-min] API listening on port ${PORT}`);
});
