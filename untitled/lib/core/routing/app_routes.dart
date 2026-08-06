class AppRoutes {
  AppRoutes._();

  // Auth
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String otpLogin = '/login-otp';
  static const String register = '/register';
  static const String otp = '/otp';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // Visitor
  static const String visitorHome = '/visitor';
  static const String sitterDetails = '/sitter/:id';
  static const String search = '/search';
  static const String filters = '/filters';

  // Parent
  static const String parentHome = '/parent';
  static const String parentSearch = '/parent/search';
  static const String parentSearchResults = '/parent/search/results';
  static const String parentSitterDetails = '/parent/sitter/:id';
  static const String parentBookings = '/parent/bookings';
  static const String parentNotifications = '/parent/notifications';
  static const String parentProfile = '/parent/profile';
  static const String parentEditProfile = '/parent/edit-profile';
  static const String parentFavorites = '/parent/favorites';
  static const String parentSettings = '/parent/settings';
  static const String parentSupport = '/parent/support';

  // Sitter
  static const String sitterDashboard = '/sitter';
  static const String sitterBookings = '/sitter/bookings';
  static const String sitterCalendar = '/sitter/calendar';
  static const String sitterMessages = '/sitter/messages';
  static const String sitterProfile = '/sitter/profile';
  static const String sitterEditProfile = '/sitter/edit-profile';
  static const String sitterAnalytics = '/sitter/analytics';
  static const String sitterEarnings = '/sitter/earnings';
  static const String sitterReviews = '/sitter/reviews';
  static const String sitterFollowers = '/sitter/followers';
  static const String sitterAvailability = '/sitter/availability';
  static const String sitterPricing = '/sitter/pricing';
  static const String sitterRescheduleRequests = '/sitter/reschedule-requests';
  static const String sitterManagement = '/sitter/management';
  static const String sitterNotifications = '/sitter/notifications';
  static const String sitterSettings = '/sitter/settings';
  static const String sitterSupport = '/sitter/support';
  static const String sitterVerification = '/sitter/verification';
  static const String sitterSubscription = '/sitter/subscription';

  // Shared
  static const String chat = '/chat';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String support = '/support';
  static const String terms = '/terms';
  static const String privacy = '/privacy';
  static const String payments = '/payments';
  static const String about = '/about';
  static const String editProfile = '/edit-profile';
  static const String editSitterProfile = '/edit-sitter-profile';
  static const String bookingDetails = '/booking/:id';
  static const String bookingFlow = '/booking/flow';
  static const String bookingSession = '/booking/:id/session';
  static const String sessionQrStart = '/booking/:id/session/qr-start';
  static const String sessionQrEnd = '/booking/:id/session/qr-end';
  static const String sessionScanStart = '/booking/:id/session/scan-start';
  static const String sessionScanEnd = '/booking/:id/session/scan-end';
  static const String invoice = '/booking/:id/invoice';
  static const String bookingTimeline = '/booking/:id/timeline';
  static const String notificationSettings = '/notification-settings';

  // Legacy (kept for backwards compat)
  static const String profile = '/profile';
  static const String favorites = '/favorites';
  static const String bookings = '/bookings';
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String analytics = '/analytics';
  static const String earnings = '/earnings';
  static const String legacySitterReviews = '/sitter-reviews';
  static const String followers = '/followers';
  static const String rescheduleRequests = '/reschedule-requests';
  static const String faq = '/faq';
  static const String adminSitterApproval = '/admin/sitter-approval';
  static const String becomeSitter = '/become-sitter';
  static const String sitterRegistration = '/sitter-registration';
}
