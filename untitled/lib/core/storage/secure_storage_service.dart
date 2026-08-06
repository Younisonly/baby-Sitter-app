import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService._();
  static final SecureStorageService instance = SecureStorageService._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _tokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _userRoleKey = 'user_role';
  static const _userDataKey = 'user_data';

  Future<void> saveToken(String token) => _safeWrite(_tokenKey, token);
  Future<String?> getToken() => _safeRead(_tokenKey);
  Future<void> deleteToken() => _safeDelete(_tokenKey);

  Future<void> saveRefreshToken(String token) => _safeWrite(_refreshTokenKey, token);
  Future<String?> getRefreshToken() => _safeRead(_refreshTokenKey);
  Future<void> deleteRefreshToken() => _safeDelete(_refreshTokenKey);

  Future<void> saveUserId(String id) => _safeWrite(_userIdKey, id);
  Future<String?> getUserId() => _safeRead(_userIdKey);

  Future<void> saveUserRole(String role) => _safeWrite(_userRoleKey, role);
  Future<String?> getUserRole() => _safeRead(_userRoleKey);

  Future<void> saveUserData(String json) => _safeWrite(_userDataKey, json);
  Future<String?> getUserData() => _safeRead(_userDataKey);

  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }

  Future<void> _safeWrite(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {}
  }

  Future<String?> _safeRead(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null;
    }
  }

  Future<void> _safeDelete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {}
  }
}
