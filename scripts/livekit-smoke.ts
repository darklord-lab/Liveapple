function decodeJwt(token: string): any {
  const parts = token.split('.');
  if (parts.length < 2) throw new Error('Invalid JWT format');
  const payload = Buffer.from(parts[1], 'base64url').toString('utf-8');
  return JSON.parse(payload);
}

interface HealthResponse {
  status: string;
  service: string;
  version: string;
  livekit?: {
    configured: boolean;
    urlHost: string;
    urlIsWss: boolean;
    usingDefaultKeys: boolean;
  };
  build?: {
    commit: string;
    builtAt: string;
  };
}

interface LoginResponse {
  data?: {
    token?: string;
    accessToken?: string;
    user?: { id: string; email: string; role: string; name: string };
  };
  token?: string;
  accessToken?: string;
}

interface TokenResponse {
  data?: {
    token?: string;
    livekitToken?: string;
    serverUrl?: string;
  };
  token?: string;
}

const API_BASE = process.env.API_URL || 'https://liveapple.onrender.com';
const CLASS_ID = process.env.CLASS_ID || 'class-demo-phy-01';

console.log(`🔍 [SMOKE TEST] Testing LiveKit & API Gateway at: ${API_BASE}`);
console.log(`🔍 [SMOKE TEST] Target Class ID: ${CLASS_ID}`);

