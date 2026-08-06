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
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/core/routing/app_routes.dart';
import 'package:babysitter/core/services/auth_provider.dart';
import 'package:babysitter/shared/widgets/widgets.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _resendTimer = 60;
  bool _canResend = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        if (_resendTimer > 0) {
          setState(() => _resendTimer--);
          _startResendTimer();
        } else {
          setState(() => _canResend = true);
        }
      }
    });
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_otp.length != 6) return;
    context.hideKeyboard();

    final authState = ref.read(authProvider);
    final mode = authState.otpMode;

    if (mode == 'reset') {
      ref.read(authProvider.notifier).setPendingOtp(_otp);
      if (!mounted) return;
      context.pushReplacement(AppRoutes.resetPassword);
      return;
    }

    await ref.read(authProvider.notifier).verifyOtp(_otp);

    if (!mounted) return;
    final state = ref.read(authProvider);
    if (state.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.home);
      });
    } else if (state.error != null) {
      context.showErrorSnackBar(state.error ?? 'Please check your connection and try again');
    }
  }

  Future<void> _resend() async {
    if (_isResending) return;
    setState(() {
      _isResending = true;
      _canResend = false;
      _resendTimer = 60;
    });
    await ref.read(authProvider.notifier).resendOtp();
    if (!mounted) return;
    setState(() => _isResending = false);
    _startResendTimer();
    final authState = ref.read(authProvider);
    final strings = AppLocalization.get(ref.read(languageProvider).code);
    if (authState.error != null) {
      context.showErrorSnackBar(authState.error ?? 'Please check your connection and try again');
    } else {
      context.showSuccessSnackBar(
        strings[AppLocalization.code_resent] ?? 'Verification code resent',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final authState = ref.watch(authProvider);
    final contact = authState.otpContact.isNotEmpty
        ? authState.otpContact
        : widget.phone;

    return Scaffold(
      appBar: AppAppBar(title: strings[AppLocalization.otp_verification]),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: SingleChildScrollView(
            child: Column(
            children: [
              SizedBox(height: AppSpacing.xxl),
              Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  color: AppColors.primaryUltraLight,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Icon(
                  Icons.security_rounded,
                  size: 40.sp,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              Text(
                strings[AppLocalization.otp_verification] ??
                    'OTP Verification',
                style: AppTextStyles.displaySmall(),
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                strings[AppLocalization.enter_otp] ??
                    'Enter the verification code',
                style: AppTextStyles.bodyMedium(),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                contact,
                style: AppTextStyles.titleMedium(
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: AppSpacing.xxl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 48.w,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: AppTextStyles.headlineMedium(),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.md),
                          borderSide: const BorderSide(
                            color: AppColors.dividerLight,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.md),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        }
                        if (_otp.length == 6) {
                          _verify();
                        }
                      },
                    ),
                  );
                }),
              ),
              SizedBox(height: AppSpacing.xxl),
              AppButton(
                text: strings[AppLocalization.verify] ?? 'Verify',
                isLoading: authState.isLoading,
                onPressed: _otp.length == 6 ? _verify : null,
              ),
              SizedBox(height: AppSpacing.lg),
              if (!_canResend)
                Text(
                  (strings[AppLocalization.resend_in] ?? 'Resend code in {seconds}s')
                      .replaceFirst('{seconds}', '$_resendTimer'),
                  style: AppTextStyles.bodyMedium(),
                )
              else
                TextButton(
                  onPressed: _isResending ? null : _resend,
                  child: Text(
                    _isResending
                        ? (strings[AppLocalization.resending] ?? 'Resending...')
                        : (strings[AppLocalization.resend_code] ?? 'Resend Code'),
                    style: AppTextStyles.labelLarge(),
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
