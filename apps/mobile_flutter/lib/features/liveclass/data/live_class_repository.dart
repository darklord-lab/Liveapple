import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/live_class_model.dart';

class LiveClassRepository {
  final ApiClient _apiClient;

  LiveClassRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<LiveClassModel>> getClasses({
    String? batchId,
    String? status,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (batchId != null && batchId.isNotEmpty) 'batchId': batchId,
        if (status != null && status.isNotEmpty) 'status': status,
        if (fromDate != null && fromDate.isNotEmpty) 'fromDate': fromDate,
        if (toDate != null && toDate.isNotEmpty) 'toDate': toDate,
      };

      final response = await _apiClient.dio.get(
        '/v1/classes',
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      final list = (data['classes'] as List?) ?? [];
      return list.map((e) => LiveClassModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(code: 'FETCH_CLASSES_ERROR', message: e.message ?? 'Failed to load live classes');
    }
  }

  Future<LiveClassModel> createClass({
    required String batchId,
    required String title,
    required String scheduledAt,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/v1/classes',
        data: {
          'batchId': batchId,
          'title': title.trim(),
          'scheduledAt': scheduledAt,
        },
      );

      return LiveClassModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(code: 'CREATE_CLASS_ERROR', message: e.message ?? 'Failed to schedule class');
    }
  }

  Future<Map<String, dynamic>> generateUpcoming({int daysAhead = 7}) async {
    try {
      final response = await _apiClient.dio.post(
        '/v1/classes/generate-upcoming',
        data: {'daysAhead': daysAhead},
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(code: 'GENERATE_CLASSES_ERROR', message: e.message ?? 'Failed to generate upcoming classes');
    }
  }

  Future<LiveClassModel> getClassById(String id) async {
    try {
      final response = await _apiClient.dio.get('/v1/classes/$id');
      return LiveClassModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(code: 'GET_CLASS_ERROR', message: e.message ?? 'Failed to load class details');
    }
  }

  Future<LiveClassModel> startClass(String id) async {
    try {
      final response = await _apiClient.dio.post('/v1/classes/$id/start');
      return LiveClassModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(code: 'START_CLASS_ERROR', message: e.message ?? 'Failed to start live class');
    }
  }

  Future<Map<String, dynamic>> getToken(String id) async {
    try {
      final response = await _apiClient.dio.post('/v1/classes/$id/token');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(code: 'GET_TOKEN_ERROR', message: e.message ?? 'Failed to get room token');
    }
  }

  Future<void> endClass(String id) async {
    try {
      await _apiClient.dio.post('/v1/classes/$id/end');
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(code: 'END_CLASS_ERROR', message: e.message ?? 'Failed to end live class');
    }
  }

  Future<void> muteAll(String id) async {
    try {
      await _apiClient.dio.post('/v1/classes/$id/host/mute-all');
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(code: 'MUTE_ALL_ERROR', message: e.message ?? 'Failed to mute participants');
    }
  }

  Future<void> removeParticipant(String id, String participantId) async {
    try {
      await _apiClient.dio.post(
        '/v1/classes/$id/host/remove-participant',
        data: {'participantId': participantId},
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(code: 'REMOVE_PARTICIPANT_ERROR', message: e.message ?? 'Failed to remove participant');
    }
  }
}

