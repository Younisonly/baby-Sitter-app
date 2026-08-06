import 'package:babysitter/core/utils/time_formatter.dart';

String formatMessageTime(String createdAt, String locale) {
  return TimeFormatter.formatMessageTime(createdAt, locale);
}

String formatConversationTime(String createdAt, String locale) {
  return formatMessageTime(createdAt, locale);
}

String formatRelativeTime(String isoDate, String locale) {
  final dt = DateTime.tryParse(isoDate);
  if (dt == null) return '';
  return TimeFormatter.formatRelativeTime(dt, locale);
}
