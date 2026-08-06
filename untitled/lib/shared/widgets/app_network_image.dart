import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_config.dart';
import 'package:babysitter/core/constants/app_image_types.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/extensions/theme_colors.dart';

class AppNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final bool isCircular;
  final Widget? placeholder;
  final Widget? errorWidget;
  final AppImageType? imageType;

  const AppNetworkImage({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = AppRadius.md,
    this.isCircular = false,
    this.placeholder,
    this.errorWidget,
    this.imageType,
  });

  String? get _resolvedUrl {
    if (imageUrl == null || imageUrl!.isEmpty) return null;
    return AppConfig.absoluteUrl(imageUrl!);
  }

  @override
  Widget build(BuildContext context) {
    final type = imageType;
    final placeholderIcon = type?.placeholderIcon ?? Icons.image_outlined;
    final iconSize = type?.iconSize ?? 36;
    final effectiveBorderRadius = isCircular ? 0.0 : borderRadius;

    Widget buildPlaceholder({Color? bgColor}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: bgColor ?? (context.isDark
              ? context.primaryColor.withValues(alpha: 0.08)
              : context.primaryColor.withValues(alpha: 0.06)),
          borderRadius: BorderRadius.circular(effectiveBorderRadius),
          shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
        ),
        child: Center(
          child: Icon(
            placeholderIcon,
            size: iconSize,
            color: context.primaryColor.withValues(alpha: 0.3),
          ),
        ),
      );
    }

    if (_resolvedUrl == null) {
      return placeholder ?? buildPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(effectiveBorderRadius),
      child: CachedNetworkImage(
        imageUrl: _resolvedUrl!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) =>
            placeholder ?? Shimmer.fromColors(
          baseColor: context.isDark
              ? AppColors.skeletonBaseDark
              : AppColors.skeletonBaseLight,
          highlightColor: context.isDark
              ? AppColors.skeletonHighlightDark
              : AppColors.skeletonHighlightLight,
          child: buildPlaceholder(
            bgColor: context.isDark
                ? AppColors.skeletonBaseDark
                : AppColors.skeletonBaseLight,
          ),
        ),
        errorWidget: (context, url, error) =>
            errorWidget ?? buildPlaceholder(),
        imageBuilder: (context, imageProvider) {
          return Animate(
            effects: const [FadeEffect(duration: Duration(milliseconds: 300))],
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: imageProvider,
                  fit: fit,
                ),
                shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
              ),
            ),
          );
        },
      ),
    );
  }
}
