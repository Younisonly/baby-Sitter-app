import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/extensions.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/shared/repositories/image_upload_repository.dart';

enum ImageUploadType { avatar, gallery }

class AppImagePicker {
  AppImagePicker._();

  static Future<String?> pickAndUpload({
    required BuildContext context,
    required WidgetRef ref,
    ImageUploadType uploadType = ImageUploadType.gallery,
  }) async {
    final source = await _showPickerSheet(context, ref);
    if (source == null) return null;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (picked == null) return null;

    _showUploadingDialog(context);

    try {
      final repo = ref.read(imageUploadRepositoryProvider);
      final url = uploadType == ImageUploadType.avatar
          ? await repo.uploadAvatar(filePath: picked.path)
          : await repo.uploadImage(filePath: picked.path);
      Navigator.of(context).pop();
      return url;
    } catch (e) {
      Navigator.of(context).pop();
      if (context.mounted) {
        final strings = AppLocalization.get(ref.read(languageProvider).code);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings[AppLocalization.upload_failed] ?? 'Upload failed. Please try again.')),
        );
      }
      return null;
    }
  }

  static Future<ImageSource?> _showPickerSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final strings = AppLocalization.get(ref.read(languageProvider).code);
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.md),
              Text(
                strings['choose_source'] ?? 'Choose Source',
                style: AppTextStyles.titleMedium(weight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: _SourceOption(
                      icon: Icons.camera_alt_rounded,
                      label: strings[AppLocalization.camera] ?? 'Camera',
                      onTap: () => Navigator.pop(ctx, ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _SourceOption(
                      icon: Icons.photo_library_rounded,
                      label: strings[AppLocalization.gallery] ?? 'Gallery',
                      onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showUploadingDialog(BuildContext context) {
    final strings = AppLocalization.get(Localizations.localeOf(context).languageCode);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: AppSpacing.md),
                Text(strings[AppLocalization.uploading] ?? 'Uploading...'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        decoration: BoxDecoration(
          color: context.primaryColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: context.primaryColor.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: AppColors.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: AppTextStyles.labelLarge(
                weight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
