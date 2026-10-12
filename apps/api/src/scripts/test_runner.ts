import { spawnSync } from 'child_process';
import fs from 'fs';
import path from 'path';

const testDbPath = path.resolve(process.cwd(), 'prisma', 'test.db');
const testDbUrl = `file:./test.db`;

console.log('🧪 [TEST RUNNER] Initializing isolated SQLite database for tests...');

// 1. Clean previous test database files if any
const filesToClean = [
  testDbPath,
  `${testDbPath}-journal`,
  `${testDbPath}-wal`,
  `${testDbPath}-shm`,
];
for (const f of filesToClean) {
  if (fs.existsSync(f)) {
    try { fs.unlinkSync(f); } catch {}
  }
}

// 2. Set environment variable for test DB
const env = {
  ...process.env,
  DATABASE_URL: testDbUrl,
  NODE_ENV: 'test',
};

// 3. Push schema to test.db
console.log('📦 [TEST RUNNER] Pushing schema to test.db...');
const pushRes = spawnSync('npx', ['prisma', 'db', 'push', '--skip-generate', '--schema', 'prisma/schema.prisma'], {
  env,
  stdio: 'inherit',
  shell: true,
});

if (pushRes.status !== 0) {
  console.error('❌ Failed to push schema to test.db');
  process.exit(pushRes.status || 1);
}

// 4. Seed test.db with baseline demo data
console.log('🌱 [TEST RUNNER] Seeding baseline test data...');
const seedRes = spawnSync('npx', ['tsx', 'prisma/seed.ts'], {
  env,
  stdio: 'inherit',
  shell: true,
});

if (seedRes.status !== 0) {
  console.error('❌ Failed to seed test.db');
  process.exit(seedRes.status || 1);
}

// 5. Run tests against test.db
console.log('🚀 [TEST RUNNER] Running test suite against test.db...');
const testRes = spawnSync('npx', ['tsx', '--test', 'src/tests/**/*.test.ts'], {
  env,
  stdio: 'inherit',
  shell: true,
});

// 6. Clean up test database files
console.log('🧹 [TEST RUNNER] Cleaning up test.db files...');
for (const f of filesToClean) {
  if (fs.existsSync(f)) {
    try { fs.unlinkSync(f); } catch {}
  }
}

process.exit(testRes.status ?? 0);
