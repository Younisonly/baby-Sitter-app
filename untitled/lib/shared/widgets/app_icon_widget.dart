import 'package:flutter/material.dart';
import 'package:babysitter/core/constants/app_icons.dart';
import 'package:babysitter/core/constants/app_sizes.dart';

class AppIconWidget extends StatelessWidget {
  final String? name;
  final double? size;
  final Color? color;
  final IconData fallback;

  const AppIconWidget({
    super.key,
    this.name,
    this.size,
    this.color,
    this.fallback = Icons.help_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      AppIcons.resolve(name, fallback: fallback),
      size: size ?? AppSizes.iconSize22,
      color: color,
    );
  }
}
