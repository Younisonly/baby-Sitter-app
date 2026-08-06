import 'package:flutter/material.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/extensions.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/shared/widgets/app_button.dart';
import 'package:babysitter/shared/widgets/app_text_field.dart';
import 'package:babysitter/shared/widgets/app_dialog_bottom_sheet.dart';

class RatingBottomSheetData {
  final double initialRating;
  final String? initialReview;
  final bool isEdit;

  const RatingBottomSheetData({
    this.initialRating = 5.0,
    this.initialReview,
    this.isEdit = false,
  });
}

Future<({double rating, String review})?> showRatingBottomSheet(
  BuildContext context, {
  RatingBottomSheetData? data,
}) {
  final strings = AppLocalization.get(
    Localizations.localeOf(context).languageCode,
  );

  final ratingData = data ?? const RatingBottomSheetData();

  return showAppModalSheet<({double rating, String review})>(
    context,
    child: _RatingBottomSheetContent(
      initialRating: ratingData.initialRating,
      initialReview: ratingData.initialReview,
      isEdit: ratingData.isEdit,
      strings: strings,
    ),
  );
}

class _RatingBottomSheetContent extends StatefulWidget {
  final double initialRating;
  final String? initialReview;
  final bool isEdit;
  final Map<String, String> strings;

  const _RatingBottomSheetContent({
    required this.initialRating,
    this.initialReview,
    required this.isEdit,
    required this.strings,
  });

  @override
  State<_RatingBottomSheetContent> createState() =>
      _RatingBottomSheetContentState();
}

class _RatingBottomSheetContentState extends State<_RatingBottomSheetContent>
    with SingleTickerProviderStateMixin {
  late double _rating;
  late TextEditingController _reviewController;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
    _reviewController = TextEditingController(text: widget.initialReview ?? '');

    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    _animController.forward();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(context),
            _buildHeader(context, isDark),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                child: Column(
                  children: [
                    _buildRatingStars(context),
                    const SizedBox(height: AppSpacing.lg),
                    _buildReviewField(context),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSubmitButton(context),
                    SizedBox(height: MediaQuery.of(context).padding.bottom + AppSpacing.sm),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: context.textMutedColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.primaryDark,
                  AppColors.primary.withValues(alpha: 0.8),
                ]
              : [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.3 : 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.isEdit ? Icons.star_rounded : Icons.star_rounded,
              size: 28,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isEdit
                      ? (widget.strings['update_review'] ?? 'Update Review')
                      : (widget.strings['leave_review'] ?? 'Leave a Review'),
                  style: AppTextStyles.titleMedium(
                    color: Colors.white,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.isEdit
                      ? (widget.strings['update_review_subtitle'] ??
                          'Tap a star to update your rating')
                      : (widget.strings['rate_experience'] ??
                          'Rate your experience'),
                  style: AppTextStyles.bodySmall(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingStars(BuildContext context) {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            _ratingLabel(context),
            key: ValueKey('label_$_rating'),
            style: AppTextStyles.titleLarge(
              weight: FontWeight.bold,
              color: context.textPrimaryColor,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _AnimatedStarRating(
          rating: _rating,
          onChanged: (v) => setState(() => _rating = v),
          size: 44,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _ratingDescription(_rating, context),
          style: AppTextStyles.bodySmall(
            color: context.textMutedColor,
          ),
        ),
      ],
    );
  }

  String _ratingLabel(BuildContext context) {
    final i = _rating.round();
    if (i == 5) return _rating >= 4.5 ? 'Excellent!' : 'Very Good!';
    if (i == 4) return 'Good';
    if (i == 3) return 'Average';
    if (i == 2) return 'Below Average';
    return 'Poor';
  }

  String _ratingDescription(double rating, BuildContext context) {
    final i = rating.round();
    if (i == 5) return 'You had a great experience with this sitter';
    if (i == 4) return 'You had a positive experience overall';
    if (i == 3) return 'It was an okay experience';
    if (i == 2) return 'There were some issues with this booking';
    return 'You were not satisfied with this experience';
  }

  Widget _buildReviewField(BuildContext context) {
    return AppTextField(
      controller: _reviewController,
      label: widget.strings['review'] ?? 'Your review',
      hint: widget.strings['review_hint'] ?? 'Share your experience...',
      maxLines: 4,
      maxLength: 500,
      showCounter: true,
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AppButton(
        text: widget.isEdit
            ? (widget.strings['update_review_btn'] ?? 'Update Review')
            : (widget.strings['submit_review'] ?? 'Submit Review'),
        onPressed: () {
          final reviewText = _reviewController.text.trim();
          Navigator.pop(context, (rating: _rating, review: reviewText));
        },
        variant: AppButtonVariant.filled,
        prefixIcon: Icon(
          widget.isEdit ? Icons.update_rounded : Icons.send_rounded,
          size: 18,
        ),
      ),
    );
  }
}

class _AnimatedStarRating extends StatelessWidget {
  final double rating;
  final ValueChanged<double> onChanged;
  final double size;

  const _AnimatedStarRating({
    required this.rating,
    required this.onChanged,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final starValue = i + 1;
        final filled = starValue <= rating;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: size * 0.1),
          child: GestureDetector(
            onTap: () => onChanged(starValue.toDouble()),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled
                    ? AppColors.warning.withValues(alpha: 0.1)
                    : Colors.transparent,
              ),
              padding: EdgeInsets.all(size * 0.15),
              child: AnimatedScale(
                scale: filled ? 1.0 : 0.9,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: size,
                  color: filled
                      ? AppColors.warning
                      : context.textMutedColor.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
