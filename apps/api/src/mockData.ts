export interface Institute {
  id: string;
  name: string;
  slug: string;
  plan: 'Starter' | 'Growth' | 'Pro' | 'Enterprise';
  logo_url: string;
  custom_domain?: string;
  status: 'active' | 'inactive';
  created_at: string;
}

export interface User {
  id: string;
  institute_id: string;
  name: string;
  email: string;
  phone: string;
  role: 'owner' | 'admin' | 'teacher' | 'student' | 'parent';
  avatar_url: string;
  status: 'active' | 'suspended';
  created_at: string;
}

export interface Course {
  id: string;
  institute_id: string;
  name: string;
  description: string;
  cover_image: string;
  subjects: {
    id: string;
    name: string;
    chapters: {
      id: string;
      name: string;
      order_index: number;
      notes_count: number;
    }[];
  }[];
}

export interface Batch {
  id: string;
  institute_id: string;
  name: string;
  course_id: string;
  course_name: string;
  teacher_name: string;
  student_count: number;
  start_date: string;
  end_date: string;
}

export interface LiveClass {
  id: string;
  institute_id: string;
  batch_id: string;
  batch_name: string;
  teacher_id: string;
  teacher_name: string;
  subject_name: string;
  chapter_id: string;
  chapter_name: string;
  title: string;
  scheduled_at: string;
  started_at?: string;
  ended_at?: string;
  room_id: string;
  status: 'scheduled' | 'live' | 'completed';
  recording_url?: string;
  duration_sec?: number;
}

export interface Assignment {
  id: string;
  institute_id: string;
  chapter_id: string;
  chapter_name: string;
  subject_name: string;
  teacher_id: string;
  title: string;
  description: string;
  due_date: string;
  attachment_url?: string;
  total_submissions: number;
  pending_grading: number;
}

export interface TestQuestion {
  id: string;
  test_id: string;
  type: 'mcq' | 'numerical';
  question_text: string;
  options?: string[];
  correct_answer: string;
  marks: number;
}

export interface OnlineTest {
  id: string;
  institute_id: string;
  chapter_id: string;
  chapter_name: string;
  subject_name: string;
  title: string;
  duration_min: number;
  total_marks: number;
  negative_marking: number;
  status: 'upcoming' | 'live' | 'completed';
  questions: TestQuestion[];
}

export interface FeePlan {
  id: string;
  institute_id: string;
  course_id: string;
  course_name: string;
  title: string;
  amount: number;
  installments_allowed: boolean;
}

export interface FeeTransaction {
  id: string;
  institute_id: string;
  fee_plan_id: string;
  student_id: string;
  student_name: string;
  course_name: string;
  amount_paid: number;
  total_amount: number;
  mode: 'UPI' | 'Razorpay' | 'Card' | 'Cash';
  txn_id: string;
  status: 'paid' | 'pending' | 'overdue';
  paid_at: string;
}

export const initialInstitutes: Institute[] = [
  {
    id: 'inst-apex-01',
    name: 'Apex IIT-JEE & Medical Academy',
    slug: 'apex-academy',
    plan: 'Pro',
    logo_url: 'https://images.unsplash.com/photo-1546410531-bb4caa6b424d?w=100&h=100&fit=crop&crop=faces',
    custom_domain: 'learn.apexacademy.in',
    status: 'active',
    created_at: '2025-01-10T10:00:00Z',
  }
];

export const initialUsers: User[] = [
  {
    id: 'usr-admin-01',
    institute_id: 'inst-apex-01',
    name: 'Dr. Vikramaditya Sen',
    email: 'admin@apex.edu',
    phone: '+91 98765 43210',
    role: 'owner',
    avatar_url: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&h=100&fit=crop&crop=faces',
    status: 'active',
    created_at: '2025-01-10T10:00:00Z',
  },
  {
    id: 'usr-teacher-01',
    institute_id: 'inst-apex-01',
    name: 'Prof. Rajesh Sharma',
    email: 'teacher@apex.edu',
    phone: '+91 98111 22334',
    role: 'teacher',
    avatar_url: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop&crop=faces',
    status: 'active',
    created_at: '2025-01-12T10:00:00Z',
  },
  {
    id: 'usr-student-01',
    institute_id: 'inst-apex-01',
    name: 'Aarav Patel',
    email: 'student@apex.edu',
    phone: '+91 99000 11223',
    role: 'student',
    avatar_url: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=100&h=100&fit=crop&crop=faces',
    status: 'active',
    created_at: '2025-02-01T10:00:00Z',
  },
  {
    id: 'usr-student-02',
    institute_id: 'inst-apex-01',
    name: 'Priya Singh',
    email: 'priya.singh@apex.edu',
    phone: '+91 99000 44556',
    role: 'student',
    avatar_url: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&h=100&fit=crop&crop=faces',
    status: 'active',
    created_at: '2025-02-03T10:00:00Z',
  },
  {
    id: 'usr-student-03',
    institute_id: 'inst-apex-01',
    name: 'Rohan Verma',
    email: 'rohan.verma@apex.edu',
    phone: '+91 99000 77889',
    role: 'student',
    avatar_url: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&h=100&fit=crop&crop=faces',
    status: 'active',
    created_at: '2025-02-05T10:00:00Z',
  }
];

