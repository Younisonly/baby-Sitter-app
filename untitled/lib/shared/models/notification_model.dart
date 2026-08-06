// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:babysitter/core/services/notification_localization_service.dart';

part 'notification_model.freezed.dart';
part 'notification_model.g.dart';

enum NotificationPriority {
  @JsonValue('low')
  low,
  @JsonValue('normal')
  normal,
  @JsonValue('high')
  high,
  @JsonValue('critical')
  critical,
}

@freezed
class NotificationModel with _$NotificationModel {
  const factory NotificationModel({
    required String id,
    @JsonKey(name: 'userId') @Default('') String userId,
    @JsonKey(name: 'templateId') String? templateId,
    required String title,
    required String body,
    required String type,
    @JsonKey(name: 'actionKey') String? actionKey,
    @Default('en') String language,
    @JsonKey(name: 'dataJson') Map<String, dynamic>? dataJson,
    @JsonKey(name: 'isRead') @Default(false) bool isRead,
    @JsonKey(name: 'readAt') DateTime? readAt,
    @Default(NotificationPriority.normal) NotificationPriority priority,
    String? icon,
    String? image,
    @JsonKey(name: 'deepLinkType') String? deepLinkType,
    @JsonKey(name: 'deepLinkId') String? deepLinkId,
    @JsonKey(name: 'showPush') @Default(true) bool showPush,
    @JsonKey(name: 'showInApp') @Default(true) bool showInApp,
    @JsonKey(name: 'createdAt') required DateTime createdAt,
    @JsonKey(name: 'updatedAt') DateTime? updatedAt,
  }) = _NotificationModel;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);

  const NotificationModel._();

  String localizedTitle(String locale) {
    return NotificationLocalizationService.resolveTitle(
      actionKey: actionKey,
      locale: locale,
      apiTitle: title,
      data: dataJson,
    );
  }

  String localizedBody(String locale) {
    return NotificationLocalizationService.resolveBody(
      actionKey: actionKey,
      locale: locale,
      apiBody: body,
      data: dataJson,
    );
  }

  String get category {
    if (actionKey != null && actionKey!.startsWith('booking_')) return 'booking';
    if (actionKey != null && actionKey!.startsWith('chat_')) return 'chat';
    if (actionKey != null && actionKey!.startsWith('review_')) return 'review';
    if (actionKey != null && actionKey!.startsWith('new_follower')) return 'followers';
    if (actionKey != null && actionKey!.startsWith('follower_')) return 'followers';
    if (actionKey != null && actionKey!.startsWith('support_')) return 'support';
    if (actionKey != null && actionKey!.startsWith('report_')) return 'support';
    if (actionKey != null && actionKey!.startsWith('subscription_')) return 'subscription';
    if (actionKey != null && actionKey!.startsWith('profile_')) return 'profile';
    if (actionKey != null && actionKey!.startsWith('system_')) return 'system';
    if (actionKey != null && actionKey!.startsWith('payment_')) return 'payment';
    if (actionKey != null && actionKey!.startsWith('emergency_')) return 'booking';
    if (type == 'security') return 'security';
    if (type == 'booking') return 'booking';
    if (type == 'chat') return 'chat';
    if (type == 'followers') return 'followers';
    if (type == 'review') return 'review';
    if (type == 'support') return 'support';
    if (type == 'subscription') return 'subscription';
    if (type == 'system') return 'system';
    return type;
  }
}
