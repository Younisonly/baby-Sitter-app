import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_constants.dart';
import 'package:babysitter/core/constants/app_icons.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_shadows.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/theme_colors.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/routing/app_routes.dart';
import 'package:babysitter/core/services/app_provider.dart';
import 'package:babysitter/core/services/auth_provider.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/features/babysitters/data/babysitter_repository.dart';
import 'package:babysitter/features/babysitters/presentation/widgets/sitter_card.dart';
import 'package:babysitter/features/home/data/home_repository.dart';
import 'package:babysitter/shared/models/service_category_model.dart';
import 'package:babysitter/shared/models/user_model.dart';
import 'package:babysitter/shared/widgets/widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onBookTap(BuildContext context, String sitterId) {
    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) {
      context.pushNamed(
        AppRoutes.bookingFlow,
        queryParameters: {'sitterId': sitterId},
      );
    } else {
      showLoginSheet(context, message: ref.read(languageProvider).code == 'ar'
          ? 'سجل الدخول لحجز جليسة أطفال'
          : 'Login to book a babysitter');
    }
  }

  void _navigateToSearch(BuildContext context, WidgetRef ref, {String? category}) {
    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) {
      if (category != null) {
        context.pushNamed('parent-search', queryParameters: {'category': category});
      } else {
        context.pushNamed('parent-search');
      }
    } else {
      if (category != null) {
        context.pushNamed('visitor-search', queryParameters: {'category': category});
      } else {
        context.pushNamed('visitor-search');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final nearbySitters = ref.watch(nearbySittersProvider);
    final topRatedSitters = ref.watch(topRatedSittersProvider);
    final categories = ref.watch(serviceCategoriesProvider);

    ref.listen(featuredSittersProvider, (_, next) {
      next.whenData((sitters) =>
          ref.read(appStateProvider.notifier).syncFavoritesFromModels(sitters));
    });
    ref.listen(topRatedSittersProvider, (_, next) {
      next.whenData((sitters) =>
          ref.read(appStateProvider.notifier).syncFavoritesFromModels(sitters));
    });

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(nearbySittersProvider);
        ref.invalidate(topRatedSittersProvider);
        ref.invalidate(serviceCategoriesProvider);
        ref.invalidate(platformStatisticsProvider);
      },
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _HomeHeader(
              subtitle: strings[AppLocalization.find_babysitter] ??
                  'Find trusted care nearby',
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _SearchBar(
                controller: _searchController,
                hint: strings[AppLocalization.search_hint] ??
                    'Search by location, skill, or name',
                onTap: () {
                  _navigateToSearch(context, ref);
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                0,
              ),
              child: const _PromoCard(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xl),
              child: categories.when(
                data: (items) => _CategoryStrip(
                  categories: items,
                  onCategoryTap: (category) => _navigateToSearch(context, ref, category: category.key),
                  onSeeAll: () => _navigateToSearch(context, ref),
                ),
                loading: () => const _CategorySkeleton(),
                error: (error, _) => _SectionError(
                  loadingChild: const _CategorySkeleton(),
                  onRetry: () {
                    // ignore: unused_result
                    ref.refresh(serviceCategoriesProvider);
                  },
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                top: AppSpacing.xl,
                start: AppSpacing.lg,
              ),
              child: AppSectionHeader(
                title: strings[AppLocalization.nearby] ?? 'Available near you',
                actionText: strings[AppLocalization.view_all] ?? 'View All',
                onAction: () => _navigateToSearch(context, ref),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 318,
              child: nearbySitters.when(
                data: (sitters) {
                  if (sitters.isEmpty) {
                    return const _EmptySittersCard();
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    scrollDirection: Axis.horizontal,
                    itemCount: sitters.length > 9 ? 10 : sitters.length + (sitters.length == 9 ? 1 : 0),
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.md),
                    itemBuilder: (context, index) {
                      if (index == sitters.length || index == 9) {
                        return _ShowAllCard(
                          onTap: () => _navigateToSearch(context, ref),
                        );
                      }
                      final sitter = sitters[index];
                      return _FeaturedSitterCard(
                        sitter: sitter,
                        onTap: () => context.pushNamed(
                          AppRoutes.sitterDetails,
                          pathParameters: {'id': sitter.id},
                        ),
                        onBookTap: () => _onBookTap(context, sitter.id),
                      )
                          .animate()
                          .fadeIn(
                            duration: 400.ms,
                            delay: (50 * index).ms,
                          )
                          .slideX(
                            begin: 0.1,
                            duration: 400.ms,
                            delay: (50 * index).ms,
                          );
                    },
                  );
                },
                loading: () => ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (_, __) => const SitterCardShimmer(),
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSpacing.md),
                  itemCount: 3,
                ),
                  error: (error, _) => _SectionError(
                    loadingChild: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.sm,
                      ),
                      scrollDirection: Axis.horizontal,
                    itemBuilder: (_, __) => const SitterCardShimmer(),
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.md),
                    itemCount: 3,
                  ),
                  onRetry: () {
                    // ignore: unused_result
                    ref.refresh(nearbySittersProvider);
                  },
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
                0,
              ),
              child: AppSectionHeader(
                title: strings[AppLocalization.top_rated] ?? 'Top rated',
              ),
            ),
          ),
          topRatedSitters.when(
            data: (sitters) {
              if (sitters.isEmpty) {
                return SliverToBoxAdapter(
                  key: const ValueKey('top_rated_empty'),
                  child: const _EmptySittersCard(),
                );
              }
              return SliverList(
                key: const ValueKey('top_rated_data'),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final sitter = sitters[index];
                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        index == 0 ? AppSpacing.md : 0,
                        AppSpacing.lg,
                        index == sitters.length - 1
                            ? AppSpacing.lg
                            : AppSpacing.md,
                      ),
                      child: SitterCard(
                        id: sitter.id,
                        name: sitter.name,
                        rating: sitter.babysitterProfile?.rating ?? 0,
                        reviews: sitter.babysitterProfile?.reviewCount ?? 0,
                        hourlyRate: sitter.babysitterProfile?.hourlyRate ?? 0,
                        experience:
                            sitter.babysitterProfile?.yearsExperience ?? 0,
                        distance: sitter.location ?? 'Nearby',
                        imageUrl: sitter.avatar,
                        isFavorite: ref
                            .watch(appStateProvider)
                            .favoriteIds
                            .contains(sitter.id),
                        categories:
                            sitter.babysitterProfile?.categories ?? const [],
                        isCompact: true,
                        onTap: () => context.pushNamed(
                          AppRoutes.sitterDetails,
                          pathParameters: {'id': sitter.id},
                        ),
                        onBookTap: () => _onBookTap(context, sitter.id),
                      ),
                    );
                  },
                  childCount: sitters.length,
                ),
              );
            },
            loading: () => SliverList(
              key: const ValueKey('top_rated_loading'),
              delegate: SliverChildBuilderDelegate(
                (_, __) => const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: SitterCardShimmer(width: double.infinity),
                ),
                childCount: 3,
              ),
            ),
            error: (error, _) => SliverToBoxAdapter(
              key: const ValueKey('top_rated_error'),
              child: _SectionError(
                loadingChild: SizedBox(
                  height: 280,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    itemBuilder: (_, __) => const SitterCardShimmer(
                      width: double.infinity,
                    ),
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemCount: 3,
                  ),
                ),
                onRetry: () {
                  // ignore: unused_result
                  ref.refresh(topRatedSittersProvider);
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xxxl,
              ),
              child: const _HowItWorksSection(),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final String subtitle;

  const _HomeHeader({
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSpacing.sm,
        bottom: AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.xxxl),
          bottomRight: Radius.circular(AppRadius.xxxl),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppColors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: AppLocalization.get(Localizations.localeOf(context).languageCode)[AppLocalization.menu] ?? 'Menu',
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  AppConstants.appName,
                  style: AppTextStyles.headlineMedium(
                    weight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.caption(
                    color: AppColors.white.withValues(alpha: 0.86),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xxxl),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onTap;

  const _SearchBar({
    required this.controller,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -18),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child:
                    Icon(Icons.search, color: context.primaryColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  hint,
                  style: AppTextStyles.bodyMedium(
                    color: context.textMutedColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.tune_rounded, color: context.textMutedColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.get(
      Localizations.localeOf(context).languageCode,
    );
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative Abstract Blobs
          Positioned(
            right: isArabic ? null : -30,
            left: isArabic ? -30 : null,
            top: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            right: isArabic ? null : 60,
            left: isArabic ? 60 : null,
            bottom: -70,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Text(
                          strings[AppLocalization.first_booking_perk] ?? 'Trusted Care',
                          style: AppTextStyles.labelSmall(
                            color: AppColors.white,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        strings[AppLocalization.match_verified_care] ?? 'Find the perfect sitter for your child',
                        style: AppTextStyles.headlineSmall(
                          color: AppColors.white,
                          weight: FontWeight.bold,
                        ).copyWith(height: 1.2),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        strings[AppLocalization.browse_real_profiles] ?? 'All sitters are fully verified, reviewed, and ready to help.',
                        style: AppTextStyles.bodyMedium(
                          color: AppColors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: isArabic ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.child_care_rounded,
                        color: AppColors.primary,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  final List<ServiceCategoryModel> categories;
  final ValueChanged<ServiceCategoryModel> onCategoryTap;
  final VoidCallback onSeeAll;

  const _CategoryStrip({
    required this.categories,
    required this.onCategoryTap,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    final strings = AppLocalization.get(
      Localizations.localeOf(context).languageCode,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: AppSectionHeader(
            title: strings[AppLocalization.care_services] ?? 'Care services',
            actionText: strings[AppLocalization.see_all] ?? 'See All',
            onAction: onSeeAll,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 96,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final category = categories[index];
              final color = _parseHexColor(category.color);
              return GestureDetector(
                onTap: () => onCategoryTap(category),
                child: Container(
                  width: 96,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
Icon(AppIcons.resolve(category.icon),
    color: color, size: 22),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        category.label,
                        style: AppTextStyles.labelSmall(
                          weight: FontWeight.w600,
                          color: context.textPrimaryColor,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FeaturedSitterCard extends ConsumerWidget {
  final UserModel sitter;
  final VoidCallback onTap;
  final VoidCallback onBookTap;

  const _FeaturedSitterCard({
    required this.sitter,
    required this.onTap,
    required this.onBookTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = sitter.babysitterProfile;
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final isFavorite =
        ref.watch(appStateProvider).favoriteIds.contains(sitter.id);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                GestureDetector(
                  onTap: AppImagePreview.canPreview(sitter.avatar)
                      ? () => AppImagePreview.show(context, sitter.avatar, name: sitter.name)
                      : null,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.xl),
                    ),
                    child: AppNetworkImage(
                      imageUrl: sitter.avatar,
                      width: double.infinity,
                      height: 130,
                      placeholder: _SitterPhotoPlaceholder(name: sitter.name),
                      errorWidget: _SitterPhotoPlaceholder(name: sitter.name),
                    ),
                  ),
                ),
                Positioned(
                  top: AppSpacing.sm,
                  left: AppSpacing.sm,
                  child: AppStatusPill(
                    icon: Icons.star_rounded,
                    label: (profile?.rating ?? 0).toStringAsFixed(1),
                    color: AppColors.accentDark,
                  ),
                ),
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: GestureDetector(
                    onTap: () {
                      if (!ref.read(authProvider).isAuthenticated) {
                        showLoginSheet(context, message: 'Login to save favorites');
                        return;
                      }
                      ref.read(appStateProvider.notifier).toggleFavorite(sitter.id).then((_) {
                        if (!context.mounted) return;
                        final isFav = ref.read(appStateProvider).favoriteIds.contains(sitter.id);
                        AppSnackbar.success(context, isFav ? (strings[AppLocalization.added_to_favorites] ?? 'Added to favorites') : (strings[AppLocalization.removed_from_favorites] ?? 'Removed from favorites'));
                      }).catchError((e) {
                        if (!context.mounted) return;
                        final msg = e is Exception ? e.toString().replaceAll('Exception: ', '') : (strings[AppLocalization.could_not_update_favorite] ?? 'Could not update favorite');
                        AppSnackbar.error(context, msg);
                      });
                    },
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: context.cardColor,
                      child: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFavorite
                            ? AppColors.error
                            : context.textMutedColor,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sitter.name,
                    style: AppTextStyles.titleMedium(
                      weight: FontWeight.w600,
                      color: context.textPrimaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: context.textMutedColor,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          sitter.location ?? 'Nearby',
                          style: AppTextStyles.labelSmall(
                            color: context.textMutedColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '﷼${(profile?.hourlyRate ?? 0).toStringAsFixed(0)}/hr',
                        style: AppTextStyles.titleLarge(
                          weight: FontWeight.bold,
                          color: context.primaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      GestureDetector(
                        onTap: onBookTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: AppColors.primaryGradient),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Text(
                            strings[AppLocalization.book] ?? 'Book',
                            style: AppTextStyles.labelMedium(
                              weight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SitterPhotoPlaceholder extends StatelessWidget {
  final String name;

  const _SitterPhotoPlaceholder({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((part) => part.isEmpty ? '' : part[0])
        .join()
        .toUpperCase();

    return Container(
      height: 130,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: CircleAvatar(
          radius: 32,
          backgroundColor: AppColors.white.withValues(alpha: 0.25),
          child: Text(
            initials,
            style: AppTextStyles.titleLarge(
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}


class _SectionError extends StatefulWidget {
  final Widget loadingChild;
  final VoidCallback? onRetry;

  const _SectionError({
    required this.loadingChild,
    this.onRetry,
  });

  @override
  State<_SectionError> createState() => _SectionErrorState();
}

class _SectionErrorState extends State<_SectionError> {
  bool _isRetrying = false;

  @override
  void didUpdateWidget(_SectionError oldWidget) {
    super.didUpdateWidget(oldWidget);
    _isRetrying = false;
  }

  void _onRetry() {
    setState(() => _isRetrying = true);
    final cb = widget.onRetry;
    if (cb == null) return;
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) cb();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isRetrying) {
      return widget.loadingChild;
    }

    final strings = AppLocalization.get(
      Localizations.localeOf(context).languageCode,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.errorColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.errorColor.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 18,
                color: context.errorColor,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                strings[AppLocalization.no_internet_connection] ??
                    'No internet connection',
                style: AppTextStyles.bodySmall(
                  color: context.textSecondaryColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.onRetry != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Material(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.button),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  onTap: _onRetry,
                  child: Container(
                    width: 100,
                    height: 34,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.refresh_rounded,
                            size: 14, color: AppColors.white),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          strings[AppLocalization.retry] ?? 'Retry',
                          style: AppTextStyles.bodySmall(
                            weight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptySittersCard extends StatelessWidget {
  const _EmptySittersCard();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.get(
      Localizations.localeOf(context).languageCode,
    );
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          strings[AppLocalization.no_sitters_available] ??
              'No babysitters available yet.',
          style: AppTextStyles.bodyMedium(color: context.textSecondaryColor),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _CategorySkeleton extends StatelessWidget {
  const _CategorySkeleton();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.get(
      Localizations.localeOf(context).languageCode,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                strings[AppLocalization.care_services] ?? 'Care services',
                style: AppTextStyles.titleLarge(
                  color: context.textPrimaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                strings[AppLocalization.see_all] ?? 'See All',
                style: AppTextStyles.labelLarge(
                  weight: FontWeight.w500,
                  color: context.primaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 96,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            scrollDirection: Axis.horizontal,
            itemBuilder: (_, __) => AppShimmer(
              width: 96,
              height: 96,
              borderRadius: AppRadius.lg,
            ),
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemCount: 4,
          ),
        ),
      ],
    );
  }
}

Color _parseHexColor(String value) {
  final hex = value.replaceAll('#', '');
  if (hex.length != 6) return AppColors.primary;
  return Color(int.parse('FF$hex', radix: 16));
}

class _ShowAllCard extends StatelessWidget {
  final VoidCallback onTap;
  
  const _ShowAllCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.get(Localizations.localeOf(context).languageCode);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: context.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: context.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              strings[AppLocalization.view_all] ?? 'Show all',
              style: AppTextStyles.titleMedium(
                weight: FontWeight.w600,
                color: context.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HowItWorksSection extends ConsumerWidget {
  const _HowItWorksSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalization.get(Localizations.localeOf(context).languageCode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings[AppLocalization.how_it_works] ?? 'How It Works',
          style: AppTextStyles.titleLarge(
            color: context.textPrimaryColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            children: [
              _StepRow(
                icon: Icons.search_rounded,
                title: strings[AppLocalization.find_sitters] ?? 'Find Sitters',
                description: strings[AppLocalization.find_sitters_desc] ?? 'Search for trusted sitters near you.',
                color: context.primaryColor,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xs, horizontal: 22),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    height: 20,
                    child: VerticalDivider(color: AppColors.textMutedLight, thickness: 2),
                  ),
                ),
              ),
              _StepRow(
                icon: Icons.check_circle_outline_rounded,
                title: strings[AppLocalization.book_confirm] ?? 'Book & Confirm',
                description: strings[AppLocalization.book_confirm_desc] ?? 'Schedule a booking and get instant confirmation.',
                color: context.successColor,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xs, horizontal: 22),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    height: 20,
                    child: VerticalDivider(color: AppColors.textMutedLight, thickness: 2),
                  ),
                ),
              ),
              _StepRow(
                icon: Icons.favorite_border_rounded,
                title: strings[AppLocalization.enjoy_peace] ?? 'Enjoy Peace of Mind',
                description: strings[AppLocalization.enjoy_peace_desc] ?? 'Relax knowing your children are in good hands.',
                color: context.errorColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.primaryGradient),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: ref.watch(platformStatisticsProvider).when(
                data: (stats) {
                  if (stats.isEmpty) return const SizedBox.shrink();

                  final languageCode = Localizations.localeOf(context).languageCode;
                  final isArabic = languageCode == 'ar';

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (int i = 0; i < stats.length; i++) ...[
                        _StatItem(
                          value: stats[i].value,
                          label: isArabic ? stats[i].labelAr : stats[i].label,
                          icon: stats[i].icon == 'star_rounded' ? Icons.star_rounded : null,
                        ),
                        if (i < stats.length - 1)
                          Container(width: 1, height: 40, color: AppColors.white.withValues(alpha: 0.3)),
                      ]
                    ],
                  );
                },
                loading: () => const Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                  ),
                ),
                error: (error, _) => const SizedBox.shrink(),
              ),
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _StepRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.titleMedium(
                  weight: FontWeight.w600,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTextStyles.bodySmall(
                  color: context.textMutedColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;

  const _StatItem({required this.value, required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.warning, size: 18),
              const SizedBox(width: 4),
            ],
            Text(
              value,
              style: AppTextStyles.titleLarge(
                weight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: AppTextStyles.labelSmall(
            color: AppColors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
