import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';

class StepPricing extends StatefulWidget {
  final Map<String, String> strings;
  final Map<String, dynamic> data;
  final void Function(Map<String, dynamic>) onChanged;

  const StepPricing({
    super.key,
    required this.strings,
    required this.data,
    required this.onChanged,
  });

  @override
  State<StepPricing> createState() => _StepPricingState();
}

class _StepPricingState extends State<StepPricing> {
  late TextEditingController _hourlyCtrl;
  late TextEditingController _extraCtrl;
  late TextEditingController _specialCtrl;
  int _includedChildren = 1;
  late TextEditingController _maxChildrenCtrl;

  @override
  void initState() {
    super.initState();
    _hourlyCtrl = TextEditingController(
      text: (widget.data['hourly_rate'] as num?)?.toStringAsFixed(0) ?? '',
    );
    _extraCtrl = TextEditingController(
      text: (widget.data['extra_child_fee'] as num?)?.toStringAsFixed(0) ?? '',
    );
    _specialCtrl = TextEditingController(
      text: (widget.data['special_needs_rate'] as num?)?.toStringAsFixed(0) ?? '',
    );
    _includedChildren = widget.data['included_children'] as int? ?? 1;
    _maxChildrenCtrl = TextEditingController(
      text: widget.data['absolute_max_children']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _hourlyCtrl.dispose();
    _extraCtrl.dispose();
    _specialCtrl.dispose();
    _maxChildrenCtrl.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged({
      'hourly_rate': _hourlyCtrl.text.trim().isNotEmpty ? int.tryParse(_hourlyCtrl.text.trim()) ?? 0 : 0,
      'included_children': _includedChildren,
      'extra_child_fee': _extraCtrl.text.trim().isNotEmpty ? int.tryParse(_extraCtrl.text.trim()) ?? 0 : 0,
      'special_needs_rate': _specialCtrl.text.trim().isNotEmpty ? int.tryParse(_specialCtrl.text.trim()) ?? 0 : 0,
      'absolute_max_children': _maxChildrenCtrl.text.trim().isNotEmpty ? int.tryParse(_maxChildrenCtrl.text.trim()) : null,
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _SectionHeader(
          icon: Icons.monetization_on_outlined,
          title: s['step_reg_pricing'] ?? 'Pricing',
          subtitle: s['rates_subtitle'] ?? 'Set your rates and children limits',
        ),
        SizedBox(height: AppSpacing.xl),

        _PricingCard(
          icon: Icons.timer_outlined,
          label: s['hourly_rate'] ?? 'Hourly Rate',
          subtitle: s['rate_hint'] ?? 'e.g. 15.00',
          controller: _hourlyCtrl,
          onChanged: _emit,
          cs: cs,
        ),
        SizedBox(height: AppSpacing.md),

        _ChildrenCard(
          value: _includedChildren,
          onChanged: (v) {
            setState(() => _includedChildren = v);
            _emit();
          },
          strings: s,
          cs: cs,
        ),
        SizedBox(height: AppSpacing.md),

        _PricingCard(
          icon: Icons.people_outline_rounded,
          label: s['extra_child_fee'] ?? 'Extra Child Fee',
          subtitle: s['per_hour'] ?? '/hr',
          controller: _extraCtrl,
          onChanged: _emit,
          cs: cs,
        ),
        SizedBox(height: AppSpacing.md),

        _TextFieldCard(
          icon: Icons.numbers_rounded,
          label: s['absolute_max_children'] ?? 'Maximum Total Children',
          subtitle: s['max_hint'] ?? 'Leave empty for no hard limit',
          controller: _maxChildrenCtrl,
          onChanged: _emit,
          cs: cs,
        ),
        SizedBox(height: AppSpacing.md),

        _PricingCard(
          icon: Icons.healing_outlined,
          label: s['special_needs_rate'] ?? 'Special Needs Rate',
          subtitle: s['per_hour'] ?? '/hr',
          controller: _specialCtrl,
          onChanged: _emit,
          cs: cs,
        ),
        SizedBox(height: AppSpacing.md),

        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: cs.primary),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Platform fee: 10%. You keep 90% of all booking earnings.',
                  style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6), height: 1.5),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _ChildrenCard extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final Map<String, String> strings;
  final ColorScheme cs;

  const _ChildrenCard({
    required this.value,
    required this.onChanged,
    required this.strings,
    required this.cs,
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
              _IconBox(icon: Icons.child_care_rounded, color: cs.primary),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings['included_children'] ?? 'Children Included in Base Rate',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                    ),
                    SizedBox(height: 2),
                    Text(
                      strings['up_to_kids']?.replaceAll('{count}', value.toString()) ?? 'Up to $value kids',
                      style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _RoundButton(
                icon: Icons.remove_rounded,
                onTap: value > 1 ? () => onChanged(value - 1) : null,
                cs: cs,
              ),
              SizedBox(width: AppSpacing.md),
              Text(
                '$value',
                style: AppTextStyles.headlineMedium(weight: FontWeight.w700),
              ),
              SizedBox(width: AppSpacing.md),
              _RoundButton(
                icon: Icons.add_rounded,
                onTap: value < 20 ? () => onChanged(value + 1) : null,
                cs: cs,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PricingCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final ColorScheme cs;

  const _PricingCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.controller,
    required this.onChanged,
    required this.cs,
  });

  @override
  State<_PricingCard> createState() => _PricingCardState();
}

class _PricingCardState extends State<_PricingCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: widget.cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: widget.cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBox(icon: widget.icon, color: widget.cs.primary),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: widget.cs.onSurface),
                    ),
                    if (widget.subtitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          widget.subtitle,
                          style: TextStyle(fontSize: 12, color: widget.cs.onSurface.withValues(alpha: 0.5)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          TextField(
            controller: widget.controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: widget.subtitle,
              prefixText: '﷼ ',
              hintStyle: TextStyle(fontSize: 14, color: widget.cs.onSurface.withValues(alpha: 0.35)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              filled: true,
              fillColor: widget.cs.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: widget.cs.onSurface),
            onChanged: (_) => widget.onChanged(),
          ),
        ],
      ),
    );
  }
}

class _TextFieldCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final ColorScheme cs;

  const _TextFieldCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.controller,
    required this.onChanged,
    required this.cs,
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
              _IconBox(icon: icon, color: cs.primary),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
                    if (subtitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(subtitle, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: subtitle,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              filled: true,
              fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface),
            onChanged: (_) => onChanged(),
          ),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IconBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final ColorScheme cs;
  const _RoundButton({required this.icon, this.onTap, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap != null ? cs.primary.withValues(alpha: 0.1) : cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.full),
        onTap: onTap,
        child: Container(
          width: 36, height: 36,
          alignment: Alignment.center,
          child: Icon(icon, size: 22, color: onTap != null ? cs.primary : cs.onSurface.withValues(alpha: 0.2)),
        ),
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
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface)),
              SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.55))),
            ],
          ),
        ),
      ],
    );
  }
}