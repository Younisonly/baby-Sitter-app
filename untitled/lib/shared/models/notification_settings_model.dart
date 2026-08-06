// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_settings_model.freezed.dart';
part 'notification_settings_model.g.dart';

@freezed
class NotificationSettingsModel with _$NotificationSettingsModel {
  const factory NotificationSettingsModel({
    @Default(0) int id,
    @JsonKey(name: 'bookingEnabled') @Default(true) bool bookingEnabled,
    @JsonKey(name: 'chatEnabled') @Default(true) bool chatEnabled,
    @JsonKey(name: 'reviewEnabled') @Default(true) bool reviewEnabled,
    @JsonKey(name: 'followersEnabled') @Default(true) bool followersEnabled,
    @JsonKey(name: 'supportEnabled') @Default(true) bool supportEnabled,
    @JsonKey(name: 'securityEnabled') @Default(true) bool securityEnabled,
    @JsonKey(name: 'promotionEnabled') @Default(false) bool promotionEnabled,
    @JsonKey(name: 'pushEnabled') @Default(true) bool pushEnabled,
    @JsonKey(name: 'inAppEnabled') @Default(true) bool inAppEnabled,
    @JsonKey(name: 'quietHoursStart') String? quietHoursStart,
    @JsonKey(name: 'quietHoursEnd') String? quietHoursEnd,
  }) = _NotificationSettingsModel;

  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationSettingsModelFromJson(json);
}
