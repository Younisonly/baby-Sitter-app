// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

enum UserRole {
  @JsonValue('customer')
  customer,
  @JsonValue('babysitter')
  babysitter,
  @JsonValue('admin')
  admin,
}

enum VerificationStatus {
  @JsonValue('unverified')
  unverified,
  @JsonValue('under_review')
  underReview,
  @JsonValue('verified')
  verified,
  @JsonValue('rejected')
  rejected,
}

enum RegistrationStatus {
  @JsonValue('none')
  none,
  @JsonValue('draft')
  draft,
  @JsonValue('submitted')
  submitted,
  @JsonValue('under_review')
  underReview,
  @JsonValue('verified')
  verified,
  @JsonValue('rejected')
  rejected,
  @JsonValue('suspended')
  suspended,
  @JsonValue('inactive')
  inactive,
  @JsonValue('pending_more_info')
  pendingMoreInfo,
}

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String name,
    required String email,
    @Default(null) String? phone,
    @Default(null) String? avatar,
    @Default(UserRole.customer) UserRole role,
    @Default(null) String? bio,
    @Default(null) String? location,
    @Default(null) double? latitude,
    @Default(null) double? longitude,
    @Default(null) int? age,
    @Default(null) String? gender,
    @JsonKey(name: 'nationalId') @Default(null) String? nationalId,
    @Default(null) List<String>? languages,
    @Default(false) bool isVerified,
    @Default(VerificationStatus.unverified) VerificationStatus verificationStatus,
    @Default(RegistrationStatus.none) RegistrationStatus registrationStatus,
    @Default(false) bool isSuspended,
    @Default(null) String? suspensionReason,
    @JsonKey(name: 'isActiveSitter') @Default(false) bool isActiveSitter,
    @JsonKey(name: 'hasParentProfile') @Default(false) bool hasParentProfile,
    @JsonKey(name: 'hasSitterProfile') @Default(false) bool hasSitterProfile,
    @JsonKey(name: 'availableRoles') @Default([]) List<String> availableRoles,
    @Default(null) DateTime? createdAt,
    @Default(null) DateTime? updatedAt,
    @Default(false) bool isFavorite,
    @Default(null) BabysitterProfile? babysitterProfile,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  factory UserModel.empty() => const UserModel(
        id: '',
        name: '',
        email: '',
      );
}

@freezed
class BabysitterProfile with _$BabysitterProfile {
  const factory BabysitterProfile({
    @Default(null) String? userId,
    @Default(0.0) double hourlyRate,
    @Default(0.0) double rating,
    @Default(0) int reviewCount,
    @Default(0) int yearsExperience,
    @Default(null) String? description,
    @Default([]) List<String> categories,
    @Default([]) List<dynamic> certificates,
    @Default([]) List<String> galleryImages,
    @Default(0) int completedBookings,
    @Default(0) int cancelledBookings,
    @Default(0) int totalEarnings,
    @Default(true) bool isAvailable,
    @Default([]) List<AvailabilitySlot> availability,
    @Default(null) String? bankAccount,
    @Default(1) int includedChildren,
    @Default(0.0) double extraChildFee,
    @Default(null) int? absoluteMaxChildren,
    @Default(0.0) double specialNeedsRate,
    @Default(0) int followerCount,
  }) = _BabysitterProfile;

  factory BabysitterProfile.fromJson(Map<String, dynamic> json) =>
      _$BabysitterProfileFromJson(json);

  factory BabysitterProfile.empty() => const BabysitterProfile();
}

@freezed
class AvailabilitySlot with _$AvailabilitySlot {
  const factory AvailabilitySlot({
    required int dayOfWeek,
    required String startTime,
    required String endTime,
  }) = _AvailabilitySlot;

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) =>
      _$AvailabilitySlotFromJson(json);
}
