import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:babysitter/core/routing/app_routes.dart';
import 'package:babysitter/core/services/role_manager.dart';

class DeepLinkService {
  DeepLinkService._();

  /// Returns the role required for this deep link type, or null if any role works.
  static AppRole? _requiredRole(String type) {
    switch (type) {
      case 'booking':
      case 'favorites':
        return AppRole.parent;
      case 'dashboard':
      case 'analytics':
      case 'earnings':
      case 'followers':
      case 'reviews':
        return AppRole.sitter;
      case 'chat':
      case 'notifications':
      case 'settings':
      case 'profile':
      case 'support':
        return null; // shared
      default:
        return null;
    }
  }

  static String _resolveRoute(String type, String id, {AppRole? role}) {
    switch (type) {
      case 'booking':
        // The booking details screen is just /booking/:id for both roles
        return '/booking/$id';
      case 'chat':
        return '${AppRoutes.chat}?conversationId=$id';
      case 'followers':
        if (role == AppRole.sitter) return AppRoutes.sitterFollowers;
        return AppRoutes.followers;
      case 'reviews':
        return AppRoutes.sitterReviews;
      case 'profile':
        if (role == AppRole.parent) return AppRoutes.parentProfile;
        if (role == AppRole.sitter) return AppRoutes.sitterProfile;
        return AppRoutes.profile;
      case 'home':
        if (role == AppRole.parent) return AppRoutes.parentHome;
        if (role == AppRole.sitter) return AppRoutes.sitterDashboard;
        return AppRoutes.home;
      case 'support':
        if (role == AppRole.parent) return AppRoutes.parentSupport;
        if (role == AppRole.sitter) return AppRoutes.sitterSupport;
        return AppRoutes.support;
      case 'subscription':
        return AppRoutes.sitterSubscription;
      case 'security':
      case 'settings':
        if (role == AppRole.parent) return AppRoutes.parentSettings;
        if (role == AppRole.sitter) return AppRoutes.sitterSettings;
        return AppRoutes.settings;
      case 'dashboard':
        return AppRoutes.sitterDashboard;
      case 'analytics':
        return AppRoutes.sitterAnalytics;
      case 'earnings':
        return AppRoutes.sitterEarnings;
      case 'favorites':
        return AppRoutes.parentFavorites;
      default:
        return AppRoutes.home;
    }
  }

  /// Navigate with automatic role switching if needed.
  /// Returns true if a role switch was performed.
  static bool navigateWithRoleSwitch(
    WidgetRef ref,
    GoRouter router,
    String? type,
    String? id,
  ) {
    if (type == null || type.isEmpty) return false;

    final roleState = ref.read(roleManagerProvider);
    final requiredRole = _requiredRole(type);

    // Switch role if required and possible
    if (requiredRole != null && roleState.activeRole != requiredRole) {
      if (requiredRole == AppRole.sitter && roleState.canActAsSitter) {
        ref.read(roleManagerProvider.notifier).switchToSitter();
      } else if (requiredRole == AppRole.parent && roleState.canActAsParent) {
        ref.read(roleManagerProvider.notifier).switchToParent();
      }
    }

    final route = _resolveRoute(type, id ?? '', role: ref.read(roleManagerProvider).activeRole);
    router.push(route);
    return true;
  }

  static void navigate(GoRouter router, String? type, String? id, {AppRole? role}) {
    if (type == null || type.isEmpty) return;
    final route = _resolveRoute(type, id ?? '', role: role);
    router.push(route);
  }

  static void navigateFromContext(BuildContext context, String? type, String? id, {AppRole? role}) {
    if (type == null || type.isEmpty) return;
    final route = _resolveRoute(type, id ?? '', role: role);
    context.push(route);
  }
}
