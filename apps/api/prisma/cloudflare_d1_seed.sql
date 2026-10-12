-- Seed Apex Institute
INSERT OR IGNORE INTO "Institute" ("id", "name", "slug", "plan", "createdAt", "updatedAt")
VALUES ('inst-apex-01', 'Apex IIT-JEE & Medical Academy', 'apex', 'ENTERPRISE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- Seed Admin
INSERT OR IGNORE INTO "User" ("id", "instituteId", "name", "email", "phone", "role", "status", "passwordHash", "createdAt", "updatedAt")
VALUES ('usr-admin-01', 'inst-apex-01', 'Dr. S. N. Roy', 'admin@apex.edu', '+91 98765 00001', 'ADMIN', 'ACTIVE', '$argon2id$v=19$m=65536,p=4,t=3$9mI1hL0Hn5N2Cg8gG0hE1A$l0J8m4l2O9i8h7g6f5e4d3c2b1a0Z9y8x7w6v5u4t3s', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- Seed Teachers
INSERT OR IGNORE INTO "User" ("id", "instituteId", "name", "email", "phone", "role", "status", "passwordHash", "createdAt", "updatedAt")
VALUES ('usr-teacher-01', 'inst-apex-01', 'Prof. Rajesh Sharma', 'teacher1@apex.edu', '+91 98765 00002', 'TEACHER', 'ACTIVE', '$argon2id$v=19$m=65536,p=4,t=3$9mI1hL0Hn5N2Cg8gG0hE1A$l0J8m4l2O9i8h7g6f5e4d3c2b1a0Z9y8x7w6v5u4t3s', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT OR IGNORE INTO "User" ("id", "instituteId", "name", "email", "phone", "role", "status", "passwordHash", "createdAt", "updatedAt")
VALUES ('usr-teacher-02', 'inst-apex-01', 'Dr. Kavita Rao', 'teacher2@apex.edu', '+91 98765 00003', 'TEACHER', 'ACTIVE', '$argon2id$v=19$m=65536,p=4,t=3$9mI1hL0Hn5N2Cg8gG0hE1A$l0J8m4l2O9i8h7g6f5e4d3c2b1a0Z9y8x7w6v5u4t3s', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- Seed Students
INSERT OR IGNORE INTO "User" ("id", "instituteId", "name", "email", "phone", "role", "status", "passwordHash", "createdAt", "updatedAt")
VALUES ('usr-student-01', 'inst-apex-01', 'Aarav Patel', 'student1@apex.edu', '+91 98765 00011', 'STUDENT', 'ACTIVE', '$argon2id$v=19$m=65536,p=4,t=3$9mI1hL0Hn5N2Cg8gG0hE1A$l0J8m4l2O9i8h7g6f5e4d3c2b1a0Z9y8x7w6v5u4t3s', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT OR IGNORE INTO "User" ("id", "instituteId", "name", "email", "phone", "role", "status", "passwordHash", "createdAt", "updatedAt")
VALUES ('usr-student-02', 'inst-apex-01', 'Priya Sharma', 'student2@apex.edu', '+91 98765 00012', 'STUDENT', 'ACTIVE', '$argon2id$v=19$m=65536,p=4,t=3$9mI1hL0Hn5N2Cg8gG0hE1A$l0J8m4l2O9i8h7g6f5e4d3c2b1a0Z9y8x7w6v5u4t3s', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- Seed Batch
INSERT OR IGNORE INTO "Batch" ("id", "instituteId", "teacherId", "name", "subject", "joinCode", "createdAt", "updatedAt")
VALUES ('batch-jee-12', 'inst-apex-01', 'usr-teacher-01', 'Class 12th IIT-JEE Masterclass', 'Physics & Mathematics', 'JEE2026', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- Seed Enrollments
INSERT OR IGNORE INTO "Enrollment" ("id", "instituteId", "batchId", "studentId", "status", "enrolledAt", "updatedAt")
VALUES ('enr-01', 'inst-apex-01', 'batch-jee-12', 'usr-student-01', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT OR IGNORE INTO "Enrollment" ("id", "instituteId", "batchId", "studentId", "status", "enrolledAt", "updatedAt")
VALUES ('enr-02', 'inst-apex-01', 'batch-jee-12', 'usr-student-02', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- Seed Timetable Slot (Monday 18:00 - 19:30)
INSERT OR IGNORE INTO "TimetableSlot" ("id", "instituteId", "teacherId", "batchId", "dayOfWeek", "startMin", "endMin", "recurring", "createdAt", "updatedAt")
VALUES ('slot-01', 'inst-apex-01', 'usr-teacher-01', 'batch-jee-12', 1, 1080, 1170, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- Seed Live Class
INSERT OR IGNORE INTO "LiveClass" ("id", "instituteId", "batchId", "teacherId", "title", "scheduledAt", "status", "livekitRoom", "createdAt", "updatedAt")
VALUES ('class-demo-101', 'inst-apex-01', 'batch-jee-12', 'usr-teacher-01', 'Electromagnetic Induction & Faradays Laws', CURRENT_TIMESTAMP, 'SCHEDULED', 'room-jee-101', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
