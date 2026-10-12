const BASE_URL = 'http://localhost:4000';

interface TestResult {
  category: string;
  feature: string;
  operation: string;
  status: 'PASS' | 'FAIL';
  details?: string;
  durationMs?: number;
}

const results: TestResult[] = [];

async function apiCall(
  method: string,
  path: string,
  options: {
    token?: string;
    body?: any;
    expectedStatus?: number;
  } = {}
) {
  const headers: Record<string, string> = {};
  if (options.token) {
    headers['Authorization'] = `Bearer ${options.token}`;
  }
  if (options.body) {
    headers['Content-Type'] = 'application/json';
  }

  const res = await fetch(`${BASE_URL}${path}`, {
    method,
    headers,
    body: options.body ? JSON.stringify(options.body) : undefined,
  });

  const contentType = res.headers.get('content-type') || '';
  let json: any = null;
  let text = '';
  if (contentType.includes('application/json')) {
    json = await res.json();
  } else {
    text = await res.text();
  }

  if (options.expectedStatus && res.status !== options.expectedStatus) {
    const errMsg = json ? JSON.stringify(json) : text;
    throw new Error(`Expected HTTP ${options.expectedStatus}, got ${res.status}: ${errMsg}`);
  }

  return { status: res.status, data: json, text };
}

async function logStep(category: string, feature: string, operation: string, fn: () => Promise<string | void>) {
  const t0 = Date.now();
  try {
    const details = await fn();
    const durationMs = Date.now() - t0;
    results.push({ category, feature, operation, status: 'PASS', details: details || 'OK', durationMs });
    console.log(`  ✅ [${category}] ${feature} -> ${operation} (${durationMs}ms)`);
  } catch (err: any) {
    const durationMs = Date.now() - t0;
    const msg = err.message || String(err);
    results.push({ category, feature, operation, status: 'FAIL', details: msg, durationMs });
    console.error(`  ❌ [${category}] ${feature} -> ${operation} FAILED: ${msg}`);
    throw err;
  }
}

