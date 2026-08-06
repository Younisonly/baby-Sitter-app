import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:babysitter/core/constants/app_config.dart';
import 'package:babysitter/core/network/error_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';

import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/extensions/extensions.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/routing/app_routes.dart';
import 'package:babysitter/core/services/app_provider.dart';
import 'package:babysitter/core/services/auth_provider.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/core/utils/time_formatter.dart';
import 'package:babysitter/features/babysitters/data/babysitter_repository.dart';
import 'package:babysitter/features/babysitters/data/sitter_reviews_provider.dart';
import 'package:babysitter/shared/models/user_model.dart';
import 'package:babysitter/shared/widgets/widgets.dart';

class SitterDetailsScreen extends ConsumerStatefulWidget {
  const SitterDetailsScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<SitterDetailsScreen> createState() =>
      _SitterDetailsScreenState();
}

class _SitterDetailsScreenState extends ConsumerState<SitterDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ValueNotifier<bool> _followLoading = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _followLoading.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sitterAsync = ref.watch(sitterDetailsProvider(widget.id));

    ref.listen(sitterDetailsProvider(widget.id), (_, next) {
      next.whenData((sitter) => ref
          .read(appStateProvider.notifier)
          .syncFavoritesFromModels([sitter]));
    });

    return sitterAsync.when(
      data: _buildDetails,
      loading: () => const Scaffold(
        body: DetailsShimmer(),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorState(
          message: 'Failed to load sitter details. Please try again.',
          onRetry: () => ref.invalidate(sitterDetailsProvider(widget.id)),
        ),
      ),
    );
  }

  Widget _buildDetails(UserModel sitter) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final profile = sitter.babysitterProfile ?? BabysitterProfile.empty();
    final isFavorite =
        ref.watch(appStateProvider).favoriteIds.contains(sitter.id);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 300.h,
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: Container(
              margin: const EdgeInsets.only(left: AppSpacing.sm),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Center(
                  child: Icon(Icons.arrow_back_rounded, color: AppColors.white, size: 20),
                ),
              ),
            ),
              actions: [
                Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(right: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      if (!ref.read(authProvider).isAuthenticated) {
                        showLoginSheet(context, message: strings[AppLocalization.login_to_favorite] ?? 'Login to save your favorite babysitters');
                        return;
                      }
                      ref.read(appStateProvider.notifier).toggleFavorite(sitter.id)
                        .then((_) {
                          if (!mounted) return;
                          final isFav = ref.read(appStateProvider).favoriteIds.contains(sitter.id);
                          AppSnackbar.success(
                            context,
                            isFav
                                ? (strings[AppLocalization.added_to_favorites] ?? 'Added to favorites')
                                : (strings[AppLocalization.removed_from_favorites] ?? 'Removed from favorites'),
                          );
                        })
                        .catchError((e) {
                          if (!mounted) return;
                          AppSnackbar.error(context, ErrorHandler.handle(e).message);
                        });
                    },
                    child: Center(
                      child: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFavorite ? AppColors.error : AppColors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: GestureDetector(
                  onTap: AppImagePreview.canPreview(sitter.avatar)
                      ? () => AppImagePreview.show(context, sitter.avatar, name: sitter.name)
                      : null,
                  child: AppNetworkImage(
                    imageUrl: sitter.avatar,
                    fit: BoxFit.cover,
                    placeholder: _ProfileHeroPlaceholder(name: sitter.name),
                    errorWidget: _ProfileHeroPlaceholder(name: sitter.name),
                  ),
                ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sitter.name,
                              style: AppTextStyles.displaySmall(),
                            ),
                            SizedBox(height: AppSpacing.xs),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
                                SizedBox(width: 2),
                                Text(
                                  profile.rating.toStringAsFixed(1),
                                  style: AppTextStyles.titleSmall(
                                    weight: FontWeight.w700,
                                    color: AppColors.warning,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '(${profile.reviewCount})',
                                  style: AppTextStyles.caption(color: context.textMutedColor),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppColors.primaryGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.button),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '﷼',
                              style: AppTextStyles.titleSmall(
                                weight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                            SizedBox(width: AppSpacing.xxs),
                            Text(
                              profile.hourlyRate.toStringAsFixed(0),
                              style: AppTextStyles.titleMedium(
                                weight: FontWeight.w800,
                                color: AppColors.white,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: AppSpacing.xs),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Text(
                                  strings[AppLocalization.per_hour] ?? '/hr',
                                  style: AppTextStyles.caption(color: AppColors.white.withValues(alpha: 0.85)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.md),
                  _buildActionButtons(sitter, strings, isFavorite),
                  SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCell(
                          icon: Icons.work_outline,
                          value: '${profile.yearsExperience}',
                          label: strings[AppLocalization.experience] ?? 'Experience',
                        ),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _StatCell(
                          icon: Icons.event_available,
                          value: '${profile.completedBookings}',
                          label: strings[AppLocalization.bookings] ?? 'Bookings',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCell(
                          icon: Icons.group_outlined,
                          value: '${profile.followerCount > 0 ? profile.followerCount : 0}',
                          label: strings[AppLocalization.followers] ?? 'Followers',
                        ),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _StatCell(
                          icon: Icons.star_rounded,
                          value: profile.rating.toStringAsFixed(1),
                          label: strings[AppLocalization.rating] ?? 'Rating',
                        ),
                      ),
                    ],
                  ),
                  if (profile.categories.isNotEmpty) ...[
                    SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: 32,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: profile.categories.length,
                        separatorBuilder: (_, __) => SizedBox(width: AppSpacing.sm),
                        itemBuilder: (_, i) => AppChip(
                          label: profile.categories[i],
                          isSelected: false,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabDelegate(
              AppTabBar(
                controller: _tabController,
                tabs: [
                  strings[AppLocalization.about] ?? 'About',
                  strings[AppLocalization.reviews] ?? 'Reviews',
                  strings[AppLocalization.schedule] ?? 'Schedule',
                ],
              ),
            ),
          ),
        ],
        body: Builder(
          builder: (context) => TabBarView(
            controller: _tabController,
            children: [
              CustomScrollView(
                slivers: [
                  _AboutSliver(profile: profile, location: sitter.location, latitude: sitter.latitude, longitude: sitter.longitude),
                ],
              ),
              CustomScrollView(
                slivers: [
                  _ReviewsSliver(sitterId: sitter.id, profile: profile),
                ],
              ),
              CustomScrollView(
                slivers: [
                  _ScheduleSliver(availability: profile.availability),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(UserModel sitter, Map<String, String> strings, bool isFavorite) {
    return Row(
      children: [
        // TODO: Uncomment when chat is enabled for confirmed bookings only
        // Container(
        //   decoration: BoxDecoration(
        //     shape: BoxShape.circle,
        //     color: context.cardColor,
        //   ),
        //   child: IconButton(
        //     icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
        //     onPressed: () {
        //       if (!ref.read(authProvider).isAuthenticated) {
        //         showLoginSheet(context, message: strings[AppLocalization.login_to_chat] ?? 'Login to message babysitters');
        //         return;
        //       }
        //       context.push('/chat?userId=${sitter.id}');
        //     },
        //   ),
        // ),
        SizedBox(width: AppSpacing.sm),
        ValueListenableBuilder<bool>(
          valueListenable: _followLoading,
          builder: (context, isLoading, _) {
            final cs = Theme.of(context).colorScheme;
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFavorite
                    ? cs.primary.withValues(alpha: 0.12)
                    : context.cardColor,
              ),
              child: isLoading
                  ? Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.primary,
                        ),
                      ),
                    )
                  : IconButton(
                      icon: Icon(
                        isFavorite ? Icons.person_remove_rounded : Icons.person_add_alt_rounded,
                        size: 20,
                        color: isFavorite ? cs.primary : null,
                      ),
                      onPressed: () {
                        if (!ref.read(authProvider).isAuthenticated) {
                          showLoginSheet(context, message: strings[AppLocalization.login_to_favorite] ?? 'Login to follow babysitters');
                          return;
                        }
                        final currentUserId = ref.read(authProvider).user?.id;
                        if (currentUserId == sitter.id) {
                          AppSnackbar.info(context, strings[AppLocalization.cannot_follow_yourself] ?? 'You cannot follow yourself.');
                          return;
                        }
                        _followLoading.value = true;
                        ref.read(appStateProvider.notifier).toggleFavorite(sitter.id)
                          .then((_) {
                            _followLoading.value = false;
                            if (!mounted) return;
                            final nowFav = ref.read(appStateProvider).favoriteIds.contains(sitter.id);
                            AppSnackbar.success(
                              context,
                              nowFav
                                  ? (strings[AppLocalization.following_sitter]?.replaceAll('{name}', sitter.name) ?? 'Following ${sitter.name}')
                                  : (strings[AppLocalization.unfollowed_sitter]?.replaceAll('{name}', sitter.name) ?? 'Unfollowed ${sitter.name}'),
                            );
                          })
                          .catchError((error) {
                            _followLoading.value = false;
                            if (!mounted) return;
                            final msg = error is AppException
                                ? error.message
                                : (strings[AppLocalization.could_not_update_follow] ?? 'Could not update follow status');
                            AppSnackbar.error(context, msg);
                          });
                      },
                    ),
            );
          },
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: AppButton(
            text: strings[AppLocalization.book_now] ?? 'Book Now',
            fontSize: 14,
            prefixIcon: const Icon(Icons.calendar_today_rounded, size: 17),
            onPressed: () {
              if (!ref.read(authProvider).isAuthenticated) {
                showLoginSheet(context, message: strings[AppLocalization.login_to_book] ?? 'Login to book a babysitter');
                return;
              }
              final currentUser = ref.read(authProvider).user;
              if (currentUser?.id == sitter.id) {
                AppSnackbar.info(context, strings[AppLocalization.cannot_book_yourself] ?? 'You cannot book yourself.');
                return;
              }
              context.pushNamed(
                AppRoutes.bookingFlow,
                queryParameters: {'sitterId': sitter.id},
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProfileHeroPlaceholder extends StatelessWidget {
  const _ProfileHeroPlaceholder({required this.name});

  final String name;

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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: CircleAvatar(
          radius: 54.r,
          backgroundColor: AppColors.white.withValues(alpha: 0.2),
          child: Text(
            initials,
            style: AppTextStyles.displaySmall(color: AppColors.white),
          ),
        ),
      ),
    );
  }
}

class _SliverTabDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabDelegate(this.tabBar);

  final Widget tabBar;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: tabBar,
      ),
    );
  }

  @override
  double get maxExtent => AppSpacing.sm + 48 + AppSpacing.sm;

  @override
  double get minExtent => AppSpacing.sm + 48 + AppSpacing.sm;

  @override
  bool shouldRebuild(_SliverTabDelegate oldDelegate) => false;
}

class _AboutSliver extends StatelessWidget {
  const _AboutSliver({required this.profile, this.location, this.latitude, this.longitude});

  final BabysitterProfile profile;
  final String? location;
  final double? latitude;
  final double? longitude;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.get(
      Localizations.localeOf(context).languageCode,
    );
    final cs = Theme.of(context).colorScheme;
    final includedChildren = profile.includedChildren;
    final absoluteMaxChildren = profile.absoluteMaxChildren;
    final hourlyRate = profile.hourlyRate;
    final extraChildFee = profile.extraChildFee;

    Widget buildPricingRow({
      required IconData icon,
      required String title,
      required String subtitle,
      required String value,
      bool isPrimary = false,
    }) {
      return Container(
        padding: EdgeInsets.all(isPrimary ? AppSpacing.md : AppSpacing.sm),
        decoration: isPrimary
            ? BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: cs.primary.withValues(alpha: 0.2),
                ),
              )
            : null,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.primaryGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, size: 18, color: AppColors.white),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleSmall(
                      weight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption(color: cs.onSurface.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
            Text(
              value,
              style: AppTextStyles.titleMedium(
                weight: FontWeight.w700,
                color: isPrimary ? cs.primary : cs.onSurface,
              ),
            ),
          ],
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (location != null && location!.isNotEmpty) ...[
              _SectionHeader(
                icon: Icons.location_on_rounded,
                title: strings[AppLocalization.location] ?? 'Location',
              ),
              SizedBox(height: AppSpacing.sm),
              if (latitude != null && longitude != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocationView(
                      latitude: latitude,
                      longitude: longitude,
                      locationName: location,
                      strings: strings,
                    ),
                    if (location != null && location!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: cs.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: AppColors.primaryGradient,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                                child: const Icon(Icons.location_on_rounded,
                                    size: 18, color: AppColors.white),
                              ),
                              SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  location!,
                                  style: AppTextStyles.bodyMedium(
                                    color: cs.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppColors.primaryGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(Icons.location_on_rounded,
                            size: 18, color: AppColors.white),
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          location ?? strings[AppLocalization.nearby] ?? 'Nearby',
                          style: AppTextStyles.bodyMedium(
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: AppSpacing.xl),
            ],
            _SectionHeader(
              icon: Icons.info_outline_rounded,
              title: strings[AppLocalization.about] ?? 'About',
            ),
            SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: profile.description?.isNotEmpty == true
                  ? ExpandableText(
                      text: profile.description!,
                      style: AppTextStyles.bodyMedium(color: cs.onSurface),
                    )
                  : Text(
                      strings[AppLocalization.no_bio_yet] ??
                          'This sitter has not added a bio yet.',
                      style: AppTextStyles.bodyMedium(
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
            ),
            SizedBox(height: AppSpacing.xl),
            _SectionHeader(
              icon: Icons.receipt_long_rounded,
              title: strings[AppLocalization.pricing] ?? 'Fees',
            ),
            SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                children: [
                  buildPricingRow(
                    icon: Icons.child_care_rounded,
                    title: strings[AppLocalization.base_rate] ?? 'Base fee',
                    subtitle: includedChildren > 1
                        ? (strings[AppLocalization.up_to_children] ?? 'Up to {count} children').replaceAll('{count}', '$includedChildren')
                        : (strings[AppLocalization.up_to_child] ?? 'Up to {count} child').replaceAll('{count}', '$includedChildren'),
                    value: '﷼$hourlyRate${strings[AppLocalization.per_hour] ?? '/hr'}',
                    isPrimary: true,
                  ),
                  if (extraChildFee > 0) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Divider(height: 1),
                    ),
                    buildPricingRow(
                      icon: Icons.add_circle_outline_rounded,
                      title: strings[AppLocalization.additional_child] ?? 'Additional child',
                      subtitle: absoluteMaxChildren != null
                          ? (strings[AppLocalization.children_total] ?? '{count} children total').replaceAll('{count}', '$absoluteMaxChildren')
                          : (strings[AppLocalization.per_extra_child] ?? 'Per extra child'),
                      value: '+﷼$extraChildFee${strings[AppLocalization.per_hour] ?? '/hr'}',
                    ),
                  ],
                  if (profile.specialNeedsRate > 0) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Divider(height: 1),
                    ),
                    buildPricingRow(
                      icon: Icons.favorite_outline_rounded,
                      title: strings[AppLocalization.special_needs_rate_label] ?? 'Special needs care',
                      subtitle: strings[AppLocalization.additional_hourly_rate] ?? 'Additional hourly rate',
                      value: '+﷼${profile.specialNeedsRate.toStringAsFixed(0)}${strings[AppLocalization.per_hour] ?? '/hr'}',
                    ),
                  ],
                  if (absoluteMaxChildren != null) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Divider(height: 1),
                    ),
                    buildPricingRow(
                      icon: Icons.people_outline_rounded,
                      title: strings[AppLocalization.max_capacity] ?? 'Max capacity',
                      subtitle: strings[AppLocalization.maximum_children] ?? 'Maximum children allowed',
                      value: '$absoluteMaxChildren',
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: AppSpacing.xl),
            _SectionHeader(
              icon: Icons.verified_outlined,
              title: strings[AppLocalization.certificates] ?? 'Certificates',
            ),
            SizedBox(height: AppSpacing.sm),
            if (profile.certificates.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  strings[AppLocalization.no_certificates] ??
                      'No certificates uploaded yet.',
                  style: AppTextStyles.bodyMedium(
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              )
            else
              ...profile.certificates.map(
                (cert) => _CertificateTile(
                  title: cert is String ? cert : (cert['name'] as String? ?? ''),
                ),
              ),
            SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.primaryGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: 16, color: AppColors.white),
        ),
        SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: AppTextStyles.titleMedium(
            weight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Container(
            height: 1,
            color: cs.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }
}

class _CertificateTile extends StatelessWidget {
  const _CertificateTile({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Icons.verified_outlined, color: AppColors.white),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(child: Text(title, style: AppTextStyles.titleMedium())),
        ],
      ),
    );
  }
}

