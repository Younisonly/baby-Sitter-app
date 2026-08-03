<?php

namespace App\Services;

use App\Models\UserDevice;
use App\Models\NotificationAuditLog;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

final class FcmPushService
{
    private const FCM_V1_URL = 'https://fcm.googleapis.com/v1/projects/babysitter-29120/messages:send';
    private const FCM_LEGACY_URL = 'https://fcm.googleapis.com/fcm/send';
    private const OAUTH_URL = 'https://oauth2.googleapis.com/token';
    private const MAX_RETRIES = 3;

    private ?string $accessToken = null;
    private ?int $tokenExpiresAt = 0;
    private ?object $serviceAccount = null;
    private ?string $legacyKey = null;

    public function __construct()
    {
        $this->loadServiceAccount();
        $this->legacyKey = config('services.fcm.server_key');
        if (!empty($this->legacyKey)) {
            Log::info('FCM legacy server key configured.');
        }
    }

    private function loadServiceAccount(): void
    {
        $path = storage_path('app/firebase-service-account.json');
        if (file_exists($path)) {
            $content = file_get_contents($path);
            $decoded = json_decode($content);
            if ($decoded !== null) {
                $this->serviceAccount = $decoded;
                return;
            }
            Log::warning('Firebase service account file is not valid JSON at: ' . $path);
        }

        $envJson = env('FIREBASE_SERVICE_ACCOUNT_JSON');
        if (!empty($envJson)) {
            $decoded = json_decode(base64_decode($envJson));
            if ($decoded !== null) {
                $this->serviceAccount = $decoded;
                return;
            }
            Log::warning('FIREBASE_SERVICE_ACCOUNT_JSON env var is not valid JSON');
        }

        Log::warning('Firebase service account not found. Push notifications disabled.');
    }

    public function send(
        UserDevice $device,
        string $title,
        string $body,
        ?string $deepLinkType = null,
        ?string $deepLinkId = null,
        ?int $notificationId = null,
        ?string $actionKey = null,
        array $replacements = [],
    ): bool {
        if ($this->serviceAccount !== null) {
            return $this->sendV1($device, $title, $body, $deepLinkType, $deepLinkId, $notificationId, $actionKey, $replacements);
        }

        if (!empty($this->legacyKey)) {
            return $this->sendLegacy($device, $title, $body, $deepLinkType, $deepLinkId, $notificationId, $actionKey, $replacements);
        }

        Log::warning('No FCM credentials configured. Set FCM_SERVER_KEY or add firebase-service-account.json.');
        return false;
    }

    private function sendV1(
        UserDevice $device,
        string $title,
        string $body,
        ?string $deepLinkType = null,
        ?string $deepLinkId = null,
        ?int $notificationId = null,
        ?string $actionKey = null,
        array $replacements = [],
    ): bool {
        if (!$this->ensureAccessToken()) {
            return false;
        }

        $payload = $this->buildV1Payload($device, $title, $body, $deepLinkType, $deepLinkId, $notificationId, $actionKey, $replacements);

        $attempts = 0;
        while ($attempts < self::MAX_RETRIES) {
            $attempts++;

            try {
                $response = Http::withHeaders([
                    'Authorization' => 'Bearer ' . $this->accessToken,
                    'Content-Type' => 'application/json',
                ])->timeout(10)->post(self::FCM_V1_URL, $payload);

                if ($response->successful()) {
                    return true;
                }

                if ($response->status() === 401) {
                    $this->accessToken = null;
                    if ($this->ensureAccessToken()) {
                        continue;
                    }
                    return false;
                }

                if ($response->status() === 404 && str_contains($response->body(), 'UNREGISTERED')) {
                    $device->update(['is_active' => false]);
                    Log::info("Device token deactivated (unregistered): {$device->id}");
                    return false;
                }

                Log::warning("FCM v1 attempt {$attempts} failed", [
                    'status' => $response->status(),
                    'body' => $response->body(),
                ]);

                if ($attempts < self::MAX_RETRIES) {
                    sleep(min($attempts * 2, 5));
                }
            } catch (\Exception $e) {
                Log::error("FCM v1 exception on attempt {$attempts}: {$e->getMessage()}");

                if ($attempts >= self::MAX_RETRIES) {
                    $this->logFailure($device, $notificationId, $e->getMessage());
                    return false;
                }

                sleep(min($attempts * 2, 5));
            }
        }

        return false;
    }

