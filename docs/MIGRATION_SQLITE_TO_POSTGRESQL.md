# SQLite to PostgreSQL Migration Guide — Classora 2.0

This guide outlines the production migration procedure from SQLite (`dev.db`) to PostgreSQL 14+ / 16+.

---

## 1. Schema Differences & Preparation

Classora v2 was developed with an engine-agnostic relational data model in Prisma.
The production PostgreSQL schema is maintained in:
`apps/api/prisma/schema.postgresql.prisma`.

Key enhancements in PostgreSQL:
1. **Concurrency:** Full multi-writer ACID transactions without SQLite file-level locks (`WAL` writer contention).
2. **Connection Pooling:** Supports PgBouncer / Supabase / Neon transaction mode connection poolers.
3. **Multi-Tenancy:** Preserves all foreign key `onDelete: Cascade` and tenant-scoped composite indices (`@@index([instituteId, ...])`).

---

## 2. Step-by-Step Migration

### Step A: Configure PostgreSQL Database
Ensure your PostgreSQL instance is running. Obtain your connection URL:
```bash
DATABASE_URL="postgresql://classora_user:secure_password@postgres.internal:5432/classora_prod?schema=public&sslmode=prefer"
```

### Step B: Push or Migrate Schema to PostgreSQL
Run Prisma to create all tables, composite keys, and indices on PostgreSQL:
```bash
cd apps/api
npx prisma db push --schema=prisma/schema.postgresql.prisma
```
Or for versioned migrations:
```bash
npx prisma migrate dev --name init_postgres --schema=prisma/schema.postgresql.prisma
```

### Step C: Data Migration (SQLite to PostgreSQL)

#### Option 1: Automated Migration via `pgloader` (Recommended for Zero-Downtime)
Install `pgloader`:
```bash
# Ubuntu / Debian
sudo apt-get install pgloader

# macOS
brew install pgloader
```

Create a migration command file `migrate_classora.load`:
```
load database
     from sqlite:///path/to/apps/api/dev.db
     into postgresql://classora_user:secure_password@localhost:5432/classora_prod

 with include drop, create tables, create indexes, reset sequences

  set work_mem to '128MB', maintenance_work_mem to '256MB'

 cast type datetime to timestamptz drop default drop not null using sqlite-timestamp-to-timestamp;
```

Execute migration:
```bash
pgloader migrate_classora.load
```

#### Option 2: Selective Seed / Transfer via Prisma Script
For cloud environments where `pgloader` is not available, you can use Classora's export/import script:
```bash
npm run db:reset-demo # with DATABASE_URL set to PostgreSQL
```

---

## 3. Environment Variable Switch

In `apps/api/.env`:
```env
# Switch DATABASE_URL to PostgreSQL
DATABASE_URL="postgresql://classora_user:secure_password@postgres.internal:5432/classora_prod?schema=public"

# Replace schema pointer in package.json or copy schema.postgresql.prisma to schema.prisma
```

Regenerate Prisma Client:
```bash
npx prisma generate --schema=prisma/schema.postgresql.prisma
```

Verify connection and run tests:
```bash
npm test
```
