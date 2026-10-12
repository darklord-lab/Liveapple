import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/teacher_model.dart';

class AdminRepository {
  final ApiClient _apiClient;

  AdminRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> getTeachers({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty && status != 'ALL') 'status': status,
      };

      final response = await _apiClient.dio.get(
        '/v1/admin/teachers',
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      final teacherList = (data['data'] as List?) ?? [];
      final pagination = data['pagination'] as Map<String, dynamic>? ?? {};

      final teachers = teacherList.map((e) => TeacherModel.fromJson(e as Map<String, dynamic>)).toList();

      return {
        'teachers': teachers,
        'pagination': pagination,
      };
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(code: 'NETWORK_ERROR', message: e.message ?? 'Failed to load teachers');
    }
  }

  Future<AddTeacherResult> addTeacher({
    required String name,
    required String email,
    String? phone,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/v1/admin/teachers',
        data: {
          'name': name.trim(),
          'email': email.trim(),
          if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
        },
      );

      return AddTeacherResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(code: 'ADD_TEACHER_ERROR', message: e.message ?? 'Failed to add teacher');
    }
  }

  Future<BulkOnboardReport> bulkOnboard({required String csvText}) async {
    try {
      final response = await _apiClient.dio.post(
        '/v1/admin/teachers/bulk',
        data: {'csvText': csvText.trim()},
      );

      return BulkOnboardReport.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(code: 'BULK_ONBOARD_ERROR', message: e.message ?? 'Failed to process bulk onboard');
    }
  }

  Future<TeacherModel> updateTeacherStatus({
    required String teacherId,
    required String newStatus,
  }) async {
    try {
      final response = await _apiClient.dio.patch(
        '/v1/admin/teachers/$teacherId/status',
        data: {'status': newStatus},
      );

      final teacherData = response.data['teacher'] as Map<String, dynamic>;
      return TeacherModel.fromJson(teacherData);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(code: 'STATUS_UPDATE_ERROR', message: e.message ?? 'Failed to update teacher status');
    }
  }
}
