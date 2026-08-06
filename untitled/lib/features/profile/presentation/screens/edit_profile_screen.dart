import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:babysitter/core/constants/app_image_types.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_sizes.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/extensions.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/services/auth_provider.dart';
import 'package:babysitter/core/services/role_manager.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/shared/widgets/widgets.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _nationalIdController = TextEditingController();

  String? _avatarUrl;
  bool _isUploadingAvatar = false;
  bool _isSaving = false;

  String? _originalName;
  String? _originalEmail;
  String? _originalPhone;
  String? _originalLocation;
  String? _originalNationalId;
  String? _originalAvatar;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _originalName = user?.name ?? '';
    _originalEmail = user?.email ?? '';
    _originalPhone = user?.phone ?? '';
    _originalLocation = user?.location ?? '';
    _originalNationalId = user?.nationalId;
    _originalAvatar = user?.avatar;

    _nameController.text = _originalName!;
    _emailController.text = _originalEmail!;
    _phoneController.text = _originalPhone ?? '';
    _locationController.text = _originalLocation ?? '';
    _nationalIdController.text = _originalNationalId ?? '';
    _avatarUrl = _originalAvatar;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _nationalIdController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    setState(() => _isUploadingAvatar = true);
    final url = await AppImagePicker.pickAndUpload(
      context: context,
      ref: ref,
      uploadType: ImageUploadType.avatar,
    );
    if (mounted) {
      if (url != null) {
        final notifier = ref.read(authProvider.notifier);
        final currentUser = ref.read(authProvider).user;
        if (currentUser != null) {
          final updated = currentUser.copyWith(avatar: url);
          notifier.updateUserDirectly(updated);
        }
      }
      setState(() {
        _isUploadingAvatar = false;
        if (url != null) _avatarUrl = url;
      });
    }
  }

  bool get _emailChanged =>
      _emailController.text.trim() != _originalEmail;

  bool get _phoneChanged =>
      _phoneController.text.trim() != (_originalPhone ?? '');

  bool get _sensitiveChanged => _emailChanged || _phoneChanged;

  bool get _hasChanges {
    return _nameController.text.trim() != _originalName ||
        _emailChanged ||
        _phoneChanged ||
        _locationController.text.trim() != (_originalLocation ?? '') ||
        _nationalIdController.text.trim() != (_originalNationalId ?? '') ||
        _avatarUrl != _originalAvatar;
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    return null;
  }

  String? _validateEmail(String? value) {
    if (!_emailChanged) return null;
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!value.trim().isValidEmail) return 'Enter a valid email';
    return null;
  }

  String? _validatePhone(String? value) {
    if (!_phoneChanged) return null;
    if (value == null || value.trim().isEmpty) return 'Phone is required';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      final s = AppLocalization.get(ref.read(languageProvider).code);
      context.showErrorSnackBar(s[AppLocalization.please_fix_form_errors] ?? 'Please fix the form errors');
      return;
    }
    if (!_hasChanges) {
      final s = AppLocalization.get(ref.read(languageProvider).code);
      context.showInfoSnackBar(s[AppLocalization.no_changes_to_save] ?? 'No changes to save');
      return;
    }

    setState(() => _isSaving = true);

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final location = _locationController.text.trim();
    final nationalId = _nationalIdController.text.trim();

    final roleState = ref.read(roleManagerProvider);
    final isSitter = roleState.isSitter;

    try {
      if (_sensitiveChanged) {
        final result = await ref.read(authProvider.notifier).sendUpdateOtp(
              email: _emailChanged ? email : null,
              phone: _phoneChanged ? phone : null,
            );
        await _saveNonSensitive(name, location, nationalId: isSitter ? nationalId : null);
        if (!mounted) return;
        await _showOtpSheet(result['otpToken'] as String);
      } else {
        await ref.read(authProvider.notifier).updateProfile(
              name: name,
              email: _originalEmail,
              phone: _originalPhone,
              location: location,
              avatar: _avatarUrl != _originalAvatar ? _avatarUrl : null,
              nationalId: isSitter ? nationalId : null,
            );
        if (!mounted) return;
        _updateOriginals();
        final s = AppLocalization.get(ref.read(languageProvider).code);
        context.showSuccessSnackBar(s[AppLocalization.profile_updated_successfully] ?? 'Profile updated successfully');
      }
    } catch (e) {
      if (!mounted) return;
      final error = ref.read(authProvider).error;
      final s = AppLocalization.get(ref.read(languageProvider).code);
      context.showErrorSnackBar(error ?? (s[AppLocalization.failed_to_update_profile] ?? 'Failed to update profile'));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveNonSensitive(String name, String location, {String? nationalId}) async {
    await ref.read(authProvider.notifier).updateProfile(
          name: name,
          email: _originalEmail,
          phone: _originalPhone,
          location: location,
          avatar: _avatarUrl != _originalAvatar ? _avatarUrl : null,
          nationalId: nationalId,
        );
  }

  Future<void> _showOtpSheet(String otpToken) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => _OtpVerificationSheet(otpToken: otpToken),
    );
    if (confirmed == true && mounted) {
      _updateOriginals();
      final s = AppLocalization.get(ref.read(languageProvider).code);
      context.showSuccessSnackBar(s[AppLocalization.profile_updated] ?? 'Profile updated');
    }
  }

  void _updateOriginals() {
    _originalName = _nameController.text.trim();
    _originalEmail = _emailController.text.trim();
    _originalPhone = _phoneController.text.trim();
    _originalLocation = _locationController.text.trim();
    _originalNationalId = _nationalIdController.text.trim();
    _originalAvatar = _avatarUrl;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = context.isDark;
    final strings = AppLocalization.get(Localizations.localeOf(context).languageCode);

    return Scaffold(
      appBar: AppAppBar(title: strings[AppLocalization.edit_profile] ?? 'Edit Profile'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.huge,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildAvatarSection(cs, isDark),
              SizedBox(height: AppSpacing.xl),
              _buildSectionHeader('Personal Info'),
              SizedBox(height: AppSpacing.md),
              _buildInfoCard(cs, isDark),
              SizedBox(height: AppSpacing.lg),
              _buildSectionHeader('Contact'),
              SizedBox(height: AppSpacing.md),
              _buildContactCard(cs, isDark),
              SizedBox(height: AppSpacing.xxl),
              _buildSaveButton(cs, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        title,
        style: AppTextStyles.titleSmall(
          weight: FontWeight.w700,
          color: context.textSecondary,
        ),
      ),
    );
  }

  Widget _buildAvatarSection(ColorScheme cs, bool isDark) {
    return Center(
      child: GestureDetector(
        onTap: _isUploadingAvatar ? null : _pickAvatar,
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                cs.primary,
                cs.tertiary,
              ],
            ),
          ),
          child: CircleAvatar(
            radius: AppSizes.avatarXLarge / 2,
            backgroundColor: cs.surface,
            child: Stack(
              children: [
                ClipOval(
                  child: AppNetworkImage(
                    imageUrl: _avatarUrl,
                    width: AppSizes.avatarXLarge - 6,
                    height: AppSizes.avatarXLarge - 6,
                    imageType: AppImageType.avatar,
                  ),
                ),
                if (_isUploadingAvatar)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black38,
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        ),
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

  Widget _buildInfoCard(ColorScheme cs, bool isDark) {
    final roleState = ref.read(roleManagerProvider);
    final isSitter = roleState.isSitter;
    final strings = AppLocalization.get(Localizations.localeOf(context).languageCode);

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.outlineVariant),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          AppTextField(
            label: strings[AppLocalization.full_name] ?? 'Full Name',
            controller: _nameController,
            prefixIcon: const Icon(Icons.person_outline),
            validator: _validateName,
            fillColor: isDark ? cs.surfaceContainerHighest : cs.surfaceContainerLow,
          ),
          if (isSitter) ...[
            SizedBox(height: AppSpacing.md),
            AppTextField(
              label: strings[AppLocalization.national_id_number] ?? 'National ID Number',
              controller: _nationalIdController,
              prefixIcon: const Icon(Icons.badge_outlined),
              keyboardType: TextInputType.number,
              fillColor: isDark ? cs.surfaceContainerHighest : cs.surfaceContainerLow,
            ),
          ],
          SizedBox(height: AppSpacing.md),
          AppTextField(
            label: strings[AppLocalization.location] ?? 'Location',
            controller: _locationController,
            prefixIcon: const Icon(Icons.location_on_outlined),
            fillColor: isDark ? cs.surfaceContainerHighest : cs.surfaceContainerLow,
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(ColorScheme cs, bool isDark) {
    final strings = AppLocalization.get(Localizations.localeOf(context).languageCode);
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.outlineVariant),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          AppTextField(
            label: strings[AppLocalization.email] ?? 'Email',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined),
            validator: _validateEmail,
            fillColor: isDark ? cs.surfaceContainerHighest : cs.surfaceContainerLow,
          ),
          if (_emailChanged)
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.xs,
                left: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 14,
                    color: cs.error,
                  ),
                  SizedBox(width: AppSpacing.xxs),
                  Text(
                    'OTP verification required',
                    style: AppTextStyles.caption(color: cs.error),
                  ),
                ],
              ),
            ),
          SizedBox(height: AppSpacing.md),
          AppTextField(
            label: strings[AppLocalization.phone] ?? 'Phone',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            prefixIcon: const Icon(Icons.phone_outlined),
            validator: _validatePhone,
            fillColor: isDark ? cs.surfaceContainerHighest : cs.surfaceContainerLow,
          ),
          if (_phoneChanged)
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.xs,
                left: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 14,
                    color: cs.error,
                  ),
                  SizedBox(width: AppSpacing.xxs),
                  Text(
                    'OTP verification required',
                    style: AppTextStyles.caption(color: cs.error),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(ColorScheme cs, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.button),
          gradient: LinearGradient(
            colors: isDark
                ? [cs.primary, cs.primary.withValues(alpha: 0.8)]
                : [cs.primary, cs.primary.withValues(alpha: 0.7)],
          ),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
          child: _isSaving
              ? const SpinKitDualRing(
                  color: Colors.white,
                  size: 24,
                  lineWidth: 2.5,
                )
              : Text(
                  'Save Changes',
                  style: AppTextStyles.labelLarge(
                    weight: FontWeight.w700,
                    color: cs.onPrimary,
                  ),
                ),
        ),
      ),
    );
  }
}

