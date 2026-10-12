import { PrismaClient } from '@prisma/client';

export const prisma = new PrismaClient({
  log: process.env.NODE_ENV === 'development' ? ['warn', 'error'] : ['error'],
});

// Configure SQLite pragmas on initialization
export async function initializePrisma(): Promise<void> {
  try {
    await prisma.$queryRawUnsafe('PRAGMA journal_mode = WAL;');
    await prisma.$queryRawUnsafe('PRAGMA foreign_keys = ON;');
  } catch (error) {
    console.error('Failed to set SQLite pragmas:', error);
  }
}