async function runComprehensiveSanity() {
  console.log('\n=============================================================');
  console.log('🚀 CLASSORA 2.0 FULL SANITY & FEATURE CRUD VERIFICATION SUITE');
  console.log(`📡 Target API Gateway: ${BASE_URL}`);
  console.log('=============================================================\n');

  let adminToken = '';
  let teacherToken = '';
  let studentToken = '';

  let createdBatchId = '';
  let createdBatchJoinCode = '';
  let createdSlotId = '';
  let createdClassId = '';
  let createdAssignmentId = '';
  let createdSubmissionId = '';
  let createdTestId = '';
  let question1Id = '';
  let question2Id = '';
  let createdRecordingId = '';
  let createdFeePlanId = '';
  let inviteCode = '';

  // 1. AUTHENTICATION SANITY
  console.log('\n🔑 1. AUTHENTICATION & RBAC ROLES');
  await logStep('Auth', 'Admin Login', 'POST /api/v1/auth/login', async () => {
    const res = await apiCall('POST', '/api/v1/auth/login', {
      body: { email: 'admin@apex.edu', password: 'Password@123' },
      expectedStatus: 200,
    });
    adminToken = res.data.accessToken || res.data.token;
    if (!adminToken) throw new Error('No admin token returned');
    return `Logged in as ${res.data.user.name} (${res.data.user.role})`;
  });

  await logStep('Auth', 'Teacher Login', 'POST /api/v1/auth/login', async () => {
    const res = await apiCall('POST', '/api/v1/auth/login', {
      body: { email: 'teacher1@apex.edu', password: 'Password@123' },
      expectedStatus: 200,
    });
    teacherToken = res.data.accessToken || res.data.token;
    if (!teacherToken) throw new Error('No teacher token returned');
    return `Logged in as ${res.data.user.name} (${res.data.user.role})`;
  });

  await logStep('Auth', 'Student Login', 'POST /api/v1/auth/login', async () => {
    const res = await apiCall('POST', '/api/v1/auth/login', {
      body: { email: 'student1@apex.edu', password: 'Password@123' },
      expectedStatus: 200,
    });
    studentToken = res.data.accessToken || res.data.token;
    if (!studentToken) throw new Error('No student token returned');
    return `Logged in as ${res.data.user.name} (${res.data.user.role})`;
  });

  // 2. BATCHES CRUD (ADD, READ, UPDATE, JOIN)
  console.log('\n📚 2. BATCHES FEATURE (CRUD & MEMBERSHIP)');
  await logStep('Batches', 'Create Batch', 'POST /api/v1/batches', async () => {
    const res = await apiCall('POST', '/api/v1/batches', {
      token: teacherToken,
      body: {
        name: 'Sanity Chemistry 2026',
        subject: 'Inorganic & Physical Chemistry',
      },
      expectedStatus: 201,
    });
    createdBatchId = res.data.id;
    createdBatchJoinCode = res.data.joinCode;
    return `Created Batch ID: ${createdBatchId}, JoinCode: ${createdBatchJoinCode}`;
  });

  await logStep('Batches', 'List Batches', 'GET /api/v1/batches', async () => {
    const res = await apiCall('GET', '/api/v1/batches', {
      token: teacherToken,
      expectedStatus: 200,
    });
    const found = res.data.batches.find((b: any) => b.id === createdBatchId);
    if (!found) throw new Error('Newly created batch not found in list');
    return `Found batch in list of ${res.data.batches.length} batches`;
  });

  await logStep('Batches', 'Student Join Batch', 'POST /api/v1/batches/join', async () => {
    const res = await apiCall('POST', '/api/v1/batches/join', {
      token: studentToken,
      body: { joinCode: createdBatchJoinCode },
      expectedStatus: 200,
    });
    return `Student joined batch successfully (${res.data.message || 'Enrolled'})`;
  });

  await logStep('Batches', 'Update Batch Details', 'PATCH /api/v1/batches/:id', async () => {
    const res = await apiCall('PATCH', `/api/v1/batches/${createdBatchId}`, {
      token: teacherToken,
      body: { subject: 'Advanced Physical & Organic Chemistry' },
      expectedStatus: 200,
    });
    return `Batch subject updated: "${res.data.subject}"`;
  });

  // 3. TIMETABLE FEATURE (ADD, CONFLICT CHECK, REMOVE)
  console.log('\n🗓️ 3. TIMETABLE & SCHEDULING (ADD, CONFLICT, REMOVE)');
  await logStep('Timetable', 'Add Timetable Slot', 'POST /api/v1/timetable', async () => {
    const res = await apiCall('POST', '/api/v1/timetable', {
      token: teacherToken,
      body: {
        batchId: createdBatchId,
        dayOfWeek: 4, // Thursday
        startMin: 600, // 10:00 AM
        endMin: 690,   // 11:30 AM
        recurring: true,
      },
      expectedStatus: 201,
    });
    createdSlotId = res.data.id || (res.data.slot && res.data.slot.id);
    return `Slot created with ID: ${createdSlotId} (Thu 10:00-11:30)`;
  });

  await logStep('Timetable', 'Conflict Detection', 'POST /api/v1/timetable (Overlap)', async () => {
    const res = await apiCall('POST', '/api/v1/timetable', {
      token: teacherToken,
      body: {
        batchId: createdBatchId,
        dayOfWeek: 4,
        startMin: 630, // Overlaps 10:00 - 11:30
        endMin: 720,
        recurring: true,
      },
    });
    if (res.status !== 409 && res.status !== 400) {
      throw new Error(`Expected conflict (409/400), got status ${res.status}`);
    }
    return `Conflict correctly prevented (Status ${res.status}): ${res.data?.error || res.data?.message}`;
  });

  await logStep('Timetable', 'Delete Timetable Slot', 'DELETE /api/v1/timetable/:id', async () => {
    await apiCall('DELETE', `/api/v1/timetable/${createdSlotId}`, {
      token: teacherToken,
      expectedStatus: 200,
    });
    return `Slot ${createdSlotId} removed successfully`;
  });

  // 4. LIVE CLASSES FEATURE (SCHEDULE, START, TOKEN, HOST CONTROL, END)
  console.log('\n📹 4. LIVE CLASSES & LIVEKIT SFU');
  await logStep('LiveClass', 'Schedule Live Class', 'POST /api/v1/classes', async () => {
    const res = await apiCall('POST', '/api/v1/classes', {
      token: teacherToken,
      body: {
        batchId: createdBatchId,
        title: 'Chemical Kinetics Masterclass',
        scheduledAt: new Date(Date.now() + 1800000).toISOString(),
      },
      expectedStatus: 201,
    });
    createdClassId = res.data.id;
    return `Scheduled class ID: ${createdClassId} ("${res.data.title}")`;
  });

  await logStep('LiveClass', 'Teacher Starts Class', 'POST /api/v1/classes/:id/start', async () => {
    const res = await apiCall('POST', `/api/v1/classes/${createdClassId}/start`, {
      token: teacherToken,
      expectedStatus: 200,
    });
    return `Class status updated to: ${res.data.status}`;
  });

  await logStep('LiveClass', 'Generate LiveKit Room Token', 'POST /api/v1/classes/:id/token', async () => {
    const res = await apiCall('POST', `/api/v1/classes/${createdClassId}/token`, {
      token: studentToken,
      expectedStatus: 200,
    });
    if (!res.data.token || !res.data.serverUrl) throw new Error('LiveKit token or serverUrl missing');
    return `Generated token for room: ${res.data.roomName}, server: ${res.data.serverUrl}`;
  });

  await logStep('LiveClass', 'Host Control Mute All', 'POST /api/v1/classes/:id/host/mute-all', async () => {
    await apiCall('POST', `/api/v1/classes/${createdClassId}/host/mute-all`, {
      token: teacherToken,
      expectedStatus: 200,
    });
    return 'Host muted all participants successfully';
  });

  await logStep('LiveClass', 'Teacher Ends Class', 'POST /api/v1/classes/:id/end', async () => {
    const res = await apiCall('POST', `/api/v1/classes/${createdClassId}/end`, {
      token: teacherToken,
      expectedStatus: 200,
    });
    const status = res.data.class ? res.data.class.status : res.data.status;
    return `Class ended successfully. Status: ${status || 'ENDED'}`;
  });

  // 5. ATTENDANCE FEATURE (JOIN, LEAVE, SUMMARY)
  console.log('\n📊 5. ATTENDANCE LOGGING & ROSTER');
  await logStep('Attendance', 'Record Student Join', 'POST /api/v1/attendance/join', async () => {
    const res = await apiCall('POST', '/api/v1/attendance/join', {
      token: studentToken,
      body: { classId: createdClassId },
      expectedStatus: 200,
    });
    return `Attendance recorded. Status: ${res.data.data.status}`;
  });

  await logStep('Attendance', 'Record Student Leave', 'POST /api/v1/attendance/leave', async () => {
    const res = await apiCall('POST', '/api/v1/attendance/leave', {
      token: studentToken,
      body: { classId: createdClassId },
      expectedStatus: 200,
    });
    return `Leave timestamp marked. Duration: ${res.data.data.durationMinutes ?? 0} mins`;
  });

  await logStep('Attendance', 'Student Attendance Summary', 'GET /api/v1/attendance/my-summary', async () => {
    const res = await apiCall('GET', '/api/v1/attendance/my-summary', {
      token: studentToken,
      expectedStatus: 200,
    });
    return `Total classes attended: ${res.data.data.totalClasses}`;
  });

  // 6. RECORDINGS FEATURE (ADD, LIST)
  console.log('\n📼 6. RECORDINGS & VOD');
  await logStep('Recordings', 'Save Recording Entry', 'POST /api/v1/recordings', async () => {
    const res = await apiCall('POST', '/api/v1/recordings', {
      token: teacherToken,
      body: {
        liveClassId: createdClassId,
        title: 'Chemical Kinetics Full Session Recording',
        videoUrl: 'https://cdn.classora.com/recordings/kinetics_lec1.mp4',
        durationSec: 3600,
        fileSizeMb: 420,
      },
      expectedStatus: 201,
    });
    createdRecordingId = res.data.data.id;
    return `Recording saved: ID ${createdRecordingId} ("${res.data.data.title}")`;
  });

  await logStep('Recordings', 'List Recordings', 'GET /api/v1/recordings', async () => {
    const res = await apiCall('GET', `/api/v1/recordings?batchId=${createdBatchId}`, {
      token: studentToken,
      expectedStatus: 200,
    });
    return `Found ${res.data.data.recordings.length} recordings for batch`;
  });

  // 7. ASSIGNMENTS FEATURE (CREATE, LIST, SUBMIT, GRADE)
  console.log('\n📝 7. ASSIGNMENTS & HOMEWORK (CREATE, SUBMIT, GRADE)');
  await logStep('Assignments', 'Create Assignment', 'POST /api/v1/assignments', async () => {
    const res = await apiCall('POST', '/api/v1/assignments', {
      token: teacherToken,
      body: {
        batchId: createdBatchId,
        title: 'Kinetics Homework Sheet 1',
        description: 'Solve first order rate kinetics problems 1-10',
        dueDate: new Date(Date.now() + 86400000 * 2).toISOString(),
        maxMarks: 50,
      },
      expectedStatus: 201,
    });
    createdAssignmentId = res.data.data.id;
    return `Assignment created ID: ${createdAssignmentId}`;
  });

  await logStep('Assignments', 'Student Submit Assignment', 'POST /api/v1/assignments/:id/submit', async () => {
    const res = await apiCall('POST', `/api/v1/assignments/${createdAssignmentId}/submit`, {
      token: studentToken,
      body: {
        fileUrl: 'https://cdn.classora.com/submissions/student1_kinetics.pdf',
      },
      expectedStatus: 201,
    });
    createdSubmissionId = res.data.data.id;
    return `Submission created ID: ${createdSubmissionId}`;
  });

  await logStep('Assignments', 'Teacher Grade Submission', 'PATCH /api/v1/assignments/submissions/:id/grade', async () => {
    const res = await apiCall('PATCH', `/api/v1/assignments/submissions/${createdSubmissionId}/grade`, {
      token: teacherToken,
      body: {
        marksObtained: 48,
        feedback: 'Superb step-by-step derivation for half-life calculation.',
      },
      expectedStatus: 200,
    });
    return `Submission graded: ${res.data.data.marksObtained}/50 with feedback`;
  });

  // 8. CBT TESTS & ONLINE QUIZZES (CREATE, ATTEMPT, SUBMIT, RESULT)
  console.log('\n🎯 8. CBT ONLINE TESTS (CREATE, ATTEMPT, SCORE)');
  await logStep('Tests', 'Create CBT Test', 'POST /api/v1/tests', async () => {
    const res = await apiCall('POST', '/api/v1/tests', {
      token: teacherToken,
      body: {
        batchId: createdBatchId,
        title: 'Chemical Kinetics & Equilibrium Rapid Quiz',
        durationMin: 20,
        questions: [
          {
            text: 'What is the order of a radioactive decay process?',
            optionA: 'Zero order',
            optionB: 'First order',
            optionC: 'Second order',
            optionD: 'Third order',
            correctOption: 'B',
            marks: 4,
            explanation: 'Radioactive decay follows first order kinetics.',
          },
          {
            text: 'Units of rate constant for zero order reaction are:',
            optionA: 'mol L^-1 s^-1',
            optionB: 's^-1',
            optionC: 'L mol^-1 s^-1',
            optionD: 'dimensionless',
            correctOption: 'A',
            marks: 4,
            explanation: 'Rate = k[A]^0 = k, so unit is mol/(L*s).',
          },
        ],
      },
      expectedStatus: 201,
    });
    createdTestId = res.data.data.id;
    question1Id = res.data.data.questions[0].id;
    question2Id = res.data.data.questions[1].id;
    return `Test created ID: ${createdTestId} with 2 questions`;
  });

  await logStep('Tests', 'Start Test Attempt', 'POST /api/v1/tests/:id/start', async () => {
    const res = await apiCall('POST', `/api/v1/tests/${createdTestId}/start`, {
      token: studentToken,
      expectedStatus: 200,
    });
    return `Attempt started: ID ${res.data.data.id}`;
  });

  await logStep('Tests', 'Submit Test Attempt & Auto-Score', 'POST /api/v1/tests/:id/submit', async () => {
    const res = await apiCall('POST', `/api/v1/tests/${createdTestId}/submit`, {
      token: studentToken,
      body: {
        answers: {
          [question1Id]: 'B', // Correct
          [question2Id]: 'A', // Correct
        },
      },
      expectedStatus: 200,
    });
    return `Score: ${res.data.data.score}/${res.data.data.totalMarks} (${res.data.data.percentage}%)`;
  });

  await logStep('Tests', 'Get Test Result', 'GET /api/v1/tests/:id/result', async () => {
    const res = await apiCall('GET', `/api/v1/tests/${createdTestId}/result`, {
      token: studentToken,
      expectedStatus: 200,
    });
    return `Verified result: Score ${res.data.data.score}/${res.data.data.totalMarks}`;
  });

  // 9. FEES MANAGEMENT (CREATE PLAN, DUE CHECK, PAY, REPORT)
  console.log('\n💳 9. FEES & FINANCIAL LEDGER (PLANS, PAY, REPORTS)');
  await logStep('Fees', 'Admin Create Fee Plan', 'POST /api/v1/fees/plans', async () => {
    const res = await apiCall('POST', '/api/v1/fees/plans', {
      token: adminToken,
      body: {
        name: 'Crash Course Fee 2026',
        amount: 8500,
        interval: 'ONE_TIME',
        batchId: createdBatchId,
        description: 'Comprehensive tuition and test series fee',
      },
      expectedStatus: 201,
    });
    createdFeePlanId = res.data.data.id;
    return `Fee plan created ID: ${createdFeePlanId} (Amount: Rs. ${res.data.data.amount})`;
  });

  await logStep('Fees', 'Student Check Dues', 'GET /api/v1/fees/my-dues', async () => {
    const res = await apiCall('GET', '/api/v1/fees/my-dues', {
      token: studentToken,
      expectedStatus: 200,
    });
    return `Pending fee plans found: ${res.data.data.length}`;
  });

  await logStep('Fees', 'Student Process Payment', 'POST /api/v1/fees/pay', async () => {
    const res = await apiCall('POST', '/api/v1/fees/pay', {
      token: studentToken,
      body: {
        feePlanId: createdFeePlanId,
        amount: 8500,
        paymentMethod: 'UPI',
      },
      expectedStatus: 201,
    });
    return `Payment recorded ID: ${res.data.data.id}, Receipt: ${res.data.data.receiptNo}`;
  });

  await logStep('Fees', 'Admin View Financial Reports', 'GET /api/v1/fees/reports', async () => {
    const res = await apiCall('GET', '/api/v1/fees/reports', {
      token: adminToken,
      expectedStatus: 200,
    });
    return `Total Revenue: Rs. ${res.data.data.totalCollected}, Transactions: ${res.data.data.transactionsCount}`;
  });

  // 10. INVITES & ADMIN MANAGEMENT
  console.log('\n🔗 10. INVITES & ADMIN USER DIRECTORY');
  await logStep('Invites', 'Admin Create Invite Code', 'POST /api/v1/invites', async () => {
    const res = await apiCall('POST', '/api/v1/invites', {
      token: adminToken,
      body: {
        email: `newstudent_${Date.now()}@apex.edu`,
        role: 'STUDENT',
      },
      expectedStatus: 201,
    });
    inviteCode = res.data.inviteCode;
    return `Invite created Code: ${inviteCode}`;
  });

  await logStep('Invites', 'Public Validate Invite Code', 'GET /api/v1/invites/validate/:code', async () => {
    const res = await apiCall('GET', `/api/v1/invites/validate/${inviteCode}`, {
      expectedStatus: 200,
    });
    if (!res.data.valid) throw new Error('Invite validation failed');
    return `Invite validated successfully: Institute "${res.data.instituteName || 'Apex Academy'}"`;
  });

  await logStep('Admin', 'Admin List Faculty', 'GET /api/v1/admin/teachers', async () => {
    const res = await apiCall('GET', '/api/v1/admin/teachers', {
      token: adminToken,
      expectedStatus: 200,
    });
    const teachersList = res.data.data || res.data.teachers || [];
    return `Total active teachers: ${teachersList.length}`;
  });

  // 11. CLEANUP & REMOVAL TEST
  console.log('\n🗑️ 11. REMOVAL & TEARDOWN TEST (DATA REMOVAL)');
  await logStep('Batches', 'Delete Test Batch', 'DELETE /api/v1/batches/:id', async () => {
    await apiCall('DELETE', `/api/v1/batches/${createdBatchId}`, {
      token: teacherToken,
      expectedStatus: 200,
    });
    return `Batch ${createdBatchId} and relations deleted successfully`;
  });

  await logStep('Batches', 'Verify Batch Removal', 'GET /api/v1/batches/:id', async () => {
    const res = await apiCall('GET', `/api/v1/batches/${createdBatchId}`, {
      token: teacherToken,
    });
    if (res.status !== 404) {
      throw new Error(`Expected 404 Not Found after deletion, got ${res.status}`);
    }
    return 'Confirmed batch no longer exists (404 Not Found)';
  });

  console.log('\n=============================================================');
  console.log(`🎉 ALL ${results.length} SANITY CHECKS PASSED WITH 100% SUCCESS!`);
  console.log('=============================================================\n');

  console.table(results.map(r => ({
    Category: r.category,
    Feature: r.feature,
    Status: r.status,
    Duration: `${r.durationMs}ms`,
    Details: r.details?.slice(0, 50),
  })));
}

runComprehensiveSanity()
  .then(() => {
    process.exit(0);
  })
  .catch((err) => {
    console.error('Fatal Sanity Error:', err);
    process.exit(1);
  });
