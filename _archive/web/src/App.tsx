import React, { useState } from 'react';
import { LoginPage, UserSession } from './pages/auth/LoginPage.js';
import { StudentDashboard } from './pages/student/StudentDashboard.js';
import { TeacherDashboard } from './pages/teacher/TeacherDashboard.js';

export function App() {
  const [currentUser, setCurrentUser] = useState<UserSession | null>(null);

  const handleLoginSuccess = (user: UserSession) => {
    setCurrentUser(user);
  };

  const handleLogout = () => {
    setCurrentUser(null);
  };

  // 1. Initial State: If not logged in, render Safe Role-Based Login Screen
  if (!currentUser) {
    return <LoginPage onLoginSuccess={handleLoginSuccess} />;
  }

  // 2. Authenticated State: Route to Student vs Teacher Portal based on user role
  if (currentUser.role === 'student') {
    return <StudentDashboard userSession={currentUser} onLogout={handleLogout} />;
  }

  return <TeacherDashboard userSession={currentUser} onLogout={handleLogout} />;
}

export default App;
