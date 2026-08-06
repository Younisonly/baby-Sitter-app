import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/theme_colors.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/network/error_handler.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/features/booking/data/booking_provider.dart';
import 'package:babysitter/features/booking/data/session_provider.dart';
import 'package:babysitter/shared/widgets/widgets.dart';

class QrDisplayScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final bool isEndQr;

  const QrDisplayScreen({
    super.key,
    required this.bookingId,
    this.isEndQr = false,
  });

  @override
  ConsumerState<QrDisplayScreen> createState() => _QrDisplayScreenState();
}

class _QrDisplayScreenState extends ConsumerState<QrDisplayScreen> {
  String? _qrToken;
  bool _isLoading = true;
  bool _isRegenerating = false;
  String? _error;
  bool _isOutOfSchedule = false;
  bool _timeWarningAccepted = false;

  @override
  void initState() {
    super.initState();
    _generateQr();
  }

  Future<void> _generateQr() async {
    setState(() {
      _isLoading = true;
      _isRegenerating = _qrToken != null;
    });

    try {
      final sessionNotifier = ref.read(sessionProvider(widget.bookingId).notifier);
      final qr = widget.isEndQr
          ? await sessionNotifier.generateEndQr()
          : await sessionNotifier.generateStartQr();
      ref.invalidate(bookingDetailProvider(widget.bookingId));
      if (!mounted) return;

      if (qr.isOutOfSchedule && !_timeWarningAccepted) {
        final confirmed = await _showOutOfScheduleDialog();
        if (!mounted) return;
        if (confirmed) {
          _timeWarningAccepted = true;
          _isLoading = false;
          _isRegenerating = false;
          await _generateQr();
          return;
        }
        setState(() {
          _isLoading = false;
          _isRegenerating = false;
        });
        return;
      }

      setState(() {
        _qrToken = qr.qrToken;
        _isLoading = false;
        _isRegenerating = false;
        _error = null;
        _isOutOfSchedule = qr.isOutOfSchedule;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ErrorHandler.handle(e).message;
        _isLoading = false;
        _isRegenerating = false;
      });
    }
  }