class _ReviewsSliver extends ConsumerWidget {
  const _ReviewsSliver({required this.sitterId, required this.profile});

  final String sitterId;
  final BabysitterProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalization.get(
      Localizations.localeOf(context).languageCode,
    );
    final reviewsAsync = ref.watch(sitterReviewsProvider(sitterId));

    return reviewsAsync.when(
      loading: () => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: List.generate(3, (_) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppShimmer(width: 40, height: 40, isCircular: true),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppShimmer(width: 120, height: 14),
                        SizedBox(height: AppSpacing.sm),
                        AppShimmer(width: 60, height: 12),
                        SizedBox(height: AppSpacing.xs),
                        AppShimmer(width: double.infinity, height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ),
        ),
      ),
      error: (_, __) => SliverToBoxAdapter(
        child: EmptyState(
          title: strings[AppLocalization.failed_to_load_reviews] ?? 'Failed to load reviews',
          subtitle: strings[AppLocalization.retry_message] ?? 'Please check your connection and try again.',
          icon: Icon(Icons.error_outline_rounded,
              size: 72.sp, color: AppColors.error),
          actionLabel: strings[AppLocalization.retry] ?? 'Retry',
          onAction: () => ref.invalidate(sitterReviewsProvider(sitterId)),
        ),
      ),
      data: (reviews) {
        if (reviews.isEmpty) {
          return SliverToBoxAdapter(
            child: EmptyState(
              title: '${profile.rating.toStringAsFixed(1)} ${strings[AppLocalization.rating] ?? 'Rating'}',
              subtitle: '${profile.reviewCount} ${strings[AppLocalization.reviews] ?? 'Reviews'}',
              icon: Icon(Icons.rate_review_outlined,
                  size: 72.sp, color: AppColors.accent),
            ),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final review = reviews[index];
              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md,
                ),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18.sp,
                            backgroundImage: review.reviewerAvatar != null
                                ? CachedNetworkImageProvider(
                                    AppConfig.absoluteUrl(review.reviewerAvatar!),
                                  )
                                : null,
                            child: review.reviewerAvatar == null
                                ? Text(
                                    review.reviewerName.isNotEmpty
                                        ? review.reviewerName[0].toUpperCase()
                                        : '?',
                                    style: AppTextStyles.titleSmall(),
                                  )
                                : null,
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  review.reviewerName,
                                  style: AppTextStyles.titleMedium(
                                      weight: FontWeight.w600),
                                ),
                                Text(
                                  DateFormat('MMM d, yyyy').format(review.createdAt),
                                  style: AppTextStyles.caption(
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                                ),
                              ],
                            ),
                          ),
                          RatingDisplay(
                            rating: review.rating,
                            reviewCount: 0,
                            size: 16,
                          ),
                        ],
                      ),
                      if (review.comment != null && review.comment!.isNotEmpty) ...[
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          review.comment!,
                          style: AppTextStyles.bodyMedium(),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
            childCount: reviews.length,
          ),
        );
      },
    );
  }
}

