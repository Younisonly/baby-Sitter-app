import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:shimmer/shimmer.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_config.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/extensions.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/network/dio_client.dart';
import 'package:babysitter/core/services/base_repository.dart';
import 'package:babysitter/core/services/cache_service.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/features/chat/data/chat_repository.dart';
import 'package:babysitter/features/chat/presentation/screens/conversation_detail_screen.dart';
import 'package:babysitter/shared/models/user_model.dart';
import 'package:babysitter/shared/widgets/widgets.dart';

final followersProvider = FutureProvider.autoDispose<List<UserModel>>((ref) async {
  return BaseRepository.fetchList(
    request: () async {
      final response = await DioClient.dio.get('/dashboard/followers', queryParameters: {
        'per_page': 50,
      });
      final raw = response.data is Map<String, dynamic>
          ? (response.data as Map<String, dynamic>)['data']
          : response.data;
      if (raw is! List) return [];
      return raw.whereType<Map<String, dynamic>>().toList();
    },
    cacheKey: 'dashboard_followers',
    fromJson: UserModel.fromJson,
    cacheDuration: CacheService.shortExpiry,
  );
});

class FollowersScreen extends ConsumerStatefulWidget {
  const FollowersScreen({super.key});

  @override
  ConsumerState<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends ConsumerState<FollowersScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final followersAsync = ref.watch(followersProvider);
    final strings = AppLocalization.get(ref.watch(languageProvider).code);

    return Scaffold(
      appBar: AppAppBar(
        title: strings[AppLocalization.followers] ?? 'Followers',
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md.w,
              AppSpacing.md.h,
              AppSpacing.md.w,
              AppSpacing.sm.h,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: strings[AppLocalization.search_hint] ?? 'Search followers...',
                prefixIcon: Icon(Icons.search_rounded, size: 20.sp),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded, size: 18.sp),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: AppSpacing.sm.h),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: followersAsync.when(
              loading: () => const _FollowersShimmer(),
              error: (err, _) => Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl.w),
                  child: AppErrorState(
                    title: strings[AppLocalization.something_went_wrong] ?? 'Something went wrong',
                    message: 'Failed to load followers',
                    onRetry: () => ref.invalidate(followersProvider),
                  ),
                ),
              ),
              data: (followers) {
                final filtered = _searchQuery.isEmpty
                    ? followers
                    : followers.where((f) =>
                        f.name.toLowerCase().contains(_searchQuery) ||
                        f.email.toLowerCase().contains(_searchQuery)).toList();

                if (filtered.isEmpty) {
                  final message = _searchQuery.isNotEmpty
                      ? 'No followers match your search'
                      : 'No followers yet';
                  final icon = _searchQuery.isNotEmpty
                      ? Icons.search_off_rounded
                      : Icons.people_outline_rounded;

                  return Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80.w,
                            height: 80.h,
                            decoration: BoxDecoration(
                              color: context.primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, size: 40.sp, color: context.primaryColor),
                          ),
                          Gap(AppSpacing.lg.h),
                          Text(
                            message,
                            style: AppTextStyles.bodyLarge(
                              color: context.textPrimaryColor,
                              weight: FontWeight.w600,
                            ),
                          ),
                          if (_searchQuery.isEmpty) ...[
                            Gap(AppSpacing.xs.h),
                            Text(
                              'When someone follows you, they will appear here',
                              style: AppTextStyles.bodySmall(
                                color: context.textSecondaryColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(followersProvider),
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.md.w,
                      AppSpacing.xs.h,
                      AppSpacing.md.w,
                      AppSpacing.xxl.h,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 60.w,
                      color: context.dividerColor,
                    ),
                    itemBuilder: (_, i) => _FollowerTile(follower: filtered[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowerTile extends ConsumerWidget {
  final UserModel follower;

  const _FollowerTile({required this.follower});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initial = follower.name.isNotEmpty ? follower.name[0].toUpperCase() : '?';
    final avatarUrl = follower.avatar;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm.h),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22.r,
            backgroundImage: avatarUrl != null ? NetworkImage(AppConfig.absoluteUrl(follower.avatar!)) : null,
            child: avatarUrl == null
                ? Text(initial, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600))
                : null,
          ),
          Gap(AppSpacing.sm.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  follower.name,
                  style: AppTextStyles.bodyMedium(
                    color: context.textPrimaryColor,
                    weight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Gap(AppSpacing.xxs.h),
                Text(
                  follower.email,
                  style: AppTextStyles.caption(color: context.textMutedColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 40.w,
            width: 40.w,
            child: IconButton(
              onPressed: () => _openChat(context, ref),
              icon: Icon(Icons.chat_bubble_outline_rounded, size: 18.sp),
              color: context.primaryColor,
              style: FilledButton.styleFrom(
                backgroundColor: context.primaryColor.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm.r),
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openChat(BuildContext context, WidgetRef ref) async {
    final userId = int.tryParse(follower.id);
    if (userId == null) return;

    try {
      final repo = ref.read(chatRepositoryProvider);
      final conversation = await repo.startConversation(userId);
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ConversationDetailScreen(conversation: conversation),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        final strings = AppLocalization.get(ref.read(languageProvider).code);
        AppSnackbar.error(context, strings['chat_create_failed'] ?? 'Could not start conversation');
      }
    }
  }
}

class _FollowersShimmer extends StatelessWidget {
  const _FollowersShimmer();

  @override
  Widget build(BuildContext context) {
    final base = context.isDark ? AppColors.skeletonBaseDark : AppColors.skeletonBaseLight;
    final highlight = context.isDark ? AppColors.skeletonHighlightDark : AppColors.skeletonHighlightLight;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: ListView(
        padding: EdgeInsets.all(AppSpacing.md.w),
        children: List.generate(6, (_) => Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm.h),
          child: Row(
            children: [
              Container(
                width: 44.w,
                height: 44.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              Gap(AppSpacing.sm.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 140.w,
                      height: 14.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.sm.r),
                      ),
                    ),
                    Gap(AppSpacing.xxs.h),
                    Container(
                      width: 100.w,
                      height: 10.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.sm.r),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.sm.r),
                ),
              ),
            ],
          ),
        )),
      ),
    );
  }
}
