import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/extensions/extensions.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/routing/app_routes.dart';
import 'package:babysitter/core/services/auth_provider.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/shared/widgets/widgets.dart';

class ProtectedRoute extends StatelessWidget {
  final Widget child;
  final String messageKey;

  const ProtectedRoute({
    super.key,
    required this.child,
    this.messageKey = AppLocalization.login_to_access,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final authState = ref.watch(authProvider);
        if (authState.isAuthenticated) return child;

        return _AuthPrompt(messageKey: messageKey);
      },
    );
  }
}

class _AuthPrompt extends ConsumerWidget {
  final String messageKey;
  const _AuthPrompt({required this.messageKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final message = strings[messageKey] ?? 'Please login to access this feature';
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppColors.primaryGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.lock_person_rounded,
                      size: 48, color: AppColors.white),
                ),
                const SizedBox(height: 28),
                Text(
                  strings[AppLocalization.login_required] ?? 'Login Required',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 15,
                    color: context.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                AppButton(
                  text: strings[AppLocalization.login] ?? 'Login',
                  onPressed: () => context.push(AppRoutes.login),
                ),
                const SizedBox(height: 14),
                AppButton(
                  text: strings[AppLocalization.create_account] ?? 'Create Account',
                  variant: AppButtonVariant.outlined,
                  onPressed: () => context.push(AppRoutes.register),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => context.go(AppRoutes.home),
                  child: Text(
                    strings[AppLocalization.continue_browsing] ?? 'Continue Browsing',
                    style: TextStyle(
                      fontSize: 14,
                      color: context.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
