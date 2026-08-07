<?php

namespace App\Services;

use App\Notifications\OtpNotification;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

/**
 * Central OTP generation, caching, and delivery.
 *
 * Channels:
 *  - email: delivered via Laravel Mail (OtpNotification).
 *  - phone: delivered via SmsProvider (config-driven; log driver until a
 *           KSA provider such as 4jawaly/Unifonic/Twilio keys are configured).
 *
 * All OTPs are single-use and expire after 5 minutes. The plain code is
 * never persisted — only its bcrypt hash, so a cache leak cannot reveal it.
 */
class OtpService
{
    private const TTL_MINUTES = 5;

    public function __construct(private SmsProvider $smsProvider)
    {
    }

    /**
     * Generate an OTP for a user, cache it, and deliver it on the given channel.
     *
     * @return array{otp_token: string, channel: string} token to pass to verify/reset
     */
    public function send(string $userId, string $channel, array $context = []): array
    {
        $channel = $channel === 'phone' ? 'phone' : 'email';

        $otpToken = Str::uuid()->toString();
        $otp = app()->isProduction() ? (string) random_int(100000, 999999) : '111111';

        try {
            Cache::put("otp:$otpToken", [
                'user_id' => $userId,
                'otp' => bcrypt($otp),
                'channel' => $channel,
                ...$context,
            ], now()->addMinutes(self::TTL_MINUTES));
        } catch (\Throwable $e) {
            Log::error('Failed to cache OTP', [
                'user_id' => $userId,
                'error' => $e->getMessage(),
            ]);

            throw new \RuntimeException('Failed to prepare verification code.');
        }

        $this->deliver($userId, $channel, $otp, $context);

        return ['otp_token' => $otpToken, 'channel' => $channel];
    }

    /**
     * Best-effort resend for an existing (un-consumed) OTP token. Reads the
     * cached context, regenerates the code under a fresh token, and re-delivers
     * it. Works for flows where no user row exists yet (registration).
     *
     * @return array{otp_token: string, channel: string}
     */
    public function resendByToken(string $otpToken, ?string $channel = null): array
    {
        try {
            $cached = Cache::get("otp:$otpToken");
        } catch (\Throwable $e) {
            Log::error('OTP resend cache read failed', ['error' => $e->getMessage()]);

            throw new \RuntimeException('Your session expired. Please request a new code.');
        }

        if (! $cached || ! isset($cached['user_id'])) {
            throw new \RuntimeException('Your session expired. Please request a new code.');
        }

        $context = $cached;
        unset($context['otp'], $context['channel']);

        return $this->send(
            (int) $cached['user_id'],
            $channel ?? ($cached['channel'] ?? 'email'),
            $context,
        );
    }

    /**
     * Verify a code against its cached hash. Consumes the OTP on success.
     *
     * @return array{user_id: int, channel: string} cached context or throws
     */
    public function verify(string $otpToken, string $otp): array
    {
        try {
            $cached = Cache::pull("otp:$otpToken");
        } catch (\Throwable $e) {
            Log::error('OTP cache pull failed', ['error' => $e->getMessage()]);

            throw new \RuntimeException('Verification failed. Please try again.');
        }

        if (! $cached || ! password_verify($otp, $cached['otp'])) {
            throw new \RuntimeException('Invalid or expired verification code.');
        }

        return [
            'user_id' => (int) $cached['user_id'],
            'channel' => $cached['channel'] ?? 'email',
            'context' => $cached,
        ];
    }

    private function deliver(string $userId, string $channel, string $otp, array $context = []): void
    {
        try {
            if ($channel === 'phone') {
                $phone = $context['phone'] ?? null;
                $this->smsProvider->send($userId, $otp, $phone);

                return;
            }

            $user = \App\Models\User::find($userId);
            $email = $user?->email ?? $context['email'] ?? null;

            if (! $email) {
                return;
            }

            $userName = $user?->name ?? trim((string) ($context['name'] ?? ''));

            if ($user) {
                $user->notify(new OtpNotification($otp));

                return;
            }

            \Illuminate\Support\Facades\Mail::to($email)->send(new \App\Mail\OtpMail($otp, $userName));
        } catch (\Throwable $e) {
            Log::error('OTP delivery failed', [
                'user_id' => $userId,
                'channel' => $channel,
                'error' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Best-effort resend: regenerate and re-deliver. Used by the "resend" button.
     */
    public function resend(string $userId, string $channel, array $context = []): array
    {
        return $this->send($userId, $channel, $context);
    }
}
