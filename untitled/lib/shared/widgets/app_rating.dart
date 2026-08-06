import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/extensions/theme_colors.dart';

class AppRatingBar extends StatelessWidget {
  final double rating;
  final int itemCount;
  final double itemSize;
  final bool allowHalfRating;
  final bool ignoreGestures;
  final Color activeColor;
  final Color inactiveColor;
  final Function(double)? onRatingUpdate;

  const AppRatingBar({
    super.key,
    required this.rating,
    this.itemCount = 5,
    this.itemSize = 20,
    this.allowHalfRating = true,
    this.ignoreGestures = true,
    this.activeColor = AppColors.warning,
    this.inactiveColor = AppColors.skeletonBaseLight,
    this.onRatingUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return RatingBar.builder(
      initialRating: rating,
      minRating: 0,
      direction: Axis.horizontal,
      allowHalfRating: allowHalfRating,
      itemCount: itemCount,
      itemSize: itemSize,
      ignoreGestures: ignoreGestures,
      tapOnlyMode: false,
      updateOnDrag: false,
      glow: false,
      itemBuilder: (context, _) => Icon(
        Icons.star_rounded,
        color: activeColor,
      ),
      onRatingUpdate: onRatingUpdate ?? (_) {},
    );
  }
}

class RatingDisplay extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  final double size;
  final bool showCount;

  const RatingDisplay({
    super.key,
    required this.rating,
    this.reviewCount,
    this.size = 16,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star_rounded,
          size: size,
          color: AppColors.warning,
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: size.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.warning,
          ),
        ),
        if (showCount && reviewCount != null) ...[
          const SizedBox(width: AppSpacing.xxs),
          Text(
            '($reviewCount)',
            style: TextStyle(
              fontSize: (size - 2).sp,
              color: context.textMutedColor,
            ),
          ),
        ],
      ],
    );
  }
}
