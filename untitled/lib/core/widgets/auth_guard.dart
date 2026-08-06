import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/theme_colors.dart';
import 'package:babysitter/core/routing/app_routes.dart';
import 'package:babysitter/core/services/auth_provider.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/shared/widgets/widgets.dart';

class AuthGuard extends ConsumerWidget {
  final Widget child;
  final String? requiredAction;

  const AuthGuard({
    super.key,
    required this.child,
    this.requiredAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final strings = AppLocalization.get(ref.watch(languageProvider).code);

    if (authState.isAuthenticated && authState.user != null) {
      return child;
    }

    return _AuthRequiredView(
      strings: strings,
      onLogin: () {
        Navigator.of(context).pop();
        context.push(AppRoutes.login);
      },
      onRegister: () {
        Navigator.of(context).pop();
        context.push(AppRoutes.register);
      },
      onContinue: () => Navigator.of(context).pop(),
      action: requiredAction,
    );
  }
}

class _AuthRequiredView extends StatelessWidget {
  final Map<String, String> strings;
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onContinue;
  final String? action;

  const _AuthRequiredView({
    required this.strings,
    required this.onLogin,
    required this.onRegister,
    required this.onContinue,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.lock_person_rounded,
                  size: 48,
                  color: AppColors.white,
                ),
              ),
              SizedBox(height: AppSpacing.xxl),
              Text(
                action ?? 'Authentication Required',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                'Please login or create an account to access this feature.',
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.xxl),
              AppButton(
                text: strings[AppLocalization.login] ?? 'Login',
                onPressed: onLogin,
              ),
              SizedBox(height: AppSpacing.md),
              AppButton(
                text:
                    strings[AppLocalization.create_account] ?? 'Create Account',
                variant: AppButtonVariant.outlined,
                onPressed: onRegister,
              ),
              SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: onContinue,
                child: Text(
                  'Continue as Visitor',
                  style: AppTextStyles.bodyMedium(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthBottomSheet extends StatelessWidget {
  final String message;
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onSkip;

  const AuthBottomSheet({
    super.key,
    this.message = 'Login to access this feature',
    required this.onLogin,
    required this.onRegister,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: AppSpacing.md),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_add_rounded,
              size: 36,
              color: AppColors.white,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: AppTextStyles.titleLarge(weight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Create an account to book babysitters and access all features.',
            style: AppTextStyles.bodyMedium(color: context.textSecondaryColor),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.xl),
          AppButton(
            text: 'Login',
            onPressed: onLogin,
          ),
          SizedBox(height: AppSpacing.md),
          AppButton(
            text: 'Create Account',
            variant: AppButtonVariant.outlined,
            onPressed: onRegister,
          ),
          SizedBox(height: AppSpacing.lg),
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            ),
            child: Text(
              'Maybe Later',
              style: AppTextStyles.bodyMedium(color: context.textMutedColor),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  static Future<void> show({
    required BuildContext context,
    String message = 'Login to access this feature',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AuthBottomSheet(
        message: message,
        onLogin: () {
          Navigator.of(context).pop();
          context.push(AppRoutes.login);
        },
        onRegister: () {
          Navigator.of(context).pop();
          context.push(AppRoutes.register);
        },
        onSkip: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class AuthInterceptor {
  static void check(
    BuildContext context,
    WidgetRef ref, {
    String message = 'Login to access this feature',
  }) {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) {
      AuthBottomSheet.show(
        context: context,
        message: message,
      );
    }
  }
}
