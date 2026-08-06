import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimeFormatter {
  TimeFormatter._();

  static String formatTimeOfDay(TimeOfDay t, String locale) {
    final isArabic = locale == 'ar';
    final hour = t.hour;
    final minute = t.minute.toString().padLeft(2, '0');
    if (isArabic) {
      final period = hour < 12 ? 'ص' : 'م';
      final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$h:$minute $period';
    }
    final period = hour < 12 ? 'AM' : 'PM';
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$h:$minute $period';
  }

  static String formatTimeString(String? time, String locale) {
    if (time == null || time.isEmpty) return '--:--';
    final parts = time.split(':');
    if (parts.length < 2) return time;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1].padLeft(2, '0');
    final isArabic = locale == 'ar';
    if (isArabic) {
      final period = hour < 12 ? 'ص' : 'م';
      final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$h:$minute $period';
    }
    final period = hour < 12 ? 'AM' : 'PM';
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$h:$minute $period';
  }

  static String formatTimeRange(String? startTime, String? endTime, String locale) {
    final start = formatTimeString(startTime, locale);
    final end = formatTimeString(endTime, locale);
    final separator = locale == 'ar' ? ' إلى ' : ' to ';
    return '$start$separator$end';
  }

  static String formatRelativeTime(DateTime dt, String locale) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    final isArabic = locale == 'ar';

    if (diff.inSeconds < 60) {
      return isArabic ? 'الآن' : 'now';
    }
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      if (isArabic) return 'منذ $m د';
      return '${m}m';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      if (isArabic) return 'منذ $h س';
      return '${h}h';
    }
    if (diff.inDays < 7) {
      final d = diff.inDays;
      if (isArabic) return 'منذ $d ي';
      return '${d}d';
    }
    if (diff.inDays < 30) {
      final w = (diff.inDays / 7).floor();
      if (isArabic) return 'منذ $w أ';
      return '${w}w';
    }
    if (diff.inDays < 365) {
      final mo = (diff.inDays / 30).floor();
      if (isArabic) return 'منذ $mo ش';
      return '${mo}mo';
    }
    final y = (diff.inDays / 365).floor();
    if (isArabic) return 'منذ $y س';
    return '${y}y';
  }

  static String formatMessageTime(String isoDate, String locale) {
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDate = DateTime(dt.year, dt.month, dt.day);

    if (msgDate == today) {
      if (isArabicLocale(locale)) {
        final hour = dt.hour;
        final minute = dt.minute.toString().padLeft(2, '0');
        final period = hour < 12 ? 'ص' : 'م';
        final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        return '$h:$minute $period';
      }
      return DateFormat('h:mm a', locale).format(dt);
    }

    final yesterday = today.subtract(const Duration(days: 1));
    if (msgDate == yesterday) {
      return isArabicLocale(locale) ? 'أمس' : 'Yesterday';
    }

    final weekAgo = today.subtract(const Duration(days: 7));
    if (msgDate.isAfter(weekAgo) || msgDate == weekAgo) {
      return DateFormat('EEE', locale).format(dt);
    }

    return DateFormat('M/d', locale).format(dt);
  }

  static String formatDetailTime(String isoDate, String locale) {
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return '';

    final now = DateTime.now();
    final diff = now.difference(dt);
    final isArabic = locale == 'ar';

    if (diff.inSeconds < 60) {
      return isArabic ? 'الآن' : 'Just now';
    }
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      if (isArabic) return 'منذ $m دقيقة';
      return '$m ${m == 1 ? 'minute' : 'minutes'} ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      if (isArabic) return 'منذ $h ساعة';
      return '$h ${h == 1 ? 'hour' : 'hours'} ago';
    }
    if (diff.inDays < 7) {
      final d = diff.inDays;
      if (isArabic) return 'منذ $d يوم';
      return '$d ${d == 1 ? 'day' : 'days'} ago';
    }

    final isArabicLocale = locale == 'ar';
    if (isArabicLocale) {
      return DateFormat('d/M/yyyy', locale).format(dt);
    }
    return DateFormat('M/d/yyyy', locale).format(dt);
  }

  static bool isArabicLocale(String locale) => locale == 'ar';

  static String notificationGroupKey(DateTime date, String locale) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dt = DateTime(date.year, date.month, date.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    if (isArabicLocale(locale)) {
      if (dt == today) return 'اليوم';
      if (dt == yesterday) return 'أمس';
      if (dt.isAfter(weekAgo) || dt == weekAgo) return 'هذا الأسبوع';
      return 'سابقاً';
    }

    if (dt == today) return 'Today';
    if (dt == yesterday) return 'Yesterday';
    if (dt.isAfter(weekAgo) || dt == weekAgo) return 'This Week';
    return 'Earlier';
  }
}
