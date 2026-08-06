import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/utils/time_formatter.dart';
import 'package:babysitter/shared/models/booking_model.dart';
import 'package:babysitter/shared/models/user_model.dart';

enum DayStatus {
  available,
  partiallyBooked,
  fullyBooked,
  nonWorking,
  past,
  outOfRange,
}

class CalendarDayInfo {
  final DateTime date;
  final DayStatus status;
  final bool isToday;
  final bool isSelected;
  final int remainingCapacityMinutes;
  final int totalAvailableMinutes;

  const CalendarDayInfo({
    required this.date,
    required this.status,
    required this.isToday,
    required this.isSelected,
    this.remainingCapacityMinutes = 0,
    this.totalAvailableMinutes = 0,
  });

  bool get isSelectable =>
      status == DayStatus.available ||
      status == DayStatus.partiallyBooked;
}

class CalendarMonthData {
  final int year;
  final int month;
  final String locale;
  final List<CalendarDayInfo> days;

  const CalendarMonthData({
    required this.year,
    required this.month,
    this.locale = 'en',
    required this.days,
  });

  String get monthName =>
      DateFormat('MMMM', locale).format(DateTime(year, month, 1));

  int get daysInMonth {
    return DateTime(year, month + 1, 0).day;
  }

  int get firstWeekday {
    final first = DateTime(year, month, 1);
    return (first.weekday + 1) % 7;
  }
}

class StatusVisual {
  final IconData icon;
  final String label;
  final Color color;
  final Color badgeColor;
  final String description;

