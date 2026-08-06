import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/theme_colors.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/network/error_handler.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/features/booking/data/session_provider.dart';
import 'package:babysitter/features/booking/data/booking_provider.dart';
import 'package:babysitter/shared/widgets/widgets.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final bool isEndQr;

  const QrScannerScreen({
    super.key,
    required this.bookingId,
    this.isEndQr = false,
  });

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final _tokenController = TextEditingController();
  bool _isProcessing = false;
  String? _error;
  bool _useManualEntry = false;
  bool _cameraPermissionDenied = false;
  DateTime? _lastErrorTime;
  static const Duration _rateLimitCooldown = Duration(seconds: 3);

  final _scannerController = MobileScannerController(
    facing: CameraFacing.back,
    detectionSpeed: DetectionSpeed.normal,
  );

  @override
  void initState() {
    super.initState();
    _scannerController.addListener(_onScannerState);
  }

  @override
  void dispose() {
    _scannerController.removeListener(_onScannerState);
    _scannerController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  void _onScannerState() {
    if (!mounted) return;
    final state = _scannerController.value;
    setState(() {
      _cameraPermissionDenied = !state.hasCameraPermission &&
          state.error?.errorCode == MobileScannerErrorCode.permissionDenied;
    });
  }

  void _retryCamera() {
    setState(() => _cameraPermissionDenied = false);
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    if (_lastErrorTime != null &&
        DateTime.now().difference(_lastErrorTime!) < _rateLimitCooldown) {
      return;
    }
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue != null) {
      _tokenController.text = barcode!.rawValue!;
      _processQrToken();
    }
  }

  Future<void> _processQrToken() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(() => _error = 'Please scan or enter the QR code');
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final sessionNotifier = ref.read(sessionProvider(widget.bookingId).notifier);

      if (widget.isEndQr) {
        final booking = await sessionNotifier.scanEndQr(qrToken: token);
        if (!mounted) return;
        ref.read(bookingActionProvider)(
          widget.bookingId,
          () async => booking,
        );
        ref.read(pendingSessionSnackProvider.notifier).state = 'session_ended';
        context.pushReplacement('/booking/${widget.bookingId}');
      } else {
        final booking = await sessionNotifier.scanStartQr(qrToken: token);
        if (!mounted) return;
        ref.read(bookingActionProvider)(
          widget.bookingId,
          () async => booking,
        );
        ref.read(pendingSessionSnackProvider.notifier).state = 'session_started';
        if (context.mounted) context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorHandler.handle(e).message;
          _isProcessing = false;
          _lastErrorTime = DateTime.now();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final isDark = context.isDark;
    final isStart = !widget.isEndQr;
    final title = isStart
        ? (strings['scan_start_qr'] ?? 'Scan to Start')
        : (strings['scan_end_qr'] ?? 'Scan to End');

    final availableHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom -
        kToolbarHeight -
        AppSpacing.xl * 2;
    final cameraHeight = (availableHeight * 0.45).clamp(200.0, 340.0);

    return Scaffold(
      appBar: AppAppBar(
        title: title,
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_useManualEntry) ...[
              Container(
                width: double.infinity,
                height: cameraHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: _cameraPermissionDenied
                    ? _CameraPermissionPlaceholder(
                        strings: strings,
                        isDark: isDark,
                        onRetry: _retryCamera,
                      )
                    : MobileScanner(
                        controller: _scannerController,
                        onDetect: _onDetect,
                        overlayBuilder: (context, constraints) => _QrOverlay(),
                      ),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: TextButton.icon(
                  onPressed: () => setState(() => _useManualEntry = true),
                  icon: const Icon(Icons.keyboard_rounded, size: 18),
                  label: Text(
                    strings['enter_manually'] ?? 'Enter code manually',
                    style: AppTextStyles.bodyMedium(
                      color: context.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (_useManualEntry) ...[
              _buildManualEntry(strings),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: TextButton.icon(
                  onPressed: () => setState(() => _useManualEntry = false),
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                  label: Text(
                    strings['scan_with_camera'] ?? 'Scan with camera',
                    style: AppTextStyles.bodyMedium(
                      color: context.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            _StepGuide(
              isStart: isStart,
              strings: strings,
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 16, color: AppColors.error),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _error!,
                        style: AppTextStyles.bodySmall(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildManualEntry(Map<String, String> strings) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.dividerColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.keyboard_rounded,
                  size: 20, color: context.primaryColor),
              const SizedBox(width: AppSpacing.sm),
              Text(
                strings['enter_qr_code'] ?? 'Enter QR Code',
                style: AppTextStyles.titleMedium(weight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _tokenController,
            label: strings['qr_code'] ?? 'QR Code',
            hint: strings['paste_qr_code'] ?? 'Paste the QR code here',
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: _isProcessing
                  ? (strings['processing'] ?? 'Processing...')
                  : (strings['verify_qr'] ?? 'Verify & Submit'),
              onPressed: _isProcessing ? null : _processQrToken,
              variant: AppButtonVariant.filled,
              prefixIcon: const Icon(Icons.verified_rounded, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepGuide extends StatelessWidget {
  final bool isStart;
  final Map<String, String> strings;

  const _StepGuide({
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
              Icon(Icons.lightbulb_outline_rounded,
                  size: 20, color: context.primaryColor),
              const SizedBox(width: AppSpacing.sm),
              Text(
                isStart
                    ? (strings['how_to_start_session'] ?? 'How to start the session')
                    : (strings['how_to_end_session'] ?? 'How to end the session'),
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
              text: strings['step_sitter_generates_qr'] ??
                  'Wait for the babysitter to generate a start QR code on their phone',
            ),
            const SizedBox(height: AppSpacing.sm),
            _StepItem(
              number: 2,
              text: strings['step_scan_qr'] ??
                  'Ask the babysitter to show you the QR code, then scan it with the camera above',
            ),
            const SizedBox(height: AppSpacing.sm),
            _StepItem(
              number: 3,
              text: strings['step_session_starts'] ??
                  'Once scanned, the session starts automatically and you\'ll enter the live session screen',
            ),
          ] else ...[
            _StepItem(
              number: 1,
              text: strings['step_sitter_generates_end_qr'] ??
                  'Ask the babysitter to generate an end QR code on their phone',
            ),
            const SizedBox(height: AppSpacing.sm),
            _StepItem(
              number: 2,
              text: strings['step_scan_end_qr'] ??
                  'Scan the QR code shown on the babysitter\'s phone using the camera above',
            ),
            const SizedBox(height: AppSpacing.sm),
            _StepItem(
              number: 3,
              text: strings['step_session_ends'] ??
                  'The session ends and overtime is calculated automatically',
            ),
          ],
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

class _QrOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary, width: 3),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _CameraPermissionPlaceholder extends StatelessWidget {
  final Map<String, String> strings;
  final bool isDark;
  final VoidCallback onRetry;

  const _CameraPermissionPlaceholder({
    required this.strings,
    required this.isDark,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.qr_code_scanner_rounded,
                size: 56,
                color: context.primaryColor.withValues(alpha: 0.4),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                strings['camera_permission_needed'] ??
                    'Camera access needed',
                style: AppTextStyles.titleMedium(weight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                strings['camera_permission_desc'] ??
                    'Grant camera permission to scan the QR code, or enter the code manually.',
                style: AppTextStyles.bodySmall(
                  color: context.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                text: strings['enable_camera'] ?? 'Enable Camera',
                onPressed: onRetry,
                variant: AppButtonVariant.filled,
                prefixIcon: const Icon(Icons.camera_alt_rounded, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
