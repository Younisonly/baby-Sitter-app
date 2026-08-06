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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;
  AppRole _selectedRole = AppRole.parent;
  bool _isRedirecting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final roleState = ref.read(roleManagerProvider);
      final queryRole = GoRouterState.of(context).uri.queryParameters['role'];

      if (queryRole == 'sitter' && roleState.canActAsSitter) {
        setState(() => _selectedRole = AppRole.sitter);
      } else if (queryRole == 'parent' && roleState.canActAsParent) {
        setState(() => _selectedRole = AppRole.parent);
      } else if (roleState.isSitter && roleState.canActAsSitter) {
        setState(() => _selectedRole = AppRole.sitter);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool get _isSitter => _selectedRole == AppRole.sitter;
  bool get _isParent => _selectedRole == AppRole.parent;

  IconData get _roleIcon =>
      _isSitter ? Icons.work_rounded : Icons.family_restroom_rounded;

  String _title(Map<String, String> strings) =>
      _isSitter
          ? (strings[AppLocalization.sitter_login_title] ?? 'Welcome back, Sitter')
          : (strings[AppLocalization.parent_login_title] ?? 'Welcome back, Parent');

  String _subtitle(Map<String, String> strings) =>
      _isSitter
          ? (strings[AppLocalization.sitter_login_subtitle] ??
              'Sign in to manage your babysitting business')
          : (strings[AppLocalization.parent_login_subtitle] ??
              'Sign in to find and book trusted sitters');

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    context.hideKeyboard();

    final result = await ref.read(authProvider.notifier).login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      preferredRole: _selectedRole,
    );

    if (!mounted) return;
    final authState = ref.read(authProvider);

    if (authState.isAuthenticated) {
      if (result?.containsKey('roleUnavailable') == true) {
        _showRoleUnavailableDialog(result!['roleUnavailable'] as String);
        return;
      }

      setState(() => _isRedirecting = true);
      if (!mounted) return;
      context.go(_isSitter ? AppRoutes.sitterDashboard : AppRoutes.parentHome);
    }
  }

  void _showRoleUnavailableDialog(String role) {
    final strings = AppLocalization.get(ref.read(languageProvider).code);
    final isSitterUnavailable = role == 'sitter';

    AppDialog.show(
      context: context,
      title: strings[AppLocalization.role_unavailable_title] ?? 'Role Not Available',
      content: isSitterUnavailable
          ? (strings[AppLocalization.sitter_profile_unavailable] ??
              "You haven't created a sitter profile yet.")
          : (strings[AppLocalization.parent_profile_unavailable] ??
              "Parent profile not available for this account."),
      confirmText: isSitterUnavailable
          ? (strings[AppLocalization.become_sitter_action] ?? 'Become a Sitter')
          : (strings[AppLocalization.continue_as_parent_action] ?? 'Continue as Parent'),
      cancelText: isSitterUnavailable
          ? (strings[AppLocalization.continue_as_parent_action] ?? 'Continue as Parent')
          : (strings[AppLocalization.switch_to_sitter] ?? 'Switch to Sitter'),
      onConfirm: () async {
        if (!mounted) return;
        if (isSitterUnavailable) {
          context.go(AppRoutes.becomeSitter);
        } else {
          ref.read(roleManagerProvider.notifier).switchToParent();
          if (!mounted) return;
          context.go(AppRoutes.parentHome);
        }
      },
      onCancel: () async {
        if (!mounted) return;
        if (isSitterUnavailable) {
          ref.read(roleManagerProvider.notifier).switchToParent();
          if (!mounted) return;
          context.go(AppRoutes.parentHome);
        } else {
          ref.read(roleManagerProvider.notifier).switchToSitter();
          if (!mounted) return;
          context.go(AppRoutes.sitterDashboard);
        }
      },
    );
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
                            label: strings[AppLocalization.email] ?? 'Email',
                            hint: strings[AppLocalization.email_hint] ?? 'example@email.com',
                            controller: _emailController,
                            focusNode: _emailFocus,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            prefixIcon: const Icon(Icons.email_outlined),
                            onSubmitted: (_) => _passwordFocus.requestFocus(),
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
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            label: strings[AppLocalization.password] ?? 'Password',
                            hint: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onSuffixTap: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                            onSubmitted: (_) => _login(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return strings[AppLocalization.password_required] ??
                                    'Password is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () => context.push(AppRoutes.otpLogin),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  strings[AppLocalization.login_with_code] ??
                                      'Login with Code',
                                  style: AppTextStyles.bodySmall(color: context.primaryColor),
                                ),
                              ),
                              Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: TextButton(
                                  onPressed: () =>
                                      context.push(AppRoutes.forgotPassword),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    strings[AppLocalization.forgot_password] ??
                                        'Forgot Password?',
                                    style: AppTextStyles.bodySmall(color: context.primaryColor),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                                        strings[error] ?? error,
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
                            text: strings[AppLocalization.login] ?? 'Login',
                            isLoading: isLoading || _isRedirecting,
                            onPressed: _login,
                          ),
                          if (_isParent) ...[
                            const SizedBox(height: AppSpacing.lg),
                            _buildDivider(),
                            const SizedBox(height: AppSpacing.lg),
                            _buildGoogleButton(strings, isLoading),
                          ],
                          const SizedBox(height: AppSpacing.xl),
                          _buildSignUpRow(strings),
                          const SizedBox(height: AppSpacing.md),
                          _buildVisitorLink(strings),
                          const SizedBox(height: AppSpacing.lg),
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
      padding: const EdgeInsets.only(
        top: 0,
        left: AppSpacing.sm,
        right: AppSpacing.sm,
        bottom: AppSpacing.xxl * 1.5,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xxl * 2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
        parentLabel: strings[AppLocalization.parent_role] ?? 'Parent',
        sitterLabel: strings[AppLocalization.sitter_role] ?? 'Sitter',
      ),
    );
  }

  Widget _buildTitle(Map<String, String> strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings[AppLocalization.login] ?? 'Sign In',
          style: AppTextStyles.headlineMedium(),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          strings[AppLocalization.login_subtitle] ??
              'Enter your credentials to access your account',
          style: AppTextStyles.bodyMedium(color: context.textSecondaryColor),
        ),
      ],
    );
  }

  Widget _buildSignUpRow(Map<String, String> strings) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            strings[AppLocalization.dont_have_account] ??
                "Don't have an account?",
            style: AppTextStyles.bodyMedium(color: context.textMutedColor),
          ),
          TextButton(
            onPressed: () => context.go(_isSitter ? '${AppRoutes.register}?role=sitter' : AppRoutes.register),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              strings[AppLocalization.sign_up] ?? 'Sign Up',
              style: AppTextStyles.labelLarge(color: context.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitorLink(Map<String, String> strings) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: TextButton(
            onPressed: () {
              ref.read(roleManagerProvider.notifier).switchToVisitor();
              context.go(AppRoutes.visitorHome);
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              strings[AppLocalization.continue_as_visitor] ??
                  'Continue as Visitor',
              style: AppTextStyles.bodySmall(color: context.textMutedColor),
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildDivider() {
    final strings = AppLocalization.get(ref.read(languageProvider).code);
    return Row(
      children: [
        Expanded(child: Divider(color: context.dividerColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            strings[AppLocalization.or] ?? 'OR',
            style: AppTextStyles.bodySmall(color: context.textMutedColor),
          ),
        ),
        Expanded(child: Divider(color: context.dividerColor)),
      ],
    );
  }

  Widget _buildGoogleButton(Map<String, String> strings, bool isLoading) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: isLoading
            ? null
            : () async {
                final error = await ref.read(authProvider.notifier).loginWithGoogle();
                if (!mounted) return;
                ref.read(authProvider.notifier).clearError();
                if (error == null) {
                  final updatedState = ref.read(authProvider);
                  if (updatedState.isAuthenticated) {
                    setState(() => _isRedirecting = true);
                    if (!mounted) return;
                    context.go(AppRoutes.parentHome);
                  }
                } else {
                  if (!mounted) return;
                  AppSnackbar.error(context, error);
                }
              },
        icon: Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          child: const Text(
            'G',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF4285F4),
              fontFamily: 'Georgia',
            ),
          ),
        ),
        label: Text(
          strings[AppLocalization.google_sign_in] ?? 'Continue with Google',
          style: AppTextStyles.labelLarge(),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          side: BorderSide(color: context.dividerColor),
          backgroundColor: context.cardColor,
          foregroundColor: context.textPrimaryColor,
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
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
              text: strings[AppLocalization.by_signing_in_agree] ??
                  'By signing in, you agree to our ',
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
