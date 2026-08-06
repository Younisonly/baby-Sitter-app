import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_shadows.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/extensions/extensions.dart';
import 'package:babysitter/shared/widgets/app_text_field.dart';

class BookingNotesField extends StatelessWidget {
  final TextEditingController controller;
  final Map<String, String> strings;
  final ValueChanged<String>? onChanged;

  const BookingNotesField({
    super.key,
    required this.controller,
    required this.strings,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.subtle,
      ),
      child: AppTextField(
        controller: controller,
        maxLines: 3,
        maxLength: 1000,
        hint: strings['notes_hint'] ??
            'Allergies, routines, special instructions...',
        showCounter: true,
        onChanged: onChanged,
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 400.ms);
  }
}
