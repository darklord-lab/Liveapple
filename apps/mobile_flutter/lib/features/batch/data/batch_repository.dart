import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/batch_model.dart';

class BatchRepository {
  final ApiClient _apiClient;

  BatchRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<BatchModel>> getBatches({String? search, String? teacherId}) async {
    try {
      final queryParams = <String, dynamic>{
        if (search != null && search.isNotEmpty) 'search': search,
        if (teacherId != null && teacherId.isNotEmpty) 'teacherId': teacherId,
      };

      final response = await _apiClient.dio.get(
        '/v1/batches',
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      final list = (data['batches'] as List?) ?? [];
      return list.map((e) => BatchModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(code: 'FETCH_BATCHES_ERROR', message: e.message ?? 'Failed to load batches');
    }
  }

  Future<BatchModel> createBatch({
    required String name,
    required String subject,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/v1/batches',
        data: {
          'name': name.trim(),
          'subject': subject.trim(),
        },
      );

      return BatchModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(code: 'CREATE_BATCH_ERROR', message: e.message ?? 'Failed to create batch');
    }
  }

  Future<BatchModel> getBatchById(String id) async {
    try {
      final response = await _apiClient.dio.get('/v1/batches/$id');
      return BatchModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(code: 'GET_BATCH_ERROR', message: e.message ?? 'Failed to get batch details');
    }
  }

  Future<void> deleteBatch(String id) async {
    try {
      await _apiClient.dio.delete('/v1/batches/$id');
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(code: 'DELETE_BATCH_ERROR', message: e.message ?? 'Failed to delete batch');
    }
  }

  Future<Map<String, dynamic>> joinBatch({required String joinCode}) async {
    try {
      final response = await _apiClient.dio.post(
        '/v1/batches/join',
        data: {'joinCode': joinCode.trim().toUpperCase()},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(code: 'JOIN_BATCH_ERROR', message: e.message ?? 'Failed to join batch');
    }
  }

  Future<List<EnrolledStudentModel>> getStudents(String batchId, {String? status}) async {
    try {
      final queryParams = <String, dynamic>{
        if (status != null && status.isNotEmpty) 'status': status,
      };

      final response = await _apiClient.dio.get(
        '/v1/batches/$batchId/students',
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      final list = (data['students'] as List?) ?? [];
      return list.map((e) => EnrolledStudentModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(code: 'GET_STUDENTS_ERROR', message: e.message ?? 'Failed to load enrolled students');
    }
  }

  Future<Map<String, dynamic>> addStudent({
    required String batchId,
    required String name,
    required String email,
    String? phone,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/v1/batches/$batchId/students',
        data: {
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(code: 'ADD_STUDENT_ERROR', message: e.message ?? 'Failed to add student to batch');
    }
  }

  Future<BulkEnrollResultModel> bulkEnroll({
    required String batchId,
    required String csvText,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/v1/batches/$batchId/students/bulk',
        data: {'csvText': csvText.trim()},
      );

      return BulkEnrollResultModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(code: 'BULK_ENROLL_ERROR', message: e.message ?? 'Failed to bulk enroll students');
    }
  }

  Future<BatchModel> regenerateCode(String batchId) async {
    try {
      final response = await _apiClient.dio.post('/v1/batches/$batchId/regenerate-code');
      return BatchModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(code: 'REGENERATE_CODE_ERROR', message: e.message ?? 'Failed to regenerate join code');
    }
  }
}
