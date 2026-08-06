import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/core/network/error_handler.dart';
import 'package:babysitter/features/booking/data/booking_repository.dart';
import 'package:babysitter/features/booking/presentation/helpers/booking_helpers.dart';
import 'package:babysitter/shared/models/booking_model.dart';
import 'package:babysitter/shared/models/user_model.dart';

class BookingFlowState {
  final int currentStep;
  final DateTime selectedDate;
  final Set<String> selectedDateKeys;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final Map<String, PerDateTimeOverride> perDateTimes;
  final bool isSubmitting;
  final bool isLoadingBookings;
  final bool isBooked;
  final bool isProviderStillAvailable;
  final bool isRebook;
  final List<BookingModel> existingBookings;
  final List<AvailabilitySlot> sitterAvailability;
  final Set<String> blockedDates;
  final String? editBookingId;
  final int childrenCount;
  final int specialNeedsCount;
  final List<String> childrenNames;
  final List<String> childrenAges;
  final List<ScheduleEventData> scheduleEvents;
  final String? notes;
  final String? specialInstructions;
  final String? error;
  final String? dateValidationMsg;
  final String? timeValidationMsg;
  final String? childrenValidationMsg;
  final String? notesValidationMsg;
  final String? providerValidationMsg;
  final String? bookingConflictMsg;
  final String? timeAvailabilityMsg;

  const BookingFlowState({
    this.currentStep = 0,
    required this.selectedDate,
    this.selectedDateKeys = const {},
    this.startTime,
    this.endTime,
    this.perDateTimes = const {},
    this.isSubmitting = false,
    this.isLoadingBookings = false,
    this.isBooked = false,
    this.isProviderStillAvailable = true,
    this.isRebook = false,
    this.existingBookings = const [],
    this.sitterAvailability = const [],
    this.blockedDates = const {},
    this.editBookingId,
    this.childrenCount = 1,
    this.specialNeedsCount = 0,
    this.childrenNames = const [],
    this.childrenAges = const [],
    this.scheduleEvents = const [],
    this.notes,
    this.specialInstructions,
    this.error,
    this.dateValidationMsg,
    this.timeValidationMsg,
    this.childrenValidationMsg,
    this.notesValidationMsg,
    this.providerValidationMsg,
    this.bookingConflictMsg,
    this.timeAvailabilityMsg,
  });

  int get selectedDateCount => selectedDateKeys.length;

  bool get isMultiDay => selectedDateKeys.length > 1;

  BookingFlowState copyWith({
    int? currentStep,
    DateTime? selectedDate,
    Set<String>? selectedDateKeys,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    Map<String, PerDateTimeOverride>? perDateTimes,
    bool? isSubmitting,
    bool? isLoadingBookings,
    bool? isBooked,
    bool? isProviderStillAvailable,
    bool? isRebook,
    List<BookingModel>? existingBookings,
    List<AvailabilitySlot>? sitterAvailability,
    Set<String>? blockedDates,
    String? editBookingId,
    int? childrenCount,
    int? specialNeedsCount,
    List<ScheduleEventData>? scheduleEvents,
    List<String>? childrenNames,
    List<String>? childrenAges,
    String? notes,
    String? specialInstructions,
    String? error,
    String? dateValidationMsg,
    String? timeValidationMsg,
    String? childrenValidationMsg,
    String? notesValidationMsg,
    String? providerValidationMsg,
    String? bookingConflictMsg,
    String? timeAvailabilityMsg,
  }) {
    return BookingFlowState(
      currentStep: currentStep ?? this.currentStep,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedDateKeys: selectedDateKeys ?? this.selectedDateKeys,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      perDateTimes: perDateTimes ?? this.perDateTimes,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isLoadingBookings: isLoadingBookings ?? this.isLoadingBookings,
      isBooked: isBooked ?? this.isBooked,
      isProviderStillAvailable: isProviderStillAvailable ?? this.isProviderStillAvailable,
      isRebook: isRebook ?? this.isRebook,
      existingBookings: existingBookings ?? this.existingBookings,
      sitterAvailability: sitterAvailability ?? this.sitterAvailability,
      blockedDates: blockedDates ?? this.blockedDates,
      childrenCount: childrenCount ?? this.childrenCount,
      specialNeedsCount: specialNeedsCount ?? this.specialNeedsCount,
      scheduleEvents: scheduleEvents ?? this.scheduleEvents,
      childrenNames: childrenNames ?? this.childrenNames,
      childrenAges: childrenAges ?? this.childrenAges,
      editBookingId: editBookingId ?? this.editBookingId,
      notes: notes ?? this.notes,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      error: error,
      dateValidationMsg: dateValidationMsg,
      timeValidationMsg: timeValidationMsg,
      childrenValidationMsg: childrenValidationMsg,
      notesValidationMsg: notesValidationMsg,
      providerValidationMsg: providerValidationMsg,
      bookingConflictMsg: bookingConflictMsg,
      timeAvailabilityMsg: timeAvailabilityMsg,
    );
  }
}

