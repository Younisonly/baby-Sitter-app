import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/extensions.dart';
import 'package:babysitter/core/extensions/theme_colors.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/network/dio_client.dart';
import 'package:babysitter/core/routing/app_routes.dart';
import 'package:babysitter/core/services/auth_provider.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/features/sitter_registration/data/sitter_registration_provider.dart';
import 'package:babysitter/features/sitter_registration/presentation/widgets/step_basic_info.dart';
import 'package:babysitter/features/sitter_registration/presentation/widgets/step_experience.dart';
import 'package:babysitter/features/sitter_registration/presentation/widgets/step_pricing.dart';
import 'package:babysitter/features/sitter_registration/presentation/widgets/step_schedule.dart';
import 'package:babysitter/features/sitter_registration/presentation/widgets/step_bank.dart';
import 'package:babysitter/features/sitter_registration/presentation/widgets/step_review.dart';
import 'package:babysitter/shared/models/language_provider.dart';
import 'package:babysitter/shared/models/user_model.dart';

final List<_StepData> _registrationSteps = [
  _StepData(icon: Icons.person_outline_rounded, key: 'step_reg_basic_info'),
  _StepData(icon: Icons.auto_stories_outlined, key: 'step_reg_certificates'),
  _StepData(icon: Icons.monetization_on_outlined, key: 'step_reg_pricing'),
  _StepData(icon: Icons.calendar_month_rounded, key: 'step_reg_schedule'),
  _StepData(icon: Icons.account_balance_rounded, key: 'step_reg_bank'),
  _StepData(icon: Icons.receipt_long_rounded, key: 'step_reg_review'),
];

class _StepData {
  final IconData icon;
  final String key;
  const _StepData({required this.icon, required this.key});
}

class RegistrationWizardScreen extends ConsumerStatefulWidget {
  const RegistrationWizardScreen({super.key});

  @override
  ConsumerState<RegistrationWizardScreen> createState() => _RegistrationWizardScreenState();
}

class _RegistrationWizardScreenState extends ConsumerState<RegistrationWizardScreen> {
  final _pageController = PageController();
  bool _initialized = false;
  Map<int, Map<String, dynamic>> _stepData = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final notifier = ref.read(sitterRegistrationProvider.notifier);
    await notifier.loadStatus();
    if (!mounted) return;

