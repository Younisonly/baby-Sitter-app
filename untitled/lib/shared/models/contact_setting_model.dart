import 'package:freezed_annotation/freezed_annotation.dart';

part 'contact_setting_model.freezed.dart';
part 'contact_setting_model.g.dart';

@freezed
class ContactSettingModel with _$ContactSettingModel {
  const factory ContactSettingModel({
    required String id,
    String? email,
    String? phone,
    String? whatsapp,
    String? facebook,
    String? instagram,
    String? x,
    String? website,
  }) = _ContactSettingModel;

  factory ContactSettingModel.fromJson(Map<String, dynamic> json) =>
      _$ContactSettingModelFromJson(json);
}
