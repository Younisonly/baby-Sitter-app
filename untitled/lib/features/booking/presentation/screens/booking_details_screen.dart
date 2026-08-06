import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/theme_colors.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/features/booking/data/booking_helpers.dart';
import 'package:babysitter/features/booking/data/booking_provider.dart';
import 'package:babysitter/features/booking/data/booking_repository.dart';
import 'package:babysitter/shared/models/booking_model.dart';
import 'package:babysitter/core/network/error_handler.dart';
import 'package:babysitter/core/services/auth_provider.dart';
import 'package:babysitter/shared/models/user_model.dart';
import 'package:babysitter/core/utils/time_formatter.dart';
import 'package:babysitter/shared/widgets/widgets.dart';


class BookingDetailsScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const BookingDetailsScreen({super.key, required this.bookingId});

  @override
  ConsumerState<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends ConsumerState<BookingDetailsScreen> {
  BookingModel? _cachedBooking;
  bool _hasShownWelcome = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.invalidate(bookingDetailProvider(widget.bookingId));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasShownWelcome) {
        _hasShownWelcome = true;
        final pending = ref.read(pendingSessionSnackProvider);
        if (pending == 'session_ended') {
          final strings = AppLocalization.get(ref.read(languageProvider).code);
          AppSnackbar.success(
            context,
            strings['session_ended_success'] ?? 'Session completed successfully!',
          );
          ref.read(pendingSessionSnackProvider.notifier).state = null;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final bookingAsync = ref.watch(bookingDetailProvider(widget.bookingId));

    return Scaffold(
      appBar: AppAppBar(
        titleWidget: Consumer(
          builder: (context, ref, _) {
            final booking = ref.watch(bookingDetailProvider(widget.bookingId)).valueOrNull;
            final isActive = booking?.isSessionActive ?? false;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(strings['booking_details'] ?? 'Booking Details'),
                if (isActive) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    strings['active_session_banner'] ?? 'Active',
                    style: AppTextStyles.bodySmall(
                      color: AppColors.success,
                      weight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        showBackButton: true,
      ),
      body: bookingAsync.when(
        loading: () {
          if (_cachedBooking != null) {
            return _BookingDetailsContent(booking: _cachedBooking!);
          }
          return const Center(child: CircularProgressIndicator());
        },
        error: (err, stack) {
          if (_cachedBooking != null) {
            return _BookingDetailsContent(booking: _cachedBooking!);
          }
          final errorMsg = ErrorHandler.handle(err).message;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.errorColor.withValues(alpha: 0.08),
                    ),
                    child: Icon(Icons.cloud_off_rounded, size: 44, color: context.errorColor),
                  ),
                  const SizedBox(height: AppSpacing.lg + 4),
                  Text(
                    strings['load_error_title'] ?? 'Something went wrong',
                    style: AppTextStyles.headlineMedium(color: context.textPrimaryColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    errorMsg,
                    style: AppTextStyles.bodyMedium(color: context.textSecondaryColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    text: strings['retry'] ?? 'Try Again',
                    onPressed: () {
                      ref.invalidate(bookingDetailProvider(widget.bookingId));
                    },
                    variant: AppButtonVariant.outlined,
                    prefixIcon: const Icon(Icons.refresh_rounded, size: 18),
                  ),
                ],
              ),
            ),
          );
        },
        data: (booking) {
          _cachedBooking = booking;
          return _BookingDetailsContent(booking: booking);
        },
      ),
    );
  }
}

