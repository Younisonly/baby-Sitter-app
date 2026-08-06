<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * SMS delivery abstraction, built to KSA-market best practices.
 *
 * The driver is chosen from config('services.sms.driver'):
 *  - 'log' (default): writes the code to the log — used in development and
 *    until a real provider's keys are configured.
 *  - 'twilio': Twilio Verify-compatible sender (works in KSA via Twilio SMS).
 *  - 'unifonic': Unifonic (Jordan/KSA) REST API.
 *  - '4jawaly': Saudi 4jawaly SMS gateway.
 *  - 'whatsapp': placeholder — extend with the chosen WhatsApp Business API.
 *
 * To activate a provider, set SERVICES_SMS_DRIVER and the matching keys in
 * config/services.php. The send() method never throws to the caller: delivery
 * failures are logged so auth flows degrade gracefully.
 */
class SmsProvider
{
    public function send(int|string $userId, string $otp): void
    {
        $driver = config('services.sms.driver', 'log');
        $phone = $this->resolvePhone($userId);

        try {
            match ($driver) {
                'twilio' => $this->sendViaTwilio($phone, $otp),
                'unifonic' => $this->sendViaUnifonic($phone, $otp),
                '4jawaly' => $this->sendVia4jawaly($phone, $otp),
                'whatsapp' => $this->sendViaWhatsApp($phone, $otp),
                default => $this->logOtp($userId, $phone, $otp),
            };
        } catch (\Throwable $e) {
            Log::error('SMS send failed', [
                'driver' => $driver,
                'phone' => $this->mask($phone),
                'error' => $e->getMessage(),
            ]);

            $this->logOtp($userId, $phone, $otp);
        }
    }

    private function resolvePhone(int|string $userId): ?string
    {
        $user = \App\Models\User::find($userId);

        return $user?->phone;
    }

    private function logOtp(int|string $userId, ?string $phone, string $otp): void
    {
        Log::info('OTP generated (log SMS driver — configure SERVICES_SMS_DRIVER for real delivery)', [
            'user_id' => $userId,
            'phone' => $this->mask($phone),
            'otp' => $otp,
        ]);
    }

    private function sendViaTwilio(?string $phone, string $otp): void
    {
        $sid = config('services.sms.twilio_sid');
        $token = config('services.sms.twilio_token');
        $from = config('services.sms.twilio_from');

        Http::withBasicAuth($sid, $token)
            ->asForm()
            ->post("https://api.twilio.com/2010-04-01/Accounts/{$sid}/Messages.json", [
                'To' => $this->normalizeKsaPhone($phone),
                'From' => $from,
                'Body' => "Your babysitter app verification code is: {$otp}. It expires in 5 minutes.",
            ])
            ->throw();
    }

    private function sendViaUnifonic(?string $phone, string $otp): void
    {
        Http::asForm()
            ->post('https://el.cloud.unifonic.com/rest/SMS/Messages', [
                'AppSid' => config('services.sms.unifonic_app_sid'),
                'SenderID' => config('services.sms.unifonic_sender_id'),
                'Recipient' => $this->normalizeKsaPhone($phone),
                'Body' => "Your babysitter app verification code is: {$otp}. It expires in 5 minutes.",
            ])
            ->throw();
    }

    private function sendVia4jawaly(?string $phone, string $otp): void
    {
        Http::withToken(config('services.sms.jawaly_api_key'))
            ->post('https://api.4jawaly.com/api/v1/account/area/sms/send', [
                'messages' => [
                    [
                        'text' => "Your babysitter app verification code is: {$otp}. It expires in 5 minutes.",
                        'numbers' => [$this->normalizeKsaPhone($phone)],
                    ],
                ],
            ])
            ->throw();
    }

    private function sendViaWhatsApp(?string $phone, string $otp): void
    {
        // Placeholder: swap with the chosen WhatsApp Business API provider
        // (e.g. WhatsApp Cloud API via Twilio/Infobip/360dialog).
        throw new \RuntimeException('WhatsApp driver not configured yet.');
    }

    /**
     * Normalize local KSA numbers (05XXXXXXXX) to E.164 international format.
     */
    private function normalizeKsaPhone(?string $phone): ?string
    {
        if (! $phone) {
            return null;
        }

        $digits = preg_replace('/\D+/', '', $phone);
        if (str_starts_with($digits, '05')) {
            return '+966'.substr($digits, 1);
        }

        if (str_starts_with($digits, '5') && strlen($digits) === 9) {
            return '+966'.$digits;
        }

        return $phone;
    }

    private function mask(?string $phone): ?string
    {
        if (! $phone) {
            return null;
        }

        return strlen($phone) > 6 ? substr($phone, 0, 3).'***'.substr($phone, -2) : '***';
    }
}
