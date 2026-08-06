import re

def patch_app_localization(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # We only add these as raw string keys to the maps, not as static consts, 
    # because they come dynamically from the backend or exceptions.
    
    en_values = {
        "The provided credentials are incorrect.": "The provided credentials are incorrect.",
        "The provided credentials are incorrect": "The provided credentials are incorrect.",
        "unexpected erro": "An unexpected error occurred.",
        "An unexpected error occurred.": "An unexpected error occurred.",
        "An unexpected error occurred": "An unexpected error occurred.",
        "Google sign-in was cancelled": "Google sign-in was cancelled.",
        "Failed to get Google ID token": "Failed to get Google ID token.",
        "Failed to get Firebase ID token": "Failed to get Firebase ID token.",
        "User cancelled login": "User cancelled login."
    }
    
    ar_values = {
        "The provided credentials are incorrect.": "البيانات المقدمة غير صحيحة.",
        "The provided credentials are incorrect": "البيانات المقدمة غير صحيحة.",
        "unexpected erro": "حدث خطأ غير متوقع.",
        "An unexpected error occurred.": "حدث خطأ غير متوقع.",
        "An unexpected error occurred": "حدث خطأ غير متوقع.",
        "Google sign-in was cancelled": "تم إلغاء تسجيل الدخول عبر جوجل.",
        "Failed to get Google ID token": "فشل في الحصول على رمز جوجل.",
        "Failed to get Firebase ID token": "فشل في الحصول على رمز المصادقة.",
        "User cancelled login": "تم إلغاء تسجيل الدخول."
    }

    # 1. Add to _en map
    en_entries = "\\n".join([f"    '{k}': '{v}'," for k, v in en_values.items() if f"'{k}':" not in content])
    if en_entries:
        match = re.search(r'(  static const Map<String, String> _en = \\{.*?)(\\n  \\};)', content, re.DOTALL)
        if match:
            content = content[:match.end(1)] + "\\n" + en_entries + content[match.start(2):]

    # 2. Add to _ar map
    ar_entries = "\\n".join([f"    '{k}': '{v}'," for k, v in ar_values.items() if f"'{k}':" not in content])
    if ar_entries:
        match = re.search(r'(  static const Map<String, String> _ar = \\{.*?)(\\n  \\};)', content, re.DOTALL)
        if match:
            content = content[:match.end(1)] + "\\n" + ar_entries + content[match.start(2):]

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
        
    print("Successfully patched app_localization.dart with raw error strings")

if __name__ == '__main__':
    patch_app_localization('/home/younis/AndroidStudioProjects/setter project/untitled/lib/core/localization/app_localization.dart')
