import re

def patch_app_localization(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    key = "upload_failed"
    en_val = "Upload failed. Please try again."
    ar_val = "فشل الرفع. يرجى المحاولة مرة أخرى."

    # 1. Add static const string
    static_const = f"  static const String {key} = '{key}';"
    if static_const not in content:
        match = re.search(r'(  static const String \w+ = \'[^\']+\';\n)(?!  static const String)', content)
        if match:
            content = content[:match.end()] + static_const + "\n" + content[match.end():]

    # 2. Add to _en map
    en_entry = f"    {key}: '{en_val}',"
    if en_entry not in content:
        match = re.search(r'(  static const Map<String, String> _en = \{.*?)(\n  \};)', content, re.DOTALL)
        if match:
            content = content[:match.end(1)] + "\n" + en_entry + content[match.start(2):]

    # 3. Add to _ar map
    ar_entry = f"    {key}: '{ar_val}',"
    if ar_entry not in content:
        match = re.search(r'(  static const Map<String, String> _ar = \{.*?)(\n  \};)', content, re.DOTALL)
        if match:
            content = content[:match.end(1)] + "\n" + ar_entry + content[match.start(2):]

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
        
    print(f"Successfully added {key}")

if __name__ == '__main__':
    patch_app_localization('/home/younis/AndroidStudioProjects/setter project/untitled/lib/core/localization/app_localization.dart')
