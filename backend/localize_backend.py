import os
import re
import json

translations = {
    "{$count} notifications deleted.": ("notifications_deleted", "تم حذف {$count} إشعار/إشعارات."),
    "{$count} notifications marked as read.": ("notifications_marked_read", "تم تحديد {$count} إشعار/إشعارات كمقروءة."),
    "Account deleted.": ("account_deleted", "تم حذف الحساب."),
    "Already marked as helpful.": ("already_marked_helpful", "تم وضع علامة مفيد مسبقاً."),
    "Avatar updated successfully": ("avatar_updated", "تم تحديث الصورة الشخصية بنجاح."),
    "Babysitter profile not found.": ("sitter_profile_not_found", "لم يتم العثور على ملف الجليسة."),
    "Cannot clear availability while you have active bookings.": ("cannot_clear_availability_active_bookings", "لا يمكن مسح أوقات التوفر أثناء وجود حجوزات نشطة."),
    "Cannot delete account while you have active bookings. Please cancel or complete them first.": ("cannot_delete_account_active_bookings", "لا يمكن حذف الحساب أثناء وجود حجوزات نشطة. يرجى إلغاؤها أو إكمالها أولاً."),
    "Cannot delete account while you have pending earnings. Please contact support to process your payouts before deleting your account.": ("cannot_delete_account_pending_earnings", "لا يمكن حذف الحساب أثناء وجود أرباح معلقة. يرجى التواصل مع الدعم لمعالجة مدفوعاتك قبل الحذف."),
    "Cannot reduce included children. You have an active booking with": ("cannot_reduce_included_children", "لا يمكن تقليل عدد الأطفال المشمولين. لديك حجز نشط مع"),
    "Cannot reduce max children limit. You have an active booking with": ("cannot_reduce_max_children", "لا يمكن تقليل الحد الأقصى للأطفال. لديك حجز نشط مع"),
    "Cannot remove availability on": ("cannot_remove_availability_on", "لا يمكن إزالة التوفر في"),
    "Cannot start conversation with yourself": ("cannot_start_conversation_with_self", "لا يمكنك بدء محادثة مع نفسك."),
    "Conversation archived": ("conversation_archived", "تم أرشفة المحادثة."),
    "Conversation deleted": ("conversation_deleted", "تم حذف المحادثة."),
    "Conversation unarchived": ("conversation_unarchived", "تم إلغاء أرشفة المحادثة."),
    "Counter proposal submitted.": ("counter_proposal_submitted", "تم تقديم العرض المضاد."),
    "Device registered.": ("device_registered", "تم تسجيل الجهاز."),
    "Device unregistered.": ("device_unregistered", "تم إلغاء تسجيل الجهاز."),
    "Failed to send verification code. Please try again.": ("failed_send_verification", "فشل إرسال رمز التحقق. يرجى المحاولة مرة أخرى."),
    "FAQ created.": ("faq_created", "تم إنشاء السؤال الشائع."),
    "FAQ deleted.": ("faq_deleted", "تم حذف السؤال الشائع."),
    "FAQ updated.": ("faq_updated", "تم تحديث السؤال الشائع."),
    "File uploaded successfully": ("file_uploaded_successfully", "تم رفع الملف بنجاح."),
    "Image uploaded successfully": ("image_uploaded_successfully", "تم رفع الصورة بنجاح."),
    "Invalid or expired verification code.": ("invalid_expired_verification_code", "رمز التحقق غير صالح أو منتهي الصلاحية."),
    "Languages retrieved successfully": ("languages_retrieved", "تم جلب اللغات بنجاح."),
    "Logged out.": ("logged_out", "تم تسجيل الخروج."),
    "Marked as helpful.": ("marked_helpful", "تم تحديد كـ مفيد."),
    "Marked as read": ("marked_read", "تم التحديد كمقروء."),
    "Message deleted": ("message_deleted", "تم حذف الرسالة."),
    "Message does not belong to this conversation": ("message_not_in_conversation", "الرسالة لا تنتمي لهذه المحادثة."),
    "Messages can only be edited within 30 minutes of sending": ("message_edit_timeout", "يمكن تعديل الرسائل فقط خلال 30 دقيقة من إرسالها."),
    "New availability hours would conflict with an active booking on": ("availability_conflict_active_booking", "أوقات التوفر الجديدة تتعارض مع حجز نشط في"),
    "No review found.": ("no_review_found", "لم يتم العثور على تقييم."),
    "No review to report.": ("no_review_to_report", "لا يوجد تقييم للإبلاغ عنه."),
    "Notification deleted.": ("notification_deleted", "تم حذف الإشعار."),
    "Notification marked as read.": ("notification_marked_read", "تم تحديد الإشعار كمقروء."),
    "Notification not found.": ("notification_not_found", "لم يتم العثور على الإشعار."),
    "Notification settings updated.": ("notification_settings_updated", "تم تحديث إعدادات الإشعارات."),
    "OK": ("ok", "حسناً"),
    "Only babysitters can access analytics.": ("only_sitters_access_analytics", "فقط الجليسات يمكنهن الوصول إلى الإحصائيات."),
    "Only babysitters can access earnings data.": ("only_sitters_access_earnings", "فقط الجليسات يمكنهن الوصول إلى بيانات الأرباح."),
    "Only babysitters can access the dashboard.": ("only_sitters_access_dashboard", "فقط الجليسات يمكنهن الوصول إلى لوحة التحكم."),
    "Only JSON requests are accepted.": ("only_json_requests_accepted", "يتم قبول طلبات JSON فقط."),
    "Only pending or confirmed bookings can be rescheduled.": ("only_pending_confirmed_rescheduled", "يمكن فقط إعادة جدولة الحجوزات المعلقة أو المؤكدة."),
    "Only the requester can cancel.": ("only_requester_can_cancel", "فقط مقدم الطلب يمكنه الإلغاء."),
    "Password is incorrect.": ("password_incorrect", "كلمة المرور غير صحيحة."),
    "Profile updated successfully.": ("profile_updated", "تم تحديث الملف الشخصي بنجاح."),
    "Reaction not found": ("reaction_not_found", "التفاعل غير موجود."),
    "Reaction removed": ("reaction_removed", "تمت إزالة التفاعل."),
    "Reply submitted successfully.": ("reply_submitted", "تم تقديم الرد بنجاح."),
    "Reschedule request accepted.": ("reschedule_request_accepted", "تم قبول طلب إعادة الجدولة."),
    "Reschedule request cancelled.": ("reschedule_request_cancelled", "تم إلغاء طلب إعادة الجدولة."),
    "Reschedule request rejected.": ("reschedule_request_rejected", "تم رفض طلب إعادة الجدولة."),
    "Reschedule request submitted.": ("reschedule_request_submitted", "تم تقديم طلب إعادة الجدولة."),
    "Review reported. We will review it shortly.": ("review_reported", "تم الإبلاغ عن التقييم. سنقوم بمراجعته قريباً."),
    "Sitter approved successfully.": ("sitter_approved", "تم الموافقة على الجليسة بنجاح."),
    "Sitter is not in review status.": ("sitter_not_in_review", "الجليسة ليست قيد المراجعة."),
    "Sitter profile created successfully.": ("sitter_profile_created", "تم إنشاء ملف الجليسة بنجاح."),
    "Sitter rejected.": ("sitter_rejected", "تم رفض الجليسة."),
    "Template updated.": ("template_updated", "تم تحديث القالب."),
    "There is already an active reschedule request for this booking.": ("active_reschedule_request_exists", "يوجد بالفعل طلب إعادة جدولة نشط لهذا الحجز."),
    "This booking has no review to reply to.": ("booking_no_review_reply", "هذا الحجز لا يحتوي على تقييم للرد عليه."),
    "This request is no longer open.": ("request_no_longer_open", "هذا الطلب لم يعد مفتوحاً."),
    "Unauthorized.": ("unauthorized", "غير مصرح."),
    "Unauthorized. Admin access required.": ("unauthorized_admin", "غير مصرح. مطلوب صلاحيات الإدارة."),
    "User is not a babysitter.": ("user_not_babysitter", "المستخدم ليس جليسة."),
    "User reinstated.": ("user_reinstated", "تم إعادة تفعيل المستخدم."),
    "User suspended.": ("user_suspended", "تم إيقاف المستخدم."),
    "Verification failed. Please try again.": ("verification_failed", "فشل التحقق. يرجى المحاولة مرة أخرى."),
    "You already have a sitter profile.": ("already_have_sitter_profile", "لديك بالفعل ملف جليسة."),
    "You cannot accept your own request.": ("cannot_accept_own_request", "لا يمكنك قبول طلبك الخاص."),
    "You cannot counter your own request.": ("cannot_counter_own_request", "لا يمكنك تقديم عرض مضاد لطلبك الخاص."),
    "You cannot reject your own request.": ("cannot_reject_own_request", "لا يمكنك رفض طلبك الخاص."),
    "You can only delete your own messages": ("can_only_delete_own_messages", "يمكنك فقط حذف رسائلك الخاصة."),
    "You need a parent profile to access this feature.": ("need_parent_profile", "تحتاج إلى حساب ولي أمر للوصول إلى هذه الميزة."),
    "You need a sitter profile to access this feature.": ("need_sitter_profile", "تحتاج إلى حساب جليسة للوصول إلى هذه الميزة."),
    "Your account has been suspended. Please contact support.": ("account_suspended", "تم تعليق حسابك. يرجى التواصل مع الدعم."),
    "Your account has been suspended. Please contact support for more information.": ("account_suspended_more_info", "تم تعليق حسابك. يرجى التواصل مع الدعم لمزيد من المعلومات."),
    "Your account is suspended. You cannot change your availability.": ("account_suspended_availability", "حسابك معلق. لا يمكنك تغيير أوقات توفرك."),
    "Your account is suspended. You cannot edit your profile.": ("account_suspended_edit_profile", "حسابك معلق. لا يمكنك تعديل ملفك الشخصي."),
    "Your account is suspended. You cannot register as a babysitter.": ("account_suspended_register", "حسابك معلق. لا يمكنك التسجيل كجليسة."),
    "Your password has been reset successfully.": ("password_reset_successfully", "تمت إعادة تعيين كلمة المرور بنجاح.")
}