class _BookingDetailsContent extends ConsumerWidget {
  final BookingModel booking;
  const _BookingDetailsContent({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final locale = ref.watch(languageProvider).code;
    final currentUser = ref.watch(authProvider).user;
    final isSitterRole = currentUser?.id == booking.sitterId;
    final isCustomerRole = currentUser?.id == booking.customerId;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusHeader(booking: booking),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusTimeline(booking: booking),
                const SizedBox(height: AppSpacing.lg),

                if (isSitterRole) ...[
                  _SectionCard(
                    title: strings['parent'] ?? 'Parent',
                    child: booking.customer != null
                        ? _ProviderInfoCard(user: booking.customer!, onTap: null)
                        : _InfoUnavailable(label: strings['parent_info_unavailable'] ?? 'Parent info unavailable'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ] else if (isCustomerRole) ...[
                  _SectionCard(
                    title: strings['sitter_label'] ?? 'Sitter',
                    child: booking.sitter != null
                        ? _ProviderInfoCard(
                            user: booking.sitter!,
                            onTap: () => context.push('/sitter/${booking.sitter!.id}'),
                          )
                        : _InfoUnavailable(label: strings['sitter_info_unavailable'] ?? 'Sitter info unavailable'),
                  ),
                  if (booking.isSessionActive && booking.latestLocation != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _LocationCard(booking: booking),
                  ],
                  const SizedBox(height: AppSpacing.md),
                ] else if (booking.sitter != null) ...[
                  _SectionCard(
                    title: strings['sitter_label'] ?? 'Sitter',
                    child: _ProviderInfoCard(
                      user: booking.sitter!,
                      onTap: () => context.push('/sitter/${booking.sitter!.id}'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                _SectionCard(
                  title: strings['schedule'] ?? 'Schedule',
                  child: Column(
                    children: [
                      if (booking.isMultiDay) ...[
                        _InfoRow(
                          icon: Icons.date_range_rounded,
                          label: strings['booking_type'] ?? 'Type',
                          value: strings['multi_day_booking'] ?? 'Multi-Day Booking',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      _InfoRow(
                        icon: Icons.calendar_today_rounded,
                        label: strings['date'] ?? 'Date',
                        value: DateFormat('EEEE, MMMM d, yyyy', locale).format(booking.date),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _InfoRow(
                        icon: Icons.schedule_rounded,
                        label: strings['time'] ?? 'Time',
                        value: BookingHelpers.formatTimeRange(booking.startTime, booking.endTime, locale: locale),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _InfoRow(
                        icon: Icons.timer_outlined,
                        label: strings['duration'] ?? 'Duration',
                        value: '${booking.duration} ${booking.duration == 1 ? (strings['hour'] ?? 'hr') : (strings['hours'] ?? 'hrs')}',
                      ),
                      if (booking.address != null && booking.address!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _InfoRow(
                          icon: Icons.location_on_outlined,
                          label: strings['address'] ?? 'Address',
                          value: booking.address!,
                        ),
                      ],
                    ],
                  ),
                ),
                if (booking.isMultiDay) ...[
                  const SizedBox(height: AppSpacing.md),
                  _GroupSessionsCard(booking: booking, isSitterRole: isSitterRole),
                ],
                const SizedBox(height: AppSpacing.md),

                _SectionCard(
                  title: strings['children'] ?? 'Children',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(AppRadius.full),
                            ),
                            child: Text(
                              '${strings['count'] ?? 'Count'}: ${booking.childrenCount ?? 1}',
                              style: AppTextStyles.labelSmall(
                                weight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          if (booking.specialNeedsCount > 0) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppRadius.full),
                              ),
                              child: Text(
                                '${booking.specialNeedsCount} ${strings['special_needs'] ?? 'Special Needs'}',
                                style: AppTextStyles.labelSmall(
                                  weight: FontWeight.w600,
                                  color: AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (booking.childrenNames.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          strings['children_list'] ?? 'Children',
                          style: AppTextStyles.bodySmall(
                            weight: FontWeight.w600,
                            color: context.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: List.generate(booking.childrenNames.length, (i) {
                            final name = booking.childrenNames[i];
                            final age = booking.childrenAges != null && i < booking.childrenAges!.length
                                ? booking.childrenAges![i]
                                : null;
                            return Container(
                              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: context.cardColor,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(color: context.dividerColor),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                                      style: AppTextStyles.labelSmall(
                                        weight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    name,
                                    style: AppTextStyles.bodyMedium(weight: FontWeight.w600),
                                  ),
                                  if (age != null) ...[
                                    const SizedBox(width: AppSpacing.xs),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(AppRadius.sm),
                                      ),
                                      child: Text(
                                        age,
                                        style: AppTextStyles.labelSmall(color: context.textSecondary),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                    );
                  }),
                ),
              ],
              // Show extra-child pricing info if children exceed included
              if (booking.extraAmount > 0) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, size: 16, color: AppColors.warning),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          strings[AppLocalization.extra_charges_note] ?? 'Additional children incur extra charges reflected in the total.',
                          style: AppTextStyles.caption(color: AppColors.warning),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

                _SectionCard(
                  title: strings['pricing'] ?? 'Pricing',
                  child: _PricingDetail(booking: booking),
                ),
                const SizedBox(height: AppSpacing.md),

                if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                  _SectionCard(
                    title: strings['notes'] ?? 'Notes',
                    child: Text(
                      booking.notes!,
                      style: AppTextStyles.bodyMedium(color: context.textSecondaryColor),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                if (booking.specialInstructions != null && booking.specialInstructions!.isNotEmpty) ...[
                  _SectionCard(
                    title: strings['special_instructions'] ?? 'Special Instructions',
                    child: Text(
                      booking.specialInstructions!,
                      style: AppTextStyles.bodyMedium(color: context.textSecondaryColor),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                if ((booking.status == BookingStatus.cancelled && booking.cancellationReason != null && booking.cancellationReason!.isNotEmpty) ||
                    (booking.status == BookingStatus.rejected && booking.rejectionReason != null && booking.rejectionReason!.isNotEmpty)) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, color: AppColors.error, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                              Text(
                                booking.status == BookingStatus.cancelled
                                    ? (strings['cancellation_reason'] ?? 'Cancellation Reason')
                                    : (strings['rejection_reason'] ?? 'Rejection Reason'),
                                style: AppTextStyles.labelLarge(weight: FontWeight.w600, color: AppColors.error),
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                booking.status == BookingStatus.cancelled
                                    ? booking.cancellationReason!
                                    : booking.rejectionReason!,
                                style: AppTextStyles.bodyMedium(color: AppColors.error),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                if (booking.scheduleEvents.isNotEmpty) ...[
                  _SectionCard(
                    title: strings['daily_schedule'] ?? 'Daily Schedule',
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Icon(Icons.schedule_rounded, size: 16, color: AppColors.primary),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              strings['activities'] ?? 'Activities',
                              style: AppTextStyles.bodySmall(weight: FontWeight.w600, color: context.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ...booking.scheduleEvents.map((event) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 60,
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: AppSpacing.xs),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                                ),
                                child: Text(
                                  event.time,
                                  style: AppTextStyles.labelSmall(
                                    weight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Container(
                                width: 2,
                                height: 30,
                                margin: const EdgeInsets.only(top: 4),
                                color: AppColors.primary.withValues(alpha: 0.15),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: Text(
                                    event.activity,
                                    style: AppTextStyles.bodyMedium(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                _ActionButtons(booking: booking),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusHeader extends ConsumerWidget {
  final BookingModel booking;
  const _StatusHeader({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final statusColor = BookingHelpers.statusColor(booking.status);
    final isDark = context.isDark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor.withValues(alpha: isDark ? 0.15 : 0.08), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: statusColor.withValues(alpha: 0.2), width: 2),
            ),
            child: Icon(BookingHelpers.statusIcon(booking.status), size: 36, color: statusColor),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _statusText(booking.status, strings),
            style: AppTextStyles.titleLarge(weight: FontWeight.w700, color: statusColor),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '${strings['booking_reference'] ?? 'Booking'}: #${booking.id}',
            style: AppTextStyles.bodySmall(color: context.textMutedColor),
          ),
          if (booking.createdAt != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              '${DateFormat('MMM d, yyyy', ref.watch(languageProvider).code).format(booking.createdAt!)} • ${TimeFormatter.formatTimeString('${booking.createdAt!.hour.toString().padLeft(2, '0')}:${booking.createdAt!.minute.toString().padLeft(2, '0')}', ref.watch(languageProvider).code)}',
              style: AppTextStyles.labelSmall(color: context.textMutedColor),
            ),
          ],
        ],
      ),
    );
  }

  String _statusText(BookingStatus status, Map<String, String> strings) {
    const fallbacks = {
      BookingStatus.pending: 'Pending',
      BookingStatus.confirmed: 'Confirmed',
      BookingStatus.inProgress: 'In Progress',
      BookingStatus.completed: 'Completed',
      BookingStatus.cancelled: 'Cancelled',
      BookingStatus.rejected: 'Rejected',
      BookingStatus.expired: 'Expired',
    };
    return strings[BookingHelpers.statusLocalizationKey(status)] ?? fallbacks[status]!;
  }
}

class _StatusTimeline extends ConsumerStatefulWidget {
  final BookingModel booking;
  const _StatusTimeline({required this.booking});

  @override
  ConsumerState<_StatusTimeline> createState() => _StatusTimelineState();
}

class _StatusTimelineState extends ConsumerState<_StatusTimeline> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final locale = ref.watch(languageProvider).code;

    final List<_TimelineEntry> entries = [];

    if (widget.booking.statusHistory.isNotEmpty) {
      for (final history in widget.booking.statusHistory) {
        entries.add(_TimelineEntry(
          from: history.fromStatus,
          to: history.toStatus,
          timestamp: history.createdAt,
          reason: history.reason,
        ));
      }
    } else {
      entries.add(_TimelineEntry(from: null, to: 'pending', timestamp: widget.booking.createdAt, reason: strings['booking_created'] ?? 'Booking created'));
      if (widget.booking.confirmedAt != null) entries.add(_TimelineEntry(from: 'pending', to: 'confirmed', timestamp: widget.booking.confirmedAt));
      if (widget.booking.sessionStartedAt != null) entries.add(_TimelineEntry(from: 'confirmed', to: 'session_started', timestamp: widget.booking.sessionStartedAt));
      if (widget.booking.sessionEndedAt != null) entries.add(_TimelineEntry(from: 'session_started', to: 'session_completed', timestamp: widget.booking.sessionEndedAt));
      if (widget.booking.completedAt != null) entries.add(_TimelineEntry(from: 'session_completed', to: 'completed', timestamp: widget.booking.completedAt));
      if (widget.booking.cancelledAt != null) {
        entries.add(_TimelineEntry(
          from: widget.booking.status == BookingStatus.cancelled ? 'confirmed' : 'pending',
          to: 'cancelled',
          timestamp: widget.booking.cancelledAt,
          reason: widget.booking.cancellationReason,
        ));
      }
    }

    return _SectionCard(
      title: strings['status_history'] ?? 'Status History',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Text(
                  _expanded
                      ? (strings['hide_timeline'] ?? 'Hide')
                      : (strings['show_timeline'] ?? 'Show'),
                  style: AppTextStyles.labelSmall(color: context.primaryColor),
                ),
                const SizedBox(width: 2),
                Icon(
                  _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  size: 18,
                  color: context.primaryColor,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: AppSpacing.sm),
            ...List.generate(entries.length, (i) {
          final entry = entries[i];
          final isLast = i == entries.length - 1;
          final statusColor = _entryColor(entry.to);

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  child: Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 2),
                        ),
                      ),
                      if (!isLast)
                        Expanded(child: Container(width: 2, color: statusColor.withValues(alpha: 0.2))),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(_statusLabel(entry.to, strings), style: AppTextStyles.bodyMedium(weight: FontWeight.w600)),
                            if (entry.from != null) ...[
                              const SizedBox(width: AppSpacing.xxs),
                              Text('(${_statusLabel(entry.from!, strings)})', style: AppTextStyles.labelSmall(color: context.textMutedColor)),
                            ],
                          ],
                        ),
                        if (entry.timestamp != null) ...[
                          const SizedBox(height: 2),
                          Text('${DateFormat('MMM d', locale).format(entry.timestamp!)} • ${TimeFormatter.formatTimeString('${entry.timestamp!.hour.toString().padLeft(2, '0')}:${entry.timestamp!.minute.toString().padLeft(2, '0')}', locale)}', style: AppTextStyles.labelSmall(color: context.textMutedColor)),
                        ],
                        if (entry.reason != null && entry.reason!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(_localizedReason(entry.reason!, strings), style: AppTextStyles.bodySmall(color: context.textSecondaryColor)),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ));
          }),
        ],
      ],
    ),
  );
  }

  Color _entryColor(String status) {
    switch (status) {
      case 'pending': return AppColors.warning;
      case 'confirmed': return AppColors.success;
      case 'session_started': return AppColors.primary;
      case 'session_completed': return AppColors.info;
      case 'completed': return AppColors.success;
      case 'cancelled': return AppColors.error;
      case 'rejected': return AppColors.error;
      case 'expired': return AppColors.textMutedLight;
      case 'rebooked': return AppColors.info;
      default: return Colors.grey;
    }
  }

  String _statusLabel(String status, Map<String, String> strings) {
    return strings[status] ?? status;
  }

  String _localizedReason(String reason, Map<String, String> strings) {
    const mapping = {
      'Booking created': 'reason_booking_created',
      'Multi-day booking created': 'reason_multi_day_created',
      'Booking edited by customer': 'reason_edited_by_customer',
      'Group booking edited by customer': 'reason_group_edited',
      'Cancelled by customer': 'reason_cancelled_by_customer',
      'Rebooked by customer': 'reason_rebooked',
      'Confirmation deadline passed — the sitter did not respond in time.': 'reason_deadline_passed',
      'Booking date has passed — no response from the sitter.': 'reason_date_passed',
      'Booking time has passed — no response from the sitter.': 'reason_time_passed',
      'Admin force confirm': 'reason_admin_confirm',
      'Admin force complete': 'reason_admin_complete',
      'Admin force cancel': 'reason_admin_cancel',
      'Admin force rebook': 'reason_admin_rebook',
    };
    final key = mapping[reason];
    if (key != null && strings.containsKey(key)) {
      return strings[key]!;
    }
    if (reason.startsWith('Review submitted') || reason.startsWith('Review updated')) {
      final key2 = reason.startsWith('Review submitted') ? 'reason_review' : 'reason_review_updated';
      return strings[key2] ?? reason;
    }
    final lower = reason.toLowerCase();
    if ((lower.contains('dates ') || lower.contains('date ')) && lower.contains('passed') && (lower.contains('auto') || lower.contains('group'))) {
      return strings['reason_auto_cancelled_group'] ?? reason;
    }
    if (lower.contains('expired') || lower.contains('time slot') || lower.contains('time has passed')) {
      return strings['reason_cancelled_expired'] ?? reason;
    }
    return reason;
  }
}

class _TimelineEntry {
  final String? from;
  final String to;
  final DateTime? timestamp;
  final String? reason;
  const _TimelineEntry({this.from, required this.to, this.timestamp, this.reason});
}

class _LocationCard extends StatelessWidget {
  final BookingModel booking;
  const _LocationCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final location = booking.latestLocation;
    final strings = AppLocalization.get(Localizations.localeOf(context).languageCode);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.6),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.md),
                bottomLeft: Radius.circular(AppRadius.md),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.gps_fixed, size: 14, color: AppColors.info),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        strings['live_location'] ?? 'Live Location',
                        style: AppTextStyles.labelLarge(
                          weight: FontWeight.w600,
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (location?.address != null && location!.address!.isNotEmpty) ...[
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: strings['address'] ?? 'Address',
                      value: location.address!,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  if (location != null) ...[
                    _InfoRow(
                      icon: Icons.explore_outlined,
                      label: strings['gps_label'] ?? 'GPS',
                      value: '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                    ),
                    if (location.speed != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _InfoRow(
                        icon: Icons.speed_rounded,
                        label: strings['speed_label'] ?? 'Speed',
                        value: '${location.speed!.toStringAsFixed(1)} km/h',
                      ),
                    ],
                    if (location.battery != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _InfoRow(
                        icon: Icons.battery_std_rounded,
                        label: strings['battery'] ?? 'Battery',
                        value: '${location.battery}%',
                      ),
                    ],
                    if (location.recordedAt != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _InfoRow(
                        icon: Icons.update_rounded,
                        label: strings['last_updated'] ?? 'Last Updated',
                        value: TimeFormatter.formatTimeString('${location.recordedAt!.hour.toString().padLeft(2, '0')}:${location.recordedAt!.minute.toString().padLeft(2, '0')}', Localizations.localeOf(context).languageCode),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.dividerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.4),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.md),
                bottomLeft: Radius.circular(AppRadius.md),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelLarge(weight: FontWeight.w600)),
                  const SizedBox(height: AppSpacing.sm),
                  child,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final TextStyle? valueStyle;
  const _InfoRow({required this.icon, required this.label, required this.value, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: context.textMutedColor),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 2,
          child: Text(label, style: AppTextStyles.bodyMedium(color: context.textSecondaryColor), overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: valueStyle ?? AppTextStyles.bodyMedium(weight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _GroupSessionsCard extends ConsumerStatefulWidget {
  final BookingModel booking;
  final bool isSitterRole;

  const _GroupSessionsCard({required this.booking, required this.isSitterRole});

  @override
  ConsumerState<_GroupSessionsCard> createState() => _GroupSessionsCardState();
}

class _GroupSessionsCardState extends ConsumerState<_GroupSessionsCard> {
  bool _expanded = false;
  bool _isLoadingAction = false;

  Future<void> _handleStartSession(String sessionId) async {
    if (_isLoadingAction) return;
    setState(() => _isLoadingAction = true);
    try {
      final booking = await ref.read(bookingRepositoryProvider).startBooking(sessionId);
      ref.read(bookingActionProvider)(
        sessionId,
        () async => booking,
      );
      ref.invalidate(bookingGroupProvider(widget.booking.bookingGroupId!));
      if (mounted) {
        context.push('/booking/$sessionId/session');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, ErrorHandler.handle(e).message);
      }
    } finally {
      if (mounted) setState(() => _isLoadingAction = false);
    }
  }

  Future<void> _handleCompleteSession(String sessionId) async {
    if (_isLoadingAction) return;
    setState(() => _isLoadingAction = true);
    try {
      final booking = await ref.read(bookingRepositoryProvider).completeBooking(sessionId);
      ref.read(bookingActionProvider)(
        sessionId,
        () async => booking,
      );
      ref.invalidate(bookingGroupProvider(widget.booking.bookingGroupId!));
      if (mounted) {
        context.pushReplacement('/booking/$sessionId/session');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, ErrorHandler.handle(e).message);
      }
    } finally {
      if (mounted) setState(() => _isLoadingAction = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final locale = ref.watch(languageProvider).code;
    final groupId = widget.booking.bookingGroupId;
    if (groupId == null || groupId.isEmpty) return const SizedBox.shrink();

    final groupAsync = ref.watch(bookingGroupProvider(groupId));

    return _SectionCard(
      title: strings['sessions_list'] ?? 'Sessions',
      child: groupAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (err, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: context.textMutedColor),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  strings['failed_load_sessions'] ?? 'Could not load session details',
                  style: AppTextStyles.bodySmall(color: context.textMutedColor),
                ),
              ),
              TextButton(
                onPressed: () => ref.invalidate(bookingGroupProvider(groupId)),
                child: Text(
                  strings['retry'] ?? 'Retry',
                  style: AppTextStyles.labelSmall(color: context.primaryColor),
                ),
              ),
            ],
          ),
        ),
        data: (groupData) {
          final bookings = groupData['bookings'] as List<dynamic>? ?? [];
          final summary = groupData['summary'] as Map<String, dynamic>? ?? {};
          final totalCount = summary['count'] as int? ?? bookings.length;
          final dates = summary['dates'] as List<dynamic>? ?? [];
          final sortedSessions = List<Map<String, dynamic>>.from(bookings.cast<Map<String, dynamic>>())
            ..sort((a, b) {
              final da = DateTime.tryParse(a['date'] as String? ?? '');
              final db = DateTime.tryParse(b['date'] as String? ?? '');
              if (da != null && db != null) return da.compareTo(db);
              return 0;
            });
            final doneCount = sortedSessions.where((s) {
              final st = s['status'] as String? ?? '';
              return !['pending', 'confirmed'].contains(st);
            }).length;
            final anyLive = sortedSessions.any((s) {
            final ss = s['sessionStatus'] as String? ?? '';
            return ss == 'active' || ss == 'end_qr_generated';
          });
          String? nextSessionId;
          if (!anyLive) {
            for (final s in sortedSessions) {
              final sStatus = s['status'] as String? ?? '';
              final sSessStatus = s['sessionStatus'] as String? ?? 'pending';
              final sDayDone = s['isDayCompleted'] as bool? ?? false;
              if (!sDayDone && (sStatus == 'confirmed' || sStatus == 'in_progress') && sSessStatus == 'pending') {
                nextSessionId = '${s['id']}';
                break;
              }
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: _GroupProgressBar(
                  doneCount: doneCount,
                  totalCount: totalCount,
                  strings: strings,
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: _expanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.md),
                          ...List.generate(bookings.length, (i) {
                final session = bookings[i] as Map<String, dynamic>;
                final sessionDate = session['date'] as String? ?? '';
                final sessionStart = session['startTime'] as String? ?? '';
                final sessionEnd = session['endTime'] as String? ?? '';
                final sessionStatusStr = session['status'] as String? ?? '';
                final sessionStatusField = session['sessionStatus'] as String? ?? '';
                final sessionAddress = session['address'] as String? ?? '';
                final isDayCompleted = session['isDayCompleted'] as bool? ?? false;
                final parsedDate = DateTime.tryParse(sessionDate);
                final formattedDate = parsedDate != null
                    ? DateFormat('MMM d, yyyy', locale).format(parsedDate)
                    : sessionDate;
                final statusEnum = BookingHelpers.parseBookingStatus(sessionStatusStr);
                final bookingStatus = widget.booking.status;
                final sessionSessStatus = BookingHelpers.parseSessionStatus(sessionStatusField);
                final isSessionLive = sessionSessStatus == SessionStatus.active || sessionSessStatus == SessionStatus.endQrGenerated;
                final isTerminalBooking = bookingStatus == BookingStatus.cancelled || 
                    bookingStatus == BookingStatus.rejected || 
                    bookingStatus == BookingStatus.expired;

                BookingStatus effectiveStatus;
                if (statusEnum == BookingStatus.cancelled || statusEnum == BookingStatus.rejected) {
                  effectiveStatus = statusEnum;
                } else if (isSessionLive) {
                  effectiveStatus = BookingStatus.inProgress;
                } else if (isTerminalBooking) {
                  effectiveStatus = bookingStatus;
                } else {
                  effectiveStatus = statusEnum;
                }

                final displayStatus = isDayCompleted ? BookingStatus.completed : effectiveStatus;
                final isCompleted = displayStatus == BookingStatus.completed;
                final isCancelled = !isCompleted && (isTerminalBooking || statusEnum == BookingStatus.cancelled || statusEnum == BookingStatus.rejected);
                final sessionStatusColor = BookingHelpers.statusColor(displayStatus);
                final sessionId = '${session['id']}';
                final isCurrentSession = sessionId == widget.booking.id &&
                    (bookingStatus == BookingStatus.inProgress || bookingStatus == BookingStatus.confirmed) &&
                    !isCompleted && !isCancelled;

                final sessionCancelReason = session['cancellationReason'] as String? ?? '';
                return InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: isCancelled
                      ? () => _showDayCancelledDialog(
                          context, strings, displayStatus, sessionAddress,
                          cancelReason: sessionCancelReason,
                          formattedDate: formattedDate,
                        )
                      : null,
                  child: Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: isCurrentSession
                        ? context.primaryColor.withValues(alpha: 0.04)
                        : context.surfaceColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: isCurrentSession
                        ? Border.all(color: context.primaryColor.withValues(alpha: 0.2))
                        : Border.all(color: context.dividerColor.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: sessionStatusColor.withValues(alpha: isCancelled ? 0.08 : 0.12),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Icon(
                              BookingHelpers.statusIcon(displayStatus),
                              size: 20,
                              color: sessionStatusColor,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today_rounded, size: 12, color: context.textMutedColor),
                                    const SizedBox(width: 3),
                                    Flexible(
                                      child: Text(
                                        formattedDate,
                                        style: AppTextStyles.bodySmall(
                                          weight: isCurrentSession ? FontWeight.w600 : FontWeight.w500,
                                          color: isCurrentSession ? context.textPrimaryColor : context.textSecondaryColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: sessionStatusColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(AppRadius.full),
                                      ),
                                      child: Text(
                                        strings[BookingHelpers.statusLocalizationKey(displayStatus)] ?? displayStatus.name,
                                        style: AppTextStyles.labelSmall(
                                          color: sessionStatusColor,
                                          weight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(Icons.schedule_rounded, size: 12, color: context.textMutedColor),
                                    const SizedBox(width: 3),
                                    Text(
                                      BookingHelpers.formatTimeRange(sessionStart, sessionEnd, locale: locale),
                                      style: AppTextStyles.caption(color: context.textMutedColor),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (sessionAddress.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 13, color: context.textMutedColor),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                sessionAddress,
                                style: AppTextStyles.caption(color: context.textMutedColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (widget.isSitterRole &&
                          bookingStatus == BookingStatus.inProgress &&
                          statusEnum == BookingStatus.confirmed &&
                          sessionSessStatus == SessionStatus.pending &&
                          sessionId == nextSessionId) ...[
                        const SizedBox(height: AppSpacing.xs),
                        AppButton(
                          text: strings['start_session'] ?? 'Start Session',
                          onPressed: _isLoadingAction ? null : () => _handleStartSession(sessionId),
                          variant: AppButtonVariant.filled,
                          isLoading: _isLoadingAction,
                          height: 40,
                        ),
                      ],
                      if (widget.isSitterRole &&
                          bookingStatus == BookingStatus.inProgress &&
                          statusEnum == BookingStatus.inProgress) ...[
                        const SizedBox(height: AppSpacing.xs),
                        AppButton(
                          text: strings['complete_session'] ?? 'Complete',
                          onPressed: _isLoadingAction ? null : () => _handleCompleteSession(sessionId),
                          variant: AppButtonVariant.filled,
                          isLoading: _isLoadingAction,
                          height: 40,
                        ),
                      ],
                    ],
                  ),
                ),
              );
              }),
              if (dates.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(Icons.date_range_rounded, size: 14, color: context.textMutedColor),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${dates.length} ${strings['dates_count']?.replaceAll('{count}', '${dates.length}') ?? '${dates.length} days'}',
                      style: AppTextStyles.caption(color: context.textMutedColor),
                    ),
                  ],
                ),
              ],
            ],
          )
        : const SizedBox.shrink(),
      ),
    ],
  );
},
),
);
}

  void _showDayCancelledDialog(
    BuildContext context,
    Map<String, String> strings,
    BookingStatus status,
    String address, {
    String cancelReason = '',
    String formattedDate = '',
  }) {
    final isExpired = status == BookingStatus.expired;
    final icon = isExpired ? Icons.timer_off_rounded : Icons.cancel_outlined;
    final iconColor = isExpired ? AppColors.warning : AppColors.error;
    final iconBgColor = (isExpired ? AppColors.warning : AppColors.error).withValues(alpha: 0.1);
    final title = isExpired
        ? (strings['day_expired_title'] ?? 'Session Ended')
        : (strings['day_cancelled_title'] ?? 'Session Cancelled');

    String body;
    if (isExpired) {
      body = strings['day_expired_body'] ??
          'The time slot for this session has passed and it never started, so the system closed it automatically.';
    } else if (cancelReason.isNotEmpty) {
      body = (strings['day_cancelled_with_reason'] ?? 'Cancelled — {reason}')
          .replaceAll('{reason}', cancelReason);
    } else {
      body = strings['day_cancelled_body'] ??
          'This session has been cancelled and won\'t take place.';
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.dialog),
        ),
        backgroundColor: ctx.cardColor,
        content: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: iconColor),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                style: AppTextStyles.titleLarge(weight: FontWeight.bold, color: ctx.textPrimaryColor),
                textAlign: TextAlign.center,
              ),
              if (formattedDate.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  formattedDate,
                  style: AppTextStyles.bodySmall(weight: FontWeight.w600, color: iconColor),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Text(
                body,
                style: AppTextStyles.bodyMedium(color: ctx.textSecondaryColor),
                textAlign: TextAlign.center,
              ),
              if (cancelReason.isNotEmpty && !isExpired) ...[
                const SizedBox(height: AppSpacing.xs),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    cancelReason,
                    style: AppTextStyles.bodySmall(
                      color: iconColor,
                      weight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: strings['got_it'] ?? 'Got it',
                  onPressed: () => Navigator.pop(ctx),
                  variant: AppButtonVariant.filled,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupProgressBar extends StatelessWidget {
  final int doneCount;
  final int totalCount;
  final Map<String, String> strings;

  const _GroupProgressBar({
    required this.doneCount,
    required this.totalCount,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalCount > 0 ? doneCount / totalCount : 0.0;
    final isComplete = doneCount >= totalCount;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.dividerColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isComplete ? Icons.check_circle_rounded : Icons.pending_rounded,
                size: 18,
                color: isComplete ? AppColors.success : AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                isComplete
                    ? (strings['all_sessions_completed'] ?? 'All sessions completed')
                    : (strings['sessions_progress'] ?? 'Sessions Progress'),
                style: AppTextStyles.titleSmall(weight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '$doneCount / $totalCount',
                style: AppTextStyles.titleSmall(
                  weight: FontWeight.w700,
                  color: isComplete ? AppColors.success : AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: context.surfaceColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _ProviderInfoCard extends ConsumerWidget {
  final UserModel user;
  final VoidCallback? onTap;
  const _ProviderInfoCard({required this.user, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: AppNetworkImage(imageUrl: user.avatar ?? '', width: 48, height: 48),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: AppTextStyles.bodyLarge(weight: FontWeight.w600)),
                  if (user.babysitterProfile != null && user.babysitterProfile!.rating > 0)
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                        const SizedBox(width: 2),
                        Text(user.babysitterProfile!.rating.toStringAsFixed(1), style: AppTextStyles.bodySmall(color: context.textSecondaryColor)),
                        if (user.babysitterProfile!.reviewCount > 0) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Text('(${user.babysitterProfile!.reviewCount})', style: AppTextStyles.caption(color: context.textMutedColor)),
                        ],
                      ],
                    ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right_rounded, size: 22, color: context.textMutedColor),
          ],
        ),
      ),
    );
  }
}

class _InfoUnavailable extends StatelessWidget {
  final String label;
  const _InfoUnavailable({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.textMutedColor.withValues(alpha: 0.1),
            ),
            child: Icon(Icons.person_off_rounded, size: 24, color: context.textMutedColor),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium(color: context.textMutedColor))),
        ],
      ),
    );
  }
}

class _ActionButtons extends ConsumerStatefulWidget {
  final BookingModel booking;
  const _ActionButtons({required this.booking});

