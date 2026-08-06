import 'package:freezed_annotation/freezed_annotation.dart';

part 'service_category_model.freezed.dart';
part 'service_category_model.g.dart';

@freezed
class ServiceCategoryModel with _$ServiceCategoryModel {
  const factory ServiceCategoryModel({
    required String key,
    required String label,
    @Default('') String description,
    @Default('child_care') String icon,
    @Default('#2563EB') String color,
  }) = _ServiceCategoryModel;

  factory ServiceCategoryModel.fromJson(Map<String, dynamic> json) =>
      _$ServiceCategoryModelFromJson(json);
}
