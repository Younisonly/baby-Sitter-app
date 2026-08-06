<!DOCTYPE html>
<html lang="{{ app()->getLocale() }}" dir="{{ app()->getLocale() === 'ar' ? 'rtl' : 'ltr' }}">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ __('auth.otp_email_subject') }}</title>
</head>
<body style="margin:0;padding:0;background-color:#f4f6fb;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#f4f6fb;padding:40px 16px">
        <tr>
            <td align="center">
                <!-- Brand -->
                <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:520px;margin-bottom:24px">
                    <tr>
                        <td align="center" style="padding-bottom:16px">
                            <div style="display:inline-block;width:44px;height:44px;background:linear-gradient(135deg,#6366f1,#8b5cf6);border-radius:12px;vertical-align:middle"></div>
                            <span style="font-size:22px;font-weight:800;color:#1e293b;letter-spacing:-0.3px;padding-inline-start:10px;vertical-align:middle">BabySitter</span>
                        </td>
                    </tr>
                </table>

                <!-- Card -->
                <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:520px;background-color:#ffffff;border-radius:20px;overflow:hidden;border:1px solid #e8ecf4;box-shadow:0 8px 30px rgba(30,41,59,0.06)">
                    <tr>
                        <td style="background:linear-gradient(135deg,#6366f1,#8b5cf6);padding:36px 28px;text-align:center">
                            <p style="margin:0 0 8px;color:#c7d2fe;font-size:13px;font-weight:600;letter-spacing:0.6px;text-transform:uppercase">{{ __('auth.otp_email_kicker') }}</p>
                            <h1 style="margin:0;color:#ffffff;font-size:24px;font-weight:800;line-height:1.3">{{ __('auth.otp_email_title') }}</h1>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding:36px 28px">
                            <p style="margin:0 0 6px;color:#475569;font-size:16px;line-height:1.6">{{ __('auth.otp_email_hello', ['name' => $userName]) }}</p>
                            <p style="margin:0 0 28px;color:#64748b;font-size:15px;line-height:1.7">{{ __('auth.otp_email_body') }}</p>

                            <div style="text-align:center;margin:0 0 28px">
                                <div style="display:inline-block;background:#f1f5f9;border:2px dashed #c7d2fe;border-radius:16px;padding:22px 40px;letter-spacing:14px;font-size:40px;font-weight:800;color:#6366f1;font-family:'SF Mono',Consolas,Menlo,monospace" dir="ltr">{{ $otp }}</div>
                            </div>

                            <p style="margin:0 0 8px;color:#94a3b8;font-size:13px;line-height:1.6">{{ __('auth.otp_email_expiry') }}</p>
                            <p style="margin:0;color:#94a3b8;font-size:13px;line-height:1.6">🔒 {{ __('auth.otp_email_security') }}</p>
                        </td>
                    </tr>
                </table>

                <!-- Footer -->
                <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:520px;margin-top:24px">
                    <tr>
                        <td align="center" style="color:#94a3b8;font-size:12px;line-height:1.7">
                            {{ __('auth.otp_email_footer') }}
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
