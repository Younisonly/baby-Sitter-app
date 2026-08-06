import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:babysitter/core/constants/app_config.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';

class AppImagePreview {
  AppImagePreview._();

  static String? _resolve(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    try {
      return AppConfig.absoluteUrl(imageUrl);
    } catch (_) {
      return imageUrl.startsWith('http://') || imageUrl.startsWith('https://')
          ? imageUrl
          : null;
    }
  }

  static bool canPreview(String? imageUrl) => _resolve(imageUrl) != null;

  static void show(BuildContext context, String? imageUrl, {String? name}) {
    final url = _resolve(imageUrl);
    if (url == null) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.92),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4,
                    child: Center(
                      child: CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => _placeholder(name),
                        errorWidget: (_, __, ___) => _placeholder(name),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 28,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  static Widget _placeholder(String? name) {
    return Container(
      color: Colors.white.withValues(alpha: 0.05),
      child: Center(
        child: Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: Colors.white12,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              (name != null && name.isNotEmpty) ? name[0].toUpperCase() : '?',
              style: AppTextStyles.displaySmall(color: Colors.white54),
            ),
          ),
        ),
      ),
    );
  }
}