    private function sendLegacy(
        UserDevice $device,
        string $title,
        string $body,
        ?string $deepLinkType = null,
        ?string $deepLinkId = null,
        ?int $notificationId = null,
        ?string $actionKey = null,
        array $replacements = [],
    ): bool {
        $payload = [
            'to'           => $device->device_token,
            'priority'     => 'high',
            'notification' => [
                'title'        => $title,
                'body'         => $body,
                'sound'        => 'default',
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
            ],
            'data' => [
                'type'            => $deepLinkType ?? '',
                'id'              => $deepLinkId ?? '',
                'notification_id' => (string) ($notificationId ?? ''),
                'title'           => $title,
                'body'            => $body,
                // Flutter reads these to localize foreground push notifications.
                'action_key'      => $actionKey ?? '',
                'data_json'       => json_encode($replacements),
            ],
            'android' => [
                'priority'     => 'high',
                'notification' => [
                    'channel_id' => $this->channelForType($deepLinkType),
                ],
            ],
            'apns' => [
                'headers' => [
                    'apns-priority' => '10',
                ],
                'payload' => [
                    'aps' => [
                        'sound' => 'default',
                        'badge' => 1,
                        'content-available' => 1,
                    ],
                ],
            ],
        ];

        $attempts = 0;
        while ($attempts < self::MAX_RETRIES) {
            $attempts++;

            try {
                $response = Http::withHeaders([
                    'Authorization' => 'key=' . $this->legacyKey,
                    'Content-Type' => 'application/json',
                ])->timeout(10)->post(self::FCM_LEGACY_URL, $payload);

                if ($response->successful()) {
                    return true;
                }

                $responseJson = $response->json();
                if (($responseJson['results'][0]['error'] ?? null) === 'NotRegistered') {
                    $device->update(['is_active' => false]);
                    Log::info("Device token deactivated (NotRegistered): {$device->id}");
                    return false;
                }

                Log::warning("FCM legacy attempt {$attempts} failed", [
                    'status' => $response->status(),
                    'body' => $response->body(),
                ]);

                if ($attempts < self::MAX_RETRIES) {
                    sleep(min($attempts * 2, 5));
                }
            } catch (\Exception $e) {
                Log::error("FCM legacy exception on attempt {$attempts}: {$e->getMessage()}");

                if ($attempts >= self::MAX_RETRIES) {
                    $this->logFailure($device, $notificationId, $e->getMessage());
                    return false;
                }

                sleep(min($attempts * 2, 5));
            }
        }

        return false;
    }

    private function ensureAccessToken(): bool
    {
        if ($this->accessToken && $this->tokenExpiresAt > time()) {
            return true;
        }

        if ($this->serviceAccount === null) {
            Log::warning('Firebase service account not loaded');
            return false;
        }

        try {
            $sa = (array) $this->serviceAccount;
            $header = ['alg' => 'RS256', 'typ' => 'JWT'];
            $now = time();
            $claims = [
                'iss' => $sa['client_email'],
                'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
                'aud' => self::OAUTH_URL,
                'iat' => $now,
                'exp' => $now + 3600,
            ];

            $jwt = $this->encodeJWT($header, $claims, $sa['private_key']);

            $response = Http::asForm()->post(self::OAUTH_URL, [
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion' => $jwt,
            ]);

            if (!$response->successful()) {
                Log::error('Failed to get OAuth token', ['body' => $response->body()]);
                return false;
            }

            $data = $response->json();
            $this->accessToken = $data['access_token'] ?? null;
            $this->tokenExpiresAt = $now + ($data['expires_in'] ?? 3600) - 60;

            return $this->accessToken !== null;
        } catch (\Exception $e) {
            Log::error("Failed to get FCM access token: {$e->getMessage()}");
            return false;
        }
    }

    private function buildV1Payload(
        UserDevice $device,
        string $title,
        string $body,
        ?string $deepLinkType,
        ?string $deepLinkId,
        ?int $notificationId,
        ?string $actionKey = null,
        array $replacements = [],
    ): array {
        $deepLink = null;
        if ($deepLinkType && $deepLinkId) {
            $deepLink = config('app.url') . "/open/{$deepLinkType}/{$deepLinkId}";
        }

        return [
            'message' => [
                'token'        => $device->device_token,
                'notification' => [
                    'title' => $title,
                    'body'  => $body,
                ],
                'data' => [
                    'type'            => $deepLinkType ?? '',
                    'id'              => $deepLinkId ?? '',
                    'deep_link'       => $deepLink ?? '',
                    'notification_id' => (string) ($notificationId ?? ''),
                    'title'           => $title,
                    'body'            => $body,
                    // Flutter reads these to localize foreground push notifications.
                    'action_key'      => $actionKey ?? '',
                    'data_json'       => json_encode($replacements),
                ],
                'android' => [
                    'priority'     => 'high',
                    'notification' => [
                        'sound'        => 'default',
                        'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                        'channel_id'   => $this->channelForType($deepLinkType),
                    ],
                ],
                'apns' => [
                    'payload' => [
                        'aps' => [
                            'sound'           => 'default',
                            'badge'           => 1,
                            'click_action'    => 'FLUTTER_NOTIFICATION_CLICK',
                            'content_available' => true,
                        ],
                    ],
                ],
            ],
        ];
    }

    private function channelForType(?string $type): string
    {
        return match ($type) {
            'booking' => 'bookings',
            'chat' => 'chat',
            'followers' => 'followers',
            'review' => 'review',
            'security' => 'security',
            'support' => 'support',
            'system' => 'system',
            default => 'default',
        };
    }

    private function encodeJWT(array $header, array $claims, string $privateKey): string
    {
        $segments = [];
        $segments[] = $this->base64UrlEncode(json_encode($header));
        $segments[] = $this->base64UrlEncode(json_encode($claims));

        $signInput = implode('.', $segments);
        $signature = '';
        openssl_sign($signInput, $signature, $privateKey, OPENSSL_ALGO_SHA256);
        $segments[] = $this->base64UrlEncode($signature);

        return implode('.', $segments);
    }

    private function base64UrlEncode(string $data): string
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    private function logFailure(UserDevice $device, ?int $notificationId, string $error): void
    {
        try {
            NotificationAuditLog::create([
                'notification_id' => $notificationId,
                'user_id' => $device->user_id,
                'channel' => 'push',
                'status' => 'failed',
                'error_message' => $error,
            ]);
        } catch (\Exception $e) {
            Log::error("Failed to log push failure: {$e->getMessage()}");
        }
    }
}
