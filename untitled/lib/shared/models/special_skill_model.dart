import 'package:freezed_annotation/freezed_annotation.dart';

part 'special_skill_model.freezed.dart';
part 'special_skill_model.g.dart';

@freezed
class SpecialSkillModel with _$SpecialSkillModel {
  const factory SpecialSkillModel({
    required String key,
    required String label,
    @Default('child_care') String icon,
  }) = _SpecialSkillModel;

  factory SpecialSkillModel.fromJson(Map<String, dynamic> json) =>
      _$SpecialSkillModelFromJson(json);
}