  Future<bool> _showOutOfScheduleDialog() async {
    final strings = AppLocalization.get(ref.read(languageProvider).code);
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Row(
          children: [
            const Icon(Icons.access_time_rounded, color: AppColors.warning, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                strings['out_of_schedule_title'] ?? 'Outside Scheduled Time',
                style: AppTextStyles.titleMedium(weight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          strings['out_of_schedule_desc'] ??
              'The current time is outside the scheduled session time. Are you sure you want to generate the QR code and start the session?',
          style: AppTextStyles.bodyMedium(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              strings['cancel'] ?? 'Cancel',
              style: AppTextStyles.bodyMedium(color: context.textSecondaryColor),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(strings['continue_anyway'] ?? 'Continue Anyway'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _copyToClipboard() {
    if (_qrToken == null) return;
    Clipboard.setData(ClipboardData(text: _qrToken!));
    final locale = ref.read(languageProvider).code;
    final s = AppLocalization.get(locale);
    AppSnackbar.success(
      context,
      s['qr_copied'] ?? 'QR code copied to clipboard',
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final isDark = context.isDark;
    final isStart = !widget.isEndQr;
    final title = isStart
        ? (strings['start_qr'] ?? 'Start QR')
        : (strings['end_qr'] ?? 'End QR');

    return Scaffold(
      appBar: AppAppBar(
        title: title,
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            _SitterGuide(isStart: isStart, strings: strings),
            const SizedBox(height: AppSpacing.xl),
            _QrCard(
              isLoading: _isLoading,
              isRegenerating: _isRegenerating,
              qrToken: _qrToken,
              error: _error,
              isDark: isDark,
              strings: strings,
              onCopy: _copyToClipboard,
              onRegenerate: _generateQr,
            ),
            if (_qrToken != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _ExpiryWarning(key: ValueKey(_qrToken), strings: strings),
              if (_isOutOfSchedule) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 16, color: AppColors.warning),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          strings['out_of_schedule_banner'] ??
                              'Started outside scheduled hours',
                          style: AppTextStyles.caption(
                            color: AppColors.warning,
                            weight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _QrCard extends StatelessWidget {
  final bool isLoading;
  final bool isRegenerating;
  final String? qrToken;
  final String? error;
  final bool isDark;
  final Map<String, String> strings;
  final VoidCallback onCopy;
  final VoidCallback onRegenerate;

  const _QrCard({
    required this.isLoading,
    required this.isRegenerating,
    required this.qrToken,
    required this.error,
    required this.isDark,
    required this.strings,
    required this.onCopy,
    required this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading || isRegenerating)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 56),
              child: CircularProgressIndicator(),
            )
          else if (error != null)
            _QrErrorState(
              error: error!,
              strings: strings,
              onRetry: onRegenerate,
            )
          else if (qrToken != null)
            _QrCodeArea(
              qrToken: qrToken!,
              isRegenerating: isRegenerating,
              isDark: isDark,
            ),
          if (qrToken != null) ...[
            const SizedBox(height: AppSpacing.xl),
            _QrTokenText(
              qrToken: qrToken!,
              strings: strings,
              onCopy: onCopy,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: strings['copy_qr'] ?? 'Copy Code',
                    onPressed: onCopy,
                    variant: AppButtonVariant.outlined,
                    prefixIcon: const Icon(Icons.copy_rounded, size: 18),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppButton(
                    text: strings['regenerate'] ?? 'Regenerate',
                    onPressed: isRegenerating ? null : onRegenerate,
                    variant: AppButtonVariant.outlined,
                    prefixIcon: isRegenerating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded, size: 18),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _QrTokenText extends StatelessWidget {
  final String qrToken;
  final Map<String, String> strings;
  final VoidCallback onCopy;

  const _QrTokenText({
    required this.qrToken,
    required this.strings,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.dividerColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.text_fields_rounded,
                  size: 14, color: context.textMutedColor),
              const SizedBox(width: AppSpacing.xs),
              Text(
                strings['qr_token'] ?? 'QR Code Token',
                style: AppTextStyles.labelSmall(color: context.textMutedColor),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SelectableText(
            qrToken,
            style: AppTextStyles.bodySmall(
              color: context.textSecondaryColor,
            ).copyWith(fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}

class _QrCodeArea extends StatelessWidget {
  final String qrToken;
  final bool isRegenerating;
  final bool isDark;

  const _QrCodeArea({
    required this.qrToken,
    required this.isRegenerating,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isRegenerating
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          child: QrImageView(
            data: qrToken,
            version: QrVersions.auto,
            size: 200,
            backgroundColor: AppColors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: AppColors.black,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: AppColors.black,
            ),
          ),
        ),
        if (isRegenerating)
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              color: AppColors.black.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}

class _QrErrorState extends StatelessWidget {
  final String error;
  final Map<String, String> strings;
  final VoidCallback onRetry;

  const _QrErrorState({
    required this.error,
    required this.strings,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            error,
            style: AppTextStyles.bodySmall(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            text: strings['retry'] ?? 'Retry',
            onPressed: onRetry,
            variant: AppButtonVariant.filled,
            prefixIcon: const Icon(Icons.refresh_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _ExpiryWarning extends StatefulWidget {
  final Map<String, String> strings;

  const _ExpiryWarning({super.key, required this.strings});

  @override
  State<_ExpiryWarning> createState() => _ExpiryWarningState();
}

class _ExpiryWarningState extends State<_ExpiryWarning> {
  static const int _expirySeconds = 300;
  int _remaining = _expirySeconds;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining > 0) _startTimer();
    });
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _remaining ~/ 60;
    final seconds = _remaining % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    final isUrgent = _remaining <= 60;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: (isUrgent ? AppColors.error : AppColors.warning).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: (isUrgent ? AppColors.error : AppColors.warning).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isUrgent ? Icons.timer_off_rounded : Icons.timer_outlined,
            size: 18,
            color: isUrgent ? AppColors.error : AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '${widget.strings['qr_expiry_warning'] ?? 'This QR code expires in 5 minutes for security. Generate a new one if it expires.'}  $timeStr',
              style: AppTextStyles.caption(
                color: isUrgent ? AppColors.error : AppColors.warning,
                weight: isUrgent ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SitterGuide extends StatelessWidget {
  final bool isStart;
  final Map<String, String> strings;

  const _SitterGuide({
    required this.isStart,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: context.primaryColor.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 20, color: context.primaryColor),
              const SizedBox(width: AppSpacing.sm),
              Text(
                strings['what_to_do_next'] ?? 'What to do next',
                style: AppTextStyles.titleMedium(
                  weight: FontWeight.w600,
                  color: context.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (isStart) ...[
            _StepItem(
              number: 1,
              text: strings['sitter_step_show_qr'] ??
                  'Show this QR code to the parent so they can scan it',
            ),
            const SizedBox(height: AppSpacing.sm),
            _StepItem(
              number: 2,
              text: strings['sitter_step_wait_scan'] ??
                  'Wait for the parent to scan the code',
            ),
            const SizedBox(height: AppSpacing.sm),
            _StepItem(
              number: 3,
              text: strings['sitter_step_session_starts'] ??
                  'The session will start automatically once scanned',
            ),
          ] else ...[
            _StepItem(
              number: 1,
              text: strings['sitter_step_show_end_qr'] ??
                  'Show this QR code to the parent to end the session',
            ),
            const SizedBox(height: AppSpacing.sm),
            _StepItem(
              number: 2,
              text: strings['sitter_step_wait_end_scan'] ??
                  'Wait for the parent to scan it',
            ),
            const SizedBox(height: AppSpacing.sm),
            _StepItem(
              number: 3,
              text: strings['sitter_step_session_ends'] ??
                  'The session will end and overtime will be calculated',
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded,
                    size: 16, color: AppColors.warning),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    isStart
                        ? (strings['sitter_start_tip'] ??
                            'Tip: The parent must be nearby to scan this code. If it expires, generate a new one.')
                        : (strings['sitter_end_tip'] ??
                            'Tip: Make sure all tasks are done before ending. Overtime is calculated automatically.'),
                    style: AppTextStyles.caption(
                      color: AppColors.warning,
                      weight: FontWeight.w500,
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

class _StepItem extends StatelessWidget {
  final int number;
  final String text;

  const _StepItem({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: context.primaryColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: AppTextStyles.labelSmall(
                color: Colors.white,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyMedium(
              color: context.textSecondaryColor,
            ),
          ),
        ),
      ],
    );
  }
}
