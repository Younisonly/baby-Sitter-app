class AppConstants {
  AppConstants._();

  static const String appName = 'sitter';
  static const String appVersion = '1.0.0';

  static const int apiTimeout = 15000;
  static const int maxRetries = 2;

  static const String firebaseProjectId = 'babysitter-app';

  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration otpExpiryDuration = Duration(minutes: 5);
  static const Duration sessionTimeout = Duration(hours: 24);

  static const int otpLength = 6;
  static const int maxPhoneLength = 15;
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 32;
  static const int maxNameLength = 50;
  static const int maxBioLength = 500;

  static const int pageSize = 20;
  static const int maxImageUploadSize = 5 * 1024 * 1024; // 5MB
  static const int maxImagesPerUpload = 5;

  static const double minRating = 0.0;
  static const double maxRating = 5.0;
  static const double nearRadius = 10.0; // km

  static const String defaultCurrency = 'USD';
  static const String defaultLanguage = 'en';
  static const String defaultCountryCode = '+962';

  static const List<String> supportedLanguages = ['en', 'ar'];
  static const Map<String, String> languageNames = {
    'en': 'English',
    'ar': 'العربية',
  };

  static const List<String> sitterCategories = [
    'newborn',
    'infant',
    'toddler',
    'preschool',
    'school_age',
    'special_needs',
    'overnight',
    'emergency',
  ];

  static const Map<String, String> categoryIcons = {
    'newborn': 'baby',
    'infant': 'child',
    'toddler': 'kid',
    'preschool': 'school',
    'school_age': 'graduation',
    'special_needs': 'heart',
    'overnight': 'moon',
    'emergency': 'alert',
  };

  static const List<String> certificateTypes = [
    'first_aid',
    'cpr',
    'childcare',
    'early_education',
    'nutrition',
    'special_needs',
    'other',
  ];

  static const String termsUrl = 'https://babysitter.com/terms';
  static const String privacyUrl = 'https://babysitter.com/privacy';
  static const String supportEmail = 'support@babysitter.com';
  static const String supportPhone = '+962790000000';
}