class _ScheduleSliver extends StatelessWidget {
  const _ScheduleSliver({required this.availability});

  final List<AvailabilitySlot> availability;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final strings = AppLocalization.get(locale);
    final cs = Theme.of(context).colorScheme;
    if (availability.isEmpty) {
      return SliverToBoxAdapter(
        child: EmptyState(
          title: strings[AppLocalization.no_schedule_yet] ?? 'No schedule yet',
          subtitle: strings[AppLocalization.no_schedule_subtitle] ??
              'This sitter has not published availability.',
          icon: Icon(Icons.schedule_outlined,
              size: 72.sp, color: cs.primary),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final slot = availability[index];
          return Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg, index == 0 ? AppSpacing.lg : 0, AppSpacing.lg, AppSpacing.sm,
            ),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.primaryGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _dayLabel(slot.dayOfWeek).substring(0, 2),
                          style: AppTextStyles.caption(
                            weight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _dayLabel(slot.dayOfWeek),
                          style: AppTextStyles.titleMedium(
                            weight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded,
                                size: 13, color: cs.onSurface.withValues(alpha: 0.5)),
                            SizedBox(width: 4),
                            Text(
                              slot.startTime == '00:00' && slot.endTime == '23:59'
                                  ? (strings[AppLocalization.all_day] ?? 'All Day')
                                  : TimeFormatter.formatTimeRange(slot.startTime, slot.endTime, locale),
                              style: AppTextStyles.bodySmall(
                                color: cs.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      strings[AppLocalization.calendar_available] ?? 'Available',
                      style: AppTextStyles.caption(
                        weight: FontWeight.w600,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        childCount: availability.length,
      ),
    );
  }

}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
            ),
            child: Icon(icon, size: 16, color: AppColors.white),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: AppTextStyles.titleSmall(weight: FontWeight.w700)),
                Text(label, style: AppTextStyles.caption()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}






String _dayLabel(int day) {
  if (day < 0 || day > 6) return 'Day $day';
  return DateFormat('EEE').format(
    DateTime(2024, 1, 6 + day),
  );
}
