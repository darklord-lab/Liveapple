import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/timetable_model.dart';

class TimetableRepository {
  final ApiClient _apiClient;

  TimetableRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<TimetableSlotModel>> getSlots({
    String? batchId,
    String? teacherId,
    int? dayOfWeek,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (batchId != null && batchId.isNotEmpty) 'batchId': batchId,
        if (teacherId != null && teacherId.isNotEmpty) 'teacherId': teacherId,
        if (dayOfWeek != null) 'dayOfWeek': dayOfWeek,
      };

      final response = await _apiClient.dio.get(
        '/v1/timetable',
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      final list = (data['slots'] as List?) ?? [];
      return list.map((e) => TimetableSlotModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(code: 'FETCH_SLOTS_ERROR', message: e.message ?? 'Failed to load timetable slots');
    }
  }

  Future<TimetableSlotModel> createSlot({
    required String batchId,
    required int dayOfWeek,
    required int startMin,
    required int endMin,
    bool recurring = true,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/v1/timetable',
        data: {
          'batchId': batchId,
          'dayOfWeek': dayOfWeek,
          'startMin': startMin,
          'endMin': endMin,
          'recurring': recurring,
        },
      );

      return TimetableSlotModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(
        code: e.response?.data?['code'] ?? 'CREATE_SLOT_ERROR',
        message: e.response?.data?['message'] ?? e.message ?? 'Failed to create timetable slot',
        details: e.response?.data?['details'],
      );
    }
  }

  Future<void> deleteSlot(String id) async {
    try {
      await _apiClient.dio.delete('/v1/timetable/$id');
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(code: 'DELETE_SLOT_ERROR', message: e.message ?? 'Failed to delete timetable slot');
    }
  }
}