  @override
  ConsumerState<_ActionButtons> createState() => _ActionButtonsState();
}

class _ActionButtonsState extends ConsumerState<_ActionButtons> {
  bool _isLoading = false;
  DateTime _lastNavigationTime = DateTime(2000);

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final booking = widget.booking;
    final authState = ref.watch(authProvider);
    final currentUser = authState.user;

    final isBookingOwner = currentUser?.id == booking.customerId;
    final isAssignedSitter = currentUser?.id == booking.sitterId;
    final isCustomerRole = isBookingOwner;
    final isSitterRole = isAssignedSitter;

    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.dividerColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                if (isSitterRole) _buildSitterActions(booking, strings),
                if (isCustomerRole) _buildCustomerActions(booking, strings),
                if (!isSitterRole && !isCustomerRole) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        text: strings['support'] ?? 'Support',
                        onPressed: _isLoading ? null : () => context.push('/support'),
                        variant: AppButtonVariant.outlined,
                        prefixIcon: const Icon(Icons.headset_mic_rounded, size: 18),
                      ),
                    ),
                  ),
                ],
                const Divider(height: AppSpacing.lg),
                Row(
                  children: [
                    if (booking.status == BookingStatus.confirmed)
                      Expanded(
                        child: _ActionChip(
                          icon: Icons.chat_outlined,
                          label: strings['chat'] ?? 'Chat',
                          onTap: () => _handleChat(booking),
                        ),
                      ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _ActionChip(
                        icon: Icons.headset_mic_outlined,
                        label: strings['support'] ?? 'Support',
                        onTap: () => context.push('/support'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerActions(BookingModel booking, Map<String, String> strings) {
    switch (booking.status) {
      case BookingStatus.pending:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: strings['edit_booking'] ?? 'Edit Booking',
                onPressed: _isLoading ? null : () => _handleEdit(booking),
                variant: AppButtonVariant.outlined,
                prefixIcon: const Icon(Icons.edit_outlined, size: 18),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: _isLoading ? (strings['cancelling'] ?? 'Cancelling...') : (strings['cancel_booking'] ?? 'Cancel Booking'),
                onPressed: _isLoading ? null : () => _showCancelDialog(context, booking, strings),
                variant: AppButtonVariant.danger,
                prefixIcon: const Icon(Icons.cancel_outlined, size: 18),
              ),
            ),
          ],
        );

      case BookingStatus.confirmed:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: strings['go_to_session'] ?? 'Go to Session',
                onPressed: () => context.push('/booking/${booking.id}/session'),
                variant: AppButtonVariant.filled,
                prefixIcon: const Icon(Icons.play_circle_outline, size: 18),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: strings['cancel_booking'] ?? 'Cancel Booking',
                onPressed: _isLoading ? null : () => _showCancelDialog(context, booking, strings),
                variant: AppButtonVariant.danger,
                prefixIcon: const Icon(Icons.cancel_outlined, size: 18),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: strings['add_to_calendar'] ?? 'Add to Calendar',
                    onPressed: _isLoading ? null : () => _handleAddToCalendar(booking),
                    variant: AppButtonVariant.outlined,
                    prefixIcon: const Icon(Icons.calendar_month_rounded, size: 18),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    text: strings['rebook'] ?? 'Rebook',
                    onPressed: () => _showRebookDialog(context, booking, strings),
                    variant: AppButtonVariant.outlined,
                    prefixIcon: const Icon(Icons.replay_rounded, size: 18),
                  ),
                ),
              ],
            ),
          ],
        );

      case BookingStatus.completed:
        return Column(
          children: [
            if (booking.rating != null) ...[
              _ExistingRatingCard(booking: booking, strings: strings),
              const SizedBox(height: AppSpacing.md),
            ],
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: booking.rating != null
                    ? (strings['update_review_btn'] ?? 'Update Review')
                    : (strings['leave_review'] ?? 'Review Sitter'),
                onPressed: _isLoading ? null : () => _showReviewDialog(context, booking, strings),
                variant: AppButtonVariant.filled,
                prefixIcon: Icon(
                  booking.rating != null
                      ? Icons.edit_rounded
                      : Icons.star_outline_rounded,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: strings['rebook'] ?? 'Rebook',
                    onPressed: () => _showRebookDialog(context, booking, strings),
                    variant: AppButtonVariant.outlined,
                    prefixIcon: const Icon(Icons.replay_rounded, size: 18),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    text: strings['invoice'] ?? 'Invoice',
                    onPressed: _isLoading ? null : () => _handleDownloadInvoice(booking),
                    variant: AppButtonVariant.outlined,
                    prefixIcon: const Icon(Icons.receipt_long_rounded, size: 18),
                  ),
                ),
              ],
            ),
          ],
        );

      case BookingStatus.cancelled:
      case BookingStatus.expired:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: strings['rebook'] ?? 'Rebook',
                onPressed: () => _showRebookDialog(context, booking, strings),
                variant: AppButtonVariant.filled,
                prefixIcon: const Icon(Icons.replay_rounded, size: 18),
              ),
            ),
          ],
        );

      case BookingStatus.rejected:
        return Column(
          children: [
            if (booking.rejectionReason != null && booking.rejectionReason!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: AppColors.error),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          booking.rejectionReason!,
                          style: AppTextStyles.bodySmall(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: strings['edit_and_resubmit'] ?? 'Edit & Submit Again',
                onPressed: _isLoading ? null : () {
                  context.push('/booking/flow?sitterId=${booking.sitterId}');
                },
                variant: AppButtonVariant.filled,
                prefixIcon: const Icon(Icons.edit_outlined, size: 18),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: strings['book_another_date'] ?? 'Book Another Date',
                onPressed: _isLoading ? null : () => context.push('/booking/flow?sitterId=${booking.sitterId}'),
                variant: AppButtonVariant.outlined,
                prefixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
              ),
            ),
          ],
        );

      case BookingStatus.inProgress:
        return SizedBox(
          width: double.infinity,
          child: AppButton(
            text: strings['view_session'] ?? 'View Session',
            onPressed: () => context.push('/booking/${booking.id}/session'),
            variant: AppButtonVariant.filled,
            prefixIcon: const Icon(Icons.timer_outlined, size: 18),
          ),
        );
    }
  }

  Widget _buildSitterActions(BookingModel booking, Map<String, String> strings) {
    final isGroupBooking = booking.bookingGroupId != null && booking.bookingGroupId!.isNotEmpty;
    if (!isGroupBooking && booking.isPastDue && booking.status == BookingStatus.pending) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.warningColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: context.warningColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.timer_off_rounded, color: context.warningColor, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                strings['booking_expired_message'] ?? 'This booking has expired. The customer will be notified.',
                style: AppTextStyles.bodySmall(color: context.textSecondaryColor),
              ),
            ),
          ],
        ),
      );
    }

    switch (booking.status) {
      case BookingStatus.pending:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: strings['confirm_booking'] ?? 'Accept',
                onPressed: _isLoading ? null : () => _showConfirmDialog(context, booking, strings),
                variant: AppButtonVariant.filled,
                prefixIcon: const Icon(Icons.check_circle_outline, size: 18),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                    text: strings['reject'] ?? 'Reject',
                onPressed: _isLoading ? null : () => _showRejectDialog(context, booking, strings),
                variant: AppButtonVariant.danger,
                prefixIcon: const Icon(Icons.block_rounded, size: 18),
              ),
            ),
          ],
        );

      case BookingStatus.confirmed:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: strings['go_to_session'] ?? 'Go to Session',
                onPressed: () => context.push('/booking/${booking.id}/session'),
                variant: AppButtonVariant.filled,
                prefixIcon: const Icon(Icons.play_circle_outline, size: 18),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: strings['cancel_booking'] ?? 'Cancel',
                    onPressed: _isLoading ? null : () => _showSitterCancelDialog(context, booking, strings),
                    variant: AppButtonVariant.danger,
                    prefixIcon: const Icon(Icons.cancel_outlined, size: 18),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    text: strings['reschedule'] ?? 'Reschedule',
                    onPressed: _isLoading ? null : () => _handleReschedule(booking),
                    variant: AppButtonVariant.outlined,
                    prefixIcon: const Icon(Icons.date_range_rounded, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: strings['emergency_cancel'] ?? 'Emergency Cancel',
                    onPressed: _isLoading ? null : () => _showEmergencyCancelDialog(context, booking, strings),
                    variant: AppButtonVariant.danger,
                    prefixIcon: const Icon(Icons.warning_rounded, size: 18),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    text: strings['invoice'] ?? 'Invoice',
                    onPressed: _isLoading ? null : () => _handleDownloadInvoice(booking),
                    variant: AppButtonVariant.outlined,
                    prefixIcon: const Icon(Icons.receipt_long_rounded, size: 18),
                  ),
                ),
              ],
            ),
          ],
        );

      case BookingStatus.completed:
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: strings['invoice'] ?? 'Invoice',
                    onPressed: _isLoading ? null : () => _handleDownloadInvoice(booking),
                    variant: AppButtonVariant.outlined,
                    prefixIcon: const Icon(Icons.receipt_long_rounded, size: 18),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    text: strings['customer_profile'] ?? 'Customer Profile',
                    onPressed: _isLoading ? null : () => _handleViewCustomerProfile(booking),
                    variant: AppButtonVariant.outlined,
                    prefixIcon: const Icon(Icons.person_rounded, size: 18),
                  ),
                ),
              ],
            ),
          ],
        );

      case BookingStatus.cancelled:
        return Column(
          children: [
            if (booking.cancellationReason != null && booking.cancellationReason!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: AppColors.error),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(booking.cancellationReason!, style: AppTextStyles.bodySmall(color: AppColors.error)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );

      case BookingStatus.rejected:
        return Column(
          children: [
            if (booking.rejectionReason != null && booking.rejectionReason!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: AppColors.error),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(booking.rejectionReason!, style: AppTextStyles.bodySmall(color: AppColors.error)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );

      case BookingStatus.inProgress:
        return SizedBox(
          width: double.infinity,
          child: AppButton(
            text: strings['view_session'] ?? 'View Session',
            onPressed: () => context.push('/booking/${booking.id}/session'),
            variant: AppButtonVariant.filled,
            prefixIcon: const Icon(Icons.timer_outlined, size: 18),
          ),
        );

      case BookingStatus.expired:
        return const SizedBox.shrink();
    }
  }

  void _handleEdit(BookingModel booking) {
    if (booking.isMultiDay && booking.bookingGroupId != null && booking.bookingGroupId!.isNotEmpty) {
      context.push('/booking/flow?sitterId=${booking.sitterId}&groupEdit=${booking.bookingGroupId}');
    } else {
      context.push('/booking/flow?sitterId=${booking.sitterId}&edit=${booking.id}');
    }
  }

  void _handleAddToCalendar(BookingModel booking) {
    final locale = ref.read(languageProvider).code;
    final calendarStrings = AppLocalization.get(locale);
    final startDate = DateTime(
      booking.date.year,
      booking.date.month,
      booking.date.day,
      int.tryParse(booking.startTime.split(':')[0]) ?? 9,
      int.tryParse(booking.startTime.split(':')[1]) ?? 0,
    );
    final endDate = DateTime(
      booking.date.year,
      booking.date.month,
      booking.date.day,
      int.tryParse(booking.endTime.split(':')[0]) ?? 17,
      int.tryParse(booking.endTime.split(':')[1]) ?? 0,
    );
    final title = (calendarStrings['calendar_event_title'] ?? 'Babysitting: {sitter_name}')
        .replaceFirst('{sitter_name}', booking.sitter?.name ?? (calendarStrings['sitter_label'] ?? 'Sitter'));

    final event = Event(
      title: title,
      description: (calendarStrings['calendar_event_desc'] ?? 'Booking #{booking_id}\n{customer_name}')
          .replaceFirst('{booking_id}', booking.id.toString())
          .replaceFirst('{customer_name}', booking.customer?.name ?? (calendarStrings['parent'] ?? 'Customer')),
      location: booking.address ?? '',
      startDate: startDate,
      endDate: endDate,
    );
    Add2Calendar.addEvent2Cal(event);
  }

  void _handleDownloadInvoice(BookingModel booking) {
    context.push('/booking/${booking.id}/invoice');
  }

  void _handleReschedule(BookingModel booking) {
    context.push('/booking/${booking.id}/reschedule'    );
  }

  void _showConfirmDialog(BuildContext context, BookingModel booking, Map<String, String> strings) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardColor,
      builder: (_) => _ConfirmBookingDialog(
        booking: booking,
        onConfirm: () async {
          setState(() => _isLoading = true);
          try {
            await ref.read(bookingActionProvider)(
              booking.id,
              () => ref.read(bookingRepositoryProvider).confirmBooking(booking.id),
            );
            if (mounted) {
              setState(() => _isLoading = false);
              AppSnackbar.success(context, strings['booking_confirmed_successfully'] ?? 'Booking confirmed successfully');
              ref.invalidate(bookingDetailProvider(booking.id));
            }
          } catch (e) {
            if (mounted) {
              setState(() => _isLoading = false);
              AppSnackbar.error(context, ErrorHandler.handle(e).message);
            }
          }
        },
      ),
    );
  }

  void _showRejectDialog(BuildContext context, BookingModel booking, Map<String, String> strings) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardColor,
      builder: (sheetContext) => _RejectBookingDialog(booking: booking, onConfirm: (reason) async {
        Navigator.pop(context);
        setState(() => _isLoading = true);
        try {
          await ref.read(bookingActionProvider)(
            booking.id,
            () => ref.read(bookingRepositoryProvider).rejectBooking(booking.id, reason: reason),
          );
          if (mounted) {
            setState(() => _isLoading = false);
            AppSnackbar.success(context, strings['booking_rejected'] ?? 'Booking rejected');
            ref.invalidate(bookingDetailProvider(booking.id));
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isLoading = false);
            AppSnackbar.error(context, ErrorHandler.handle(e).message);
          }
        }
      }),
    );
  }

  void _handleViewCustomerProfile(BookingModel booking) {
    if (booking.customerId.isNotEmpty) {
      context.push('/sitter/${booking.customerId}');
    }
  }

  void _showEmergencyCancelDialog(BuildContext context, BookingModel booking, Map<String, String> strings) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardColor,
      builder: (_) => _CancelBookingDialog(booking: booking, onConfirm: (reason) async {
        Navigator.pop(context);
        _handleEmergencyCancel(booking, reason, strings);
      }),
    );
  }

  Future<void> _handleEmergencyCancel(BookingModel booking, String reason, Map<String, String> strings) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(bookingActionProvider)(
        booking.id,
        () => ref.read(bookingRepositoryProvider).sitterCancelBooking(booking.id, reason: reason),
      );
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackbar.success(context, strings['booking_cancelled'] ?? 'Booking cancelled');
        ref.invalidate(bookingDetailProvider(booking.id));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackbar.error(context, ErrorHandler.handle(e).message);
      }
    }
  }

  void _handleChat(BookingModel booking) {
    context.push('/chat?userId=${booking.sitterId}&bookingId=${booking.id}');
  }

  void _showCancelDialog(BuildContext context, BookingModel booking, Map<String, String> strings) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardColor,
      builder: (_) => _CancelBookingDialog(booking: booking, onConfirm: (reason) async {
        Navigator.pop(context);
        _handleCustomerCancel(booking, reason, strings);
      }),
    );
  }

  Future<void> _handleCustomerCancel(BookingModel booking, String reason, Map<String, String> strings) async {
    setState(() => _isLoading = true);
    try {
      if (booking.isMultiDay) {
        await ref.read(bookingRepositoryProvider).cancelBookingGroup(
          booking.bookingGroupId!,
          reason: reason,
        );
        ref.invalidate(pendingBookingsProvider);
        ref.invalidate(confirmedBookingsProvider);
        ref.invalidate(bookingDetailProvider(booking.id));
        if (mounted) {
          setState(() => _isLoading = false);
          context.pop();
        }
      } else {
        await ref.read(bookingActionProvider)(
          booking.id,
          () => ref.read(bookingRepositoryProvider).cancelBooking(booking.id, reason: reason),
        );
        if (mounted) {
          setState(() => _isLoading = false);
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackbar.error(context, ErrorHandler.handle(e).message);
      }
    }
  }

  void _showSitterCancelDialog(BuildContext context, BookingModel booking, Map<String, String> strings) {
    final reasonController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardColor,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.08), shape: BoxShape.circle),
                child: const Icon(Icons.cancel_outlined, size: 48, color: AppColors.error),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(strings['sitter_cancel_title'] ?? 'Cancel This Booking', style: AppTextStyles.titleLarge(weight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                strings['sitter_cancel_body'] ?? 'Cancelling a confirmed booking may affect your reliability. Provide a reason.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium(color: context.textSecondaryColor),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: reasonController,
                label: strings['reason_required'] ?? 'Reason (required)',
                hint: strings['sitter_cancel_hint'] ?? 'Explain why you need to cancel',
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: strings['keep_booking'] ?? 'Keep Booking',
                      onPressed: () => Navigator.pop(context),
                      variant: AppButtonVariant.outlined,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppButton(
                      text: strings['confirm_cancel'] ?? 'Yes, Cancel',
                      onPressed: () {
                        if (reasonController.text.trim().length < 10) return;
                        Navigator.pop(context);
                        _handleSitterCancel(booking, reasonController.text, strings);
                      },
                      variant: AppButtonVariant.danger,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSitterCancel(BookingModel booking, String reason, Map<String, String> strings) async {
    setState(() => _isLoading = true);
    try {
      if (booking.isMultiDay) {
        await ref.read(bookingRepositoryProvider).cancelBookingGroup(
          booking.bookingGroupId!,
          reason: reason,
        );
        ref.invalidate(pendingBookingsProvider);
        ref.invalidate(confirmedBookingsProvider);
        ref.invalidate(bookingDetailProvider(booking.id));
        if (mounted) {
          setState(() => _isLoading = false);
          AppSnackbar.success(context, strings['booking_cancelled_successfully'] ?? 'Booking cancelled');
        }
      } else {
        await ref.read(bookingActionProvider)(
          booking.id,
          () => ref.read(bookingRepositoryProvider).sitterCancelBooking(booking.id, reason: reason),
        );
        if (mounted) {
          setState(() => _isLoading = false);
          AppSnackbar.success(context, strings['booking_cancelled_successfully'] ?? 'Booking cancelled');
          ref.invalidate(bookingDetailProvider(booking.id));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackbar.error(context, ErrorHandler.handle(e).message);
      }
    }
  }


  void _showRebookDialog(BuildContext context, BookingModel booking, Map<String, String> strings) {
    final today = DateTime.now();
    final bookingDate = DateTime(booking.date.year, booking.date.month, booking.date.day);
    final todayDate = DateTime(today.year, today.month, today.day);
    final isPast = bookingDate.isBefore(todayDate);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardColor,
      builder: (_) => _RebookDialog(
        booking: booking,
        isPast: isPast,
        onRebook: () {
          Navigator.pop(context);
          _performRebook(booking, strings);
        },
        onEditRebook: () {
          final now = DateTime.now();
          if (now.difference(_lastNavigationTime).inSeconds < 3) return;
          _lastNavigationTime = now;
          Navigator.pop(context);
          if (booking.isMultiDay && booking.bookingGroupId != null) {
            context.push('/booking/flow?sitterId=${booking.sitterId}&groupEdit=${booking.bookingGroupId}&forRebook=true');
          } else {
            context.push('/booking/flow?sitterId=${booking.sitterId}&rebookFrom=${booking.id}');
          }
        },
      ),
    );
  }

  Future<void> _performRebook(BookingModel booking, Map<String, String> strings) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(bookingActionProvider)(
        booking.id,
        () => ref.read(bookingRepositoryProvider).rebookBooking(
          booking.id,
          date: booking.date,
          startTime: booking.startTime,
          endTime: booking.endTime,
          duration: booking.duration,
          childrenCount: booking.childrenCount,
          notes: booking.notes,
          address: booking.address,
          specialInstructions: booking.specialInstructions,
        ),
      );
      if (mounted) {
        setState(() => _isLoading = false);
        if (booking.bookingGroupId != null && booking.bookingGroupId!.isNotEmpty) {
          ref.invalidate(bookingGroupProvider(booking.bookingGroupId!));
        }
        AppSnackbar.success(context, strings['booking_updated_rebooked'] ?? 'Updated & Rebooked');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackbar.error(context, ErrorHandler.handle(e).message);
      }
    }
  }

  void _showReviewDialog(BuildContext context, BookingModel booking, Map<String, String> strings) async {
    if (booking.isMultiDay && booking.bookingGroupId != null) {
      final result = await showRatingBottomSheet(
        context,
        data: RatingBottomSheetData(
          initialRating: 5.0,
          initialReview: null,
          isEdit: false,
        ),
      );
      if (result == null || !context.mounted) return;
      setState(() => _isLoading = true);
      try {
        await ref.read(bookingRepositoryProvider).submitGroupReview(
          booking.bookingGroupId!,
          rating: result.rating,
          review: result.review,
        );
        if (mounted) {
          setState(() => _isLoading = false);
          AppSnackbar.success(context, strings['review_submitted'] ?? 'Review submitted');
          ref.invalidate(bookingDetailProvider(booking.id));
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          AppSnackbar.error(context, strings['booking_failed'] ?? 'Failed to submit review');
        }
      }
      return;
    }

    final result = await showRatingBottomSheet(
      context,
      data: RatingBottomSheetData(
        initialRating: booking.rating ?? 5.0,
        initialReview: booking.review,
        isEdit: booking.rating != null,
      ),
    );

    if (result == null || !context.mounted) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(bookingRepositoryProvider).submitReview(
        booking.id,
        rating: result.rating,
        review: result.review,
      );
      if (mounted) {
        setState(() => _isLoading = false);
        final msg = booking.rating != null
            ? (strings['review_updated'] ?? 'Review updated')
            : (strings['review_submitted'] ?? 'Review submitted');
        AppSnackbar.success(context, msg);
        ref.invalidate(bookingDetailProvider(booking.id));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackbar.error(context, strings['booking_failed'] ?? 'Failed to submit review');
      }
    }
  }
}

