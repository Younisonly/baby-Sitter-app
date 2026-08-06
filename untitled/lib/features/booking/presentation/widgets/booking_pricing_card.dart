import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_config.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/extensions.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/utils/time_formatter.dart';
import 'package:babysitter/features/booking/presentation/helpers/booking_helpers.dart';
import 'package:babysitter/shared/models/user_model.dart';

class BookingPricingCard extends StatelessWidget {
  final UserModel sitter;
  final DateTime selectedDate;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final int childrenCount;
  final int specialNeedsCount;
  final int scheduleEventsCount;
  final Map<String, String> strings;
  final Set<String> selectedDateKeys;
  final Map<String, PerDateTimeOverride> perDateTimes;

  const BookingPricingCard({
    super.key,
    required this.sitter,
    required this.selectedDate,
    required this.startTime,
    required this.endTime,
    required this.childrenCount,
    required this.specialNeedsCount,
    required this.scheduleEventsCount,
    required this.strings,
    this.selectedDateKeys = const {},
    this.perDateTimes = const {},
  });

  void _showPricingInfo(BuildContext context, Map<String, String> strings) {
    final profile = sitter.babysitterProfile;
    final included = profile?.includedChildren ?? 1;
    final hourly = (profile?.hourlyRate ?? 0).toDouble();
    final extraFee = (profile?.extraChildFee ?? 0).toDouble();
    final specialRate = (profile?.specialNeedsRate ?? 0).toDouble();

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) {
        final bottomStrings = AppLocalization.get(
          Localizations.localeOf(ctx).languageCode,
        );
        final currencySymbol = bottomStrings['sar'] ?? '﷼';
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: AppSpacing.lg),
                Text(bottomStrings['pricing_info_title'] ?? 'How Pricing Works',
                    style: AppTextStyles.titleLarge(weight: FontWeight.w700)),
                SizedBox(height: AppSpacing.sm),
                Text(
                  (bottomStrings['pricing_info_base_rate'] ?? 'The base rate ({currency}{rate}/hr) covers up to {count} child{plural}. Additional children beyond are charged at {currency}{extraFee}/hr each.')
                      .replaceAll('{currency}', currencySymbol)
                      .replaceAll('{rate}', hourly.toStringAsFixed(0))
                      .replaceAll('{count}', included.toString())
                      .replaceAll('{plural}', included == 1 ? '' : 'ren')
                      .replaceAll('{extraFee}', extraFee.toStringAsFixed(0)),
                  style: AppTextStyles.bodyMedium(color: ctx.textSecondary),
                ),
                if (specialRate > 0) ...[
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    (bottomStrings['pricing_info_special_needs'] ?? 'Children with special needs are charged at {currency}{rate}/hr and are not counted as additional children.')
                        .replaceAll('{currency}', currencySymbol)
                        .replaceAll('{rate}', specialRate.toStringAsFixed(0)),
                    style: AppTextStyles.bodyMedium(color: ctx.textSecondary),
                  ),
                ],
                SizedBox(height: AppSpacing.lg),
                Divider(height: 1, color: ctx.dividerColor),
                SizedBox(height: AppSpacing.md),
                Text(bottomStrings['policies_title'] ?? 'Policies',
                    style: AppTextStyles.titleMedium(weight: FontWeight.w600)),
                SizedBox(height: AppSpacing.sm),
                _PolicyLink(
                  icon: Icons.description_outlined,
                  label: bottomStrings[AppLocalization.terms_of_service] ?? 'Terms of Service',
                  url: AppConfig.termsUrl,
                ),
                SizedBox(height: AppSpacing.sm),
                _PolicyLink(
                  icon: Icons.privacy_tip_outlined,
                  label: bottomStrings[AppLocalization.privacy_policy_title] ?? 'Privacy Policy',
                  url: AppConfig.privacyUrl,
                ),
                SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    if (startTime == null || endTime == null) return const SizedBox.shrink();

    final isMultiDay = selectedDateKeys.length > 1;

    if (isMultiDay) {
      return _buildMultiDay(context, locale);
    }

    return _buildSingleDay(context, locale);
  }

  Widget _buildSingleDay(BuildContext context, String locale) {
    if (startTime == null || endTime == null) return const SizedBox.shrink();
    final duration = durationHours(startTime, endTime);
    if (duration < 1) return const SizedBox.shrink();

    final profile = sitter.babysitterProfile;
    final hourlyRate = (profile?.hourlyRate ?? 0).toDouble();
    final includedChildren = profile?.includedChildren ?? 1;
    final extraChildFee = (profile?.extraChildFee ?? 0).toDouble();
    final specialNeedsRate = (profile?.specialNeedsRate ?? 0).toDouble();

    final regularChildren = (childrenCount - specialNeedsCount).clamp(0, 999);
    final extraRegularChildren = (regularChildren - includedChildren).clamp(0, 999);
    final baseCost = duration.toDouble() * hourlyRate;
    final extraCost = duration.toDouble() * extraRegularChildren * extraChildFee;
    final specialCost =
        duration.toDouble() * specialNeedsCount * specialNeedsRate;
    final total = baseCost + extraCost + specialCost;
    final hrAbbr = strings['hr_abbreviation'] ?? 'hr';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
              color: AppColors.black.withValues(alpha: 0.08),
              blurRadius: 3,
              offset: const Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_rounded,
                  size: 18.sp, color: AppColors.primary),
              SizedBox(width: AppSpacing.sm),
              Text(strings['invoice'] ?? 'Invoice',
                  style: AppTextStyles.titleMedium()),
              Spacer(),
              GestureDetector(
                onTap: () => _showPricingInfo(context, strings),
                child: Container(
                  padding: EdgeInsets.all(AppSpacing.xxs),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Icon(Icons.info_outline_rounded,
                      size: 16.sp, color: AppColors.primary),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          _PricingRow(
              icon: Icons.calendar_today_rounded,
              label: strings['date'] ?? 'Date',
              value: DateFormat('MMM d, yyyy', locale).format(selectedDate)),
          SizedBox(height: AppSpacing.xs),
          _PricingRow(
              icon: Icons.access_time_rounded,
              label: strings['time'] ?? 'Time',
              value:
                  '${TimeFormatter.formatTimeOfDay(startTime!, locale)} - ${TimeFormatter.formatTimeOfDay(endTime!, locale)}'),
          SizedBox(height: AppSpacing.xs),
          _PricingRow(
              icon: Icons.timer_outlined,
              label: strings['duration'] ?? 'Duration',
              value: '$duration $hrAbbr'),
          SizedBox(height: AppSpacing.xs),
          _PricingRow(
              icon: Icons.people_outline_rounded,
              label: strings['children'] ?? 'Children',
              value:
                  '$childrenCount${specialNeedsCount > 0 ? ' ($specialNeedsCount ${strings['special_care'] ?? 'special care'})' : ''}'),
          if (scheduleEventsCount > 0) ...[
            SizedBox(height: AppSpacing.xs),
            _PricingRow(
                icon: Icons.event_note_rounded,
                label: strings['events'] ?? 'Events',
                value: '$scheduleEventsCount ${strings['scheduled'] ?? 'scheduled'}'),
          ],
          Divider(height: AppSpacing.lg, color: context.dividerColor),
          _PricingRow(
              icon: Icons.attach_money_rounded,
              label:
                  '﷼${hourlyRate.toStringAsFixed(0)}/$hrAbbr × $duration $hrAbbr',
              value: '﷼${baseCost.toStringAsFixed(2)}'),
          if (extraRegularChildren > 0) ...[
            SizedBox(height: AppSpacing.xxs),
            _PricingRow(
                icon: Icons.add_circle_outline_rounded,
                label:
                    '$extraRegularChildren ${strings['additional'] ?? 'additional'} × ﷼${extraChildFee.toStringAsFixed(0)}/$hrAbbr',
                value: '﷼${extraCost.toStringAsFixed(2)}',
                color: AppColors.warning),
          ],
          if (specialNeedsCount > 0) ...[
            SizedBox(height: AppSpacing.xxs),
            _PricingRow(
                icon: Icons.medical_services_outlined,
                label:
                    '$specialNeedsCount ${strings['special_needs_rate_label'] ?? 'special needs'} × ﷼${specialNeedsRate.toStringAsFixed(0)}/$hrAbbr',
                value: '﷼${specialCost.toStringAsFixed(2)}',
                color: AppColors.error),
          ],
          Divider(height: AppSpacing.lg, color: context.dividerColor),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(strings['total'] ?? 'Total',
                  style:
                      AppTextStyles.titleMedium(weight: FontWeight.bold)),
              TweenAnimationBuilder<double>(
                duration: 400.ms,
                tween: Tween<double>(begin: 0.0, end: total),
                builder: (context, value, _) => Text(
                  '﷼${value.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 450.ms);
  }

  Widget _buildMultiDay(BuildContext context, String locale) {
    final loc = AppLocalization.get(locale);
    final profile = sitter.babysitterProfile;
    final hourlyRate = (profile?.hourlyRate ?? 0).toDouble();
    final includedChildren = profile?.includedChildren ?? 1;
    final extraChildFee = (profile?.extraChildFee ?? 0).toDouble();
    final specialNeedsRate = (profile?.specialNeedsRate ?? 0).toDouble();

    final regularChildren = (childrenCount - specialNeedsCount).clamp(0, 999);
    final extraRegularChildren = (regularChildren - includedChildren).clamp(0, 999);

    final sortedKeys = selectedDateKeys.toList()..sort();

    double accumulatedTotal = 0;

    final dayRows = <Widget>[];
    for (int i = 0; i < sortedKeys.length; i++) {
      final key = sortedKeys[i];
      final override = perDateTimes[key];
      final dayStartTime = override?.startTime ?? startTime!;
      final dayEndTime = override?.endTime ?? endTime!;

      final dayDuration = durationHours(dayStartTime, dayEndTime);
      if (dayDuration < 1) continue;

      final date = DateTime.parse(key);
      final baseCost = dayDuration.toDouble() * hourlyRate;
      final extraCost = dayDuration.toDouble() * extraRegularChildren * extraChildFee;
      final specialCost = dayDuration.toDouble() * specialNeedsCount * specialNeedsRate;
      final subtotal = baseCost + extraCost + specialCost;
      accumulatedTotal += subtotal;

      final dateFormatted = DateFormat('MMM d', locale).format(date);

      dayRows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i < sortedKeys.length - 1 ? AppSpacing.sm : 0),
          child: Row(
            children: [
              Container(
                width: 22.sp,
                alignment: Alignment.centerLeft,
                child: Text(
                  '${loc['day'] ?? 'Day'} ${i + 1}',
                  style: AppTextStyles.bodySmall(
                    weight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.xs),
              Expanded(
                flex: 2,
                child: Text(
                  dateFormatted,
                  style: AppTextStyles.bodySmall(color: context.textMuted),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                '${loc['duration'] ?? 'Duration'}: ${dayDuration}h',
                style: AppTextStyles.bodySmall(color: context.textMuted),
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                '﷼${subtotal.toStringAsFixed(0)}',
                style: AppTextStyles.bodyMedium(
                  weight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (dayRows.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
              color: AppColors.black.withValues(alpha: 0.08),
              blurRadius: 3,
              offset: const Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_rounded,
                  size: 18.sp, color: AppColors.primary),
              SizedBox(width: AppSpacing.sm),
              Text(strings['invoice'] ?? 'Invoice',
                  style: AppTextStyles.titleMedium()),
              const Spacer(),
              GestureDetector(
                onTap: () => _showPricingInfo(context, strings),
                child: Container(
                  padding: EdgeInsets.all(AppSpacing.xxs),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Icon(Icons.info_outline_rounded,
                      size: 16.sp, color: AppColors.primary),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(Icons.receipt_long_rounded,
                  size: 14.sp, color: AppColors.primary),
              SizedBox(width: AppSpacing.xs),
              Text(
                loc['per_day_breakdown'] ?? 'Per-Day Breakdown',
                style: AppTextStyles.titleSmall(
                  weight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          ...dayRows,
          SizedBox(height: AppSpacing.sm),
          Divider(height: 1, color: context.dividerColor),
          SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc['total'] ?? 'Total',
                style: AppTextStyles.titleMedium(weight: FontWeight.bold),
              ),
              TweenAnimationBuilder<double>(
                duration: 400.ms,
                tween: Tween<double>(begin: 0.0, end: accumulatedTotal),
                builder: (context, value, _) => Text(
                  '﷼${value.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 450.ms);
  }
}

class _PricingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _PricingRow({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14.sp, color: color ?? context.textMuted),
        SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(label,
              style: AppTextStyles.bodySmall(color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
        SizedBox(width: AppSpacing.sm),
        Text(value,
            style: AppTextStyles.bodyMedium(
                weight: FontWeight.w500, color: color)),
      ],
    );
  }
}

class _PolicyLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;

  const _PolicyLink({
    required this.icon,
    required this.label,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: AppTextStyles.bodyMedium(
              color: AppColors.primary,
              weight: FontWeight.w600,
            ),
          ),
          Spacer(),
          Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.primary),
        ],
      ),
    );
  }
}
