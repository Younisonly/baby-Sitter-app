import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/routing/app_routes.dart';
import 'package:babysitter/core/routing/app_router_guard.dart';
import 'package:babysitter/core/widgets/protected_route.dart';
import 'package:babysitter/features/auth/presentation/splash/splash_screen.dart';
import 'package:babysitter/features/auth/presentation/onboarding/onboarding_screen.dart';
import 'package:babysitter/features/auth/presentation/welcome/welcome_screen.dart';
import 'package:babysitter/features/auth/presentation/login/login_screen.dart';
import 'package:babysitter/features/auth/presentation/login/otp_login_screen.dart';

import 'package:babysitter/features/auth/presentation/register/register_screen.dart';

import 'package:babysitter/features/auth/presentation/otp/otp_screen.dart';
import 'package:babysitter/features/auth/presentation/forgot_password/forgot_password_screen.dart';
import 'package:babysitter/features/auth/presentation/forgot_password/reset_password_screen.dart';
import 'package:babysitter/features/home/presentation/screens/main_shell.dart';
import 'package:babysitter/features/babysitters/presentation/screens/filters_screen.dart';
import 'package:babysitter/features/babysitters/presentation/screens/search_screen.dart';
import 'package:babysitter/features/babysitters/presentation/screens/sitter_details_screen.dart';
import 'package:babysitter/features/booking/presentation/screens/booking_flow_screen.dart';
import 'package:babysitter/features/booking/presentation/screens/booking_details_screen.dart';
import 'package:babysitter/features/booking/presentation/screens/booking_timeline_screen.dart';
import 'package:babysitter/features/booking/presentation/screens/my_bookings_screen.dart';
import 'package:babysitter/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:babysitter/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:babysitter/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:babysitter/features/profile/presentation/screens/edit_sitter_profile_screen.dart';
import 'package:babysitter/features/profile/presentation/screens/profile_screen.dart';
import 'package:babysitter/features/settings/presentation/screens/settings_screen.dart';
import 'package:babysitter/features/setter_dashboard/presentation/screens/analytics_screen.dart';
import 'package:babysitter/features/setter_dashboard/presentation/screens/dashboard_screen.dart';
import 'package:babysitter/features/setter_dashboard/presentation/screens/earnings_screen.dart';
import 'package:babysitter/features/setter_dashboard/presentation/screens/followers_screen.dart';
import 'package:babysitter/features/setter_dashboard/presentation/screens/reviews_screen.dart';
import 'package:babysitter/features/faq/presentation/screens/faq_screen.dart';
import 'package:babysitter/features/support/presentation/screens/support_screen.dart';
import 'package:babysitter/features/chat/presentation/screens/chat_screen.dart';
import 'package:babysitter/features/sitter_registration/presentation/screens/registration_wizard_screen.dart';
import 'package:babysitter/features/booking/presentation/screens/reschedule_requests_screen.dart';
import 'package:babysitter/features/booking/presentation/screens/invoice_screen.dart';
import 'package:babysitter/features/booking/presentation/screens/sitter_bookings_screen.dart';
import 'package:babysitter/features/booking/presentation/screens/session_screen.dart';
import 'package:babysitter/features/booking/presentation/screens/qr_display_screen.dart';
import 'package:babysitter/features/booking/presentation/screens/qr_scanner_screen.dart';
import 'package:babysitter/features/sitter_management/presentation/screens/sitter_dashboard_screen.dart';
import 'package:babysitter/features/admin/presentation/screens/admin_sitter_approval_screen.dart';
import 'package:babysitter/features/notifications/presentation/screens/notification_settings_screen.dart';

