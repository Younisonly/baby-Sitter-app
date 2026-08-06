import 'package:flutter/material.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/localization/app_localization.dart';

class StepReview extends StatelessWidget {
  final Map<String, String> strings;
  final Map<String, dynamic> data;

  const StepReview({
    super.key,
    required this.strings,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.reviews_rounded,
            title: strings['review_submit'] ?? 'Review & Submit',
            subtitle: strings['review_submit_subtitle'] ?? 'Please review your information before submitting',
          ),
          const SizedBox(height: AppSpacing.xl),
          _ReviewSection(
            icon: Icons.person_outline_rounded,
            title: strings['about_you'] ?? 'About You',
            cs: cs,
            children: [
              _InfoRow(label: strings['gender'] ?? 'Gender', value: _val(data['gender'])),
              _InfoRow(label: strings['age'] ?? 'Age', value: data['age'] != null ? '${data['age']}' : '--'),
              _InfoRow(label: strings['languages'] ?? 'Languages', value: _listVal(data['languages'])),
              _InfoRow(label: strings['years_experience'] ?? 'Experience', value: '${data['years_experience'] ?? 0} years'),
              _InfoRow(label: strings['bio'] ?? 'Bio', value: _val(data['bio'])),
              _InfoRow(label: strings['city'] ?? 'Location', value: _val(data['location'])),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _ReviewSection(
            icon: Icons.auto_stories_outlined,
            title: strings['experience_certificates'] ?? 'Certificates',
            cs: cs,
            children: [
              _InfoRow(
                label: strings['certificates'] ?? 'Certificates',
                value: _certsSummary(data['certificates']),
              ),
              if (data['description'] != null && (data['description'] as String).isNotEmpty)
                _InfoRow(label: strings['description'] ?? 'Description', value: _val(data['description'])),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _ReviewSection(
            icon: Icons.attach_money_rounded,
            title: strings['rates_subtitle'] ?? 'Pricing',
            cs: cs,
            children: [
              _InfoRow(label: strings['hourly_rate'] ?? 'Hourly Rate', value: '\$${(data['hourly_rate'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
              _InfoRow(label: strings['included_children'] ?? 'Included Children', value: '${data['included_children'] ?? 1}'),
              if ((data['extra_child_fee'] as num?)?.toDouble() != 0)
                _InfoRow(label: strings['extra_child_fee'] ?? 'Extra Child Fee', value: '\$${(data['extra_child_fee'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
              if (data['absolute_max_children'] != null)
                _InfoRow(label: strings['absolute_max_children'] ?? 'Max Children', value: '${data['absolute_max_children']}'),
              if ((data['special_needs_rate'] as num?)?.toDouble() != 0)
                _InfoRow(label: strings['special_needs_rate'] ?? 'Special Needs Rate', value: '\$${(data['special_needs_rate'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _ReviewSection(
            icon: Icons.schedule_rounded,
            title: strings['availability'] ?? 'Availability',
            cs: cs,
            children: [
              if (data['availability'] is List && (data['availability'] as List).isNotEmpty)
                ...(data['availability'] as List).map((slot) {
                  final map = slot is Map<String, dynamic> ? slot : <String, dynamic>{};
                  final day = map['day'] as String? ?? '';
                  final start = map['start_time'] as String? ?? '';
                  final end = map['end_time'] as String? ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('$day: $start - $end',
                        style: TextStyle(fontSize: 13, color: cs.onSurface)),
                  );
                })
              else
                _InfoRow(label: '', value: strings['not_set'] ?? 'Not set'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _ReviewSection(
            icon: Icons.account_balance_rounded,
            title: strings['bank_info'] ?? 'Bank Account',
            cs: cs,
            children: [
              if (data['bank_account'] is Map && (data['bank_account'] as Map).isNotEmpty)
                _bankDetails(data['bank_account'] as Map<String, dynamic>?, cs)
              else
                _InfoRow(label: '', value: strings['not_set'] ?? 'Not set'),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _bankDetails(Map<String, dynamic>? bank, ColorScheme cs) {
    if (bank == null || bank.isEmpty) {
      return _InfoRow(label: '', value: strings['not_set'] ?? 'Not set');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (bank['account_holder'] != null && (bank['account_holder'] as String).isNotEmpty)
          _InfoRow(label: strings['account_holder'] ?? 'Account Holder', value: bank['account_holder'] as String),
        if (bank['bank_name'] != null && (bank['bank_name'] as String).isNotEmpty)
          _InfoRow(label: strings['bank_name'] ?? 'Bank Name', value: bank['bank_name'] as String),
        if (bank['iban'] != null && (bank['iban'] as String).isNotEmpty)
          _InfoRow(label: strings[AppLocalization.iban_label] ?? 'IBAN', value: bank['iban'] as String),
        if (bank['account_number'] != null && (bank['account_number'] as String).isNotEmpty)
          _InfoRow(label: strings['account_number'] ?? 'Bank Account', value: bank['account_number'] as String),
      ],
    );
  }

  String _val(dynamic v) => v?.toString() ?? '--';
  String _listVal(dynamic v) {
    if (v is List) return v.join(', ');
    return v?.toString() ?? '--';
  }
  String _certsSummary(dynamic certs) {
    if (certs is! List || certs.isEmpty) return strings['no_certificates_added'] ?? 'None';
    return certs.map((c) {
      if (c is Map) return c['name']?.toString() ?? '';
      return c.toString();
    }).join(', ');
  }
}

class _ReviewSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final ColorScheme cs;
  final List<Widget> children;

  const _ReviewSection({
    required this.icon,
    required this.title,
    required this.cs,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Icon(icon, size: 18, color: cs.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (label.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(value, style: TextStyle(fontSize: 13, color: cs.onSurface)),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 13, color: cs.onSurface), softWrap: true),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SectionHeader({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [cs.primary, cs.primary.withValues(alpha: 0.8)]),
            borderRadius: BorderRadius.circular(AppRadius.button),
            boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Icon(icon, color: cs.onPrimary, size: 24),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.55))),
            ],
          ),
        ),
      ],
    );
  }
}
