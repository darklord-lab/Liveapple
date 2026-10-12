import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/learning_repository.dart';
import '../../domain/models/learning_models.dart';

final learningRepositoryProvider = Provider<LearningRepository>((ref) {
  return LearningRepository();
});

// 1. Recordings Provider
final recordingsProvider = FutureProvider.autoDispose<List<RecordingModel>>((ref) async {
  final repo = ref.watch(learningRepositoryProvider);
  return repo.getRecordings();
});

// 2. Assignments Provider
final assignmentsProvider = FutureProvider.autoDispose<List<AssignmentModel>>((ref) async {
  final repo = ref.watch(learningRepositoryProvider);
  return repo.getAssignments();
});

// 3. CBT Tests Provider
final cbtTestsProvider = FutureProvider.autoDispose<List<CbtTestModel>>((ref) async {
  final repo = ref.watch(learningRepositoryProvider);
  return repo.getTests();
});

// 4. Student Dues Provider
final studentDuesProvider = FutureProvider.autoDispose<StudentDuesModel>((ref) async {
  final repo = ref.watch(learningRepositoryProvider);
  return repo.getMyDues();
});

// 5. Student Attendance Summary Provider
final studentAttendanceProvider = FutureProvider.autoDispose<AttendanceSummaryModel>((ref) async {
  final repo = ref.watch(learningRepositoryProvider);
  return repo.getMyAttendanceSummary();
});

// 6. Admin Financial Report Provider
final adminFinancialReportProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(learningRepositoryProvider);
  return repo.getFinancialReport();
});