Page<void> _slideUpTransition(Widget child) {
  return CustomTransitionPage<void>(
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.08),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        )),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(animation),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: AppRouterGuard.redirect,
    routes: [
      // === PUBLIC / AUTH ROUTES ===
      GoRoute(
        path: AppRoutes.splash,
        name: AppRoutes.splash,
        pageBuilder: (_, __) => _slideUpTransition(const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: AppRoutes.onboarding,
        pageBuilder: (_, __) => _slideUpTransition(const OnboardingScreen()),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        name: AppRoutes.welcome,
        pageBuilder: (_, __) => _slideUpTransition(const WelcomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: AppRoutes.login,
        pageBuilder: (_, __) => _slideUpTransition(const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.otpLogin,
        name: AppRoutes.otpLogin,
        pageBuilder: (_, __) => _slideUpTransition(const OtpLoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: AppRoutes.register,
        pageBuilder: (_, __) => _slideUpTransition(const RegisterScreen()),
      ),
      GoRoute(
        path: AppRoutes.otp,
        name: AppRoutes.otp,
        pageBuilder: (_, state) => _slideUpTransition(
          OtpScreen(phone: state.uri.queryParameters['phone'] ?? ''),
        ),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: AppRoutes.forgotPassword,
        pageBuilder: (_, __) => _slideUpTransition(const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        name: AppRoutes.resetPassword,
        pageBuilder: (_, __) => _slideUpTransition(const ResetPasswordScreen()),
      ),

      // === VISITOR ===
      GoRoute(
        path: AppRoutes.visitorHome,
        name: AppRoutes.visitorHome,
        pageBuilder: (_, __) => _slideUpTransition(const MainShell()),
        routes: [
          GoRoute(
            path: 'sitter/:id',
            name: 'visitor-sitter-details',
            pageBuilder: (_, state) => _slideUpTransition(
              SitterDetailsScreen(id: state.pathParameters['id'] ?? ''),
            ),
          ),
          GoRoute(
            path: 'search',
            name: 'visitor-search',
            pageBuilder: (_, state) => _slideUpTransition(
              SearchScreen(initialCategory: state.uri.queryParameters['category']),
            ),
          ),
          GoRoute(
            path: 'filters',
            name: 'visitor-filters',
            pageBuilder: (_, __) => _slideUpTransition(const FiltersScreen()),
          ),
        ],
      ),

      // === PARENT ===
      GoRoute(
        path: AppRoutes.parentHome,
        name: 'parent-home',
        pageBuilder: (_, __) => _slideUpTransition(const MainShell()),
        routes: [
          GoRoute(
            path: 'search',
            name: 'parent-search',
            pageBuilder: (_, state) => _slideUpTransition(
              SearchScreen(initialCategory: state.uri.queryParameters['category']),
            ),
          ),
          GoRoute(
            path: 'sitter/:id',
            name: 'parent-sitter-details',
            pageBuilder: (_, state) => _slideUpTransition(
              SitterDetailsScreen(id: state.pathParameters['id'] ?? ''),
            ),
          ),
          GoRoute(
            path: 'filters',
            name: 'parent-filters',
            pageBuilder: (_, __) => _slideUpTransition(const FiltersScreen()),
          ),
          GoRoute(
            path: 'favorites',
            name: 'parent-favorites',
            pageBuilder: (_, __) => _slideUpTransition(
              const ProtectedRoute(child: FavoritesScreen()),
            ),
          ),
        ],
      ),

      // === SITTER ===
      GoRoute(
        path: AppRoutes.sitterDashboard,
        name: 'sitter-dashboard',
        pageBuilder: (_, __) => _slideUpTransition(const MainShell()),
        routes: [
          GoRoute(
            path: 'bookings',
            name: 'sitter-bookings-route',
            pageBuilder: (_, __) => _slideUpTransition(
              const ProtectedRoute(child: SitterBookingsScreen()),
            ),
          ),
          GoRoute(
            path: 'analytics',
            name: 'sitter-analytics-route',
            pageBuilder: (_, __) => _slideUpTransition(
              const ProtectedRoute(child: AnalyticsScreen()),
            ),
          ),
          GoRoute(
            path: 'earnings',
            name: 'sitter-earnings-route',
            pageBuilder: (_, __) => _slideUpTransition(
              const ProtectedRoute(child: EarningsScreen()),
            ),
          ),
          GoRoute(
            path: 'reviews',
            name: 'sitter-reviews-route',
            pageBuilder: (_, __) => _slideUpTransition(
              const ProtectedRoute(child: ReviewsScreen()),
            ),
          ),
          GoRoute(
            path: 'followers',
            name: 'sitter-followers-route',
            pageBuilder: (_, __) => _slideUpTransition(
              const ProtectedRoute(child: FollowersScreen()),
            ),
          ),
          GoRoute(
            path: 'reschedule-requests',
            name: 'sitter-reschedule-requests',
            pageBuilder: (_, __) => _slideUpTransition(
              const ProtectedRoute(child: RescheduleRequestsScreen()),
            ),
          ),
          GoRoute(
            path: 'availability',
            name: 'sitter-availability',
            pageBuilder: (_, __) => _slideUpTransition(
              const ProtectedRoute(child: SitterManagementDashboard()),
            ),
          ),
        ],
      ),

      // === SHARED ROUTES ===
      GoRoute(
        path: AppRoutes.sitterDetails,
        name: AppRoutes.sitterDetails,
        pageBuilder: (_, state) => _slideUpTransition(
          SitterDetailsScreen(id: state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: AppRoutes.chat,
        name: AppRoutes.chat,
        pageBuilder: (_, state) => _slideUpTransition(
          ProtectedRoute(
            messageKey: AppLocalization.login_to_chat,
            child: ChatScreen(
              initialConversationId: state.uri.queryParameters['conversationId'],
              initialUserId: state.uri.queryParameters['userId'],
              bookingId: state.uri.queryParameters['bookingId'],
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: AppRoutes.notifications,
        pageBuilder: (_, __) => _slideUpTransition(
          const ProtectedRoute(
            messageKey: AppLocalization.login_to_notifications,
            child: NotificationsScreen(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: AppRoutes.settings,
        pageBuilder: (_, __) => _slideUpTransition(const SettingsScreen()),
        routes: [
          GoRoute(
            path: 'notification-settings',
            name: 'settings-notification-settings',
            pageBuilder: (_, __) => _slideUpTransition(const NotificationSettingsScreen()),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.faq,
        name: AppRoutes.faq,
        pageBuilder: (_, __) => _slideUpTransition(const FaqScreen()),
      ),
      GoRoute(
        path: AppRoutes.support,
        name: AppRoutes.support,
        pageBuilder: (_, __) => _slideUpTransition(const SupportScreen()),
      ),
      GoRoute(
        path: AppRoutes.terms,
        name: AppRoutes.terms,
        pageBuilder: (_, __) => _slideUpTransition(const _TermsScreen()),
      ),
      GoRoute(
        path: AppRoutes.privacy,
        name: AppRoutes.privacy,
        pageBuilder: (_, __) => _slideUpTransition(const _PrivacyScreen()),
      ),
      GoRoute(
        path: AppRoutes.about,
        name: AppRoutes.about,
        pageBuilder: (_, __) => _slideUpTransition(
          const _ComingSoonScreen(
            titleKey: AppLocalization.about_app,
            descriptionKey: AppLocalization.about_app,
            icon: Icons.info_outline_rounded,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        name: AppRoutes.editProfile,
        pageBuilder: (_, __) => _slideUpTransition(
          const ProtectedRoute(child: EditProfileScreen()),
        ),
      ),
      GoRoute(
        path: AppRoutes.editSitterProfile,
        name: AppRoutes.editSitterProfile,
        pageBuilder: (_, __) => _slideUpTransition(
          const ProtectedRoute(child: EditSitterProfileScreen()),
        ),
      ),
      GoRoute(
        path: AppRoutes.notificationSettings,
        name: AppRoutes.notificationSettings,
        pageBuilder: (_, __) => _slideUpTransition(
          const ProtectedRoute(child: NotificationSettingsScreen()),
        ),
      ),

      // === BOOKING / SESSION ROUTES ===
      GoRoute(
        path: '/booking/flow',
        name: AppRoutes.bookingFlow,
        pageBuilder: (_, state) => _slideUpTransition(
          BookingFlowScreen(
            sitterId: state.uri.queryParameters['sitterId'] ?? '',
            editBookingId: state.uri.queryParameters['edit'],
            rebookFromId: state.uri.queryParameters['rebookFrom'],
            groupEditId: state.uri.queryParameters['groupEdit'],
            forRebook: state.uri.queryParameters['forRebook'] == 'true',
          ),
        ),
      ),
      GoRoute(
        path: '/booking/:id',
        name: 'booking-details',
        pageBuilder: (_, state) => _slideUpTransition(
          BookingDetailsScreen(bookingId: state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/booking/:id/timeline',
        name: 'booking-timeline',
        pageBuilder: (_, state) => _slideUpTransition(
          BookingTimelineScreen(bookingId: state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/booking/:id/invoice',
        name: 'booking-invoice',
        pageBuilder: (_, state) => _slideUpTransition(
          InvoiceScreen(bookingId: state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/booking/:id/session',
        name: 'booking-session',
        pageBuilder: (_, state) => _slideUpTransition(
          SessionScreen(bookingId: state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/booking/:id/session/qr-start',
        name: 'session-qr-start',
        pageBuilder: (_, state) => _slideUpTransition(
          QrDisplayScreen(bookingId: state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/booking/:id/session/qr-end',
        name: 'session-qr-end',
        pageBuilder: (_, state) => _slideUpTransition(
          QrDisplayScreen(bookingId: state.pathParameters['id'] ?? '', isEndQr: true),
        ),
      ),
      GoRoute(
        path: '/booking/:id/session/scan-start',
        name: 'session-scan-start',
        pageBuilder: (_, state) => _slideUpTransition(
          QrScannerScreen(bookingId: state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/booking/:id/session/scan-end',
        name: 'session-scan-end',
        pageBuilder: (_, state) => _slideUpTransition(
          QrScannerScreen(bookingId: state.pathParameters['id'] ?? '', isEndQr: true),
        ),
      ),

      // === LEGACY / KEPT ROUTES ===
      GoRoute(
        path: AppRoutes.profile,
        name: AppRoutes.profile,
        pageBuilder: (_, __) => _slideUpTransition(
          const ProtectedRoute(child: ProfileScreen()),
        ),
      ),
      GoRoute(
        path: AppRoutes.favorites,
        name: AppRoutes.favorites,
        pageBuilder: (_, __) => _slideUpTransition(
          const ProtectedRoute(
            messageKey: AppLocalization.login_to_favorite,
            child: FavoritesScreen(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.bookings,
        name: AppRoutes.bookings,
        pageBuilder: (_, __) => _slideUpTransition(
          const ProtectedRoute(
            messageKey: AppLocalization.login_to_bookings,
            child: MyBookingsScreen(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: AppRoutes.home,
        pageBuilder: (_, __) => _slideUpTransition(const _LegacyRedirect()),
      ),
      GoRoute(
        path: AppRoutes.payments,
        name: AppRoutes.payments,
        pageBuilder: (_, __) => _slideUpTransition(
          const ProtectedRoute(
            messageKey: AppLocalization.login_to_payments,
            child: _ComingSoonScreen(
              titleKey: AppLocalization.payments_coming_soon,
              descriptionKey: AppLocalization.payments_description,
              icon: Icons.payments_rounded,
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.becomeSitter,
        name: AppRoutes.becomeSitter,
        pageBuilder: (_, __) => _slideUpTransition(
          const ProtectedRoute(child: RegistrationWizardScreen()),
        ),
      ),
      GoRoute(
        path: AppRoutes.sitterRegistration,
        name: AppRoutes.sitterRegistration,
        pageBuilder: (_, __) => _slideUpTransition(
          const ProtectedRoute(child: RegistrationWizardScreen()),
        ),
      ),
      GoRoute(
        path: AppRoutes.sitterManagement,
        name: AppRoutes.sitterManagement,
        pageBuilder: (_, __) => _slideUpTransition(
          const ProtectedRoute(
            messageKey: AppLocalization.login_to_dashboard,
            child: SitterManagementDashboard(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        name: AppRoutes.dashboard,
        pageBuilder: (_, __) => _slideUpTransition(
          const ProtectedRoute(
            messageKey: AppLocalization.login_to_dashboard,
            child: DashboardScreen(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.analytics,
        name: AppRoutes.analytics,
        pageBuilder: (_, __) => _slideUpTransition(
          const ProtectedRoute(
            messageKey: AppLocalization.login_to_dashboard,
            child: AnalyticsScreen(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.earnings,
        name: AppRoutes.earnings,
        pageBuilder: (_, __) => _slideUpTransition(
          const ProtectedRoute(
            messageKey: AppLocalization.login_to_dashboard,
            child: EarningsScreen(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.legacySitterReviews,
        name: AppRoutes.legacySitterReviews,
        pageBuilder: (_, __) => _slideUpTransition(
          const ProtectedRoute(
            messageKey: AppLocalization.login_to_dashboard,
            child: ReviewsScreen(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.followers,
        name: AppRoutes.followers,
        pageBuilder: (_, __) => _slideUpTransition(
          const ProtectedRoute(
            messageKey: AppLocalization.login_to_dashboard,
            child: FollowersScreen(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.rescheduleRequests,
        name: AppRoutes.rescheduleRequests,
        pageBuilder: (_, __) => _slideUpTransition(
          const ProtectedRoute(
            messageKey: AppLocalization.login_to_dashboard,
            child: RescheduleRequestsScreen(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.sitterBookings,
        name: AppRoutes.sitterBookings,
        pageBuilder: (_, __) => _slideUpTransition(
          const ProtectedRoute(
            messageKey: AppLocalization.login_to_bookings,
            child: SitterBookingsScreen(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminSitterApproval,
        name: AppRoutes.adminSitterApproval,
        pageBuilder: (_, __) => _slideUpTransition(
          const ProtectedRoute(
            messageKey: AppLocalization.login_to_admin,
            child: AdminSitterApprovalScreen(),
          ),
        ),
      ),
    ],
    errorBuilder: (_, __) => const _ErrorScreen(),
  );
}

class _LegacyRedirect extends StatelessWidget {
  const _LegacyRedirect();
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _TermsScreen extends StatelessWidget {
  const _TermsScreen();
  @override
  Widget build(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    final strings = AppLocalization.get(code);
    return Scaffold(
      appBar: AppBar(title: Text(strings[AppLocalization.terms_of_service] ?? 'Terms of Service')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            strings[AppLocalization.terms_of_service] ?? 'Terms of Service',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _PrivacyScreen extends StatelessWidget {
  const _PrivacyScreen();
  @override
  Widget build(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    final strings = AppLocalization.get(code);
    return Scaffold(
      appBar: AppBar(title: Text(strings[AppLocalization.privacy_policy_title] ?? 'Privacy Policy')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            strings[AppLocalization.privacy_policy_title] ?? 'Privacy Policy',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen();
  @override
  Widget build(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    final strings = AppLocalization.get(code);
    return Scaffold(
      appBar: AppBar(title: Text(strings[AppLocalization.page_not_found] ?? 'Page Not Found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text(strings[AppLocalization.page_not_found] ?? 'Page Not Found', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(strings[AppLocalization.page_not_found_message] ?? 'The page you\'re looking for doesn\'t exist.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComingSoonScreen extends StatelessWidget {
  final String titleKey;
  final String descriptionKey;
  final IconData icon;

  const _ComingSoonScreen({
    required this.titleKey,
    required this.descriptionKey,
    this.icon = Icons.construction_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    final strings = AppLocalization.get(code);
    return Scaffold(
      appBar: AppBar(title: Text(strings[titleKey] ?? 'Coming Soon')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icon, size: 44, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 24),
              Text(strings[titleKey] ?? 'Coming Soon', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(strings[descriptionKey] ?? '', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
