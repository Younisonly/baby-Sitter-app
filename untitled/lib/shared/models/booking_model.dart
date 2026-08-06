import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:babysitter/shared/models/user_model.dart';

part 'booking_model.freezed.dart';
part 'booking_model.g.dart';

enum BookingStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('confirmed')
  confirmed,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('rejected')
  rejected,
  @JsonValue('expired')
  expired,
}

enum SessionStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('start_qr_generated')
  startQrGenerated,
  @JsonValue('active')
  active,
  @JsonValue('end_qr_generated')
  endQrGenerated,
  @JsonValue('completed')
  completed,
}

extension BookingStatusX on BookingStatus {
  bool get isActive => this == BookingStatus.pending || this == BookingStatus.confirmed || this == BookingStatus.inProgress;
  bool get isTerminal => this == BookingStatus.completed || this == BookingStatus.cancelled || this == BookingStatus.rejected || this == BookingStatus.expired;
  bool get canCancel => this == BookingStatus.pending || this == BookingStatus.confirmed;
  bool get canEdit => this == BookingStatus.pending || this == BookingStatus.confirmed;
  bool get canRebook => this == BookingStatus.completed || this == BookingStatus.cancelled;
  bool get canReview => this == BookingStatus.completed;
}

extension SessionStatusX on SessionStatus {
  bool get isActive => this == SessionStatus.active;
  bool get isPending => this == SessionStatus.pending;
  bool get isCompleted => this == SessionStatus.completed;
  bool get hasQrGenerated => this == SessionStatus.startQrGenerated || this == SessionStatus.endQrGenerated;
}

extension BookingModelX on BookingModel {
  bool get isPastDue {
    if (status != BookingStatus.pending && status != BookingStatus.confirmed) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bookingDate = DateTime(date.year, date.month, date.day);
    if (bookingDate.isBefore(today)) return true;
    if (bookingDate.isAfter(today)) return false;
    if (endTime.isEmpty) return false;
    final parts = endTime.split(':');
    if (parts.length < 2) return false;
    final end = DateTime(
      today.year, today.month, today.day,
      int.tryParse(parts[0]) ?? 0,
      int.tryParse(parts[1]) ?? 0,
    );
    return now.isAfter(end);
  }

  bool get canGenerateStartQr => status == BookingStatus.confirmed && sessionStatus == SessionStatus.pending;
  bool get canGenerateEndQr => sessionStatus == SessionStatus.active;
  bool get canScanQr => sessionStatus == SessionStatus.startQrGenerated || sessionStatus == SessionStatus.endQrGenerated;
  bool get isSessionActive => sessionStatus == SessionStatus.active || sessionStatus == SessionStatus.endQrGenerated;
  bool get isSessionCompleted => sessionStatus == SessionStatus.completed;
  bool get isMultiDay => bookingGroupId != null && bookingGroupId!.isNotEmpty;
  bool get isDayDone => isDayCompleted || isSessionCompleted;
  bool get canStartSession => status == BookingStatus.confirmed && sessionStatus == SessionStatus.pending;
  bool get isGroupInProgress => status == BookingStatus.inProgress && !isSessionCompleted;
}

@freezed
class BookingStatusHistory with _$BookingStatusHistory {
  const factory BookingStatusHistory({
    required String id,
    @Default(null) String? fromStatus,
    required String toStatus,
    @Default(null) String? reason,
    @Default(null) DateTime? createdAt,
    @Default(null) Map<String, dynamic>? changedBy,
  }) = _BookingStatusHistory;

  factory BookingStatusHistory.fromJson(Map<String, dynamic> json) =>
      _$BookingStatusHistoryFromJson(json);
}

@freezed
class BookingModel with _$BookingModel {
  const factory BookingModel({
    required String id,
    @Default(null) String? bookingNumber,
    @Default(null) String? bookingGroupId,
    required String customerId,
    required String sitterId,
    required DateTime date,
    required String startTime,
    required String endTime,
    required int duration,
    required double totalAmount,
    @Default(0) double baseAmount,
    @Default(0) double extraAmount,
    @Default(0) double specialNeedsAmount,
    required BookingStatus status,
    @Default(SessionStatus.pending) SessionStatus sessionStatus,
    @Default(null) UserModel? customer,
    @Default(null) UserModel? sitter,
    @Default(null) String? notes,
    @Default(null) String? address,
    @Default(null) int? childrenCount,
    @Default(0) int specialNeedsCount,
    @Default(null) List<String>? childrenAges,
    @Default([]) List<String> childrenNames,
    @Default(null) String? specialInstructions,
    @Default([]) List<ScheduleEvent> scheduleEvents,
    @Default(null) String? cancellationReason,
    @Default(null) String? rejectionReason,
    @Default(null) DateTime? createdAt,
    @Default(null) DateTime? updatedAt,
    @Default(null) DateTime? inProgressAt,
    @Default(null) DateTime? completedAt,
    @Default(null) DateTime? cancelledAt,
    @Default(null) DateTime? confirmedAt,
    @Default(null) DateTime? rejectedAt,
    @Default(null) DateTime? expiredAt,
    @Default(null) DateTime? confirmationDeadline,
    @Default(null) String? rescheduledFromId,
    @Default(null) double? rating,
    @Default(null) String? review,
    @Default(null) String? reply,
    @Default(null) DateTime? repliedAt,
    @Default(0) int helpfulCount,
    @Default([]) List<BookingStatusHistory> statusHistory,
    @Default([]) List<TimelineEvent> timelineEvents,
    @Default(null) DateTime? sessionStartedAt,
    @Default(null) DateTime? sessionEndedAt,
    @Default(null) DateTime? gpsStartedAt,
    @Default(null) DateTime? gpsEndedAt,
    @Default(0) int overtimeMinutes,
    @Default(0) double overtimeCost,
    @Default(0) int waitingMinutes,
    @Default(0) double waitingCost,
    @Default(0) double expectedHours,
    @Default(0) double actualHours,
    @Default(null) String? sessionNotes,
    @Default(false) bool isDayCompleted,
    @Default(null) DateTime? dayCompletedAt,
    @Default(false) bool isOutOfSchedule,
    @Default(null) LocationPoint? latestLocation,
  }) = _BookingModel;

