import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/extensions.dart';

class VoicePreviewSheet extends ConsumerStatefulWidget {
  final String filePath;
  final int durationSeconds;

  const VoicePreviewSheet({
    super.key,
    required this.filePath,
    required this.durationSeconds,
  });

  @override
  ConsumerState<VoicePreviewSheet> createState() => _VoicePreviewSheetState();
}

class _VoicePreviewSheetState extends ConsumerState<VoicePreviewSheet> {
  final _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
        _player.seek(Duration.zero);
      }
    });
    _player.setSourceDeviceFile(widget.filePath);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_isPlaying) {
      _player.pause();
      setState(() => _isPlaying = false);
    } else {
      if (_position >= Duration(seconds: widget.durationSeconds)) {
        _player.seek(Duration.zero);
      }
      _player.resume();
      setState(() => _isPlaying = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final duration = widget.durationSeconds;
    final progress = duration > 0 ? (_position.inSeconds / duration) : 0.0;
    final remaining = (duration - _position.inSeconds).clamp(0, duration);
    final remStr = '${(remaining ~/ 60).toString().padLeft(2, '0')}:${(remaining % 60).toString().padLeft(2, '0')}';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HandleBar(),
            SizedBox(height: AppSpacing.md.h),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.mic_rounded, size: 28, color: AppColors.primary),
            ),
            SizedBox(height: AppSpacing.md.h),
            Text(
              'Voice message',
              style: AppTextStyles.labelLarge(
                color: context.textPrimary,
                weight: FontWeight.w600,
              ),
            ),
            Text(
              '${widget.durationSeconds}s',
              style: AppTextStyles.caption(color: context.textMuted),
            ),
            SizedBox(height: AppSpacing.lg.h),
            Row(
              children: [
                Text(remStr, style: AppTextStyles.caption(color: context.textMuted)),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: context.borderColor,
                        thumbColor: AppColors.primary,
                      ),
                      child: Slider(
                        value: progress.clamp(0.0, 1.0),
                        onChanged: (v) {
                          _player.seek(Duration(seconds: (v * duration).round()));
                        },
                      ),
                    ),
                  ),
                ),
                Text('0:00', style: AppTextStyles.caption(color: context.textMuted)),
              ],
            ),
            SizedBox(height: AppSpacing.md.h),
            GestureDetector(
              onTap: _togglePlay,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 28,
                  color: AppColors.white,
                ),
              ),
            ),
            SizedBox(height: AppSpacing.lg.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    child: Text('Delete', style: AppTextStyles.labelMedium(color: context.textPrimary)),
                  ),
                ),
                SizedBox(width: AppSpacing.md.w),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    child: Text('Send', style: AppTextStyles.labelMedium(color: AppColors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HandleBar extends StatelessWidget {
  const HandleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 32,
        height: 4,
        decoration: BoxDecoration(
          color: context.textMuted.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
