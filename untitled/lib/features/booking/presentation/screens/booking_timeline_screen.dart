import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/theme_colors.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/core/utils/time_formatter.dart';
import 'package:babysitter/features/booking/data/booking_provider.dart';
import 'package:babysitter/shared/models/booking_model.dart';
import 'package:babysitter/shared/widgets/widgets.dart';

class BookingTimelineScreen extends ConsumerWidget {
  final String bookingId;

  const BookingTimelineScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final timelineAsync = ref.watch(bookingTimelineProvider(bookingId));

    return Scaffold(
      appBar: AppAppBar(title: strings['view_timeline'] ?? 'Booking Timeline'),
      body: timelineAsync.when(
        loading: () => const _TimelineShimmer(),
        error: (e, _) => _ErrorView(bookingId: bookingId, ref: ref),
        data: (events) {
          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timeline_rounded, size: 64, color: context.textMuted),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    strings['no_events'] ?? 'No timeline events yet',
                    style: AppTextStyles.titleMedium(color: context.textMuted),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: events.length,
            itemBuilder: (context, index) => _TimelineEventTile(
              event: events[index],
              isFirst: index == 0,
              isLast: index == events.length - 1,
              strings: strings,
            ),
          );
        },
      ),
    );
  }
}

class _TimelineEventTile extends StatelessWidget {
  final TimelineEvent event;
  final bool isFirst;
  final bool isLast;
  final Map<String, String> strings;

  const _TimelineEventTile({
    required this.event,
    required this.isFirst,
    required this.isLast,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final icon = _iconForType(event.type);
    final label = _labelForType(event.type);
    final desc = _description(event);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(child: Container(width: 2, color: context.textMuted.withValues(alpha: 0.3)))
                else
                  const Expanded(child: SizedBox.shrink()),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 16, color: context.primaryColor),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: context.textMuted.withValues(alpha: 0.3)))
                else
                  const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: isFirst ? 4 : 8, bottom: isLast ? 4 : 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.titleSmall(weight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(desc, style: AppTextStyles.bodySmall(color: context.textSecondary)),
                  const SizedBox(height: 2),
                  Text(
                    TimeFormatter.formatDetailTime(event.createdAt.toIso8601String(), Localizations.localeOf(context).languageCode),
                    style: AppTextStyles.bodySmall(color: context.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) => switch (type) {
        'created' => Icons.add_circle_outline,
        'status_change' => Icons.swap_horiz_rounded,
        'cancelled' => Icons.cancel_outlined,
        'reviewed' => Icons.star_outline_rounded,
        'rebooked' => Icons.replay_rounded,
        'rebook_from' => Icons.replay_rounded,
        'admin_override' => Icons.admin_panel_settings_outlined,
        _ => Icons.circle_outlined,
      };

  String _labelForType(String type) => switch (type) {
        'created' => (strings['booking_created'] ?? 'Booking Created'),
        'status_change' => (strings['status_changed'] ?? 'Status Changed'),
        'cancelled' => (strings['cancelled'] ?? 'Cancelled'),
        'reviewed' => (strings['reviewed'] ?? 'Reviewed'),
        'rebooked' => (strings['rebooked'] ?? 'Rebooked'),
        'rebook_from' => (strings['rebooked'] ?? 'Rebooked'),
        'admin_override' => (strings['admin_action'] ?? 'Admin Action'),
        _ => type,
      };

  String _description(TimelineEvent event) {
    final p = event.payload;
    return switch (event.type) {
      'created' => (p['total_amount'] as num?) != null
          ? (strings['timeline_amount'] ?? 'Amount: {amount}')
              .replaceAll('{amount}', '\$${(p['total_amount'] as num).toStringAsFixed(2)}')
          : '',
      'status_change' => p['reason'] != null
          ? (strings['status_change_with_reason'] ?? '{from} → {to} — {reason}')
              .replaceAll('{from}', '${p['from'] ?? '?'}')
              .replaceAll('{to}', '${p['to'] ?? '?'}')
              .replaceAll('{reason}', '${p['reason']}')
          : (strings['status_change_format'] ?? '{from} → {to}')
              .replaceAll('{from}', '${p['from'] ?? '?'}')
              .replaceAll('{to}', '${p['to'] ?? '?'}'),
      'cancelled' => (strings['cancelled_reason_refund'] ?? '{reason} (Refund: {refund_percent}%)')
          .replaceAll('{reason}', '${p['reason'] ?? (strings['no_reason_provided'] ?? 'No reason provided')}')
          .replaceAll('{refund_percent}', '${p['refund_percent'] ?? 0}'),
      'reviewed' => (strings['timeline_rating'] ?? 'Rating: {rating}/5')
          .replaceAll('{rating}', '${p['rating'] ?? '?'}'),
      'rebooked' => (strings['timeline_rebooked'] ?? 'New booking #{id}')
          .replaceAll('{id}', '${p['new_booking_id'] ?? '?'}'),
      'rebook_from' => (strings['timeline_rebook_from'] ?? 'From booking #{id}')
          .replaceAll('{id}', '${p['original_booking_id'] ?? '?'}'),
      'admin_override' => p['reason'] != null
          ? (strings['timeline_admin_action'] ?? '{action} — {reason}')
              .replaceAll('{action}', '${p['action'] ?? (strings['admin_action'] ?? 'Admin Action')}')
              .replaceAll('{reason}', '${p['reason']}')
          : (strings['timeline_admin_action_simple'] ?? '{action}')
              .replaceAll('{action}', '${p['action'] ?? (strings['admin_action'] ?? 'Admin Action')}'),
      _ => '',
    };
  }


}

class _TimelineShimmer extends StatelessWidget {
  const _TimelineShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: 5,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Row(
          children: [
            const SizedBox(width: 48, child: AppShimmer(width: 32, height: 32, borderRadius: 16)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  AppShimmer(width: 140, height: 14),
                  SizedBox(height: 6),
                  AppShimmer(width: double.infinity, height: 12),
                  SizedBox(height: 4),
                  AppShimmer(width: 60, height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String bookingId;
  final WidgetRef ref;

  const _ErrorView({required this.bookingId, required this.ref});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: context.textMuted),
            const SizedBox(height: AppSpacing.md),
            Text(
              strings['failed_to_load_timeline'] ?? 'Failed to load timeline',
              style: AppTextStyles.titleMedium(color: context.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              text: strings['retry'] ?? 'Retry',
              onPressed: () => ref.invalidate(bookingTimelineProvider(bookingId)),
            ),
          ],
        ),
      ),
    );
  }
}
