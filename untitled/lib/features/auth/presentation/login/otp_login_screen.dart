import 'package:flutter/material.dart';
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

class OtpLoginScreen extends ConsumerStatefulWidget {
  const OtpLoginScreen({super.key});

  @override
  ConsumerState<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends ConsumerState<OtpLoginScreen> {
  final _identifierController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPhone = false;

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    context.hideKeyboard();

    final value = _identifierController.text.trim();
    await ref.read(authProvider.notifier).requestLoginOtp(
          email: _isPhone ? null : value,
          phone: _isPhone ? value : null,
          channel: _isPhone ? 'phone' : 'email',
        );

    if (!mounted) return;
    final authState = ref.read(authProvider);
    if (authState.otpToken != null && authState.otpMode == 'login') {
      context.push(AppRoutes.otp);
    } else if (authState.error != null) {
      context.showErrorSnackBar(
        authState.error ?? 'Please check your connection and try again',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final isLoading = ref.watch(authProvider.select((s) => s.isLoading));

    return Scaffold(
      appBar: AppAppBar(title: strings[AppLocalization.login_with_code] ?? 'Login with Code'),
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
                      Icons.sms_outlined,
                      size: 50.sp,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.xl),
                Text(
                  strings[AppLocalization.login_with_code] ?? 'Login with Code',
                  style: AppTextStyles.displaySmall(),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  strings[AppLocalization.login_code_instruction] ??
                      'Enter your email or phone number and we\'ll send you a verification code.',
                  style: AppTextStyles.bodyMedium(),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppSpacing.xxl),
                AppTextField(
                  label: strings[AppLocalization.email_or_phone] ?? 'Email or Phone',
                  hint: _isPhone ? '05XXXXXXXX' : 'example@email.com',
                  controller: _identifierController,
                  keyboardType:
                      _isPhone ? TextInputType.phone : TextInputType.emailAddress,
                  prefixIcon: Icon(
                    _isPhone ? Icons.phone_outlined : Icons.email_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return strings[AppLocalization.field_required] ??
                          'This field is required';
                    }
                    if (!_isPhone && !value.isValidEmail) {
                      return strings[AppLocalization.invalid_email];
                    }
                    if (_isPhone && value.length < 10) {
                      return strings[AppLocalization.phone_min_length] ??
                          'Enter a valid phone number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _channelOption(
                        strings,
                        label: strings[AppLocalization.channel_email] ?? 'Email',
                        icon: Icons.email_outlined,
                        selected: !_isPhone,
                        onTap: () => setState(() => _isPhone = false),
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _channelOption(
                        strings,
                        label: strings[AppLocalization.channel_phone] ?? 'Phone',
                        icon: Icons.phone_outlined,
                        selected: _isPhone,
                        onTap: () => setState(() => _isPhone = true),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.xxl),
                AppButton(
                  text: strings[AppLocalization.send_code] ?? 'Send Code',
                  isLoading: isLoading,
                  onPressed: _sendCode,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _channelOption(
    Map<String, String> strings, {
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? AppColors.primaryUltraLight : context.cardColor,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: selected ? AppColors.primary : context.dividerColor,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20.sp,
                color: selected ? AppColors.primary : context.textSecondaryColor,
              ),
              SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTextStyles.labelLarge(
                  color: selected ? AppColors.primary : context.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
