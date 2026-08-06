import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/theme_colors.dart';

enum AppButtonVariant {
  filled,
  tonal,
  outlined,
  text,
  danger,
}

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final double? fontSize;
  final FontWeight? fontWeight;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Gradient? gradient;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.filled,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.prefixIcon,
    this.suffixIcon,
    this.fontSize,
    this.fontWeight,
    this.padding,
    this.borderRadius,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;
    final bg = backgroundColor ?? context.primaryColor;
    final h = height ?? 52;
    final radius = borderRadius ?? AppRadius.button;

    return SizedBox(
      width: width,
      height: h,
      child: _buildButton(context, isEnabled, bg, h, radius),
    );
  }

  Widget _buildButton(BuildContext context, bool isEnabled, Color bg, double h, double radius) {
    final common = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(width ?? 0, h)),
      padding: WidgetStatePropertyAll(padding ?? const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      )),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      )),
    );

    Widget button;

    switch (variant) {
      case AppButtonVariant.text:
        button = TextButton(
          onPressed: isEnabled ? onPressed : null,
          style: common.copyWith(
            foregroundColor: WidgetStatePropertyAll(textColor ?? context.primaryColor),
          ),
          child: _buildChild(context, isEnabled),
        );

      case AppButtonVariant.tonal:
        button = FilledButton.tonal(
          onPressed: isEnabled ? onPressed : null,
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) return bg.withValues(alpha: 0.08);
              return bg.withValues(alpha: 0.12);
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) return context.textMutedColor;
              return textColor ?? bg;
            }),
          ).merge(common),
          child: _buildChild(context, isEnabled),
        );

      case AppButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) return context.textMutedColor;
              return textColor ?? bg;
            }),
            side: WidgetStateProperty.resolveWith((states) {
              final color = states.contains(WidgetState.disabled)
                  ? context.textMutedColor
                  : (textColor ?? bg);
              return BorderSide(color: color, width: 1.2);
            }),
          ).merge(common),
          child: _buildChild(context, isEnabled),
        );

      case AppButtonVariant.danger:
        button = _AnimatedButton(
          onPressed: isEnabled ? onPressed : null,
          child: ElevatedButton(
            onPressed: isEnabled ? onPressed : null,
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return context.errorColor.withValues(alpha: 0.4);
                }
                return context.errorColor;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) return AppColors.white.withValues(alpha: 0.5);
                return AppColors.white;
              }),
              elevation: WidgetStatePropertyAll(0),
              shadowColor: WidgetStatePropertyAll(Colors.transparent),
            ).merge(common),
            child: _buildChild(context, isEnabled),
          ),
        );

      case AppButtonVariant.filled:
        final useGradient = gradient ??
            (backgroundColor == null ? const LinearGradient(colors: AppColors.primaryGradient) : null);

        Widget rawBtn = ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(Colors.transparent),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) return AppColors.white.withValues(alpha: 0.5);
              return textColor ?? AppColors.white;
            }),
            elevation: WidgetStatePropertyAll(0),
            shadowColor: WidgetStatePropertyAll(Colors.transparent),
            overlayColor: WidgetStatePropertyAll(AppColors.white.withValues(alpha: 0.1)),
          ).merge(common),
          child: _buildChild(context, isEnabled),
        );

        if (useGradient != null) {
          rawBtn = ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Container(
              decoration: BoxDecoration(
                gradient: useGradient,
              ),
              child: rawBtn,
            ),
          );
          if (!isEnabled) rawBtn = Opacity(opacity: 0.4, child: rawBtn);
        } else {
          rawBtn = ElevatedButton(
            onPressed: isEnabled ? onPressed : null,
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) return bg.withValues(alpha: 0.4);
                return bg;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) return AppColors.white.withValues(alpha: 0.5);
                return textColor ?? AppColors.white;
              }),
              elevation: WidgetStatePropertyAll(0),
              shadowColor: WidgetStatePropertyAll(Colors.transparent),
            ).merge(common),
            child: _buildChild(context, isEnabled),
          );
        }

        button = _AnimatedButton(
          onPressed: isEnabled ? onPressed : null,
          child: rawBtn,
        );
    }

    return button;
  }

  Widget _buildChild(BuildContext context, bool isEnabled) {
    final color = _resolveTextColor(context);

    if (isLoading) {
      return SpinKitDualRing(
        color: color,
        size: 22,
        lineWidth: 2.5,
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (prefixIcon != null) ...[
          SizedBox(
            width: (fontSize ?? 15) + 3,
            height: (fontSize ?? 15) + 3,
            child: prefixIcon!,
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        Flexible(
          child: Text(
            text,
            style: AppTextStyles.button(
              size: fontSize ?? 15,
              weight: fontWeight ?? FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (suffixIcon != null) ...[
          const SizedBox(width: AppSpacing.xs),
          SizedBox(
            width: (fontSize ?? 15) + 3,
            height: (fontSize ?? 15) + 3,
            child: suffixIcon!,
          ),
        ],
      ],
    );
  }

  Color _resolveTextColor(BuildContext context) {
    if (textColor != null) return textColor!;
    return switch (variant) {
      AppButtonVariant.filled || AppButtonVariant.danger => AppColors.white,
      AppButtonVariant.tonal || AppButtonVariant.outlined || AppButtonVariant.text => context.primaryColor,
    };
  }
}

class _AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;

  const _AnimatedButton({required this.child, this.onPressed});

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      onTapDown: widget.onPressed != null ? (_) => _controller.forward() : null,
      onTapUp: widget.onPressed != null
          ? (_) => _controller.reverse()
          : null,
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
