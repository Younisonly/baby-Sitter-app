import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_config.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_shadows.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/extensions.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/routing/app_routes.dart';
import 'package:babysitter/core/services/app_provider.dart';
import 'package:babysitter/core/services/auth_provider.dart';
import 'package:babysitter/core/services/role_manager.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/features/babysitters/data/babysitter_repository.dart';
import 'package:babysitter/features/booking/data/booking_flow_notifier.dart';
import 'package:babysitter/features/booking/data/booking_provider.dart';
import 'package:babysitter/shared/widgets/widgets.dart';
import 'package:babysitter/features/booking/presentation/widgets/widgets.dart';
import 'package:intl/intl.dart';
import 'package:babysitter/features/booking/presentation/helpers/booking_helpers.dart';
import 'package:babysitter/shared/models/user_model.dart';

class BookingFlowScreen extends ConsumerStatefulWidget {
  final String sitterId;
  final String? editBookingId;
  final String? rebookFromId;
  final String? groupEditId;
  final bool forRebook;
  const BookingFlowScreen({super.key, required this.sitterId, this.editBookingId, this.rebookFromId, this.groupEditId, this.forRebook = false});

  @override
  ConsumerState<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends ConsumerState<BookingFlowScreen> {
  final _notesController = TextEditingController();
  final _specialCareController = TextEditingController();
  final List<TextEditingController> _nameControllers = [];
  final List<TextEditingController> _ageControllers = [];
  final _pageController = PageController();
  bool _controllersInitialized = false;
  bool _isMultiDayMode = false;
  BookingFlowNotifier? _flowNotifier;
  bool _shouldPop = false;

  @override
  void initState() {
    super.initState();
    _flowNotifier = ref.read(bookingFlowProvider(widget.sitterId).notifier);
    Future.microtask(() async {
      _flowNotifier!.reset();
      if (widget.groupEditId != null) {
        await _flowNotifier!.loadExistingGroup(widget.groupEditId!, forRebook: widget.forRebook);
      } else if (widget.editBookingId != null) {
        await _flowNotifier!.loadExistingBooking(widget.editBookingId!);
      } else if (widget.rebookFromId != null) {
        await _flowNotifier!.prefillFromBooking(widget.rebookFromId!);
      }
      final loadedState = ref.read(bookingFlowProvider(widget.sitterId));
      if (loadedState.selectedDateKeys.length > 1 && mounted) {
        setState(() => _isMultiDayMode = true);
      }
      _flowNotifier!.startAutoRefresh();
    });
  }

  @override
  void dispose() {
    _flowNotifier?.stopAutoRefresh();
    _notesController.dispose();
    _specialCareController.dispose();
    for (final c in _nameControllers) {
      c.dispose();
    }
    for (final c in _ageControllers) {
      c.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  void _syncChildControllers(BookingFlowState state) {
    while (_nameControllers.length < state.childrenCount) {
      _nameControllers.add(TextEditingController());
      _ageControllers.add(TextEditingController());
    }
    while (_nameControllers.length > state.childrenCount) {
      _nameControllers.removeLast().dispose();
      _ageControllers.removeLast().dispose();
    }
    for (int i = 0; i < state.childrenCount; i++) {
      if (i < state.childrenNames.length && _nameControllers[i].text != state.childrenNames[i]) {
        _nameControllers[i].text = state.childrenNames[i];
      }
      if (i < state.childrenAges.length && _ageControllers[i].text != state.childrenAges[i]) {
        _ageControllers[i].text = state.childrenAges[i];
      }
    }
  }

  String _localizeMsg(String msg) {
    final localeCode = ref.read(languageProvider).code;
    final strings = AppLocalization.get(localeCode);
    return localizeValidationMessage(msg, strings, locale: localeCode);
  }

  void _showCalendarMessage(String message, {SnackbarType type = SnackbarType.info}) {
    if (!mounted) return;
    AppSnackbar.show(context, message: _localizeMsg(message), type: type, duration: const Duration(seconds: 3));
  }

  void _showUnavailableDateFeedback(DayStatus status) {
    if (!mounted) return;
    final strings = AppLocalization.get(ref.read(languageProvider).code);
    final msg = switch (status) {
      DayStatus.nonWorking => strings[AppLocalization.calendar_closed_day] ?? 'This service is unavailable on this day.',
      DayStatus.fullyBooked => strings[AppLocalization.calendar_no_slots] ?? 'All available appointments have already been reserved.',
      DayStatus.past => strings[AppLocalization.calendar_past_date] ?? 'Bookings can only be made for upcoming dates.',
      DayStatus.outOfRange => strings[AppLocalization.calendar_unavailable_date] ?? 'This date is outside the available booking period.',
      _ => null,
    };
    if (msg != null) {
      AppSnackbar.show(context, message: msg, type: SnackbarType.info, duration: const Duration(seconds: 3));
    }
  }

  String _formatMinutes(int minutes, String localeCode) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final time = DateTime(2000, 1, 1, h, m);
    try {
      return DateFormat.jm(localeCode).format(time);
    } catch (_) {
      return DateFormat.jm().format(time);
    }
  }

  String _formatRangeLocalized(TimeRange r, String localeCode) =>
      '${_formatMinutes(r.startMinutes, localeCode)} – ${_formatMinutes(r.endMinutes, localeCode)}';

  String _formatConflictDate(DateTime date, String localeCode) {
    try {
      return DateFormat('EEEE, MMM d', localeCode).format(date);
    } catch (_) {
      return DateFormat('EEEE, MMM d').format(date);
    }
  }

  void _showTimeConflictDialog(String errorMsg) {
    if (!mounted) return;
    final localeCode = ref.read(languageProvider).code;
    final strings = AppLocalization.get(localeCode);
    final sitterId = widget.sitterId;
    final dateMatch = RegExp(r'^(\d{4}-\d{2}-\d{2}):').firstMatch(errorMsg);
    String rawDateKey = '';
    if (dateMatch != null) rawDateKey = dateMatch.group(1)!;
    final currentState = ref.read(bookingFlowProvider(sitterId));
    if (rawDateKey.isEmpty && currentState.selectedDateKeys.isNotEmpty) {
      rawDateKey = currentState.selectedDateKeys.first;
    }

    DateTime? conflictDate;
    List<TimeRange> availableRanges = [];
    String dateLabel = '';
    if (rawDateKey.isNotEmpty) {
      conflictDate = DateTime.tryParse(rawDateKey);
      if (conflictDate != null) {
        dateLabel = _formatConflictDate(conflictDate, localeCode);
        if (dateLabel.isEmpty) dateLabel = rawDateKey;
        availableRanges = availableTimeRangesForDate(
          conflictDate,
          currentState.sitterAvailability,
          currentState.existingBookings,
          excludeBookingId: currentState.editBookingId,
        );
      } else {
        dateLabel = rawDateKey;
      }
    }

    final isOverlap = errorMsg.contains('overlap');
    final isFullyBooked = errorMsg.contains('fully booked') || errorMsg.contains('fully_booked');
    final rangeMatch = RegExp(r'\(([^–]+)–([^)]+)\)').firstMatch(errorMsg);
    final conflictRange = rangeMatch != null
        ? '${rangeMatch.group(1)} – ${rangeMatch.group(2)}'
        : (currentState.startTime != null && currentState.endTime != null
            ? '${currentState.startTime!.format(context)} – ${currentState.endTime!.format(context)}'
            : '');

    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {

        final slotLabel = availableRanges.length == 1
            ? (strings[AppLocalization.available_slot_single] ?? 'Available Slot')
            : (strings[AppLocalization.calendar_available_slots] ?? 'Available Slots');

        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.xxl,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.dialog),
          ),
          backgroundColor: ctx.cardColor,
          content: SizedBox(
            width: 360,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isOverlap ? Icons.schedule_rounded : Icons.event_busy_rounded,
                      size: 32,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    isOverlap
                        ? (strings[AppLocalization.booking_overlap_title] ??
                            'Time Conflict')
                        : isFullyBooked
                            ? (strings[AppLocalization.calendar_fully_booked] ??
                                'Fully Booked')
                            : (strings[AppLocalization.time_unavailable] ??
                                'Time Not Available'),
                    style: AppTextStyles.titleLarge(
                      weight: FontWeight.bold,
                      color: ctx.textPrimaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (dateLabel.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 16, color: ctx.textPrimaryColor),
                          SizedBox(width: AppSpacing.xs),
                          Text(
                            dateLabel,
                            style: AppTextStyles.titleSmall(
                              weight: FontWeight.w600,
                              color: ctx.textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    isOverlap
                        ? '${strings[AppLocalization.suggestion_overlap_start] ?? 'The selected time'} $conflictRange ${strings[AppLocalization.suggestion_overlap_end] ?? 'overlaps with an existing booking.'}'
                        : isFullyBooked
                            ? (strings[AppLocalization.calendar_fully_booked] ?? 'Fully booked')
                            : '${strings[AppLocalization.suggestion_unavail_start] ?? 'The selected time'} $conflictRange ${strings[AppLocalization.suggestion_unavail_end] ?? 'is outside available hours.'}',
                    style: AppTextStyles.bodyMedium(
                      color: ctx.textSecondaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (availableRanges.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time_rounded,
                                  size: 18, color: AppColors.warning),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                slotLabel,
                                style: AppTextStyles.labelLarge(
                                  weight: FontWeight.w600,
                                  color: ctx.textPrimaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ...availableRanges.map(
                            (r) => Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.xs,
                                left: AppSpacing.xs,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: AppColors.warning,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    _formatRangeLocalized(r, localeCode),
                                    style: AppTextStyles.bodyMedium(
                                      color: ctx.textPrimaryColor,
                                      weight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      text: strings[AppLocalization.got_it] ?? 'Got It',
                      onPressed: () {
                        Navigator.of(ctx).pop();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _autoSelectFirstValid(sitter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final maxDate = today.add(const Duration(days: 90));
    final availability = sitter.babysitterProfile?.availability ?? [];
    final flowState = ref.read(bookingFlowProvider(widget.sitterId));
    final currentStatus = calendarDayStatusForDate(
      flowState.selectedDate, availability, flowState.existingBookings, today, maxDate,
      excludeBookingId: flowState.editBookingId,
    );
    if (currentStatus == DayStatus.past || currentStatus == DayStatus.nonWorking ||
        currentStatus == DayStatus.fullyBooked || currentStatus == DayStatus.outOfRange) {
      final first = firstAvailableDate(
        today, availability, flowState.existingBookings, maxDate,
        excludeBookingId: flowState.editBookingId,
      );
      if (first != null) {
        ref.read(bookingFlowProvider(widget.sitterId).notifier).setDate(first);
      }
    }
  }

  bool _canProceedFromStep(int step, BookingFlowState state) {
    switch (step) {
      case 0:
        if (state.isLoadingBookings) return false;
        if (state.bookingConflictMsg != null) return false;
        if (state.timeAvailabilityMsg != null) return false;
        if (state.isMultiDay) {
          if (state.selectedDateKeys.isEmpty) return false;
          if (state.startTime == null || state.endTime == null) return false;
          if (durationHours(state.startTime, state.endTime) < 1) return false;
          for (final key in state.selectedDateKeys) {
            final override = state.perDateTimes[key];
            final st = override?.startTime ?? state.startTime;
            final et = override?.endTime ?? state.endTime;
            if (st == null || et == null) return false;
            if (durationHours(st, et) < 1) return false;
          }
          return true;
        }
        return state.startTime != null &&
            state.endTime != null &&
            durationHours(state.startTime, state.endTime) >= 1;
      case 1:
        return state.childrenCount >= 1;
      case 2:
        return true;
      case 3:
        return !state.isSubmitting &&
            !state.isLoadingBookings &&
            state.bookingConflictMsg == null &&
            state.timeAvailabilityMsg == null;
      default:
        return false;
    }
  }

  void _handleBack() {
    final step = ref.read(bookingFlowProvider(widget.sitterId)).currentStep;
    if (step > 0 && step < 4) {
      ref.read(bookingFlowProvider(widget.sitterId).notifier).previousStep();
    } else {
      _shouldPop = true;
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleConfirm() async {
    final notifier = ref.read(bookingFlowProvider(widget.sitterId).notifier);
    final flowState = ref.read(bookingFlowProvider(widget.sitterId));
    if (flowState.isSubmitting) return;
    notifier.stopAutoRefresh();
    notifier.state = flowState.copyWith(isSubmitting: true);

    final strings = AppLocalization.get(ref.read(languageProvider).code);

    if (flowState.startTime == null || flowState.endTime == null) {
      notifier.state = flowState.copyWith(isSubmitting: false, timeValidationMsg: strings[AppLocalization.set_start_end_time] ?? 'Please set start and end time first.');
      return;
    }
    if (durationHours(flowState.startTime, flowState.endTime) < 1) {
      notifier.state = flowState.copyWith(isSubmitting: false, timeValidationMsg: strings[AppLocalization.booking_min_1hour] ?? 'Minimum booking duration is 1 hour.');
      return;
    }

    for (int i = 0; i < _nameControllers.length; i++) {
      notifier.setChildName(i, _nameControllers[i].text);
    }
    for (int i = 0; i < _ageControllers.length; i++) {
      notifier.setChildAge(i, _ageControllers[i].text);
    }

    final currentUser = ref.read(authProvider).user;
    if (currentUser?.id == widget.sitterId) {
      notifier.state = flowState.copyWith(isSubmitting: false, providerValidationMsg: strings[AppLocalization.cannot_book_yourself] ?? 'You cannot book yourself.');
      return;
    }

    await notifier.loadExistingBookings(forceRefresh: true);
    if (!mounted) {
      notifier.state = ref.read(bookingFlowProvider(widget.sitterId)).copyWith(isSubmitting: false);
      return;
    }

    notifier.checkForDoubleBooking();
    final updatedState = ref.read(bookingFlowProvider(widget.sitterId));
    if (updatedState.bookingConflictMsg != null) {
      notifier.state = updatedState.copyWith(isSubmitting: false);
      notifier.clearAllMessages();
      if (mounted) _showTimeConflictDialog(updatedState.bookingConflictMsg!);
      return;
    }
    if (updatedState.timeAvailabilityMsg != null) {
      notifier.state = updatedState.copyWith(isSubmitting: false);
      notifier.clearAllMessages();
      if (mounted) _showTimeConflictDialog(updatedState.timeAvailabilityMsg!);
      return;
    }

    final error = await notifier.confirmBooking(
      notes: _notesController.text,
      specialInstructions: _specialCareController.text,
    );
    if (error != null) {
      notifier.state = updatedState.copyWith(isSubmitting: false, error: error);
      notifier.clearAllMessages();
      if (mounted) _showTimeConflictDialog(error);
      notifier.startAutoRefresh();
      return;
    }
    ref.invalidate(pendingBookingsProvider);
    ref.invalidate(confirmedBookingsProvider);
    ref.invalidate(completedBookingsProvider);
    ref.invalidate(cancelledBookingsProvider);
    if (!mounted) return;
    ref.read(bookingFlowProvider(widget.sitterId).notifier).goToStep(4);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<BookingFlowState>(bookingFlowProvider(widget.sitterId), (prev, next) {
      _syncChildControllers(next);
      if (!_controllersInitialized) {
        bool hasData = false;
        if (next.notes != null && _notesController.text.isEmpty) {
          _notesController.text = next.notes!;
          hasData = true;
        }
        if (next.specialInstructions != null && _specialCareController.text.isEmpty) {
          _specialCareController.text = next.specialInstructions!;
          hasData = true;
        }
        if (next.childrenNames.isNotEmpty) hasData = true;
        // Only mark initialized after data actually loads (or for fresh booking)
        if (hasData || widget.editBookingId == null) {
          _controllersInitialized = true;
        }
      }
    });
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final flowState = ref.watch(bookingFlowProvider(widget.sitterId));
    final sitterAsync = ref.watch(sitterDetailsProvider(widget.sitterId));

    return PopScope(
      canPop: _shouldPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
      appBar: AppAppBar(
        title: widget.rebookFromId != null || widget.forRebook
            ? (strings[AppLocalization.rebook] ?? 'Rebook')
            : widget.editBookingId != null
            ? (strings[AppLocalization.edit_booking] ?? 'Edit Booking')
            : (strings[AppLocalization.book_sitter] ?? 'Book a Sitter'),
        onBackPressed: _handleBack,
      ),
      body: sitterAsync.when(
        data: (sitter) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _autoSelectFirstValid(sitter);
            final availability = sitter.babysitterProfile?.availability ?? [];
            ref.read(bookingFlowProvider(widget.sitterId).notifier)
                .setSitterAvailability(availability);
          });
          return flowState.isBooked
              ? _buildConfirmationStep(context, sitter, strings)
              : _buildMultiStep(context, sitter, flowState, strings);
        },
        loading: () => _buildShimmerContent(),
        error: (_, __) => _buildErrorContent(strings),
      ),
    ),
    );
  }

  Widget _buildMultiStep(
    BuildContext context,
    sitter,
    BookingFlowState flowState,
    Map<String, String> strings,
  ) {
    return Column(
      children: [
        BookingStepIndicator(currentStep: flowState.currentStep),
        Divider(height: 1, color: context.dividerColor),
        Expanded(
          child: AnimatedSwitcher(
            duration: 300.ms,
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child).animate().slideX(
                begin: 0.03,
                duration: 300.ms,
                curve: Curves.easeOutCubic,
              );
            },
            child: KeyedSubtree(
              key: ValueKey('step-${flowState.currentStep}'),
              child: _buildStepContent(context, flowState.currentStep, sitter, flowState, strings),
            ),
          ),
        ),
        _buildBottomBar(context, sitter, flowState, strings),
      ],
    );
  }

  Widget _buildStepContent(
    BuildContext context,
    int step,
    sitter,
    BookingFlowState flowState,
    Map<String, String> strings,
  ) {
    switch (step) {
      case 0:
        return _buildStepDateTime(context, sitter, flowState, strings);
      case 1:
        return _buildStepChildren(context, sitter, flowState, strings);
      case 2:
        return _buildStepAdditional(context, sitter, flowState, strings);
      case 3:
        return _buildStepReview(context, sitter, flowState, strings);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStepDateTime(
    BuildContext context,
    sitter,
    BookingFlowState flowState,
    Map<String, String> strings,
  ) {
    final availability = sitter.babysitterProfile?.availability ?? [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final maxDate = today.add(const Duration(days: 90));
    final hasConflict = flowState.bookingConflictMsg != null ||
        flowState.timeAvailabilityMsg != null;
    final notifier = ref.read(bookingFlowProvider(widget.sitterId).notifier);
    final dateKeys = flowState.selectedDateKeys;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: context.borderColor.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.date_range_rounded, size: 18.sp, color: AppColors.primary),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings[AppLocalization.multi_day_booking] ?? 'Multi-Day Booking',
                        style: AppTextStyles.labelMedium(weight: FontWeight.w600, color: context.textPrimary),
                      ),
                      Text(
                        _isMultiDayMode
                            ? ((strings[AppLocalization.days_selected] ?? '{count} days selected')
                                .replaceAll('{count}', '${flowState.selectedDateCount}'))
                            : (strings[AppLocalization.calendar_select_date] ?? 'Select dates'),
                        style: AppTextStyles.caption(color: context.textMuted),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isMultiDayMode,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() {
                      _isMultiDayMode = val;
                    });
                    if (val && flowState.selectedDateKeys.isEmpty) {
                      notifier.toggleDate(flowState.selectedDate);
                    } else if (!val && flowState.selectedDateKeys.length > 1) {
                      final sortedKeys = flowState.selectedDateKeys.toList()..sort();
                      final firstKey = sortedKeys.first;
                      notifier.setDate(DateTime.parse(firstKey));
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        Expanded(
          child: StepDateTimeWidget(
            sitterId: widget.sitterId,
            sitter: sitter,
            flowState: flowState,
            strings: strings,
            selectedDateKeys: dateKeys,
            perDateTimes: flowState.perDateTimes,
            onSetPerDateTime: (dateKey, start, end) {
              notifier.setPerDateTime(dateKey, start, end);
            },
            onClearPerDateTime: (dateKey) {
              notifier.clearPerDateTime(dateKey);
            },
            topBanner: hasConflict
                ? _buildRebookConflictBanner(context, flowState, strings)
                : null,
            onDateSelected: (date) {
              final dayStatus = calendarDayStatusForDate(
                date, availability, flowState.existingBookings, today, maxDate,
                excludeBookingId: flowState.editBookingId,
              );
              if (dayStatus == DayStatus.available || dayStatus == DayStatus.partiallyBooked) {
                if (_isMultiDayMode) {
                  notifier.toggleDate(date);
                } else {
                  notifier.setDate(date);
                }
              } else {
                _showUnavailableDateFeedback(dayStatus);
              }
            },
            guidanceWidget: _buildSmartGuidance(context, flowState.selectedDate, sitter, flowState, strings),
            dateSummaryWidget: _buildCompactDateSummary(context, sitter, flowState, strings),
            validationMessage: _buildValidationMessage(flowState.timeValidationMsg, flowState.bookingConflictMsg, flowState.timeAvailabilityMsg),
          ),
        ),
      ],
    );
  }

  Widget _buildRebookConflictBanner(
    BuildContext context,
    BookingFlowState flowState,
    Map<String, String> strings,
  ) {
    final msg = flowState.timeAvailabilityMsg ?? flowState.bookingConflictMsg;
    if (msg == null || msg.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.sm,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.error),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings[AppLocalization.time_unavailable] ?? 'Time Not Available',
                    style: AppTextStyles.titleSmall(
                      weight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    msg,
                    style: AppTextStyles.bodySmall(color: context.textPrimary),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    strings[AppLocalization.rebook_conflict_hint] ?? 'Pick a different date or time to continue.',
                    style: AppTextStyles.caption(color: context.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepChildren(
    BuildContext context,
    sitter,
    BookingFlowState flowState,
    Map<String, String> strings,
  ) {
    return StepChildrenWidget(
      sitterId: widget.sitterId,
      sitter: sitter,
      flowState: flowState,
      strings: strings,
      specialCareController: _specialCareController,
      nameControllers: _nameControllers,
      ageControllers: _ageControllers,
      validationMessage: _buildValidationMessage(flowState.childrenValidationMsg),
    );
  }

  Widget _buildStepAdditional(
    BuildContext context,
    sitter,
    BookingFlowState flowState,
    Map<String, String> strings,
  ) {
    return StepAdditionalWidget(
      sitterId: widget.sitterId,
      flowState: flowState,
      strings: strings,
      notesController: _notesController,
      notesCharCount: _buildNotesCharCount(strings),
      validationMessage: _buildValidationMessage(flowState.notesValidationMsg),
      onPickEventTime: _pickEventTime,
    );
  }

  Widget _buildStepReview(
    BuildContext context,
    sitter,
    BookingFlowState flowState,
    Map<String, String> strings,
  ) {
    return StepReviewWidget(
      sitterId: widget.sitterId,
      sitter: sitter,
      flowState: flowState,
      strings: strings,
      summaryCard: _buildSummaryCard(context, sitter, flowState, strings),
      sitterCard: _buildSitterCard(context, sitter, strings),
      reviewWarnings: _buildReviewWarnings(context, flowState, strings),
      termsHint: _buildTermsHint(context, strings),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    sitter,
    BookingFlowState flowState,
    Map<String, String> strings,
  ) {
    final selected = flowState.selectedDate;
    final locale = ref.watch(languageProvider).code;
    final weekdayName = DateFormat('EEE', locale).format(selected);
    final dateStr = DateFormat('MMM d, yyyy', locale).format(selected);
    final duration = durationHours(flowState.startTime, flowState.endTime);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.borderColor.withValues(alpha: 0.5)),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        children: [
          if (flowState.isMultiDay) ...[
            _summaryRow(Icons.date_range_rounded, strings[AppLocalization.multi_day_booking] ?? 'Multi-Day Booking',
                '${flowState.selectedDateCount} ${strings[AppLocalization.days_selected]?.replaceAll('{count}', '${flowState.selectedDateCount}') ?? 'days'}'),
            Divider(height: AppSpacing.sm * 2, color: context.dividerColor),
            ...() {
              final sortedKeys = flowState.selectedDateKeys.toList()..sort();
              return sortedKeys.map((key) {
              final d = DateTime.parse(key);
              final wd = DateFormat('EEE', locale).format(d);
              final ds = DateFormat('MMM d', locale).format(d);
              final override = flowState.perDateTimes[key];
              final st = override?.startTime ?? flowState.startTime;
              final et = override?.endTime ?? flowState.endTime;
              final dur = st != null && et != null ? durationHours(st, et) : duration;
              return Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.xs),
                child: _summaryRow(Icons.calendar_today_rounded, '$wd, $ds',
                    st != null && et != null ? '$dur hr' : '-'),
              );
            }).toList();
          }(),
            Divider(height: AppSpacing.sm * 2, color: context.dividerColor),
          ] else ...[
            _summaryRow(Icons.calendar_today_rounded, strings[AppLocalization.date] ?? 'Date', '$weekdayName, $dateStr'),
            Divider(height: AppSpacing.sm * 2, color: context.dividerColor),
            _summaryRow(
              Icons.access_time_rounded,
              strings[AppLocalization.time] ?? 'Time',
              flowState.startTime != null && flowState.endTime != null
                  ? '${formatTime(flowState.startTime!, locale: locale)} - ${formatTime(flowState.endTime!, locale: locale)}'
                  : '-',
            ),
            Divider(height: AppSpacing.sm * 2, color: context.dividerColor),
            _summaryRow(Icons.timer_rounded, strings[AppLocalization.duration] ?? 'Duration', '$duration hr${duration == 1 ? '' : 's'}'),
            Divider(height: AppSpacing.sm * 2, color: context.dividerColor),
          ],
          _summaryRow(
            Icons.child_care_rounded,
            strings[AppLocalization.children] ?? 'Children',
            '${flowState.childrenCount} child${flowState.childrenCount == 1 ? '' : 'ren'}',
          ),
          if (flowState.specialNeedsCount > 0) ...[
            Divider(height: AppSpacing.sm * 2, color: context.dividerColor),
            _summaryRow(
              Icons.accessible_forward_rounded,
              strings[AppLocalization.special_needs] ?? 'Special Needs',
              '${flowState.specialNeedsCount} child${flowState.specialNeedsCount == 1 ? '' : 'ren'}',
            ),
          ],
          if (_notesController.text.isNotEmpty) ...[
            Divider(height: AppSpacing.sm * 2, color: context.dividerColor),
            _summaryRow(Icons.notes_rounded, strings[AppLocalization.notes] ?? 'Notes', _notesController.text),
          ],
          if (flowState.scheduleEvents.any((e) => e.activity.isNotEmpty)) ...[
            Divider(height: AppSpacing.sm * 2, color: context.dividerColor),
            _summaryRow(
              Icons.schedule_rounded,
              strings[AppLocalization.events] ?? 'Events',
              '${flowState.scheduleEvents.where((e) => e.activity.isNotEmpty).length} event${flowState.scheduleEvents.where((e) => e.activity.isNotEmpty).length == 1 ? '' : 's'}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: context.textMuted),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(label, style: AppTextStyles.bodySmall(color: context.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        SizedBox(width: AppSpacing.sm),
        Text(
          value,
          style: AppTextStyles.labelMedium(weight: FontWeight.w600, color: context.textPrimary),
          textAlign: TextAlign.end,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildReviewWarnings(BuildContext context, BookingFlowState flowState, Map<String, String> strings) {
    final warnings = <Widget>[];
    if (flowState.providerValidationMsg != null) {
      warnings.add(_buildWarningRow(_localizeMsg(flowState.providerValidationMsg!), AppColors.error));
    }
    if (flowState.timeAvailabilityMsg != null) {
      warnings.add(_buildWarningRow(_localizeMsg(flowState.timeAvailabilityMsg!), AppColors.error));
    }
    if (flowState.bookingConflictMsg != null) {
      warnings.add(_buildWarningRow(_localizeMsg(flowState.bookingConflictMsg!), AppColors.error));
    }
    if (flowState.timeValidationMsg != null) {
      warnings.add(_buildWarningRow(_localizeMsg(flowState.timeValidationMsg!), AppColors.warning));
    }
    if (flowState.error != null) {
      warnings.add(_buildWarningRow(flowState.error!, AppColors.error));
    }
    if (warnings.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.error_outline_rounded, size: 16, color: AppColors.error),
              SizedBox(width: AppSpacing.xs),
              Text(
                strings[AppLocalization.please_fix_before_confirm] ?? 'Please fix the following before confirming:',
                style: AppTextStyles.labelMedium(weight: FontWeight.w600, color: AppColors.error),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          ...warnings,
        ],
      ),
    );
  }

  Widget _buildWarningRow(String message, Color color) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 16, color: color),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(message, style: AppTextStyles.bodySmall(color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartGuidance(
    BuildContext context,
    DateTime currentDate,
    sitter,
    BookingFlowState flowState,
    Map<String, String> strings,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final maxDate = today.add(const Duration(days: 90));
    final availability = sitter.babysitterProfile?.availability ?? [];

    final status = calendarDayStatusForDate(currentDate, availability, flowState.existingBookings, today, maxDate,
      excludeBookingId: flowState.editBookingId,
    );

    if (status == DayStatus.available) return const SizedBox.shrink();

    if (status == DayStatus.partiallyBooked) {
      final slots = bookableSlotsForDate(currentDate, availability, flowState.existingBookings,
        excludeBookingId: flowState.editBookingId,
      );
      final available = slots.where((s) => s.isAvailable).length;
      if (available <= 2) {
        return _guidanceBanner(
          context,
          Icons.alarm_rounded,
          strings[AppLocalization.calendar_few_slots] ?? 'Only $available slot${available == 1 ? '' : 's'} remain for this date. Consider booking soon.',
          const Color(0xFFEF4444),
        );
      }
      final limitedCount = slots.where((s) => s.isAvailable && slotStatusFor(s.capacityFraction) != SlotStatus.available).length;
      if (limitedCount > 0) {
        return _guidanceBanner(
          context,
          Icons.access_time_rounded,
          strings[AppLocalization.calendar_few_slots] ?? 'Most preferred times are filling up. Early booking recommended.',
          const Color(0xFFF59E0B),
        );
      }
      return const SizedBox.shrink();
    }

    final first = firstAvailableDate(today, availability, flowState.existingBookings, maxDate,
      excludeBookingId: flowState.editBookingId,
    );
    if (first == null) return const SizedBox.shrink();

    final locale = ref.watch(languageProvider).code;
    final weekdayName = DateFormat('EEE', locale).format(first);
    final dateStr = DateFormat('MMM d', locale).format(first);
    return _guidanceBanner(
      context,
      Icons.lightbulb_outline_rounded,
      (strings[AppLocalization.next_available_date] ?? 'Next available: {date}')
          .replaceAll('{date}', '$weekdayName, $dateStr'),
      AppColors.primary,
    );
  }

  Widget _guidanceBanner(BuildContext context, IconData icon, String message, Color color) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(message, style: AppTextStyles.bodySmall(color: context.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildSitterCard(BuildContext context, sitter, Map<String, String> strings) {
    final profile = sitter.babysitterProfile;
    final initials = sitter.name.isNotEmpty
        ? sitter.name.split(' ').map((n) => n.isNotEmpty ? n[0].toUpperCase() : '').take(2).join()
        : '?';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.borderColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Center(
              child: Text(
                initials,
                style: AppTextStyles.titleSmall(
                  weight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sitter.name,
                  style: AppTextStyles.labelMedium(
                    weight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                if (profile != null && profile.rating > 0)
                  Row(
                    children: [
                      Icon(Icons.star_rounded, size: 13, color: const Color(0xFFF59E0B)),
                      SizedBox(width: 2),
                      Text(
                        profile.rating.toStringAsFixed(1),
                        style: AppTextStyles.caption(color: context.textMuted),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Text(
                        '(${profile.reviewCount})',
                        style: AppTextStyles.caption(color: context.textMuted),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              strings[AppLocalization.verified] ?? 'Verified',
              style: AppTextStyles.caption(
                weight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsHint(BuildContext context, Map<String, String> strings) {
    final locale = ref.read(languageProvider).code;
    final isRtl = locale == 'ar';
    final agreeText = strings[AppLocalization.booking_terms_confirm] ?? 'By booking, you agree to our ';
    final termsText = strings[AppLocalization.terms_of_service] ?? 'Terms of Service';
    final andText = strings[AppLocalization.terms_and] ?? ' and ';
    final privacyText = strings[AppLocalization.privacy_policy_title] ?? 'Privacy Policy';
    final periodText = strings[AppLocalization.terms_period] ?? '.';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.description_rounded, size: 16, color: AppColors.primary),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: isRtl
                ? RichText(
                    text: TextSpan(
                      style: AppTextStyles.caption(color: context.textMuted),
                      children: [
                        TextSpan(
                          text: privacyText,
                          style: AppTextStyles.caption(color: AppColors.primary, weight: FontWeight.w600),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              final uri = Uri.parse(AppConfig.privacyUrl);
                              if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                            },
                        ),
                        TextSpan(text: andText),
                        TextSpan(
                          text: termsText,
                          style: AppTextStyles.caption(color: AppColors.primary, weight: FontWeight.w600),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              final uri = Uri.parse(AppConfig.termsUrl);
                              if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                            },
                        ),
                        TextSpan(text: periodText),
                        TextSpan(text: ' $agreeText'),
                      ],
                    ),
                  )
                : RichText(
                    text: TextSpan(
                      style: AppTextStyles.caption(color: context.textMuted),
                      children: [
                        TextSpan(text: agreeText),
                        TextSpan(
                          text: termsText,
                          style: AppTextStyles.caption(color: AppColors.primary, weight: FontWeight.w600),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              final uri = Uri.parse(AppConfig.termsUrl);
                              if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                            },
                        ),
                        TextSpan(text: andText),
                        TextSpan(
                          text: privacyText,
                          style: AppTextStyles.caption(color: AppColors.primary, weight: FontWeight.w600),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              final uri = Uri.parse(AppConfig.privacyUrl);
                              if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                            },
                        ),
                        TextSpan(text: periodText),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationStep(BuildContext context, sitter, Map<String, String> strings) {
    final locale = ref.read(languageProvider).code;
    final flowState = ref.read(bookingFlowProvider(widget.sitterId));

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 40.h),
            Container(
              width: 96.w,
              height: 96.w,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, size: 48.sp, color: AppColors.success),
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
            SizedBox(height: AppSpacing.lg),
            Text(
              widget.rebookFromId != null || widget.forRebook
                  ? (strings[AppLocalization.booking_rebooked_title] ?? 'Booking Rebooked!')
                  : widget.editBookingId != null
                  ? (strings[AppLocalization.booking_updated_title] ?? 'Booking Updated!')
                  : flowState.isMultiDay
                  ? (strings[AppLocalization.booking_confirmed_title] ?? 'Booking Confirmed!')
                  : (strings[AppLocalization.booking_confirmed_title] ?? 'Booking Confirmed!'),
              style: AppTextStyles.headlineSmall(color: context.textPrimary),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, duration: 400.ms),
            SizedBox(height: AppSpacing.xs),
            Text(
              widget.rebookFromId != null || widget.forRebook
                  ? (strings[AppLocalization.booking_rebooked_body] ?? 'Your booking has been rebooked successfully.')
                  : widget.editBookingId != null
                  ? (strings[AppLocalization.booking_updated_body] ?? 'Your booking has been updated successfully.')
                  : flowState.isMultiDay
                  ? (strings[AppLocalization.booking_confirmed_body] ?? 'Your babysitter has been booked successfully.')
                  : (strings[AppLocalization.booking_confirmed_body] ?? 'Your babysitter has been booked successfully.'),
              style: AppTextStyles.bodyMedium(color: context.textMuted),
              textAlign: TextAlign.center,
            ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
            SizedBox(height: AppSpacing.xl),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: context.borderColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  if (flowState.isMultiDay) ...[
                    _summaryRow(Icons.date_range_rounded, strings[AppLocalization.multi_day_booking] ?? 'Multi-Day Booking',
                        '${flowState.selectedDateCount} ${strings[AppLocalization.days_selected]?.replaceAll('{count}', '${flowState.selectedDateCount}') ?? 'days'}'),
                  ] else ...[
                    _summaryRow(Icons.calendar_today_rounded, strings[AppLocalization.date] ?? 'Date', _formatDate(flowState.selectedDate)),
                  ],
                  SizedBox(height: AppSpacing.sm),
                  _summaryRow(
                    Icons.access_time_rounded,
                    strings[AppLocalization.time] ?? 'Time',
                    flowState.startTime != null && flowState.endTime != null
                        ? '${formatTime(flowState.startTime!, locale: locale)} - ${formatTime(flowState.endTime!, locale: locale)}'
                        : '-',
                  ),
                  SizedBox(height: AppSpacing.sm),
                  _summaryRow(
                    Icons.person_rounded,
                    strings[AppLocalization.sitter_label] ?? 'Sitter',
                    sitter.name,
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
            SizedBox(height: AppSpacing.xxl),
            SafeArea(
              child: Column(
                children: [
                  AppButton(
                    text: strings[AppLocalization.view_bookings] ?? 'View My Bookings',
                    onPressed: () {
                      ref.read(pendingBookingsProvider.notifier).loadTab();
                      ref.read(confirmedBookingsProvider.notifier).loadTab();
                      ref.read(completedBookingsProvider.notifier).loadTab();
                      ref.read(cancelledBookingsProvider.notifier).loadTab();
                      ref.read(bottomNavIndexProvider.notifier).state = 1;
                      final isSitter = ref.read(roleManagerProvider).isSitter;
                      context.go(isSitter ? AppRoutes.sitterDashboard : AppRoutes.parentHome);
                    },
                  ),
                  SizedBox(height: AppSpacing.sm),
                  AppButton(
                    text: strings[AppLocalization.return_home] ?? 'Return Home',
                    variant: AppButtonVariant.outlined,
                    onPressed: () {
                      ref.read(pendingBookingsProvider.notifier).loadTab();
                      ref.read(confirmedBookingsProvider.notifier).loadTab();
                      ref.read(completedBookingsProvider.notifier).loadTab();
                      ref.read(cancelledBookingsProvider.notifier).loadTab();
                      final isSitter = ref.read(roleManagerProvider).isSitter;
                      context.go(isSitter ? AppRoutes.sitterDashboard : AppRoutes.parentHome);
                    },
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 600.ms),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final locale = ref.watch(languageProvider).code;
    return DateFormat('EEE, MMM d, yyyy', locale).format(date);
  }

  Widget _buildBottomBar(
    BuildContext context,
    sitter,
    BookingFlowState flowState,
    Map<String, String> strings,
  ) {
    if (flowState.isBooked) return const SizedBox.shrink();

    final step = flowState.currentStep;
    final canProceed = _canProceedFromStep(step, flowState);

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.sm, AppSpacing.screenPadding, AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!canProceed)
              _buildDisabledHint(context, flowState, strings),
            SizedBox(height: !canProceed ? AppSpacing.xs : 0),
            Row(
              children: [
            if (step > 0)
              Expanded(
                child: AppButton(
                  text: strings[AppLocalization.step_back] ?? 'Back',
                  variant: AppButtonVariant.outlined,
                  onPressed: () => ref.read(bookingFlowProvider(widget.sitterId).notifier).previousStep(),
                ),
              ),
            if (step > 0) SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: step == 3 ? 3 : step == 0 ? 2 : 2,
              child: step == 3
                  ? AppButton(
                      text: widget.rebookFromId != null || widget.forRebook
                          ? (strings[AppLocalization.confirm_rebook] ?? 'Confirm Rebook')
                          : widget.editBookingId != null
                          ? (strings[AppLocalization.update_booking] ?? 'Update Booking')
                          : flowState.isMultiDay
                          ? (strings[AppLocalization.confirm_multi_day] ?? 'Confirm Booking ({count} days)').replaceAll('{count}', '${flowState.selectedDateCount}')
                          : (strings[AppLocalization.confirm_booking] ?? 'Confirm Booking'),
                      isLoading: flowState.isSubmitting,
                      onPressed: canProceed && !flowState.isSubmitting ? _handleConfirm : null,
                    )
                  : AppButton(
                      text: strings[AppLocalization.step_next] ?? 'Continue',
                      onPressed: canProceed
                          ? () {
                              final notifier = ref.read(bookingFlowProvider(widget.sitterId).notifier);
                              notifier.nextStep();
                              final s = ref.read(bookingFlowProvider(widget.sitterId));
                              final msg = s.timeAvailabilityMsg ?? s.bookingConflictMsg;
                              if (msg != null) {
                                notifier.clearAllMessages();
                                _showTimeConflictDialog(msg);
                              }
                            }
                          : null,
                    ),
            ),
          ],
        ),
      ],
    ),
    ),
    );
  }

  Widget _buildCompactDateSummary(
    BuildContext context,
    sitter,
    BookingFlowState flowState,
    Map<String, String> strings,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final maxDate = today.add(const Duration(days: 90));
    final selected = flowState.selectedDate;
    final availability = sitter.babysitterProfile?.availability ?? [];

    final dayStatus = calendarDayStatusForDate(
      selected, availability, flowState.existingBookings, today, maxDate,
      excludeBookingId: flowState.editBookingId,
    );
    final visual = statusVisualFor(dayStatus, strings: strings);
    final locale = ref.watch(languageProvider).code;
    final isToday = isSameDay(selected, today);
    final weekdayName = DateFormat('EEE', locale).format(selected);
    final dateStr = DateFormat('MMM d, yyyy', locale).format(selected);

    final hasTimeSet = flowState.startTime != null && flowState.endTime != null;
    final hasConflict = flowState.bookingConflictMsg != null || flowState.timeAvailabilityMsg != null;

    Color borderColor;
    double borderAlpha;
    if (dayStatus == DayStatus.fullyBooked || dayStatus == DayStatus.nonWorking) {
      borderColor = AppColors.error;
      borderAlpha = 0.5;
    } else if (hasConflict) {
      borderColor = AppColors.warning;
      borderAlpha = 0.5;
    } else {
      borderColor = visual.color;
      borderAlpha = 0.25;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor.withValues(alpha: borderAlpha)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: visual.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(visual.icon, size: 15, color: visual.color),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$weekdayName, $dateStr',
                      style: AppTextStyles.titleSmall(weight: FontWeight.w600, color: context.textPrimary),
                    ),
                    if (hasTimeSet)
                      Text(
                        '${formatTime(flowState.startTime!, locale: locale)} - ${formatTime(flowState.endTime!, locale: locale)}',
                        style: AppTextStyles.caption(
                          color: hasConflict ? AppColors.warning : context.textPrimary,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                decoration: BoxDecoration(
                  color: visual.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(visual.icon, size: 11, color: visual.color),
                    SizedBox(width: 3),
                    Text(
                      isToday ? strings[AppLocalization.calendar_today] ?? 'Today' : visual.label,
                      style: AppTextStyles.labelSmall(weight: FontWeight.w600, color: visual.color),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (dayStatus == DayStatus.available || dayStatus == DayStatus.partiallyBooked) ...[
            SizedBox(height: AppSpacing.sm),
            Divider(height: 1, color: context.dividerColor),
            SizedBox(height: AppSpacing.sm),
            hasConflict
                ? _buildTimeConflictBanner(context, flowState, availability, strings)
                : _buildSlotSummary(context, flowState, availability, strings),
          ],
          if (dayStatus == DayStatus.fullyBooked || dayStatus == DayStatus.nonWorking) ...[
            SizedBox(height: AppSpacing.sm),
            Divider(height: 1, color: context.dividerColor),
            SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.block_rounded, size: 14, color: AppColors.error),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      strings[AppLocalization.calendar_no_slots] ?? 'No slots available for this date.',
                      style: AppTextStyles.caption(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (dayStatus == DayStatus.past) ...[
            SizedBox(height: AppSpacing.sm),
            Divider(height: 1, color: context.dividerColor),
            SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.dividerColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  Icon(Icons.history_rounded, size: 14, color: context.textMuted),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      strings[AppLocalization.calendar_past_date_message] ?? 'This date has passed.',
                      style: AppTextStyles.caption(color: context.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeConflictBanner(
    BuildContext context,
    BookingFlowState flowState,
    List<AvailabilitySlot> availability,
    Map<String, String> strings,
  ) {
    final locale = ref.read(languageProvider).code;
    final slots = bookableSlotsForDate(
      flowState.selectedDate, availability, flowState.existingBookings,
      excludeBookingId: flowState.editBookingId,
    );
    final available = slots.where((s) => s.isAvailable).toList();
    final ranges = availableTimeRangesForDate(
      flowState.selectedDate, availability, flowState.existingBookings,
      excludeBookingId: flowState.editBookingId,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 14, color: AppColors.warning),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  strings[AppLocalization.time_unavailable] ?? 'Time not available',
                  style: AppTextStyles.caption(color: AppColors.warning),
                ),
              ),
            ],
          ),
        ),
        if (ranges.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          ...ranges.map((r) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatRangeLocalized(r, locale),
                      style: AppTextStyles.caption(
                        color: context.textPrimary,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )),
        ],
        if (available.isEmpty && ranges.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              strings[AppLocalization.calendar_no_slots] ?? 'No slots available for this date.',
              style: AppTextStyles.caption(color: AppColors.error),
            ),
          ),
      ],
    );
  }

  Widget _buildSlotSummary(
    BuildContext context,
    BookingFlowState flowState,
    List<AvailabilitySlot> availability,
    Map<String, String> strings,
  ) {
    final locale = ref.read(languageProvider).code;
    final slots = bookableSlotsForDate(
      flowState.selectedDate, availability, flowState.existingBookings,
      excludeBookingId: flowState.editBookingId,
    );
    final available = slots.where((s) => s.isAvailable).toList();

    if (available.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(Icons.block_rounded, size: 14, color: AppColors.error),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                strings[AppLocalization.calendar_no_slots] ?? 'No slots available for this date.',
                style: AppTextStyles.caption(color: AppColors.error),
              ),
            ),
          ],
        ),
      );
    }

    final limitedCount = available.where((s) => slotStatusFor(s.capacityFraction) != SlotStatus.available).length;
    final earliest = earliestAvailableTimeDescription(
      available.where((s) => slotStatusFor(s.capacityFraction) == SlotStatus.available)
          .map((s) => TimeRange(startMinutes: s.startMinutes, endMinutes: s.endMinutes)).toList(),
      60,
      locale: locale,
    );

    String text;
    Color color;
    IconData icon;
    if (limitedCount > 0) {
      final trulyAvailable = available.where((s) => slotStatusFor(s.capacityFraction) == SlotStatus.available).length;
      if (trulyAvailable == 0) {
        text = strings[AppLocalization.calendar_few_slots] ?? 'Limited availability';
        color = AppColors.warning;
        icon = Icons.access_time_rounded;
      } else {
        text = earliest != null
            ? '${strings[AppLocalization.calendar_available_slots] ?? 'Available from'}: $earliest'
            : '$trulyAvailable slot${trulyAvailable == 1 ? '' : 's'} available';
        color = const Color(0xFF22C55E);
        icon = Icons.check_circle_rounded;
      }
    } else {
      text = earliest != null
          ? '${strings[AppLocalization.calendar_available_slots] ?? 'Available from'}: $earliest'
          : '${available.length} slot${available.length == 1 ? '' : 's'} available';
      color = const Color(0xFF22C55E);
      icon = Icons.check_circle_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.caption(color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationMessage(String? timeMsg, [String? conflictMsg, String? availabilityMsg]) {
    final hasTimeMsg = timeMsg != null && timeMsg.isNotEmpty;
    final hasConflict = conflictMsg != null && conflictMsg.isNotEmpty;
    final hasAvailability = availabilityMsg != null && availabilityMsg.isNotEmpty;
    if (!hasTimeMsg && !hasConflict && !hasAvailability) return const SizedBox.shrink();
    return Column(
      children: [
        if (hasTimeMsg)
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(top: AppSpacing.xs),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: AppColors.warning),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(_localizeMsg(timeMsg), style: AppTextStyles.bodySmall(color: AppColors.warning)),
                ),
              ],
            ),
          ),
        if (hasAvailability)
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(top: AppSpacing.xs),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.error),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(_localizeMsg(availabilityMsg), style: AppTextStyles.bodySmall(color: AppColors.error)),
                ),
              ],
            ),
          ),
        if (hasConflict && !hasAvailability)
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(top: AppSpacing.xs),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.error),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(_localizeMsg(conflictMsg), style: AppTextStyles.bodySmall(color: AppColors.error)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNotesCharCount(Map<String, String> strings) {
    final count = _notesController.text.length;
    final maxChars = 1000;
    final remaining = maxChars - count;
    final isOver = count > maxChars;
    return Padding(
      padding: EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Text(
            '${strings[AppLocalization.characters] ?? 'Characters'}: $count/$maxChars',
            style: AppTextStyles.caption(
              color: isOver ? AppColors.error : context.textMuted,
            ),
          ),
          if (remaining <= 50 && remaining > 0)
            Text(
              ' ($remaining ${strings[AppLocalization.remaining] ?? 'remaining'})',
              style: AppTextStyles.caption(color: AppColors.warning),
            ),
        ],
      ),
    );
  }

  Widget _buildDisabledHint(BuildContext context, BookingFlowState flowState, Map<String, String> strings) {
    if (flowState.currentStep == 0) {
      if (flowState.startTime == null) {
        return Text(strings[AppLocalization.select_time_first] ?? 'Select a time first', style: AppTextStyles.caption(color: context.textMuted));
      }
      if (flowState.endTime == null) {
        return Text(strings[AppLocalization.select_end_time] ?? 'Select end time', style: AppTextStyles.caption(color: context.textMuted));
      }
      if (flowState.timeValidationMsg != null) {
        return Text(_localizeMsg(flowState.timeValidationMsg!), style: AppTextStyles.caption(color: AppColors.warning));
      }
      if (flowState.timeAvailabilityMsg != null) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 13, color: AppColors.error),
              SizedBox(width: 4),
              Flexible(child: Text(_localizeMsg(flowState.timeAvailabilityMsg!), style: AppTextStyles.caption(color: AppColors.error))),
            ],
          ),
        );
      }
      if (flowState.bookingConflictMsg != null) {
        return Text(_localizeMsg(flowState.bookingConflictMsg!), style: AppTextStyles.caption(color: AppColors.error));
      }
    }
    if (flowState.currentStep == 1 && flowState.childrenValidationMsg != null) {
      return Text(flowState.childrenValidationMsg!, style: AppTextStyles.caption(color: AppColors.warning));
    }
    if (flowState.currentStep == 3) {
      if (flowState.bookingConflictMsg != null) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 13, color: AppColors.error),
              SizedBox(width: 4),
              Flexible(
                child: Text(_localizeMsg(flowState.bookingConflictMsg!),
                  style: AppTextStyles.caption(color: AppColors.error),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }
      if (flowState.timeAvailabilityMsg != null) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 13, color: AppColors.error),
              SizedBox(width: 4),
              Flexible(
                child: Text(_localizeMsg(flowState.timeAvailabilityMsg!),
                  style: AppTextStyles.caption(color: AppColors.error),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }
      if (flowState.providerValidationMsg != null) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 13, color: AppColors.error),
              SizedBox(width: 4),
              Flexible(
                child: Text(flowState.providerValidationMsg!,
                  style: AppTextStyles.caption(color: AppColors.error),
                ),
              ),
            ],
          ),
        );
      }
    }
    return const SizedBox.shrink();
  }

