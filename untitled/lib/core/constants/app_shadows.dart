import 'package:flutter/material.dart';

class AppShadows {
  AppShadows._();

  static double _darkAlpha(double lightAlpha) =>
      (lightAlpha * 4.5).clamp(0.0, 0.3);

  static List<BoxShadow> get subtle => _subtle(Brightness.light);

  static List<BoxShadow> get card => _card(Brightness.light);

  static List<BoxShadow> get elevated => _elevated(Brightness.light);

  static List<BoxShadow> get button =>
      _button(Brightness.light);

  static List<BoxShadow> get dialog => _dialog(Brightness.light);

  static List<BoxShadow> get floating => _floating(Brightness.light);

  static List<BoxShadow> get navigationBar => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 14,
          offset: const Offset(0, -3),
        ),
      ];

  static List<BoxShadow> of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brightness = isDark ? Brightness.dark : Brightness.light;
    return _card(brightness);
  }

  static List<BoxShadow> _subtle(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? _darkAlpha(0.04) : 0.04),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ];
  }

  static List<BoxShadow> _card(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return [
      if (isDark)
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.03),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? _darkAlpha(0.05) : 0.05),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? _darkAlpha(0.02) : 0.02),
        blurRadius: 4,
        offset: const Offset(0, 1),
      ),
    ];
  }

  static List<BoxShadow> _elevated(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? _darkAlpha(0.07) : 0.07),
        blurRadius: 14,
        offset: const Offset(0, 5),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? _darkAlpha(0.03) : 0.03),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ];
  }

  static List<BoxShadow> _button(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return [
      BoxShadow(
        color: const Color(0xFF2CA6A4)
            .withValues(alpha: isDark ? 0.35 : 0.2),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ];
  }

  static List<BoxShadow> _dialog(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? _darkAlpha(0.12) : 0.12),
        blurRadius: 28,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? _darkAlpha(0.04) : 0.04),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> _floating(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? _darkAlpha(0.08) : 0.08),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? _darkAlpha(0.03) : 0.03),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ];
  }
}
