import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_config.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/features/admin/data/admin_providers.dart';
import 'package:babysitter/features/admin/data/admin_repository.dart';
import 'package:babysitter/shared/models/user_model.dart';
import 'package:babysitter/shared/widgets/widgets.dart';

class AdminSitterApprovalScreen extends ConsumerStatefulWidget {
  const AdminSitterApprovalScreen({super.key});

  @override
  ConsumerState<AdminSitterApprovalScreen> createState() => _AdminSitterApprovalScreenState();
}

class _AdminSitterApprovalScreenState extends ConsumerState<AdminSitterApprovalScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() => ref.read(pendingSittersProvider.notifier).load());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(pendingSittersProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final state = ref.watch(pendingSittersProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: strings['admin_sitter_approval'] ?? 'Sitter Approvals',
      ),
      body: _buildBody(strings, state),
    );
  }

  Widget _buildBody(Map<String, String> strings, PendingSittersState state) {
    if (state.isLoading) {
      return const ListShimmer(itemCount: 4, itemHeight: 180);
    }

    if (state.error != null && state.sitters.isEmpty) {
      return ErrorState(
        title: strings['failed_load'] ?? 'Failed to load',
        message: state.error ?? 'Please check your connection and try again',
        onRetry: () => ref.read(pendingSittersProvider.notifier).load(),
      );
    }

    if (state.sitters.isEmpty) {
      return EmptyState(
        title: strings['no_pending_sitters'] ?? 'No pending approvals',
        subtitle: strings['no_pending_sitters_subtitle'] ?? 'All sitter registrations have been reviewed.',
        icon: Icon(
          Icons.verified_user_rounded,
          size: 80,
          color: AppColors.primary,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(pendingSittersProvider.notifier).refresh();
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: state.sitters.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.sitters.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return _SitterApprovalCard(
            sitter: state.sitters[index],
            onApprove: () => _confirmApprove(state.sitters[index]),
            onReject: () => _showRejectDialog(state.sitters[index]),
          );
        },
      ),
    );
  }

  void _confirmApprove(UserModel sitter) {
    final strings = AppLocalization.get(ref.read(languageProvider).code);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.check_circle_outline_rounded, size: 48, color: AppColors.success),
        title: Text(strings['approve_sitter_confirm'] ?? 'Approve Sitter'),
        content: Text(
          '${strings['approve_sitter_body'] ?? 'Are you sure you want to approve'} "${sitter.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(strings['cancel'] ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _approveSitter(sitter);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            child: Text(strings['approve'] ?? 'Approve'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveSitter(UserModel sitter) async {
    final strings = AppLocalization.get(ref.read(languageProvider).code);
    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.approveSitter(sitter.id);
      ref.read(pendingSittersProvider.notifier).refresh();
      if (mounted) {
        AppSnackbar.success(
          context,
          strings['sitter_approved'] ?? 'Sitter approved successfully.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e.toString());
      }
    }
  }

  void _showRejectDialog(UserModel sitter) {
    final strings = AppLocalization.get(ref.read(languageProvider).code);
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.cancel_outlined, size: 48, color: AppColors.error),
        title: Text(strings['reject_sitter'] ?? 'Reject Sitter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${strings['reject_sitter_body'] ?? 'Why are you rejecting'} "${sitter.name}"?',
              style: AppTextStyles.bodyMedium(),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: strings['rejection_reason_hint'] ?? 'Enter reason for rejection...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(strings['cancel'] ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final reason = reasonCtrl.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(ctx);
              _rejectSitter(sitter, reason);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(strings['reject'] ?? 'Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectSitter(UserModel sitter, String reason) async {
    final strings = AppLocalization.get(ref.read(languageProvider).code);
    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.rejectSitter(sitter.id, reason);
      ref.read(pendingSittersProvider.notifier).refresh();
      if (mounted) {
        AppSnackbar.info(
          context,
          strings['sitter_rejected'] ?? 'Sitter rejected.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e.toString());
      }
    }
  }
}

class _SitterApprovalCard extends ConsumerWidget {
  final UserModel sitter;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _SitterApprovalCard({
    required this.sitter,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final cs = Theme.of(context).colorScheme;
    final profile = sitter.babysitterProfile;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primary.withValues(alpha: 0.1),
                    image: sitter.avatar != null
                        ? DecorationImage(
                            image: NetworkImage(AppConfig.absoluteUrl(sitter.avatar!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: sitter.avatar == null
                      ? Icon(Icons.person_rounded, size: 24, color: cs.primary)
                      : null,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sitter.name,
                        style: AppTextStyles.titleSmall(weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sitter.email,
                        style: AppTextStyles.caption(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (sitter.phone != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          sitter.phone!,
                          style: AppTextStyles.caption(),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: cs.onSurface.withValues(alpha: 0.3)),
              ],
            ),
          ),
          if (profile != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Divider(color: cs.outlineVariant.withValues(alpha: 0.3), height: 1),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
              child: Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xs,
                children: [
                  _InfoChip(
                    icon: Icons.work_history_rounded,
                    label: '${strings['experience'] ?? 'Exp'}: ${profile.yearsExperience}${strings['years'] ?? 'yrs'}',
                  ),
                  if (profile.hourlyRate > 0)
                    _InfoChip(
                      icon: Icons.monetization_on_outlined,
                      label: '${profile.hourlyRate.toStringAsFixed(0)} ${strings['sar'] ?? 'SAR'}/hr',
                    ),
                  if (profile.categories.isNotEmpty && profile.categories.any((c) => c.isNotEmpty))
                    _InfoChip(
                      icon: Icons.category_outlined,
                      label: profile.categories.where((c) => c.isNotEmpty).take(2).join(', '),
                    ),
                  if (sitter.gender != null)
                    _InfoChip(
                      icon: Icons.person_outline_rounded,
                      label: strings[sitter.gender!.toLowerCase()] ?? sitter.gender!,
                    ),
                ],
              ),
            ),
          ],
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(AppRadius.card),
                bottomRight: Radius.circular(AppRadius.card),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: Text(strings['reject'] ?? 'Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: FilledButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(strings['approve'] ?? 'Approve'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: cs.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}