class _OtpVerificationSheet extends ConsumerStatefulWidget {
  final String otpToken;
  const _OtpVerificationSheet({required this.otpToken});

  @override
  ConsumerState<_OtpVerificationSheet> createState() =>
      _OtpVerificationSheetState();
}

class _OtpVerificationSheetState extends ConsumerState<_OtpVerificationSheet> {
  final _otpController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) return;

    setState(() => _isVerifying = true);
    await ref.read(authProvider.notifier).verifyUpdateOtp(
          otp: otp,
          otpToken: widget.otpToken,
        );

    if (!mounted) return;
    final error = ref.read(authProvider).error;
    if (error != null) {
      context.showErrorSnackBar(error);
      setState(() => _isVerifying = false);
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final strings = AppLocalization.get(Localizations.localeOf(context).languageCode);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.xxxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: AppSpacing.md),
          Icon(
            Icons.shield_outlined,
            size: 40,
            color: cs.primary,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'Verification Required',
            style: AppTextStyles.titleMedium(weight: FontWeight.w700),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'A verification code was sent to your current email',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium(color: context.textSecondary),
          ),
          SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _otpController,
            focusNode: _focusNode,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineMedium(
              weight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintStyle: AppTextStyles.headlineMedium(
                weight: FontWeight.w700,
                color: context.textSecondary.withValues(alpha: 0.3),
              ),
              filled: true,
              fillColor: cs.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
                borderSide: BorderSide(color: cs.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
                borderSide: BorderSide(color: cs.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
                borderSide: BorderSide(color: cs.primary, width: 2),
              ),
            ),
            onChanged: (v) {
              if (v.length == 6) _verify();
            },
            onSubmitted: (_) => _verify(),
          ),
          SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isVerifying ? null : _verify,
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
              child: _isVerifying
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onPrimary,
                      ),
                    )
                  : Text(strings[AppLocalization.verify] ?? 'Verify'),
            ),
          ),
        ],
      ),
    );
  }
}
