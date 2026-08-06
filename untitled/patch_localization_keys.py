import re

def patch_app_localization(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    new_keys = {
        'uploading': ('Uploading...', 'جاري الرفع...'),
        'edit_profile': ('Edit Profile', 'تعديل الملف الشخصي'),
        'full_name': ('Full Name', 'الاسم الكامل'),
        'national_id_number': ('National ID Number', 'رقم الهوية الوطنية'),
        'location': ('Location', 'الموقع'),
        'email': ('Email', 'البريد الإلكتروني'),
        'phone': ('Phone', 'رقم الهاتف'),
        'verify': ('Verify', 'تحقق'),
        'error_loading_profile': ('Could not load profile data', 'تعذر تحميل بيانات الملف الشخصي'),
        'failed_to_load': ('Failed to load', 'فشل التحميل'),
        'iban_label': ('IBAN', 'رقم الحساب البنكي (IBAN)'),
        'all_day': ('All day', 'طوال اليوم'),
        'set_times': ('Set times', 'تحديد الأوقات'),
        'confirm_block_user': ('Are you sure you want to block this user?', 'هل أنت متأكد من حظر هذا المستخدم؟'),
        'no_contact_info': ('No contact information', 'لا توجد معلومات اتصال'),
        'care_filters': ('Care filters', 'فلاتر الرعاية'),
        'failed_to_load_reviews': ('Failed to load reviews', 'فشل تحميل التقييمات'),
        'faq': ('Frequently asked questions', 'الأسئلة الشائعة'),
        'followers': ('Followers', 'المتابعون'),
        'views': ('Views', 'المشاهدات'),
        'acceptance': ('Acceptance', 'القبول'),
        'response': ('Response', 'الاستجابة'),
        'bookings': ('Bookings', 'الحجوزات'),
        'completed': ('Completed', 'مكتمل'),
        'cancelled': ('Cancelled', 'ملغى'),
        'submit': ('Submit', 'إرسال'),
        'no_favorites_yet': ('No favorites yet', 'لا توجد مفضلة بعد'),
        'start_adding_favorites': ('Start adding babysitters to your favorites', 'ابدأ بإضافة الجليسات إلى مفضلتك')
    }

    # Add missing static consts
    for k in new_keys:
        static_const = f"  static const String {k} = '{k}';"
        if static_const not in content and f"String {k} =" not in content:
            match = re.search(r'(  static const String \w+ = \'[^\']+\';\n)(?!  static const String)', content)
            if match:
                content = content[:match.end()] + static_const + "\n" + content[match.end():]

    # Add to _en map
    for k, (en_val, ar_val) in new_keys.items():
        if f"'{k}':" not in content and f"    {k}:" not in content:
            # We must be careful not to add duplicate keys. The script already checks 'k:' in content.
            en_entry = f"    {k}: '{en_val}',"
            match = re.search(r'(  static const Map<String, String> _en = \{.*?)(\n  \};)', content, re.DOTALL)
            if match:
                content = content[:match.end(1)] + "\n" + en_entry + content[match.start(2):]

    # Add to _ar map
    for k, (en_val, ar_val) in new_keys.items():
        # Actually I need to re-read to avoid checking the en part.
        pass
    
    # Better approach for maps:
    for k, (en_val, ar_val) in new_keys.items():
        # _en
        match_en = re.search(r'(  static const Map<String, String> _en = \{.*?)(  \};)', content, re.DOTALL)
        if match_en and f"{k}:" not in match_en.group(1):
            content = content[:match_en.start(2)] + f"    {k}: '{en_val}',\n" + content[match_en.start(2):]
            
        # _ar
        match_ar = re.search(r'(  static const Map<String, String> _ar = \{.*?)(  \};)', content, re.DOTALL)
        if match_ar and f"{k}:" not in match_ar.group(1):
            content = content[:match_ar.start(2)] + f"    {k}: '{ar_val}',\n" + content[match_ar.start(2):]

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
        
    print("Successfully patched app_localization.dart with missing keys")

if __name__ == '__main__':
    patch_app_localization('/home/younis/AndroidStudioProjects/setter project/untitled/lib/core/localization/app_localization.dart')
