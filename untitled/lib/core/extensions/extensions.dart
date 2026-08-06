import 'package:flutter/material.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/shared/widgets/app_snackbar.dart';

extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  double get screenWidth => mediaQuery.size.width;
  double get screenHeight => mediaQuery.size.height;
  bool get isSmallScreen => screenWidth < 600;
  bool get isMediumScreen => screenWidth >= 600 && screenWidth < 900;
  bool get isLargeScreen => screenWidth >= 900;
  bool get isTablet => screenWidth >= 600;
  bool get isDarkMode => theme.brightness == Brightness.dark;
  bool get isDark => isDarkMode;
  Color get textPrimary => colorScheme.onSurface;
  Color get textSecondary => colorScheme.onSurface.withValues(alpha: 0.7);
  Color get textMuted => colorScheme.onSurface.withValues(alpha: 0.5);
  Color get textHint => colorScheme.onSurface.withValues(alpha: 0.45);
  Color get dividerColor => colorScheme.outlineVariant;
  Color get borderColor => colorScheme.outlineVariant;
  Color get cardColor => isDarkMode ? colorScheme.surfaceContainerHigh : colorScheme.surface;
  Color get primaryColor => colorScheme.primary;
  Color get secondaryColor => colorScheme.secondary;
  Color get surfaceColor => colorScheme.surface;
  Color get backgroundColor => theme.scaffoldBackgroundColor;
  Color get textPrimaryColor => colorScheme.onSurface;
  Color get textSecondaryColor => colorScheme.onSurface.withValues(alpha: 0.7);
  Color get textMutedColor => colorScheme.onSurface.withValues(alpha: 0.5);
  Color get errorColor => colorScheme.error;
  Color get successColor => AppColors.success;
  Color get warningColor => AppColors.warning;
  Color get infoColor => AppColors.info;

  void hideKeyboard() => FocusScope.of(this).unfocus();
  void showErrorSnackBar(String message) => AppSnackbar.error(this, message);
  void showSuccessSnackBar(String message) => AppSnackbar.success(this, message);
  void showInfoSnackBar(String message) => AppSnackbar.info(this, message);
}

extension StringExtensions on String {
  bool get isValidEmail {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(this);
  }
}

extension DateTimeExtensions on DateTime {
  String toShortDate() => '$day/$month/$year';
}

extension WidgetExtensions on Widget {
  Widget expanded({int flex = 1}) => Expanded(flex: flex, child: this);
}

extension WidgetPadding on Widget {
  Widget paddingAll(double padding) => Padding(padding: EdgeInsets.all(padding));
  Widget paddingSymmetric({double horizontal = 0, double vertical = 0}) =>
      Padding(padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical));
  Widget paddingOnly({double left = 0, double top = 0, double right = 0, double bottom = 0}) =>
      Padding(padding: EdgeInsets.only(left: left, top: top, right: right, bottom: bottom));
}
