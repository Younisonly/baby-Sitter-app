import 'package:flutter/material.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/utils/time_formatter.dart';
import 'package:babysitter/shared/models/booking_model.dart';

class BookingHelpers {
  static Color statusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return AppColors.warning;
      case BookingStatus.confirmed:
        return AppColors.success;
      case BookingStatus.inProgress:
        return AppColors.info;
      case BookingStatus.completed:
        return AppColors.info;
      case BookingStatus.cancelled:
        return AppColors.error;
      case BookingStatus.rejected:
        return AppColors.textMutedLight;
      case BookingStatus.expired:
        return AppColors.textMutedLight;
    }
  }

  static IconData statusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Icons.schedule_rounded;
      case BookingStatus.confirmed:
        return Icons.check_circle_rounded;
      case BookingStatus.inProgress:
        return Icons.play_circle_rounded;
      case BookingStatus.completed:
        return Icons.check_circle_outline;
      case BookingStatus.cancelled:
        return Icons.cancel_rounded;
      case BookingStatus.rejected:
        return Icons.block_rounded;
      case BookingStatus.expired:
        return Icons.timer_off_rounded;
    }
  }

  // Converts "10:00" → "10:00 AM", "16:30" → "4:30 PM", "00:00" → "12:00 AM"
  // TODO: Pass locale from context/ref instead of defaulting to 'en'
  static String formatTime(String? time, {String locale = 'en'}) {
    return TimeFormatter.formatTimeString(time, locale);
  }

  // Converts ("10:00", "16:00") → "10:00 AM to 4:00 PM"
  // TODO: Pass locale from context/ref instead of defaulting to 'en'
  static String formatTimeRange(String? startTime, String? endTime, {String locale = 'en'}) {
    return TimeFormatter.formatTimeRange(startTime, endTime, locale);
  }

  static BookingStatus parseBookingStatus(String status) {
    switch (status) {
      case 'pending':
        return BookingStatus.pending;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'in_progress':
        return BookingStatus.inProgress;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'rejected':
        return BookingStatus.rejected;
      case 'expired':
        return BookingStatus.expired;
      default:
        return BookingStatus.pending;
    }
  }

  static SessionStatus parseSessionStatus(String status) {
    switch (status) {
      case 'pending':
        return SessionStatus.pending;
      case 'start_qr_generated':
        return SessionStatus.startQrGenerated;
      case 'active':
        return SessionStatus.active;
      case 'end_qr_generated':
        return SessionStatus.endQrGenerated;
      case 'completed':
        return SessionStatus.completed;
      default:
        return SessionStatus.pending;
    }
  }

  static String statusLocalizationKey(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.inProgress:
        return 'in_progress';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.cancelled:
        return 'cancelled';
      case BookingStatus.rejected:
        return 'rejected';
      case BookingStatus.expired:
        return 'expired';
    }
  }
}
