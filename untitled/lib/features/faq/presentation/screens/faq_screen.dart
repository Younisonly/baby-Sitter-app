import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_shadows.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/extensions.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/features/faq/data/faq_providers.dart';
import 'package:babysitter/shared/models/faq_model.dart';
import 'package:babysitter/shared/widgets/widgets.dart';

class FaqScreen extends ConsumerStatefulWidget {
  const FaqScreen({super.key});

  @override
  ConsumerState<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends ConsumerState<FaqScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(faqProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final state = ref.watch(faqProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: strings[AppLocalization.faq_title] ?? 'FAQ',
      ),
      body: _buildBody(strings, state),
    );
  }

  Widget _buildBody(Map<String, String> strings, FaqState state) {
    switch (state.status) {
      case FaqStateStatus.initial:
      case FaqStateStatus.loading:
        return const _FaqShimmer();
      case FaqStateStatus.error:
        return ErrorState(
          title: strings[AppLocalization.failed_to_load] ?? 'Failed to load',
          message: state.error ?? strings[AppLocalization.load_error_message] ?? 'Please check your connection and try again',
          onRetry: () => ref.read(faqProvider.notifier).load(),
        );
      case FaqStateStatus.success:
        if (state.faqs.isEmpty) {
          return EmptyState(
            title: strings[AppLocalization.faq_empty] ?? 'No FAQs yet',
            subtitle: strings[AppLocalization.faq_empty_subtitle] ??
                'Check back later for frequently asked questions.',
            icon: const Icon(
              Icons.help_outline_rounded,
              size: 80,
              color: AppColors.primary,
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(faqProvider.notifier).refresh(),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: state.faqs.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              return _FaqTile(faq: state.faqs[index]);
            },
          ),
        );
    }
  }
}

class _FaqTile extends StatefulWidget {
  final FaqModel faq;
  const _FaqTile({required this.faq});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            title: Text(
              widget.faq.question,
              style: AppTextStyles.titleMedium(weight: FontWeight.w600),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Icon(
              _expanded
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded,
              color: AppColors.primary,
            ),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Text(
                widget.faq.answer,
                style: AppTextStyles.bodyMedium(),
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

class _FaqShimmer extends StatelessWidget {
  const _FaqShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: 5,
      itemBuilder: (_, __) => const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.sm),
        child: AppShimmer(width: double.infinity, height: 64),
      ),
    );
  }
}
