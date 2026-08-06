import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:babysitter/core/storage/local_storage.dart';
import 'package:babysitter/features/babysitters/data/babysitter_repository.dart';
import 'package:babysitter/features/favorites/data/favorite_repository.dart';
import 'package:babysitter/shared/models/user_model.dart';

part 'app_provider.freezed.dart';

@freezed
class AppState with _$AppState {
  const factory AppState({
    @Default(0) int currentIndex,
    @Default(false) bool hasOnboarded,
    @Default(UserRole.customer) UserRole userRole,
    @Default([]) List<String> favoriteIds,
    @Default(0) int unreadNotifications,
  }) = _AppState;
}

final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>(
  (ref) => AppStateNotifier(ref),
);

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier(this._ref) : super(const AppState()) {
    _loadFromLocal();
  }

  final Ref _ref;

  Future<void> _loadFromLocal() async {
    final ids = await LocalStorage.getFavoriteIds();
    if (ids.isNotEmpty) {
      state = state.copyWith(favoriteIds: ids);
    }
  }

  void setCurrentIndex(int index) {
    state = state.copyWith(currentIndex: index);
  }

  void setOnboarded(bool value) {
    state = state.copyWith(hasOnboarded: value);
  }

  void setUserRole(UserRole role) {
    state = state.copyWith(userRole: role);
  }

  Future<void> toggleFavorite(String id) async {
    final favorites = List<String>.from(state.favoriteIds);
    final wasFavorite = favorites.contains(id);

    if (wasFavorite) {
      favorites.remove(id);
    } else {
      favorites.add(id);
    }

    state = state.copyWith(favoriteIds: favorites);
    await LocalStorage.setFavoriteIds(favorites);

    if (!await LocalStorage.getIsLoggedIn()) return;

    try {
      final repository = _ref.read(favoriteRepositoryProvider);
      if (wasFavorite) {
        await repository.removeFavorite(id);
      } else {
        await repository.saveFavorite(id);
      }
      _ref.invalidate(favoriteSittersProvider);
      _ref.invalidate(sitterDetailsProvider(id));
    } catch (e) {
      final rollback = List<String>.from(state.favoriteIds);
      if (wasFavorite) {
        rollback.add(id);
      } else {
        rollback.remove(id);
      }
      state = state.copyWith(favoriteIds: rollback);
      await LocalStorage.setFavoriteIds(rollback);
      rethrow;
    }
  }

  bool isFavorite(String id) {
    return state.favoriteIds.contains(id);
  }

  Future<void> setFavoriteIds(List<String> ids) async {
    state = state.copyWith(favoriteIds: ids.toSet().toList());
    await LocalStorage.setFavoriteIds(ids);
  }

  void syncFavoritesFromModels(List<UserModel> sitters) {
    final updatedIds = state.favoriteIds.toSet();
    for (final sitter in sitters) {
      if (sitter.isFavorite) {
        updatedIds.add(sitter.id);
      } else {
        updatedIds.remove(sitter.id);
      }
    }
    final merged = updatedIds.toList();
    state = state.copyWith(favoriteIds: merged);
    LocalStorage.setFavoriteIds(merged);
  }

  Future<void> syncFavoritesFromServer() async {
    if (!await LocalStorage.getIsLoggedIn()) return;

    try {
      final repository = _ref.read(favoriteRepositoryProvider);
      final serverSitters = await repository.getFavorites();
      final serverIds = serverSitters.map((s) => s.id).toSet();
      final localIds = {...await LocalStorage.getFavoriteIds()};

      final toUpload = localIds.difference(serverIds);
      for (final id in toUpload) {
        try {
          await repository.saveFavorite(id);
        } catch (_) {}
      }

      final merged = {...serverIds, ...localIds}.toList();
      await setFavoriteIds(merged);
      _ref.invalidate(favoriteSittersProvider);
    } catch (_) {}
  }

  Future<void> clearFavorites() async {
    state = state.copyWith(favoriteIds: const []);
    await LocalStorage.setFavoriteIds([]);
  }

  void setUnreadNotifications(int count) {
    state = state.copyWith(unreadNotifications: count);
  }
}

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);
