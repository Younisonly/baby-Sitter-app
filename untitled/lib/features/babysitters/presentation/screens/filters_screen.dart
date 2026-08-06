import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/extensions.dart';
import 'package:babysitter/core/routing/app_routes.dart';
import 'package:babysitter/features/home/data/home_repository.dart';
import 'package:babysitter/shared/widgets/widgets.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/services/auth_provider.dart';

class FiltersScreen extends ConsumerWidget {
  const FiltersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(serviceCategoriesProvider);
    final strings = AppLocalization.get(Localizations.localeOf(context).languageCode);

    return Scaffold(
      appBar: AppAppBar(title: strings[AppLocalization.care_filters] ?? 'Care filters'),
      body: categories.when(
        data: (items) => GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.25,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final category = items[index];
            return InkWell(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              onTap: () {
                final authState = ref.read(authProvider);
                if (authState.isAuthenticated) {
                  context.pushNamed('parent-search', queryParameters: {'category': category.key});
                } else {
                  context.pushNamed('visitor-search', queryParameters: {'category': category.key});
                }
              },
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.tune_rounded, color: AppColors.primary),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      category.label,
                      style: AppTextStyles.titleMedium(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      category.description,
                      style: AppTextStyles.bodySmall(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: AppLoader()),
        error: (_, __) => ErrorState(
          message: 'Failed to load categories. Please check your connection and try again.',
          onRetry: () => ref.invalidate(serviceCategoriesProvider),
        ),
      ),
    );
  }
}