class _CancelBookingDialog extends ConsumerStatefulWidget {
  final BookingModel booking;
  final Future<void> Function(String reason) onConfirm;
  const _CancelBookingDialog({required this.booking, required this.onConfirm});

  @override
  ConsumerState<_CancelBookingDialog> createState() => _CancelBookingDialogState();
}

class _CancelBookingDialogState extends ConsumerState<_CancelBookingDialog> {
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.08), shape: BoxShape.circle),
                child: const Icon(Icons.cancel_outlined, size: 48, color: AppColors.error),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(strings['cancel_booking'] ?? 'Cancel Booking', style: AppTextStyles.titleLarge(weight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                strings['cancel_booking_consequences'] ?? 'This booking will be cancelled. Are you sure?',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium(color: context.textSecondaryColor),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: _reasonController,
                label: strings['reason_optional'] ?? 'Reason (optional)',
                hint: strings['cancellation_hint'] ?? 'Tell us why',
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: strings['keep_booking'] ?? 'Keep Booking',
                      onPressed: () => Navigator.pop(context),
                      variant: AppButtonVariant.outlined,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppButton(
                      text: _isSubmitting ? (strings['cancelling'] ?? 'Cancelling...') : (strings['confirm_cancel'] ?? 'Yes, Cancel'),
                      onPressed: _isSubmitting ? null : () {
                        setState(() => _isSubmitting = true);
                        widget.onConfirm(_reasonController.text);
                      },
                      variant: AppButtonVariant.danger,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmBookingDialog extends ConsumerStatefulWidget {
  final BookingModel booking;
  final VoidCallback onConfirm;
  const _ConfirmBookingDialog({required this.booking, required this.onConfirm});

  @override
  ConsumerState<_ConfirmBookingDialog> createState() => _ConfirmBookingDialogState();
}

class _ConfirmBookingDialogState extends ConsumerState<_ConfirmBookingDialog> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final b = widget.booking;
    final locale = ref.watch(languageProvider).code;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, size: 48, color: AppColors.success),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                strings['confirm_booking_title'] ?? 'Confirm This Booking',
                style: AppTextStyles.titleLarge(weight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                strings['confirm_booking_body'] ?? 'Once confirmed, the booking will be locked to the selected date and time. The parent will be notified immediately.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium(color: context.textSecondaryColor),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: context.primaryColor.withValues(alpha: 0.15)),
                ),
                child: Column(
                  children: [
                    if (b.isMultiDay) ...[
                      _ConfirmInfoRow(
                        icon: Icons.date_range_rounded,
                        label: strings['sessions_list'] ?? 'Sessions',
                        value: '${b.bookingGroupId != null ? strings['multi_day_badge'] ?? 'Multi-Day' : '—'}',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _ConfirmInfoRow(
                        icon: Icons.calendar_today_rounded,
                        label: strings['date'] ?? 'Date',
                        value: DateFormat('EEEE, MMMM d, yyyy', locale).format(b.date),
                      ),
                    ] else ...[
                      _ConfirmInfoRow(
                        icon: Icons.calendar_today_rounded,
                        label: strings['date'] ?? 'Date',
                        value: DateFormat('EEEE, MMMM d, yyyy', locale).format(b.date),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    _ConfirmInfoRow(
                      icon: Icons.schedule_rounded,
                      label: strings['time'] ?? 'Time',
                      value: TimeFormatter.formatTimeRange(b.startTime, b.endTime, locale),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ConfirmInfoRow(
                      icon: Icons.timer_outlined,
                      label: strings['duration'] ?? 'Duration',
                      value: '${b.duration} ${b.duration == 1 ? (strings['hour'] ?? 'hr') : (strings['hours'] ?? 'hrs')}',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ConfirmInfoRow(
                      icon: Icons.people_outline,
                      label: strings['children'] ?? 'Children',
                      value: '${b.childrenCount ?? 1}',
                    ),
                    if (b.totalAmount > 0) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _ConfirmInfoRow(
                        icon: Icons.receipt_outlined,
                        label: strings['total'] ?? 'Total',
                        value: '${strings['sar'] ?? 'SAR'} ${b.totalAmount.toStringAsFixed(0)}',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: strings['cancel'] ?? 'Cancel',
                      onPressed: () => Navigator.pop(context),
                      variant: AppButtonVariant.outlined,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppButton(
                      text: _isSubmitting ? (strings['confirm_booking'] ?? 'Confirming...') : (strings['confirm_accept'] ?? 'Yes, Confirm'),
                      onPressed: _isSubmitting ? null : () {
                        setState(() => _isSubmitting = true);
                        Navigator.pop(context);
                        widget.onConfirm();
                      },
                      variant: AppButtonVariant.filled,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ConfirmInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: context.primaryColor),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(label, style: AppTextStyles.bodySmall(color: context.textSecondaryColor)),
        ),
        Text(value, style: AppTextStyles.bodyMedium(weight: FontWeight.w600)),
      ],
    );
  }
}

class _RebookDialog extends ConsumerWidget {
  final BookingModel booking;
  final bool isPast;
  final VoidCallback onRebook;
  final VoidCallback onEditRebook;
  const _RebookDialog({required this.booking, required this.isPast, required this.onRebook, required this.onEditRebook});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider).code;
    final strings = AppLocalization.get(locale);
    final b = booking;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.replay_rounded, color: context.primaryColor, size: 32),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text(strings['rebook'] ?? 'Rebook', style: AppTextStyles.titleLarge(weight: FontWeight.bold)),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Center(
              child: Text(
                strings['rebook_subtitle'] ?? 'Choose to rebook with the same details or edit them.',
                style: AppTextStyles.bodySmall(color: context.textSecondaryColor),
                textAlign: TextAlign.center,
              ),
            ),
            if (isPast) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: AppColors.warning),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        strings['rebook_past_warning'] ?? 'The original date has passed. Edit the date below to rebook.',
                        style: AppTextStyles.bodySmall(color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: context.dividerColor.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.summarize_rounded, size: 16, color: context.textSecondaryColor),
                      const SizedBox(width: AppSpacing.sm),
                      Text(strings['previous_booking'] ?? 'Previous Booking',
                        style: AppTextStyles.labelMedium(weight: FontWeight.w600, color: context.textSecondaryColor)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SummaryRow(icon: Icons.calendar_today_rounded, label: strings['date'] ?? 'Date', value: DateFormat('MMM d, yyyy').format(b.date)),
                  const SizedBox(height: AppSpacing.sm),
                  _SummaryRow(icon: Icons.schedule_rounded, label: strings['time'] ?? 'Time', value: TimeFormatter.formatTimeRange(b.startTime, b.endTime, locale)),
                  const SizedBox(height: AppSpacing.sm),
                  _SummaryRow(icon: Icons.timer_outlined, label: strings['duration'] ?? 'Duration', value: '${b.duration} ${b.duration == 1 ? (strings['hour'] ?? 'hr') : (strings['hours'] ?? 'hrs')}'),
                  const SizedBox(height: AppSpacing.sm),
                  _SummaryRow(icon: Icons.people_outline, label: strings['children'] ?? 'Children', value: '${b.childrenCount ?? 1}'),
                  if (b.childrenAges != null && b.childrenAges!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _SummaryRow(icon: Icons.cake_outlined, label: strings['children_ages'] ?? 'Ages', value: b.childrenAges!.join(', ')),
                  ],
                  if (b.address != null && b.address!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _SummaryRow(icon: Icons.location_on_outlined, label: strings['address'] ?? 'Address', value: b.address!),
                  ],
                  if (b.notes != null && b.notes!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _SummaryRow(icon: Icons.notes_rounded, label: strings['notes'] ?? 'Notes', value: b.notes!),
                  ],
                  if (b.specialInstructions != null && b.specialInstructions!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _SummaryRow(icon: Icons.info_outline_rounded, label: strings['special_instructions'] ?? 'Special Instructions', value: b.specialInstructions!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            if (b.totalAmount > 0) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: context.primaryColor.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.receipt_outlined, size: 18, color: context.primaryColor),
                    const SizedBox(width: AppSpacing.sm),
                    Text(strings['total'] ?? 'Total', style: AppTextStyles.bodyMedium(color: context.textSecondaryColor)),
                    const Spacer(),
                    Text('${strings['sar'] ?? 'SAR'} ${b.totalAmount.toStringAsFixed(0)}',
                      style: AppTextStyles.titleMedium(weight: FontWeight.bold, color: context.primaryColor)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            if (!isPast)
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: strings['rebook_confirm'] ?? 'Rebook Now',
                  onPressed: onRebook,
                  variant: AppButtonVariant.filled,
                  prefixIcon: const Icon(Icons.replay_rounded, size: 18),
                ),
              ),
            if (!isPast)
              const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: strings['edit_rebook'] ?? 'Edit & Rebook',
                onPressed: onEditRebook,
                variant: isPast ? AppButtonVariant.filled : AppButtonVariant.outlined,
                prefixIcon: const Icon(Icons.edit_outlined, size: 18),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _SummaryRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: context.textMutedColor),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 80,
          child: Text(label, style: AppTextStyles.bodySmall(color: context.textMutedColor)),
        ),
        Expanded(
          child: Text(value, style: AppTextStyles.bodyMedium(weight: FontWeight.w500), textAlign: TextAlign.end),
        ),
      ],
    );
  }
}

