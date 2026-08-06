import 'package:freezed_annotation/freezed_annotation.dart';

part 'review_model.freezed.dart';
part 'review_model.g.dart';

@freezed
class ReviewModel with _$ReviewModel {
  const factory ReviewModel({
    required String id,
    required String bookingId,
    required String reviewerId,
    required String reviewerName,
    @Default(null) String? reviewerAvatar,
    required double rating,
    @Default(null) String? comment,
    @Default(null) Map<String, double>? subRatings,
    required DateTime createdAt,
  }) = _ReviewModel;

  factory ReviewModel.fromJson(Map<String, dynamic> json) =>
      _$ReviewModelFromJson(json);
}
