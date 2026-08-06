import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/extensions/theme_colors.dart';

class AppShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double? borderRadius;
  final bool isCircular;

  const AppShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.isCircular = false,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.isDark ? AppColors.skeletonBaseDark : AppColors.skeletonBaseLight,
      highlightColor: context.isDark ? AppColors.skeletonHighlightDark : AppColors.skeletonHighlightLight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: context.isDark ? AppColors.skeletonBaseDark : AppColors.skeletonBaseLight,
          borderRadius: isCircular
              ? null
              : BorderRadius.circular(borderRadius ?? AppRadius.sm),
          shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
        ),
      ),
    );
  }
}

class SitterCardShimmer extends StatelessWidget {
  final double width;

  const SitterCardShimmer({super.key, this.width = 230});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.isDark ? AppColors.skeletonBaseDark : AppColors.skeletonBaseLight,
      highlightColor: context.isDark ? AppColors.skeletonHighlightDark : AppColors.skeletonHighlightLight,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: context.isDark ? AppColors.skeletonBaseDark : AppColors.skeletonBaseLight,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 146,
              decoration: BoxDecoration(
                color: context.isDark ? AppColors.skeletonBaseDark : AppColors.skeletonBaseLight,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: 120,
                    decoration: BoxDecoration(
                      color: context.isDark ? AppColors.skeletonBaseDark : AppColors.skeletonBaseLight,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
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

class ListShimmer extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const ListShimmer({
    super.key,
    this.itemCount = 6,
    this.itemHeight = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.isDark ? AppColors.skeletonBaseDark : AppColors.skeletonBaseLight,
      highlightColor: context.isDark ? AppColors.skeletonHighlightDark : AppColors.skeletonHighlightLight,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Container(
            height: itemHeight,
            decoration: BoxDecoration(
              color: context.isDark ? AppColors.skeletonBaseDark : AppColors.skeletonBaseLight,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ),
        ),
      ),
    );
  }
}

class DetailsShimmer extends StatelessWidget {
  const DetailsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.isDark ? AppColors.skeletonBaseDark : AppColors.skeletonBaseLight,
      highlightColor: context.isDark ? AppColors.skeletonHighlightDark : AppColors.skeletonHighlightLight,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 300,
              color: context.isDark ? AppColors.skeletonBaseDark : AppColors.skeletonBaseLight,
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 24,
                    width: 200,
                    decoration: BoxDecoration(
                      color: context.isDark ? AppColors.skeletonBaseDark : AppColors.skeletonBaseLight,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    height: 16,
                    width: 140,
                    decoration: BoxDecoration(
                      color: context.isDark ? AppColors.skeletonBaseDark : AppColors.skeletonBaseLight,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      _infoChip(context, 60),
                      const SizedBox(width: AppSpacing.sm),
                      _infoChip(context, 80),
                      const SizedBox(width: AppSpacing.sm),
                      _infoChip(context, 70),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: context.isDark ? AppColors.skeletonBaseDark : AppColors.skeletonBaseLight,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: context.isDark ? AppColors.skeletonBaseDark : AppColors.skeletonBaseLight,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    height: 14,
                    width: 160,
                    decoration: BoxDecoration(
                      color: context.isDark ? AppColors.skeletonBaseDark : AppColors.skeletonBaseLight,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(BuildContext context, double width) {
    return Container(
      height: 32,
      width: width,
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.skeletonBaseDark : AppColors.skeletonBaseLight,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
    );
  }
}

class BookingCardShimmer extends StatelessWidget {
  const BookingCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.isDark ? AppColors.skeletonBaseDark : AppColors.skeletonBaseLight,
      highlightColor: context.isDark ? AppColors.skeletonHighlightDark : AppColors.skeletonHighlightLight,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.isDark ? AppColors.skeletonBaseDark : AppColors.skeletonBaseLight,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: context.isDark ? AppColors.skeletonBaseDark : AppColors.skeletonBaseLight,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: context.isDark ? AppColors.skeletonBaseDark : AppColors.skeletonBaseLight,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    height: 12,
                    width: 120,
                    decoration: BoxDecoration(
                      color: context.isDark ? AppColors.skeletonBaseDark : AppColors.skeletonBaseLight,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
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
