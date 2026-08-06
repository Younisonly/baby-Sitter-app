import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/extensions/theme_colors.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/routing/app_routes.dart';
import 'package:babysitter/core/services/app_provider.dart';
import 'package:babysitter/core/services/auth_provider.dart';
import 'package:babysitter/core/services/connectivity_service.dart';
import 'package:babysitter/core/services/role_manager.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/features/home/presentation/screens/home_screen.dart';
import 'package:babysitter/features/booking/presentation/screens/my_bookings_screen.dart';
import 'package:babysitter/features/notifications/data/notification_repository.dart';
import 'package:babysitter/features/profile/presentation/screens/profile_screen.dart';
import 'package:babysitter/features/chat/presentation/screens/chat_screen.dart';
import 'package:babysitter/features/sitter_management/presentation/screens/sitter_dashboard_screen.dart';
import 'package:babysitter/features/booking/data/booking_provider.dart';
import 'dart:async';
import 'package:babysitter/shared/models/booking_model.dart';
import 'package:babysitter/shared/widgets/widgets.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> with WidgetsBindingObserver {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _wasOffline = false;
  Timer? _badgeTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() async {
      final authState = ref.read(authProvider);
      if (authState.isAuthenticated) {
        await _refreshBadge();
        _startBadgePolling();
      }
    });
  }

  @override
  void dispose() {
    _badgeTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _refreshBadge() async {
    try {
      final repo = ref.read(notificationRepositoryProvider);
      final count = await repo.getUnreadCount();
      ref.read(appStateProvider.notifier).setUnreadNotifications(count);
    } catch (_) {}
  }

  void _startBadgePolling() {
    _badgeTimer?.cancel();
    _badgeTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (ref.read(authProvider).isAuthenticated) {
        _refreshBadge();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final authState = ref.read(authProvider);
      if (authState.isAuthenticated) {
        _refreshBadge();
        _startBadgePolling();
      }
    } else if (state == AppLifecycleState.paused) {
      _badgeTimer?.cancel();
    }
  }

  void _showOfflineSnackbar() {
    final loc = AppLocalization.get(ref.read(languageProvider).code);
    AppSnackbar.info(
      context,
      loc[AppLocalization.offline] ?? 'Offline',
      title: loc[AppLocalization.offline_title] ?? 'No Internet Connection',
    );
  }

  void _showBackOnlineSnackbar() {
    final loc = AppLocalization.get(ref.read(languageProvider).code);
    AppSnackbar.success(
      context,
      loc[AppLocalization.back_online] ?? 'Back Online',
      title: loc[AppLocalization.connection_restored] ?? 'Connection Restored',
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final authState = ref.watch(authProvider);
    final isLoggedIn = authState.isAuthenticated;
    final currentIndex = ref.watch(bottomNavIndexProvider);
    final isOnline = ref.watch(connectivityProvider).valueOrNull ?? true;
    final roleState = ref.watch(roleManagerProvider);
    final isSitter = roleState.isSitter && isLoggedIn;
    final isParent = roleState.isParent && isLoggedIn;
    final activeSession = ref.watch(activeSessionProvider).valueOrNull;

    ref.listen(authProvider, (_, next) {
      if (!next.isAuthenticated) {
        ref.read(bottomNavIndexProvider.notifier).state = 0;
      }
    });

    ref.listen(roleManagerProvider, (prev, next) {
      if (prev?.activeRole != next.activeRole) {
        ref.read(bottomNavIndexProvider.notifier).state = 0;
      }
    });

    ref.listen<AsyncValue<bool>>(connectivityProvider, (previous, next) {
      final wasOnline = previous?.valueOrNull ?? true;
      final nowOnline = next.valueOrNull ?? true;
      if (wasOnline && !nowOnline) {
        _wasOffline = true;
        if (context.mounted) _showOfflineSnackbar();
      } else if (!wasOnline && nowOnline && _wasOffline) {
        _wasOffline = false;
        if (context.mounted) _showBackOnlineSnackbar();
      }
    });

    // Sitter tabs: Management, Chat, Profile
    // Parent tabs: Home, Chat, Bookings, Profile
    // Visitor tabs: Home, About, Support

    final sitterTabs = [
      _NavItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
        label: strings[AppLocalization.sitter_management] ?? 'Management',
      ),
      _NavItem(
        icon: Icons.chat_bubble_outline_rounded,
        activeIcon: Icons.chat_bubble_rounded,
        label: strings['chat'] ?? 'Messages',
      ),
      _NavItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person_rounded,
        label: strings['profile'] ?? 'Profile',
      ),
    ];

    final parentTabs = [
      _NavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: strings[AppLocalization.home] ?? 'Home',
      ),
      _NavItem(
        icon: Icons.calendar_today_outlined,
        activeIcon: Icons.calendar_today_rounded,
        label: strings[AppLocalization.bookings] ?? 'Bookings',
      ),
      _NavItem(
        icon: Icons.chat_bubble_outline_rounded,
        activeIcon: Icons.chat_bubble_rounded,
        label: strings['chat'] ?? 'Chat',
      ),
      _NavItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person_rounded,
        label: strings['profile'] ?? 'Profile',
      ),
    ];

    final visitorTabs = [
      _NavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: strings[AppLocalization.home] ?? 'Home',
      ),
      _NavItem(
        icon: Icons.calendar_today_outlined,
        activeIcon: Icons.calendar_today_rounded,
        label: strings[AppLocalization.bookings] ?? 'Bookings',
      ),
      _NavItem(
        icon: Icons.chat_bubble_outline_rounded,
        activeIcon: Icons.chat_bubble_rounded,
        label: strings['chat'] ?? 'Chat',
      ),
      _NavItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person_rounded,
        label: strings['profile'] ?? 'Profile',
      ),
    ];

    final tabs = isSitter
        ? sitterTabs
        : isParent
            ? parentTabs
            : visitorTabs;
    final safeIndex = currentIndex.clamp(0, tabs.length - 1);

    final unreadCount = ref.watch(appStateProvider).unreadNotifications;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (currentIndex != 0) {
          ref.read(bottomNavIndexProvider.notifier).state = 0;
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: context.theme.scaffoldBackgroundColor,
        body: Stack(
          children: [
            Column(
              children: [
                if (!isOnline)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    color: AppColors.error,
                    child: SafeArea(
                      bottom: false,
                      child: Row(
                        children: [
                          Icon(Icons.wifi_off_rounded,
                              size: 16, color: AppColors.white),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              strings[AppLocalization.no_internet_connection] ??
                                  'No internet connection',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (isLoggedIn && activeSession != null && activeSession.isSessionActive)
                  GestureDetector(
                    onTap: () => context.push('/booking/${activeSession.id}/session'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      color: AppColors.success.withValues(alpha: 0.1),
                      child: SafeArea(
                        bottom: false,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              strings['active_session_banner'] ?? 'Active Session',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.success.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: AppColors.success.withValues(alpha: 0.7),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: IndexedStack(
                    index: safeIndex,
                    children: _buildContent(
                      strings: strings,
                      isLoggedIn: isLoggedIn,
                      isSitter: isSitter,
                      isParent: isParent,
                      unreadCount: unreadCount,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: (context.isDark ? AppColors.white : AppColors.black)
                    .withValues(alpha: context.isDark ? 0.06 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            child: BottomNavigationBar(
              currentIndex: safeIndex,
              onTap: (index) => _onNavTap(index, safeIndex, isLoggedIn, isSitter, isParent),
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 11),
              selectedItemColor: context.primaryColor,
              unselectedItemColor: context.textMutedColor,
              items: List.generate(tabs.length, (index) {
                final tab = tabs[index];
                final selected = safeIndex == index;
                final showBadge = _shouldShowBadge(index, isLoggedIn, isSitter, isParent, unreadCount);
                return BottomNavigationBarItem(
                  icon: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: selected
                          ? context.primaryColor.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: showBadge
                        ? Badge(
                            label: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: const TextStyle(fontSize: 10, color: AppColors.white),
                            ),
                            child: Icon(
                              selected ? tab.activeIcon : tab.icon,
                              size: 24,
                            ),
                          )
                        : Icon(
                            selected ? tab.activeIcon : tab.icon,
                            size: 24,
                          ),
                  ),
                  label: tab.label,
                  activeIcon: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: showBadge
                        ? Badge(
                            label: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: const TextStyle(fontSize: 10, color: AppColors.white),
                            ),
                            child: Icon(
                              tab.activeIcon,
                              size: 24,
                              color: context.primaryColor,
                            ),
                          )
                        : Icon(
                            tab.activeIcon,
                            size: 24,
                            color: context.primaryColor,
                          ),
                  ),
                );
              }),
            ),
          ),
        ),
        drawer: _PremiumDrawer(
          isLoggedIn: isLoggedIn,
          isSitter: isSitter,
          isParent: isParent,
          roleState: roleState,
          user: authState.user,
          onNavigate: (route) {
            context.push(route);
          },
          onLogout: () async {
            ref.read(bottomNavIndexProvider.notifier).state = 0;
            Navigator.pop(context);
            await ref.read(authProvider.notifier).logout();
          },
          onSwitchToSitter: () {
            final user = ref.read(authProvider).user;
            if (user?.babysitterProfile == null) {
              showLoginSheet(context,
                  message: strings[AppLocalization.no_sitter_profile] ??
                      'You don\'t have a sitter profile.');
              return;
            }
            _showRoleSwitchDialog(
              context,
              strings,
              AppRole.sitter,
              () {
                ref.read(roleManagerProvider.notifier).switchToSitter();
                context.go(AppRoutes.sitterDashboard);
              },
            );
          },
          onSwitchToParent: () => _showRoleSwitchDialog(
            context,
            strings,
            AppRole.parent,
            () {
              ref.read(roleManagerProvider.notifier).switchToParent();
              context.go(AppRoutes.parentHome);
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContent({
    required Map<String, String> strings,
    required bool isLoggedIn,
    required bool isSitter,
    required bool isParent,
    required int unreadCount,
  }) {
    if (isSitter) {
      return [
        const SitterManagementDashboard(),
        isLoggedIn
            ? const ChatScreen()
            : _AuthTab(strings: strings, messageKey: AppLocalization.login_to_chats),
        isLoggedIn
            ? const ProfileScreen()
            : _AuthTab(strings: strings, messageKey: AppLocalization.login_to_profile),
      ];
    }

    if (isParent) {
      return [
        const HomeScreen(),
        isLoggedIn
            ? const MyBookingsScreen()
            : _AuthTab(strings: strings, messageKey: AppLocalization.login_to_bookings),
        isLoggedIn
            ? const ChatScreen()
            : _AuthTab(strings: strings, messageKey: AppLocalization.login_to_chats),
        isLoggedIn
            ? const ProfileScreen()
            : _AuthTab(strings: strings, messageKey: AppLocalization.login_to_profile),
      ];
    }

    // Visitor
    return [
      const HomeScreen(),
      _AuthTab(strings: strings, messageKey: AppLocalization.login_to_bookings),
      _AuthTab(strings: strings, messageKey: AppLocalization.login_to_chats),
      _AuthTab(strings: strings, messageKey: AppLocalization.login_to_profile),
    ];
  }

  void _onNavTap(int index, int currentIndex, bool isLoggedIn, bool isSitter, bool isParent) {
    if (!isLoggedIn && index > 0) {
      _showLoginSheet();
      return;
    }
    ref.read(bottomNavIndexProvider.notifier).state = index;
  }

  void _showLoginSheet() {
    showLoginSheet(context);
  }

  void _showRoleSwitchDialog(BuildContext dialogContext, Map<String, String> strings, AppRole targetRole, VoidCallback onConfirm) {
    final isTargetSitter = targetRole == AppRole.sitter;
    final roleIcon = isTargetSitter ? Icons.badge_rounded : Icons.family_restroom_rounded;
    final confirmLabel = isTargetSitter
        ? (strings[AppLocalization.switch_to_sitter] ?? 'Switch to Sitter')
        : (strings[AppLocalization.switch_to_parent] ?? 'Switch to Parent');
    AppDialog.show(
      context: dialogContext,
      icon: roleIcon,
      title: strings['switch_role_title'] ?? 'Switch Role',
      content: isTargetSitter
          ? (strings[AppLocalization.switch_role_confirm_sitter] ?? 'Switch to Sitter mode?')
          : (strings[AppLocalization.switch_role_confirm_parent] ?? 'Switch to Parent mode?'),
      confirmText: confirmLabel,
      cancelText: strings['cancel'] ?? 'Cancel',
      onConfirm: onConfirm,
    );
  }

  bool _shouldShowBadge(int index, bool isLoggedIn, bool isSitter, bool isParent, int unreadCount) {
    if (!isLoggedIn || unreadCount <= 0) return false;
    // Sitters have 3 tabs (index 2 = Profile), parents have 4 tabs (index 3 = Profile)
    if (isSitter) return index == 2;
    return index == 3;
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _AuthTab extends StatelessWidget {
  final Map<String, String> strings;
  final String messageKey;

  const _AuthTab({required this.strings, required this.messageKey});

  @override
  Widget build(BuildContext context) {
    final message = strings[messageKey] ?? strings[AppLocalization.login_to_access] ?? 'Please login to access this feature';
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.primaryGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.lock_person_rounded,
                    size: 48, color: AppColors.white),
              ),
              const SizedBox(height: 28),
              Text(
                strings[AppLocalization.login_required] ?? 'Login Required',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              AppButton(
                text: strings[AppLocalization.login] ?? 'Login',
                onPressed: () => context.push(AppRoutes.login),
              ),
              const SizedBox(height: 14),
              AppButton(
                text: strings[AppLocalization.create_account] ?? 'Create Account',
                variant: AppButtonVariant.outlined,
                onPressed: () => context.push(AppRoutes.register),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => context.go(AppRoutes.home),
                child: Text(
                  strings[AppLocalization.continue_browsing] ?? 'Continue Browsing',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumDrawer extends ConsumerWidget {
  final bool isLoggedIn;
  final bool isSitter;
  final bool isParent;
  final RoleState roleState;
  final dynamic user;
  final ValueChanged<String> onNavigate;
  final VoidCallback onLogout;
  final VoidCallback? onSwitchToSitter;
  final VoidCallback? onSwitchToParent;

  const _PremiumDrawer({
    required this.isLoggedIn,
    required this.isSitter,
    required this.isParent,
    required this.roleState,
    required this.user,
    required this.onNavigate,
    required this.onLogout,
    this.onSwitchToSitter,
    this.onSwitchToParent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);

    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + AppSpacing.md,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                if (isLoggedIn && user != null)
                  AppAvatar(
                    imageUrl: user.avatar,
                    name: user.name,
                    size: 44,
                    onTap: () => onNavigate(AppRoutes.profile),
                  )
                else
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      size: 24,
                      color: AppColors.white,
                    ),
                  ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isLoggedIn && user != null) ...[
                        Text(
                          user.name ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user.email ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.white.withValues(alpha: 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ] else ...[
                        Text(
                          strings['welcome'] ?? 'Welcome',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            onNavigate(AppRoutes.login);
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            strings['login_register'] ?? 'Login / Register',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Role indicator (only show for dual-role accounts)
                if (isLoggedIn && roleState.hasMultipleRoles) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: (isSitter ? AppColors.secondary : AppColors.primary)
                            .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSitter ? Icons.work_rounded : Icons.family_restroom_rounded,
                            size: 20,
                            color: isSitter ? AppColors.secondary : AppColors.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              isSitter
                                  ? (strings[AppLocalization.current_mode_sitter] ?? 'Current Mode: Sitter')
                                  : (strings[AppLocalization.current_mode_parent] ?? 'Current Mode: Parent'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSitter ? AppColors.secondary : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Role switching
                if (isLoggedIn && roleState.hasMultipleRoles) ...[
                  if (isSitter && onSwitchToParent != null)
                    _DrawerItem(
                      icon: Icons.swap_horiz_rounded,
                      title: strings[AppLocalization.switch_to_parent] ?? 'Switch to Parent',
                      color: AppColors.primary,
                      onTap: onSwitchToParent!,
                    ),
                  if (isParent && onSwitchToSitter != null)
                    _DrawerItem(
                      icon: Icons.swap_horiz_rounded,
                      title: strings[AppLocalization.switch_to_sitter] ?? 'Switch to Sitter',
                      color: AppColors.secondary,
                      onTap: onSwitchToSitter!,
                    ),
                  const _DrawerDivider(),
                ],

                if (isLoggedIn) ...[
                  // Sitter management for sitter role
                  if (isSitter)
                    _DrawerItem(
                      icon: Icons.dashboard_rounded,
                      title: strings[AppLocalization.sitter_management] ?? 'Sitter Management',
                      color: AppColors.secondary,
                      onTap: () => onNavigate(AppRoutes.sitterDashboard),
                    ),

                  // Become a sitter for parent role
                  if (isParent && !roleState.hasSitterAccess)
                    _DrawerItem(
                      icon: Icons.badge_rounded,
                      title: strings[AppLocalization.become_sitter] ?? 'Become a Babysitter',
                      color: AppColors.primary,
                      onTap: () => onNavigate(AppRoutes.becomeSitter),
                    ),
                ],

                if (isParent) ...[
                  _DrawerItem(
                    icon: Icons.favorite_rounded,
                    title: strings[AppLocalization.favorites] ?? 'Favorites',
                    color: AppColors.error,
                    onTap: () => onNavigate(AppRoutes.favorites),
                  ),
                  _DrawerItem(
                    icon: Icons.payment_rounded,
                    title: strings[AppLocalization.payments] ?? 'Payments',
                    color: Theme.of(context).colorScheme.primary,
                    onTap: () => onNavigate(AppRoutes.payments),
                  ),
                ],
                if (isSitter) ...[
                  _DrawerItem(
                    icon: Icons.bar_chart_rounded,
                    title: strings[AppLocalization.analytics_title] ?? 'Analytics',
                    color: Theme.of(context).colorScheme.primary,
                    onTap: () => onNavigate(AppRoutes.analytics),
                  ),
                  _DrawerItem(
                    icon: Icons.payment_rounded,
                    title: strings['earnings'] ?? 'Earnings',
                    color: AppColors.success,
                    onTap: () => onNavigate(AppRoutes.earnings),
                  ),
                  _DrawerItem(
                    icon: Icons.star_rounded,
                    title: strings['reviews'] ?? 'Reviews',
                    color: AppColors.warning,
                    onTap: () => onNavigate(AppRoutes.sitterReviews),
                  ),
                ],

                const _DrawerDivider(),
                _DrawerItem(
                  icon: Icons.settings_rounded,
                  title: strings[AppLocalization.settings] ?? 'Settings',
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  onTap: () => onNavigate(AppRoutes.settings),
                ),
                _DrawerItem(
                  icon: Icons.info_rounded,
                  title: strings[AppLocalization.about] ?? 'About',
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  onTap: () => onNavigate(AppRoutes.about),
                ),
                if (isLoggedIn) ...[
                  const _DrawerDivider(),
                  _DrawerItem(
                    icon: Icons.logout_rounded,
                    title: strings[AppLocalization.logout] ?? 'Logout',
                    color: Theme.of(context).colorScheme.error,
                    onTap: onLogout,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color color;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
      horizontalTitleGap: AppSpacing.xs,
    );
  }
}

class _DrawerDivider extends StatelessWidget {
  const _DrawerDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Divider(
        color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        height: 1,
      ),
    );
  }
}
