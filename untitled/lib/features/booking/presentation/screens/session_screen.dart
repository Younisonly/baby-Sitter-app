import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/theme_colors.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/features/booking/data/booking_provider.dart';
import 'package:babysitter/features/booking/data/session_repository.dart';
import 'package:babysitter/features/booking/data/session_location_provider.dart';
import 'package:babysitter/core/services/auth_provider.dart';
import 'package:babysitter/shared/models/booking_model.dart';
import 'package:babysitter/core/utils/time_formatter.dart';
import 'package:babysitter/shared/widgets/widgets.dart';

class SessionScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const SessionScreen({super.key, required this.bookingId});

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  Timer? _timer;
  Timer? _pollTimer;
  int _elapsedSeconds = 0;
  bool _hasShownWelcome = false;
  bool _hasWarned20Min = false;
  bool _hasWarnedEnd = false;
  bool _hasAutoStartedTracking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasShownWelcome) {
        _hasShownWelcome = true;
        final pending = ref.read(pendingSessionSnackProvider);
        if (pending == 'session_started') {
          final strings = AppLocalization.get(ref.read(languageProvider).code);
          AppSnackbar.success(
            context,
            strings['session_started_success'] ?? 'Session started successfully!',
          );
          ref.read(pendingSessionSnackProvider.notifier).state = null;
        }
      }
    });
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) return;
      ref.invalidate(bookingDetailProvider(widget.bookingId));
      ref.invalidate(latestTrackingProvider(widget.bookingId));
    });
  }
  void _startTimerFrom(DateTime? sessionStartedAt) {
    if (sessionStartedAt != null) {
      _elapsedSeconds = DateTime.now().difference(sessionStartedAt).inSeconds;
    }
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds++;
        _checkAlarms();
      });
    });
  }

  void _checkAlarms() {
    final booking = ref.read(bookingDetailProvider(widget.bookingId)).valueOrNull;
    if (booking == null || !booking.isSessionActive) return;

    final expectedSecs = (booking.duration * 3600).round();
    final remainingSecs = expectedSecs - _elapsedSeconds;

    if (remainingSecs <= 1200 && remainingSecs > 0 && !_hasWarned20Min) {
      _hasWarned20Min = true;
      _triggerAlarm('session_ending_soon', 'Session ending in ${remainingSecs ~/ 60} minutes');
    }

    if (remainingSecs <= 0 && !_hasWarnedEnd) {
      _hasWarnedEnd = true;
      _triggerAlarm('overtime_started', 'Session time is up! Overtime started.');
    }
  }

  void _triggerAlarm(String titleKey, String defaultMsg) {
    HapticFeedback.mediumImpact();
    final strings = AppLocalization.get(ref.read(languageProvider).code);
    AppSnackbar.show(
      context,
      message: strings[titleKey] ?? defaultMsg,
      title: strings['session_alert'] ?? 'Session Alert',
      duration: const Duration(seconds: 5),
      type: SnackbarType.warning,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final bookingAsync = ref.watch(bookingDetailProvider(widget.bookingId));

    ref.listen(bookingDetailProvider(widget.bookingId), (prev, next) {
      if (!mounted) return;
      final prevBooking = prev?.valueOrNull;
      final nextBooking = next.valueOrNull;
      if (prevBooking != null && nextBooking != null &&
          prevBooking.status == BookingStatus.confirmed &&
          nextBooking.status == BookingStatus.inProgress) {
        ref.read(bookingActionProvider)(
          widget.bookingId,
          () async => nextBooking,
        );
      }
    });

    return Scaffold(
      appBar: AppAppBar(
        titleWidget: bookingAsync.whenOrNull(
          data: (booking) {
            final isActive = booking.isSessionActive;
            final isComplete = booking.isSessionCompleted;
            final statusColor = isComplete ? context.textMutedColor : (isActive ? AppColors.success : AppColors.warning);
            final statusLabel = isComplete
                ? (strings['session_completed'] ?? 'Completed')
                : (isActive
                    ? (strings['active'] ?? 'Active')
                    : (strings['inactive'] ?? 'Inactive'));
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isActive ? Icons.circle_rounded : Icons.check_circle_rounded, size: 10, color: statusColor),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  isComplete
                      ? (strings['session_completed'] ?? 'Session Completed')
                      : (strings['live_session'] ?? 'Live Session'),
                  style: AppTextStyles.bodySmall(
                    color: statusColor,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  statusLabel,
                  style: AppTextStyles.caption(
                    color: statusColor,
                    weight: FontWeight.w500,
                  ),
                ),
              ],
            );
          },
        ) ?? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(strings['live_session'] ?? 'Live Session'),
          ],
        ),
        showBackButton: true,
      ),
      body: bookingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AppErrorState(
          title: strings['load_error_title'] ?? 'Error',
          message: strings['load_error_desc'] ?? 'Failed to load session',
          onRetry: () => ref.invalidate(bookingDetailProvider(widget.bookingId)),
        ),
        data: (booking) => _buildSessionUI(booking, strings),
      ),
    );
  }

  Widget _buildSessionUI(BookingModel booking, Map<String, String> strings) {
    final isSitter = booking.sitterId ==
        ref.read(authProvider).user?.id.toString();
    final isActive = booking.isSessionActive;
    final isComplete = booking.isSessionCompleted;

    if (isActive && _elapsedSeconds == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startTimerFrom(booking.sessionStartedAt);
      });
    } else if (!isActive && _timer != null) {
      _timer?.cancel();
      _timer = null;
    }

    if (isSitter && isActive && !_hasAutoStartedTracking) {
      _hasAutoStartedTracking = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(sessionLocationProvider(booking.id).notifier).startTracking();
      });
    }

    final expectedSecs = booking.duration * 3600;
    final remainingSecs = expectedSecs - _elapsedSeconds;
    final isNearEnd = remainingSecs > 0 && remainingSecs <= 1200;
    final isOvertime = _elapsedSeconds > expectedSecs;

    final isMultiDay = booking.isMultiDay;
    final groupAsync = isMultiDay && booking.bookingGroupId != null
        ? ref.watch(bookingGroupProvider(booking.bookingGroupId!))
        : null;

    int? dayIndex;
    int? totalDays;
    int? doneCount;
    String? nextSessionId;
    if (groupAsync != null) {
      final groupData = groupAsync.valueOrNull;
      if (groupData != null) {
        final groupBookings = groupData['bookings'] as List<dynamic>? ?? [];
        final summary = groupData['summary'] as Map<String, dynamic>? ?? {};
        totalDays = summary['count'] as int? ?? groupBookings.length;
        doneCount = groupBookings.where((s) {
          final st = (s as Map<String, dynamic>)['status'] as String? ?? '';
          return !['pending', 'confirmed'].contains(st);
        }).length;
        final sorted = List<Map<String, dynamic>>.from(groupBookings)
          ..sort((a, b) {
            final da = DateTime.tryParse(a['date'] as String? ?? '');
            final db = DateTime.tryParse(b['date'] as String? ?? '');
            if (da != null && db != null) return da.compareTo(db);
            return 0;
          });
        dayIndex = sorted.indexWhere((s) => '${s['id']}' == booking.id);
        if (dayIndex == -1) dayIndex = 0;
        for (final s in sorted) {
          final idx = sorted.indexOf(s);
          if (idx > dayIndex) {
            final sId = '${s['id']}';
            final sStatus = s['status'] as String? ?? '';
            if (sStatus == 'confirmed' || sStatus == 'pending') {
              nextSessionId = sId;
              break;
            }
          }
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          if (isMultiDay && totalDays != null && dayIndex != null)
            _DayProgressIndicator(
              currentDay: dayIndex + 1,
              totalDays: totalDays,
              doneCount: doneCount ?? 0,
              strings: strings,
            ),
          const SizedBox(height: AppSpacing.md),
          _TimerCard(
            elapsedSeconds: _elapsedSeconds,
            expectedSeconds: expectedSecs,
            remainingSeconds: remainingSecs,
            isNearEnd: isNearEnd,
            isOvertime: isOvertime,
            formatDuration: _formatDuration,
          ),
          const SizedBox(height: AppSpacing.md),
          _SessionInfoBar(booking: booking, strings: strings),
          const SizedBox(height: AppSpacing.lg),

          if (isActive) ...[
            if (booking.isOutOfSchedule) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 16, color: AppColors.warning),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        strings['out_of_schedule_session_banner'] ??
                            'This session started outside the scheduled hours',
                        style: AppTextStyles.caption(
                          color: AppColors.warning,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            _ActiveSessionCard(booking: booking, strings: strings, isSitter: isSitter),
            const SizedBox(height: AppSpacing.md),
            if (isSitter)
              _SitterActiveActions(booking: booking, strings: strings)
            else
              _ParentActiveActions(booking: booking, strings: strings),
          ] else if (isComplete) ...[
            _CompletedSessionCard(booking: booking, strings: strings),
            if (isMultiDay && nextSessionId != null) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: strings['next_session'] ?? 'Next Session',
                  onPressed: () {
                    context.pushReplacement('/booking/$nextSessionId/session');
                  },
                  variant: AppButtonVariant.filled,
                  suffixIcon: const Icon(Icons.arrow_forward_rounded, size: 18),
                ),
              ),
            ],
          ] else ...[
            _PreSessionCard(booking: booking, isSitter: isSitter, strings: strings),
          ],

          const SizedBox(height: AppSpacing.lg),

          if (!isComplete && !isActive) ...[
            _SessionActionButtons(booking: booking, isSitter: isSitter, strings: strings),
          ],
        ],
      ),
    );
  }
}

