import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';

class SitterDashboardShimmer extends StatelessWidget {
  const SitterDashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.skeletonBaseDark : AppColors.skeletonBaseLight;
    final highlight = isDark ? AppColors.skeletonHighlightDark : AppColors.skeletonHighlightLight;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _shimmerBlock(height: 28, width: 200),
            const SizedBox(height: AppSpacing.xs),
            _shimmerBlock(height: 16, width: 140),
            const SizedBox(height: AppSpacing.xl),
            _shimmerBlock(height: 22, width: 160),
            const SizedBox(height: AppSpacing.md),
            _shimmerTile(),
            const SizedBox(height: AppSpacing.sm),
            _shimmerTile(),
            const SizedBox(height: AppSpacing.sm),
            _shimmerTile(),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(child: _shimmerCard()),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _shimmerCard()),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(child: _shimmerCard()),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _shimmerCard()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBlock({double? height, double? width}) {
    return Container(
      height: height ?? 20,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        color: Colors.white,
      ),
    );
  }

  Widget _shimmerCard() {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        color: Colors.white,
      ),
    );
  }

  Widget _shimmerTile() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        color: Colors.white,
      ),
    );
  }
}