export const initialCourses: Course[] = [
  {
    id: 'crs-jee-01',
    institute_id: 'inst-apex-01',
    name: 'Class 12th — IIT-JEE Masterclass (Physics)',
    description: 'Advanced mechanics, electromagnetism, modern physics with live interactive problem solving.',
    cover_image: 'https://images.unsplash.com/photo-1636466497217-26a8cbeaf0aa?w=600&h=340&fit=crop',
    subjects: [
      {
        id: 'sub-phy-01',
        name: 'Physics',
        chapters: [
          { id: 'ch-01', name: 'Rotational Dynamics & Torque', order_index: 1, notes_count: 5 },
          { id: 'ch-02', name: 'Electrostatics & Gauss Law', order_index: 2, notes_count: 8 },
          { id: 'ch-03', name: 'Electromagnetic Induction & AC Circuits', order_index: 3, notes_count: 6 },
          { id: 'ch-04', name: 'Ray Optics & Wave Theory', order_index: 4, notes_count: 7 }
        ]
      }
    ]
  },
  {
    id: 'crs-neet-02',
    institute_id: 'inst-apex-01',
    name: 'Class 11th & 12th — NEET Chemistry Intensive',
    description: 'Organic reaction mechanisms, physical chemistry equilibrium, and inorganic periodic trends.',
    cover_image: 'https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=600&h=340&fit=crop',
    subjects: [
      {
        id: 'sub-chem-01',
        name: 'Chemistry',
        chapters: [
          { id: 'ch-c1', name: 'Chemical Bonding & Molecular Structure', order_index: 1, notes_count: 4 },
          { id: 'ch-c2', name: 'Thermodynamics & Thermochemistry', order_index: 2, notes_count: 6 }
        ]
      }
    ]
  }
];

export const initialBatches: Batch[] = [
  {
    id: 'batch-jee-2026',
    institute_id: 'inst-apex-01',
    name: 'JEE Super 30 (Batch Alpha)',
    course_id: 'crs-jee-01',
    course_name: 'Class 12th — IIT-JEE Masterclass',
    teacher_name: 'Prof. Rajesh Sharma',
    student_count: 32,
    start_date: '2025-04-01',
    end_date: '2026-03-31',
  },
  {
    id: 'batch-neet-2026',
    institute_id: 'inst-apex-01',
    name: 'NEET Droppers Batch Beta',
    course_id: 'crs-neet-02',
    course_name: 'Class 11th & 12th — NEET Chemistry Intensive',
    teacher_name: 'Dr. A. K. Gupta',
    student_count: 28,
    start_date: '2025-05-01',
    end_date: '2026-04-30',
  }
];

export const initialLiveClasses: LiveClass[] = [
  {
    id: 'live-class-01',
    institute_id: 'inst-apex-01',
    batch_id: 'batch-jee-2026',
    batch_name: 'JEE Super 30 (Batch Alpha)',
    teacher_id: 'usr-teacher-01',
    teacher_name: 'Prof. Rajesh Sharma',
    subject_name: 'Physics',
    chapter_id: 'ch-01',
    chapter_name: 'Rotational Dynamics & Torque',
    title: 'Angular Momentum Conservation & Rolling Motion',
    scheduled_at: '2026-09-09T18:00:00Z',
    started_at: '2026-09-09T18:30:00Z',
    room_id: 'room-jee-super30-phy',
    status: 'live',
  },
  {
    id: 'live-class-02',
    institute_id: 'inst-apex-01',
    batch_id: 'batch-jee-2026',
    batch_name: 'JEE Super 30 (Batch Alpha)',
    teacher_id: 'usr-teacher-01',
    teacher_name: 'Prof. Rajesh Sharma',
    subject_name: 'Physics',
    chapter_id: 'ch-02',
    chapter_name: 'Electrostatics & Gauss Law',
    title: 'Electric Flux Calculation & Conductors in Field',
    scheduled_at: '2026-09-10T11:00:00Z',
    room_id: 'room-jee-super30-elec',
    status: 'scheduled',
  },
  {
    id: 'live-class-rec-01',
    institute_id: 'inst-apex-01',
    batch_id: 'batch-jee-2026',
    batch_name: 'JEE Super 30 (Batch Alpha)',
    teacher_id: 'usr-teacher-01',
    teacher_name: 'Prof. Rajesh Sharma',
    subject_name: 'Physics',
    chapter_id: 'ch-01',
    chapter_name: 'Rotational Dynamics',
    title: 'Moment of Inertia of Symmetrical Bodies',
    scheduled_at: '2026-09-08T18:00:00Z',
    started_at: '2026-09-08T18:00:00Z',
    ended_at: '2026-09-08T19:25:00Z',
    room_id: 'room-rec-01',
    status: 'completed',
    recording_url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    duration_sec: 5100,
  }
];

