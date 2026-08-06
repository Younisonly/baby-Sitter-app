class AppDurations {
  AppDurations._();

  static const Duration fastest = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration slower = Duration(milliseconds: 700);
  static const Duration pageTransition = Duration(milliseconds: 350);
  static const Duration snackbar = Duration(seconds: 3);
  static const Duration splash = Duration(seconds: 2);
  static const Duration otpExpiry = Duration(minutes: 5);
  static const Duration sessionTimeout = Duration(hours: 24);
}