  const StatusVisual({
    required this.icon,
    required this.label,
    required this.color,
    required this.badgeColor,
    required this.description,
  });
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

// TODO: Pass locale from context/ref instead of defaulting to 'en'
String formatTime(TimeOfDay t, {String locale = 'en'}) {
  return TimeFormatter.formatTimeOfDay(t, locale);
}

String formatTimeParam(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

bool isDateBlocked(DateTime date, Set<String> blockedDates) =>
    blockedDates.contains(dateKey(date));

int durationHours(TimeOfDay? startTime, TimeOfDay? endTime) {
  if (startTime == null || endTime == null) return 0;
  final s = startTime.hour * 60 + startTime.minute;
  final e = endTime.hour * 60 + endTime.minute;
  if (e <= s) return 0;
  return (e - s) ~/ 60;
}

int durationMinutes(TimeOfDay start, TimeOfDay end) {
  final s = start.hour * 60 + start.minute;
  final e = end.hour * 60 + end.minute;
  if (e <= s) return 0;
  return e - s;
}

int timeToMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

int toApiDayOfWeek(DateTime date) => date.weekday % 7;

bool isWorkingDay(DateTime date, List<AvailabilitySlot> availability) {
  if (availability.isEmpty) return true;
  final dayOfWeek = toApiDayOfWeek(date);
  return availability.any((slot) => slot.dayOfWeek == dayOfWeek);
}

int availableMinutesForDate(
    DateTime date, List<AvailabilitySlot> availability) {
  final dayOfWeek = toApiDayOfWeek(date);
  final slots = availability.where((s) => s.dayOfWeek == dayOfWeek);
  int total = 0;
  for (final slot in slots) {
    final startParts = slot.startTime.split(':');
    final endParts = slot.endTime.split(':');
    final startMin = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
    total += endMin - startMin;
  }
  return total;
}

int bookedMinutesForDate(
    DateTime date, List<BookingModel> existingBookings, {String? excludeBookingId}) {
  final dayBookings = existingBookings.where((b) =>
      b.date.year == date.year &&
      b.date.month == date.month &&
      b.date.day == date.day &&
      b.status != BookingStatus.cancelled &&
      b.id != excludeBookingId);
  int total = 0;
  for (final b in dayBookings) {
    final startParts = b.startTime.split(':');
    final endParts = b.endTime.split(':');
    final startMin = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
    total += endMin - startMin;
  }
  return total;
}

int remainingCapacityMinutesForDate(
    DateTime date, List<AvailabilitySlot> availability, List<BookingModel> existingBookings, {String? excludeBookingId}) {
  final avail = availableMinutesForDate(date, availability);
  final booked = bookedMinutesForDate(date, existingBookings, excludeBookingId: excludeBookingId);
  return (avail - booked).clamp(0, avail);
}

DayStatus dayStatusForDate(
  DateTime date,
  List<AvailabilitySlot> availability,
  List<BookingModel> existingBookings, {
  String? excludeBookingId,
}) {
  if (!isWorkingDay(date, availability)) return DayStatus.nonWorking;
  final availMin = availableMinutesForDate(date, availability);
  final bookedMin = bookedMinutesForDate(date, existingBookings, excludeBookingId: excludeBookingId);
  if (availMin > 0 && bookedMin >= availMin) return DayStatus.fullyBooked;
  if (bookedMin > 0) return DayStatus.partiallyBooked;
  return DayStatus.available;
}

DayStatus calendarDayStatusForDate(
  DateTime date,
  List<AvailabilitySlot> availability,
  List<BookingModel> existingBookings,
  DateTime today,
  DateTime maxDate, {
  String? excludeBookingId,
}) {
  final dateOnly = DateTime(date.year, date.month, date.day);
  final todayOnly = DateTime(today.year, today.month, today.day);
  final maxDateOnly = DateTime(maxDate.year, maxDate.month, maxDate.day);

  if (dateOnly.isBefore(todayOnly)) return DayStatus.past;
  if (dateOnly.isAfter(maxDateOnly)) return DayStatus.outOfRange;

  return dayStatusForDate(date, availability, existingBookings, excludeBookingId: excludeBookingId);
}

String _statusLabel(DayStatus status, Map<String, String>? strings) {
  if (strings == null) return '';
  final key = switch (status) {
    DayStatus.available => AppLocalization.status_available,
    DayStatus.partiallyBooked => AppLocalization.status_partial,
    DayStatus.fullyBooked => AppLocalization.status_fully_booked,
    DayStatus.nonWorking => AppLocalization.status_closed,
    DayStatus.past => AppLocalization.status_past,
    DayStatus.outOfRange => AppLocalization.status_unavailable,
  };
  final v = strings[key];
  if (v != null && v.isNotEmpty) return v;
  return '';
}

StatusVisual statusVisualFor(DayStatus status, {bool isToday = false, Map<String, String>? strings}) {
  final label = _statusLabel(status, strings);
  switch (status) {
    case DayStatus.available:
      return StatusVisual(
        icon: Icons.check_circle_rounded,
        label: label.isNotEmpty ? label : 'Available',
        color: const Color(0xFF22C55E),
        badgeColor: const Color(0xFF22C55E),
        description: label.isNotEmpty ? label : 'Appointments available.',
      );
    case DayStatus.partiallyBooked:
      return StatusVisual(
        icon: Icons.access_time_rounded,
        label: label.isNotEmpty ? label : 'Some slots left',
        color: const Color(0xFFF59E0B),
        badgeColor: const Color(0xFFF59E0B),
        description: label.isNotEmpty ? label : 'Limited slots remaining.',
      );
    case DayStatus.fullyBooked:
      return StatusVisual(
        icon: Icons.block_rounded,
        label: label.isNotEmpty ? label : 'Fully Booked',
        color: const Color(0xFFEF4444),
        badgeColor: const Color(0xFFEF4444),
        description: label.isNotEmpty ? label : 'All available appointments have already been reserved.',
      );
    case DayStatus.nonWorking:
      return StatusVisual(
        icon: Icons.event_busy_rounded,
        label: label.isNotEmpty ? label : 'Closed',
        color: const Color(0xFF94A3B8),
        badgeColor: const Color(0xFF94A3B8),
        description: label.isNotEmpty ? label : 'This service is unavailable on this day.',
      );
    case DayStatus.past:
      return StatusVisual(
        icon: Icons.history_rounded,
        label: label.isNotEmpty ? label : 'Past',
        color: const Color(0xFFCBD5E1),
        badgeColor: const Color(0xFFCBD5E1),
        description: label.isNotEmpty ? label : 'Bookings can only be made for upcoming dates.',
      );
    case DayStatus.outOfRange:
      return StatusVisual(
        icon: Icons.date_range_rounded,
        label: label.isNotEmpty ? label : 'Unavailable',
        color: const Color(0xFFCBD5E1),
        badgeColor: const Color(0xFFCBD5E1),
        description: label.isNotEmpty ? label : 'This date is outside the available booking period.',
      );
  }
}

String statusMessage(DayStatus status, String weekday, String dateStr) {
  switch (status) {
    case DayStatus.available:
      return '$weekday, $dateStr \u2022 Open for bookings';
    case DayStatus.partiallyBooked:
      return '$weekday, $dateStr \u2022 Some slots available';
    case DayStatus.fullyBooked:
      return '$weekday, $dateStr \u2022 All appointments reserved';
    case DayStatus.nonWorking:
      return '$weekday, $dateStr \u2022 Service unavailable on this day';
    case DayStatus.past:
      return '$weekday, $dateStr \u2022 This date has passed';
    case DayStatus.outOfRange:
      return '$weekday, $dateStr \u2022 Outside booking period';
  }
}

CalendarMonthData buildCalendarMonth(
  int year,
  int month,
  DateTime selectedDate,
  List<AvailabilitySlot> availability,
  List<BookingModel> existingBookings,
  DateTime today,
  DateTime maxDate, {
  String? excludeBookingId,
  String locale = 'en',
  Set<String>? selectedDateKeys,
}) {
  final firstDay = DateTime(year, month, 1);
  final daysInMonth = DateTime(year, month + 1, 0).day;
  final firstWeekday = (firstDay.weekday + 1) % 7;

  final days = <CalendarDayInfo>[];

  for (int i = 0; i < firstWeekday; i++) {
    final prevMonthDay = DateTime(year, month, -firstWeekday + i + 1);
    days.add(CalendarDayInfo(
      date: prevMonthDay,
      status: DayStatus.outOfRange,
      isToday: false,
      isSelected: false,
    ));
  }

  for (int day = 1; day <= daysInMonth; day++) {
    final date = DateTime(year, month, day);
    final status = calendarDayStatusForDate(
      date, availability, existingBookings, today, maxDate, excludeBookingId: excludeBookingId,
    );
    final remaining = remainingCapacityMinutesForDate(date, availability, existingBookings, excludeBookingId: excludeBookingId);
    final totalAvail = availableMinutesForDate(date, availability);
    days.add(CalendarDayInfo(
      date: date,
      status: status,
      isToday: isSameDay(date, today),
      isSelected: selectedDateKeys?.contains(dateKey(date)) ?? isSameDay(date, selectedDate),
      remainingCapacityMinutes: remaining,
      totalAvailableMinutes: totalAvail,
    ));
  }

  final remaining = 42 - days.length;
  for (int i = 1; i <= remaining; i++) {
    final nextMonthDay = DateTime(year, month + 1, i);
    days.add(CalendarDayInfo(
      date: nextMonthDay,
      status: DayStatus.outOfRange,
      isToday: false,
      isSelected: false,
    ));
  }

  return CalendarMonthData(year: year, month: month, locale: locale, days: days);
}

DateTime? firstAvailableDate(
  DateTime from,
  List<AvailabilitySlot> availability,
  List<BookingModel> existingBookings,
  DateTime maxDate, {
  String? excludeBookingId,
}) {
  for (int i = 0; i < 90; i++) {
    final date = from.add(Duration(days: i));
    if (date.isAfter(maxDate)) break;
    final status = dayStatusForDate(date, availability, existingBookings, excludeBookingId: excludeBookingId);
    if (status == DayStatus.available || status == DayStatus.partiallyBooked) {
      return date;
    }
  }
  return null;
}

class ScheduleEventData {
  final TimeOfDay? timeOfDay;
  final String activity;

  const ScheduleEventData({this.timeOfDay, this.activity = ''});

  ScheduleEventData copyWith({TimeOfDay? timeOfDay, String? activity}) =>
      ScheduleEventData(
        timeOfDay: timeOfDay ?? this.timeOfDay,
        activity: activity ?? this.activity,
      );
}

class TimeRange {
  final int startMinutes;
  final int endMinutes;

  const TimeRange({required this.startMinutes, required this.endMinutes});

  int get durationMins => endMinutes - startMinutes;
  double get durationHours => durationMins / 60.0;
}

String localizeValidationMessage(String msg, Map<String, String> strings, {String locale = 'en'}) {
  String formatDateKey(String key) {
    final parts = key.split('-');
    if (parts.length != 3) return key;
    final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    try {
      return DateFormat.yMMMEd(locale).format(date);
    } catch (_) {
      return DateFormat.yMMMEd().format(date);
    }
  }

  final datePassed = RegExp(r'^([\d-]+): The selected date has already passed\.$');
  final timePassed = RegExp(r'^([\d-]+): The selected time has already passed\.$');
  final notAvailable = RegExp(r'^([\d-]+): Time \(([^–]+)–([^)]+)\) is not within available hours\.$');
  final overlap = RegExp(r'^([\d-]+): The selected time \(([^–]+)–([^)]+)\) overlaps with an existing booking\.$');
  final fullyBooked = RegExp(r'^([\d-]+): This day is fully booked\.$');

  String? m;
  m = datePassed.firstMatch(msg)?.group(1);
  if (m != null) return strings[AppLocalization.validation_date_passed]?.replaceAll('{date}', formatDateKey(m)) ?? msg;

  m = timePassed.firstMatch(msg)?.group(1);
  if (m != null) return strings[AppLocalization.validation_time_passed]?.replaceAll('{date}', formatDateKey(m)) ?? msg;

  m = fullyBooked.firstMatch(msg)?.group(1);
  if (m != null) return strings[AppLocalization.validation_fully_booked]?.replaceAll('{date}', formatDateKey(m)) ?? msg;

  final na = notAvailable.firstMatch(msg);
  if (na != null) {
    return strings[AppLocalization.validation_not_available]
        ?.replaceAll('{date}', formatDateKey(na.group(1)!))
        .replaceAll('{start}', na.group(2)!)
        .replaceAll('{end}', na.group(3)!) ?? msg;
  }

  final ov = overlap.firstMatch(msg);
  if (ov != null) {
    return strings[AppLocalization.validation_overlap]
        ?.replaceAll('{date}', formatDateKey(ov.group(1)!))
        .replaceAll('{start}', ov.group(2)!)
        .replaceAll('{end}', ov.group(3)!) ?? msg;
  }

  if (msg == 'Minimum booking duration is 1 hour.') {
    return strings[AppLocalization.booking_min_1hour] ?? msg;
  }
  if (msg == 'End time must be after start time.') {
    return strings[AppLocalization.end_after_start] ?? msg;
  }
  if (msg == 'At least 1 child is required.') {
    return strings[AppLocalization.at_least_1_child] ?? msg;
  }
  if (msg == 'Notes must be under 1000 characters.') {
    return strings[AppLocalization.notes_max_1000] ?? msg;
  }
  if (msg == 'This sitter is currently unavailable.') {
    return strings[AppLocalization.sitter_unavailable] ?? msg;
  }
  if (msg == 'This sitter is not yet verified.') {
    return strings[AppLocalization.sitter_not_verified] ?? msg;
  }
  if (msg == 'Booking failed. Please try again.') {
    return strings[AppLocalization.booking_failed] ?? msg;
  }
  if (msg == 'Failed to load existing bookings.') {
    return strings[AppLocalization.failed_load_bookings] ?? msg;
  }
  if (msg == 'Too Many Attempts.' || msg == 'Too many requests. Please try again later.') {
    return strings[AppLocalization.too_many_requests] ?? msg;
  }

  return msg;
}

class BookableSlot {
  final int startMinutes;
  final int endMinutes;
  final bool isPast;
  final double capacityFraction;

  const BookableSlot({
    required this.startMinutes,
    required this.endMinutes,
    required this.isPast,
    required this.capacityFraction,
  });

  bool get isAvailable => !isPast && capacityFraction > 0;
  int get durationMins => endMinutes - startMinutes;
}

SlotStatus slotStatusFor(double capacityFraction) {
  if (capacityFraction <= 0) return SlotStatus.fullyBooked;
  if (capacityFraction <= 0.25) return SlotStatus.lastSlot;
  if (capacityFraction <= 0.50) return SlotStatus.limited;
  return SlotStatus.available;
}

enum SlotStatus { available, limited, lastSlot, fullyBooked }

List<TimeRange> availableTimeRangesForDate(
  DateTime date,
  List<AvailabilitySlot> availability,
  List<BookingModel> existingBookings, {
  String? excludeBookingId,
}) {
  final dayOfWeek = toApiDayOfWeek(date);
  final slots = availability.where((s) => s.dayOfWeek == dayOfWeek).toList();
  if (slots.isEmpty) return [];

  final dayBookings = existingBookings.where((b) =>
      b.date.year == date.year &&
      b.date.month == date.month &&
      b.date.day == date.day &&
      b.status != BookingStatus.cancelled &&
      b.id != excludeBookingId).toList();

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final isToday = isSameDay(date, today);
  final nowMinutes = now.hour * 60 + now.minute;

  final ranges = <TimeRange>[];
  for (final slot in slots) {
    final startParts = slot.startTime.split(':');
    final endParts = slot.endTime.split(':');
    final sStart = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final sEnd = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

    var effectiveStart = sStart;
    if (isToday) {
      final roundedNow = ((nowMinutes + 14) ~/ 15) * 15 + 15;
      effectiveStart = effectiveStart > roundedNow ? effectiveStart : roundedNow;
    }
    if (effectiveStart >= sEnd) continue;

    var currentStart = effectiveStart;
    final bookedSlots = <TimeRange>[];
    for (final b in dayBookings) {
      final bSp = b.startTime.split(':');
      final bEp = b.endTime.split(':');
      final bStart = int.parse(bSp[0]) * 60 + int.parse(bSp[1]);
      final bEnd = int.parse(bEp[0]) * 60 + int.parse(bEp[1]);
      if (bEnd > currentStart && bStart < sEnd) {
        bookedSlots.add(TimeRange(startMinutes: bStart, endMinutes: bEnd));
      }
    }
    bookedSlots.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

    for (final booked in bookedSlots) {
      if (booked.startMinutes > currentStart) {
        ranges.add(TimeRange(startMinutes: currentStart, endMinutes: booked.startMinutes));
      }
      currentStart = booked.endMinutes > currentStart ? booked.endMinutes : currentStart;
    }
    if (currentStart < sEnd) {
      ranges.add(TimeRange(startMinutes: currentStart, endMinutes: sEnd));
    }
  }
  return ranges;
}

List<BookableSlot> bookableSlotsForDate(
  DateTime date,
  List<AvailabilitySlot> availability,
  List<BookingModel> existingBookings, {
  int slotIntervalMinutes = 60,
  String? excludeBookingId,
}) {
  final ranges = availableTimeRangesForDate(date, availability, existingBookings, excludeBookingId: excludeBookingId);
  if (ranges.isEmpty) return [];

  final totalDayMinutes = availableMinutesForDate(date, availability);
  final remainingMinutes = remainingCapacityMinutesForDate(date, availability, existingBookings);
  final overallFraction = totalDayMinutes > 0 ? remainingMinutes / totalDayMinutes : 0.0;

  final now = DateTime.now();
  final isToday = isSameDay(date, DateTime(now.year, now.month, now.day));
  final nowMinutes = now.hour * 60 + now.minute;

  final slots = <BookableSlot>[];
  for (final range in ranges) {
    var slotStart = range.startMinutes;
    while (slotStart + slotIntervalMinutes <= range.endMinutes) {
      final slotEnd = slotStart + slotIntervalMinutes;
      bool isPast = false;
      if (isToday && slotEnd <= nowMinutes) {
        isPast = true;
      }
      slots.add(BookableSlot(
        startMinutes: slotStart,
        endMinutes: slotEnd,
        isPast: isPast,
        capacityFraction: overallFraction,
      ));
      slotStart += slotIntervalMinutes;
    }
  }
  return slots;
}

TimeOfDay? nextAvailableStartTime(
  TimeOfDay desired,
  List<TimeRange> ranges,
  int minDurationMinutes,
) {
  ranges.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
  final desiredMins = desired.hour * 60 + desired.minute;
  for (final r in ranges) {
    if (r.endMinutes - desiredMins >= minDurationMinutes) {
      final start = desiredMins > r.startMinutes ? desiredMins : r.startMinutes;
      return TimeOfDay(hour: start ~/ 60, minute: start % 60);
    }
    if (r.endMinutes - r.startMinutes >= minDurationMinutes) {
      return TimeOfDay(hour: r.startMinutes ~/ 60, minute: r.startMinutes % 60);
    }
  }
  return null;
}

String _slotLabel(SlotStatus status, Map<String, String>? strings) {
  if (strings == null) return '';
  final key = switch (status) {
    SlotStatus.available => AppLocalization.slot_available,
    SlotStatus.limited => AppLocalization.slot_limited,
    SlotStatus.lastSlot => AppLocalization.slot_last,
    SlotStatus.fullyBooked => AppLocalization.slot_full,
  };
  final v = strings[key];
  if (v != null && v.isNotEmpty) return v;
  return '';
}

StatusVisual slotStatusVisualFor(SlotStatus status, {Map<String, String>? strings}) {
  final label = _slotLabel(status, strings);
  switch (status) {
    case SlotStatus.available:
      return StatusVisual(
        icon: Icons.check_circle_rounded,
        label: label.isNotEmpty ? label : 'Available',
        color: const Color(0xFF22C55E),
        badgeColor: const Color(0xFF22C55E),
        description: label.isNotEmpty ? label : 'This time slot is available.',
      );
    case SlotStatus.limited:
      return StatusVisual(
        icon: Icons.access_time_rounded,
        label: label.isNotEmpty ? label : 'Limited',
        color: const Color(0xFFF59E0B),
        badgeColor: const Color(0xFFF59E0B),
        description: label.isNotEmpty ? label : 'Few openings remain for this time.',
      );
    case SlotStatus.lastSlot:
      return StatusVisual(
        icon: Icons.alarm_rounded,
        label: label.isNotEmpty ? label : 'Last',
        color: const Color(0xFFEF4444),
        badgeColor: const Color(0xFFEF4444),
        description: label.isNotEmpty ? label : 'Only one opening remains.',
      );
    case SlotStatus.fullyBooked:
      return StatusVisual(
        icon: Icons.block_rounded,
        label: label.isNotEmpty ? label : 'Full',
        color: const Color(0xFF94A3B8),
        badgeColor: const Color(0xFF94A3B8),
        description: label.isNotEmpty ? label : 'This time slot is no longer available.',
      );
  }
}

bool isTimeWithinAvailability(
  DateTime date,
  TimeOfDay start,
  TimeOfDay end,
  List<AvailabilitySlot> availability,
) {
  final dayOfWeek = toApiDayOfWeek(date);
  final slots = availability.where((s) => s.dayOfWeek == dayOfWeek);
  final startMins = start.hour * 60 + start.minute;
  final endMins = end.hour * 60 + end.minute;
  for (final slot in slots) {
    final slotParts = slot.startTime.split(':');
    final slotEndParts = slot.endTime.split(':');
    final slotStart = int.parse(slotParts[0]) * 60 + int.parse(slotParts[1]);
    final slotEnd = int.parse(slotEndParts[0]) * 60 + int.parse(slotEndParts[1]);
    if (startMins >= slotStart && endMins <= slotEnd) return true;
  }
  return false;
}

// TODO: Pass locale from context/ref instead of defaulting to 'en'
String? earliestAvailableTimeDescription(List<TimeRange> ranges, int minDurationMinutes, {String locale = 'en'}) {
  if (ranges.isEmpty) return null;
  final sorted = List<TimeRange>.from(ranges)..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
  for (final r in sorted) {
    if (r.durationMins >= minDurationMinutes) {
      final t = TimeOfDay(hour: r.startMinutes ~/ 60, minute: r.startMinutes % 60);
      return TimeFormatter.formatTimeOfDay(t, locale);
    }
  }
  return null;
}

class PerDateTimeOverride {
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  const PerDateTimeOverride({
    required this.startTime,
    required this.endTime,
  });

  PerDateTimeOverride copyWith({TimeOfDay? startTime, TimeOfDay? endTime}) =>
      PerDateTimeOverride(
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
      );

  Map<String, String> toJson() => {
        'start_time': formatTimeParam(startTime),
        'end_time': formatTimeParam(endTime),
      };
}

TimeOfDay? timeForDate(
  String dateKey,
  TimeOfDay? defaultStart,
  TimeOfDay? defaultEnd,
  Map<String, PerDateTimeOverride> overrides,
  {required bool isStart}
) {
  if (overrides.containsKey(dateKey)) {
    final override = overrides[dateKey]!;
    return isStart ? override.startTime : override.endTime;
  }
  return isStart ? defaultStart : defaultEnd;
}

bool hasTimeForDate(
  String dateKey,
  TimeOfDay? defaultStart,
  TimeOfDay? defaultEnd,
  Map<String, PerDateTimeOverride> overrides,
) {
  return overrides.containsKey(dateKey) || (defaultStart != null && defaultEnd != null);
}

class BookingGroupDisplayItem {
  final String? groupId;
  final List<BookingModel> children;

  const BookingGroupDisplayItem({
    required this.groupId,
    required this.children,
  });

  bool get isGroup => groupId != null && children.length > 1;
  BookingModel get primaryBooking {
    const priorityOrder = [
      BookingStatus.inProgress,
      BookingStatus.completed,
      BookingStatus.confirmed,
      BookingStatus.pending,
      BookingStatus.cancelled,
      BookingStatus.rejected,
      BookingStatus.expired,
    ];
    BookingModel? best;
    int bestIdx = priorityOrder.length;
    for (final b in children) {
      final idx = priorityOrder.indexOf(b.status);
      if (idx >= 0 && idx < bestIdx) {
        bestIdx = idx;
        best = b;
      }
    }
    return best ?? children.first;
  }
  DateTime get firstDate => children
      .map((b) => b.date)
      .reduce((a, b) => a.isBefore(b) ? a : b);
  DateTime get lastDate => children
      .map((b) => b.date)
      .reduce((a, b) => a.isAfter(b) ? a : b);
  double get totalAmount =>
      children.fold(0.0, (sum, b) => sum + b.totalAmount);
  int get dayCount => children.length;
  UserModel? get sitter => children.first.sitter;
  UserModel? get customer => children.first.customer;
}

List<BookingGroupDisplayItem> groupBookings(List<BookingModel> bookings) {
  final map = <String?, List<BookingModel>>{};
  for (final b in bookings) {
    final key = b.bookingGroupId ?? b.id;
    map.putIfAbsent(key, () => []);
    map[key]!.add(b);
  }
  final result = map.values.map((list) {
    list.sort((a, b) => a.date.compareTo(b.date));
    return BookingGroupDisplayItem(
      groupId: list.first.bookingGroupId,
      children: list,
    );
  }).toList();
  result.sort((a, b) => b.lastDate.compareTo(a.lastDate));
  return result;
}
