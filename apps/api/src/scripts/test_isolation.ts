const BASE_URL = 'http://localhost:4000';

async function api(method: string, path: string, token?: string, body?: any) {
  const headers: Record<string, string> = { 'Content-Type': 'application/json' };
  if (token) headers['Authorization'] = `Bearer ${token}`;
  const res = await fetch(`${BASE_URL}${path}`, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  try {
    return { status: res.status, data: JSON.parse(text) };
  } catch {
    return { status: res.status, text };
  }
}

async function runIsolationTests() {
  console.log('\n🔒 RUNNING STRICT TEACHER-STUDENT ISOLATION & ADMIN VERIFICATION SUITE...\n');

  // 1. Admin Login
  const adminRes = await api('POST', '/api/v1/auth/login', undefined, {
    email: 'admin@apex.edu',
    password: 'Password@123',
  });
  if (adminRes.status !== 200) throw new Error('Admin login failed');
  const adminToken = adminRes.data.accessToken;
  console.log('✅ 1. Admin authenticated successfully');

  // 2. Student 1 Login (Assigned to Teacher 1: Rajesh Sharma)
  const s1Res = await api('POST', '/api/v1/auth/login', undefined, {
    email: 'student1@apex.edu',
    password: 'Password@123',
  });
  if (s1Res.status !== 200) throw new Error('Student 1 login failed');
  const s1Token = s1Res.data.accessToken;
  const s1Teacher = s1Res.data.teacher;
  if (!s1Teacher || s1Teacher.name !== 'Prof. Rajesh Sharma') {
    throw new Error(`Student 1 teacher mismatch: expected Rajesh Sharma, got ${JSON.stringify(s1Teacher)}`);
  }
  console.log(`✅ 2. Student 1 received Teacher Branding: "${s1Teacher.coachingName}" (${s1Teacher.name})`);

  // 3. Student 4 Login (Assigned to Teacher 2: Anita Verma)
  const s4Res = await api('POST', '/api/v1/auth/login', undefined, {
    email: 'student4@apex.edu',
    password: 'Password@123',
  });
  if (s4Res.status !== 200) throw new Error('Student 4 login failed');
  const s4Token = s4Res.data.accessToken;
  const s4Teacher = s4Res.data.teacher;
  if (!s4Teacher || s4Teacher.name !== 'Prof. Anita Verma') {
    throw new Error(`Student 4 teacher mismatch: expected Anita Verma, got ${JSON.stringify(s4Teacher)}`);
  }
  console.log(`✅ 3. Student 4 received Teacher Branding: "${s4Teacher.coachingName}" (${s4Teacher.name})`);

  // 4. Student 1 Batches Isolation (Should only see Rajesh Sharma's batches)
  const s1Batches = await api('GET', '/api/v1/batches', s1Token);
  if (s1Batches.status !== 200) throw new Error('Student 1 list batches failed');
  for (const b of s1Batches.data.batches) {
    if (b.teacher?.name !== 'Prof. Rajesh Sharma') {
      throw new Error(`LEAK DETECTED! Student 1 saw batch taught by ${b.teacher?.name}`);
    }
  }
  console.log(`✅ 4. Student 1 batches strictly isolated to Teacher 1 (${s1Batches.data.batches.length} batches)`);

  // 5. Student 4 Cross-Teacher Forbidden Access Check
  // Student 4 tries to access Rajesh Sharma's physics batch
  const physicsBatchId = s1Batches.data.batches[0].id;
  const s4Forbidden = await api('GET', `/api/v1/batches/${physicsBatchId}`, s4Token);
  if (s4Forbidden.status !== 403) {
    throw new Error(`Expected 403 FORBIDDEN when Student 4 accesses Teacher 1 batch, got ${s4Forbidden.status}`);
  }
  console.log(`✅ 5. Cross-teacher access blocked with HTTP 403 FORBIDDEN: "${s4Forbidden.data.message}"`);

  // 6. Super Admin Teacher Management (Add, Update, Delete)
  const newTeacherRes = await api('POST', '/api/v1/admin/teachers', adminToken, {
    name: 'Dr. H. C. Verma',
    email: `hcverma_${Date.now()}@apex.edu`,
    phone: '+91 99999 11111',
    password: 'Password@123',
    coachingName: 'Concept Physics Institute',
    subjects: 'Theoretical Physics, Quantum Mechanics',
  });
  if (newTeacherRes.status !== 201) throw new Error(`Add teacher failed: ${JSON.stringify(newTeacherRes.data)}`);
  const createdTeacherId = newTeacherRes.data.teacher.id;
  console.log(`✅ 6. Super Admin created new teacher "${newTeacherRes.data.teacher.name}" (${newTeacherRes.data.teacher.coachingName})`);

  // Update Teacher Coaching Profile
  const updateRes = await api('PATCH', `/api/v1/admin/teachers/${createdTeacherId}`, adminToken, {
    coachingName: 'Concept Physics Institute (Updated)',
    bio: 'Renowned author and mentor to thousands of scholars.',
  });
  if (updateRes.status !== 200) throw new Error(`Update teacher failed: ${JSON.stringify(updateRes.data)}`);
  console.log(`✅ 7. Super Admin updated teacher profile: "${updateRes.data.teacher.coachingName}"`);

  // 7. Super Admin Student Directory with Teacher Filter
  const allStudentsRes = await api('GET', '/api/v1/admin/students', adminToken);
  const teacher1StudentsRes = await api('GET', `/api/v1/admin/students?teacherId=${s1Teacher.id}`, adminToken);
  if (allStudentsRes.status !== 200 || teacher1StudentsRes.status !== 200) {
    throw new Error('List students failed');
  }
  console.log(`✅ 8. Super Admin Student Directory: Total ${allStudentsRes.data.data.length} students, Filtered by Teacher 1: ${teacher1StudentsRes.data.data.length} students`);

  // 8. Super Admin Batches with Teacher Filter
  const filteredBatchesRes = await api('GET', `/api/v1/batches?teacherId=${s1Teacher.id}`, adminToken);
  if (filteredBatchesRes.status !== 200) throw new Error('Admin filter batches failed');
  console.log(`✅ 9. Super Admin Batches filtered by Teacher 1: ${filteredBatchesRes.data.batches.length} batches`);

  // 9. Super Admin Clean Up Test Teacher
  const deleteRes = await api('DELETE', `/api/v1/admin/teachers/${createdTeacherId}`, adminToken);
  if (deleteRes.status !== 200) throw new Error('Delete teacher failed');
  console.log(`✅ 10. Super Admin deleted test teacher successfully: ${deleteRes.data.message}`);

  console.log('\n🎉 ALL 10 STRICT ISOLATION & ADMIN MANAGEMENT CHECKS PASSED WITH 100% SUCCESS!\n');
}

runIsolationTests()
  .then(() => process.exit(0))
  .catch((e) => {
    console.error('❌ Test failed:', e);
    process.exit(1);
  });