    final state = ref.read(sitterRegistrationProvider);
    if (state.registrationStatus == RegistrationStatus.draft) {
      final resume = await _showResumeDialog(context);
      if (!mounted) return;
      if (resume == true) {
        _syncAllFromProvider();
      } else if (resume == false) {
        await notifier.discardDraft();
        if (!mounted) return;
        await notifier.startDraft();
        if (mounted) _syncAllFromProvider();
      }
    } else {
      _syncAllFromProvider();
    }
  }

  Future<bool?> _showResumeDialog(BuildContext context) {
    final s = AppLocalization.get(ref.read(languageProvider).code);
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.info_outline_rounded, size: 48, color: AppColors.warning),
        title: Text(s['draft_found'] ?? 'Existing Draft Found'),
        content: Text(
          s['draft_found_body'] ?? 'You have an incomplete registration. Would you like to continue where you left off or start fresh?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s['continue_draft'] ?? 'Continue'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s['start_fresh'] ?? 'Start Fresh'),
          ),
        ],
      ),
    );
  }

  void _syncAllFromProvider() {
    final state = ref.read(sitterRegistrationProvider);
    _stepData = _buildStepDataFromState(state);
    _initialized = true;
    if (mounted) setState(() {});
  }

  Map<int, Map<String, dynamic>> _buildStepDataFromState(SitterRegistrationState s) {
    return {
      1: {
        'gender': s.gender ?? '',
        'age': s.age ?? 25,
        'years_experience': s.yearsExperience,
        'languages': s.languages ?? [],
        'bio': s.bio ?? '',
        'location': s.location ?? '',
        'latitude': s.latitude,
        'longitude': s.longitude,
      },
      2: {
        'certificates': s.certificates,
        'description': s.description ?? '',
      },
      3: {
        'hourly_rate': s.hourlyRate,
        'included_children': s.includedChildren,
        'extra_child_fee': s.extraChildFee,
        'absolute_max_children': s.absoluteMaxChildren,
        'special_needs_rate': s.specialNeedsRate,
      },
      4: {
        'availability': s.availability.map((a) => {
          'day_of_week': a.dayOfWeek,
          'day': _dayName(a.dayOfWeek),
          'start_time': a.startTime,
          'end_time': a.endTime,
        }).toList(),
      },
      5: {
        'bank_account': s.bankAccount,
      },
    };
  }

  String _dayName(int dayOfWeek) {
    const names = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    if (dayOfWeek >= 0 && dayOfWeek < 7) return names[dayOfWeek];
    return 'Monday';
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final state = ref.watch(sitterRegistrationProvider);

    if (!_initialized && state.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(strings['become_sitter'] ?? 'Become a Sitter')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final step = state.currentStep.clamp(1, 6);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings['become_sitter'] ?? 'Become a Sitter'),
      ),
      body: Column(
        children: [
          _buildStepIndicator(context, step, strings),
          if (state.error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
              child: Text(
                state.error ?? 'Please check your connection and try again',
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13),
              ),
            ),
          Expanded(
            child: _buildStepContent(state, strings),
          ),
          _buildBottomBar(context, state, strings),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(BuildContext context, int step, Map<String, String> strings) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(bottom: BorderSide(color: context.dividerColor.withValues(alpha: 0.3))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: List.generate(_registrationSteps.length * 2 - 1, (index) {
              if (index.isOdd) return _buildConnector(context, index ~/ 2, step);
              final stepIndex = index ~/ 2;
              return _buildStepCircle(context, stepIndex, step, strings);
            }),
          ),
          SizedBox(height: 4.h),
          Text(
            strings[_registrationSteps[step - 1].key] ?? 'Step $step',
            style: AppTextStyles.labelMedium(weight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCircle(BuildContext context, int index, int currentStep, Map<String, String> strings) {
    final isActive = index + 1 == currentStep;
    final isCompleted = index + 1 < currentStep;
    final color = isCompleted || isActive ? AppColors.primary : context.textMutedColor.withValues(alpha: 0.4);

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.primary
                  : isActive
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: color,
                width: isActive ? 2 : 1.5,
              ),
            ),
            child: isCompleted
                ? Icon(Icons.check_rounded, size: 18.sp, color: AppColors.white)
                : Icon(_registrationSteps[index].icon, size: 18.sp, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildConnector(BuildContext context, int index, int currentStep) {
    final isCompleted = index + 1 < currentStep;
    return Container(
      width: 24.w,
      height: 2,
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.primary
            : context.dividerColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(1),
      ),
      margin: EdgeInsets.only(bottom: 18.h),
    );
  }

  Widget _buildStepContent(SitterRegistrationState state, Map<String, String> strings) {
    switch (state.currentStep) {
      case 1:
        return StepBasicInfo(
          strings: strings,
          data: _stepData[1] ?? {},
          availableLanguages: ref.watch(languagesProvider).when(
            data: (langs) => langs.map((l) => l.name).toList(),
            loading: () => const [],
            error: (_, __) => const [],
          ),
          onChanged: (d) => _stepData[1] = d,
        );
      case 2:
        return StepExperience(
          strings: strings,
          data: _stepData[2] ?? {},
          onChanged: (d) => _stepData[2] = d,
          onUploadFile: (fileName) => _uploadCertificateFile(),
        );
      case 3:
        return StepPricing(
          strings: strings,
          data: _stepData[3] ?? {},
          onChanged: (d) => _stepData[3] = d,
        );
      case 4:
        return StepSchedule(
          strings: strings,
          data: _stepData[4] ?? {},
          onChanged: (d) => _stepData[4] = d,
        );
      case 5:
        return StepBank(
          strings: strings,
          data: _stepData[5] ?? {},
          onChanged: (d) => _stepData[5] = d,
        );
      case 6:
        return StepReview(
          strings: strings,
          data: _mergedData(),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Map<String, dynamic> _mergedData() {
    final merged = <String, dynamic>{};
    for (final entry in _stepData.entries) {
      merged.addAll(entry.value);
    }
    return merged;
  }

  bool _validateStep(int step, Map<String, String> strings) {
    final data = _stepData[step] ?? {};
    String? error;

    switch (step) {
      case 1:
        if ((data['gender'] as String?)?.isEmpty ?? true) {
          error = strings['please_select_gender'] ?? 'Please select your gender';
        }
        break;
      case 2:
        break;
      case 3:
        final rate = (data['hourly_rate'] as num?)?.toDouble() ?? 0;
        if (rate <= 0) {
          error = strings['please_set_hourly_rate'] ?? 'Please set your hourly rate';
        }
        break;
    }

    if (error != null) {
      ref.read(sitterRegistrationProvider.notifier).setError(error);
      return false;
    }
    return true;
  }

  Widget _buildBottomBar(BuildContext context, SitterRegistrationState state, Map<String, String> strings) {
    final isReviewStep = state.currentStep == 6;
    final isSubmitting = state.isSubmitting;

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(top: BorderSide(color: context.dividerColor.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          if (state.currentStep > 1)
            Expanded(
              child: OutlinedButton(
                onPressed: state.isLoading ? null : () => _handleBack(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                ),
                child: Text(strings['step_back'] ?? 'Back'),
              ),
            ),
          if (state.currentStep > 1) const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: (isSubmitting || state.isLoading)
                  ? null
                  : () => _handleNext(state),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      isReviewStep
                          ? (strings['submit_registration'] ?? 'Submit for Review')
                          : (strings['step_next'] ?? 'Continue'),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleBack() {
    final st = ref.read(sitterRegistrationProvider);
    if (st.currentStep > 1) {
      ref.read(sitterRegistrationProvider.notifier).previousStep();
    }
  }

  Future<void> _handleNext(SitterRegistrationState state) async {
    if (!_validateStep(state.currentStep, AppLocalization.get(ref.read(languageProvider).code))) {
      return;
    }

    if (!state.isDraftInitialized) {
      final success = await ref.read(sitterRegistrationProvider.notifier).startDraft();
      if (success && mounted) _syncAllFromProvider();
      return;
    }

    if (state.currentStep < 6) {
      final notifier = ref.read(sitterRegistrationProvider.notifier);
      notifier.updateStepFromData(state.currentStep, _stepData[state.currentStep] ?? {});
      final saved = await notifier.saveCurrentStep();
      if (saved && mounted) {
        _syncAllFromProvider();
      }
    } else {
      final submitted = await ref.read(sitterRegistrationProvider.notifier).submit();
      if (submitted && mounted) {
        await ref.read(authProvider.notifier).loadUser();
        if (mounted) _showSuccessDialog(context);
      }
    }
  }

  void _showSuccessDialog(BuildContext context) {
    final strings = AppLocalization.get(ref.read(languageProvider).code);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: AppColors.success, size: 64),
        title: Text(strings['registration_submitted'] ?? 'Registration Submitted!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings['registration_submitted_body'] ??
                  'Your application has been submitted for review.',
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(Icons.admin_panel_settings_outlined, size: 20, color: AppColors.warning),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    strings['pending_admin_approval'] ??
                        'Your profile will appear in search results once an admin approves it.',
                    style: AppTextStyles.bodyMedium(
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go(AppRoutes.home);
            },
            child: Text(strings['done'] ?? 'Done'),
          ),
        ],
      ),
    );
  }

  Future<String?> _uploadCertificateFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );
      if (result == null || result.files.isEmpty) return null;

      final file = result.files.first;
      final path = file.path;
      if (path == null) return null;

      final dio = DioClient.dio;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(path, filename: file.name),
      });
      final response = await dio.post('/uploads/certificate', data: formData);
      final data = response.data['data'] as Map<String, dynamic>;
      return data['url'] as String;
    } catch (_) {
      if (mounted) {
        final errorStrings = AppLocalization.get(ref.read(languageProvider).code);
        context.showErrorSnackBar(errorStrings[AppLocalization.upload_failed_try_again] ?? 'Upload failed. Please try again.');
      }
      return null;
    }
  }
}