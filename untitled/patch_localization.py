import re
import sys

def patch_app_localization(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    keys = [
        "connection_timeout", "request_cancelled", "unexpected_error", "processing_error",
        "no_response", "bad_request", "unauthorized", "access_denied", "resource_not_found",
        "conflict", "validation_error", "too_many_requests", "internal_server_error",
        "bad_gateway", "service_unavailable", "general_error", "search_by_name",
        "minimum_rating", "sort_by", "no_matching_sitters", "no_matching_sitters_subtitle",
        "price_low", "price_high", "newest"
    ]
    
    en_values = {
        "connection_timeout": "Connection timeout. Please try again.",
        "request_cancelled": "Request was cancelled.",
        "unexpected_error": "An unexpected error occurred.",
        "processing_error": "Something went wrong processing the response. Please try again.",
        "no_response": "No response from server.",
        "bad_request": "Bad request. Please check your input.",
        "unauthorized": "Unauthorized. Please login again.",
        "access_denied": "Access denied.",
        "resource_not_found": "Resource not found.",
        "conflict": "Conflict. Resource already exists.",
        "validation_error": "Validation error. Please check your input.",
        "too_many_requests": "Too many requests. Please try again later.",
        "internal_server_error": "Internal server error. Please try again later.",
        "bad_gateway": "Bad gateway. Please try again later.",
        "service_unavailable": "Service unavailable. Please try again later.",
        "general_error": "An error occurred. Please try again.",
        "search_by_name": "Search by name",
        "minimum_rating": "Minimum rating",
        "sort_by": "Sort by",
        "no_matching_sitters": "No matching sitters",
        "no_matching_sitters_subtitle": "Try another search or category.",
        "price_low": "Price: Low to High",
        "price_high": "Price: High to Low",
        "newest": "Newest"
    }
    
    ar_values = {
        "connection_timeout": "انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى.",
        "request_cancelled": "تم إلغاء الطلب.",
        "unexpected_error": "حدث خطأ غير متوقع.",
        "processing_error": "حدث خطأ أثناء معالجة الاستجابة. يرجى المحاولة مرة أخرى.",
        "no_response": "لا توجد استجابة من الخادم.",
        "bad_request": "طلب غير صالح. يرجى التحقق من إدخالك.",
        "unauthorized": "غير مصرح. يرجى تسجيل الدخول مرة أخرى.",
        "access_denied": "الوصول مرفوض.",
        "resource_not_found": "المورد غير موجود.",
        "conflict": "تعارض. المورد موجود بالفعل.",
        "validation_error": "خطأ في التحقق. يرجى التحقق من إدخالك.",
        "too_many_requests": "طلبات كثيرة جدًا. يرجى المحاولة لاحقًا.",
        "internal_server_error": "خطأ في الخادم الداخلي. يرجى المحاولة لاحقًا.",
        "bad_gateway": "بوابة غير صالحة. يرجى المحاولة لاحقًا.",
        "service_unavailable": "الخدمة غير متوفرة. يرجى المحاولة لاحقًا.",
        "general_error": "حدث خطأ. يرجى المحاولة مرة أخرى.",
        "search_by_name": "البحث بالاسم",
        "minimum_rating": "الحد الأدنى للتقييم",
        "sort_by": "ترتيب حسب",
        "no_matching_sitters": "لا توجد جليسات مطابقة",
        "no_matching_sitters_subtitle": "جرب بحثًا أو فئة أخرى.",
        "price_low": "السعر: من الأقل للأعلى",
        "price_high": "السعر: من الأعلى للأقل",
        "newest": "الأحدث"
    }

    # 1. Add static const strings
    static_consts = "\n".join([f"  static const String {k} = '{k}';" for k in keys if f"static const String {k}" not in content])
    if static_consts:
        # Find the end of the static const declarations
        match = re.search(r'(  static const String \w+ = \'[^\']+\';\n)(?!  static const String)', content)
        if match:
            content = content[:match.end()] + static_consts + "\n" + content[match.end():]

    # 2. Add to _en map
    en_entries = "\n".join([f"    {k}: '{v}'," for k, v in en_values.items() if f"    {k}: " not in content])
    if en_entries:
        match = re.search(r'(  static const Map<String, String> _en = \{.*?)(\n  \};)', content, re.DOTALL)
        if match:
            content = content[:match.end(1)] + "\n" + en_entries + content[match.start(2):]

    # 3. Add to _ar map
    ar_entries = "\n".join([f"    {k}: '{v}'," for k, v in ar_values.items() if f"    {k}: " not in content])
    if ar_entries:
        match = re.search(r'(  static const Map<String, String> _ar = \{.*?)(\n  \};)', content, re.DOTALL)
        if match:
            content = content[:match.end(1)] + "\n" + ar_entries + content[match.start(2):]

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
        
    print("Successfully patched app_localization.dart")

if __name__ == '__main__':
    patch_app_localization('/home/younis/AndroidStudioProjects/setter project/untitled/lib/core/localization/app_localization.dart')
