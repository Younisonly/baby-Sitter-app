import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_shadows.dart';

class StepBank extends StatefulWidget {
  final Map<String, String> strings;
  final Map<String, dynamic> data;
  final void Function(Map<String, dynamic>) onChanged;
  const StepBank({
    super.key,
    required this.strings,
    required this.data,
    required this.onChanged,
  });

  @override
  State<StepBank> createState() => _StepBankState();
}

class _StepBankState extends State<StepBank> {
  late TextEditingController _accountHolderCtrl;
  late TextEditingController _bankNameCtrl;
  late TextEditingController _ibanCtrl;
  late TextEditingController _accountNumberCtrl;
  bool _touched = false;

  @override
  void initState() {
    super.initState();
    final bank = widget.data['bank_account'] is Map
        ? (widget.data['bank_account'] as Map<String, dynamic>)
        : (widget.data['bank_account'] is String
            ? _parseBankString(widget.data['bank_account'] as String)
            : <String, dynamic>{});
    _accountHolderCtrl = TextEditingController(text: bank['account_holder'] as String? ?? '');
    _bankNameCtrl = TextEditingController(text: bank['bank_name'] as String? ?? '');
    _ibanCtrl = TextEditingController(text: bank['iban'] as String? ?? '');
    _accountNumberCtrl = TextEditingController(text: bank['account_number'] as String? ?? '');
  }

  Map<String, dynamic> _parseBankString(String s) {
    try {
      final d = jsonDecode(s);
      if (d is Map) return d.cast<String, dynamic>();
    } catch (_) {}
    return {};
  }

  @override
  void dispose() {
    _accountHolderCtrl.dispose();
    _bankNameCtrl.dispose();
    _ibanCtrl.dispose();
    _accountNumberCtrl.dispose();
    super.dispose();
  }

  void _emit() {
    setState(() => _touched = true);
    final bank = {
      'account_holder': _accountHolderCtrl.text.trim(),
      'bank_name': _bankNameCtrl.text.trim(),
      'iban': _ibanCtrl.text.trim().toUpperCase(),
      'account_number': _accountNumberCtrl.text.trim(),
    };
    final hasData = bank['account_holder']!.isNotEmpty ||
        bank['bank_name']!.isNotEmpty ||
        bank['iban']!.isNotEmpty;
    widget.onChanged({'bank_account': hasData ? bank : null});
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final cs = Theme.of(context).colorScheme;
    final hasErrors = _touched && _hasErrors();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _SectionHeader(
          icon: Icons.account_balance_outlined,
          title: s['bank_info'] ?? 'Bank Account',
          subtitle: s['bank_subtitle'] ?? 'Where should we send your earnings?',
        ),
        const SizedBox(height: AppSpacing.xl),

        if (hasErrors)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: BoxDecoration(
              color: cs.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: cs.error.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, size: 20, color: cs.error),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    s['bank_validation_hint'] ?? 'Complete the required fields to continue',
                    style: TextStyle(fontSize: 12, color: cs.error, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

        _FieldCard(
          icon: Icons.person_rounded,
          label: s['account_holder'] ?? 'Account Holder',
          hint: s['account_holder_hint'] ?? 'Full name as it appears on the account',
          controller: _accountHolderCtrl,
          onChanged: _emit,
          error: _touched && _accountHolderCtrl.text.trim().isEmpty,
        ),
        const SizedBox(height: AppSpacing.md),

        _FieldCard(
          icon: Icons.business_rounded,
          label: s['bank_name'] ?? 'Bank Name',
          hint: s['bank_name_hint'] ?? 'e.g. National Bank',
          controller: _bankNameCtrl,
          onChanged: _emit,
          error: _touched && _bankNameCtrl.text.trim().isEmpty,
        ),
        const SizedBox(height: AppSpacing.md),

        _FieldCard(
          icon: Icons.numbers_rounded,
          label: s['iban_label'] ?? 'IBAN',
          hint: s['iban_hint'] ?? 'International Bank Account Number',
          controller: _ibanCtrl,
          onChanged: _emit,
          textCapitalization: TextCapitalization.characters,
          error: _touched && !_isIbanValid(_ibanCtrl.text.trim()),
        ),
        const SizedBox(height: AppSpacing.md),

        _FieldCard(
          icon: Icons.pin_rounded,
          label: s['account_number'] ?? 'Bank Account Number',
          hint: s['account_number_hint'] ?? 'e.g. SA03 8000 0000 6080 1016 7519',
          controller: _accountNumberCtrl,
          onChanged: _emit,
        ),
        const SizedBox(height: AppSpacing.xl),

        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_rounded, size: 20, color: cs.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      s['bank_encrypted_note'] ?? 'Your bank details are encrypted and used only for earnings transfers. We never share them with third parties.',
                      style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6), height: 1.4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 20, color: cs.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      s['accuracy_note'] ?? 'Please ensure all bank details are accurate. Incorrect information may delay or prevent payments.',
                      style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6), height: 1.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  bool _hasErrors() {
    final hasBank = _accountHolderCtrl.text.trim().isNotEmpty ||
        _bankNameCtrl.text.trim().isNotEmpty ||
        _ibanCtrl.text.trim().isNotEmpty;
    if (!hasBank) return false;
    return _accountHolderCtrl.text.trim().isEmpty ||
        _bankNameCtrl.text.trim().isEmpty ||
        !_isIbanValid(_ibanCtrl.text.trim());
  }

  bool _isIbanValid(String iban) {
    if (iban.isEmpty) return true;
    if (iban.length < 15 || iban.length > 34) return false;
    return RegExp(r'^[A-Z0-9]+$').hasMatch(iban);
  }
}

class _FieldCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final TextCapitalization textCapitalization;
  final bool error;

  const _FieldCard({
    required this.icon,
    required this.label,
    required this.hint,
    required this.controller,
    required this.onChanged,
    this.textCapitalization = TextCapitalization.none,
    this.error = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: error ? cs.error : cs.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBox(icon: icon, color: error ? cs.error : cs.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _FieldLabel(label),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: controller,
            textCapitalization: textCapitalization,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.35)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              filled: true,
              fillColor: error
                  ? cs.error.withValues(alpha: 0.05)
                  : cs.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
            style: TextStyle(fontSize: 15, color: cs.onSurface),
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

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface));
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
