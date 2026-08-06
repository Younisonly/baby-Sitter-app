import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_shadows.dart';
import 'package:babysitter/core/constants/app_sizes.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/extensions.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/network/error_handler.dart';
import 'package:babysitter/core/services/app_provider.dart';
import 'package:babysitter/core/services/auth_provider.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/shared/widgets/widgets.dart';

class SitterCard extends ConsumerWidget {
  final String id;
  final String name;
  final double rating;
  final int reviews;
  final double hourlyRate;
  final int experience;
  final String distance;
  final String? imageUrl;
  final bool isFavorite;
  final List<String> categories;
  final VoidCallback onTap;
  final VoidCallback? onBookTap;
  final bool isCompact;

  const SitterCard({
    super.key,
    required this.id,
    required this.name,
    required this.rating,
    required this.reviews,
    required this.hourlyRate,
    required this.experience,
    required this.distance,
    this.imageUrl,
    this.isFavorite = false,
    this.categories = const [],
    required this.onTap,
    this.onBookTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isCompact) return _buildCompactCard(context, ref);
    return _buildExpandedCard(context, ref);
  }

  Widget _buildExpandedCard(BuildContext context, WidgetRef ref) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280.w,
        margin: EdgeInsets.only(right: AppSpacing.md),
        decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                GestureDetector(
                  onTap: AppImagePreview.canPreview(imageUrl)
                      ? () => AppImagePreview.show(context, imageUrl, name: name)
                      : null,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppRadius.lg)),
                    child: AppNetworkImage(
                      imageUrl: imageUrl,
                      width: double.infinity,
                      height: 160.h,
                      placeholder: Container(
                          height: 160.h,
                          decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                  colors: AppColors.primaryGradient))),
                    ),
                  ),
                ),
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: GestureDetector(
                    onTap: () {
                      if (!ref.read(authProvider).isAuthenticated) {
                        showLoginSheet(context, message: strings['login_to_favorite'] ?? 'Login to follow babysitters');
                        return;
                      }
                      ref.read(appStateProvider.notifier).toggleFavorite(id).then((_) {
                        if (!context.mounted) return;
                        final isFav = ref.read(appStateProvider).favoriteIds.contains(id);
                        AppSnackbar.success(context, isFav ? (strings[AppLocalization.added_to_favorites] ?? 'Followed') : (strings[AppLocalization.removed_from_favorites] ?? 'Unfollowed'));
                      }).catchError((e) {
                        if (!context.mounted) return;
                        AppSnackbar.error(context, ErrorHandler.handle(e).message);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                          color: context.cardColor, shape: BoxShape.circle),
                      child: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: AppSizes.iconSize20,
                          color: isFavorite
                              ? AppColors.error
                              : context.textSecondary),
                    ),
                  ),
                ),
                Positioned(
                  bottom: AppSpacing.sm,
                  left: AppSpacing.sm,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                    decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(AppRadius.full)),
                    child: Text('Available',
                        style: AppTextStyles.labelSmall(
                            color: AppColors.white, weight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: Text(name,
                              style: AppTextStyles.titleMedium(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs, vertical: 2),
                        decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.sm)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded,
                                size: 14.sp, color: AppColors.accent),
                            const SizedBox(width: 2),
                            Text(rating.toStringAsFixed(1),
                                style: AppTextStyles.labelSmall(
                                    color: AppColors.accent,
                                    weight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      _InfoChip(
                          icon: Icons.location_on_outlined, text: distance),
                      SizedBox(width: AppSpacing.sm),
                      _InfoChip(
                          icon: Icons.work_outline, text: '$experience yrs'),
                    ],
                  ),
                  SizedBox(height: AppSpacing.sm),
                  if (categories.isNotEmpty)
                    Wrap(
                        spacing: AppSpacing.xxs,
                        runSpacing: AppSpacing.xxs,
                        children: categories
                            .take(2)
                            .map((c) =>
                                AppChip(label: c, isSelected: false))
                            .toList()),
                  SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('﷼${hourlyRate.toStringAsFixed(0)}',
                              style: AppTextStyles.titleLarge(
                                  weight: FontWeight.bold)),
                          Text('/hr', style: AppTextStyles.caption()),
                        ],
                      ),
                      GestureDetector(
                        onTap: onBookTap,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  colors: AppColors.primaryGradient),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full)),
                          child: Text('Book',
                              style: AppTextStyles.labelMedium(
                                  color: AppColors.white,
                                  weight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context, WidgetRef ref) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 80),
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.card),
          child: Row(
            children: [
              GestureDetector(
                onTap: AppImagePreview.canPreview(imageUrl)
                    ? () => AppImagePreview.show(context, imageUrl, name: name)
                    : null,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: AppNetworkImage(
                    imageUrl: imageUrl,
                    width: 72.w,
                    height: 72.w,
                    placeholder: Container(
                      width: 72.w,
                      height: 72.w,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: AppColors.primaryGradient),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(Icons.person,
                          size: 28.sp, color: AppColors.white),
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(name,
                            style: AppTextStyles.titleMedium(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      SizedBox(width: AppSpacing.xs),
                      GestureDetector(
                        onTap: () {
                          if (!ref.read(authProvider).isAuthenticated) {
                            showLoginSheet(context, message: strings['login_to_favorite'] ?? 'Login to follow babysitters');
                            return;
                          }
                          ref.read(appStateProvider.notifier).toggleFavorite(id).then((_) {
                            if (!context.mounted) return;
                            final isFav = ref.read(appStateProvider).favoriteIds.contains(id);
                            AppSnackbar.success(context, isFav ? (strings[AppLocalization.added_to_favorites] ?? 'Followed') : (strings[AppLocalization.removed_from_favorites] ?? 'Unfollowed'));
                          }).catchError((e) {
                            if (!context.mounted) return;
                            AppSnackbar.error(context, ErrorHandler.handle(e).message);
                          });
                        },
                        child: Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 18.sp,
                            color: isFavorite
                                ? AppColors.error
                                : AppColors.primary),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.xxs),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded,
                                size: 11.sp, color: AppColors.accent),
                            SizedBox(width: 2),
                            Text(rating.toStringAsFixed(1),
                                style: AppTextStyles.caption(
                                    color: AppColors.accent,
                                    weight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      SizedBox(width: AppSpacing.xs),
                      Text('($reviews)', style: AppTextStyles.caption()),
                    ],
                  ),
                  SizedBox(height: AppSpacing.xxs),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 12.sp, color: context.textMuted),
                      SizedBox(width: 2),
                      Flexible(
                        child: Text(distance,
                            style: AppTextStyles.bodySmall(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Icon(Icons.work_outline,
                          size: 12.sp, color: context.textMuted),
                      SizedBox(width: 2),
                      Flexible(
                        child: Text('$experience yrs',
                            style: AppTextStyles.bodySmall(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    '﷼${hourlyRate.toStringAsFixed(0)}/hr',
                    style: AppTextStyles.titleSmall(
                        color: AppColors.primary, weight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13.sp, color: context.textMuted),
        SizedBox(width: 2),
        Text(text, style: AppTextStyles.bodySmall(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
