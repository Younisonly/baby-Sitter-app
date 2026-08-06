import 'package:freezed_annotation/freezed_annotation.dart';

part 'reschedule_request_model.freezed.dart';
part 'reschedule_request_model.g.dart';

enum RescheduleRequestStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('accepted')
  accepted,
  @JsonValue('rejected')
  rejected,
  @JsonValue('countered')
  countered,
  @JsonValue('cancelled')
  cancelled,
}

@freezed
class RescheduleRequestModel with _$RescheduleRequestModel {
  const factory RescheduleRequestModel({
    required int id,
    required int bookingId,
    required int requestedById,
    @Default(null) Map<String, dynamic>? requester,
    required String status,
    required String proposedDate,
    required String proposedStartTime,
    required String proposedEndTime,
    @Default(null) String? reason,
    @Default(null) String? counterDate,
    @Default(null) String? counterStartTime,
    @Default(null) String? counterEndTime,
    @Default(null) String? counterReason,
    @Default(null) String? respondedAt,
    @Default(null) String? createdAt,
    @Default(null) String? updatedAt,
  }) = _RescheduleRequestModel;

  factory RescheduleRequestModel.fromJson(Map<String, dynamic> json) =>
      _$RescheduleRequestModelFromJson(json);
}

extension RescheduleRequestStatusX on RescheduleRequestStatus {
  String get localizedKey {
    switch (this) {
      case RescheduleRequestStatus.pending:
        return 'reschedule_status_pending';
      case RescheduleRequestStatus.accepted:
        return 'reschedule_status_accepted';
      case RescheduleRequestStatus.rejected:
        return 'reschedule_status_rejected';
      case RescheduleRequestStatus.countered:
        return 'reschedule_status_countered';
      case RescheduleRequestStatus.cancelled:
        return 'reschedule_status_cancelled';
    }
  }
}
