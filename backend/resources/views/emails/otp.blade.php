<!DOCTYPE html>
<html lang="{{ app()->getLocale() }}" dir="{{ app()->getLocale() === 'ar' ? 'rtl' : 'ltr' }}">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="x-apple-disable-message-reformatting">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <title>{{ __('auth.otp_email_subject') }}</title>
    <style>
        @media only screen and (max-width: 600px) {
            .container { width: 100% !important; }
            .card { border-radius: 14px !important; }
            .card-inner { padding: 24px 18px !important; }
            .header { padding: 26px 18px !important; }
            .otp-box { padding: 18px 24px !important; letter-spacing: 10px !important; font-size: 32px !important; }
            .brand-text { font-size: 19px !important; }
            .body-text { font-size: 15px !important; }
            .title-text { font-size: 21px !important; }
        }
        @media (prefers-color-scheme: dark) {
            .card-bg { background-color: #0f172a !important; border-color: #1e293b !important; }
            .card-inner { background-color: #0f172a !important; }
            .title-text { color: #f1f5f9 !important; }
            .body-text, .hello-text { color: #cbd5e1 !important; }
            .otp-box { background-color: #1e293b !important; border-color: #4f46e5 !important; }
            .footer-text { color: #64748b !important; }
        }
    </style>
</head>
<body style="margin:0;padding:0;background-color:#eef1f8;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#eef1f8;padding:32px 12px">
        <tr>
            <td align="center">
                <!-- Brand -->
                <table role="presentation" class="container" width="100%" cellpadding="0" cellspacing="0" style="max-width:560px;margin-bottom:20px">
                    <tr>
                        <td align="center" style="padding-bottom:12px">
                            <span style="font-size:20px;font-weight:800;color:#1e293b;letter-spacing:-0.3px">BabySitter</span>
                        </td>
                    </tr>
                </table>

                <!-- Card -->
                <table role="presentation" class="container card-bg" width="100%" cellpadding="0" cellspacing="0" style="max-width:560px;background-color:#ffffff;border-radius:22px;overflow:hidden;border:1px solid #e3e8f2;box-shadow:0 12px 40px rgba(30,41,59,0.08)">
                    <tr>
                        <td class="header" style="background:linear-gradient(135deg,#6366f1,#8b5cf6);padding:38px 30px;text-align:center">
                            <div style="display:inline-block;width:48px;height:48px;background:rgba(255,255,255,0.16);border-radius:14px;margin-bottom:14px;border:1px solid rgba(255,255,255,0.25)"></div>
                            <p style="margin:0 0 6px;color:#c7d2fe;font-size:12px;font-weight:700;letter-spacing:1.2px;text-transform:uppercase">{{ __('auth.otp_email_kicker') }}</p>
                            <h1 class="title-text" style="margin:0;color:#ffffff;font-size:24px;font-weight:800;line-height:1.35">{{ __('auth.otp_email_title') }}</h1>
                        </td>
                    </tr>
                    <tr>
                        <td class="card-inner" style="padding:38px 30px;background-color:#ffffff">
                            <p class="hello-text" style="margin:0 0 8px;color:#1e293b;font-size:17px;font-weight:700;line-height:1.5">{{ __('auth.otp_email_hello', ['name' => $userName]) }}</p>
                            <p class="body-text" style="margin:0 0 26px;color:#64748b;font-size:15px;line-height:1.8">{{ __('auth.otp_email_body') }}</p>

                            <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin:0 0 26px">
                                <tr>
                                    <td align="center" style="padding:0 8px">
                                        <div class="otp-box" style="display:inline-block;background:#f4f6fc;border:2px dashed #a5b4fc;border-radius:16px;padding:20px 38px;letter-spacing:14px;font-size:38px;font-weight:800;color:#6366f1;font-family:'SF Mono',Consolas,Menlo,monospace" dir="ltr">{{ $otp }}</div>
                                    </td>
                                </tr>
                            </table>

                            <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#f8fafc;border-radius:12px;margin:0 0 22px">
                                <tr>
                                    <td style="padding:14px 16px;font-size:13px;color:#94a3b8;line-height:1.7">
                                        {{ __('auth.otp_email_expiry') }}
                                    </td>
                                </tr>
                            </table>

                            <p style="margin:0;color:#94a3b8;font-size:12.5px;line-height:1.7">🔒 {{ __('auth.otp_email_security') }}</p>
                        </td>
                    </tr>
                </table>

                <!-- Footer -->
                <table role="presentation" class="container" width="100%" cellpadding="0" cellspacing="0" style="max-width:560px;margin-top:22px">
                    <tr>
                        <td align="center" class="footer-text" style="color:#94a3b8;font-size:12px;line-height:1.8;padding:0 12px">
                            {{ __('auth.otp_email_footer') }}
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
