import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/theme_colors.dart';

class AppLoader extends StatelessWidget {
  final double size;
  final Color? color;

  const AppLoader({
    super.key,
    this.size = 48,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: FittedBox(
        child: SpinKitSpinningLines(
          color: color ?? context.primaryColor,
          lineWidth: 5,
          itemCount: 4,
        ),
      ),
    );
  }
}

class FullscreenLoader extends StatelessWidget {
  final String? message;

  const FullscreenLoader({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: FittedBox(
              child: SpinKitSpinningLines(
                color: context.primaryColor,
                lineWidth: 8,
                itemCount: 4,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              message!,
              style: AppTextStyles.bodyMedium(
                color: context.textSecondaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class InlineLoader extends StatelessWidget {
  final double size;

  const InlineLoader({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: SizedBox(
          width: size,
          height: size,
          child: FittedBox(
            child: SpinKitSpinningLines(
              color: context.primaryColor,
              lineWidth: 8,
              itemCount: 4,
            ),
          ),
        ),
      ),
    );
  }
}

class OverlayLoader extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const OverlayLoader({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: context.isDark ? Colors.black54 : Colors.black26,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: FittedBox(
                        child: SpinKitSpinningLines(
                          color: context.primaryColor,
                          lineWidth: 8,
                          itemCount: 4,
                        ),
                      ),
                    ),
                    if (message != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        message!,
                        style: AppTextStyles.bodyMedium(
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