  Future<void> _pickEventTime(int index) async {
    final flowState = ref.read(bookingFlowProvider(widget.sitterId));
    if (flowState.startTime == null || flowState.endTime == null) {
      final strings = AppLocalization.get(ref.read(languageProvider).code);
      _showCalendarMessage(strings[AppLocalization.set_start_end_time] ?? 'Please set start and end time first.', type: SnackbarType.info);
      return;
    }
    final existing = index < flowState.scheduleEvents.length ? flowState.scheduleEvents[index].timeOfDay : null;
    final picked = await showTimePicker(
      context: Navigator.of(context).context,
      initialTime: existing ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked == null) return;
    final pickedMins = picked.hour * 60 + picked.minute;
    final startMins = flowState.startTime!.hour * 60 + flowState.startTime!.minute;
    final endMins = flowState.endTime!.hour * 60 + flowState.endTime!.minute;
    if (pickedMins < startMins || pickedMins > endMins) {
      final locale = ref.read(languageProvider).code;
      final strings = AppLocalization.get(locale);
      final msg = (strings[AppLocalization.event_time_between] ?? 'Event time must be between {start} and {end}')
          .replaceAll('{start}', formatTime(flowState.startTime!, locale: locale))
          .replaceAll('{end}', formatTime(flowState.endTime!, locale: locale));
      if (!mounted) return;
      _showCalendarMessage(msg, type: SnackbarType.info);
      return;
    }
    ref.read(bookingFlowProvider(widget.sitterId).notifier).updateScheduleEventTime(index, picked);
  }

  Widget _buildShimmerContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        children: [
          Container(
            height: 200.h,
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppRadius.xxxl),
                bottomRight: Radius.circular(AppRadius.xxxl),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              children: List.generate(
                  5,
                  (_) => Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.lg),
                        child: AppShimmer(width: double.infinity, height: 60, borderRadius: AppRadius.lg),
                      )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(Map<String, String> strings) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 40.h),
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cloud_off_rounded, size: 40.sp, color: AppColors.error),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              strings[AppLocalization.load_error_title] ?? 'Could not load sitter info',
              style: AppTextStyles.titleSmall(weight: FontWeight.w600, color: context.textPrimary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              strings[AppLocalization.load_error_desc] ?? 'Please check your connection and try again.',
              style: AppTextStyles.bodyMedium(color: context.textMuted),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.lg),
            AppButton(
              text: strings[AppLocalization.retry] ?? 'Retry',
              onPressed: () => ref.invalidate(sitterDetailsProvider(widget.sitterId)),
            ),
          ],
        ),
      ),
    );
  }
}