class _RejectBookingDialog extends ConsumerStatefulWidget {
  final BookingModel booking;
  final Function(String reason) onConfirm;
  const _RejectBookingDialog({required this.booking, required this.onConfirm});

  @override
  ConsumerState<_RejectBookingDialog> createState() => _RejectBookingDialogState();
}

class _RejectBookingDialogState extends ConsumerState<_RejectBookingDialog> {
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.08), shape: BoxShape.circle),
                child: const Icon(Icons.block_rounded, size: 48, color: AppColors.error),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(strings['reject'] ?? 'Reject Booking', style: AppTextStyles.titleLarge(weight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                strings['rejection_hint'] ?? 'Let the customer know why',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium(color: context.textSecondaryColor),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: _reasonController,
                label: strings['reason_optional'] ?? 'Reason (optional)',
                hint: strings['rejection_hint'] ?? 'Why are you declining?',
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: strings['cancel'] ?? 'Cancel',
                      onPressed: () => Navigator.pop(context),
                      variant: AppButtonVariant.outlined,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppButton(
                      text: _isSubmitting ? (strings['reject'] ?? 'Rejecting...') : (strings['reject'] ?? 'Yes, Reject'),
                      onPressed: _isSubmitting ? null : () async {
                        setState(() => _isSubmitting = true);
                        try {
                          await widget.onConfirm(_reasonController.text);
                        } finally {
                          if (mounted) setState(() => _isSubmitting = false);
                        }
                      },
                      variant: AppButtonVariant.danger,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExistingRatingCard extends StatelessWidget {
  final BookingModel booking;
  final Map<String, String> strings;

  const _ExistingRatingCard({
    required this.booking,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              Icons.star_rounded,
              color: AppColors.warning,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings['your_rating'] ?? 'Your Rating',
                  style: AppTextStyles.bodySmall(
                    color: context.textMutedColor,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    children: [
                      ...List.generate(5, (i) {
                        final filled = (i + 1) <= (booking.rating ?? 0).round();
                        return Padding(
                          padding: const EdgeInsets.only(right: 2),
                          child: Icon(
                            filled ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 18,
                            color: filled ? AppColors.warning : context.textMutedColor.withValues(alpha: 0.2),
                          ),
                        );
                      }),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        booking.rating!.toStringAsFixed(1),
                        style: AppTextStyles.titleSmall(
                          weight: FontWeight.w600,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (booking.review != null && booking.review!.isNotEmpty)
            Container(
              width: 1,
              height: 32,
              color: context.dividerColor,
            ),
          if (booking.review != null && booking.review!.isNotEmpty)
            const SizedBox(width: AppSpacing.sm),
          if (booking.review != null && booking.review!.isNotEmpty)
            Flexible(
              child: Text(
                booking.review!,
                style: AppTextStyles.caption(
                  color: context.textMutedColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

class _PricingDetail extends ConsumerWidget {
  final BookingModel booking;
  const _PricingDetail({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = booking.sitter?.babysitterProfile;
    final locale = ref.watch(languageProvider).code;
    final strings = AppLocalization.get(locale);

    if (booking.isMultiDay && booking.bookingGroupId != null) {
      final groupAsync = ref.watch(bookingGroupProvider(booking.bookingGroupId!));
      return groupAsync.when(
        data: (groupData) => _buildMultiDayPricing(context, strings, groupData, locale),
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.sm),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (_, __) => _buildSingleDayPricing(context, strings, profile),
      );
    }

    return _buildSingleDayPricing(context, strings, profile);
  }

  Widget _buildMultiDayPricing(BuildContext context, Map<String, String> strings, Map<String, dynamic> groupData, String locale) {
    final profile = booking.sitter?.babysitterProfile;
    final hourlyRate = profile?.hourlyRate ?? 0;
    final summary = groupData['summary'] as Map<String, dynamic>? ?? {};
    final totalAmount = (summary['total'] as num?)?.toDouble() ?? booking.totalAmount;
    final bookingsList = groupData['bookings'] as List<dynamic>? ?? [];

    final currency = strings['sar'] ?? 'SAR';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (profile != null)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  '$hourlyRate $currency/${strings['h_abbr'] ?? 'h'}',
                  style: AppTextStyles.labelSmall(weight: FontWeight.w600, color: context.primaryColor),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${strings['sessions_list'] ?? 'Sessions'}: ${bookingsList.length}',
                style: AppTextStyles.bodySmall(color: context.textSecondary),
              ),
            ],
          ),
        const SizedBox(height: AppSpacing.md),
        Text(
          strings['per_day_breakdown'] ?? 'Per-Day Breakdown',
          style: AppTextStyles.titleSmall(weight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...bookingsList.asMap().entries.map((entry) {
          final s = entry.value as Map<String, dynamic>;
          final sessionDate = s['date'] as String? ?? '';
          final parsedDate = DateTime.tryParse(sessionDate);
          final dateStr = parsedDate != null
              ? DateFormat('MMM d, yyyy', locale).format(parsedDate)
              : sessionDate;
          final st = s['startTime'] as String? ?? '';
          final et = s['endTime'] as String? ?? '';
          final dur = (s['duration'] as int?) ?? booking.duration;
          final amt = (s['totalAmount'] as num?)?.toDouble() ?? 0;
          final timeStr = BookingHelpers.formatTimeRange(st, et, locale: locale);
          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: context.surfaceColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: context.dividerColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Center(
                    child: Text(
                      '${entry.key + 1}',
                      style: AppTextStyles.labelSmall(
                        weight: FontWeight.w700,
                        color: context.primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateStr,
                        style: AppTextStyles.bodySmall(weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$timeStr ($dur ${strings['h_abbr'] ?? 'h'})',
                        style: AppTextStyles.caption(color: context.textMutedColor),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$currency ${amt.toStringAsFixed(0)}',
                  style: AppTextStyles.bodyMedium(weight: FontWeight.w700),
                ),
              ],
            ),
          );
        }),
        const Divider(height: AppSpacing.lg),
        _PricingRow(
          icon: Icons.receipt_long_rounded,
          label: strings['total_amount'] ?? 'Total',
          value: '$currency ${totalAmount.toStringAsFixed(2)}',
        ),
      ],
    );
  }

  Widget _buildSingleDayPricing(BuildContext context, Map<String, String> strings, BabysitterProfile? profile) {
    if (profile == null) {
      return _InfoRow(
        icon: Icons.receipt_outlined,
        label: strings['total'] ?? 'Total',
        value: '${booking.totalAmount.toStringAsFixed(2)} ${strings['sar'] ?? 'SAR'}',
        valueStyle: AppTextStyles.titleMedium(weight: FontWeight.w700),
      );
    }

    final hourlyRate = profile.hourlyRate;
    final includedChildren = profile.includedChildren;
    final extraChildFee = profile.extraChildFee;
    final specialNeedsRate = profile.specialNeedsRate;

    final duration = booking.duration;
    final childrenCount = booking.childrenCount ?? 1;

    final regularChildren = (childrenCount - booking.specialNeedsCount).clamp(0, 999);
    final extraRegularChildren = (regularChildren - includedChildren).clamp(0, 999);
    final baseCost = duration.toDouble() * hourlyRate;
    final extraCost = duration.toDouble() * extraRegularChildren * extraChildFee;
    final specialCost =
        duration.toDouble() * booking.specialNeedsCount * specialNeedsRate;

    final currency = strings['sar'] ?? 'SAR';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                '$hourlyRate $currency/${strings['h_abbr'] ?? 'h'}',
                style: AppTextStyles.labelSmall(weight: FontWeight.w600, color: context.primaryColor),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${strings['duration'] ?? 'Duration'}: $duration ${strings['h_abbr'] ?? 'h'}',
              style: AppTextStyles.bodySmall(color: context.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _PricingRow(
          icon: Icons.child_care_rounded,
          label: '${strings['base_rate'] ?? 'Base rate'} ($includedChildren ${strings['children'] ?? 'children'})',
          value: '$currency ${baseCost.toStringAsFixed(2)}',
        ),
        if (extraRegularChildren > 0) ...[
          const SizedBox(height: AppSpacing.xxs),
          _PricingRow(
            icon: Icons.add_circle_outline_rounded,
            label: '$extraRegularChildren ${strings['additional'] ?? 'additional'} × $extraChildFee $currency/${strings['h_abbr'] ?? 'h'}',
            value: '$currency ${extraCost.toStringAsFixed(2)}',
            color: AppColors.warning,
          ),
        ],
        if (booking.specialNeedsCount > 0) ...[
          const SizedBox(height: AppSpacing.xxs),
          _PricingRow(
            icon: Icons.medical_services_outlined,
            label: '${booking.specialNeedsCount} ${strings['special_needs'] ?? 'special needs'} × $specialNeedsRate $currency/${strings['h_abbr'] ?? 'h'}',
            value: '$currency ${specialCost.toStringAsFixed(2)}',
            color: AppColors.error,
          ),
        ],
        const Divider(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(strings['total'] ?? 'Total', style: AppTextStyles.titleMedium(weight: FontWeight.bold)),
            Text(
              '$currency ${booking.totalAmount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PricingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _PricingRow({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color ?? context.textMutedColor),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(label,
            style: AppTextStyles.bodySmall(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(value,
          style: AppTextStyles.bodyMedium(weight: FontWeight.w500, color: color),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.primaryColor.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: context.primaryColor),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                label,
                style: AppTextStyles.labelSmall(
                  weight: FontWeight.w600,
                  color: context.primaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


