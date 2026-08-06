import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:babysitter/core/network/error_handler.dart';
import 'package:babysitter/features/booking/data/booking_flow_notifier.dart';
import 'package:babysitter/features/booking/data/booking_repository.dart';
import 'package:babysitter/features/booking/presentation/helpers/booking_helpers.dart';
import 'package:babysitter/shared/models/booking_model.dart';

class FakeBookingRepository extends BookingRepository {
  List<BookingModel> bookings = [];
  bool createBookingCalled = false;
  bool createBookingShouldThrow = false;
  bool getSitterBookingsShouldThrow = false;

  FakeBookingRepository() : super(Dio());

  @override
  Future<List<BookingModel>> getSitterBookings(
    String sitterId,
    DateTime date, {
    DateTime? dateTo,
    bool forceRefresh = false,
  }) async {
    if (getSitterBookingsShouldThrow) {
      throw AppException(message: 'Failed to load bookings.');
    }
    return bookings.where((b) {
      if (b.sitterId != sitterId) return false;
      return true;
    }).toList();
  }

  @override
  Future<BookingModel> createBooking({
    required String sitterId,
    required DateTime date,
    required String startTime,
    required String endTime,
    required int duration,
    required int childrenCount,
    int specialNeedsCount = 0,
    String? notes,
    String? address,
    String? specialInstructions,
    List<Map<String, String>>? scheduleEvents,
    List<String>? childrenNames,
    List<String>? childrenAges,
  }) async {
    if (createBookingShouldThrow) {
      throw AppException(message: 'Booking creation failed');
    }
    createBookingCalled = true;
    final startParts = startTime.split(':');
    final startHour = int.parse(startParts[0]);
    final endHour = duration > 0
        ? (startHour + duration).clamp(0, 23)
        : startHour;
    final endMin = startParts.length > 1 ? startParts[1] : '00';
    return BookingModel(
      id: 'new-booking',
      customerId: 'customer1',
      sitterId: sitterId,
      date: date,
      startTime: startTime,
      endTime: '${endHour.toString().padLeft(2, '0')}:$endMin',
      duration: duration,
      totalAmount: 100.0,
      status: BookingStatus.pending,
    );
  }
}

