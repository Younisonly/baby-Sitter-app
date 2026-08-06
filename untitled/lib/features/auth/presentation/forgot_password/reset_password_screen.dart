import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/extensions.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/routing/app_routes.dart';
import 'package:babysitter/core/services/auth_provider.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/shared/widgets/widgets.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    context.hideKeyboard();
    final strings = AppLocalization.get(ref.read(languageProvider).code);

    final authState = ref.read(authProvider);
    if (authState.pendingOtp == null || authState.otpToken == null) {
      context.showErrorSnackBar(
        strings[AppLocalization.code_expired] ?? 'Verification code expired. Please try again.',
      );
      return;
    }

    await ref.read(authProvider.notifier).resetPassword(
          otp: authState.pendingOtp!,
          password: _passwordController.text,
        );

    if (!mounted) return;
    final state = ref.read(authProvider);
    if (state.error != null) {
      context.showErrorSnackBar(state.error ?? 'Failed to reset password');
      return;
    }

    context.showSuccessSnackBar(
      strings[AppLocalization.password_reset_success] ?? 'Password reset successfully',
    );
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final isLoading = ref.watch(authProvider.select((s) => s.isLoading));

    return Scaffold(
      appBar: AppAppBar(title: strings[AppLocalization.reset_password]),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: AppSpacing.xxl),
                Center(
                  child: Container(
                    width: 100.w,
                    height: 100.w,
                    decoration: BoxDecoration(
                      color: AppColors.primaryUltraLight,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Icon(
                      Icons.password_rounded,
                      size: 50.sp,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.xl),
                Text(
                  strings[AppLocalization.new_password] ?? 'Create New Password',
                  style: AppTextStyles.displaySmall(),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  strings[AppLocalization.new_password_instruction] ??
                      'Choose a strong password for your account.',
                  style: AppTextStyles.bodyMedium(),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppSpacing.xxl),
                AppTextField(
                  label: strings[AppLocalization.password] ?? 'Password',
                  hint: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onSuffixTap: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return strings[AppLocalization.password_required];
                    }
                    if (value.length < 8) {
                      return strings[AppLocalization.password_too_short];
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: strings[AppLocalization.confirm_password] ?? 'Confirm Password',
                  hint: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onSuffixTap: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  onSubmitted: (_) => _submit(),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return strings[AppLocalization.password_mismatch];
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppSpacing.xxl),
                AppButton(
                  text: strings[AppLocalization.reset_password] ?? 'Reset Password',
                  isLoading: isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
