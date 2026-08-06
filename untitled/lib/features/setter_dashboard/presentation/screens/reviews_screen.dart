import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/extensions/extensions.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/network/dio_client.dart';
import 'package:babysitter/core/network/error_handler.dart';
import 'package:babysitter/core/services/base_repository.dart';
import 'package:babysitter/core/services/cache_service.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/shared/models/booking_model.dart';
import 'package:babysitter/shared/widgets/widgets.dart';

final sitterReviewsProvider =
    FutureProvider.autoDispose<List<BookingModel>>((ref) async {
  return BaseRepository.fetchList(
    request: () async {
      final response = await DioClient.dio.get('/sitters/reviews', queryParameters: {
        'per_page': 50,
      });
      final raw = response.data is Map<String, dynamic>
          ? (response.data as Map<String, dynamic>)['data']
          : response.data;
      if (raw is! List) return [];
      return raw.whereType<Map<String, dynamic>>().toList();
    },
    cacheKey: 'sitter_reviews_list',
    fromJson: BookingModel.fromJson,
    cacheDuration: CacheService.shortExpiry,
  );
});

class ReviewsScreen extends ConsumerWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(sitterReviewsProvider);
    final strings = AppLocalization.get(ref.watch(languageProvider).code);

    return Scaffold(
      appBar: AppAppBar(
        title: strings[AppLocalization.reviews] ?? 'Reviews',
      ),
      body: reviewsAsync.when(
        loading: () => const _ReviewsShimmer(),
        error: (err, _) => Center(
          child: AppErrorState(
            title: strings[AppLocalization.something_went_wrong] ?? 'Something went wrong',
            message: ErrorHandler.handle(err).message,
            onRetry: () => ref.invalidate(sitterReviewsProvider),
          ),
        ),
        data: (reviews) {
          if (reviews.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.rate_review_outlined,
                        size: 72.sp, color: context.textMuted),
                    SizedBox(height: AppSpacing.lg),
                    Text(
                      strings[AppLocalization.reviews_empty] ??
                          'No reviews yet',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      strings[AppLocalization.reviews_empty_subtitle] ??
                          'Reviews from completed bookings will appear here.',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: reviews.length,
            separatorBuilder: (_, __) => SizedBox(height: AppSpacing.md),
            itemBuilder: (_, i) => _ReviewCard(
              booking: reviews[i],
              strings: strings,
              onReplied: () => ref.invalidate(sitterReviewsProvider),
            ),
          );
        },
      ),
    );
  }
}

class _ReviewCard extends ConsumerStatefulWidget {
  final BookingModel booking;
  final Map<String, String> strings;
  final VoidCallback onReplied;

  const _ReviewCard({
    required this.booking,
    required this.strings,
    required this.onReplied,
  });

  @override
  ConsumerState<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends ConsumerState<_ReviewCard> {
  bool _isReplying = false;
  bool _isReporting = false;

  Future<void> _submitReply(String text) async {
    setState(() => _isReplying = true);
    try {
      await DioClient.dio.put(
        '/sitters/reviews/${widget.booking.id}/reply',
        data: {'reply': text},
      );
      widget.onReplied();
    } catch (e) {
      if (context.mounted) {
        context.showErrorSnackBar(ErrorHandler.handle(e).message);
      }
    } finally {
      if (mounted) setState(() => _isReplying = false);
    }
  }

  Future<void> _reportReview() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => _ReportDialog(strings: widget.strings),
    );
    if (reason == null) return;

