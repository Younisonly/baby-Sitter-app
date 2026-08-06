import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/extensions.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/features/booking/data/reschedule_request_provider.dart';
import 'package:babysitter/shared/models/reschedule_request_model.dart';

class RescheduleRequestsScreen extends ConsumerStatefulWidget {
  const RescheduleRequestsScreen({super.key});

  @override
  ConsumerState<RescheduleRequestsScreen> createState() => _RescheduleRequestsScreenState();
}

class _RescheduleRequestsScreenState extends ConsumerState<RescheduleRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rescheduleRequestsProvider.notifier).loadRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final state = ref.watch(rescheduleRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings[AppLocalization.reschedule_requests] ?? 'Reschedule Requests'),
      ),
      body: _buildBody(state, strings),
    );
  }

  Widget _buildBody(RescheduleRequestsState state, Map<String, String> strings) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: context.textSecondary.withValues(alpha: 0.4)),
            SizedBox(height: AppSpacing.md),
            Text(state.error ?? (strings['load_error_message'] ?? 'Please check your connection and try again'), style: AppTextStyles.bodyMedium()),
            SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: () => ref.read(rescheduleRequestsProvider.notifier).loadRequests(),
              child: Text(strings[AppLocalization.retry] ?? 'Retry'),
            ),
          ],
        ),
      );
    }

    if (state.requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.date_range, size: 64, color: context.textSecondary.withValues(alpha: 0.3)),
              SizedBox(height: AppSpacing.md),
              Text(
                strings[AppLocalization.no_reschedule_requests] ?? 'No Reschedule Requests',
                style: AppTextStyles.titleLarge(),
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                strings[AppLocalization.no_reschedule_requests_subtitle] ?? 'Reschedule requests for your bookings will appear here.',
                style: AppTextStyles.bodyMedium(color: context.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification && notification.metrics.pixels >= notification.metrics.maxScrollExtent - 200) {
          ref.read(rescheduleRequestsProvider.notifier).loadMore();
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () => ref.read(rescheduleRequestsProvider.notifier).loadRequests(),
        child: ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: state.requests.length + (state.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == state.requests.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              );
            }
            return _RequestCard(
              request: state.requests[index],
              strings: strings,
              onAccept: () => _handleAccept(state.requests[index], strings),
              onReject: () => _handleReject(state.requests[index], strings),
              onCounter: () => _showCounterSheet(state.requests[index], strings),
              onCancel: () => _handleCancel(state.requests[index], strings),
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleAccept(RescheduleRequestModel req, Map<String, String> strings) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings[AppLocalization.accept_request] ?? 'Accept'),
        content: Text(strings[AppLocalization.reschedule_request_accepted] ?? 'Accept this reschedule request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(strings[AppLocalization.cancel] ?? 'Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(strings[AppLocalization.accept_request] ?? 'Accept')),
        ],
      ),
    );
    if (confirmed != true) return;
    final success = await ref.read(rescheduleRequestsProvider.notifier).acceptRequest(req.id);
    if (mounted) {
      if (success) {
        context.showSuccessSnackBar(strings[AppLocalization.reschedule_request_accepted] ?? 'Reschedule request accepted');
      } else {
        context.showErrorSnackBar(strings[AppLocalization.something_went_wrong] ?? 'Something went wrong');
      }
    }
  }

  Future<void> _handleReject(RescheduleRequestModel req, Map<String, String> strings) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings[AppLocalization.reject_request] ?? 'Reject'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(strings[AppLocalization.reschedule_request_rejected] ?? 'Reject this reschedule request?'),
            SizedBox(height: AppSpacing.sm),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: strings[AppLocalization.reason_optional] ?? 'Reason (optional)',
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(strings[AppLocalization.cancel] ?? 'Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(strings[AppLocalization.reject_request] ?? 'Reject')),
        ],
      ),
    );
    if (confirmed != true) return;
    final success = await ref.read(rescheduleRequestsProvider.notifier).rejectRequest(req.id, reason: reasonController.text.trim());
    if (mounted) {
      if (success) {
        context.showSuccessSnackBar(strings[AppLocalization.reschedule_request_rejected] ?? 'Reschedule request rejected');
      } else {
        context.showErrorSnackBar(strings[AppLocalization.something_went_wrong] ?? 'Something went wrong');
      }
    }
  }

  Future<void> _handleCancel(RescheduleRequestModel req, Map<String, String> strings) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings[AppLocalization.cancel_request] ?? 'Cancel Request'),
        content: Text(strings[AppLocalization.reschedule_request_cancelled] ?? 'Cancel this reschedule request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(strings[AppLocalization.cancel] ?? 'Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(strings[AppLocalization.cancel_request] ?? 'Cancel Request')),
        ],
      ),
    );
    if (confirmed != true) return;
    final success = await ref.read(rescheduleRequestsProvider.notifier).cancelRequest(req.id);
    if (mounted) {
      if (success) {
        context.showSuccessSnackBar(strings[AppLocalization.reschedule_request_cancelled] ?? 'Reschedule request cancelled');
      } else {
        context.showErrorSnackBar(strings[AppLocalization.something_went_wrong] ?? 'Something went wrong');
      }
    }
  }

  void _showCounterSheet(RescheduleRequestModel req, Map<String, String> strings) {
    DateTime? selectedDate;
    TimeOfDay? selectedStart;
    TimeOfDay? selectedEnd;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              top: AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings[AppLocalization.counter_offer] ?? 'Counter Offer',
                  style: AppTextStyles.titleLarge(),
                ),
                SizedBox(height: AppSpacing.md),
                ListTile(
                  title: Text(strings[AppLocalization.date] ?? 'Date'),
                  subtitle: Text(selectedDate != null
                      ? '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'
                      : (strings[AppLocalization.tap_to_select] ?? 'Tap to select')),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setSheetState(() => selectedDate = picked);
                  },
                ),
                ListTile(
                  title: Text(strings[AppLocalization.start_time] ?? 'Start Time'),
                  subtitle: Text(selectedStart?.format(context) ?? (strings[AppLocalization.tap_to_select] ?? 'Tap to select')),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final picked = await showTimePicker(context: Navigator.of(context).context, initialTime: TimeOfDay(hour: 9, minute: 0));
                    if (picked != null) setSheetState(() => selectedStart = picked);
                  },
                ),
                ListTile(
                  title: Text(strings[AppLocalization.end_time] ?? 'End Time'),
                  subtitle: Text(selectedEnd?.format(context) ?? (strings[AppLocalization.tap_to_select] ?? 'Tap to select')),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final picked = await showTimePicker(context: Navigator.of(context).context, initialTime: TimeOfDay(hour: 17, minute: 0));
                    if (picked != null) setSheetState(() => selectedEnd = picked);
                  },
                ),
                SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: selectedDate == null || selectedStart == null || selectedEnd == null
                        ? null
                        : () async {
                            final startStr = '${selectedStart!.hour.toString().padLeft(2, '0')}:${selectedStart!.minute.toString().padLeft(2, '0')}';
                            final endStr = '${selectedEnd!.hour.toString().padLeft(2, '0')}:${selectedEnd!.minute.toString().padLeft(2, '0')}';
                            try {
                              await ref.read(rescheduleRequestsProvider.notifier).counterRequest(
                                req.id,
                                counterDate: selectedDate!,
                                counterStartTime: startStr,
                                counterEndTime: endStr,
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                                context.showSuccessSnackBar(strings[AppLocalization.counter_submitted] ?? 'Counter proposal submitted');
                              }
                            } catch (_) {
                              if (ctx.mounted) {
                                context.showErrorSnackBar(strings[AppLocalization.something_went_wrong] ?? 'Something went wrong');
                              }
                            }
                          },
                    child: Text(strings[AppLocalization.counter_offer] ?? 'Submit Counter Offer'),
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final RescheduleRequestModel request;
  final Map<String, String> strings;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onCounter;
  final VoidCallback onCancel;

  const _RequestCard({
    required this.request,
    required this.strings,
    required this.onAccept,
    required this.onReject,
    required this.onCounter,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isOpen = request.status == 'pending' || request.status == 'countered';
    final isOwnRequest = request.requester == null;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(request.status, context).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    _statusLabel(request.status, strings),
                    style: AppTextStyles.labelSmall(color: _statusColor(request.status, context)),
                  ),
                ),
                const Spacer(),
                Text(
                  isOwnRequest
                      ? (strings[AppLocalization.requested_by_you] ?? 'You')
                      : '${strings[AppLocalization.request_by] ?? 'Requested by'}: ${request.requester?['name'] ?? ''}',
                  style: AppTextStyles.bodySmall(color: context.textSecondary),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            _TimeRow(
              icon: Icons.calendar_today,
              label: '${strings[AppLocalization.date] ?? 'Date'}:',
              value: request.proposedDate,
            ),
            SizedBox(height: AppSpacing.xs),
            _TimeRow(
              icon: Icons.access_time,
              label: '${strings[AppLocalization.proposed_time] ?? 'Proposed Time'}:',
              value: '${request.proposedStartTime} - ${request.proposedEndTime}',
            ),
            if (request.reason != null && request.reason!.isNotEmpty) ...[
              SizedBox(height: AppSpacing.xs),
              Text(request.reason!, style: AppTextStyles.bodySmall(color: context.textSecondary)),
            ],
            if (request.status == 'countered') ...[
              SizedBox(height: AppSpacing.sm),
              Divider(),
              SizedBox(height: AppSpacing.xs),
              Text(
                strings[AppLocalization.counter_proposal] ?? 'Counter Proposal',
                style: AppTextStyles.titleSmall(color: AppColors.accent),
              ),
              SizedBox(height: AppSpacing.xs),
              _TimeRow(
                icon: Icons.calendar_today,
                label: '${strings[AppLocalization.date] ?? 'Date'}:',
                value: request.counterDate ?? '',
              ),
              SizedBox(height: AppSpacing.xs),
              _TimeRow(
                icon: Icons.access_time,
                label: '${strings[AppLocalization.proposed_time] ?? 'Time'}:',
                value: '${request.counterStartTime ?? ''} - ${request.counterEndTime ?? ''}',
              ),
              if (request.counterReason != null && request.counterReason!.isNotEmpty) ...[
                SizedBox(height: AppSpacing.xs),
                Text(
                  '${strings[AppLocalization.counter_reason] ?? 'Counter Reason'}: ${request.counterReason}',
                  style: AppTextStyles.bodySmall(color: context.textSecondary),
                ),
              ],
            ],
            if (isOpen) ...[
              SizedBox(height: AppSpacing.sm),
              if (!isOwnRequest)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.close, size: 18),
                        label: Text(strings[AppLocalization.reject_request] ?? 'Reject'),
                        onPressed: onReject,
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.swap_horiz, size: 18),
                        label: Text(strings[AppLocalization.counter_offer] ?? 'Counter'),
                        onPressed: onCounter,
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.check, size: 18),
                        label: Text(strings[AppLocalization.accept_request] ?? 'Accept'),
                        onPressed: onAccept,
                      ),
                    ),
                  ],
                ),
              if (isOwnRequest)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: Text(strings[AppLocalization.cancel_request] ?? 'Cancel Request'),
                    onPressed: onCancel,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status, BuildContext context) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'accepted':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'countered':
        return AppColors.accent;
      case 'cancelled':
        return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
      default:
        return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    }
  }
}

String _statusLabel(String status, Map<String, String> strings) {
    switch (status) {
      case 'pending':
        return strings[AppLocalization.reschedule_status_pending] ?? 'Pending';
      case 'accepted':
        return strings[AppLocalization.reschedule_status_accepted] ?? 'Accepted';
      case 'rejected':
        return strings[AppLocalization.reschedule_status_rejected] ?? 'Rejected';
      case 'countered':
        return strings[AppLocalization.reschedule_status_countered] ?? 'Countered';
      case 'cancelled':
        return strings[AppLocalization.reschedule_status_cancelled] ?? 'Cancelled';
      default:
        return status;
    }
  }

class _TimeRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TimeRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: context.textSecondary),
        SizedBox(width: AppSpacing.xs),
        Text(label, style: AppTextStyles.bodySmall(color: context.textSecondary)),
        SizedBox(width: AppSpacing.xs),
        Text(value, style: AppTextStyles.bodyMedium()),
      ],
    );
  }
}
