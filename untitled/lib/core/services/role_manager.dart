import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/core/storage/local_storage.dart';

enum AppRole {
  visitor,
  parent,
  sitter,
}

class RoleState {
  final AppRole activeRole;
  final bool hasParentAccess;
  final bool hasSitterAccess;

  const RoleState({
    this.activeRole = AppRole.visitor,
    this.hasParentAccess = false,
    this.hasSitterAccess = false,
  });

  RoleState copyWith({
    AppRole? activeRole,
    bool? hasParentAccess,
    bool? hasSitterAccess,
  }) {
    return RoleState(
      activeRole: activeRole ?? this.activeRole,
      hasParentAccess: hasParentAccess ?? this.hasParentAccess,
      hasSitterAccess: hasSitterAccess ?? this.hasSitterAccess,
    );
  }

  bool get isVisitor => activeRole == AppRole.visitor;
  bool get isParent => activeRole == AppRole.parent;
  bool get isSitter => activeRole == AppRole.sitter;

  bool get canActAsParent => hasParentAccess;
  bool get canActAsSitter => hasSitterAccess;
  bool get hasMultipleRoles => hasParentAccess && hasSitterAccess;
}

final roleManagerProvider = StateNotifierProvider<RoleManager, RoleState>((ref) {
  return RoleManager();
});

class RoleManager extends StateNotifier<RoleState> {
  RoleManager() : super(const RoleState()) {
    _loadRole();
  }

  Future<void> _loadRole() async {
    final saved = await LocalStorage.getCurrentRole();
    final userId = await LocalStorage.getUserId();
    final hasSitter = userId != null
        ? await LocalStorage.getHasSitterProfile()
        : false;
    final hasParent = userId != null
        ? await LocalStorage.getHasParentProfile()
        : true;

    state = RoleState(
      activeRole: saved,
      hasParentAccess: hasParent,
      hasSitterAccess: hasSitter,
    );
  }

  Future<void> switchTo(AppRole role) async {
    state = state.copyWith(activeRole: role);
    await LocalStorage.setCurrentRole(role.name);
  }

  Future<void> switchToParent() async => switchTo(AppRole.parent);
  Future<void> switchToSitter() async => switchTo(AppRole.sitter);
  Future<void> switchToVisitor() async => switchTo(AppRole.visitor);

  Future<void> setAvailableRoles({
    required bool hasParentAccess,
    required bool hasSitterAccess,
    AppRole? preferredRole,
  }) async {
    final currentActive = state.activeRole;

    AppRole newActive;
    if (preferredRole != null && _canActAs(preferredRole, hasParentAccess, hasSitterAccess)) {
      newActive = preferredRole;
    } else if (currentActive == AppRole.sitter && hasSitterAccess) {
      newActive = AppRole.sitter;
    } else if (currentActive == AppRole.parent && hasParentAccess) {
      newActive = AppRole.parent;
    } else if (hasSitterAccess) {
      newActive = AppRole.sitter;
    } else if (hasParentAccess) {
      newActive = AppRole.parent;
    } else {
      newActive = AppRole.visitor;
    }

    state = RoleState(
      activeRole: newActive,
      hasParentAccess: hasParentAccess,
      hasSitterAccess: hasSitterAccess,
    );

    await LocalStorage.setCurrentRole(newActive.name);
    await LocalStorage.setHasParentProfile(hasParentAccess);
    await LocalStorage.setHasSitterProfile(hasSitterAccess);
  }

  bool _canActAs(AppRole role, bool hasParent, bool hasSitter) {
    if (role == AppRole.sitter) return hasSitter;
    if (role == AppRole.parent) return hasParent;
    return true;
  }

  bool canSwitchTo(AppRole role) {
    if (role == AppRole.sitter) return state.canActAsSitter && !state.isSitter;
    if (role == AppRole.parent) return state.canActAsParent && !state.isParent;
    return false;
  }

  String? roleUnavailableReason(AppRole role) {
    if (role == AppRole.sitter && !state.hasSitterAccess) {
      return 'You haven\'t created a sitter profile yet.';
    }
    if (role == AppRole.parent && !state.hasParentAccess) {
      return 'Parent profile not available for this account.';
    }
    return null;
  }
}
