import 'package:babysitter/core/localization/app_localization.dart';

/// Service responsible for resolving notification text (title + body) into
/// properly localized, fully-interpolated strings.
///
/// ─────────────────────────────────────────────────────────────────────────────
/// TEMPLATE AUTHORING GUIDE
/// ─────────────────────────────────────────────────────────────────────────────
///
/// When the backend adds a new `action_key`, add matching keys in
/// `app_localization.dart` following this exact naming convention:
///
///   {action_key}_title   →  e.g. "booking_confirmed_title"
///   {action_key}_body    →  e.g. "booking_confirmed_body"
///
/// For sitter-specific variants that need different text than the customer
/// version, use the full title_key / body_key from the backend:
///   e.g. "booking_in_progress_sitter_title", "booking_in_progress_sitter_body"
///
/// Template values may contain placeholder tokens in the form `{variable_name}`.
/// Every token MUST have a corresponding key in the `data_json` sent by the backend.
///
/// Common tokens and where they come from:
///   {sitter_name}     — sitter's display name (from booking/review data)
///   {customer_name}   — parent's display name
///   {date}            — booking date string, e.g. "Jul 28, 2026"
///   {time}            — booking time string, e.g. "15:00"
///   {children_count}  — number of children in the booking
///   {total_amount}    — total booking amount
///   {rating}          — star rating value, e.g. "4.5"
///   {count}           — generic count (followers, etc.)
///   {plan_name}       — subscription plan name
///   {reason}          — rejection/cancellation reason
///   {device_name}     — device name for security alerts
///   {location}        — geographic location for login alerts
///   {message}         — generic message body for security_alert
///   {booking_id}      — booking ID number
///   {ticket_id}       — support ticket ID
///   {session_count}   — number of sessions in a group booking
///   {completed_count} — number of completed sessions
///   {message_preview} — first ~60 chars of a chat message
///   {sender_name}     — name of chat message sender
///
/// Testing:
///   After adding a new template key, verify that the English string produces
///   no raw `{token}` text when all expected data values are provided.
/// ─────────────────────────────────────────────────────────────────────────────
class NotificationLocalizationService {
  NotificationLocalizationService._();

  /// Regex to detect remaining unreplaced `{token}` placeholders.
  static final RegExp _placeholderPattern =
      RegExp(r'\{[a-zA-Z_][a-zA-Z0-9_]*\}');

  // ─────────────────────────────────────────────────────────────────────────
  // Public API
  // ─────────────────────────────────────────────────────────────────────────

  /// Resolves the notification **title** to a localized, fully-interpolated string.
  static String resolveTitle({
    required String? actionKey,
    required String locale,
    required String apiTitle,
    required Map<String, dynamic>? data,
  }) {
    return _resolve(
      actionKey: actionKey,
      locale: locale,
      apiText: apiTitle,
      data: _flattenData(data),
      suffix: 'title',
      explicitKey: data?['title_key']?.toString(),
    );
  }

  /// Resolves the notification **body** to a localized, fully-interpolated string.
  static String resolveBody({
    required String? actionKey,
    required String locale,
    required String apiBody,
    required Map<String, dynamic>? data,
  }) {
    return _resolve(
      actionKey: actionKey,
      locale: locale,
      apiText: apiBody,
      data: _flattenData(data),
      suffix: 'body',
      explicitKey: data?['body_key']?.toString(),
    );
  }

