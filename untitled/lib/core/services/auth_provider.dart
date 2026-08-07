import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:babysitter/core/constants/app_config.dart';
import 'package:babysitter/core/network/error_handler.dart';
import 'package:babysitter/core/routing/app_router.dart';
import 'package:babysitter/core/routing/app_router_guard.dart';
import 'package:babysitter/core/services/app_provider.dart';
import 'package:babysitter/core/services/auth_event_service.dart';
import 'package:babysitter/core/services/social_auth_service.dart';
import 'package:babysitter/features/favorites/data/favorite_repository.dart';
import 'package:babysitter/core/storage/local_storage.dart';
import 'package:babysitter/core/services/role_manager.dart';
import 'package:babysitter/features/auth/data/repositories/auth_repository.dart';
import 'package:babysitter/features/notifications/data/notification_repository.dart';
import 'package:babysitter/features/notifications/data/notification_settings_provider.dart';
import 'package:babysitter/shared/models/user_model.dart';

part 'auth_provider.freezed.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState({
    @Default(false) bool isLoading,
    @Default(false) bool isAuthenticated,
    @Default(null) UserModel? user,
    @Default(null) String? error,
    @Default(null) String? otpToken,
    @Default(false) bool isFromCache,
    @Default(null) String? otpMode,
    @Default('email') String otpChannel,
    @Default('') String otpContact,
    @Default(null) String? otpEmail,
    @Default(null) String? otpPhone,
    @Default(null) String? otpResendKey,
    @Default(null) String? pendingOtp,
  }) = _AuthState;
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref, ref.read(authRepositoryProvider));
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref, this._authRepository) : super(const AuthState()) {
    _checkAuthStatus();
    _unauthorizedSub = AuthEventService.instance.unauthorizedStream.listen((_) {
      if (!mounted || _isLoggingOut) return;
      logout();
    });
  }

  StreamSubscription<void>? _unauthorizedSub;
  bool _isLoggingOut = false;
  final Ref _ref;
  final AuthRepository _authRepository;

  Map<String, dynamic> _normalizeUserData(Map<String, dynamic> data) {
    if (data['avatar'] is String) {
      data['avatar'] = AppConfig.absoluteUrl(data['avatar'] as String);
    }
    return data;
  }

  Future<void> _refreshRouter() async {
    await AppRouterGuard.refresh();
    AppRouter.router.refresh();
  }

  @override
  void dispose() {
    _unauthorizedSub?.cancel();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    final token = await LocalStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      state = state.copyWith(isAuthenticated: true);

      final cachedUser = await _loadCachedUser();
      if (cachedUser != null) {
        state = state.copyWith(user: cachedUser, isFromCache: true);
      }

      await loadUser();
    }
  }

  Future<void> _saveUserToCache(UserModel user) async {
    final jsonStr = jsonEncode(user.toJson());
    await LocalStorage.setUserData(jsonStr);
  }

  Future<UserModel?> _loadCachedUser() async {
    final cached = await LocalStorage.getUserData();
    if (cached == null || cached.isEmpty) return null;
    try {
      final json = jsonDecode(cached) as Map<String, dynamic>;
      return UserModel.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadUser() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await _authRepository.loadUser();
      final user = UserModel.fromJson(_normalizeUserData(data));
      await _saveUserToCache(user);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
        isFromCache: false,
      );
      await _setRoleFromUser(user);
      await _registerDeviceToken();
      await _ref.read(appStateProvider.notifier).syncFavoritesFromServer();
      await _refreshRouter();
      _ref.read(notificationRepositoryProvider).getUnreadCount().then((count) {
        _ref.read(appStateProvider.notifier).setUnreadNotifications(count);
      });
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await LocalStorage.logout();
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          user: null,
        );
      } else if (_isNetworkError(e)) {
        final cachedUser = await _loadCachedUser();
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: cachedUser,
          error: cachedUser != null
              ? ErrorHandler.handle(e).message
              : ErrorHandler.handle(e).message,
          isFromCache: cachedUser != null,
        );
        if (cachedUser != null) {
          await _refreshRouter();
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          error: ErrorHandler.handle(e).message,
        );
      }
    } catch (e) {
      final appException = ErrorHandler.handle(e);
      final isOffline = e is DioException && _isNetworkError(e);
      if (isOffline) {
        final cachedUser = await _loadCachedUser();
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: cachedUser,
          error: appException.message,
          isFromCache: cachedUser != null,
        );
        if (cachedUser != null) {
          await _refreshRouter();
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          error: appException.message,
        );
      }
    }
  }

  Future<void> _registerDeviceToken() async {
    try {
      final token = await LocalStorage.getDeviceToken();
      if (token != null && token.isNotEmpty) {
        await _ref
            .read(notificationSettingsProvider.notifier)
            .registerDeviceToken(token);
      }
    } catch (_) {}
  }

  bool _isNetworkError(DioException e) {
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout;
  }

  Future<void> _setRoleFromUser(UserModel user, {AppRole? preferredRole}) async {
    final hasParent = user.hasParentProfile;
    final hasSitter = user.hasSitterProfile;

    await _ref.read(roleManagerProvider.notifier).setAvailableRoles(
      hasParentAccess: hasParent,
      hasSitterAccess: hasSitter,
      preferredRole: preferredRole,
    );
  }

  Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
    AppRole? preferredRole,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _authRepository.login(email, password);

      await LocalStorage.setAccessToken(data['token'] as String);
      await LocalStorage.setIsLoggedIn(true);

      final user = UserModel.fromJson(
        _normalizeUserData(data['user'] as Map<String, dynamic>),
      );
      await LocalStorage.setUserId(user.id);
      await LocalStorage.setUserRole(user.role.name);
      await _saveUserToCache(user);
      await _setRoleFromUser(user, preferredRole: preferredRole);

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
        isFromCache: false,
      );

      // Check if the preferred role is available
      final roleState = _ref.read(roleManagerProvider);
      if (preferredRole != null) {
        if (preferredRole == AppRole.sitter && !roleState.canActAsSitter) {
          return {'roleUnavailable': 'sitter'};
        }
        if (preferredRole == AppRole.parent && !roleState.canActAsParent) {
          return {'roleUnavailable': 'parent'};
        }
      }

      await _ref.read(appStateProvider.notifier).syncFavoritesFromServer();
      await _registerDeviceToken();
      await _refreshRouter();
      _ref.read(notificationRepositoryProvider).getUnreadCount().then((count) {
        _ref.read(appStateProvider.notifier).setUnreadNotifications(count);
      });

      return null;
    } catch (e) {
      final appException = ErrorHandler.handle(e);
      if (appException.statusCode == 403 &&
          appException.data is Map &&
          (appException.data as Map)['needsVerification'] == true) {
        final data = appException.data as Map;
        final unverifiedEmail = data['email']?.toString();
        final unverifiedPhone = data['phone']?.toString();
        state = state.copyWith(
          isLoading: false,
          error: appException.message,
          otpToken: null,
          otpMode: 'login',
          otpChannel: unverifiedEmail?.isNotEmpty == true ? 'email' : 'phone',
          otpContact: unverifiedEmail?.isNotEmpty == true
              ? unverifiedEmail!
              : unverifiedPhone ?? '',
          otpEmail: unverifiedEmail,
          otpPhone: unverifiedPhone,
        );
        return {'needsVerification': true};
      }
      state = state.copyWith(
        isLoading: false,
        error: appException.message,
      );
      return null;
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    String? role,
    String? nationalId,
    String channel = 'email',
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _authRepository.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        role: role,
        nationalId: nationalId,
        channel: channel,
      );
      state = state.copyWith(
        isLoading: false,
        otpToken: data['otpToken']?.toString(),
        otpMode: 'register',
        otpChannel: data['channel']?.toString() ?? channel,
        otpContact: channel == 'phone' ? phone : email,
        otpEmail: email,
        otpPhone: phone,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.handle(e).message,
      );
    }
  }

  Future<void> forgotPassword({
    String? email,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _authRepository.forgotPassword(
        email: email,
        phone: phone,
      );
      final channel = data['channel']?.toString() ?? (email != null ? 'email' : 'phone');
      state = state.copyWith(
        isLoading: false,
        otpToken: data['otpToken']?.toString(),
        otpMode: 'reset',
        otpChannel: channel,
        otpContact: email ?? phone ?? '',
        otpEmail: email,
        otpPhone: phone,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.handle(e).message,
      );
    }
  }

  Future<void> requestLoginOtp({
    String? email,
    String? phone,
    String? channel,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _authRepository.requestLoginOtp(
        email: email,
        phone: phone,
        channel: channel,
      );
      state = state.copyWith(
        isLoading: false,
        otpToken: data['otpToken']?.toString(),
        otpMode: 'login',
        otpChannel: data['channel']?.toString() ?? channel ?? 'email',
        otpContact: email ?? phone ?? '',
        otpEmail: email,
        otpPhone: phone,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.handle(e).message,
      );
    }
  }

  Future<bool> resendOtp({String? channel}) async {
    if (state.isLoading) return false;
    final targetChannel = channel ?? state.otpChannel;
    final currentToken = state.otpToken;

    if (currentToken != null && currentToken.isNotEmpty) {
      state = state.copyWith(isLoading: true, error: null);
      try {
        final data = await _authRepository.resendOtp(
          currentToken,
          channel: targetChannel,
        );
        final newToken = data['otpToken']?.toString();
        if (newToken == null || newToken.isEmpty) {
          state = state.copyWith(
            isLoading: false,
            error: ErrorHandler.handle(
              const FormatException('missing_otp_token'),
            ).message,
          );
          return false;
        }
        state = state.copyWith(
          isLoading: false,
          otpToken: newToken,
          otpChannel: data['channel']?.toString() ?? targetChannel,
          otpContact: state.otpContact,
        );
        return true;
      } catch (e) {
        state = state.copyWith(
          isLoading: false,
          error: ErrorHandler.handle(e).message,
        );
        return false;
      }
    }

    final email = targetChannel == 'email'
        ? (state.otpEmail ??
            (state.otpContact.contains('@') ? state.otpContact : null))
        : null;
    final phone = targetChannel == 'phone'
        ? (state.otpPhone ??
            (state.otpContact.contains('@') ? null : state.otpContact))
        : null;

    if (state.otpMode == 'register') {
      state = state.copyWith(
        error: ErrorHandler.handle(
          const FormatException('missing_otp_token'),
        ).message,
      );
      return false;
    }

    if (email == null && phone == null) {
      state = state.copyWith(
        error: ErrorHandler.handle(
          const FormatException('missing_otp_contact'),
        ).message,
      );
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _authRepository.requestLoginOtp(
        email: email,
        phone: phone,
        channel: targetChannel,
      );
      final newToken = data['otpToken']?.toString();
      if (newToken == null || newToken.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: ErrorHandler.handle(
            const FormatException('missing_otp_token'),
          ).message,
        );
        return false;
      }
      state = state.copyWith(
        isLoading: false,
        otpToken: newToken,
        otpChannel: data['channel']?.toString() ?? targetChannel,
        otpContact: targetChannel == 'email' ? (email ?? state.otpContact) : (phone ?? state.otpContact),
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.handle(e).message,
      );
      return false;
    }
  }

  Future<void> verifyOtp(String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (state.otpMode == 'login') {
        final data = await _authRepository.verifyLoginOtp(otp, state.otpToken);
        await _completeAuthentication(data);
        return;
      }

      final data = await _authRepository.verifyOtp(otp, state.otpToken);
      await _completeAuthentication(data);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.handle(e).message,
      );
    }
  }

  Future<void> _completeAuthentication(Map<String, dynamic> data) async {
    await LocalStorage.setAccessToken(data['token'] as String);
    await LocalStorage.setIsLoggedIn(true);

    final user = UserModel.fromJson(
      _normalizeUserData(data['user'] as Map<String, dynamic>),
    );
    await LocalStorage.setUserId(user.id);
    await LocalStorage.setUserRole(user.role.name);
    await _saveUserToCache(user);
    await _setRoleFromUser(user);

    state = state.copyWith(
      isLoading: false,
      isAuthenticated: true,
      user: user,
      otpToken: null,
      otpMode: null,
      isFromCache: false,
    );
    await _ref.read(appStateProvider.notifier).syncFavoritesFromServer();
    await _registerDeviceToken();
    await _refreshRouter();
    _ref.read(notificationRepositoryProvider).getUnreadCount().then((count) {
      _ref.read(appStateProvider.notifier).setUnreadNotifications(count);
    });
  }

  Future<void> resetPassword({
    required String otp,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authRepository.resetPassword(
        otpToken: state.otpToken ?? '',
        otp: otp,
        password: password,
      );
      state = state.copyWith(
        isLoading: false,
        otpToken: null,
        otpMode: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.handle(e).message,
      );
    }
  }

  Future<String?> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final idToken = await SocialAuthService.signInWithGoogle();
      return _handleSocialLogin('google', idToken);
    } catch (e) {
      final msg = ErrorHandler.handle(e).message;
      state = state.copyWith(
        isLoading: false,
        error: msg,
      );
      return msg;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<String?> loginWithApple() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final idToken = await SocialAuthService.signInWithApple();
      return _handleSocialLogin('apple', idToken);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.handle(e).message,
      );
      return null;
    }
  }

  Future<String?> _handleSocialLogin(String provider, String idToken) async {
    try {
      final data = await _authRepository.socialLogin(provider, idToken);

      await LocalStorage.setAccessToken(data['token'] as String);
      await LocalStorage.setIsLoggedIn(true);

      final user = UserModel.fromJson(
        _normalizeUserData(data['user'] as Map<String, dynamic>),
      );
      await LocalStorage.setUserId(user.id);
      await LocalStorage.setUserRole(user.role.name);
      await _saveUserToCache(user);
      await _setRoleFromUser(user);

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
        isFromCache: false,
      );
      await _ref.read(appStateProvider.notifier).syncFavoritesFromServer();
      await _registerDeviceToken();
      await _refreshRouter();
      _ref.read(notificationRepositoryProvider).getUnreadCount().then((count) {
        _ref.read(appStateProvider.notifier).setUnreadNotifications(count);
      });

      return null;
    } catch (e) {
      final msg = ErrorHandler.handle(e).message;
      state = state.copyWith(
        isLoading: false,
        error: msg,
      );
      return msg;
    }
  }

  Future<void> logout() async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;
    try {
      await _authRepository.logout();
    } catch (_) {}
    await SocialAuthService.signOut();
    await LocalStorage.logout();
    _ref.read(appStateProvider.notifier).clearFavorites();
    _ref.invalidate(favoriteSittersProvider);
    state = const AuthState();
    _isLoggingOut = false;
    await _refreshRouter();
  }

  Future<void> deleteAccount() async {
    try {
      await _authRepository.deleteAccount();
    } catch (_) {}
    await LocalStorage.clear();
    _ref.read(appStateProvider.notifier).clearFavorites();
    _ref.invalidate(favoriteSittersProvider);
    state = const AuthState();
    await _refreshRouter();
  }

  Future<String?> removeSitterAccount(String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authRepository.removeSitterAccount(password);
      await LocalStorage.setUserRole('customer');
      await loadUser();
      return null;
    } catch (e) {
      final msg = ErrorHandler.handle(e).message;
      state = state.copyWith(isLoading: false, error: msg);
      return msg;
    }
  }

  Future<Map<String, dynamic>?> becomeSitter(String nationalId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _authRepository.becomeSitter(nationalId);

      final user = UserModel.fromJson(
        _normalizeUserData(data['user'] as Map<String, dynamic>),
      );
      await _saveUserToCache(user);
      await _setRoleFromUser(user, preferredRole: AppRole.sitter);

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
      );
      await _refreshRouter();
      return null;
    } catch (e) {
      final msg = ErrorHandler.handle(e).message;
      state = state.copyWith(isLoading: false, error: msg);
      return {'error': msg};
    }
  }

  Future<void> updateProfile({
    required String name,
    String? email,
    String? phone,
    String? location,
    String? avatar,
    String? nationalId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _authRepository.updateProfile({
        'name': name,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (location != null) 'location': location,
        if (avatar != null) 'avatar': avatar,
        if (nationalId != null) 'national_id': nationalId,
      });
      final user = UserModel.fromJson(_normalizeUserData(data));
      await _saveUserToCache(user);
      state = state.copyWith(
        isLoading: false,
        user: user,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.handle(e).message,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> sendUpdateOtp({
    String? email,
    String? phone,
  }) async {
    state = state.copyWith(error: null);
    return _authRepository.sendUpdateOtp(email: email, phone: phone);
  }

  Future<void> verifyUpdateOtp({
    required String otp,
    required String otpToken,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _authRepository.verifyUpdateOtp(
        otp: otp,
        otpToken: otpToken,
      );
      final user = UserModel.fromJson(_normalizeUserData(data));
      await _saveUserToCache(user);
      state = state.copyWith(
        isLoading: false,
        user: user,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.handle(e).message,
      );
    }
  }

  void setPendingOtp(String otp) {
    state = state.copyWith(pendingOtp: otp);
  }

  void updateUserDirectly(UserModel user) {
    state = state.copyWith(user: user);
    _saveUserToCache(user);
  }
}
