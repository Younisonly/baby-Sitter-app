import 'package:flutter/material.dart';

enum AppImageType { avatar, sitter, certificate, gallery, chat, review, promo }

extension AppImageTypeExtension on AppImageType {
  double get placeholderSize {
    return switch (this) {
      AppImageType.avatar => 48,
      AppImageType.sitter => 120,
      AppImageType.certificate => 80,
      AppImageType.gallery => 100,
      AppImageType.chat => 40,
      AppImageType.review => 44,
      AppImageType.promo => double.infinity,
    };
  }

  IconData get placeholderIcon {
    return switch (this) {
      AppImageType.avatar => Icons.person_rounded,
      AppImageType.sitter => Icons.badge_rounded,
      AppImageType.certificate => Icons.verified_rounded,
      AppImageType.gallery => Icons.image_rounded,
      AppImageType.chat => Icons.chat_bubble_rounded,
      AppImageType.review => Icons.rate_review_rounded,
      AppImageType.promo => Icons.campaign_rounded,
    };
  }

  double get iconSize {
    return switch (this) {
      AppImageType.avatar => 24,
      AppImageType.sitter => 48,
      AppImageType.certificate => 36,
      AppImageType.gallery => 40,
      AppImageType.chat => 20,
      AppImageType.review => 22,
      AppImageType.promo => 64,
    };
  }
}
