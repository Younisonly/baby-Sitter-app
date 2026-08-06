import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_shadows.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/theme_colors.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/features/booking/data/booking_helpers.dart';
import 'package:babysitter/features/booking/data/booking_provider.dart';
import 'package:babysitter/shared/models/booking_model.dart';
import 'package:babysitter/core/utils/time_formatter.dart';
import 'package:babysitter/shared/widgets/widgets.dart';

class InvoiceScreen extends ConsumerWidget {
  final String bookingId;

  const InvoiceScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings =
        AppLocalization.get(ref.watch(languageProvider).code);
    final bookingAsync = ref.watch(bookingDetailProvider(bookingId));

    return Scaffold(
      appBar: AppAppBar(
        title: strings[AppLocalization.invoice] ?? 'Invoice',
        showBackButton: true,
      ),
      body: bookingAsync.when(
        data: (booking) => _InvoiceBody(booking: booking),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => AppErrorState(
          title: strings['load_error_title'] ?? 'Something went wrong',
          message: strings['failed_load_invoice'] ?? 'Failed to load invoice',
          onRetry: () => ref.invalidate(bookingDetailProvider(bookingId)),
        ),
      ),
    );
  }
}

class _InvoiceBody extends StatelessWidget {
  final BookingModel booking;

  const _InvoiceBody({required this.booking});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final strings = AppLocalization.get(locale);
    final statusColor = BookingHelpers.statusColor(booking.status);
    final currency = strings['sar'] ?? 'SAR';
    final invoiceNum = 'INV-${booking.id}';
    final dateStr = DateFormat('MMM d, yyyy').format(booking.date);
    final startTime = booking.startTime;
    final endTime = booking.endTime;
    final timeRange = TimeFormatter.formatTimeRange(startTime, endTime, locale);

    final invoiceText = '''
${strings['invoice_title'] ?? 'INVOICE'}
======
${strings['booking_reference'] ?? 'Invoice #'}: $invoiceNum
${strings['date'] ?? 'Date'}: $dateStr
${strings['status'] ?? 'Status'}: ${booking.status.name.toUpperCase()}

${strings['invoice_from'] ?? 'FROM'}:
${booking.sitter?.name ?? strings['sitter_label'] ?? 'Sitter'}

${strings['invoice_to'] ?? 'TO'}:
${booking.customer?.name ?? strings['parent'] ?? 'Customer'}

${strings['invoice_service_details'] ?? 'SERVICE DETAILS'}:
${strings['date'] ?? 'Date'}: $dateStr
${strings['time'] ?? 'Time'}: $timeRange
${strings['duration'] ?? 'Duration'}: ${booking.duration} ${strings['hr_abbreviation'] ?? 'hr'}
${strings['children'] ?? 'Children'}: ${booking.childrenCount ?? 1}
${strings['address'] ?? 'Location'}: ${booking.address ?? 'N/A'}

${strings['invoice_pricing'] ?? 'PRICING'}:
${strings['base_rate'] ?? 'Base Rate'}: $currency ${booking.totalAmount.toStringAsFixed(2)}
${strings['total'] ?? 'Total'}: $currency ${booking.totalAmount.toStringAsFixed(2)}

${strings['invoice_thanks'] ?? 'Thank you for choosing our service!'}
''';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: context.dividerColor.withValues(alpha: 0.3),
              ),
              boxShadow: AppShadows.of(context),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                                child: const Icon(
                                  Icons.receipt_long_rounded,
                                  size: 24,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    invoiceNum,
                                    style: AppTextStyles.titleLarge(
                                      weight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    dateStr,
                                    style: AppTextStyles.bodySmall(
                                      color: context.textMutedColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        strings[BookingHelpers.statusLocalizationKey(booking.status)] ?? booking.status.name,
                        style: AppTextStyles.labelSmall(
                          color: statusColor,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: AppSpacing.xl),
                _Section(
                  title: strings['from'] ?? 'From',
                  children: [
                    _InfoRow(
                      icon: Icons.person_rounded,
                      label: booking.sitter?.name ?? 'Sitter',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _Section(
                  title: strings['to'] ?? 'To',
                  children: [
                    _InfoRow(
                      icon: Icons.person_rounded,
                      label: booking.customer?.name ?? 'Customer',
                    ),
                  ],
                ),
                const Divider(height: AppSpacing.xl),
                _Section(
                  title: strings['service_details'] ?? 'Service Details',
                  children: [
                    _InfoRow(
                      icon: Icons.calendar_today_rounded,
                      label: dateStr,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _InfoRow(
                      icon: Icons.access_time_rounded,
                      label: '$timeRange (${booking.duration} ${strings['hr_abbreviation'] ?? 'hr'})',
                    ),
                    if (booking.address != null && booking.address!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      _InfoRow(
                        icon: Icons.location_on_rounded,
                        label: booking.address!,
                      ),
                    ],
                    if (booking.childrenCount != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      _InfoRow(
                        icon: Icons.child_care_rounded,
                        label: '${booking.childrenCount} ${(booking.childrenCount ?? 1) == 1 ? (strings['child_label'] ?? 'child') : (strings['children_label'] ?? 'children')}',
                      ),
                    ],
                  ],
                ),
                const Divider(height: AppSpacing.xl),
                _Section(
                  title: strings['pricing'] ?? 'Pricing',
                  children: [
                    _PricingRow(
                      label: strings['base_rate'] ?? 'Base Rate',
                      value: '$currency ${booking.totalAmount.toStringAsFixed(2)}',
                    ),
                    const Divider(height: AppSpacing.md),
                    _PricingRow(
                      label: strings['total'] ?? 'Total',
                      value: '$currency ${booking.totalAmount.toStringAsFixed(0)}',
                      isTotal: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: strings['copy_invoice'] ?? 'Copy Invoice',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: invoiceText));
                AppSnackbar.success(
                  context,
                  strings['invoice_copied'] ?? 'Invoice copied to clipboard.',
                );
              },
              variant: AppButtonVariant.filled,
              prefixIcon: const Icon(Icons.copy_rounded, size: 18),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: strings['share'] ?? 'Share',
              onPressed: () {
                Share.share(invoiceText, subject: invoiceNum);
              },
              variant: AppButtonVariant.outlined,
              prefixIcon: const Icon(Icons.share_rounded, size: 18),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.labelMedium(
            weight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...children,
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium(),
          ),
        ),
      ],
    );
  }
}

class _PricingRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _PricingRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppTextStyles.titleMedium(weight: FontWeight.bold)
              : AppTextStyles.bodyMedium(),
        ),
        Text(
          value,
          style: isTotal
              ? AppTextStyles.titleLarge(
                  weight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                )
              : AppTextStyles.bodyMedium(),
        ),
      ],
    );
  }
}