  factory BookingModel.fromJson(Map<String, dynamic> json) =>
      _$BookingModelFromJson(json);

  factory BookingModel.empty() => BookingModel(
        id: '',
        customerId: '',
        sitterId: '',
        date: DateTime.now(),
        startTime: '',
        endTime: '',
        duration: 0,
        totalAmount: 0,
        baseAmount: 0,
        extraAmount: 0,
        specialNeedsAmount: 0,
        status: BookingStatus.pending,
      );
}

@freezed
class ScheduleEvent with _$ScheduleEvent {
  const factory ScheduleEvent({
    required String time,
    required String activity,
  }) = _ScheduleEvent;

  factory ScheduleEvent.fromJson(Map<String, dynamic> json) =>
      _$ScheduleEventFromJson(json);

  factory ScheduleEvent.empty() => const ScheduleEvent(
        time: '',
        activity: '',
      );
}

@freezed
class TimelineEvent with _$TimelineEvent {
  const factory TimelineEvent({
    required String id,
    required String type,
    @Default({}) Map<String, dynamic> payload,
    @Default(null) Map<String, dynamic>? actor,
    required DateTime createdAt,
  }) = _TimelineEvent;

  factory TimelineEvent.fromJson(Map<String, dynamic> json) =>
      _$TimelineEventFromJson(json);
}

@freezed
class CancellationPolicyInfo with _$CancellationPolicyInfo {
  const factory CancellationPolicyInfo({
    @Default(null) int? id,
    required String name,
    required String description,
    required int refundPercent,
    required int hoursBefore,
  }) = _CancellationPolicyInfo;

  factory CancellationPolicyInfo.fromJson(Map<String, dynamic> json) =>
      _$CancellationPolicyInfoFromJson(json);
}

@freezed
class LocationPoint with _$LocationPoint {
  const factory LocationPoint({
    required double latitude,
    required double longitude,
    @Default(null) String? address,
    @Default(null) double? speed,
    @Default(null) int? battery,
    @Default(null) DateTime? recordedAt,
  }) = _LocationPoint;

  factory LocationPoint.fromJson(Map<String, dynamic> json) =>
      _$LocationPointFromJson(json);
}

@freezed
class QrCodeResponse with _$QrCodeResponse {
  const factory QrCodeResponse({
    required String qrToken,
    required String bookingId,
    required DateTime expiresAt,
    @Default(false) bool isOutOfSchedule,
  }) = _QrCodeResponse;

  factory QrCodeResponse.fromJson(Map<String, dynamic> json) =>
      _$QrCodeResponseFromJson(json);
}

@freezed
class SessionStatusResponse with _$SessionStatusResponse {
  const factory SessionStatusResponse({
    required String sessionStatus,
    @Default(null) DateTime? sessionStartedAt,
    @Default(null) DateTime? sessionEndedAt,
    @Default(null) DateTime? gpsStartedAt,
    @Default(null) DateTime? gpsEndedAt,
    @Default(null) int? durationMinutes,
    @Default(0) double expectedHours,
    @Default(0) double actualHours,
    @Default(0) int overtimeMinutes,
    @Default(0) double overtimeCost,
    @Default(null) LocationPoint? latestLocation,
  }) = _SessionStatusResponse;

  factory SessionStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$SessionStatusResponseFromJson(json);
}

@freezed
class TrackingData with _$TrackingData {
  const factory TrackingData({
    @Default([]) List<LocationPoint> tracking,
    @Default(null) LocationPoint? latest,
    @Default(null) int? sessionDurationMinutes,
    @Default(null) String? bookingAddress,
  }) = _TrackingData;

  factory TrackingData.fromJson(Map<String, dynamic> json) =>
      _$TrackingDataFromJson(json);
}
