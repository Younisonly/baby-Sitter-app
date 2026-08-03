<?php

namespace Database\Seeders;

use App\Models\AppIcon;
use Illuminate\Database\Seeder;

class AppIconSeeder extends Seeder
{
    public function run(): void
    {
        $icons = [
            // ── Childcare ──
            ['baby', 'Baby', 'رضيع', 'childcare', 'newborn infant baby child care'],
            ['child_care', 'Child Care', 'رعاية أطفال', 'childcare', 'childcare care child caring'],
            ['toddler', 'Toddler', 'طفل صغير', 'childcare', 'toddler small child kid'],
            ['newborn', 'Newborn', 'حديث الولادة', 'childcare', 'newborn infant baby'],
            ['preschool', 'Preschool', 'ما قبل المدرسة', 'childcare', 'preschool kindergarten nursery'],
            ['school', 'School', 'مدرسة', 'childcare', 'school education learning academic'],
            ['special_needs', 'Special Needs', 'احتياجات خاصة', 'childcare', 'special needs disability care support'],
            ['kids', 'Kids', 'أطفال', 'childcare', 'kids children play fun'],
            ['family', 'Family', 'عائلة', 'childcare', 'family parents home'],
            ['heart', 'Heart', 'قلب', 'childcare', 'heart love care affection'],
            ['favorite', 'Favorite', 'مفضل', 'childcare', 'favorite love heart bookmark'],
            ['favorite_border', 'Favorite Outline', 'مفضل (حدود)', 'childcare', 'favorite outline love heart bookmark'],
            ['spa', 'Spa', 'سبا', 'childcare', 'spa relaxation wellness calm'],
            ['self_improvement', 'Self Improvement', 'تحسين الذات', 'childcare', 'self improvement growth development'],
            ['overnight', 'Overnight', 'مبيت', 'childcare', 'overnight night stay sleepover'],
            ['moon', 'Moon', 'قمر', 'childcare', 'moon night sleep overnight'],
            ['nightlight', 'Nightlight', 'ضوء ليلي', 'childcare', 'nightlight night sleep dark'],
            ['emergency', 'Emergency', 'طوارئ', 'childcare', 'emergency urgent quick fast'],
            ['health_and_safety', 'Health & Safety', 'الصحة والسلامة', 'childcare', 'health safety medical emergency'],
            ['emoji_people', 'People (emoji)', 'أشخاص', 'childcare', 'people emoji social group community'],

            // ── Booking & Calendar ──
            ['calendar', 'Calendar', 'تقويم', 'booking', 'calendar date event schedule'],
            ['calendar_today', 'Calendar Today', 'تقويم اليوم', 'booking', 'calendar today date event'],
            ['event', 'Event', 'حدث', 'booking', 'event date calendar booking'],
            ['event_available', 'Event Available', 'حدث متاح', 'booking', 'event available booking confirmed'],
            ['event_busy', 'Event Busy', 'حدث مشغول', 'booking', 'event busy booked occupied'],
            ['schedule', 'Schedule', 'جدول', 'booking', 'schedule timetable plan'],
            ['clock', 'Clock', 'ساعة', 'booking', 'clock time hour minute'],
            ['timer', 'Timer', 'مؤقت', 'booking', 'timer countdown stopwatch'],
            ['date_range', 'Date Range', 'نطاق تاريخ', 'booking', 'date range period duration'],
            ['history', 'History', 'سجل', 'booking', 'history past previous log'],
            ['booking', 'Booking', 'حجز', 'booking', 'booking reservation appointment'],
            ['replay', 'Replay', 'إعادة', 'booking', 'replay repeat again rebook'],

            // ── Communication ──
            ['chat', 'Chat', 'محادثة', 'communication', 'chat talk conversation message'],
            ['chat_bubble', 'Chat Bubble', 'فقاعة محادثة', 'communication', 'chat bubble message talk'],
            ['message', 'Message', 'رسالة', 'communication', 'message text sms chat'],
            ['email', 'Email', 'بريد إلكتروني', 'communication', 'email mail envelope letter'],
            ['mail', 'Mail', 'بريد', 'communication', 'mail email envelope letter'],
            ['envelope', 'Envelope', 'ظرف', 'communication', 'envelope email mail letter'],
            ['phone', 'Phone', 'هاتف', 'communication', 'phone call contact ring'],
            ['phone_in_talk', 'Phone In Talk', 'هاتف في مكالمة', 'communication', 'phone call talking active'],
            ['support_agent', 'Support Agent', 'وكيل دعم', 'communication', 'support agent help customer service'],
            ['forum', 'Forum', 'منتدى', 'communication', 'forum discussion group community'],
            ['contact_support', 'Contact Support', 'اتصل بالدعم', 'communication', 'contact support help question'],
            ['send', 'Send', 'إرسال', 'communication', 'send submit dispatch message'],

            // ── Security ──
            ['security', 'Security', 'أمان', 'security', 'security safe protect guard'],
            ['shield', 'Shield', 'درع', 'security', 'shield protect security safe'],
            ['verified', 'Verified', 'موثق', 'security', 'verified check trusted certified'],
            ['lock', 'Lock', 'قفل', 'security', 'lock secure privacy password'],
            ['lock_open', 'Lock Open', 'قفل مفتوح', 'security', 'lock open unlock accessible'],
            ['privacy_tip', 'Privacy Tip', 'نصيحة خصوصية', 'security', 'privacy tip info confidential'],
            ['gpp_good', 'Privacy Good', 'خصوصية جيدة', 'security', 'privacy protection good secure'],
            ['user', 'User', 'مستخدم', 'security', 'user person account profile'],

            // ── Navigation & UI ──
            ['home', 'Home', 'الرئيسية', 'navigation', 'home house main start'],
            ['search', 'Search', 'بحث', 'navigation', 'search find look magnifier'],
            ['filter', 'Filter', 'تصفية', 'navigation', 'filter sort refine narrow'],
            ['filter_list', 'Filter List', 'قائمة التصفية', 'navigation', 'filter list sort refine'],
            ['settings', 'Settings', 'إعدادات', 'navigation', 'settings gear configure preferences'],
            ['dark_mode', 'Dark Mode', 'الوضع الليلي', 'navigation', 'dark mode theme night'],
            ['language', 'Language', 'لغة', 'navigation', 'language lang translate globe'],
            ['logout', 'Logout', 'تسجيل خروج', 'navigation', 'logout exit sign out leave'],
            ['login', 'Login', 'تسجيل دخول', 'navigation', 'login sign in enter access'],
            ['close', 'Close', 'إغلاق', 'navigation', 'close exit cancel dismiss x'],
            ['menu', 'Menu', 'قائمة', 'navigation', 'menu navigation drawer hamburger'],
            ['more_horiz', 'More', 'المزيد', 'navigation', 'more options horizontal menu'],
            ['arrow_back', 'Arrow Back', 'سهم للخلف', 'navigation', 'arrow back previous return'],
            ['arrow_forward', 'Arrow Forward', 'سهم للأمام', 'navigation', 'arrow forward next continue'],

            // ── Profile & People ──
            ['person', 'Person', 'شخص', 'profile', 'person user individual profile'],
            ['person_outline', 'Person Outline', 'شخص (حدود)', 'profile', 'person outline user profile'],
            ['people', 'People', 'أشخاص', 'profile', 'people group users community'],
            ['people_outline', 'People Outline', 'أشخاص (حدود)', 'profile', 'people outline group users'],
            ['group', 'Group', 'مجموعة', 'profile', 'group team community users'],
            ['badge', 'Badge', 'شارة', 'profile', 'badge role identification tag'],
            ['account_circle', 'Account Circle', 'حساب دائري', 'profile', 'account circle user profile avatar'],
            ['manage_accounts', 'Manage Accounts', 'إدارة الحسابات', 'profile', 'manage accounts admin users'],
            ['profile', 'Profile', 'ملف شخصي', 'profile', 'profile person user account'],

            // ── Status & Alerts ──
            ['check_circle', 'Check Circle', 'علامة صح', 'status', 'check circle success done complete'],
            ['check', 'Check', 'صح', 'status', 'check done complete success yes'],
            ['cancel', 'Cancel', 'إلغاء', 'status', 'cancel stop abort decline'],
            ['error', 'Error', 'خطأ', 'status', 'error problem issue bug'],
            ['error_outline', 'Error Outline', 'خطأ (حدود)', 'status', 'error outline problem issue'],
            ['warning', 'Warning', 'تحذير', 'status', 'warning alert caution danger'],
            ['warning_amber', 'Warning Amber', 'تحذير عنبري', 'status', 'warning alert caution amber'],
            ['exclamation', 'Exclamation', 'علامة تعجب', 'status', 'exclamation warning alert danger'],
            ['info', 'Info', 'معلومات', 'status', 'info information details'],
            ['info_outline', 'Info Outline', 'معلومات (حدود)', 'status', 'info outline information'],
            ['help_outline', 'Help Outline', 'مساعدة (حدود)', 'status', 'help question support faq'],
            ['done_all', 'Done All', 'تم الكل', 'status', 'done all complete finished success'],
            ['alert', 'Alert', 'تنبيه', 'status', 'alert warning caution attention'],
            ['danger', 'Danger', 'خطر', 'status', 'danger warning alert critical'],
            ['success', 'Success', 'نجاح', 'status', 'success check done complete'],
            ['call', 'Call', 'اتصال', 'communication', 'call phone contact ring'],

            // ── Payment & Finance ──
            ['payment', 'Payment', 'دفع', 'payment', 'payment pay transaction money'],
            ['account_balance', 'Account Balance', 'رصيد حساب', 'payment', 'account balance bank finance'],
            ['wallet', 'Wallet', 'محفظة', 'payment', 'wallet money pay purse'],
            ['card_giftcard', 'Gift Card', 'بطاقة هدية', 'payment', 'gift card present reward'],
            ['gift', 'Gift', 'هدية', 'payment', 'gift present present reward card'],
            ['earnings', 'Earnings', 'أرباح', 'payment', 'earnings income revenue profit'],
            ['monetization_on', 'Monetization', 'ربح', 'payment', 'monetization money cash profit'],
            ['savings', 'Savings', 'مدخرات', 'payment', 'savings bank money piggy bank'],
            ['receipt_long', 'Receipt', 'إيصال', 'payment', 'receipt invoice bill payment'],
            ['money', 'Money', 'مال', 'payment', 'money cash dollar currency'],
            ['credit_card', 'Credit Card', 'بطاقة ائتمان', 'payment', 'credit card visa mastercard payment'],
            ['credit-card', 'Credit Card (alt)', 'بطاقة ائتمان', 'payment', 'credit card hyphen alternate'],

            // ── Notifications ──
            ['notifications', 'Notifications', 'إشعارات', 'notifications', 'notifications alerts bell'],
            ['notifications_active', 'Notifications Active', 'إشعارات نشطة', 'notifications', 'notifications active alerts ringing'],
            ['bell', 'Bell', 'جرس', 'notifications', 'bell notification alert ring'],
            ['campaign', 'Campaign', 'حملة', 'notifications', 'campaign announcement broadcast megaphone'],
            ['announcement', 'Announcement', 'إعلان', 'notifications', 'announcement news update broadcast'],
            ['circle_notifications', 'Circle Notifications', 'إشعار دائري', 'notifications', 'notifications circle alert ring'],
            ['megaphone', 'Megaphone', 'مكبر صوت', 'notifications', 'megaphone announcement broadcast campaign'],
            ['x', 'X Mark', 'علامة إكس', 'notifications', 'x close cancel dismiss remove'],

            // ── Reviews & Ratings ──
            ['star', 'Star', 'نجمة', 'reviews', 'star rating favorite top'],
            ['star_outline', 'Star Outline', 'نجمة (حدود)', 'reviews', 'star outline rating review'],
            ['star_half', 'Star Half', 'نصف نجمة', 'reviews', 'star half rating semi'],
            ['rate_review', 'Rate Review', 'تقييم', 'reviews', 'rate review feedback opinion'],
            ['thumb_up', 'Thumb Up', 'إعجاب', 'reviews', 'thumb up like approve good'],

            // ── Location & Maps ──
            ['location_on', 'Location On', 'موقع', 'location', 'location on pin map place'],
            ['location_off', 'Location Off', 'موقع متوقف', 'location', 'location off disabled hidden'],
            ['place', 'Place', 'مكان', 'location', 'place location map destination'],
            ['map', 'Map', 'خريطة', 'location', 'map location navigation geography'],
            ['near_me', 'Near Me', 'قربي', 'location', 'near me close nearby vicinity'],
            ['pin', 'Pin', 'دبوس', 'location', 'pin location mark drop'],
            ['explore_nearby', 'Explore Nearby', 'استكشاف قريب', 'location', 'explore nearby close vicinity'],

            // ── Activities & Analytics ──
            ['dashboard', 'Dashboard', 'لوحة القيادة', 'activities', 'dashboard overview stats analytics'],
            ['trending_up', 'Trending Up', 'اتجاه صاعد', 'activities', 'trending up growth increase rise'],
            ['auto_graph', 'Auto Graph', 'رسم بياني', 'activities', 'graph chart analytics data stats'],
            ['analytics', 'Analytics', 'تحليلات', 'activities', 'analytics data stats insights metrics'],

            // ── Media & Files ──
            ['image', 'Image', 'صورة', 'media', 'image photo picture gallery'],
            ['photo_camera', 'Photo Camera', 'كاميرا', 'media', 'photo camera picture capture'],
            ['videocam', 'Video Camera', 'كاميرا فيديو', 'media', 'videocam video record camera'],
            ['mic', 'Microphone', 'ميكروفون', 'media', 'mic microphone audio voice record'],
            ['file_upload', 'File Upload', 'رفع ملف', 'media', 'file upload attach document'],
            ['attachment', 'Attachment', 'مرفق', 'media', 'attachment file clip pin'],
            ['description', 'Description', 'وصف', 'media', 'description document file paper'],
            ['document', 'Document', 'مستند', 'media', 'document file paper doc'],

            // ── Support & Help ──
            ['support', 'Support', 'دعم', 'support', 'support help customer service'],
            ['help', 'Help', 'مساعدة', 'support', 'help support assistance faq'],
            ['live_help', 'Live Help', 'مساعدة مباشرة', 'support', 'live help support chat'],
            ['question_answer', 'Q&A', 'سؤال وجواب', 'support', 'question answer faq help support'],
            ['faq', 'FAQ', 'أسئلة شائعة', 'support', 'faq questions answers help'],
            ['question', 'Question', 'سؤال', 'support', 'question help query ask support'],

            // ── Actions ──
            ['delete', 'Delete', 'حذف', 'actions', 'delete remove trash erase'],
            ['trash', 'Trash', 'مهملات', 'actions', 'trash delete remove discard'],
            ['edit', 'Edit', 'تعديل', 'actions', 'edit change modify update pencil'],
            ['pencil', 'Pencil', 'قلم رصاص', 'actions', 'pencil edit write draw'],
            ['add', 'Add', 'إضافة', 'actions', 'add create new plus'],
            ['plus', 'Plus', 'زائد', 'actions', 'plus add create new'],
            ['refresh', 'Refresh', 'تحديث', 'actions', 'refresh reload sync update'],
            ['sync', 'Sync', 'مزامنة', 'actions', 'sync synchronize refresh load'],
            ['share', 'Share', 'مشاركة', 'actions', 'share send forward social'],
            ['upload', 'Upload', 'رفع', 'actions', 'upload file send cloud'],
            ['download', 'Download', 'تحميل', 'actions', 'download save file get'],
            ['flag', 'Flag', 'علم', 'actions', 'flag report marker indicate'],
            ['report', 'Report', 'بلاغ', 'actions', 'report flag complaint issue'],
            ['fire', 'Fire', 'نار', 'actions', 'fire hot trend alert warning'],
            ['hand', 'Hand', 'يد', 'actions', 'hand stop help gesture offering'],

            // ── Certificates & Education ──
            ['certificate', 'Certificate', 'شهادة', 'certificates', 'certificate award credential verified'],
            ['auto_stories', 'Auto Stories', 'قصص', 'certificates', 'stories learning reading book'],
            ['psychology', 'Psychology', 'علم نفس', 'certificates', 'psychology mind brain behavior'],
            ['skills', 'Skills', 'مهارات', 'certificates', 'skills abilities talent expertise'],
            ['eye', 'Eye', 'عين', 'certificates', 'eye visibility view preview see'],

            // ── Admin & Management ──
            ['admin_panel_settings', 'Admin Panel', 'لوحة الإدارة', 'admin', 'admin panel settings management'],
            ['supervisor_account', 'Supervisor', 'مشرف', 'admin', 'supervisor admin manager overseer'],
            ['settings_applications', 'App Settings', 'إعدادات التطبيق', 'admin', 'settings applications app config'],
        ];

        $order = 0;
        foreach ($icons as [$key, $label, $labelAr, $category, $keywords]) {
            AppIcon::updateOrCreate(
                ['key' => $key],
                [
                    'label' => $label,
                    'label_ar' => $labelAr,
                    'category' => $category,
                    'keywords' => $keywords,
                    'sort_order' => $order++,
                    'is_active' => true,
                ]
            );
        }
    }
}
