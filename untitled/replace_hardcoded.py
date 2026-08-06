import os
import re

def replace_hardcoded(directory):
    mapping = {
        'Uploading...': 'uploading',
        'Edit Profile': 'edit_profile',
        'Full Name': 'full_name',
        'National ID Number': 'national_id_number',
        'Location': 'location',
        'Email': 'email',
        'Phone': 'phone',
        'Verify': 'verify',
        'Could not load profile data': 'error_loading_profile',
        'Failed to load': 'failed_to_load',
        'IBAN': 'iban_label',
        'All day': 'all_day',
        'Set times': 'set_times',
        'Are you sure you want to block this user?': 'confirm_block_user',
        'No contact information': 'no_contact_info',
        'Care filters': 'care_filters',
        'Failed to load reviews': 'failed_to_load_reviews',
        'Frequently asked questions': 'faq',
        'Followers': 'followers',
        'Views': 'views',
        'Acceptance': 'acceptance',
        'Response': 'response',
        'Bookings': 'bookings',
        'Completed': 'completed',
        'Cancelled': 'cancelled',
        'Submit': 'submit',
        'No favorites yet': 'no_favorites_yet',
        'Start adding babysitters to your favorites': 'start_adding_favorites'
    }
    
    for root, _, files in os.walk(directory):
        for file in files:
            if not file.endswith('.dart') or file.endswith('.g.dart') or file.endswith('.freezed.dart'):
                continue
                
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
                
            original_content = content
            
            for hard_str, loc_key in mapping.items():
                # Replace Text('String') -> Text(strings[AppLocalization.key] ?? 'String')
                # Be careful with the quotes.
                pattern_text1 = r"Text\('" + re.escape(hard_str) + r"'"
                repl_text1 = r"Text(strings[AppLocalization." + loc_key + r"] ?? '" + hard_str + r"'"
                content = re.sub(pattern_text1, repl_text1, content)
                
                pattern_text2 = r'Text\("' + re.escape(hard_str) + r'"'
                repl_text2 = r"Text(strings[AppLocalization." + loc_key + r"] ?? '" + hard_str + r"'"
                content = re.sub(pattern_text2, repl_text2, content)
                
                # Replace label: 'String' -> label: strings[AppLocalization.key] ?? 'String'
                pattern_label1 = r"label:\s*'" + re.escape(hard_str) + r"'"
                repl_label1 = r"label: strings[AppLocalization." + loc_key + r"] ?? '" + hard_str + r"'"
                content = re.sub(pattern_label1, repl_label1, content)
                
                # title: 'String'
                pattern_title1 = r"title:\s*'" + re.escape(hard_str) + r"'"
                repl_title1 = r"title: strings[AppLocalization." + loc_key + r"] ?? '" + hard_str + r"'"
                content = re.sub(pattern_title1, repl_title1, content)
                
                # hintText: 'String'
                pattern_hint1 = r"hintText:\s*'" + re.escape(hard_str) + r"'"
                repl_hint1 = r"hintText: strings[AppLocalization." + loc_key + r"] ?? '" + hard_str + r"'"
                content = re.sub(pattern_hint1, repl_hint1, content)

            if content != original_content:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"Patched {filepath}")

if __name__ == '__main__':
    replace_hardcoded('/home/younis/AndroidStudioProjects/setter project/untitled/lib')
