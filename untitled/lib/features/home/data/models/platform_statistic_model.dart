// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'platform_statistic_model.freezed.dart';
part 'platform_statistic_model.g.dart';

@freezed
class PlatformStatisticModel with _$PlatformStatisticModel {
  const factory PlatformStatisticModel({
    required String key,
    required String value,
    required String label,
    @JsonKey(name: 'label_ar') required String labelAr,
    String? icon,
    @JsonKey(name: 'sort_order') required int sortOrder,
  }) = _PlatformStatisticModel;

  factory PlatformStatisticModel.fromJson(Map<String, dynamic> json) =>
      _$PlatformStatisticModelFromJson(json);
}
