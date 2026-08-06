import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:babysitter/core/routing/app_routes.dart';
import 'package:babysitter/core/storage/local_storage.dart';

class AppRouterGuard {
  AppRouterGuard._();

  static bool _hasToken = false;
  static bool _isOnboarded = false;

  static Future<void> init() async {
    final token = await LocalStorage.getAccessToken();
    _hasToken = token != null && token.isNotEmpty;
    _isOnboarded = await LocalStorage.getIsOnboarded();
  }

  static String? redirect(
    BuildContext context,
    GoRouterState state,
  ) {
    final path = state.uri.path;

    // Onboarding redirect
    if (!_isOnboarded &&
        path != AppRoutes.onboarding &&
        path != AppRoutes.splash) {
      return AppRoutes.onboarding;
    }

    // Auth pages - redirect authenticated users to appropriate home
    if (_hasToken &&
        (path == AppRoutes.onboarding ||
            path == AppRoutes.welcome ||
            path == AppRoutes.login ||

            path == AppRoutes.register ||
            path == AppRoutes.otp ||
            path == AppRoutes.forgotPassword)) {
      // Will be overridden by RoleManager in splash
      return AppRoutes.parentHome;
    }

    return null;
  }

  static void markOnboarded() {
    _isOnboarded = true;
  }

  static Future<void> refresh() async {
    await init();
  }
}