  /// Resolves a notification **category** to its localized display label.
  static String resolveCategory(String locale, String category) {
    final strings = AppLocalization.get(locale);
    final key = 'category_$category';
    if (strings.containsKey(key)) return strings[key]!;
    if (category.isEmpty) return '';
    return category[0].toUpperCase() + category.substring(1);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Data normalization
  // ─────────────────────────────────────────────────────────────────────────

  /// Flattens the data_json map so replacement values are always at the top level.
  ///
  /// The backend may store data_json differently depending on the notification path:
  /// - Via `BookingNotification` / `AppDatabaseChannel`: flat map with replacement keys.
  /// - Via `NotificationService::send()`: may embed a nested `data_json` sub-map.
  ///
  /// This method merges everything into a single flat map so resolution is consistent.
  static Map<String, dynamic> _flattenData(Map<String, dynamic>? raw) {
    if (raw == null) return {};
    final flat = Map<String, dynamic>.from(raw);

    // If there's a nested 'data_json' map, merge its values into the top level.
    // (Older notifications stored via AppDatabaseChannel had this structure.)
    final nested = raw['data_json'];
    if (nested is Map<String, dynamic>) {
      for (final entry in nested.entries) {
        flat.putIfAbsent(entry.key, () => entry.value);
      }
    }

    return flat;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Core resolution chain
  // ─────────────────────────────────────────────────────────────────────────

  /// Resolution chain for both title and body.
  ///
  /// Strategy (in order of priority):
  ///   1. [explicitKey]    — exact key stored by backend (e.g. "booking_in_progress_sitter_title")
  ///   2. apiText          — if it matches a localization key directly (e.g. "booking_confirmed_title")
  ///   3. {actionKey}_suffix      — primary convention: "booking_confirmed_title"
  ///   4. {actionKey}_notification_suffix — legacy convention
  ///   5. Interpolate matched template with flat data_json values
  ///   6. If no key found → interpolate raw apiText from DB
  ///   7. Strip remaining {tokens} as last resort — NEVER show raw tokens to user
  static String _resolve({
    required String? actionKey,
    required String locale,
    required String apiText,
    required Map<String, dynamic> data,
    required String suffix,
    String? explicitKey,
  }) {
    final strings = AppLocalization.get(locale);

    // ── Step 1: Backend-provided explicit localization key ────────────────
    // Most reliable — the backend knows exactly which template was used.
    if (explicitKey != null && explicitKey.isNotEmpty) {
      final template = strings[explicitKey];
      if (template != null) {
        final result = _finalize(_interpolate(template, data, locale));
        if (result.isNotEmpty) return result;
      }
    }

    // ── Step 2: apiText might itself be a localization key ─────────────────
    // Happens when AppDatabaseChannel stores the titleKey directly as title.
    if (apiText.isNotEmpty && !apiText.contains(' ') && strings.containsKey(apiText)) {
      final template = strings[apiText]!;
      final result = _finalize(_interpolate(template, data, locale));
      if (result.isNotEmpty) return result;
    }

    // ── Step 3 & 4: Look up by action_key ────────────────────────────────
    final localizedTemplate = _lookupKey(strings, actionKey, suffix);
    if (localizedTemplate != null) {
      final interpolated = _interpolate(localizedTemplate, data, locale);
      if (!_hasPlaceholders(interpolated)) {
        final trimmed = interpolated.trim();
        if (trimmed.isNotEmpty) return trimmed;
      }

      // Some tokens unreplaced — try API text fallback first.
      final apiFallback = _tryApiText(apiText, data, locale);
      if (apiFallback != null) return apiFallback;

      // Strip remaining tokens from the localized template.
      final stripped = _stripPlaceholders(interpolated).trim();
      if (stripped.isNotEmpty) return stripped;
    }

    // ── Step 5: No localization key → use API text ────────────────────────
    final apiFallback = _tryApiText(apiText, data, locale);
    if (apiFallback != null) return apiFallback;

    // ── Step 6: Empty — UI handles this gracefully ────────────────────────
    return '';
  }

  /// Looks up a localization key for the given [actionKey] and [suffix].
  static String? _lookupKey(
    Map<String, String> strings,
    String? actionKey,
    String suffix,
  ) {
    if (actionKey == null || actionKey.isEmpty) return null;

    // Primary: booking_confirmed_title
    final primary = '${actionKey}_$suffix';
    if (strings.containsKey(primary)) return strings[primary];

    // Legacy infix: booking_confirmed_notification_title
    final legacy = '${actionKey}_notification_$suffix';
    if (strings.containsKey(legacy)) return strings[legacy];

    return null;
  }

  /// Tries to produce a clean string from [apiText] by interpolating [data].
  static String? _tryApiText(
    String apiText,
    Map<String, dynamic> data,
    String locale,
  ) {
    if (apiText.trim().isEmpty) return null;
    final interpolated = _interpolate(apiText, data, locale);
    if (!_hasPlaceholders(interpolated)) {
      final trimmed = interpolated.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    final stripped = _stripPlaceholders(interpolated).trim();
    if (stripped.isNotEmpty) return stripped;
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  static String _interpolate(String text, Map<String, dynamic> data, String locale) {
    var result = text;
    if (data.isNotEmpty) {
      for (final entry in data.entries) {
        if (entry.value == null) continue;
        result = result.replaceAll('{${entry.key}}', entry.value.toString());
      }
    }
    return _localizeAmPm(result, locale);
  }

  static String _localizeAmPm(String text, String locale) {
    if (locale != 'ar') return text;
    return text
        .replaceAllMapped(
          RegExp(r'(\d{1,2}:\d{2})\s*AM\b', caseSensitive: false),
          (m) => '${m[1]} ص',
        )
        .replaceAllMapped(
          RegExp(r'(\d{1,2}:\d{2})\s*PM\b', caseSensitive: false),
          (m) => '${m[1]} م',
        );
  }

  static String _finalize(String text) {
    if (_hasPlaceholders(text)) return _stripPlaceholders(text).trim();
    return text.trim();
  }

  static bool _hasPlaceholders(String text) => _placeholderPattern.hasMatch(text);

  static String _stripPlaceholders(String text) =>
      text.replaceAll(_placeholderPattern, '').replaceAll(RegExp(r'\s{2,}'), ' ').trim();
}
