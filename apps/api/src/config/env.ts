import dotenv from 'dotenv';
import { z } from 'zod';

dotenv.config();

const envSchema = z.object({
  PORT: z.string().default('4000').transform((val) => parseInt(val, 10)),
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  DATABASE_URL: z.string().default('file:./dev.db'),
  JWT_ACCESS_SECRET: z.string().default('classora_super_secret_access_jwt_key_2026_change_in_prod'),
  JWT_REFRESH_SECRET: z.string().default('classora_super_secret_refresh_jwt_key_2026_change_in_prod'),
  JWT_ACCESS_EXPIRES_IN: z.string().default('15m'),
  JWT_REFRESH_EXPIRES_DAYS: z.string().default('30').transform((val) => parseInt(val, 10)),
  INVITE_TOKEN_EXPIRES_HOURS: z.string().default('48').transform((val) => parseInt(val, 10)),
  CORS_ORIGINS: z.string().default('http://localhost:3000,http://localhost:3001,http://localhost:3002,http://localhost:3003,http://localhost:5173'),
  LIVEKIT_URL: z.string().default('http://localhost:7880'),
  LIVEKIT_API_KEY: z.string().default('devkey'),
  LIVEKIT_API_SECRET: z.string().default('secret'),
  // Public URL of the deployed server (used for self-ping keep-alive on Render)
  APP_URL: z.string().optional(),
});

export const env = envSchema.parse(process.env);
