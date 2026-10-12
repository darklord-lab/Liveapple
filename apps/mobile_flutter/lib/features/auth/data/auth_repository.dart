import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/user_model.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  AuthRepository({
    ApiClient? apiClient,
    SecureStorageService? storageService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _storage = storageService ?? SecureStorageService();

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        Endpoints.login,
        data: {
          'email': email.trim(),
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final accessToken = data['accessToken'] as String;
      final refreshToken = data['refreshToken'] as String;
      
      final userData = data['user'] as Map<String, dynamic>;
      if (data['institute'] != null) {
        userData['institute'] = data['institute'];
      }
      if (data['teacher'] != null) {
        userData['teacher'] = data['teacher'];
      }

      final user = UserModel.fromJson(userData);

      // Save tokens and cached user
      await _storage.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
      await _storage.saveCachedUser(jsonEncode(user.toJson()));

      return user;
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(code: 'NETWORK_ERROR', message: e.message ?? 'Login failed');
    }
  }

  Future<UserModel> acceptInvite({
    required String inviteCode,
    required String password,
    String? name,
    String? phone,
    String? email,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        Endpoints.acceptInvite,
        data: {
          'inviteCode': inviteCode.trim(),
          'password': password,
          if (email != null && email.isNotEmpty) 'email': email.trim(),
          if (name != null && name.isNotEmpty) 'name': name.trim(),
          if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
        },
      );

      final data = response.data as Map<String, dynamic>;
      final accessToken = data['accessToken'] as String;
      final refreshToken = data['refreshToken'] as String;

      final userData = data['user'] as Map<String, dynamic>;
      if (data['institute'] != null) {
        userData['institute'] = data['institute'];
      }
      if (data['teacher'] != null) {
        userData['teacher'] = data['teacher'];
      }

      final user = UserModel.fromJson(userData);

      await _storage.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
      await _storage.saveCachedUser(jsonEncode(user.toJson()));

      return user;
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(code: 'INVITE_ERROR', message: e.message ?? 'Failed to accept invite');
    }
  }

  Future<Map<String, dynamic>> validateInvite(String code) async {
    try {
      final response = await _apiClient.dio.get('${Endpoints.validateInvite}/${code.trim()}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(code: 'INVALID_INVITE', message: e.message ?? 'Invalid invite code');
    }
  }

  Future<UserModel?> checkAuthStatus() async {
    try {
      final accessToken = await _storage.getAccessToken();
      if (accessToken == null) return null;

      // Try fetching current user profile from server
      final response = await _apiClient.dio.get(Endpoints.me);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final userData = data['user'] as Map<String, dynamic>;
        if (data['institute'] != null && userData['institute'] == null) {
          userData['institute'] = data['institute'];
        }
        if (data['teacher'] != null && userData['teacher'] == null) {
          userData['teacher'] = data['teacher'];
        }
        final user = UserModel.fromJson(userData);
        await _storage.saveCachedUser(jsonEncode(user.toJson()));
        return user;
      }
    } catch (_) {
      // If offline, check cached user
      final cached = await _storage.getCachedUser();
      if (cached != null) {
        try {
          return UserModel.fromJson(jsonDecode(cached) as Map<String, dynamic>);
        } catch (_) {}
      }
    }
    return null;
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null) {
        await _apiClient.dio.post(Endpoints.logout, data: {'refreshToken': refreshToken});
      }
    } catch (_) {
      // ignore network errors on logout
    } finally {
      await _storage.clearAll();
    }
  }
}
