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
  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();
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
    _otpController.dispose();
    _otpFocusNode.dispose();
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

  String get _otp => _otpController.text.replaceAll(RegExp(r'\D'), '');

  void _onOtpChanged(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 6) {
      _otpController.text = digits.substring(0, 6);
      _otpController.selection = TextSelection.collapsed(
        offset: _otpController.text.length,
      );
    }
    setState(() {});
    if (_otp.length == 6) {
      _verify();
    }
  }

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
    final isEmail = authState.otpChannel == 'email';
    final contact = authState.otpContact.isNotEmpty
        ? authState.otpContact
        : widget.phone;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.welcome);
        }
      },
      child: Scaffold(
        appBar: AppAppBar(
          title: strings[AppLocalization.otp_verification],
          onBackPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.welcome);
            }
          },
        ),
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
                  isEmail ? Icons.mark_email_read_rounded : Icons.sms_rounded,
                  size: 40.sp,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              Text(
                strings[AppLocalization.otp_verification] ??
                    'Verification Code',
                style: AppTextStyles.displaySmall(),
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                strings[AppLocalization.otp_sent_to] ??
                    'We sent a 6-digit verification code to',
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
              GestureDetector(
                onTap: () => _otpFocusNode.requestFocus(),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    final digit = _otp.length > index
                        ? _otp[index]
                        : null;
                    final isActive = index == _otp.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 48.w,
                      height: 56.h,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius:
                            BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          width: isActive ? 2 : 1,
                          color: isActive
                              ? AppColors.primary
                              : AppColors.dividerLight,
                        ),
                      ),
                      child: Text(
                        digit ?? '',
                        style: AppTextStyles.headlineMedium(
                          color: digit == null
                              ? AppColors.dividerLight
                              : context.textPrimaryColor,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              SizedBox(height: AppSpacing.md),
              TextField(
                controller: _otpController,
                focusNode: _otpFocusNode,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                autofocus: true,
                showCursor: false,
                style: const TextStyle(fontSize: 1, color: Colors.transparent),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  counterText: '',
                ),
                onChanged: _onOtpChanged,
              ),
              Text(
                strings[AppLocalization.otp_paste_hint] ??
                    'You can paste the code from your messages',
                style: AppTextStyles.bodySmall(
                  color: context.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
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
              else if (_canResendViaOtherChannel())
                Column(
                  children: [
                    Text(
                      strings[AppLocalization.didnt_get_code] ??
                          "Didn't get the code?",
                      style: AppTextStyles.bodyMedium(),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AppSpacing.sm,
                      children: [
                        _resendChannelButton(
                          label: strings[AppLocalization.resend_via_email] ??
                              'Resend via Email',
                          icon: Icons.email_outlined,
                          channel: 'email',
                        ),
                        _resendChannelButton(
                          label: strings[AppLocalization.resend_via_phone] ??
                              'Resend via SMS',
                          icon: Icons.sms_outlined,
                          channel: 'phone',
                        ),
                      ],
                    ),
                  ],
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
      ),
    );
  }

  bool _canResendViaOtherChannel() {
    final authState = ref.read(authProvider);
    return (authState.otpEmail?.isNotEmpty ?? false) &&
        (authState.otpPhone?.isNotEmpty ?? false);
  }

  Widget _resendChannelButton({
    required String label,
    required IconData icon,
    required String channel,
  }) {
    return OutlinedButton.icon(
      onPressed: _isResending
          ? null
          : () => _resendToChannel(channel),
      icon: Icon(icon, size: 18.sp),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
    );
  }

  Future<void> _resendToChannel(String channel) async {
    if (_isResending) return;
    setState(() {
      _isResending = true;
      _canResend = false;
      _resendTimer = 60;
    });
    await ref.read(authProvider.notifier).resendOtp(channel: channel);
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
}
