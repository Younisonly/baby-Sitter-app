<!DOCTYPE html>
<html lang="{{ app()->getLocale() }}">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ __('auth.otp_email_subject') }}</title>
</head>
<body style="margin:0;padding:0;background-color:#f8fafc;font-family:Arial,Helvetica,sans-serif">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#f8fafc;padding:32px 16px">
        <tr>
            <td align="center">
                <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:480px;background-color:#ffffff;border-radius:16px;overflow:hidden;border:1px solid #e2e8f0">
                    <tr>
                        <td style="background:linear-gradient(135deg,#6366f1,#8b5cf6);padding:32px 24px;text-align:center">
                            <h1 style="margin:0;color:#ffffff;font-size:20px;font-weight:bold">{{ __('auth.otp_email_title') }}</h1>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding:32px 24px;text-align:center">
                            <p style="margin:0 0 16px;color:#475569;font-size:15px;line-height:1.6">{{ __('auth.otp_email_body') }}</p>
                            <div style="margin:24px 0;padding:16px;background-color:#f1f5f9;border-radius:12px;font-size:34px;font-weight:bold;letter-spacing:10px;color:#6366f1">{{ $otp }}</div>
                            <p style="margin:0;color:#94a3b8;font-size:13px;line-height:1.6">{{ __('auth.otp_email_expiry') }}</p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