void main() {
  late FakeBookingRepository repo;
  late BookingFlowNotifier notifier;
  final sitterId = 'sitter-1';
  final testDate = DateTime(2027, 6, 20);
  final tomorrow = DateTime.now().add(const Duration(days: 1));

  setUp(() {
    repo = FakeBookingRepository();
    notifier = BookingFlowNotifier(repo, sitterId);
  });

  group('Initial state', () {
    test('has correct defaults', () {
      expect(notifier.state.currentStep, 0);
      expect(notifier.state.isSubmitting, false);
      expect(notifier.state.isBooked, false);
      expect(notifier.state.isProviderStillAvailable, true);
      expect(notifier.state.existingBookings, isEmpty);
      expect(notifier.state.childrenCount, 1);
      expect(notifier.state.specialNeedsCount, 0);
      expect(notifier.state.scheduleEvents, isEmpty);
      expect(notifier.state.selectedDate.year, tomorrow.year);
      expect(notifier.state.selectedDate.month, tomorrow.month);
      expect(notifier.state.selectedDate.day, tomorrow.day);
    });
  });

  group('Date selection', () {
    test('setDate updates date and resets times', () {
      notifier.setDate(testDate);
      expect(notifier.state.selectedDate, testDate);
      expect(notifier.state.startTime, isNull);
      expect(notifier.state.endTime, isNull);
    });

    test('setDate with same date is a no-op', () {
      notifier.setStartTime(const TimeOfDay(hour: 9, minute: 0));
      notifier.setEndTime(const TimeOfDay(hour: 12, minute: 0));
      notifier.setDate(testDate);
      expect(notifier.state.startTime, const TimeOfDay(hour: 9, minute: 0));
      expect(notifier.state.endTime, const TimeOfDay(hour: 12, minute: 0));

      notifier.setDate(testDate);
      expect(notifier.state.startTime, const TimeOfDay(hour: 9, minute: 0));
      expect(notifier.state.endTime, const TimeOfDay(hour: 12, minute: 0));
    });

    test('setDate loads existing bookings', () async {
      repo.bookings = [
        BookingModel(
          id: '1',
          customerId: 'customer-a',
          sitterId: sitterId,
          date: testDate,
          startTime: '09:00',
          endTime: '12:00',
          duration: 3,
          totalAmount: 150.0,
          status: BookingStatus.confirmed,
        ),
      ];
      notifier.setDate(testDate);
      await Future(() {});
      expect(notifier.state.existingBookings, isNotEmpty);
    });
  });

  group('Time selection', () {
    test('setStartTime sets the start time', () {
      notifier.setStartTime(const TimeOfDay(hour: 9, minute: 0));
      expect(notifier.state.startTime, const TimeOfDay(hour: 9, minute: 0));
    });

    test('setEndTime after start succeeds', () {
      notifier.setStartTime(const TimeOfDay(hour: 9, minute: 0));
      notifier.setEndTime(const TimeOfDay(hour: 12, minute: 0));
      expect(notifier.state.endTime, const TimeOfDay(hour: 12, minute: 0));
      expect(notifier.state.timeValidationMsg, isNull);
    });

    test('setEndTime before start shows validation error', () {
      notifier.setStartTime(const TimeOfDay(hour: 14, minute: 0));
      notifier.setEndTime(const TimeOfDay(hour: 9, minute: 0));
      expect(notifier.state.timeValidationMsg,
          'End time must be after start time.');
    });

    test('setStartTime after current end runs the if-branch but copyWith [[ prevents resetting endTime to null', () {
      notifier.setStartTime(const TimeOfDay(hour: 9, minute: 0));
      notifier.setEndTime(const TimeOfDay(hour: 12, minute: 0));
      notifier.setStartTime(const TimeOfDay(hour: 14, minute: 0));
      expect(notifier.state.endTime, const TimeOfDay(hour: 12, minute: 0));
    });

    test(
        'duration less than 1 hour caught by setEndTime equal check first',
        () {
      notifier.setStartTime(const TimeOfDay(hour: 10, minute: 0));
      notifier.setEndTime(const TimeOfDay(hour: 10, minute: 0));
      expect(notifier.state.timeValidationMsg,
          'End time must be after start time.');
    });

    test(
        'setStartTime that reduces duration below 1h does not set validation in else branch',
        () {
      notifier.setStartTime(const TimeOfDay(hour: 9, minute: 0));
      notifier.setEndTime(const TimeOfDay(hour: 12, minute: 0));
      notifier.setStartTime(const TimeOfDay(hour: 11, minute: 45));
      expect(notifier.state.timeValidationMsg, isNull);
    });
  });

  group('Children count', () {
    test('setChildrenCount validates minimum of 1', () {
      notifier.setChildrenCount(0);
      expect(notifier.state.childrenValidationMsg,
          'At least 1 child is required.');
      expect(notifier.state.childrenCount, 0);
    });

    test('setChildrenCount accepts valid counts', () {
      notifier.setChildrenCount(3);
      expect(notifier.state.childrenValidationMsg, isNull);
      expect(notifier.state.childrenCount, 3);
    });

    test('setChildrenCount clamps specialNeedsCount, setSpecialNeedsCount does not', () {
      notifier.setChildrenCount(2);
      notifier.setSpecialNeedsCount(5);
      expect(notifier.state.specialNeedsCount, 5);
      notifier.setChildrenCount(1);
      expect(notifier.state.specialNeedsCount, 1);
    });

    test('toggleSpecialCare sets count to 1 or 0', () {
      notifier.toggleSpecialCare(true);
      expect(notifier.state.specialNeedsCount, 1);
      notifier.toggleSpecialCare(false);
      expect(notifier.state.specialNeedsCount, 0);
    });
  });

  group('Provider availability validation', () {
    test('detects unavailable sitter', () {
      notifier.validateProviderAvailability(
        isAvailable: false,
        isVerified: true,
      );
      expect(notifier.state.isProviderStillAvailable, false);
      expect(notifier.state.providerValidationMsg,
          'This sitter is currently unavailable.');
    });

    test('detects unverified sitter', () {
      notifier.validateProviderAvailability(
        isAvailable: true,
        isVerified: false,
      );
      expect(notifier.state.isProviderStillAvailable, false);
      expect(notifier.state.providerValidationMsg,
          'This sitter is not yet verified.');
    });

    test('passes when available and verified', () {
      notifier.validateProviderAvailability(
        isAvailable: true,
        isVerified: true,
      );
      expect(notifier.state.isProviderStillAvailable, true);
      expect(notifier.state.providerValidationMsg, isNull);
    });
  });

  group('Notes validation', () {
    test('rejects more than 1000 characters', () {
      notifier.validateNotes('a' * 1001);
      expect(notifier.state.notesValidationMsg,
          'Notes must be under 1000 characters.');
    });

    test('accepts valid notes', () {
      notifier.validateNotes('Short note');
      expect(notifier.state.notesValidationMsg, isNull);
    });
  });

  group('Step navigation', () {
    test('goToStep navigates to valid steps', () {
      notifier.goToStep(2);
      expect(notifier.state.currentStep, 2);
      notifier.goToStep(0);
      expect(notifier.state.currentStep, 0);
    });

    test('goToStep ignores invalid steps', () {
      notifier.goToStep(-1);
      expect(notifier.state.currentStep, 0);
      notifier.goToStep(5);
      expect(notifier.state.currentStep, 0);
    });

    test('nextStep increments step', () {
      notifier.nextStep();
      expect(notifier.state.currentStep, 1);
      notifier.nextStep();
      expect(notifier.state.currentStep, 2);
    });

    test('double booking detection works with copyWith state setup', () {
      notifier.state = notifier.state.copyWith(
        selectedDate: testDate,
        selectedDateKeys: {dateKey(testDate)},
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 13, minute: 0),
        existingBookings: [
          BookingModel(
            id: '1',
            customerId: 'customer-a',
            sitterId: sitterId,
            date: testDate,
            startTime: '11:00',
            endTime: '12:00',
            duration: 1,
            totalAmount: 50.0,
            status: BookingStatus.confirmed,
          ),
        ],
        currentStep: 2,
      );

      notifier.checkForDoubleBooking();
      expect(notifier.state.bookingConflictMsg,
          '2027-06-20: The selected time overlaps with an existing booking.');
    });

    test('nextStep from step 2 reaches step 3 and conflict can be detected', () {
      notifier.state = notifier.state.copyWith(
        selectedDate: testDate,
        selectedDateKeys: {dateKey(testDate)},
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 13, minute: 0),
        existingBookings: [
          BookingModel(
            id: '1',
            customerId: 'customer-a',
            sitterId: sitterId,
            date: testDate,
            startTime: '11:00',
            endTime: '12:00',
            duration: 1,
            totalAmount: 50.0,
            status: BookingStatus.confirmed,
          ),
        ],
        currentStep: 2,
      );
      notifier.nextStep();
      expect(notifier.state.currentStep, 3);
      notifier.checkForDoubleBooking();
      expect(notifier.state.bookingConflictMsg,
          '2027-06-20: The selected time overlaps with an existing booking.');
    });

    test('nextStep does not exceed step 3', () {
      notifier.goToStep(3);
      notifier.nextStep();
      expect(notifier.state.currentStep, 3);
    });

    test('previousStep decrements step', () {
      notifier.goToStep(2);
      notifier.previousStep();
      expect(notifier.state.currentStep, 1);
    });

    test('previousStep does not go below 0', () {
      notifier.previousStep();
      expect(notifier.state.currentStep, 0);
    });
  });

  group('hasStepError', () {
    test('returns correct values for each step', () {
      expect(notifier.hasStepError(0), false);
      expect(notifier.hasStepError(1), false);
      expect(notifier.hasStepError(2), false);
      expect(notifier.hasStepError(3), false);

      notifier.setChildrenCount(0);
      expect(notifier.hasStepError(1), true);

      notifier.state = notifier.state.copyWith(
        bookingConflictMsg: 'Conflict exists.',
      );
      expect(notifier.hasStepError(3), true);
    });
  });

  group('Double booking detection', () {
    test('detects overlapping time slot', () {
      notifier.setDate(testDate);
      notifier.setStartTime(const TimeOfDay(hour: 10, minute: 0));
      notifier.setEndTime(const TimeOfDay(hour: 13, minute: 0));
      notifier.state = notifier.state.copyWith(
        existingBookings: [
          BookingModel(
            id: '1',
            customerId: 'customer-a',
            sitterId: sitterId,
            date: testDate,
            startTime: '11:00',
            endTime: '14:00',
            duration: 3,
            totalAmount: 150.0,
            status: BookingStatus.confirmed,
          ),
        ],
      );
      notifier.checkForDoubleBooking();
      expect(notifier.state.bookingConflictMsg,
          '2027-06-20: The selected time overlaps with an existing booking.');
    });

    test('detects exact edge overlap (end == start) as no conflict', () {
      notifier.setDate(testDate);
      notifier.setStartTime(const TimeOfDay(hour: 10, minute: 0));
      notifier.setEndTime(const TimeOfDay(hour: 12, minute: 0));
      notifier.state = notifier.state.copyWith(
        existingBookings: [
          BookingModel(
            id: '1',
            customerId: 'customer-a',
            sitterId: sitterId,
            date: testDate,
            startTime: '08:00',
            endTime: '10:00',
            duration: 2,
            totalAmount: 100.0,
            status: BookingStatus.confirmed,
          ),
        ],
      );
      notifier.checkForDoubleBooking();
      expect(notifier.state.bookingConflictMsg, isNull);
    });

    test('passes when no overlap exists', () {
      notifier.setDate(testDate);
      notifier.setStartTime(const TimeOfDay(hour: 10, minute: 0));
      notifier.setEndTime(const TimeOfDay(hour: 12, minute: 0));
      notifier.state = notifier.state.copyWith(
        existingBookings: [
          BookingModel(
            id: '1',
            customerId: 'customer-a',
            sitterId: sitterId,
            date: testDate,
            startTime: '08:00',
            endTime: '09:30',
            duration: 1,
            totalAmount: 75.0,
            status: BookingStatus.confirmed,
          ),
        ],
      );
      notifier.checkForDoubleBooking();
      expect(notifier.state.bookingConflictMsg, isNull);
    });

    test('excludes cancelled bookings from conflict detection', () {
      notifier.setDate(testDate);
      notifier.setStartTime(const TimeOfDay(hour: 10, minute: 0));
      notifier.setEndTime(const TimeOfDay(hour: 13, minute: 0));
      notifier.state = notifier.state.copyWith(
        existingBookings: [
          BookingModel(
            id: '1',
            customerId: 'customer-a',
            sitterId: sitterId,
            date: testDate,
            startTime: '11:00',
            endTime: '14:00',
            duration: 3,
            totalAmount: 150.0,
            status: BookingStatus.cancelled,
          ),
        ],
      );
      notifier.checkForDoubleBooking();
      expect(notifier.state.bookingConflictMsg, isNull);
    });

    test('returns early when start or end time is null', () {
      notifier.setDate(testDate);
      notifier.state = notifier.state.copyWith(
        existingBookings: [
          BookingModel(
            id: '1',
            customerId: 'customer-a',
            sitterId: sitterId,
            date: testDate,
            startTime: '11:00',
            endTime: '14:00',
            duration: 3,
            totalAmount: 150.0,
            status: BookingStatus.confirmed,
          ),
        ],
      );
      notifier.checkForDoubleBooking();
      expect(notifier.state.bookingConflictMsg, isNull);
    });

    test('ignores bookings for different dates', () {
      notifier.setDate(testDate);
      notifier.setStartTime(const TimeOfDay(hour: 10, minute: 0));
      notifier.setEndTime(const TimeOfDay(hour: 13, minute: 0));
      final differentDate = DateTime(2026, 6, 21);
      notifier.state = notifier.state.copyWith(
        existingBookings: [
          BookingModel(
            id: '1',
            customerId: 'customer-a',
            sitterId: sitterId,
            date: differentDate,
            startTime: '09:00',
            endTime: '18:00',
            duration: 9,
            totalAmount: 450.0,
            status: BookingStatus.confirmed,
          ),
        ],
      );
      notifier.checkForDoubleBooking();
      expect(notifier.state.bookingConflictMsg, isNull);
    });
  });

  group('Concurrent race condition', () {
    test('loadExistingBookings updates state then checkForDoubleBooking detects conflict',
        () async {
      notifier.setDate(testDate);
      notifier.setStartTime(const TimeOfDay(hour: 10, minute: 0));
      notifier.setEndTime(const TimeOfDay(hour: 13, minute: 0));

      expect(notifier.state.existingBookings, isEmpty);

      repo.bookings = [
        BookingModel(
          id: '1',
          customerId: 'customer-a',
          sitterId: sitterId,
          date: testDate,
          startTime: '11:00',
          endTime: '14:00',
          duration: 3,
          totalAmount: 150.0,
          status: BookingStatus.confirmed,
        ),
      ];

      await notifier.loadExistingBookings();

      expect(notifier.state.existingBookings.length, 1);
      expect(notifier.state.isLoadingBookings, false);

      notifier.checkForDoubleBooking();
      expect(notifier.state.bookingConflictMsg,
          '2027-06-20: The selected time overlaps with an existing booking.');
    });

    test(
        'loadExistingBookings fetches bookings then checkForDoubleBooking detects conflict',
        () async {
      notifier.state = notifier.state.copyWith(
        selectedDate: testDate,
        selectedDateKeys: {dateKey(testDate)},
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 13, minute: 0),
      );

      repo.bookings = [
        BookingModel(
          id: '1',
          customerId: 'customer-a',
          sitterId: sitterId,
          date: testDate,
          startTime: '11:00',
          endTime: '12:00',
          duration: 1,
          totalAmount: 50.0,
          status: BookingStatus.confirmed,
        ),
      ];

      await notifier.loadExistingBookings();

      expect(notifier.state.existingBookings.length, 1);
      expect(notifier.state.isLoadingBookings, false);

      notifier.checkForDoubleBooking();
      expect(notifier.state.bookingConflictMsg, isNotNull);
    });

    test('startAutoRefresh and stopAutoRefresh manage timer lifecycle',
        () {
      notifier.startAutoRefresh();
      notifier.stopAutoRefresh();
      expect(notifier.state.currentStep, 0);
    });
  });

  group('Confirm booking', () {
    test('successfully creates booking and updates state', () async {
      notifier.setDate(testDate);
      notifier.setStartTime(const TimeOfDay(hour: 9, minute: 0));
      notifier.setEndTime(const TimeOfDay(hour: 12, minute: 0));

      final result = await notifier.confirmBooking(
        notes: 'Test notes',
        specialInstructions: '',
      );

      expect(result, isNull);
      expect(repo.createBookingCalled, true);
      expect(notifier.state.isBooked, true);
      expect(notifier.state.isSubmitting, false);
      expect(notifier.state.error, isNull);
    });

    test('handles repository error', () async {
      repo.createBookingShouldThrow = true;
      notifier.setDate(testDate);
      notifier.setStartTime(const TimeOfDay(hour: 9, minute: 0));
      notifier.setEndTime(const TimeOfDay(hour: 12, minute: 0));

      final result = await notifier.confirmBooking(
        notes: 'Test',
        specialInstructions: '',
      );

      expect(result, 'Booking creation failed');
      expect(notifier.state.isBooked, false);
      expect(notifier.state.isSubmitting, false);
      expect(notifier.state.error, 'Booking creation failed');
    });

    test('returns null when times are not set', () async {
      final result = await notifier.confirmBooking(
        notes: '',
        specialInstructions: '',
      );

      expect(result, isNull);
      expect(repo.createBookingCalled, false);
    });

    test('rejects duration less than 1 hour', () async {
      notifier.setDate(testDate);
      notifier.setStartTime(const TimeOfDay(hour: 10, minute: 0));
      notifier.setEndTime(const TimeOfDay(hour: 10, minute: 30));

      final result = await notifier.confirmBooking(
        notes: '',
        specialInstructions: '',
      );

      expect(result, 'Minimum booking duration is 1 hour.');
      expect(notifier.state.isSubmitting, false);
    });
  });

  group('Schedule events', () {
    test('addScheduleEvent adds event', () {
      notifier.addScheduleEvent();
      expect(notifier.state.scheduleEvents.length, 1);
      notifier.addScheduleEvent();
      expect(notifier.state.scheduleEvents.length, 2);
    });

    test('removeScheduleEvent removes event at index', () {
      notifier.addScheduleEvent();
      notifier.addScheduleEvent();
      notifier.removeScheduleEvent(0);
      expect(notifier.state.scheduleEvents.length, 1);
    });

    test('removeScheduleEvent ignores invalid index', () {
      notifier.removeScheduleEvent(-1);
      notifier.removeScheduleEvent(0);
      expect(notifier.state.scheduleEvents.length, 0);
    });

    test('updateScheduleEventTime updates time', () {
      notifier.addScheduleEvent();
      notifier.updateScheduleEventTime(
        0,
        const TimeOfDay(hour: 14, minute: 0),
      );
      expect(
        notifier.state.scheduleEvents[0].timeOfDay,
        const TimeOfDay(hour: 14, minute: 0),
      );
    });

    test('updateScheduleEventActivity updates activity', () {
      notifier.addScheduleEvent();
      notifier.updateScheduleEventActivity(0, 'Playtime');
      expect(notifier.state.scheduleEvents[0].activity, 'Playtime');
    });

    test('reorderScheduleEvents moves item down correctly', () {
      notifier.addScheduleEvent();
      notifier.updateScheduleEventActivity(0, 'First');
      notifier.addScheduleEvent();
      notifier.updateScheduleEventActivity(1, 'Second');
      notifier.reorderScheduleEvents(1, 0);
      expect(notifier.state.scheduleEvents[0].activity, 'Second');
      expect(notifier.state.scheduleEvents[1].activity, 'First');
    });
  });

  group('Reset and clear', () {
    test('reset clears state to defaults', () {
      notifier.goToStep(2);
      notifier.setStartTime(const TimeOfDay(hour: 9, minute: 0));
      notifier.setDate(testDate);
      notifier.setChildrenCount(3);

      notifier.reset();

      expect(notifier.state.currentStep, 0);
      expect(notifier.state.startTime, isNull);
      expect(notifier.state.endTime, isNull);
      expect(notifier.state.childrenCount, 1);
      expect(notifier.state.specialNeedsCount, 0);
    });

    test('clearError clears error', () {
      notifier.state = notifier.state.copyWith(error: 'Some error');
      notifier.clearError();
      expect(notifier.state.error, isNull);
    });
  });
}
