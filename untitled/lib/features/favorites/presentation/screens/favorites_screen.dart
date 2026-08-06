import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/routing/app_routes.dart';
import 'package:babysitter/core/services/app_provider.dart';
import 'package:babysitter/core/network/error_handler.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/features/babysitters/presentation/widgets/sitter_card.dart';
import 'package:babysitter/features/favorites/data/favorite_repository.dart';
import 'package:babysitter/shared/widgets/widgets.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final favorites = ref.watch(favoriteSittersProvider);

    ref.listen(favoriteSittersProvider, (_, next) {
      next.whenData(
        (sitters) => ref
            .read(appStateProvider.notifier)
            .setFavoriteIds(sitters.map((sitter) => sitter.id).toList()),
      );
    });

    return Scaffold(
      appBar: AppAppBar(title: strings[AppLocalization.favorites]),
      body: favorites.when(
        data: (sitters) {
          if (sitters.isEmpty) {
            return EmptyState(
              title: strings[AppLocalization.no_favorites_yet] ?? 'No favorites yet',
              subtitle: strings[AppLocalization.start_adding_favorites] ?? 'Start adding babysitters to your favorites',
              icon: Icon(Icons.favorite_border, size: 80),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(favoriteSittersProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: sitters.length,
              itemBuilder: (context, index) {
                final sitter = sitters[index];
                final profile = sitter.babysitterProfile;
                return Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.md),
                  child: SitterCard(
                    id: sitter.id,
                    name: sitter.name,
                    rating: profile?.rating ?? 0,
                    reviews: profile?.reviewCount ?? 0,
                    hourlyRate: profile?.hourlyRate ?? 0,
                    experience: profile?.yearsExperience ?? 0,
                    distance: sitter.location ?? 'Nearby',
                    imageUrl: sitter.avatar,
                    isFavorite: true,
                    categories: profile?.categories ?? const [],
                    isCompact: true,
                    onTap: () => context.pushNamed(
                      AppRoutes.sitterDetails,
                      pathParameters: {'id': sitter.id},
                    ),
                    onBookTap: () => context.pushNamed(
                      AppRoutes.bookingFlow,
                      queryParameters: {'sitterId': sitter.id},
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: ListShimmer(itemCount: 4, itemHeight: 120),
        ),
        error: (error, _) => ErrorState(
          message: ErrorHandler.handle(error).message,
          icon: const Icon(
            Icons.favorite_border,
            size: 80,
            color: AppColors.error,
          ),
          onRetry: () => ref.invalidate(favoriteSittersProvider),
        ),
      ),
    );
  }
}
