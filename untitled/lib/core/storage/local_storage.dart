import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:babysitter/core/storage/secure_storage_service.dart';
import 'package:babysitter/core/services/role_manager.dart';

class LocalStorage {
  LocalStorage._();

  static const String _tokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userRoleKey = 'user_role';
  static const String _isFirstLaunchKey = 'is_first_launch';
  static const String _isOnboardedKey = 'is_onboarded';
  static const String _themeModeKey = 'theme_mode';
  static const String _languageCodeKey = 'language_code';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _favoriteIdsKey = 'favorite_ids';
  static const String _userDataKey = 'user_data';
  static const String _deviceTokenKey = 'device_token';
  static const String _currentRoleKey = 'current_role';
  static const String _pendingDeepLinkKey = 'pending_deep_link';
  static const String _hasParentProfileKey = 'has_parent_profile';
  static const String _hasSitterProfileKey = 'has_sitter_profile';
  static const String _otpSessionKey = 'otp_session';

  static SharedPreferences? _prefs;
  static Box? _cacheBox;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await Hive.initFlutter();
    _cacheBox = await Hive.openBox('cache');
  }

  static Future<void> setAccessToken(String token) async {
    await SecureStorageService.instance.saveToken(token);
    await _prefs?.setString(_tokenKey, token);
  }

  static Future<String?> getAccessToken() async {
    return await SecureStorageService.instance.getToken() ?? _prefs?.getString(_tokenKey);
  }

  static Future<void> setRefreshToken(String token) async {
    await SecureStorageService.instance.saveRefreshToken(token);
    await _prefs?.setString(_refreshTokenKey, token);
  }

  static Future<String?> getRefreshToken() async {
    return await SecureStorageService.instance.getRefreshToken() ?? _prefs?.getString(_refreshTokenKey);
  }

  static Future<void> setUserId(String id) async {
    await SecureStorageService.instance.saveUserId(id);
    await _prefs?.setString(_userIdKey, id);
  }

  static Future<String?> getUserId() async {
    return await SecureStorageService.instance.getUserId() ?? _prefs?.getString(_userIdKey);
  }

  static Future<void> setUserRole(String role) async {
    await SecureStorageService.instance.saveUserRole(role);
    await _prefs?.setString(_userRoleKey, role);
  }

  static Future<String?> getUserRole() async {
    return await SecureStorageService.instance.getUserRole() ?? _prefs?.getString(_userRoleKey);
  }

  static Future<bool> getIsFirstLaunch() async {
    return _prefs?.getBool(_isFirstLaunchKey) ?? true;
  }

  static Future<void> setIsFirstLaunch(bool value) async {
    await _prefs?.setBool(_isFirstLaunchKey, value);
  }

  static Future<bool> getIsOnboarded() async {
    return _prefs?.getBool(_isOnboardedKey) ?? false;
  }

  static Future<void> setIsOnboarded(bool value) async {
    await _prefs?.setBool(_isOnboardedKey, value);
  }

  static Future<String> getThemeMode() async {
    return _prefs?.getString(_themeModeKey) ?? 'system';
  }

  static Future<void> setThemeMode(String mode) async {
    await _prefs?.setString(_themeModeKey, mode);
  }

  static Future<bool> hasLanguageCode() async {
    return _prefs?.containsKey(_languageCodeKey) ?? false;
  }

  static Future<String> getLanguageCode() async {
    return _prefs?.getString(_languageCodeKey) ?? 'en';
  }

  static String getLanguageCodeSync() {
    return _prefs?.getString(_languageCodeKey) ?? 'en';
  }

  static Future<void> setLanguageCode(String code) async {
    await _prefs?.setString(_languageCodeKey, code);
  }

  static Future<bool> getIsLoggedIn() async {
    return _prefs?.getBool(_isLoggedInKey) ?? false;
  }

  static Future<void> setIsLoggedIn(bool value) async {
    await _prefs?.setBool(_isLoggedInKey, value);
  }

  static Future<List<String>> getFavoriteIds() async {
    return _prefs?.getStringList(_favoriteIdsKey) ?? [];
  }

  static Future<void> setFavoriteIds(List<String> ids) async {
    await _prefs?.setStringList(_favoriteIdsKey, ids);
  }

  static Future<void> cacheData(String key, dynamic value) async {
    await _cacheBox?.put(key, value);
  }

  static dynamic getCachedData(String key) {
    return _cacheBox?.get(key);
  }

  static Future<void> removeCachedData(String key) async {
    await _cacheBox?.delete(key);
  }

  static Future<void> clearCache() async {
    await _cacheBox?.clear();
  }

  static Future<void> setUserData(String json) async {
    await SecureStorageService.instance.saveUserData(json);
    await _prefs?.setString(_userDataKey, json);
  }

  static Future<String?> getUserData() async {
    return await SecureStorageService.instance.getUserData() ?? _prefs?.getString(_userDataKey);
  }

  static Future<void> setDeviceToken(String token) async {
    await _prefs?.setString(_deviceTokenKey, token);
  }

  static Future<String?> getDeviceToken() async {
    return _prefs?.getString(_deviceTokenKey);
  }

  static Future<void> setCurrentRole(String role) async {
    await SecureStorageService.instance.saveUserRole(role);
    await _prefs?.setString(_currentRoleKey, role);
  }

  static Future<AppRole> getCurrentRole() async {
    final roleStr = await SecureStorageService.instance.getUserRole() ?? _prefs?.getString(_currentRoleKey);
    if (roleStr == 'sitter') return AppRole.sitter;
    if (roleStr == 'parent') return AppRole.parent;
    return AppRole.visitor;
  }

  static Future<bool> getHasParentProfile() async {
    return _prefs?.getBool(_hasParentProfileKey) ?? true;
  }

  static Future<void> setHasParentProfile(bool value) async {
    await _prefs?.setBool(_hasParentProfileKey, value);
  }

  static Future<bool> getHasSitterProfile() async {
    return _prefs?.getBool(_hasSitterProfileKey) ?? false;
  }

  static Future<void> setHasSitterProfile(bool value) async {
    await _prefs?.setBool(_hasSitterProfileKey, value);
  }

  static Future<void> setPendingDeepLink(String type, String id) async {
    await _prefs?.setString(_pendingDeepLinkKey, '$type|$id');
  }

  static Future<String?> getPendingDeepLink() async {
    return _prefs?.getString(_pendingDeepLinkKey);
  }

  static Future<void> clearPendingDeepLink() async {
    await _prefs?.remove(_pendingDeepLinkKey);
  }

  static Future<void> saveOtpSession(String json) async {
    await _prefs?.setString(_otpSessionKey, json);
  }

  static Future<String?> getOtpSession() async {
    return _prefs?.getString(_otpSessionKey);
  }

  static Future<void> clearOtpSession() async {
    await _prefs?.remove(_otpSessionKey);
  }

  static Future<void> clear() async {
    await SecureStorageService.instance.clearAll();
    await _prefs?.clear();
    await clearCache();
  }

  static Future<void> logout() async {
    await SecureStorageService.instance.deleteToken();
    await SecureStorageService.instance.deleteRefreshToken();
    await _prefs?.remove(_tokenKey);
    await _prefs?.remove(_refreshTokenKey);
    await _prefs?.remove(_userDataKey);
    await _prefs?.setBool(_isLoggedInKey, false);
  }
}
