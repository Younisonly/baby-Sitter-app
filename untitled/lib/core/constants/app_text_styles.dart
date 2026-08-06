import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTextStyles {
  AppTextStyles._();

  static const String? _fontFamily = null;

  static TextStyle _base({
    required double size,
    required FontWeight weight,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
    Color? decorationColor,
  }) {
    return TextStyle(
      fontFamily: _fontFamily,
      fontSize: size.sp,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
      decorationColor: decorationColor,
    );
  }

  // ================= DISPLAY (page-level hero text) =================
  static TextStyle displayLarge({
    Color? color,
    FontWeight weight = FontWeight.bold,
  }) =>
      _base(size: 34, weight: weight, color: color, height: 1.15, letterSpacing: -0.5);

  static TextStyle displayMedium({
    Color? color,
    FontWeight weight = FontWeight.bold,
  }) =>
      _base(size: 28, weight: weight, color: color, height: 1.2, letterSpacing: -0.3);

  static TextStyle displaySmall({
    Color? color,
    FontWeight weight = FontWeight.w600,
  }) =>
      _base(size: 24, weight: weight, color: color, height: 1.3);

  // ================= HEADLINE (section-level emphasis) =================
  static TextStyle headlineLarge({
    Color? color,
    FontWeight weight = FontWeight.w600,
  }) =>
      _base(size: 22, weight: weight, color: color, height: 1.3);

  static TextStyle headlineMedium({
    Color? color,
    FontWeight weight = FontWeight.w600,
  }) =>
      _base(size: 20, weight: weight, color: color, height: 1.3);

  static TextStyle headlineSmall({
    Color? color,
    FontWeight weight = FontWeight.w600,
  }) =>
      _base(size: 18, weight: weight, color: color, height: 1.4);

  // ================= TITLE (card titles, prominent items) =================
  static TextStyle titleLarge({
    Color? color,
    FontWeight weight = FontWeight.w600,
  }) =>
      _base(size: 18, weight: weight, color: color, height: 1.3);

  static TextStyle titleMedium({
    Color? color,
    FontWeight weight = FontWeight.w500,
  }) =>
      _base(size: 16, weight: weight, color: color, height: 1.4);

  static TextStyle titleSmall({
    Color? color,
    FontWeight weight = FontWeight.w500,
  }) =>
      _base(size: 14, weight: weight, color: color, height: 1.4);

  // ================= BODY (primary reading text) =================
  static TextStyle bodyLarge({
    Color? color,
    FontWeight weight = FontWeight.normal,
  }) =>
      _base(size: 16, weight: weight, color: color, height: 1.5, letterSpacing: 0.1);

  static TextStyle bodyMedium({
    Color? color,
    FontWeight weight = FontWeight.normal,
  }) =>
      _base(size: 14, weight: weight, color: color, height: 1.5, letterSpacing: 0.1);

  static TextStyle bodySmall({
    Color? color,
    FontWeight weight = FontWeight.normal,
  }) =>
      _base(size: 13, weight: weight, color: color, height: 1.4, letterSpacing: 0.1);

  // ================= LABEL (buttons, chips, form labels) =================
  static TextStyle labelLarge({
    Color? color,
    FontWeight weight = FontWeight.w500,
  }) =>
      _base(size: 14, weight: weight, color: color, height: 1.3, letterSpacing: 0.3);

  static TextStyle labelMedium({
    Color? color,
    FontWeight weight = FontWeight.w500,
  }) =>
      _base(size: 12, weight: weight, color: color, height: 1.3, letterSpacing: 0.3);

  static TextStyle labelSmall({
    Color? color,
    FontWeight weight = FontWeight.w500,
  }) =>
      _base(size: 11, weight: weight, color: color, height: 1.3, letterSpacing: 0.3);

  // ================= SPECIAL =================
  static TextStyle button({
    Color? color,
    FontWeight weight = FontWeight.w600,
    double size = 16,
  }) =>
      _base(size: size, weight: weight, color: color, letterSpacing: 0.5);

  static TextStyle caption({
    Color? color,
    FontWeight weight = FontWeight.normal,
  }) =>
      _base(size: 12, weight: weight, color: color, height: 1.3, letterSpacing: 0.1);

  static TextStyle overline({
    Color? color,
    FontWeight weight = FontWeight.w500,
  }) =>
      _base(size: 11, weight: weight, color: color, height: 1.3, letterSpacing: 1.2);

  static TextStyle price({
    Color? color,
    FontWeight weight = FontWeight.bold,
  }) =>
      _base(size: 20, weight: weight, color: color, height: 1.2);

  static TextStyle link({
    Color? color,
    FontWeight weight = FontWeight.w500,
  }) =>
      _base(
        size: 14,
        weight: weight,
        color: color,
        letterSpacing: 0.1,
        decoration: TextDecoration.underline,
      );
}
