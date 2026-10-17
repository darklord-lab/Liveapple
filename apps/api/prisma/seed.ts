import { PrismaClient } from '@prisma/client';
import argon2 from 'argon2';

const prisma = new PrismaClient();

async function resetDemo() {
  // 3.1 Guard against running in production
  if (process.env.NODE_ENV === 'production') {
    const isOverrideAllowed =
      process.env.ALLOW_DESTRUCTIVE_DEMO_RESET === 'true' ||
      process.env.FORCE_DEMO_RESET === 'true';

    if (!isOverrideAllowed) {
      const instituteCount = await prisma.institute.count().catch(() => 0);
      if (instituteCount > 0) {
        console.log('ℹ️ Production environment detected: Database already contains data. Skipping demo reset to protect data.');
        return;
      }
      console.log('🌱 Production initial deploy: Database is empty. Seeding baseline demo data...');
    } else {
      // If override is enabled, verify there are no real customer users
      const nonDemoUserCount = await prisma.user.count({
        where: {
          email: { not: { endsWith: '@apex.edu' } },
        },
      }).catch(() => 0);

      if (nonDemoUserCount > 0) {
        console.log(`ℹ️ Refusing to reset DB in production: Found ${nonDemoUserCount} real non-demo users. Skipping demo reset safely.`);
        return;
      }
    }
  }

  console.log('🌱 Starting Classora 2.0 Demo Reset & Seeding (Clean Data Hygiene)...');

  // Configure SQLite WAL mode & Foreign keys
  await prisma.$queryRawUnsafe('PRAGMA journal_mode = WAL;');
  await prisma.$queryRawUnsafe('PRAGMA foreign_keys = ON;');

  // Clean all existing tables in dependency order
  await prisma.payment.deleteMany();
  await prisma.feePlan.deleteMany();
  await prisma.testAttempt.deleteMany();
  await prisma.question.deleteMany();
  await prisma.test.deleteMany();
  await prisma.submission.deleteMany();
  await prisma.assignment.deleteMany();
  await prisma.recording.deleteMany();
  await prisma.attendance.deleteMany();
  await prisma.liveClass.deleteMany();
  await prisma.timetableSlot.deleteMany();
  await prisma.enrollment.deleteMany();
  await prisma.batch.deleteMany();
  await prisma.invite.deleteMany();
  await prisma.notification.deleteMany();
  await prisma.refreshToken.deleteMany();
  await prisma.auditLog.deleteMany();
  await prisma.user.deleteMany();
  await prisma.institute.deleteMany();

  // 1. Institute
  const institute = await prisma.institute.create({
    data: {
      id: 'inst-apex-01',
      name: 'Apex IIT-JEE & Medical Academy',
      slug: 'apex',
      code: 'APEX01',
      primaryColor: '#0A9BE8',
      tagline: 'Premier IIT-JEE & Medical Academy',
      plan: 'ENTERPRISE',
    },
  });
  console.log(`✅ Institute created: ${institute.name} (${institute.id})`);

  // Default password hash using argon2id
  const defaultPassword = 'Password@123';
  const defaultPasswordHash = await argon2.hash(defaultPassword, {
    type: argon2.argon2id,
    memoryCost: 65536,
    timeCost: 3,
    parallelism: 4,
  });

  // 2. Admin: Dr. S. N. Roy
  const admin = await prisma.user.create({
    data: {
      id: 'usr-admin-01',
      instituteId: institute.id,
      name: 'Dr. S. N. Roy',
      email: 'admin@apex.edu',
      phone: '+91 98765 00001',
      role: 'ADMIN',
      status: 'ACTIVE',
      passwordHash: defaultPasswordHash,
    },
  });
  console.log(`✅ Admin created: ${admin.name} (${admin.email})`);

  // 3. Teachers: Prof. Rajesh Sharma (Physics), Prof. Anita Verma (Maths)
  const teacher1 = await prisma.user.create({
    data: {
      id: 'usr-teacher-01',
      instituteId: institute.id,
      name: 'Prof. Rajesh Sharma',
      email: 'teacher1@apex.edu',
      phone: '+91 98765 00002',
      role: 'TEACHER',
      status: 'ACTIVE',
      passwordHash: defaultPasswordHash,
      coachingName: 'Sharma Physics Academy',
      centreLogo: 'https://cdn.classora.com/logos/sharma_physics.png',
      centreAddress: 'Plot 42, Knowledge Park III, Greater Noida, UP',
      contactPhone: '+91 98765 00002',
      bio: 'Senior Faculty with 18+ years of mentoring top JEE Advanced Physics rankers.',
      subjects: 'JEE Physics, Mechanics, Waves & Optics',
    },
  });

  const teacher2 = await prisma.user.create({
    data: {
      id: 'usr-teacher-02',
      instituteId: institute.id,
      name: 'Prof. Anita Verma',
      email: 'teacher2@apex.edu',
      phone: '+91 98765 00003',
      role: 'TEACHER',
      status: 'ACTIVE',
      passwordHash: defaultPasswordHash,
      coachingName: 'Verma Mathematics Hub',
      centreLogo: 'https://cdn.classora.com/logos/verma_maths.png',
      centreAddress: 'B-12, Sector 62, Noida, UP',
      contactPhone: '+91 98765 00003',
      bio: 'Ex-HOD Mathematics specializing in Differential & Integral Calculus.',
      subjects: 'JEE Mathematics, Calculus, Coordinate Geometry',
    },
  });
  console.log(`✅ 2 Teachers created: ${teacher1.name} (Sharma Physics Academy), ${teacher2.name} (Verma Mathematics Hub)`);

  // 4. Six Students with real names & Teacher Links
  const studentData = [
    { id: 'usr-student-01', name: 'Aarav Patel', email: 'student1@apex.edu', phone: '+91 98765 00011', teacherId: teacher1.id },
    { id: 'usr-student-02', name: 'Priya Sharma', email: 'student2@apex.edu', phone: '+91 98765 00012', teacherId: teacher1.id },
    { id: 'usr-student-03', name: 'Rohan Verma', email: 'student3@apex.edu', phone: '+91 98765 00013', teacherId: teacher1.id },
    { id: 'usr-student-04', name: 'Neha Singh', email: 'student4@apex.edu', phone: '+91 98765 00014', teacherId: teacher2.id },
    { id: 'usr-student-05', name: 'Karan Mehta', email: 'student5@apex.edu', phone: '+91 98765 00015', teacherId: teacher2.id },
    { id: 'usr-student-06', name: 'Isha Gupta', email: 'student6@apex.edu', phone: '+91 98765 00016', teacherId: teacher2.id },
  ];

  const students = [];
  for (const st of studentData) {
    const s = await prisma.user.create({
      data: {
        id: st.id,
        instituteId: institute.id,
        name: st.name,
        email: st.email,
        phone: st.phone,
        role: 'STUDENT',
        status: 'ACTIVE',
        passwordHash: defaultPasswordHash,
        creatorTeacherId: st.teacherId,
      },
    });
    students.push(s);
  }
  console.log(`✅ 6 Students created: ${students.map(s => s.name).join(', ')}`);

  // 5. Clean Batches
  const batchPhysics = await prisma.batch.create({
    data: {
      id: 'batch-jee-phy',
      instituteId: institute.id,
      teacherId: teacher1.id,
      name: 'Class 12 JEE — Physics',
      subject: 'Physics',
      joinCode: 'JEEPHY',
    },
  });

  const batchMaths = await prisma.batch.create({
    data: {
      id: 'batch-jee-mth',
      instituteId: institute.id,
      teacherId: teacher1.id,
      name: 'Class 12 JEE — Maths',
      subject: 'Mathematics',
      joinCode: 'JEEMTH',
    },
  });

  const batchChemistry = await prisma.batch.create({
    data: {
      id: 'batch-neet-chm',
      instituteId: institute.id,
      teacherId: teacher2.id,
      name: 'Class 11 NEET — Chemistry',
      subject: 'Chemistry',
      joinCode: 'NEETCH',
    },
  });
  console.log(`✅ 3 Batches created: ${batchPhysics.name}, ${batchMaths.name}, ${batchChemistry.name}`);

  // 6. Enrollments: Students 1-3 to Teacher 1 batches (Physics & Maths), Students 4-6 to Teacher 2 batch (Chemistry)
  const enrollmentsMap = [
    { batchId: batchPhysics.id, studentIds: ['usr-student-01', 'usr-student-02', 'usr-student-03'] },
    { batchId: batchMaths.id, studentIds: ['usr-student-01', 'usr-student-02', 'usr-student-03'] },
    { batchId: batchChemistry.id, studentIds: ['usr-student-04', 'usr-student-05', 'usr-student-06'] },
  ];

  for (const group of enrollmentsMap) {
    for (const sId of group.studentIds) {
      await prisma.enrollment.create({
        data: {
          instituteId: institute.id,
          batchId: group.batchId,
          studentId: sId,
          status: 'ACTIVE',
        },
      });
    }
  }
  console.log('✅ Enrollments created (Aarav Patel & Priya Sharma enrolled in both Physics and Maths).');

  // 7. Timetable slots Mon-Fri (1 = Monday, 5 = Friday)
  for (let day = 1; day <= 5; day++) {
    // Physics: 09:00 - 10:00 (540 to 600 min)
    await prisma.timetableSlot.create({
      data: {
        instituteId: institute.id,
        teacherId: teacher1.id,
        batchId: batchPhysics.id,
        dayOfWeek: day,
        startMin: 540,
        endMin: 600,
        recurring: true,
      },
    });

    // Maths: 10:30 - 11:30 (630 to 690 min)
    await prisma.timetableSlot.create({
      data: {
        instituteId: institute.id,
        teacherId: teacher1.id,
        batchId: batchMaths.id,
        dayOfWeek: day,
        startMin: 630,
        endMin: 690,
        recurring: true,
      },
    });

    // Chemistry: 16:00 - 17:00 (960 to 1020 min)
    await prisma.timetableSlot.create({
      data: {
        instituteId: institute.id,
        teacherId: teacher2.id,
        batchId: batchChemistry.id,
        dayOfWeek: day,
        startMin: 960,
        endMin: 1020,
        recurring: true,
      },
    });
  }
  console.log('✅ Mon-Fri Timetable slots created (Physics 09:00, Maths 10:30, Chemistry 16:00).');

  // 8. Scheduled classes for today (UTC stored, displayed in Asia/Kolkata)
  const now = new Date();
  // Class 1: Today at 2 hours from now
  const class1Time = new Date(now.getTime() + 2 * 60 * 60 * 1000);
  const class2Time = new Date(now.getTime() + 4 * 60 * 60 * 1000);
  const class3Time = new Date(now.getTime() + 5 * 60 * 60 * 1000);

  const liveClass1 = await prisma.liveClass.create({
    data: {
      id: 'class-demo-phy-01',
      instituteId: institute.id,
      batchId: batchPhysics.id,
      teacherId: teacher1.id,
      title: 'Electromagnetic Induction & Faraday’s Laws',
      scheduledAt: class1Time,
      status: 'SCHEDULED',
      livekitRoom: 'room-jee-phy-01',
    },
  });

  const liveClass2 = await prisma.liveClass.create({
    data: {
      id: 'class-demo-mth-01',
      instituteId: institute.id,
      batchId: batchMaths.id,
      teacherId: teacher1.id,
      title: 'Calculus: Integration by Parts & Definite Integrals',
      scheduledAt: class2Time,
      status: 'SCHEDULED',
      livekitRoom: 'room-jee-mth-01',
    },
  });

  const liveClass3 = await prisma.liveClass.create({
    data: {
      id: 'class-demo-chm-01',
      instituteId: institute.id,
      batchId: batchChemistry.id,
      teacherId: teacher2.id,
      title: 'Organic Chemistry: Reaction Mechanisms & Pathways',
      scheduledAt: class3Time,
      status: 'SCHEDULED',
      livekitRoom: 'room-neet-chm-01',
    },
  });
  console.log(`✅ 3 Live Classes created for today: ${liveClass1.title}, ${liveClass2.title}, ${liveClass3.title}`);

  // 9. Output demo credentials
  console.log('\n====================================================================');
  console.log('DEMO ACCOUNTS (TEST ONLY - DO NOT USE IN PRODUCTION):');
  console.log('Password for all accounts: ' + defaultPassword);
  console.log('--------------------------------------------------------------------');
  console.log('Admin:       admin@apex.edu');
  console.log('Teacher 1:   teacher1@apex.edu (Prof. Rajesh Sharma - Physics)');
  console.log('Teacher 2:   teacher2@apex.edu (Prof. Anita Verma - Maths)');
  console.log('Student 1:   student1@apex.edu (Aarav Patel - Enrolled: Phy + Mth)');
  console.log('Student 2:   student2@apex.edu (Priya Sharma - Enrolled: Phy + Mth)');
  console.log('Student 3:   student3@apex.edu (Rohan Verma - Enrolled: Phy + Chm)');
  console.log('Student 4:   student4@apex.edu (Neha Singh - Enrolled: Mth + Chm)');
  console.log('Student 5:   student5@apex.edu (Karan Mehta - Enrolled: Phy)');
  console.log('Student 6:   student6@apex.edu (Isha Gupta - Enrolled: Mth)');
  console.log('====================================================================\n');
}

resetDemo()
  .catch((e) => {
    console.error('❌ Reset Demo error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
