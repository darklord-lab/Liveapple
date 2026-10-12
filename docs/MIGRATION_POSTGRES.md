# SQLite to PostgreSQL Migration Plan — Classora 2.0

## 1. Overview
Classora 2.0 uses Prisma ORM with standard relational constraints (`@relation`, `@unique`, `@@index`). Migrating from local SQLite to production PostgreSQL requires zero code refactoring beyond datasource configuration and index tuning.

---

## 2. Step-by-Step Migration Process

### Step 1: Environment & Datasource Switch
1. Update `apps/api/prisma/schema.prisma`:
   ```prisma
   datasource db {
     provider = "postgresql"
     url      = env("DATABASE_URL")
   }
   ```
2. Update `.env` with production PostgreSQL connection string (Supabase / AWS RDS / Neon):
   ```env
   DATABASE_URL="postgresql://classora_admin:<PASSWORD>@<HOST>:5432/classora_prod?schema=public&sslmode=require&connection_limit=20"
   ```

### Step 2: Generate & Push Migrations
```bash
cd apps/api
# 1. Regenerate Prisma Client for PostgreSQL
npm run prisma:generate

# 2. Apply initial production migration
npx prisma migrate dev --name init_postgres

# 3. Seed production base records (System Admin & Institute)
npm run prisma:seed
```

### Step 3: Data Migration from Existing SQLite
If migrating existing SQLite records into PostgreSQL:
1. Export SQLite tables to JSON or CSV via Prisma script.
2. Bulk insert via Prisma transactions with foreign key ordering:
   `Institute` → `User` → `Invite` → `Batch` → `Enrollment` → `TimetableSlot` → `LiveClass` → `Attendance` → `Assignment` → `Submission` → `Test` → `Question` → `TestAttempt` → `FeePlan` → `Payment`.

---

## 3. Production PostgreSQL Index Optimization
All queries are multi-tenant and filter on `instituteId`. The following compound indexes are already configured in the schema:

| Table | Index Columns | Purpose |
|---|---|---|
| `User` | `[instituteId, role]`, `[email]` | Fast user lookup & auth |
| `Batch` | `[instituteId, teacherId]`, `[instituteId, joinCode]` | Batch dashboard & code join |
| `Enrollment` | `[instituteId, batchId, studentId]`, `[batchId, status]` | Student roster queries |
| `TimetableSlot` | `[instituteId, teacherId]`, `[teacherId, dayOfWeek]` | Conflict detection engine |
| `LiveClass` | `[instituteId, status]`, `[teacherId, scheduledAt]` | Live & upcoming feeds |
| `Attendance` | `[instituteId, liveClassId]`, `[instituteId, studentId]` | Attendance analytics |
| `Notification` | `[instituteId, userId, readAt]` | Instant unread count |

---

## 4. Connection Pooling & High-Availability
- Enable **PgBouncer** or **Prisma Accelerate** for connection pooling when scaling past 1,000 concurrent students.
- Recommended pool size: 20–50 connections per API instance.
- Enable automatic daily WAL backups and point-in-time recovery (PITR).
