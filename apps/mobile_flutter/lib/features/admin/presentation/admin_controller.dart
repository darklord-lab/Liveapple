import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/admin_repository.dart';
import '../domain/teacher_model.dart';
import '../../../core/errors/app_exception.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});

class AdminTeachersState {
  final bool isLoading;
  final bool isSubmitting;
  final List<TeacherModel> teachers;
  final String searchQuery;
  final String statusFilter; // "ALL" | "ACTIVE" | "INVITED" | "SUSPENDED"
  final String? errorMessage;
  final int totalCount;

  const AdminTeachersState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.teachers = const [],
    this.searchQuery = '',
    this.statusFilter = 'ALL',
    this.errorMessage,
    this.totalCount = 0,
  });

  AdminTeachersState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    List<TeacherModel>? teachers,
    String? searchQuery,
    String? statusFilter,
    String? errorMessage,
    int? totalCount,
  }) {
    return AdminTeachersState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      teachers: teachers ?? this.teachers,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      errorMessage: errorMessage,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

final adminTeachersProvider =
    StateNotifierProvider<AdminTeachersNotifier, AdminTeachersState>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return AdminTeachersNotifier(repository);
});

class AdminTeachersNotifier extends StateNotifier<AdminTeachersState> {
  final AdminRepository _repository;

  AdminTeachersNotifier(this._repository) : super(const AdminTeachersState()) {
    loadTeachers();
  }

  Future<void> loadTeachers() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _repository.getTeachers(
        search: state.searchQuery,
        status: state.statusFilter,
      );

      final teachers = result['teachers'] as List<TeacherModel>;
      final pagination = result['pagination'] as Map<String, dynamic>;
      final total = pagination['total'] as int? ?? teachers.length;

      state = state.copyWith(
        isLoading: false,
        teachers: teachers,
        totalCount: total,
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load teachers');
    }
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
    loadTeachers();
  }

  void setStatusFilter(String filter) {
    state = state.copyWith(statusFilter: filter);
    loadTeachers();
  }

  Future<AddTeacherResult?> addTeacher({
    required String name,
    required String email,
    String? phone,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final result = await _repository.addTeacher(
        name: name,
        email: email,
        phone: phone,
      );

      // Prepend newly added teacher and refresh list
      state = state.copyWith(
        isSubmitting: false,
        teachers: [result.teacher, ...state.teachers],
        totalCount: state.totalCount + 1,
      );
      return result;
    } on AppException catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.message);
      return null;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: 'Failed to add teacher');
      return null;
    }
  }

  Future<BulkOnboardReport?> bulkOnboard(String csvText) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final report = await _repository.bulkOnboard(csvText: csvText);
      state = state.copyWith(isSubmitting: false);
      // Reload full teacher list
      loadTeachers();
      return report;
    } on AppException catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.message);
      return null;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: 'Failed to process bulk upload');
      return null;
    }
  }

  Future<bool> toggleTeacherStatus(String teacherId, String currentStatus) async {
    final nextStatus = currentStatus == 'ACTIVE' ? 'SUSPENDED' : 'ACTIVE';
    try {
      final updated = await _repository.updateTeacherStatus(
        teacherId: teacherId,
        newStatus: nextStatus,
      );

      final updatedList = state.teachers.map((t) {
        return t.id == teacherId ? updated : t;
      }).toList();

      state = state.copyWith(teachers: updatedList);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update status');
      return false;
    }
  }
}