export const initialAssignments: Assignment[] = [
  {
    id: 'asg-01',
    institute_id: 'inst-apex-01',
    chapter_id: 'ch-01',
    chapter_name: 'Rotational Dynamics',
    subject_name: 'Physics',
    teacher_id: 'usr-teacher-01',
    title: 'Advanced Problems on Pure Rolling with Friction',
    description: 'Solve problem set 4.1 to 4.15 from Irodov / Advanced JEE problem bank. Upload handwritten solution PDF.',
    due_date: '2026-09-12T23:59:59Z',
    total_submissions: 24,
    pending_grading: 5,
  },
  {
    id: 'asg-02',
    institute_id: 'inst-apex-01',
    chapter_id: 'ch-02',
    chapter_name: 'Electrostatics',
    subject_name: 'Physics',
    teacher_id: 'usr-teacher-01',
    title: 'Gauss Law Applications on Non-Conducting Spheres',
    description: 'Calculate E-field across internal cavity and surface charge induction with diagrams.',
    due_date: '2026-09-15T23:59:59Z',
    total_submissions: 12,
    pending_grading: 12,
  }
];

export const initialTests: OnlineTest[] = [
  {
    id: 'test-jee-01',
    institute_id: 'inst-apex-01',
    chapter_id: 'ch-01',
    chapter_name: 'Rotational Dynamics',
    subject_name: 'Physics',
    title: 'Weekly Test 04: Rigid Body Dynamics & Collisions',
    duration_min: 45,
    total_marks: 40,
    negative_marking: 1,
    status: 'live',
    questions: [
      {
        id: 'q-01',
        test_id: 'test-jee-01',
        type: 'mcq',
        question_text: 'A uniform disc of mass M and radius R rolls without slipping down an inclined plane of angle θ. What is the linear acceleration of its center of mass?',
        options: [
          '(2/3) g sin θ',
          '(1/2) g sin θ',
          '(3/4) g sin θ',
          'g sin θ'
        ],
        correct_answer: '(2/3) g sin θ',
        marks: 4
      },
      {
        id: 'q-02',
        test_id: 'test-jee-01',
        type: 'mcq',
        question_text: 'A particle of mass m is moving with velocity v perpendicular to a rod of length L pivoted at one end. If it sticks to the free end, what is the resulting angular velocity?',
        options: [
          '3v / (4L)',
          'v / L',
          '3v / L',
          'v / (2L)'
        ],
        correct_answer: '3v / (4L)',
        marks: 4
      },
      {
        id: 'q-03',
        test_id: 'test-jee-01',
        type: 'mcq',
        question_text: 'The ratio of rotational kinetic energy to total kinetic energy for a solid sphere rolling without slipping is:',
        options: [
          '2 / 7',
          '5 / 7',
          '2 / 5',
          '1 / 2'
        ],
        correct_answer: '2 / 7',
        marks: 4
      }
    ]
  }
];

export const initialFeePlans: FeePlan[] = [
  {
    id: 'fee-plan-01',
    institute_id: 'inst-apex-01',
    course_id: 'crs-jee-01',
    course_name: 'Class 12th — IIT-JEE Masterclass',
    title: 'Annual Academic Tuition 2025-2026',
    amount: 65000,
    installments_allowed: true,
  }
];

export const initialFeeTransactions: FeeTransaction[] = [
  {
    id: 'txn-01',
    institute_id: 'inst-apex-01',
    fee_plan_id: 'fee-plan-01',
    student_id: 'usr-student-01',
    student_name: 'Aarav Patel',
    course_name: 'Class 12th — IIT-JEE Masterclass',
    amount_paid: 45000,
    total_amount: 65000,
    mode: 'Razorpay',
    txn_id: 'pay_Or9Bw82kLAp91',
    status: 'pending',
    paid_at: '2025-06-15T14:20:00Z',
  },
  {
    id: 'txn-02',
    institute_id: 'inst-apex-01',
    fee_plan_id: 'fee-plan-01',
    student_id: 'usr-student-02',
    student_name: 'Priya Singh',
    course_name: 'Class 12th — IIT-JEE Masterclass',
    amount_paid: 65000,
    total_amount: 65000,
    mode: 'UPI',
    txn_id: 'pay_Nx210Ka8Lk31',
    status: 'paid',
    paid_at: '2025-05-10T11:00:00Z',
  },
  {
    id: 'txn-03',
    institute_id: 'inst-apex-01',
    fee_plan_id: 'fee-plan-01',
    student_id: 'usr-student-03',
    student_name: 'Rohan Verma',
    course_name: 'Class 12th — IIT-JEE Masterclass',
    amount_paid: 0,
    total_amount: 65000,
    mode: 'Cash',
    txn_id: 'overdue_03',
    status: 'overdue',
    paid_at: '',
  }
];