class BookingFlowNotifier extends StateNotifier<BookingFlowState> {
  final BookingRepository _repository;
  final String sitterId;
  Timer? _refreshTimer;
  bool _disposed = false;
  DateTime _lastFetchTime = DateTime(2000);
  static const _cacheDuration = Duration(seconds: 15);

  BookingFlowNotifier(this._repository, this.sitterId)
      : super(BookingFlowState(
          selectedDate: DateTime.now().add(const Duration(days: 1)),
        ));

  @override
  set state(BookingFlowState value) {
    if (!_disposed) super.state = value;
  }

  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      loadExistingBookings();
    });
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    _disposed = true;
    stopAutoRefresh();
    super.dispose();
  }

  void reset() {
    _editBookingId = null;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowKey = dateKey(tomorrow);
    state = BookingFlowState(
      selectedDate: tomorrow,
      selectedDateKeys: {tomorrowKey},
    );
  }

  void goToStep(int step) {
    if (step >= 0 && step <= 4) {
      state = state.copyWith(currentStep: step);
    }
  }

  String? _editBookingId;

  bool get isEditing => _editBookingId != null;

  Future<void> loadExistingGroup(String groupId, {bool forRebook = false}) async {
    try {
      final groupData = await _repository.getBookingGroup(groupId);
      final groupBookings = groupData['bookings'] as List<dynamic>? ?? [];
      if (groupBookings.isEmpty) return;

      final first = groupBookings.first as Map<String, dynamic>;
      final firstBookingId = first['id'] as String?;
      if (!forRebook) {
        if (firstBookingId == null) return;
        _editBookingId = firstBookingId;
        state = state.copyWith(editBookingId: firstBookingId);
      }

      final startParts = (first['startTime'] as String? ?? '09:00').split(':');
      final endParts = (first['endTime'] as String? ?? '17:00').split(':');
      final start = TimeOfDay(hour: int.tryParse(startParts[0]) ?? 9, minute: int.tryParse(startParts[1]) ?? 0);
      final end = TimeOfDay(hour: int.tryParse(endParts[0]) ?? 17, minute: int.tryParse(endParts[1]) ?? 0);

      final keys = groupBookings.map((b) {
        final m = b as Map<String, dynamic>;
        return dateKey(DateTime.parse(m['date'] as String));
      }).toSet();

      final overrides = <String, PerDateTimeOverride>{};
      for (final b in groupBookings) {
        final m = b as Map<String, dynamic>;
        final dk = dateKey(DateTime.parse(m['date'] as String));
        if (m['startTime'] != null && m['endTime'] != null) {
          final st = m['startTime'] as String;
          final et = m['endTime'] as String;
          overrides[dk] = PerDateTimeOverride(
            startTime: TimeOfDay(
              hour: int.tryParse(st.split(':').first) ?? 8,
              minute: int.tryParse(st.split(':').last) ?? 0,
            ),
            endTime: TimeOfDay(
              hour: int.tryParse(et.split(':').first) ?? 8,
              minute: int.tryParse(et.split(':').last) ?? 0,
            ),
          );
        }
      }

      final firstDate = DateTime.parse(first['date'] as String);

      state = state.copyWith(
        selectedDate: firstDate,
        selectedDateKeys: keys,
        startTime: start,
        endTime: end,
        perDateTimes: overrides.isNotEmpty ? overrides : null,
        childrenCount: (first['childrenCount'] as int?) ?? 1,
        specialNeedsCount: (first['specialNeedsCount'] as int?) ?? 0,
        childrenNames: (first['childrenNames'] as List<dynamic>?)?.cast<String>() ?? [],
        childrenAges: (first['childrenAges'] as List<dynamic>?)?.cast<String>() ?? [],
        notes: first['notes'] as String?,
        specialInstructions: first['specialInstructions'] as String?,
      );
    } catch (_) {}
  }

  Future<void> loadExistingBooking(String bookingId) async {
    _editBookingId = bookingId;
    state = state.copyWith(editBookingId: bookingId);
    try {
      final booking = await _repository.getBooking(bookingId);
      await _applyBookingToState(booking);
    } catch (_) {}
    if (state.startTime != null && state.endTime != null) {
      _quickValidatePrefilledDate();
      final hadIssue = state.timeAvailabilityMsg != null;
      if (!hadIssue) {
        state = state.copyWith(bookingConflictMsg: null, timeAvailabilityMsg: null);
      }
      await loadExistingBookings();
      await _validatePrefilledTime();
      if (state.bookingConflictMsg != null || state.timeAvailabilityMsg != null) {
        state = state.copyWith(startTime: null, endTime: null, timeValidationMsg: null);
      }
    }
  }

  Future<void> prefillFromBooking(String bookingId) async {
    _editBookingId = bookingId;
    state = state.copyWith(editBookingId: bookingId);
    try {
      final booking = await _repository.getBooking(bookingId);
      _applyBookingToState(booking);
      state = state.copyWith(isRebook: true);
    } catch (_) {}
    if (state.startTime != null && state.endTime != null) {
      _quickValidatePrefilledDate();
      final hadPrefilledIssue = state.timeAvailabilityMsg != null;
      state = state.copyWith(isLoadingBookings: true);
      if (!hadPrefilledIssue) {
        state = state.copyWith(bookingConflictMsg: null, timeAvailabilityMsg: null);
      }
      await loadExistingBookings();
      state = state.copyWith(isLoadingBookings: false);
      await _validatePrefilledTime();
      if (state.bookingConflictMsg != null || state.timeAvailabilityMsg != null) {
        state = state.copyWith(startTime: null, endTime: null, timeValidationMsg: null);
      }
    }
  }

  void _quickValidatePrefilledDate() {
    if (state.startTime == null || state.endTime == null) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (state.selectedDate.isBefore(today)) {
      state = state.copyWith(
        timeAvailabilityMsg: 'The selected date has already passed. Please choose a different date.',
      );
      return;
    }
    if (isSameDay(state.selectedDate, today)) {
      final startMins = state.startTime!.hour * 60 + state.startTime!.minute;
      final nowMins = now.hour * 60 + now.minute;
      if (startMins <= nowMins) {
        state = state.copyWith(
          timeAvailabilityMsg: 'The selected time has already passed. Please choose a different time.',
        );
      }
    }
  }

  Future<void> _applyBookingToState(BookingModel booking) async {
    final startParts = booking.startTime.split(':');
    final endParts = booking.endTime.split(':');
    final start = TimeOfDay(hour: int.tryParse(startParts[0]) ?? 8, minute: int.tryParse(startParts[1]) ?? 0);
    final end = TimeOfDay(hour: int.tryParse(endParts[0]) ?? 10, minute: int.tryParse(endParts[1]) ?? 0);
    final bKey = dateKey(booking.date);

    Set<String> keys = {bKey};
    Map<String, PerDateTimeOverride> overrides = {};
    DateTime firstDate = booking.date;

    if (booking.isMultiDay && booking.bookingGroupId != null) {
      try {
        final groupData = await _repository.getBookingGroup(booking.bookingGroupId!);
        final groupBookings = groupData['bookings'] as List<dynamic>? ?? [];
        if (groupBookings.length > 1) {
          keys = groupBookings.map((b) {
            final m = b as Map<String, dynamic>;
            return dateKey(DateTime.parse(m['date'] as String));
          }).toSet();
          for (final b in groupBookings) {
            final m = b as Map<String, dynamic>;
            final dk = dateKey(DateTime.parse(m['date'] as String));
            if (m['startTime'] != null && m['endTime'] != null) {
              final st = m['startTime'] as String;
              final et = m['endTime'] as String;
              overrides[dk] = PerDateTimeOverride(
                startTime: TimeOfDay(
                  hour: int.tryParse(st.split(':').first) ?? 8,
                  minute: int.tryParse(st.split(':').last) ?? 0,
                ),
                endTime: TimeOfDay(
                  hour: int.tryParse(et.split(':').first) ?? 8,
                  minute: int.tryParse(et.split(':').last) ?? 0,
                ),
              );
            }
          }
          firstDate = DateTime.parse((groupBookings.first as Map<String, dynamic>)['date'] as String);
        }
      } catch (_) {}
    }

    state = state.copyWith(
      selectedDate: firstDate,
      selectedDateKeys: keys,
      startTime: start,
      endTime: end,
      perDateTimes: overrides.isNotEmpty ? overrides : null,
      childrenCount: booking.childrenCount ?? 1,
      specialNeedsCount: booking.specialNeedsCount,
      childrenNames: booking.childrenNames,
      childrenAges: booking.childrenAges ?? [],
      scheduleEvents: booking.scheduleEvents.map((e) => ScheduleEventData(
        timeOfDay: _parseTime(e.time),
        activity: e.activity,
      )).toList(),
      notes: booking.notes,
      specialInstructions: booking.specialInstructions,
    );
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0);
  }

  void nextStep() {
    if (state.currentStep < 3) {
      if (state.currentStep == 0) {
        if (state.isLoadingBookings) return;
        _validateAllDates();
        if (state.bookingConflictMsg != null || state.timeAvailabilityMsg != null) return;
      }
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
    if (state.currentStep == 3) {
      _validateAllDates();
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  Future<void> loadExistingBookings({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh && now.difference(_lastFetchTime) < _cacheDuration && state.existingBookings.isNotEmpty) {
      if (state.startTime != null && state.endTime != null) {
        _validateAllDates();
      }
      return;
    }
    _lastFetchTime = now;
    state = state.copyWith(isLoadingBookings: true, error: null);
    try {
      final from = DateTime(now.year, now.month, now.day);
      final to = now.add(const Duration(days: 14));
      final bookings = forceRefresh
          ? await _repository.getSitterBookings(sitterId, from, dateTo: to, forceRefresh: true)
          : await _repository.getSitterBookings(sitterId, from, dateTo: to);
      final blocked = bookings.map((b) => dateKey(b.date)).toSet();
      state = state.copyWith(
        existingBookings: bookings,
        blockedDates: blocked,
        isLoadingBookings: false,
      );
      if (state.startTime != null && state.endTime != null) {
        _validateAllDates();
      }
    } catch (e) {
      state = state.copyWith(
        isLoadingBookings: false,
        error: e is AppException ? e.message : 'Failed to load existing bookings.',
      );
    }
  }

  void setSitterAvailability(List<AvailabilitySlot> availability) {
    state = state.copyWith(sitterAvailability: availability);
  }

  void toggleDate(DateTime date) {
    final key = dateKey(date);
    final keys = Set<String>.from(state.selectedDateKeys);
    if (keys.contains(key)) {
      keys.remove(key);
    } else {
      keys.add(key);
    }
    if (keys.isEmpty) {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowKey = dateKey(tomorrow);
      keys.add(tomorrowKey);
      state = state.copyWith(
        selectedDate: tomorrow,
        selectedDateKeys: keys,
        startTime: null,
        endTime: null,
        perDateTimes: {},
        dateValidationMsg: null,
        timeValidationMsg: null,
        bookingConflictMsg: null,
        timeAvailabilityMsg: null,
      );
      return;
    }
    final firstDate = _firstDateFromKeys(keys);
    final oldKeys = state.selectedDateKeys;
    final addedKeys = keys.difference(oldKeys);
    final hasNewDates = addedKeys.isNotEmpty;
    final removedKeys = oldKeys.difference(keys);
    final keptPerDateTimes = Map<String, PerDateTimeOverride>.from(state.perDateTimes);
    for (final k in removedKeys) {
      keptPerDateTimes.remove(k);
    }
    for (final k in addedKeys) {
      if (keptPerDateTimes.containsKey(k)) {
        keptPerDateTimes.remove(k);
      }
    }
    state = state.copyWith(
      selectedDate: firstDate,
      selectedDateKeys: keys,
      perDateTimes: hasNewDates ? keptPerDateTimes : state.perDateTimes,
      dateValidationMsg: null,
      timeValidationMsg: null,
      bookingConflictMsg: null,
      timeAvailabilityMsg: null,
    );
    loadExistingBookings();
  }

  void setDate(DateTime date) {
    final key = dateKey(date);
    final keys = {key};
    state = state.copyWith(
      selectedDate: date,
      selectedDateKeys: keys,
      startTime: null,
      endTime: null,
      perDateTimes: {},
      dateValidationMsg: null,
      timeValidationMsg: null,
      bookingConflictMsg: null,
      timeAvailabilityMsg: null,
    );
    loadExistingBookings();
  }

  DateTime _firstDateFromKeys(Set<String> keys) {
    final sorted = keys.toList()..sort();
    if (sorted.isEmpty) return DateTime.now().add(const Duration(days: 1));
    final parts = sorted.first.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  void clearTimes() {
    state = state.copyWith(
      startTime: null,
      endTime: null,
      timeValidationMsg: null,
      bookingConflictMsg: null,
      timeAvailabilityMsg: null,
    );
  }

  void setStartTime(TimeOfDay time) {
    final end = state.endTime;
    final msg = _validateTime(time, end);
    if (end != null && time.hour * 60 + time.minute >= end.hour * 60 + end.minute) {
      state = state.copyWith(startTime: time, endTime: null, timeValidationMsg: msg);
    } else {
      state = state.copyWith(startTime: time, timeValidationMsg: null);
    }
    _checkConflictOnTimeChange();
  }

  void setEndTime(TimeOfDay time) {
    if (state.startTime != null &&
        time.hour * 60 + time.minute <= state.startTime!.hour * 60 + state.startTime!.minute) {
      state = state.copyWith(
        endTime: time,
        timeValidationMsg: 'End time must be after start time.',
      );
      return;
    }
    state = state.copyWith(endTime: time, timeValidationMsg: null);
    _checkConflictOnTimeChange();
  }

  void setPerDateTime(String dateKey, TimeOfDay start, TimeOfDay end) {
    final overrides = Map<String, PerDateTimeOverride>.from(state.perDateTimes);
    overrides[dateKey] = PerDateTimeOverride(startTime: start, endTime: end);
    state = state.copyWith(perDateTimes: overrides);
    _checkConflictOnTimeChange();
  }

  void clearPerDateTime(String dateKey) {
    final overrides = Map<String, PerDateTimeOverride>.from(state.perDateTimes);
    overrides.remove(dateKey);
    state = state.copyWith(perDateTimes: overrides);
    _checkConflictOnTimeChange();
  }

  void _checkConflictOnTimeChange() {
    if (state.startTime != null && state.endTime != null) {
      _validateAllDates();
    }
  }

  Future<void> _validatePrefilledTime() async {
    if (state.startTime == null || state.endTime == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = isSameDay(state.selectedDate, today);

    state = state.copyWith(timeAvailabilityMsg: null);

    if (state.selectedDate.isBefore(today)) {
      state = state.copyWith(
        timeAvailabilityMsg: 'The selected date has already passed. Please choose a different date.',
        dateValidationMsg: null,
      );
      return;
    }

    if (isToday) {
      final startMins = state.startTime!.hour * 60 + state.startTime!.minute;
      final nowMins = now.hour * 60 + now.minute;
      if (startMins <= nowMins) {
        state = state.copyWith(
          timeAvailabilityMsg: 'The selected time has already passed. Please choose a different time.',
          timeValidationMsg: null,
        );
        return;
      }
    }

    if (state.existingBookings.isEmpty) {
      await loadExistingBookings();
      if (state.startTime == null || state.endTime == null) return;
    }

    _validateAllDates();
  }

  void validateSpanAgainstRanges(List<TimeRange> ranges) {
    if (state.startTime == null || state.endTime == null) return;
    final startMins = state.startTime!.hour * 60 + state.startTime!.minute;
    final endMins = state.endTime!.hour * 60 + state.endTime!.minute;
    final spanFitsInSingleRange = ranges.any((r) =>
        startMins >= r.startMinutes && endMins <= r.endMinutes);
    if (!spanFitsInSingleRange && ranges.isNotEmpty) {
      state = state.copyWith(
        timeValidationMsg: 'The selected time range spans across a booked period. Please choose a continuous available time slot.',
      );
    } else {
      state = state.copyWith(timeValidationMsg: null);
    }
  }

  String? _validateTime(TimeOfDay? start, TimeOfDay? end) {
    if (start != null && end != null) {
      final dur = durationHours(start, end);
      if (dur < 1) return 'Minimum booking duration is 1 hour.';
    }
    return null;
  }

  void setChildrenCount(int count) {
    final msg = count < 1 ? 'At least 1 child is required.' : null;
    final oldNames = List<String>.from(state.childrenNames);
    final oldAges = List<String>.from(state.childrenAges);
    while (oldNames.length < count) { oldNames.add(''); }
    while (oldAges.length < count) { oldAges.add(''); }
    if (oldNames.length > count) oldNames.removeRange(count, oldNames.length);
    if (oldAges.length > count) oldAges.removeRange(count, oldAges.length);
    state = state.copyWith(
      childrenCount: count,
      specialNeedsCount: state.specialNeedsCount.clamp(0, count),
      childrenNames: oldNames,
      childrenAges: oldAges,
      childrenValidationMsg: msg,
    );
  }

  void setChildName(int index, String name) {
    final names = List<String>.from(state.childrenNames);
    if (index >= 0 && index < names.length) {
      names[index] = name;
      state = state.copyWith(childrenNames: names);
    }
  }

  void setChildAge(int index, String age) {
    final ages = List<String>.from(state.childrenAges);
    if (index >= 0 && index < ages.length) {
      ages[index] = age;
      state = state.copyWith(childrenAges: ages);
    }
  }

  void setSpecialNeedsCount(int count) {
    state = state.copyWith(specialNeedsCount: count);
  }

  void toggleSpecialCare(bool hasSpecial) {
    state = state.copyWith(specialNeedsCount: hasSpecial ? 1 : 0);
  }

  void validateNotes(String text) {
    if (text.length > 1000) {
      state = state.copyWith(notesValidationMsg: 'Notes must be under 1000 characters.');
    } else {
      state = state.copyWith(notesValidationMsg: null);
    }
  }

  void validateProviderAvailability({
    required bool isAvailable,
    required bool isVerified,
    String? profileStatus,
  }) {
    if (!isAvailable) {
      state = state.copyWith(
        providerValidationMsg: 'This sitter is currently unavailable.',
        isProviderStillAvailable: false,
      );
    } else if (!isVerified) {
      state = state.copyWith(
        providerValidationMsg: 'This sitter is not yet verified.',
        isProviderStillAvailable: false,
      );
    } else {
      state = state.copyWith(
        providerValidationMsg: null,
        isProviderStillAvailable: true,
      );
    }
  }

  void _validateAllDates() {
    if (state.startTime == null || state.endTime == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final key in state.selectedDateKeys) {
      final parts = key.split('-');
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));

      final override = state.perDateTimes[key];
      final dateStart = override?.startTime ?? state.startTime!;
      final dateEnd = override?.endTime ?? state.endTime!;

      if (date.isBefore(today)) {
        state = state.copyWith(
          dateValidationMsg: '$key: The selected date has already passed.',
          timeAvailabilityMsg: '$key: The selected date has already passed.',
        );
        return;
      }

      if (isSameDay(date, today)) {
        final selectedMinutes = dateStart.hour * 60 + dateStart.minute;
        final nowMinutes = now.hour * 60 + now.minute;
        if (selectedMinutes <= nowMinutes) {
          state = state.copyWith(
            timeValidationMsg: '$key: The selected time has already passed.',
            timeAvailabilityMsg: '$key: The selected time has already passed.',
          );
          return;
        }
      }

      final dayBookings = state.existingBookings
          .where((b) =>
              dateKey(b.date) == key &&
              b.status != BookingStatus.cancelled &&
              b.id != _editBookingId).toList();

      if (state.sitterAvailability.isNotEmpty) {
        final ranges = availableTimeRangesForDate(
          date, state.sitterAvailability, state.existingBookings,
          excludeBookingId: _editBookingId,
        );
        final sStart = dateStart.hour * 60 + dateStart.minute;
        final sEnd = dateEnd.hour * 60 + dateEnd.minute;
        final fitsInAny = ranges.any((r) => sStart >= r.startMinutes && sEnd <= r.endMinutes);
        if (!fitsInAny) {
          final sStartStr = _formatTimeAmPm(dateStart);
          final sEndStr = _formatTimeAmPm(dateEnd);
          final isFullyBooked = ranges.isEmpty && dayBookings.isNotEmpty;
          final msg = isFullyBooked
              ? '$key: This day is fully booked.'
              : '$key: Time ($sStartStr–$sEndStr) is not within available hours.';
          state = state.copyWith(
            timeAvailabilityMsg: msg,
          );
          return;
        }
      }

      for (final b in dayBookings) {
        final bStart = _parseMinutes(b.startTime);
        final bEnd = _parseMinutes(b.endTime);
        final sStart = dateStart.hour * 60 + dateStart.minute;
        final sEnd = dateEnd.hour * 60 + dateEnd.minute;
        if (sStart < bEnd && sEnd > bStart) {
          final sStr = _formatTimeAmPm(dateStart);
          final eStr = _formatTimeAmPm(dateEnd);
          final msg = '$key: The selected time ($sStr–$eStr) overlaps with an existing booking.';
          state = state.copyWith(
            bookingConflictMsg: msg,
            timeAvailabilityMsg: msg,
          );
          return;
        }
      }
    }

    state = state.copyWith(
      bookingConflictMsg: null,
      timeAvailabilityMsg: null,
    );
  }

  void checkForDoubleBooking() {
    _validateAllDates();
  }

  bool get hasConflictOrUnavailable =>
      state.bookingConflictMsg != null || state.timeAvailabilityMsg != null;

  int _parseMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + (parts.length > 1 ? int.parse(parts[1]) : 0);
  }

  void addScheduleEvent() {
    final events = List<ScheduleEventData>.from(state.scheduleEvents)
      ..add(const ScheduleEventData());
    state = state.copyWith(scheduleEvents: events);
  }

  void removeScheduleEvent(int index) {
    if (index >= 0 && index < state.scheduleEvents.length) {
      final events = List<ScheduleEventData>.from(state.scheduleEvents)
        ..removeAt(index);
      state = state.copyWith(scheduleEvents: events);
    }
  }

  void reorderScheduleEvents(int oldIndex, int newIndex) {
    final events = List<ScheduleEventData>.from(state.scheduleEvents);
    if (newIndex > oldIndex) newIndex--;
    if (oldIndex < events.length && newIndex < events.length) {
      final item = events.removeAt(oldIndex);
      events.insert(newIndex, item);
      state = state.copyWith(scheduleEvents: events);
    }
  }

  void updateScheduleEventTime(int index, TimeOfDay? time) {
    if (index >= 0 && index < state.scheduleEvents.length) {
      final events = List<ScheduleEventData>.from(state.scheduleEvents);
      events[index] = events[index].copyWith(timeOfDay: time);
      state = state.copyWith(scheduleEvents: events);
    }
  }

  void updateScheduleEventActivity(int index, String activity) {
    if (index >= 0 && index < state.scheduleEvents.length) {
      final events = List<ScheduleEventData>.from(state.scheduleEvents);
      events[index] = events[index].copyWith(activity: activity);
      state = state.copyWith(scheduleEvents: events);
    }
  }

  Future<String?> confirmBooking({
    required String notes,
    required String specialInstructions,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null);
    if (state.startTime == null || state.endTime == null) {
      state = state.copyWith(isSubmitting: false);
      return null;
    }
    final duration = durationHours(state.startTime!, state.endTime!);
    if (duration < 1) {
      state = state.copyWith(isSubmitting: false);
      return 'Minimum booking duration is 1 hour.';
    }

    final scheduleEventMaps = state.scheduleEvents
        .where((e) => e.timeOfDay != null && e.activity.isNotEmpty)
        .map((e) => {
              'time': formatTimeParam(e.timeOfDay!),
              'activity': e.activity,
            })
        .toList();
    try {
      if (state.isMultiDay && !state.isRebook && _editBookingId == null) {
        final dates = state.selectedDateKeys.toList()..sort();
        final perDateTimesJson = <String, Map<String, String>>{};
        for (final entry in state.perDateTimes.entries) {
          perDateTimesJson[entry.key] = entry.value.toJson();
        }
        await _repository.createBookingGroup(
          sitterId: sitterId,
          dates: dates,
          startTime: formatTimeParam(state.startTime!),
          endTime: formatTimeParam(state.endTime!),
          duration: duration,
          childrenCount: state.childrenCount,
          specialNeedsCount: state.specialNeedsCount,
          childrenNames: state.childrenNames.where((n) => n.isNotEmpty).toList(),
          childrenAges: state.childrenAges.where((a) => a.isNotEmpty).toList(),
          notes: notes,
          specialInstructions: specialInstructions,
          scheduleEvents: scheduleEventMaps,
          perDateTimes: perDateTimesJson.isNotEmpty ? perDateTimesJson : null,
        );
      } else if (state.isRebook && _editBookingId != null) {
        await _repository.rebookBooking(_editBookingId!,
          date: state.selectedDate,
          startTime: formatTimeParam(state.startTime!),
          endTime: formatTimeParam(state.endTime!),
          duration: duration,
          childrenCount: state.childrenCount,
          specialNeedsCount: state.specialNeedsCount,
          childrenNames: state.childrenNames.where((n) => n.isNotEmpty).toList(),
          childrenAges: state.childrenAges.where((a) => a.isNotEmpty).toList(),
          notes: notes,
          specialInstructions: specialInstructions,
          scheduleEvents: scheduleEventMaps,
        );
      } else if (_editBookingId != null) {
        await _repository.updateBooking(_editBookingId!,
          date: state.selectedDate,
          startTime: formatTimeParam(state.startTime!),
          endTime: formatTimeParam(state.endTime!),
          duration: duration,
          childrenCount: state.childrenCount,
          specialNeedsCount: state.specialNeedsCount,
          childrenNames: state.childrenNames.where((n) => n.isNotEmpty).toList(),
          childrenAges: state.childrenAges.where((a) => a.isNotEmpty).toList(),
          notes: notes,
          specialInstructions: specialInstructions,
          scheduleEvents: scheduleEventMaps,
        );
      } else {
        final firstKey = state.selectedDateKeys.first;
        final parts = firstKey.split('-');
        final firstDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        await _repository.createBooking(
          sitterId: sitterId,
          date: firstDate,
          startTime: formatTimeParam(state.startTime!),
          endTime: formatTimeParam(state.endTime!),
          duration: duration,
          childrenCount: state.childrenCount,
          specialNeedsCount: state.specialNeedsCount,
          childrenNames: state.childrenNames.where((n) => n.isNotEmpty).toList(),
          childrenAges: state.childrenAges.where((a) => a.isNotEmpty).toList(),
          notes: notes,
          specialInstructions: specialInstructions,
          scheduleEvents: scheduleEventMaps,
        );
      }
      state = state.copyWith(isSubmitting: false, isBooked: true);
      return null;
    } catch (error) {
      final msg = error is AppException ? error.message : 'Booking failed. Please try again.';
      state = state.copyWith(isSubmitting: false, error: msg);
      return msg;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearAllMessages() {
    state = state.copyWith(
      error: null,
      dateValidationMsg: null,
      timeValidationMsg: null,
      childrenValidationMsg: null,
      notesValidationMsg: null,
      providerValidationMsg: null,
      bookingConflictMsg: null,
      timeAvailabilityMsg: null,
    );
  }

  String _formatTimeAmPm(TimeOfDay t) {
    final hour = t.hour;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'AM' : 'PM';
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$h:$minute $period';
  }

  bool hasStepError(int step) {
    switch (step) {
      case 0:
        return state.dateValidationMsg != null ||
            state.timeValidationMsg != null ||
            state.timeAvailabilityMsg != null;
      case 1:
        return state.childrenValidationMsg != null;
      case 2:
        return state.notesValidationMsg != null;
      case 3:
        return state.providerValidationMsg != null || state.bookingConflictMsg != null;
      default:
        return false;
    }
  }
}

final bookingFlowProvider =
    StateNotifierProvider.family<BookingFlowNotifier, BookingFlowState, String>(
  (ref, sitterId) {
    return BookingFlowNotifier(ref.read(bookingRepositoryProvider), sitterId);
  },
);
