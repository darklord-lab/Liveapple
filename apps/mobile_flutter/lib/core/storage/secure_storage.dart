import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  static const String _keyAccessToken = 'classora_access_token';
  static const String _keyRefreshToken = 'classora_refresh_token';
  static const String _keyUser = 'classora_cached_user';
  static const String _keyBaseUrl = 'classora_api_base_url';

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: _keyAccessToken);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: _keyRefreshToken);
  }

  Future<void> saveCachedUser(String userJson) async {
    await _storage.write(key: _keyUser, value: userJson);
  }

  Future<String?> getCachedUser() async {
    return _storage.read(key: _keyUser);
  }

  Future<void> saveBaseUrl(String url) async {
    await _storage.write(key: _keyBaseUrl, value: url);
  }

  Future<String?> getBaseUrl() async {
    return _storage.read(key: _keyBaseUrl);
  }

  Future<void> deleteBaseUrl() async {
    await _storage.delete(key: _keyBaseUrl);
  }

  Future<bool> hasCompletedWalkthrough(String role) async {
    final val = await _storage.read(key: 'classora_walkthrough_completed_$role');
    return val == 'true';
  }

  Future<void> setCompletedWalkthrough(String role) async {
    await _storage.write(key: 'classora_walkthrough_completed_$role', value: 'true');
  }

  Future<void> clearAll() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyUser);
  }
}
