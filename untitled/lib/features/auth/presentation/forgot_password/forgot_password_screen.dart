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

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _channelIsEmail = true;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    context.hideKeyboard();

    await ref.read(authProvider.notifier).forgotPassword(
          email: _channelIsEmail ? _emailController.text.trim() : null,
          phone: _channelIsEmail ? null : _phoneController.text.trim(),
        );

    if (!mounted) return;
    final authState = ref.read(authProvider);
    if (authState.otpToken != null && authState.otpMode == 'reset') {
      final strings = AppLocalization.get(ref.read(languageProvider).code);
      final contact = authState.otpContact;
      AppDialog.show(
        context: context,
        icon: authState.otpChannel == 'phone'
            ? Icons.sms_rounded
            : Icons.mark_email_read_rounded,
        title: strings[AppLocalization.code_sent] ?? 'Code Sent',
        content: authState.otpChannel == 'phone'
            ? '${strings[AppLocalization.code_sent_to_phone] ?? 'We sent your verification code via SMS to'}\n$contact'
            : '${strings[AppLocalization.code_sent_to_email] ?? 'We sent your verification code to'}\n$contact',
        confirmText: strings[AppLocalization.enter_code] ?? 'Enter Code',
        cancelText: strings[AppLocalization.change_contact] ?? 'Change',
        onConfirm: () => context.push(AppRoutes.otp),
        onCancel: () {},
      );
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
      appBar: AppAppBar(
        title: strings[AppLocalization.forgot_password] ?? 'Forgot Password',
      ),
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
                      _channelIsEmail
                          ? Icons.lock_reset_rounded
                          : Icons.sms_rounded,
                      size: 50.sp,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.xl),
                Text(
                  strings[AppLocalization.reset_password] ??
                      'Reset Password',
                  style: AppTextStyles.displaySmall(),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  strings[AppLocalization.reset_password_instruction] ??
                      'Enter your email or phone number and we\'ll send you a verification code.',
                  style: AppTextStyles.bodyMedium(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.xxl),
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: true,
                      icon: const Icon(Icons.email_rounded, size: 18),
                      label: Text(
                        strings[AppLocalization.channel_email] ?? 'Email',
                      ),
                    ),
                    ButtonSegment(
                      value: false,
                      icon: const Icon(Icons.sms_rounded, size: 18),
                      label: Text(
                        strings[AppLocalization.channel_phone] ?? 'Phone',
                      ),
                    ),
                  ],
                  selected: {_channelIsEmail},
                  onSelectionChanged: (selection) {
                    setState(() => _channelIsEmail = selection.first);
                    _formKey.currentState?.reset();
                  },
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
                    textStyle: WidgetStatePropertyAll(
                      AppTextStyles.bodyMedium(weight: FontWeight.w600),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
                if (_channelIsEmail)
                  AppTextField(
                    label: strings[AppLocalization.email],
                    hint: 'example@email.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return strings[AppLocalization.email_required];
                      }
                      if (!value.isValidEmail) {
                        return strings[AppLocalization.invalid_email];
                      }
                      return null;
                    },
                  )
                else
                  AppTextField(
                    label: strings[AppLocalization.phone_number],
                    hint: '+967 7XXXXXXXX',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(Icons.phone_outlined),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return strings[AppLocalization.phone_required];
                      }
                      return null;
                    },
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
}
