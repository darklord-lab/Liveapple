export type UserRole = 'owner' | 'admin' | 'teacher' | 'student' | 'parent';

export interface User {
  id: string;
  institute_id: string;
  name: string;
  email: string;
  phone: string;
  role: UserRole;
  avatar_url: string;
  status: 'active' | 'suspended';
}

export interface Institute {
  id: string;
  name: string;
  slug: string;
  plan: string;
  logo_url: string;
  custom_domain?: string;
}

export interface LiveClass {
  id: string;
  batch_name: string;
  teacher_name: string;
  subject_name: string;
  chapter_name: string;
  title: string;
  scheduled_at: string;
  room_id: string;
  status: 'scheduled' | 'live' | 'completed';
  recording_url?: string;
  duration_sec?: number;
}

export interface Assignment {
  id: string;
  chapter_name: string;
  subject_name: string;
  title: string;
  description: string;
  due_date: string;
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
  title: string;
  subject_name: string;
  chapter_name: string;
  duration_min: number;
  total_marks: number;
  negative_marking: number;
  status: 'upcoming' | 'live' | 'completed';
  questions: TestQuestion[];
}

export interface FeeTransaction {
  id: string;
  student_name: string;
  course_name: string;
  amount_paid: number;
  total_amount: number;
  mode: string;
  txn_id: string;
  status: 'paid' | 'pending' | 'overdue';
  paid_at: string;
}

export interface ChatMessage {
  id: string;
  sender: string;
  message: string;
  role: string;
  timestamp: string;
}

export interface PollOption {
  text: string;
  votes: number;
}

export interface ActivePoll {
  id: string;
  question: string;
  options: PollOption[];
  totalVotes: number;
  active: boolean;
}

export interface DoubtItem {
  id: string;
  studentName: string;
  doubtText: string;
  status: 'pending' | 'resolved';
  timestamp: string;
}