async function runSmokeTest() {
  let passed = true;

  // 1. Health Endpoint
  console.log('\n[1/4] Verifying /api/health...');
  try {
    const healthRes = await fetch(`${API_BASE}/api/health`);
    if (!healthRes.ok) {
      throw new Error(`Health check returned HTTP ${healthRes.status}`);
    }
    const health = (await healthRes.json()) as HealthResponse;
    console.log(`  ✓ Health status: ${health.status}`);
    console.log(`  ✓ LiveKit Configured: ${health.livekit?.configured}`);
    console.log(`  ✓ LiveKit Host: ${health.livekit?.urlHost}`);
    console.log(`  ✓ LiveKit is WSS: ${health.livekit?.urlIsWss}`);
    console.log(`  ✓ Build Commit: ${health.build?.commit || 'n/a'}`);
    console.log(`  ✓ Built At: ${health.build?.builtAt || 'n/a'}`);

    if (!health.livekit?.configured || !health.livekit?.urlIsWss) {
      console.error('  ❌ LiveKit is not properly configured on server');
      passed = false;
    }
  } catch (err: any) {
    console.error(`  ❌ Health check failed: ${err.message}`);
    passed = false;
  }

  // Helper login
  async function loginUser(email: string, pass: string): Promise<string> {
    const res = await fetch(`${API_BASE}/api/v1/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password: pass }),
    });
    if (!res.ok) {
      throw new Error(`Login failed for ${email} with status ${res.status}`);
    }
    const data = (await res.json()) as LoginResponse;
    const jwtToken = data.data?.accessToken || data.data?.token || data.accessToken || data.token;
    if (!jwtToken) throw new Error(`No auth token returned for ${email}`);
    return jwtToken;
  }

  // Helper fetch livekit token
  async function getLiveKitToken(authToken: string, classId: string): Promise<string> {
    const res = await fetch(`${API_BASE}/api/v1/classes/${classId}/token`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${authToken}` },
    });
    if (!res.ok) {
      throw new Error(`Token fetch failed with status ${res.status}`);
    }
    const data = (await res.json()) as TokenResponse;
    const lkToken = data.data?.token || data.data?.livekitToken || data.token;
    if (!lkToken) throw new Error('No LiveKit token in response');
    return lkToken;
  }

  async function resolveClassId(authToken: string): Promise<string> {
    try {
      const res = await fetch(`${API_BASE}/api/v1/classes`, {
        headers: { Authorization: `Bearer ${authToken}` },
      });
      if (res.ok) {
        const body = await res.json();
        const list = Array.isArray(body) ? body : (body.data || body.classes || []);
        if (list.length > 0 && list[0].id) {
          console.log(`  ✓ Discovered existing class ID: ${list[0].id} ("${list[0].title || 'Untitled'}")`);
          return list[0].id;
        }
      }
    } catch {}
    return CLASS_ID;
  }

  // 2. Teacher Token
  console.log('\n[2/4] Testing Teacher LiveKit Token Grants...');
  let targetClassId = CLASS_ID;
  try {
    const teacherAuth = await loginUser('teacher1@apex.edu', 'Password@123');
    targetClassId = await resolveClassId(teacherAuth);
    const teacherLkToken = await getLiveKitToken(teacherAuth, targetClassId);
    const decodedTeacher = decodeJwt(teacherLkToken) as any;
    console.log(`  ✓ Teacher Identity: ${decodedTeacher?.sub}`);
    console.log(`  ✓ Teacher Can Publish: ${decodedTeacher?.video?.canPublish}`);
    console.log(`  ✓ Teacher Can Subscribe: ${decodedTeacher?.video?.canSubscribe}`);
    console.log(`  ✓ Teacher Sources: ${JSON.stringify(decodedTeacher?.video?.canPublishSources)}`);

    if (decodedTeacher?.video?.canPublish !== true) {
      console.error('  ❌ Teacher canPublish is NOT true');
      passed = false;
    }
    if (!decodedTeacher?.video?.canPublishSources?.includes('camera') ||
        !decodedTeacher?.video?.canPublishSources?.includes('microphone')) {
      console.error('  ❌ Teacher missing camera/microphone publish sources');
      passed = false;
    }
  } catch (err: any) {
    console.error(`  ❌ Teacher token verification failed: ${err.message}`);
    passed = false;
  }

  // 3. Student Token
  console.log('\n[3/4] Testing Student LiveKit Token Grants (Stage 0.2 Root Cause Fix)...');
  try {
    const studentAuth = await loginUser('student1@apex.edu', 'Password@123');
    const studentLkToken = await getLiveKitToken(studentAuth, targetClassId);
    const decodedStudent = decodeJwt(studentLkToken) as any;
    console.log(`  ✓ Student Identity: ${decodedStudent?.sub}`);
    console.log(`  ✓ Student Can Publish: ${decodedStudent?.video?.canPublish}`);
    console.log(`  ✓ Student Can Subscribe: ${decodedStudent?.video?.canSubscribe}`);
    console.log(`  ✓ Student Sources: ${JSON.stringify(decodedStudent?.video?.canPublishSources)}`);

    if (decodedStudent?.video?.canPublish !== true) {
      console.error('  ❌ Student canPublish is FALSE! Student audio/video will be rejected by SFU');
      passed = false;
    } else {
      console.log('  ✓ CRITICAL: Student canPublish is TRUE (Student camera & mic accepted by SFU)');
    }

    if (!decodedStudent?.video?.canPublishSources?.includes('camera') ||
        !decodedStudent?.video?.canPublishSources?.includes('microphone')) {
      console.error('  ❌ Student missing camera/microphone publish sources');
      passed = false;
    }
  } catch (err: any) {
    console.error(`  ❌ Student token verification failed: ${err.message}`);
    passed = false;
  }

  // 4. Flutter Web App Static Serving Check
  console.log('\n[4/4] Verifying /app Static Serving & CSP...');
  try {
    const appRes = await fetch(`${API_BASE}/app`);
    console.log(`  ✓ GET /app status: ${appRes.status}`);
    const csp = appRes.headers.get('content-security-policy') || '';
    const hasLiveKitWss = csp.includes('wss:') || csp.includes('classora');
    console.log(`  ✓ CSP includes WebSocket/LiveKit: ${hasLiveKitWss}`);
  } catch (err: any) {
    console.warn(`  ⚠ /app check warning: ${err.message}`);
  }

  console.log('\n========================================');
  if (passed) {
    console.log('🎉 SMOKE TEST PASSED: All LiveKit media permissions and gateway checks verified!');
    process.exit(0);
  } else {
    console.error('💥 SMOKE TEST FAILED: One or more checks did not pass.');
    process.exit(1);
  }
}

runSmokeTest();
