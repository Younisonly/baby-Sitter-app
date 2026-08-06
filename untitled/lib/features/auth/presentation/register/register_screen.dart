import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/extensions.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/routing/app_routes.dart';
import 'package:babysitter/core/services/auth_provider.dart';
import 'package:babysitter/core/services/role_manager.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/shared/widgets/widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  final _nationalIdController = TextEditingController();
  final _nationalIdFocus = FocusNode();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  AppRole _selectedRole = AppRole.parent;
  String _verificationChannel = 'email';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final roleState = ref.read(roleManagerProvider);
      if (roleState.activeRole == AppRole.sitter || roleState.activeRole == AppRole.parent) {
        setState(() => _selectedRole = roleState.activeRole);
      }
      final queryRole = GoRouterState.of(context).uri.queryParameters['role'];
      if (queryRole == 'sitter') {
        setState(() => _selectedRole = AppRole.sitter);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nationalIdController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _nationalIdFocus.dispose();
    super.dispose();
  }

  bool get _isSitter => _selectedRole == AppRole.sitter;

  List<Color> get _roleGradient => AppColors.primaryGradient;

  IconData get _roleIcon =>
      _isSitter ? Icons.work_rounded : Icons.family_restroom_rounded;

  String _title(Map<String, String> strings) =>
      _isSitter
          ? (strings[AppLocalization.register_sitter_title] ?? 'Become a Sitter')
          : (strings[AppLocalization.register_parent_title] ?? 'Create Parent Account');

  String _subtitle(Map<String, String> strings) =>
      _isSitter
          ? (strings['sitter_register_desc'] ??
              'Offer childcare services, set your rates, and earn')
          : (strings['parent_register_desc'] ??
              'Find and book trusted babysitters for your children');

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    context.hideKeyboard();

    await ref.read(authProvider.notifier).register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.trim(),
      role: _isSitter ? 'babysitter' : 'customer',
      nationalId: _isSitter ? _nationalIdController.text.trim() : null,
      channel: _verificationChannel,
    );

    if (!mounted) return;
    final authState = ref.read(authProvider);
    if (authState.otpToken != null) {
      final strings = AppLocalization.get(ref.read(languageProvider).code);
      final sentTo = authState.otpChannel == 'phone'
          ? _phoneController.text.trim()
          : _emailController.text.trim();
      context.showSuccessSnackBar(
        '${strings[AppLocalization.code_sent_success] ?? 'Verification code sent'} '
        '($sentTo)',
      );
      context.pushReplacement(
        '${AppRoutes.otp}?phone=${_phoneController.text}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final isLoading = ref.watch(authProvider.select((s) => s.isLoading));
    final error = ref.watch(authProvider.select((s) => s.error));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                  children: [
                    _buildHeader(strings),
                    _buildRoleToggle(strings),
                    Transform.translate(
                      offset: const Offset(0, -AppSpacing.xs),
                      child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        0,
                        AppSpacing.xl,
                        AppSpacing.xxl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTitle(strings),
                          const SizedBox(height: AppSpacing.lg),
                          AppTextField(
                            label: strings[AppLocalization.full_name] ?? 'Full Name',
                        hint: strings[AppLocalization.name_hint] ?? 'John Doe',
                        controller: _nameController,
                        focusNode: _nameFocus,
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(Icons.person_outline),
                        onSubmitted: (_) => _emailFocus.requestFocus(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return strings[AppLocalization.name_required] ??
                                'Name is required';
                          }
                          if (value.trim().length < 2) {
                            return strings[AppLocalization.name_too_short] ??
                                'Name must be at least 2 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        label: strings[AppLocalization.email] ?? 'Email',
                        hint: strings[AppLocalization.email_hint] ?? 'example@email.com',
                        controller: _emailController,
                        focusNode: _emailFocus,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(Icons.email_outlined),
                        onSubmitted: (_) => _phoneFocus.requestFocus(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return strings[AppLocalization.email_required] ??
                                'Email is required';
                          }
                          if (!value.isValidEmail) {
                            return strings[AppLocalization.invalid_email] ??
                                'Invalid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        label: strings[AppLocalization.phone_number] ?? 'Phone Number',
                        hint: strings[AppLocalization.phone_hint] ?? '+9665XXXXXXXX',
                        controller: _phoneController,
                        focusNode: _phoneFocus,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(Icons.phone_outlined),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9+]'),
                          ),
                          LengthLimitingTextInputFormatter(13),
                        ],
                        onSubmitted: (_) => _passwordFocus.requestFocus(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return strings[AppLocalization.phone_required] ??
                                'Phone number is required';
                          }
                          final digits = value.replaceAll(RegExp(r'[^0-9+]'), '');
                          final isKsa = RegExp(r'^(\+9665\d{8}|9665\d{8}|05\d{8})$')
                              .hasMatch(digits);
                          if (!isKsa) {
                            return strings[AppLocalization.phone_invalid_ksa] ??
                                'Enter a valid Saudi number, e.g. +9665XXXXXXXX';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        label: strings[AppLocalization.password] ?? 'Password',
                        hint: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
                        controller: _passwordController,
                        focusNode: _passwordFocus,
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
                        onSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return strings[AppLocalization.password_required] ??
                                'Password is required';
                          }
                          if (value.length < 8) {
                            return strings[AppLocalization.password_too_short] ??
                                'Password must be at least 8 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        label: strings[AppLocalization.confirm_password] ?? 'Confirm Password',
                        hint: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
                        controller: _confirmPasswordController,
                        focusNode: _confirmPasswordFocus,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onSuffixTap: () => setState(
                            () => _obscureConfirmPassword = !_obscureConfirmPassword),
                        onSubmitted: (_) => _register(),
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return strings[AppLocalization.password_mismatch] ??
                                'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      if (_isSitter) ...[
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          label: strings[AppLocalization.national_id] ?? 'National ID',
                          hint: strings[AppLocalization.national_id_hint] ?? 'e.g. 1234567890',
                          controller: _nationalIdController,
                          focusNode: _nationalIdFocus,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.done,
                          prefixIcon: const Icon(Icons.badge_outlined),
                          onSubmitted: (_) => _register(),
                          validator: _isSitter
                              ? (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return strings[AppLocalization.national_id_required] ??
                                        'National ID is required for sitter registration';
                                  }
                                  if (value.trim().length < 10) {
                                    return strings[AppLocalization.national_id_too_short] ??
                                        'Enter a valid National ID (min 10 digits)';
                                  }
                                  return null;
                                }
                              : null,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      _buildChannelSelector(strings),
                      const SizedBox(height: AppSpacing.lg),
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: context.errorColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: context.errorColor.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline_rounded,
                                    color: context.errorColor, size: 20),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    error,
                                    style: AppTextStyles.bodySmall(
                                      color: context.errorColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      AppButton(
                        text: strings[AppLocalization.create_account] ??
                            'Create Account',
                        isLoading: isLoading,
                        onPressed: _register,
                      ),
                      if (_isSitter) ...[
                        const SizedBox(height: AppSpacing.md),
                        _buildAbsherNotice(strings),
                      ],
                      const SizedBox(height: AppSpacing.xxl),
                      _buildSignInRow(strings),
                      const SizedBox(height: AppSpacing.md),
                      _buildTermsText(strings),
                    ],
                    ),
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

  Widget _buildHeader(Map<String, String> strings) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: 0,
        left: AppSpacing.sm,
        right: AppSpacing.sm,
        bottom: AppSpacing.xxl * 1.5,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _roleGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xxl * 2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.white),
                onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.welcome),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.white.withValues(alpha: 0.15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 0),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
              child: Container(
              key: ValueKey(_isSitter),
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(_roleIcon, size: 40, color: AppColors.white),
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _title(strings),
              key: ValueKey('title_$_isSitter'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _subtitle(strings),
              key: ValueKey('sub_$_isSitter'),
              style: TextStyle(
                fontSize: 14,
                color: AppColors.white.withValues(alpha: 0.85),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleToggle(Map<String, String> strings) {
    return Transform.translate(
      offset: const Offset(0, -AppSpacing.xxl),
      child: RoleToggle(
        isSitterSelected: _isSitter,
        onToggle: (isSitter) {
          setState(() => _selectedRole = isSitter ? AppRole.sitter : AppRole.parent);
        },
        parentLabel: strings[AppLocalization.register_as_parent_short] ?? 'Parent',
        sitterLabel: strings[AppLocalization.register_as_sitter_short] ?? 'Sitter',
      ),
    );
  }

  Widget _buildTitle(Map<String, String> strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings[AppLocalization.create_account] ?? 'Create Account',
          style: AppTextStyles.headlineMedium(),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          strings[AppLocalization.register_subtitle] ??
              'Fill in your details to get started',
          style: AppTextStyles.bodyMedium(color: context.textSecondaryColor),
        ),
      ],
    );
  }

  Widget _buildChannelSelector(Map<String, String> strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings[AppLocalization.verification_method] ??
              'Send verification code via',
          style: AppTextStyles.labelLarge(color: context.textSecondaryColor),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _channelOption(
                strings,
                label: strings[AppLocalization.channel_email] ?? 'Email',
                icon: Icons.email_outlined,
                selected: _verificationChannel == 'email',
                onTap: () => setState(() => _verificationChannel = 'email'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _channelOption(
                strings,
                label: strings[AppLocalization.channel_phone] ?? 'Phone',
                icon: Icons.phone_outlined,
                selected: _verificationChannel == 'phone',
                onTap: () => setState(() => _verificationChannel = 'phone'),
              ),
            ),
          ],
        ),
      ],
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
                size: 20,
                color: selected ? AppColors.primary : context.textSecondaryColor,
              ),
              const SizedBox(width: AppSpacing.xs),
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

  Widget _buildSignInRow(Map<String, String> strings) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            strings[AppLocalization.already_have_account] ??
                'Already have an account?',
            style: AppTextStyles.bodyMedium(color: context.textMutedColor),
          ),
          TextButton(
            onPressed: () => context.go(_isSitter ? '${AppRoutes.login}?role=sitter' : AppRoutes.login),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              strings[AppLocalization.sign_in] ?? 'Sign In',
              style: AppTextStyles.labelLarge(color: context.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbsherNotice(Map<String, String> strings) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.infoColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: context.infoColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_rounded,
              color: context.infoColor, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              strings[AppLocalization.absher_verification] ??
                  'Your identity will be verified through Absher for security purposes.',
              style: AppTextStyles.caption(color: context.textSecondaryColor),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTermsText(Map<String, String> strings) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: AppTextStyles.caption(color: context.textMutedColor),
          children: [
            TextSpan(
              text: strings[AppLocalization.by_creating_account_agree] ??
                  'By creating an account, you agree to our ',
            ),
            WidgetSpan(
              child: GestureDetector(
                onTap: () => context.push(AppRoutes.terms),
                child: Text(
                  strings[AppLocalization.terms_conditions] ?? 'Terms & Conditions',
                  style: AppTextStyles.caption(
                    color: context.primaryColor,
                  ).copyWith(decoration: TextDecoration.underline),
                ),
              ),
            ),
            TextSpan(
              text: strings[AppLocalization.and_link] ?? ' and ',
            ),
            WidgetSpan(
              child: GestureDetector(
                onTap: () => context.push(AppRoutes.privacy),
                child: Text(
                  strings[AppLocalization.privacy_policy] ?? 'Privacy Policy',
                  style: AppTextStyles.caption(
                    color: context.primaryColor,
                  ).copyWith(decoration: TextDecoration.underline),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
