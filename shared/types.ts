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

export interface ChatMessage {
  id: string;
  sender: string;
  message: string;
  role: string;
  timestamp: string;
}

export interface ActivePoll {
  id: string;
  question: string;
  options: { text: string; votes: number }[];
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
