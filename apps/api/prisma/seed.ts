import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('[Seed] Starting database seed...');

  // Clean existing tables in reverse order
  await prisma.chatMessage.deleteMany();
  await prisma.boardPage.deleteMany();
  await prisma.liveClass.deleteMany();
  await prisma.batchEnrollment.deleteMany();
  await prisma.batch.deleteMany();
  await prisma.course.deleteMany();
  await prisma.user.deleteMany();
  await prisma.institute.deleteMany();

  // 1. Create Institute
  const institute = await prisma.institute.create({
    data: {
      id: 'inst-apex-01',
      name: 'Apex IIT-JEE & Medical Academy',
      subdomain: 'apex',
      logoUrl: 'https://images.unsplash.com/photo-1546410531-bb4caa6b424d?w=100&h=100&fit=crop',
    },
  });

  // 2. Create Users (Admin, Teachers, Students)
  const admin = await prisma.user.create({
    data: {
      id: 'usr-admin-01',
      instituteId: institute.id,
      name: 'Sunil Verma',
      email: 'admin@classora.com',
      phone: '+91 98765 00001',
      role: 'ADMIN',
      avatarUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=120&h=120&fit=crop',
    },
  });

  const teacher1 = await prisma.user.create({
    data: {
      id: 'usr-teacher-01',
      instituteId: institute.id,
      name: 'Prof. Rajesh Sharma',
      email: 'teacher@classora.com',
      phone: '+91 98765 00002',
      role: 'TEACHER',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=120&h=120&fit=crop',
    },
  });

  const teacher2 = await prisma.user.create({
    data: {
      id: 'usr-teacher-02',
      instituteId: institute.id,
      name: 'Dr. Kavita Rao',
      email: 'kavita@classora.com',
      phone: '+91 98765 00003',
      role: 'TEACHER',
      avatarUrl: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=120&h=120&fit=crop',
    },
  });

  const studentAarav = await prisma.user.create({
    data: {
      id: 'usr-student-01',
      instituteId: institute.id,
      name: 'Aarav Patel',
      email: 'student@classora.com',
      phone: '+91 98765 43210',
      role: 'STUDENT',
      avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120&h=120&fit=crop',
    },
  });

  const studentPriya = await prisma.user.create({
    data: {
      id: 'usr-student-02',
      instituteId: institute.id,
      name: 'Priya Sharma',
      email: 'priya@classora.com',
      phone: '+91 98765 43211',
      role: 'STUDENT',
      avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=120&h=120&fit=crop',
    },
  });

  const studentRohan = await prisma.user.create({
    data: {
      id: 'usr-student-03',
      instituteId: institute.id,
      name: 'Rohan Verma',
      email: 'rohan@classora.com',
      phone: '+91 98765 43212',
      role: 'STUDENT',
      avatarUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=120&h=120&fit=crop',
    },
  });

  const studentAnanya = await prisma.user.create({
    data: {
      id: 'usr-student-04',
      instituteId: institute.id,
      name: 'Ananya Iyer',
      email: 'ananya@classora.com',
      phone: '+91 98765 43213',
      role: 'STUDENT',
      avatarUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=120&h=120&fit=crop',
    },
  });

  // 3. Create Courses
  const courseJee = await prisma.course.create({
    data: {
      id: 'course-jee',
      instituteId: institute.id,
      name: 'IIT-JEE Masterclass 2026',
      category: 'Engineering',
      duration: '1 Year Intensive',
    },
  });

  const courseNeet = await prisma.course.create({
    data: {
      id: 'course-neet',
      instituteId: institute.id,
      name: 'NEET Champions 2027',
      category: 'Medical',
      duration: '2 Years Comprehensive',
    },
  });

  const courseFound = await prisma.course.create({
    data: {
      id: 'course-found',
      instituteId: institute.id,
      name: 'Foundation Class 10th & Olympiads',
      category: 'Foundation',
      duration: '1 Year Academic',
    },
  });

  // 4. Create Batches
  const batchJee = await prisma.batch.create({
    data: {
      id: 'batch-jee-12',
      instituteId: institute.id,
      courseId: courseJee.id,
      name: 'Batch A — Class 12th IIT-JEE Masterclass',
      teacherId: teacher1.id,
      startDate: '2026-04-01',
      endDate: '2027-03-31',
    },
  });

  const batchNeet = await prisma.batch.create({
    data: {
      id: 'batch-neet-11',
      instituteId: institute.id,
      courseId: courseNeet.id,
      name: 'Batch B — Class 11th NEET Champions',
      teacherId: teacher2.id,
      startDate: '2026-05-01',
      endDate: '2028-04-30',
    },
  });

  const batchFound = await prisma.batch.create({
    data: {
      id: 'batch-found-10',
      instituteId: institute.id,
      courseId: courseFound.id,
      name: 'Batch C — Class 10th Board & NTSE',
      teacherId: teacher1.id,
      startDate: '2026-04-15',
      endDate: '2027-03-15',
    },
  });

  // 5. Enroll Students into Batches
  // Aarav -> Batch A (JEE 12th)
  await prisma.batchEnrollment.create({
    data: {
      batchId: batchJee.id,
      studentId: studentAarav.id,
      rollNumber: 'JEE-12-001',
    },
  });

  // Rohan -> Batch A (JEE 12th) AND Batch C (Foundation)
  await prisma.batchEnrollment.create({
    data: {
      batchId: batchJee.id,
      studentId: studentRohan.id,
      rollNumber: 'JEE-12-002',
    },
  });

  // Priya -> Batch B (NEET 11th)
  await prisma.batchEnrollment.create({
    data: {
      batchId: batchNeet.id,
      studentId: studentPriya.id,
      rollNumber: 'NEET-11-001',
    },
  });

  // Ananya -> Batch B (NEET 11th)
  await prisma.batchEnrollment.create({
    data: {
      batchId: batchNeet.id,
      studentId: studentAnanya.id,
      rollNumber: 'NEET-11-002',
    },
  });

  // 6. Create Seed Live Classes
  const now = new Date();
  const scheduledTime1 = new Date(now.getTime() - 10 * 60000); // 10 mins ago (ready to go live!)
  const scheduledTime2 = new Date(now.getTime() + 2 * 3600000); // 2 hours later

  await prisma.liveClass.create({
    data: {
      id: 'live-class-01',
      instituteId: institute.id,
      batchId: batchJee.id,
      teacherId: teacher1.id,
      title: 'Electromagnetic Induction & Faraday’s Laws',
      subject: 'Physics',
      chapter: 'Electrodynamics — Unit 4',
      roomId: 'room-jee-101',
      status: 'SCHEDULED',
      scheduledAt: scheduledTime1,
    },
  });

  await prisma.liveClass.create({
    data: {
      id: 'live-class-02',
      instituteId: institute.id,
      batchId: batchNeet.id,
      teacherId: teacher2.id,
      title: 'Human Physiology: Cardiac Cycle & ECG',
      subject: 'Biology',
      chapter: 'Circulatory Systems — Chapter 18',
      roomId: 'room-neet-202',
      status: 'SCHEDULED',
      scheduledAt: scheduledTime2,
    },
  });

  console.log('[Seed] Database seeded successfully with:');
  console.log(`- 1 Institute (${institute.name})`);
  console.log(`- 1 Admin, 2 Teachers, 4 Students`);
  console.log(`- 3 Courses, 3 Batches with assigned teachers`);
  console.log(`- Students enrolled in specific Batches`);
  console.log(`- 2 Scheduled Live Classes`);
}

main()
  .catch((e) => {
    console.error('[Seed] Error during seeding:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