class _DayProgressIndicator extends StatelessWidget {
  final int currentDay;
  final int totalDays;
  final int doneCount;
  final Map<String, String> strings;

  const _DayProgressIndicator({
    required this.currentDay,
    required this.totalDays,
    required this.doneCount,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalDays > 0 ? doneCount / totalDays : 0.0;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.primaryColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.date_range_rounded, size: 16, color: context.primaryColor),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${strings['day'] ?? 'Day'} $currentDay / $totalDays',
                style: AppTextStyles.bodyMedium(
                  weight: FontWeight.w600,
                  color: context.primaryColor,
                ),
              ),
              const Spacer(),
              Text(
                '$doneCount/$totalDays',
                style: AppTextStyles.caption(color: context.textMutedColor),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: context.primaryColor.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionInfoBar extends ConsumerWidget {
  final BookingModel booking;
  final Map<String, String> strings;

  const _SessionInfoBar({required this.booking, required this.strings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider).code;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.dividerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.receipt_long_rounded, size: 14, color: context.textMutedColor),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '#${booking.id}',
            style: AppTextStyles.bodySmall(
              color: context.textMutedColor,
              weight: FontWeight.w600,
            ),
          ),
          Container(
            width: 3, height: 3,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              color: context.textMutedColor,
              shape: BoxShape.circle,
            ),
          ),
          Icon(Icons.schedule_rounded, size: 13, color: context.textMutedColor),
          const SizedBox(width: 3),
          Text(
            TimeFormatter.formatTimeRange(booking.startTime, booking.endTime, locale),
            style: AppTextStyles.bodySmall(
              color: context.textMutedColor,
            ),
          ),
          Container(
            width: 3, height: 3,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              color: context.textMutedColor,
              shape: BoxShape.circle,
            ),
          ),
          Icon(Icons.calendar_today_rounded, size: 12, color: context.textMutedColor),
          const SizedBox(width: 3),
          Text(
            DateFormat('MMM d', ref.watch(languageProvider).code).format(booking.date),
            style: AppTextStyles.bodySmall(color: context.textMutedColor),
          ),
        ],
      ),
    );
  }
}

class _TimerCard extends ConsumerWidget {
  final int elapsedSeconds;
  final int expectedSeconds;
  final int remainingSeconds;
  final bool isNearEnd;
  final bool isOvertime;
  final String Function(int) formatDuration;

