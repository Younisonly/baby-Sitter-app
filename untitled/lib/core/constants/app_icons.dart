import 'package:flutter/material.dart';

class AppIcons {
  AppIcons._();

  static IconData resolve(String? name, {IconData fallback = Icons.help_outline_rounded}) {
    if (name == null || name.isEmpty) return fallback;
    return _map[name.trim().toLowerCase()] ?? fallback;
  }

  static Set<String> get allKeys => _map.keys.toSet();

  static Set<String> keysByPrefix(String prefix) =>
      _map.keys.where((k) => k.startsWith(prefix)).toSet();

  static const Map<String, IconData> _map = {
    // ── Childcare ──
    'baby': Icons.child_care_rounded,
    'child_care': Icons.child_care_rounded,
    'toddler': Icons.emoji_people_rounded,
    'newborn': Icons.child_care_rounded,
    'preschool': Icons.school_rounded,
    'school': Icons.school_rounded,
    'special_needs': Icons.favorite_border_rounded,
    'kids': Icons.mood_rounded,
    'family': Icons.family_restroom,
    'heart': Icons.favorite_rounded,
    'favorite': Icons.favorite_rounded,
    'favorite_border': Icons.favorite_border_rounded,
    'spa': Icons.spa_outlined,
    'self_improvement': Icons.self_improvement_rounded,
    'overnight': Icons.nightlight_round,
    'moon': Icons.nightlight_round,
    'nightlight': Icons.nightlight_round,
    'emergency': Icons.health_and_safety_outlined,
    'health_and_safety': Icons.health_and_safety_outlined,

    // ── Booking & Calendar ──
    'calendar': Icons.calendar_month_rounded,
    'calendar_today': Icons.calendar_today_rounded,
    'event': Icons.event_rounded,
    'event_available': Icons.event_available_rounded,
    'event_busy': Icons.event_busy_rounded,
    'schedule': Icons.schedule_rounded,
    'clock': Icons.schedule_rounded,
    'timer': Icons.timer_rounded,
    'date_range': Icons.date_range_rounded,
    'history': Icons.history_rounded,
    'booking': Icons.event_available_rounded,
    'replay': Icons.replay_rounded,

    // ── Communication ──
    'chat': Icons.chat_bubble_outline_rounded,
    'chat_bubble': Icons.chat_bubble_outline_rounded,
    'message': Icons.chat_bubble_outline_rounded,
    'email': Icons.email_rounded,
    'mail': Icons.mail_outline_rounded,
    'envelope': Icons.email_rounded,
    'phone': Icons.phone_rounded,
    'phone_in_talk': Icons.phone_in_talk_rounded,
    'support_agent': Icons.support_agent_rounded,
    'forum': Icons.forum_rounded,
    'contact_support': Icons.contact_support_rounded,
    'send': Icons.send_rounded,

    // ── Security ──
    'security': Icons.security_rounded,
    'shield': Icons.shield_rounded,
    'verified': Icons.verified_rounded,
    'lock': Icons.lock_rounded,
    'lock_open': Icons.lock_open_rounded,
    'privacy_tip': Icons.privacy_tip_rounded,
    'gpp_good': Icons.gpp_good_rounded,

    // ── Navigation & UI ──
    'home': Icons.home_rounded,
    'search': Icons.search_rounded,
    'filter': Icons.filter_list_rounded,
    'filter_list': Icons.filter_list_rounded,
    'settings': Icons.settings_rounded,
    'dark_mode': Icons.dark_mode_rounded,
    'language': Icons.language_rounded,
    'logout': Icons.logout_rounded,
    'login': Icons.login_rounded,
    'close': Icons.close_rounded,
    'menu': Icons.menu_rounded,
    'more_horiz': Icons.more_horiz_rounded,
    'arrow_back': Icons.arrow_back_rounded,
    'arrow_forward': Icons.arrow_forward_rounded,

    // ── Profile & People ──
    'person': Icons.person_rounded,
    'person_outline': Icons.person_outline_rounded,
    'people': Icons.people_rounded,
    'people_outline': Icons.people_outline_rounded,
    'group': Icons.group_rounded,
    'badge': Icons.badge_rounded,
    'account_circle': Icons.account_circle_rounded,
    'manage_accounts': Icons.manage_accounts_rounded,
    'profile': Icons.person_rounded,

    // ── Status & Alerts ──
    'check': Icons.check_circle_rounded,
    'check_circle': Icons.check_circle_rounded,
    'cancel': Icons.cancel_rounded,
    'error': Icons.error_outline_rounded,
    'error_outline': Icons.error_outline_rounded,
    'warning': Icons.warning_rounded,
    'exclamation': Icons.warning_rounded,
    'warning_amber': Icons.warning_amber_rounded,
    'info': Icons.info_outline_rounded,
    'info_outline': Icons.info_outline_rounded,
    'help_outline': Icons.help_outline_rounded,
    'done_all': Icons.done_all_rounded,

    // ── Payment & Finance ──
    'payment': Icons.payment_rounded,
    'account_balance': Icons.account_balance_rounded,
    'wallet': Icons.account_balance_wallet_rounded,
    'card_giftcard': Icons.card_giftcard_rounded,
    'earnings': Icons.monetization_on_rounded,
    'monetization_on': Icons.monetization_on_rounded,
    'savings': Icons.savings_rounded,
    'receipt_long': Icons.receipt_long_rounded,
    'money': Icons.attach_money_rounded,

    // ── Notifications ──
    'notifications': Icons.notifications_outlined,
    'notifications_active': Icons.notifications_active_rounded,
    'bell': Icons.notifications_outlined,
    'campaign': Icons.campaign_rounded,
    'announcement': Icons.campaign_rounded,
    'circle_notifications': Icons.circle_notifications_rounded,

    // ── Reviews & Ratings ──
    'star': Icons.star_rounded,
    'star_outline': Icons.star_outline_rounded,
    'star_half': Icons.star_half_rounded,
    'rate_review': Icons.rate_review_rounded,
    'thumb_up': Icons.thumb_up_rounded,

    // ── Location & Maps ──
    'location_on': Icons.location_on_rounded,
    'location_off': Icons.location_off_rounded,
    'place': Icons.place_rounded,
    'map': Icons.map_rounded,
    'near_me': Icons.near_me_rounded,
    'pin': Icons.push_pin_rounded,
    'explore_nearby': Icons.explore_rounded,

    // ── Activities & Analytics ──
    'dashboard': Icons.dashboard_rounded,
    'trending_up': Icons.trending_up_rounded,
    'auto_graph': Icons.show_chart_rounded,
    'analytics': Icons.analytics_rounded,

    // ── Media & Files ──
    'image': Icons.image_rounded,
    'photo_camera': Icons.photo_camera_rounded,
    'videocam': Icons.videocam_rounded,
    'mic': Icons.mic_rounded,
    'file_upload': Icons.file_upload_rounded,
    'attachment': Icons.attachment_rounded,
    'description': Icons.description_rounded,
    'document': Icons.description_rounded,

    // ── Support & Help ──
    'support': Icons.support_agent_rounded,
    'help': Icons.help_outline_rounded,
    'live_help': Icons.live_help_rounded,
    'question_answer': Icons.question_answer_rounded,
    'faq': Icons.quiz_rounded,

    // ── Actions ──
    'delete': Icons.delete_outline_rounded,
    'trash': Icons.delete_outline_rounded,
    'edit': Icons.edit_rounded,
    'pencil': Icons.edit_rounded,
    'add': Icons.add_circle_outline_rounded,
    'plus': Icons.add_circle_outline_rounded,
    'refresh': Icons.refresh_rounded,
    'sync': Icons.sync_rounded,
    'share': Icons.share_rounded,
    'upload': Icons.upload_rounded,
    'download': Icons.download_rounded,
    'flag': Icons.flag_rounded,
    'report': Icons.flag_rounded,

    // ── Certificates & Education ──
    'certificate': Icons.verified_rounded,
    'auto_stories': Icons.auto_stories_rounded,
    'psychology': Icons.psychology_rounded,
    'skills': Icons.auto_stories_rounded,

    // ── Admin & Management ──
    'admin_panel_settings': Icons.admin_panel_settings_rounded,
    'supervisor_account': Icons.supervisor_account_rounded,
    'settings_applications': Icons.settings_applications_rounded,

    // ── Legacy / Extra mappings for backward compatibility ──
    'notif': Icons.notifications_outlined,
    'alert': Icons.warning_rounded,
    'danger': Icons.warning_rounded,
    'success': Icons.check_circle_rounded,
    'emoji_people': Icons.emoji_people_rounded,
    'credit-card': Icons.credit_card_rounded,
    'fire': Icons.local_fire_department_rounded,
    'gift': Icons.card_giftcard_rounded,
    'hand': Icons.back_hand_rounded,
    'megaphone': Icons.campaign_rounded,
    'question': Icons.help_outline_rounded,
    'x': Icons.close_rounded,
    'date': Icons.calendar_today_rounded,
    'time': Icons.schedule_rounded,
    'user': Icons.person_rounded,
    'account': Icons.person_rounded,
    'gear': Icons.settings_rounded,
    'config': Icons.settings_rounded,
    'headset': Icons.support_agent_rounded,
    'premium': Icons.workspace_premium_outlined,
    'workspace_premium': Icons.workspace_premium_outlined,
    'crown': Icons.workspace_premium_outlined,
    'diamond': Icons.workspace_premium_outlined,
    'messages': Icons.chat_bubble_outline_rounded,
    'payments': Icons.payment_rounded,
    'credit_card': Icons.credit_card_rounded,
    'dollar': Icons.attach_money_rounded,
    'profile_verified': Icons.verified_rounded,
    'subscribe': Icons.subscriptions_rounded,
    'subscription': Icons.workspace_premium_outlined,
    'call': Icons.phone_rounded,
    'sort': Icons.sort_rounded,
    'pin_drop': Icons.push_pin_rounded,
    'visibility': Icons.visibility_rounded,
    'eye': Icons.visibility_rounded,
    'school_age': Icons.school_rounded,
    'infant': Icons.child_care_rounded,
    'graduation': Icons.school_rounded,
    'first_aid': Icons.medical_services_rounded,
    'cpr': Icons.favorite_border_rounded,
    'childcare': Icons.child_care_rounded,
    'early_education': Icons.school_rounded,
    'nutrition': Icons.restaurant_rounded,
    'other': Icons.more_horiz_rounded,
    'kid': Icons.emoji_people_rounded,
    'child': Icons.child_care_rounded,
  };
}
