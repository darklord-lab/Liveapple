import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/institute_link_model.dart';
import '../domain/testimonial_model.dart';

class InstituteContentRepository {
  final ApiClient _apiClient;

  InstituteContentRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /* -------------------------------------------------------------------------- */
  /* INSTITUTE LINKS                                                            */
  /* -------------------------------------------------------------------------- */
  Future<List<InstituteLinkModel>> getLinks({bool all = false}) async {
    try {
      final response = await _apiClient.dio.get(
        Endpoints.instituteLinks,
        queryParameters: all ? {'all': 'true'} : null,
      );

      final data = response.data as Map<String, dynamic>;
      final list = (data['data'] as List?) ?? [];
      return list.map((e) => InstituteLinkModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(code: 'FETCH_LINKS_ERROR', message: e.message ?? 'Failed to load institute links');
    }
  }

  Future<InstituteLinkModel> createLink({
    required String title,
    required String platform,
    required String url,
    String? icon,
    int? order,
    bool? isActive,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        Endpoints.instituteLinks,
        data: {
          'title': title.trim(),
          'platform': platform.toUpperCase().trim(),
          'url': url.trim(),
          if (icon != null) 'icon': icon.trim(),
          if (order != null) 'order': order,
          if (isActive != null) 'isActive': isActive,
        },
      );

      final data = response.data as Map<String, dynamic>;
      return InstituteLinkModel.fromJson(data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(code: 'CREATE_LINK_ERROR', message: e.message ?? 'Failed to create institute link');
    }
  }

  Future<InstituteLinkModel> updateLink(
    String id, {
    String? title,
    String? platform,
    String? url,
    String? icon,
    int? order,
    bool? isActive,
  }) async {
    try {
      final response = await _apiClient.dio.patch(
        Endpoints.instituteLink(id),
        data: {
          if (title != null) 'title': title.trim(),
          if (platform != null) 'platform': platform.toUpperCase().trim(),
          if (url != null) 'url': url.trim(),
          if (icon != null) 'icon': icon.trim(),
          if (order != null) 'order': order,
          if (isActive != null) 'isActive': isActive,
        },
      );

      final data = response.data as Map<String, dynamic>;
      return InstituteLinkModel.fromJson(data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(code: 'UPDATE_LINK_ERROR', message: e.message ?? 'Failed to update institute link');
    }
  }

  Future<void> deleteLink(String id) async {
    try {
      await _apiClient.dio.delete(Endpoints.instituteLink(id));
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(code: 'DELETE_LINK_ERROR', message: e.message ?? 'Failed to delete institute link');
    }
  }

  /* -------------------------------------------------------------------------- */
  /* TESTIMONIALS                                                               */
  /* -------------------------------------------------------------------------- */
  Future<List<TestimonialModel>> getTestimonials({bool all = false}) async {
    try {
      final response = await _apiClient.dio.get(
        Endpoints.instituteTestimonials,
        queryParameters: all ? {'all': 'true'} : null,
      );

      final data = response.data as Map<String, dynamic>;
      final list = (data['data'] as List?) ?? [];
      return list.map((e) => TestimonialModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(code: 'FETCH_TESTIMONIALS_ERROR', message: e.message ?? 'Failed to load testimonials');
    }
  }

  Future<TestimonialModel> createTestimonial({
    required String studentName,
    String? batchOrExam,
    required String quote,
    String? avatarUrl,
    int? rating,
    int? order,
    bool? isPublished,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        Endpoints.instituteTestimonials,
        data: {
          'studentName': studentName.trim(),
          if (batchOrExam != null && batchOrExam.isNotEmpty) 'batchOrExam': batchOrExam.trim(),
          'quote': quote.trim(),
          if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatarUrl': avatarUrl.trim(),
          if (rating != null) 'rating': rating,
          if (order != null) 'order': order,
          if (isPublished != null) 'isPublished': isPublished,
        },
      );

      final data = response.data as Map<String, dynamic>;
      return TestimonialModel.fromJson(data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(code: 'CREATE_TESTIMONIAL_ERROR', message: e.message ?? 'Failed to create testimonial');
    }
  }

  Future<TestimonialModel> updateTestimonial(
    String id, {
    String? studentName,
    String? batchOrExam,
    String? quote,
    String? avatarUrl,
    int? rating,
    int? order,
    bool? isPublished,
  }) async {
    try {
      final response = await _apiClient.dio.patch(
        Endpoints.instituteTestimonial(id),
        data: {
          if (studentName != null) 'studentName': studentName.trim(),
          if (batchOrExam != null) 'batchOrExam': batchOrExam.trim(),
          if (quote != null) 'quote': quote.trim(),
          if (avatarUrl != null) 'avatarUrl': avatarUrl.trim(),
          if (rating != null) 'rating': rating,
          if (order != null) 'order': order,
          if (isPublished != null) 'isPublished': isPublished,
        },
      );

      final data = response.data as Map<String, dynamic>;
      return TestimonialModel.fromJson(data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(code: 'UPDATE_TESTIMONIAL_ERROR', message: e.message ?? 'Failed to update testimonial');
    }
  }

  Future<void> deleteTestimonial(String id) async {
    try {
      await _apiClient.dio.delete(Endpoints.instituteTestimonial(id));
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(code: 'DELETE_TESTIMONIAL_ERROR', message: e.message ?? 'Failed to delete testimonial');
    }
  }
}