    setState(() => _isReporting = true);
    try {
      await DioClient.dio.post(
        '/sitters/reviews/${widget.booking.id}/report',
        data: {'reason': reason},
      );
      if (context.mounted) {
        context.showSuccessSnackBar(
          widget.strings[AppLocalization.review_reported] ??
              'Review reported',
        );
      }
    } catch (e) {
      if (context.mounted) {
        context.showErrorSnackBar(ErrorHandler.handle(e).message);
      }
    } finally {
      if (mounted) setState(() => _isReporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final customerName = b.customer?.name ?? 'Customer';
    final rating = b.rating ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              0,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20.r,
                  child: Text(
                    customerName.isNotEmpty
                        ? customerName[0].toUpperCase()
                        : '?',
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatDate(b.createdAt),
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: context.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(5, (i) {
                    return Icon(
                      i < rating.round()
                          ? Icons.star
                          : Icons.star_border,
                      size: 16.sp,
                      color: AppColors.warning,
                    );
                  }),
                ),
              ],
            ),
          ),
          if (b.review != null && b.review!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              child: Text(
                b.review!,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: context.textSecondary,
                ),
              ),
            ),
          ],
          if (b.reply != null && b.reply!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.strings[AppLocalization.your_reply] ??
                          'Your reply',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: context.textSecondary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xxs),
                    Text(
                      b.reply!,
                      style: TextStyle(fontSize: 13.sp),
                    ),
                  ],
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.xs,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: b.reply == null || b.reply!.isEmpty
                      ? () => _showReplyDialog()
                      : null,
                  icon: Icon(
                    Icons.reply,
                    size: 16.sp,
                    color: b.reply == null || b.reply!.isEmpty
                        ? AppColors.primary
                        : context.textMuted,
                  ),
                  label: Text(
                    b.reply == null || b.reply!.isEmpty
                        ? (widget.strings[AppLocalization.reply_to_review] ??
                            'Reply')
                        : (widget.strings[AppLocalization.replied] ??
                            'Replied'),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: b.reply == null || b.reply!.isEmpty
                          ? AppColors.primary
                          : context.textMuted,
                    ),
                  ),
                ),
                Spacer(),
                TextButton.icon(
                  onPressed: _isReporting ? null : _reportReview,
                  icon: Icon(
                    Icons.flag_outlined,
                    size: 16.sp,
                    color: context.textMuted,
                  ),
                  label: Text(
                    'Report',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: context.textMuted,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _markHelpful(),
                  icon: Icon(
                    Icons.thumb_up_outlined,
                    size: 16.sp,
                    color: context.textMuted,
                  ),
                  label: Text(
                    '${b.helpfulCount}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: context.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReplyDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          widget.strings[AppLocalization.reply_to_review] ?? 'Reply to Review',
        ),
        content: TextField(
          controller: controller,
          maxLines: 4,
          maxLength: 2000,
          decoration: InputDecoration(
            hintText: widget.strings[AppLocalization.reply_hint] ??
                'Write your reply...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(widget.strings[AppLocalization.cancel] ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: _isReplying
                ? null
                : () {
                    if (controller.text.trim().isNotEmpty) {
                      Navigator.pop(ctx);
                      _submitReply(controller.text.trim());
                    }
                  },
            child: _isReplying
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.strings[AppLocalization.submit] ?? 'Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _markHelpful() async {
    try {
      await DioClient.dio.post(
        '/sitters/reviews/${widget.booking.id}/helpful',
      );
    } catch (_) {}
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

class _ReportDialog extends StatelessWidget {
  final Map<String, String> strings;

  const _ReportDialog({required this.strings});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return AlertDialog(
      title: Text(
        strings[AppLocalization.report_review] ?? 'Report Review',
      ),
      content: TextField(
        controller: controller,
        maxLines: 3,
        maxLength: 500,
        decoration: InputDecoration(
          hintText: strings[AppLocalization.report_reason_hint] ??
              'Why are you reporting this review?',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings[AppLocalization.cancel] ?? 'Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (controller.text.trim().isNotEmpty) {
              Navigator.pop(context, controller.text.trim());
            }
          },
          child: Text(strings[AppLocalization.submit] ?? 'Submit'),
        ),
      ],
    );
  }
}

class _ReviewsShimmer extends StatelessWidget {
  const _ReviewsShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: 3,
      separatorBuilder: (_, __) => SizedBox(height: AppSpacing.md),
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppShimmer(
                  width: 40.w,
                  height: 40.w,
                  borderRadius: AppRadius.full,
                  isCircular: true,
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppShimmer(width: 120.w, height: 14.h, borderRadius: AppRadius.sm),
                      SizedBox(height: AppSpacing.xxs),
                      AppShimmer(width: 80.w, height: 10.h, borderRadius: AppRadius.sm),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(5, (_) => Padding(
                    padding: EdgeInsets.only(left: 2.w),
                    child: AppShimmer(width: 14.w, height: 14.w, borderRadius: AppRadius.sm),
                  )),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            AppShimmer(width: double.infinity, height: 12.h, borderRadius: AppRadius.sm),
            SizedBox(height: AppSpacing.xxs),
            AppShimmer(width: 200.w, height: 12.h, borderRadius: AppRadius.sm),
            SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppShimmer(width: 60.w, height: 10.h, borderRadius: AppRadius.sm),
                SizedBox(width: AppSpacing.sm),
                AppShimmer(width: 60.w, height: 10.h, borderRadius: AppRadius.sm),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