def build_php_array(mapping, idx):
    lines = ["<?php", "", "return ["]
    for eng, tup in mapping.items():
        key = tup[0]
        val = tup[idx]
        if '{$count}' in val:
            val = val.replace('{$count}', ':count')
        val = val.replace("'", "\\'")
        lines.append(f"    '{key}' => '{val}',")
    lines.append("];")
    lines.append("")
    return "\n".join(lines)

en_file_content = build_php_array(translations, 0)
ar_file_content = build_php_array(translations, 1)

backend_dir = "/home/younis/AndroidStudioProjects/setter project/backend"

# Ensure lang directories exist
os.makedirs(f"{backend_dir}/lang/en", exist_ok=True)
os.makedirs(f"{backend_dir}/lang/ar", exist_ok=True)

with open(f"{backend_dir}/lang/en/messages.php", "w") as f:
    f.write(en_file_content)

with open(f"{backend_dir}/lang/ar/messages.php", "w") as f:
    f.write(ar_file_content)

# Now, iterate over all files and replace
def process_file(filepath):
    with open(filepath, "r") as f:
        content = f.read()

    changed = False
    
    for eng, tup in translations.items():
        key = tup[0]
        # Replace occurrences in response()->json(['message' => '...'])
        # Or abort(..., '...')
        
        # We need to be careful with quotes. The original might use single or double.
        # We'll use regex to find exactly the string.
        
        # Escape for regex
        escaped_eng = re.escape(eng)
        
        # Look for 'message' => '...'
        pattern = re.compile(r"(['\"]message['\"]\s*=>\s*)['\"]" + escaped_eng + r"['\"]")
        new_content = pattern.sub(r"\1__('messages." + key + r"')", content)
        if new_content != content:
            content = new_content
            changed = True
            
        # Look for abort(..., '...')
        pattern_abort = re.compile(r"(abort\([^,]+,\s*)['\"]" + escaped_eng + r"['\"]")
        new_content = pattern_abort.sub(r"\1__('messages." + key + r"')", content)
        if new_content != content:
            content = new_content
            changed = True

        # Look for explicitly returning the string directly if needed, but above handles the common ones.

    if changed:
        with open(filepath, "w") as f:
            f.write(content)
        print(f"Updated {filepath}")

for root, dirs, files in os.walk(f"{backend_dir}/app"):
    for file in files:
        if file.endswith(".php"):
            process_file(os.path.join(root, file))

print("Localization script completed.")
