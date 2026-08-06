import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/extensions.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/network/dio_client.dart';
import 'package:babysitter/core/services/auth_provider.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/features/profile/data/sitter_profile_provider.dart';
import 'package:babysitter/features/sitter_registration/presentation/widgets/step_basic_info.dart';
import 'package:babysitter/features/sitter_registration/presentation/widgets/step_experience.dart';
import 'package:babysitter/features/sitter_registration/presentation/widgets/step_pricing.dart';
import 'package:babysitter/features/sitter_registration/presentation/widgets/step_schedule.dart';
import 'package:babysitter/features/sitter_registration/presentation/widgets/step_bank.dart';
import 'package:babysitter/shared/models/language_provider.dart';
import 'package:babysitter/shared/models/user_model.dart';
import 'package:babysitter/shared/widgets/widgets.dart';

final List<_StepData> _editSteps = [
  _StepData(icon: Icons.person_outline_rounded, key: 'step_reg_basic_info'),
  _StepData(icon: Icons.auto_stories_outlined, key: 'step_reg_certificates'),
  _StepData(icon: Icons.monetization_on_outlined, key: 'step_reg_pricing'),
  _StepData(icon: Icons.calendar_month_rounded, key: 'step_reg_schedule'),
  _StepData(icon: Icons.account_balance_rounded, key: 'step_reg_bank'),
];

class _StepData {
  final IconData icon;
  final String key;
  const _StepData({required this.icon, required this.key});
}

class EditSitterProfileScreen extends ConsumerStatefulWidget {
  const EditSitterProfileScreen({super.key});

  @override
  ConsumerState<EditSitterProfileScreen> createState() => _EditSitterProfileScreenState();
}