  const _TimerCard({
    required this.elapsedSeconds,
    required this.expectedSeconds,
    required this.remainingSeconds,
    required this.isNearEnd,
    required this.isOvertime,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final timerColor = isOvertime
        ? AppColors.error
        : isNearEnd
            ? AppColors.warning
            : AppColors.success;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            timerColor.withValues(alpha: 0.1),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: timerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            formatDuration(elapsedSeconds),
            style: TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w300,
              color: timerColor,
              letterSpacing: 4,
              height: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                strings['booked'] ?? 'Booked',
                style: AppTextStyles.caption(
                  color: context.textSecondaryColor,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                _formatShort(expectedSeconds, strings),
                style: AppTextStyles.caption(
                  color: context.textSecondaryColor,
                  weight: FontWeight.w600,
                ),
              ),
              if (isOvertime) ...[
                Container(
                  width: 3, height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: context.textSecondaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${strings['overtime'] ?? 'Overtime'} ${_formatDuration(remainingSeconds.abs(), strings)}',
                    style: AppTextStyles.caption(
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ] else if (remainingSeconds >= 0) ...[
                Container(
                  width: 3, height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: context.textSecondaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Text(
                  strings['remaining'] ?? 'Remaining',
                  style: AppTextStyles.caption(
                    color: context.textSecondaryColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  _formatShort(remainingSeconds, strings),
                  style: AppTextStyles.caption(
                    color: isNearEnd ? AppColors.warning : timerColor,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isOvertime)
                _Badge(
                  label: strings['overtime_badge'] ?? 'Overtime',
                  color: AppColors.error,
                ),
              if (isNearEnd && !isOvertime)
                _Badge(
                  label: strings['ending_soon'] ?? 'Ending Soon',
                  color: AppColors.warning,
                ),
              if (!isOvertime && !isNearEnd && expectedSeconds > 0)
                _Badge(
                  label: strings['on_track'] ?? 'On Track',
                  color: AppColors.success,
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatShort(int seconds, Map<String, String> strings) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final hAbbr = strings['h_abbr'] ?? 'h';
    final mAbbr = strings['m_abbr'] ?? 'm';
    if (h > 0) return '$h$hAbbr $m$mAbbr';
    return '$m$mAbbr';
  }

  String _formatDuration(int seconds, Map<String, String> strings) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    final hAbbr = strings['h_abbr'] ?? 'h';
    final mAbbr = strings['m_abbr'] ?? 'm';
    final sAbbr = strings['s_abbr'] ?? 's';
    if (h > 0) return '$h$hAbbr $m$mAbbr $s$sAbbr';
    return '$m$mAbbr $s$sAbbr';
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall(
          color: color,
          weight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ActiveSessionCard extends ConsumerWidget {
  final BookingModel booking;
  final Map<String, String> strings;
  final bool isSitter;

  const _ActiveSessionCard({
    required this.booking,
    required this.strings,
    required this.isSitter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider).code;
    final trackingState = ref.watch(sessionLocationProvider(booking.id));
    final loc = booking.latestLocation;
    final hasLocation = loc != null;
    final sessionStarted = booking.sessionStartedAt;
    final elapsed = sessionStarted != null
        ? DateTime.now().difference(sessionStarted)
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                strings['session_active'] ?? 'Session Active',
                style: AppTextStyles.titleSmall(
                  weight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
              const Spacer(),
              Text(
                '#${booking.id}',
                style: AppTextStyles.labelSmall(
                  color: context.textMutedColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(
            icon: Icons.person_outline,
            label: strings['sitter_label'] ?? 'Sitter',
            value: booking.sitter?.name ?? '—',
          ),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(
            icon: Icons.schedule_rounded,
            label: strings['time'] ?? 'Time',
            value: TimeFormatter.formatTimeRange(booking.startTime, booking.endTime, locale),
          ),
          if (sessionStarted != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(
              icon: Icons.play_arrow_rounded,
              label: strings['session_started_at'] ?? 'Started',
              value: DateFormat('HH:mm', locale).format(sessionStarted),
            ),
            if (elapsed != null) ...[
              const SizedBox(height: AppSpacing.xs),
              _InfoRow(
                icon: Icons.timer_outlined,
                label: strings['session_duration'] ?? 'Elapsed',
                value: _formatDurationShort(elapsed),
              ),
            ],
          ],
          const SizedBox(height: AppSpacing.sm),
          if (isSitter)
            _buildSitterLocationStatus(context, ref, trackingState, hasLocation)
          else
            _buildParentLocationSection(context, ref, booking),
          if (hasLocation) ...[
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(
              icon: Icons.gps_fixed,
              label: strings['gps_label'] ?? 'GPS',
              value: '${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}',
            ),
            if (loc.recordedAt != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              _InfoRow(
                icon: Icons.access_time_rounded,
                label: strings['last_updated'] ?? 'Recorded',
                value: _formatRelativeTime(loc.recordedAt!, locale),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _formatDurationShort(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final hAbbr = strings['h_abbr'] ?? 'h';
    final mAbbr = strings['m_abbr'] ?? 'm';
    if (h > 0) return '$h$hAbbr $m$mAbbr';
    return '$m$mAbbr';
  }

  String _formatRelativeTime(DateTime dt, String locale) {
    final diff = DateTime.now().difference(dt);
    final strings = AppLocalization.get(locale);
    if (diff.inSeconds < 60) return strings['now'] ?? 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} ${strings['min_ago'] ?? 'min ago'}';
    if (diff.inHours < 24) return '${diff.inHours} ${strings['hours_ago'] ?? 'h ago'}';
    return DateFormat('MMM d HH:mm', locale).format(dt);
  }

  Widget _buildSitterLocationStatus(BuildContext context, WidgetRef ref, LocationTrackingState trackingState, bool hasLocation) {
    final isActive = trackingState == LocationTrackingState.active;
    final isDisabled = trackingState == LocationTrackingState.disabled;
    final isStopped = trackingState == LocationTrackingState.stopped;
    final isIdle = trackingState == LocationTrackingState.inactive || trackingState == LocationTrackingState.requesting;
    final notifier = ref.read(sessionLocationProvider(booking.id).notifier);

    if (isActive) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.gps_fixed, size: 16, color: AppColors.success),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    strings['tracking_enabled'] ?? 'Location tracking active',
                    style: AppTextStyles.bodySmall(
                      color: AppColors.success,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final sent = await notifier.sendCurrentPosition();
                  if (context.mounted && sent) {
                    ref.invalidate(latestTrackingProvider(booking.id));
                    ref.invalidate(bookingDetailProvider(booking.id));
                    AppSnackbar.success(
                      context,
                      strings['location_updated'] ?? 'Location updated',
                    );
                  }
                },
                icon: Icon(Icons.my_location_rounded, size: 16, color: AppColors.success),
                label: Text(strings['update_location'] ?? 'Update Location'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.success,
                  side: BorderSide(color: AppColors.success.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.gps_off, size: 16,
                color: isStopped ? AppColors.warning : AppColors.warning),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  isStopped
                      ? (strings['tracking_stopped'] ?? 'Location sharing stopped')
                      : (strings['tracking_disabled'] ?? 'Location tracking disabled'),
                  style: AppTextStyles.bodySmall(
                    color: AppColors.warning,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (isDisabled || isIdle) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              strings['location_gps_desc_short'] ?? 'Enable GPS to share your location',
              style: AppTextStyles.caption(
                color: AppColors.warning.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showInAppLocationPrompt(context, strings, notifier),
                icon: Icon(Icons.gps_fixed, size: 16, color: AppColors.warning),
                label: Text(strings['enable_gps'] ?? 'Enable Location'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warning,
                  side: BorderSide(color: AppColors.warning.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () async {
                  final success = await notifier.recheck();
                  if (context.mounted && success) {
                    // tracking started — provider state will update UI automatically
                  }
                },
                icon: Icon(Icons.refresh_rounded, size: 14,
                    color: AppColors.warning.withValues(alpha: 0.7)),
                label: Text(
                  strings['recheck'] ?? 'Recheck',
                  style: AppTextStyles.caption(color: AppColors.warning.withValues(alpha: 0.7)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParentLocationSection(BuildContext context, WidgetRef ref, BookingModel booking) {
    final trackingPoint = ref.watch(latestTrackingProvider(booking.id)).valueOrNull;
    final hasAny = trackingPoint?.recordedAt != null;
    final isTrackingStopped = booking.gpsEndedAt != null;
    final lastRefreshTime = ref.watch(lastLocationRefreshProvider(booking.id));

    final Color statusColor;
    final String statusLabel;
    final Color indicatorColor;

    if (isTrackingStopped) {
      statusColor = AppColors.warning;
      statusLabel = strings['tracking_stopped'] ?? 'Stopped';
      indicatorColor = AppColors.warning;
    } else if (hasAny) {
      statusColor = AppColors.success;
      statusLabel = strings['active'] ?? 'Active';
      indicatorColor = AppColors.success;
    } else {
      statusColor = context.textMutedColor;
      statusLabel = strings['no_location_yet'] ?? 'No location yet';
      indicatorColor = context.textMutedColor;
    }

    final locale = ref.watch(languageProvider).code;

    return GestureDetector(
      onTap: () => _fetchAndShowLocation(context, ref, booking.id, gpsEndedAt: booking.gpsEndedAt),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.info.withValues(alpha: 0.15)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.location_on_rounded, size: 16, color: AppColors.info),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    strings['live_location'] ?? 'Live Location',
                    style: AppTextStyles.bodySmall(
                      color: AppColors.info,
                      weight: FontWeight.w600,
                    ),
                  ),
                  if (lastRefreshTime != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${strings['last_updated'] ?? 'Last Updated'} ${TimeFormatter.formatRelativeTime(lastRefreshTime, locale)}',
                      style: AppTextStyles.caption(
                        color: AppColors.success.withValues(alpha: 0.7),
                        weight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: indicatorColor,
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              statusLabel,
              style: AppTextStyles.caption(
                color: statusColor,
                weight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.info.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }

  void _showInAppLocationPrompt(BuildContext context, Map<String, String> strings, SessionLocationNotifier notifier) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).cardColor,
      builder: (ctx) {
        var stillOff = false;
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.gps_off_rounded, size: 36, color: AppColors.info),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  strings['location_gps_title'] ?? 'Enable Location',
                  style: AppTextStyles.titleLarge(weight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  stillOff
                      ? (strings['location_still_off'] ??
                          'Location is still off. Please turn on GPS from Quick Settings and tap Recheck.')
                      : (strings['location_gps_desc'] ??
                          'GPS is turned off. Please enable it from Quick Settings to share your location.'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    text: strings['recheck'] ?? 'Recheck',
                    onPressed: () async {
                      final success = await notifier.recheck();
                      if (ctx.mounted) {
                        if (success) {
                          Navigator.pop(ctx);
                        } else {
                          setSheetState(() => stillOff = true);
                        }
                      }
                    },
                    variant: AppButtonVariant.filled,
                    prefixIcon: const Icon(Icons.refresh_rounded, size: 18),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    text: strings['cancel'] ?? 'Cancel',
                    onPressed: () => Navigator.pop(ctx),
                    variant: AppButtonVariant.outlined,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _fetchAndShowLocation(BuildContext context, WidgetRef ref, String bookingId, {DateTime? gpsEndedAt}) async {
    final isTrackingStopped = gpsEndedAt != null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).cardColor,
      builder: (ctx) => _LocationSheetContent(
        bookingId: bookingId,
        isTrackingStopped: isTrackingStopped,
      ),
    );
  }
}

class _LocationSheetContent extends ConsumerStatefulWidget {
  final String bookingId;
  final bool isTrackingStopped;

  const _LocationSheetContent({
    required this.bookingId,
    required this.isTrackingStopped,
  });

  @override
  ConsumerState<_LocationSheetContent> createState() => _LocationSheetContentState();
}

class _LocationSheetContentState extends ConsumerState<_LocationSheetContent> {
  Timer? _agoTimer;
  bool _isRefreshing = false;
  bool _refreshFailed = false;
  bool _justRefreshed = false;
  LocationPoint? _displayedLoc;

  @override
  void initState() {
    super.initState();
    _startAgoTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.invalidate(latestTrackingProvider(widget.bookingId));
      }
    });
  }

  @override
  void dispose() {
    _agoTimer?.cancel();
    super.dispose();
  }

  void _startAgoTimer() {
    _agoTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
      _refreshFailed = false;
    });
    try {
      final repo = ref.read(sessionRepositoryProvider);
      final newLoc = await repo.refreshTracking(widget.bookingId);
      if (!mounted) return;
      setState(() {
        _displayedLoc = newLoc;
        _isRefreshing = false;
        _justRefreshed = true;
      });

      ref.invalidate(latestTrackingProvider(widget.bookingId));
      ref.invalidate(bookingDetailProvider(widget.bookingId));
      ref.read(lastLocationRefreshProvider(widget.bookingId).notifier).state = DateTime.now();

      Future.delayed(const Duration(seconds: 8), () {
        if (mounted) setState(() => _justRefreshed = false);
      });
    } catch (_) {
      // Fallback: fetch latest tracking if refresh endpoint fails
      try {
        final repo = ref.read(sessionRepositoryProvider);
        final trackingData = await repo.getTracking(widget.bookingId, limit: 1);
        if (!mounted) return;
        final fallbackLoc = trackingData.tracking.isNotEmpty
            ? trackingData.tracking.first
            : trackingData.latest;
        if (!mounted) return;
        setState(() {
          _displayedLoc = fallbackLoc;
          _isRefreshing = false;
          _justRefreshed = true;
        });
        ref.invalidate(latestTrackingProvider(widget.bookingId));
        ref.invalidate(bookingDetailProvider(widget.bookingId));
        ref.read(lastLocationRefreshProvider(widget.bookingId).notifier).state = DateTime.now();
        Future.delayed(const Duration(seconds: 8), () {
          if (mounted) setState(() => _justRefreshed = false);
        });
      } catch (_) {
        if (mounted) {
          setState(() {
            _refreshFailed = true;
            _isRefreshing = false;
          });
        }
      }
    }
  }

  String _formatRelativeTime(DateTime dt, String locale) {
    final diff = DateTime.now().difference(dt);
    final strings = AppLocalization.get(locale);
    if (diff.inSeconds < 60) return strings['now'] ?? 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} ${strings['min_ago'] ?? 'min ago'}';
    if (diff.inHours < 24) return '${diff.inHours} ${strings['hours_ago'] ?? 'h ago'}';
    return DateFormat('MMM d HH:mm', locale).format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final locale = ref.watch(languageProvider).code;
    final trackingAsync = ref.watch(latestTrackingProvider(widget.bookingId));
    final lastRefreshTime = ref.watch(lastLocationRefreshProvider(widget.bookingId));

    // Keep _displayedLoc in sync with provider data
    // Always update when provider returns fresh data (handles dialog reopen + invalidation)
    if (trackingAsync.valueOrNull != null) {
      _displayedLoc = trackingAsync.valueOrNull;
    }
    final loc = _displayedLoc;
    final hasLocation = loc != null;

    final canRefresh = !_isRefreshing;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height * 0.4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: widget.isTrackingStopped
                          ? AppColors.warning.withValues(alpha: 0.1)
                          : AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      widget.isTrackingStopped ? Icons.gps_off_rounded : Icons.map_rounded,
                      size: 20,
                      color: widget.isTrackingStopped ? AppColors.warning : AppColors.info,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      widget.isTrackingStopped
                          ? (strings['sitter_stopped_sharing'] ?? 'Sitter stopped sharing')
                          : (strings['live_location'] ?? 'Live Location'),
                      style: AppTextStyles.titleMedium(weight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (hasLocation) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: widget.isTrackingStopped
                        ? AppColors.warning.withValues(alpha: 0.05)
                        : AppColors.surfaceDark.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 36,
                        color: (widget.isTrackingStopped ? AppColors.warning : AppColors.info).withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                      ),
                      if (_justRefreshed) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 13, color: AppColors.success),
                            const SizedBox(width: AppSpacing.xxs),
                            Text(
                              strings['updated_just_now'] ?? 'Updated just now',
                              style: AppTextStyles.caption(
                                color: AppColors.success,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ] else if (lastRefreshTime != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${strings['last_updated'] ?? 'Last Updated'} ${_formatRelativeTime(lastRefreshTime, locale)}',
                          style: AppTextStyles.caption(
                            color: AppColors.success,
                            weight: FontWeight.w500,
                          ),
                        ),
                        if (loc.recordedAt != null) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            '${strings['recorded'] ?? 'Recorded'} ${_formatRelativeTime(loc.recordedAt!, locale)}',
                            style: AppTextStyles.caption(
                              color: context.textMutedColor,
                            ),
                          ),
                        ],
                      ] else if (loc.recordedAt != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${strings['recorded'] ?? 'Recorded'} ${_formatRelativeTime(loc.recordedAt!, locale)}',
                          style: AppTextStyles.caption(
                            color: widget.isTrackingStopped
                                ? AppColors.warning
                                : context.textMutedColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (loc.address != null && loc.address!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    loc.address!,
                    style: AppTextStyles.bodySmall(color: context.textSecondaryColor),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    text: strings['open_in_maps'] ?? 'Open in Maps',
                    onPressed: () {
                      Navigator.pop(context);
                      final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${loc.latitude},${loc.longitude}');
                      launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    variant: AppButtonVariant.outlined,
                    prefixIcon: const Icon(Icons.map_rounded, size: 18),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    text: strings['refresh'] ?? 'Refresh',
                    onPressed: canRefresh ? _refresh : null,
                    isLoading: _isRefreshing,
                    variant: AppButtonVariant.filled,
                    prefixIcon: const Icon(Icons.refresh_rounded, size: 18),
                  ),
                ),
                if (_refreshFailed) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    strings['refresh_failed'] ?? 'Refresh failed. Showing last known data.',
                    style: AppTextStyles.caption(color: AppColors.warning),
                    textAlign: TextAlign.center,
                  ),
                ],
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.location_off_rounded, size: 36,
                          color: AppColors.warning.withValues(alpha: 0.5)),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        strings['location_not_available'] ?? 'No location data available yet',
                        style: AppTextStyles.bodyMedium(color: context.textSecondaryColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          text: strings['refresh'] ?? 'Refresh',
                          onPressed: canRefresh ? _refresh : null,
                          isLoading: _isRefreshing,
                          variant: AppButtonVariant.filled,
                          prefixIcon: const Icon(Icons.refresh_rounded, size: 18),
                        ),
                      ),
                      if (_refreshFailed) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          strings['refresh_failed'] ?? 'Refresh failed. Please try again.',
                          style: AppTextStyles.caption(color: AppColors.warning),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: strings['got_it'] ?? 'Got it',
                  onPressed: () => Navigator.pop(context),
                  variant: widget.isTrackingStopped ? AppButtonVariant.filled : AppButtonVariant.outlined,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SitterActiveActions extends ConsumerWidget {
  final BookingModel booking;
  final Map<String, String> strings;

  const _SitterActiveActions({
    required this.booking,
    required this.strings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEndQrReady = booking.sessionStatus == SessionStatus.endQrGenerated;
    return _ActionsGrid(
      booking: booking,
      strings: strings,
      isSitter: true,
      primaryLabel: isEndQrReady
          ? (strings['view_end_qr'] ?? 'Show End QR')
          : (strings['generate_end_qr'] ?? 'End Session'),
      primaryIcon: isEndQrReady ? Icons.qr_code_2_rounded : Icons.stop_rounded,
      primaryOnTap: () {
        context.push('/booking/${booking.id}/session/qr-end');
      },
      primaryReady: true,
      primaryColor: AppColors.error,
    );
  }
}

class _ParentActiveActions extends ConsumerWidget {
  final BookingModel booking;
  final Map<String, String> strings;

  const _ParentActiveActions({
    required this.booking,
    required this.strings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasEndQr = booking.sessionStatus == SessionStatus.endQrGenerated;
    return _ActionsGrid(
      booking: booking,
      strings: strings,
      isSitter: false,
      primaryLabel: hasEndQr
          ? (strings['scan_end_qr'] ?? 'Scan End QR')
          : (strings['end_session'] ?? 'End Session'),
      primaryIcon: hasEndQr ? Icons.qr_code_scanner_rounded : Icons.stop_rounded,
      primaryOnTap: hasEndQr
          ? () => context.push('/booking/${booking.id}/session/scan-end')
          : null,
      primaryReady: hasEndQr,
      primaryColor: AppColors.error,
    );
  }
}

class _ActionsGrid extends ConsumerWidget {
  final BookingModel booking;
  final Map<String, String> strings;
  final bool isSitter;
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback? primaryOnTap;
  final bool primaryReady;
  final Color primaryColor;

  const _ActionsGrid({
    required this.booking,
    required this.strings,
    required this.isSitter,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.primaryOnTap,
    required this.primaryReady,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatUserId = isSitter ? booking.customerId : booking.sitterId;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: context.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings['session_actions'] ?? 'Session Actions',
            style: AppTextStyles.titleSmall(weight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (isSitter)
            _buildSitterActions(context, ref, chatUserId)
          else
            _buildParentActions(context, ref, chatUserId),
        ],
      ),
    );
  }

  Widget _buildSitterActions(BuildContext context, WidgetRef ref, String? chatUserId) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _ActionButton(
              icon: primaryIcon,
              label: primaryLabel,
              color: primaryColor,
              onTap: primaryReady ? primaryOnTap : null,
              isPrimary: true,
              badge: primaryReady ? null : (strings['end_session_disabled'] ?? 'Waiting'),
            )),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: _ActionButton(
              icon: Icons.warning_rounded,
              label: strings['session_emergency'] ?? 'Emergency',
              color: AppColors.error,
              onTap: () => _showEmergencySheet(context, strings),
            )),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(child: _ActionButton(
              icon: Icons.shield_rounded,
              label: strings['force_end_session'] ?? 'Force End',
              color: AppColors.error,
              onTap: () => _showForceEndSheet(context, ref, booking.id, strings, isSitter: true),
            )),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: _ActionButton(
              icon: Icons.headset_mic_rounded,
              label: strings['contact_support'] ?? 'Support',
              color: context.primaryColor,
              onTap: () => context.push('/support'),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildParentActions(BuildContext context, WidgetRef ref, String? chatUserId) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _ActionButton(
              icon: Icons.chat_rounded,
              label: strings['chat'] ?? 'Chat',
              color: context.primaryColor,
              onTap: chatUserId != null ? () => context.push('/chat?userId=$chatUserId&bookingId=${booking.id}') : null,
            )),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: _ActionButton(
              icon: primaryIcon,
              label: primaryLabel,
              color: primaryColor,
              onTap: primaryReady ? primaryOnTap : null,
              isPrimary: true,
              badge: primaryReady ? null : (strings['end_session_disabled'] ?? 'Waiting'),
            )),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(child: _ActionButton(
              icon: Icons.warning_rounded,
              label: strings['session_emergency'] ?? 'Emergency',
              color: AppColors.error,
              onTap: () => _showEmergencySheet(context, strings),
            )),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: _ActionButton(
              icon: Icons.headset_mic_rounded,
              label: strings['contact_support'] ?? 'Support',
              color: context.primaryColor,
              onTap: () => context.push('/support'),
            )),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: _ActionButton(
            icon: Icons.stop_circle_rounded,
            label: strings['force_end_session'] ?? 'Force End Session',
            color: AppColors.error.withValues(alpha: 0.7),
            onTap: () => _showForceEndSheet(context, ref, booking.id, strings, isSitter: false),
            fullWidth: true,
          ),
        ),
      ],
    );
  }
}

  void _showEmergencySheet(BuildContext context, Map<String, String> strings) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).cardColor,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emergency_rounded, size: 40, color: AppColors.white),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                strings['session_emergency'] ?? 'Emergency',
                style: AppTextStyles.titleLarge(weight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                strings['session_emergency_desc'] ??
                    'If this is an emergency, contact the relevant parties immediately.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: strings['session_emergency_call'] ?? 'Emergency Call',
                onPressed: () => Navigator.pop(ctx),
                variant: AppButtonVariant.filled,
                prefixIcon: const Icon(Icons.phone_rounded, size: 18),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: strings['contact_support'] ?? 'Contact Support',
                onPressed: () { Navigator.pop(ctx); context.push('/support'); },
                variant: AppButtonVariant.outlined,
                prefixIcon: const Icon(Icons.chat_rounded, size: 18),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    ),
  );
  }

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool isPrimary;
  final bool fullWidth;
  final String? badge;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.isPrimary = false,
    this.fullWidth = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final effectiveColor = disabled ? color.withValues(alpha: 0.4) : color;

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              vertical: fullWidth ? AppSpacing.md : AppSpacing.lg,
              horizontal: fullWidth ? AppSpacing.md : AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              gradient: isPrimary && !disabled
                  ? LinearGradient(
                      colors: [effectiveColor, effectiveColor.withValues(alpha: 0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isPrimary && !disabled ? null : effectiveColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: isPrimary && !disabled
                    ? Colors.transparent
                    : effectiveColor.withValues(alpha: disabled ? 0.08 : 0.2),
              ),
              boxShadow: isPrimary && !disabled
                  ? [
                      BoxShadow(
                        color: effectiveColor.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: fullWidth
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 18, color: isPrimary && !disabled ? AppColors.white : effectiveColor),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        label,
                        style: AppTextStyles.bodyMedium(
                          color: isPrimary && !disabled ? AppColors.white : effectiveColor,
                          weight: FontWeight.w600,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: effectiveColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                          ),
                          child: Text(
                            badge!,
                            style: AppTextStyles.caption(
                              color: effectiveColor,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 26,
                        color: isPrimary && !disabled ? AppColors.white : effectiveColor,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        label,
                        style: AppTextStyles.caption(
                          color: isPrimary && !disabled ? AppColors.white : effectiveColor,
                          weight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      if (badge != null) ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: effectiveColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                          ),
                          child: Text(
                            badge!,
                            style: AppTextStyles.caption(
                              color: effectiveColor,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _CompletedSessionCard extends ConsumerWidget {
  final BookingModel booking;
  final Map<String, String> strings;

  const _CompletedSessionCard({
    required this.booking,
    required this.strings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_rounded,
              size: 48, color: AppColors.success),
          const SizedBox(height: AppSpacing.md),
          Text(
            strings['session_completed'] ?? 'Session Completed',
            style: AppTextStyles.titleMedium(
              weight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (booking.actualHours > 0) ...[
            _SummaryRow(
              label: strings['actual_hours'] ?? 'Actual Hours',
              value: '${booking.actualHours.toStringAsFixed(1)} ${strings['h_abbr'] ?? 'h'}',
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          if (booking.overtimeMinutes > 0) ...[
            _SummaryRow(
              label: strings['overtime'] ?? 'Overtime',
              value: () {
                final h = booking.overtimeMinutes ~/ 60;
                final m = booking.overtimeMinutes % 60;
                final hAbbr = strings['h_abbr'] ?? 'h';
                final mAbbr = strings['m_abbr'] ?? 'm';
                if (h > 0) return '$h$hAbbr $m$mAbbr';
                return '$m$mAbbr';
              }(),
            ),
          ],
        ],
      ),
    );
  }
}

class _PreSessionCard extends ConsumerWidget {
  final BookingModel booking;
  final bool isSitter;
  final Map<String, String> strings;

  const _PreSessionCard({
    required this.booking,
    required this.isSitter,
    required this.strings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider).code;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.dividerColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings['session_info'] ?? 'Session Info',
            style: AppTextStyles.titleSmall(weight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(
            icon: Icons.calendar_today_rounded,
            label: strings['date'] ?? 'Date',
            value: '${booking.date.day}/${booking.date.month}/${booking.date.year}',
          ),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(
            icon: Icons.schedule_rounded,
            label: strings['time'] ?? 'Time',
            value: TimeFormatter.formatTimeRange(booking.startTime, booking.endTime, locale),
          ),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(
            icon: Icons.timer_outlined,
            label: strings['duration'] ?? 'Duration',
            value: '${booking.duration} ${strings['h_abbr'] ?? 'h'}',
          ),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(
            icon: Icons.person_outline,
            label: isSitter
                ? (strings['parent'] ?? 'Parent')
                : (strings['sitter_label'] ?? 'Sitter'),
            value: isSitter
                ? (booking.customer?.name ?? '—')
                : (booking.sitter?.name ?? '—'),
          ),
        ],
      ),
    );
  }
}

class _SessionActionButtons extends ConsumerWidget {
  final BookingModel booking;
  final bool isSitter;
  final Map<String, String> strings;

  const _SessionActionButtons({
    required this.booking,
    required this.isSitter,
    required this.strings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConfirmed = booking.status == BookingStatus.confirmed;
    final canShowActions = isConfirmed && !booking.isSessionActive;

    return Column(
      children: [
        if (isSitter && canShowActions) ...[
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: strings['view_start_qr'] ?? 'Show Start QR',
              onPressed: () => _onShowStartQr(context, ref, booking.id, strings),
              variant: AppButtonVariant.filled,
              prefixIcon: const Icon(Icons.qr_code_2_rounded, size: 20),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    size: 18, color: AppColors.success),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    strings['start_qr_ready'] ??
                        'QR code ready. Show it to the parent to scan.',
                    style: AppTextStyles.caption(
                        color: AppColors.success.withValues(alpha: 0.8)),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (!isSitter && canShowActions) ...[
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: strings['scan_start_qr'] ?? 'Scan to Start Session',
              onPressed: () => context.push(
                  '/booking/${booking.id}/session/scan-start'),
              variant: AppButtonVariant.filled,
              prefixIcon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.qr_code_scanner_rounded,
                    size: 18, color: AppColors.warning),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    strings['scan_info'] ??
                        'Scan the QR code shown on the sitter\'s phone to start the session.',
                    style: AppTextStyles.caption(
                        color: AppColors.warning.withValues(alpha: 0.8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _onShowStartQr(
    BuildContext context,
    WidgetRef ref,
    String bookingId,
    Map<String, String> strings,
  ) async {
    final activeSession = ref.read(activeSessionProvider).valueOrNull;
    if (activeSession != null && activeSession.id != bookingId) {
      if (!context.mounted) return;
      AppSnackbar.info(
        context,
        strings['already_active_session'] ?? 'You already have an active session',
      );
      return;
    }

    final notifier = ref.read(sessionLocationProvider(bookingId).notifier);

    final permission = await Permission.locationWhenInUse.status;

    if (!permission.isGranted) {
      final result = await Permission.locationWhenInUse.request();
      if (!result.isGranted) {
        if (context.mounted) {
          _showLocationRequiredDialog(context, strings, onRetry: () => _onShowStartQr(context, ref, bookingId, strings));
        }
        return;
      }
    }

    final gpsEnabled = await Geolocator.isLocationServiceEnabled();
    if (!gpsEnabled) {
      if (context.mounted) {
        _showLocationRequiredDialog(context, strings, isGpsOff: true);
      }
      return;
    }

    if (context.mounted) {
      await notifier.startTracking();
      if (!context.mounted) return;
      context.push('/booking/$bookingId/session/qr-start');
    }
  }

  void _showLocationRequiredDialog(
    BuildContext context,
    Map<String, String> strings, {
    bool isGpsOff = false,
    VoidCallback? onRetry,
  }) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).cardColor,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          top: AppSpacing.xl,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: (isGpsOff ? AppColors.info : AppColors.warning)
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isGpsOff ? Icons.gps_off_rounded : Icons.location_on_rounded,
                size: 36,
                color: isGpsOff ? AppColors.info : AppColors.warning,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              isGpsOff
                  ? (strings['location_gps_title'] ?? 'Enable GPS')
                  : (strings['location_required_title'] ?? 'Location Access Required'),
              style: AppTextStyles.titleLarge(weight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isGpsOff
                  ? (strings['location_gps_desc'] ??
                      'GPS is turned off. Please enable it from Quick Settings to start the session, then try again.')
                  : (strings['location_required_desc'] ??
                      'To start the session, location access is required. The sitter\'s location is tracked for safety during the session.'),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: isGpsOff
                    ? (strings['try_again_btn'] ?? 'Try Again')
                    : (strings['location_permission_btn'] ?? 'Enable Location'),
                onPressed: () async {
                  Navigator.pop(ctx);
                  if (isGpsOff) {
                    onRetry?.call();
                    return;
                  }
                  final result = await Permission.locationWhenInUse.request();
                  if (context.mounted && !result.isGranted) {
                    _showLocationRequiredDialog(context, strings, onRetry: onRetry);
                  }
                },
                variant: AppButtonVariant.filled,
                prefixIcon: Icon(
                  isGpsOff ? Icons.refresh_rounded : Icons.location_on_rounded,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: strings['cancel'] ?? 'Cancel',
                onPressed: () => Navigator.pop(ctx),
                variant: AppButtonVariant.outlined,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: context.textMutedColor),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 2,
          child: Text(label,
              style: AppTextStyles.bodySmall(color: context.textSecondaryColor)),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: AppTextStyles.bodyMedium(weight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTextStyles.bodySmall(
                color: context.textSecondaryColor)),
        Text(
          value,
          style: AppTextStyles.bodyMedium(weight: FontWeight.w600),
        ),
      ],
    );
  }
}

void _showForceEndSheet(
  BuildContext context,
  WidgetRef ref,
  String bookingId,
  Map<String, String> strings, {
  required bool isSitter,
}) {
  final controller = TextEditingController();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).cardColor,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xl,
        bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.shield_rounded,
                    size: 36, color: AppColors.error),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              strings['force_end_session'] ?? 'Force End Session',
              style: AppTextStyles.titleLarge(weight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              strings['force_end_session_subtitle'] ??
                  'This will immediately end the current session',
              style: AppTextStyles.bodySmall(color: context.textMutedColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.15)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 18, color: AppColors.warning),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      isSitter
                          ? (strings['force_end_session_desc_sitter'] ??
                              'Only use this in irregular cases: QR code not working, app crashed, technical issues, or the session stopped unexpectedly.')
                          : (strings['force_end_session_desc_parent'] ??
                              'Only use this in irregular cases: the sitter cannot complete normally, technical issues, or urgent situations.'),
                      style: AppTextStyles.caption(
                          color: AppColors.warning,
                          weight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              strings['force_end_session_reason_desc'] ??
                  'Please explain why you are force-ending this session:',
              style: AppTextStyles.bodySmall(weight: FontWeight.w500),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: context.dividerColor),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: TextField(
                controller: controller,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: strings['force_end_session_reason_hint'] ??
                      'Describe what happened...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(AppSpacing.md),
                ),
                autofocus: true,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: strings['cancel'] ?? 'Cancel',
                    onPressed: () => Navigator.pop(ctx),
                    variant: AppButtonVariant.outlined,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    text: strings['confirm_force_end'] ?? 'Yes, Force End',
                    onPressed: () {
                      final reason = controller.text.trim();
                      if (reason.isEmpty) return;
                      Navigator.pop(ctx);
                      _executeForceStop(context, ref, bookingId, reason);
                    },
                    variant: AppButtonVariant.filled,
                    backgroundColor: AppColors.error,
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

Future<void> _executeForceStop(
  BuildContext context,
  WidgetRef ref,
  String bookingId,
  String reason,
) async {
  final repo = ref.read(sessionRepositoryProvider);
  final performAction = ref.read(bookingActionProvider);

  await performAction(bookingId, () async {
    return repo.forceStop(bookingId: bookingId, reason: reason);
  });

  if (context.mounted) {
    ref.invalidate(bookingDetailProvider(bookingId)    );
  }
}