class _EditSitterProfileScreenState extends ConsumerState<EditSitterProfileScreen> {
  int _currentStep = 1;
  Map<int, Map<String, dynamic>> _stepData = {};
  Map<int, Map<String, dynamic>> _initialData = {};
  bool _isSubmitting = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initFromProfile());
  }

  void _initFromProfile() {
    final user = ref.read(authProvider).user;
    final profile = user?.babysitterProfile;
    if (profile == null || user == null) return;

    final data = _buildStepData(user, profile);
    _stepData = data;
    _initialData = data.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v)));
    _initialized = true;
    if (mounted) setState(() {});
  }

  Map<int, Map<String, dynamic>> _buildStepData(UserModel user, BabysitterProfile profile) {
    return {
      1: {
        'gender': user.gender ?? '',
        'age': user.age ?? 25,
        'years_experience': profile.yearsExperience,
        'languages': user.languages ?? [],
        'bio': user.bio ?? '',
        'location': user.location ?? '',
        'latitude': user.latitude,
        'longitude': user.longitude,
      },
      2: {
        'certificates': profile.certificates,
        'description': profile.description ?? '',
      },
      3: {
        'hourly_rate': profile.hourlyRate,
        'included_children': profile.includedChildren,
        'extra_child_fee': profile.extraChildFee,
        'absolute_max_children': profile.absoluteMaxChildren,
        'special_needs_rate': profile.specialNeedsRate,
      },
      4: {
        'availability': profile.availability.map((a) => {
          'day_of_week': a.dayOfWeek,
          'day': _dayName(a.dayOfWeek),
          'start_time': a.startTime,
          'end_time': a.endTime,
        }).toList(),
      },
      5: {
        'bank_account': profile.bankAccount,
      },
    };
  }

  String _dayName(int dayOfWeek) {
    const names = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    if (dayOfWeek >= 0 && dayOfWeek < 7) return names[dayOfWeek];
    return 'Monday';
  }

  Map<String, dynamic> _buildChangedFields() {
    final changed = <String, dynamic>{};

    void diff(int step, Map<String, String> mapping) {
      final oldMap = _initialData[step] ?? {};
      final newMap = _stepData[step] ?? {};
      for (final entry in mapping.entries) {
        final oldVal = oldMap[entry.key];
        final newVal = newMap[entry.key];
        if (_deepEquals(oldVal, newVal)) continue;
        changed[entry.value] = newVal;
      }
    }

    diff(1, {
      'gender': 'gender',
      'age': 'age',
      'years_experience': 'years_experience',
      'languages': 'languages',
      'bio': 'bio',
      'location': 'location',
      'latitude': 'latitude',
      'longitude': 'longitude',
    });

    diff(2, {
      'description': 'description',
      'certificates': 'certificates',
    });

    diff(3, {
      'hourly_rate': 'hourly_rate',
      'included_children': 'included_children',
      'extra_child_fee': 'extra_child_fee',
      'absolute_max_children': 'absolute_max_children',
      'special_needs_rate': 'special_needs_rate',
    });

    diff(4, {
      'availability': 'availability',
    });

    diff(5, {
      'bank_account': 'bank_account',
    });

    return changed;
  }

  bool _deepEquals(dynamic a, dynamic b) {
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (int i = 0; i < a.length; i++) {
        if (!_deepEquals(a[i], b[i])) return false;
      }
      return true;
    }
    return a == b;
  }

  Future<void> _handleSave() async {
    final changed = _buildChangedFields();
    if (changed.isEmpty) {
      if (mounted) {
        final s = AppLocalization.get(ref.read(languageProvider).code);
        context.showInfoSnackBar(s[AppLocalization.no_changes_to_save] ?? 'No changes to save');
      }
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await ref.read(sitterProfileUpdateProvider.notifier).update(changed);
    setState(() => _isSubmitting = false);

    if (result != null && mounted) {
      await ref.read(authProvider.notifier).loadUser();
      if (mounted) {
        final s = AppLocalization.get(ref.read(languageProvider).code);
        context.showSuccessSnackBar(s[AppLocalization.profile_updated_successfully] ?? 'Profile updated successfully');
        Navigator.of(context).pop();
      }
    } else if (mounted) {
      final s = AppLocalization.get(ref.read(languageProvider).code);
      context.showErrorSnackBar(s[AppLocalization.failed_to_update_profile] ?? 'Failed to update profile');
    }
  }

  bool _validateStep() {
    final data = _stepData[_currentStep] ?? {};
    switch (_currentStep) {
      case 1:
        if ((data['gender'] as String?)?.isEmpty ?? true) {
          final s = AppLocalization.get(ref.read(languageProvider).code);
          context.showErrorSnackBar(s[AppLocalization.please_select_gender] ?? 'Please select your gender');
          return false;
        }
        break;
      case 3:
        final rate = (data['hourly_rate'] as num?)?.toDouble() ?? 0;
        if (rate <= 0) {
          final s = AppLocalization.get(ref.read(languageProvider).code);
          context.showErrorSnackBar(s[AppLocalization.please_set_hourly_rate] ?? 'Please set your hourly rate');
          return false;
        }
        break;
    }
    return true;
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
      final responseData = response.data['data'] as Map<String, dynamic>;
      return responseData['url'] as String;
    } catch (_) {
      if (mounted) {
        final s = AppLocalization.get(ref.read(languageProvider).code);
        context.showErrorSnackBar(s[AppLocalization.upload_failed_try_again] ?? 'Upload failed. Please try again.');
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final authState = ref.watch(authProvider);

    final isReady = _initialized && authState.user?.babysitterProfile != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings['edit_sitter_profile'] ?? 'Edit Sitter Profile'),
      ),
      body: isReady
          ? Column(
              children: [
                _buildStepIndicator(context, strings),
                Expanded(
                  child: _buildStepContent(strings),
                ),
                _buildBottomBar(strings),
              ],
            )
          : authState.isLoading
              ? const ListShimmer()
              : Center(child: Text(strings[AppLocalization.error_loading_profile] ?? 'Could not load profile data')),
    );
  }

  Widget _buildStepIndicator(BuildContext context, Map<String, String> strings) {
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
            children: List.generate(_editSteps.length * 2 - 1, (index) {
              if (index.isOdd) return _buildConnector(index ~/ 2);
              final stepIndex = index ~/ 2;
              return _buildStepCircle(stepIndex);
            }),
          ),
          SizedBox(height: 4.h),
          Text(
            strings[_editSteps[_currentStep - 1].key] ?? 'Step $_currentStep',
            style: AppTextStyles.labelMedium(weight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int index) {
    final isActive = index + 1 == _currentStep;
    final isCompleted = index + 1 < _currentStep;
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
                : Icon(_editSteps[index].icon, size: 18.sp, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildConnector(int index) {
    final isCompleted = index + 1 < _currentStep;
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

  Widget _buildStepContent(Map<String, String> strings) {
    Widget content;
    switch (_currentStep) {
      case 1:
        content = StepBasicInfo(
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
        content = StepExperience(
          strings: strings,
          data: _stepData[2] ?? {},
          onChanged: (d) => _stepData[2] = d,
          onUploadFile: (fileName) => _uploadCertificateFile(),
        );
      case 3:
        content = StepPricing(
          strings: strings,
          data: _stepData[3] ?? {},
          onChanged: (d) => _stepData[3] = d,
        );
      case 4:
        content = StepSchedule(
          strings: strings,
          data: _stepData[4] ?? {},
          onChanged: (d) => _stepData[4] = d,
        );
      case 5:
        content = StepBank(
          strings: strings,
          data: _stepData[5] ?? {},
          onChanged: (d) => _stepData[5] = d,
        );
      default:
        content = const SizedBox.shrink();
    }
    return content.animate().fadeIn(duration: 300.ms).slideY(begin: 0.05);
  }

  Widget _buildBottomBar(Map<String, String> strings) {
    final isLastStep = _currentStep == 5;
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
          if (_currentStep > 1)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                ),
                child: Text(strings['step_back'] ?? 'Back'),
              ),
            ),
          if (_currentStep > 1) const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: _isSubmitting
                  ? null
                  : () {
                      if (isLastStep) {
                        _handleSave();
                      } else if (_validateStep()) {
                        setState(() => _currentStep++);
                      }
                    },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
              ),
              child: _isSubmitting && isLastStep
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      isLastStep
                          ? (strings['sitter_profile_save'] ?? 'Save Changes')
                          : (strings['step_next'] ?? 'Continue'),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
