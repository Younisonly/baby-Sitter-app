<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class SocialAuthController extends Controller
{
    private const string FIREBASE_CERT_URI = 'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com';

    private const array ALLOWED_PROVIDERS = ['google', 'apple'];

    public function login(Request $request): JsonResponse
    {
        $request->validate([
            'provider' => ['required', 'string', 'in:' . implode(',', self::ALLOWED_PROVIDERS)],
            'id_token' => ['required', 'string'],
            'device_name' => ['nullable', 'string', 'max:255'],
        ]);

        $payload = $this->verifyFirebaseToken($request->input('id_token'));

        if ($payload === null) {
            return response()->json([
                'status' => 'error',
                'message' => __('Invalid or expired authentication token.'),
            ], 401);
        }

        $firebaseUid = $payload['sub'];
        $email = $payload['email'] ?? null;
        $name = $payload['name'] ?? null;
        $avatar = $payload['picture'] ?? null;
        $emailVerified = $payload['email_verified'] ?? false;
        $provider = $request->input('provider');

        if (! $emailVerified && $provider === 'google') {
            return response()->json([
                'status' => 'error',
                'message' => __('Please verify your email with Google before signing in.'),
            ], 403);
        }

        $user = $this->findOrCreateUser(
            provider: $provider,
            providerId: $firebaseUid,
            email: $email,
            name: $name,
            avatar: $avatar,
        );

        $token = $user->createToken(
            $request->input('device_name', 'social-login'),
            ['*'],
            now()->addDays(30),
        )->plainTextToken;

        return response()->json([
            'status' => 'success',
            'data' => [
                'token' => $token,
                'user' => new UserResource($user),
            ],
            'message' => __('Logged in successfully.'),
        ]);
    }

    private function verifyFirebaseToken(string $idToken): ?array
    {
        try {
            $projectId = config('services.firebase.project_id');
            if (empty($projectId)) {
                Log::error('Firebase project_id is not configured in services.php');
                return null;
            }

            $response = Http::timeout(10)->get(self::FIREBASE_CERT_URI);

            if (! $response->successful()) {
                Log::error('Failed to fetch Firebase public keys', [
                    'status' => $response->status(),
                ]);
                return null;
            }

            $publicKeys = $response->json();

            $tokenParts = explode('.', $idToken);
            if (count($tokenParts) !== 3) {
                Log::warning('Invalid Firebase token format');
                return null;
            }

            $header = json_decode(base64_decode($tokenParts[0]), true);
            $payload = json_decode(base64_decode($tokenParts[1]), true);
            $signature = $tokenParts[2];

            if ($payload === null || $header === null) {
                return null;
            }

            if (! isset($payload['exp']) || $payload['exp'] < time()) {
                Log::warning('Firebase token expired');
                return null;
            }

            if (! isset($payload['aud']) || $payload['aud'] !== $projectId) {
                Log::warning('Firebase token audience mismatch', [
                    'expected' => $projectId,
                    'got' => $payload['aud'] ?? null,
                ]);
                return null;
            }

            if (! isset($payload['iss']) || $payload['iss'] !== "https://securetoken.google.com/{$projectId}") {
                Log::warning('Firebase token issuer mismatch');
                return null;
            }

            $kid = $header['kid'] ?? null;
            if ($kid === null || ! isset($publicKeys[$kid])) {
                Log::warning('Firebase signing key not found', ['kid' => $kid]);
                return null;
            }

            $publicKey = $publicKeys[$kid];

            $dataToVerify = $tokenParts[0] . '.' . $tokenParts[1];
            $signatureRaw = $this->base64UrlDecode($signature);

            $verified = openssl_verify(
                $dataToVerify,
                $signatureRaw,
                $publicKey,
                OPENSSL_ALGO_SHA256,
            );

            if (! $verified) {
                Log::warning('Firebase token signature verification failed');
                return null;
            }

            return $payload;
        } catch (\Throwable $e) {
            Log::error('Firebase token verification error', [
                'message' => $e->getMessage(),
            ]);

            return null;
        }
    }

    private function findOrCreateUser(
        string $provider,
        string $providerId,
        ?string $email,
        ?string $name,
        ?string $avatar,
    ): User {
        $user = User::where('provider', $provider)
            ->where('provider_id', $providerId)
            ->first();

        if ($user !== null) {
            if ($avatar !== null && $user->avatar === null) {
                $user->update(['avatar' => $avatar]);
            }
            if ($name !== null && ($user->name === null || $user->name === '')) {
                $user->update(['name' => $name]);
            }

            return $user;
        }

        if ($email !== null) {
            $existingUser = User::where('email', $email)->first();
            if ($existingUser !== null) {
                $existingUser->update([
                    'provider' => $provider,
                    'provider_id' => $providerId,
                    'email_verified_at' => $existingUser->email_verified_at ?? now(),
                ]);
                if ($avatar !== null && $existingUser->avatar === null) {
                    $existingUser->update(['avatar' => $avatar]);
                }

                return $existingUser;
            }
        }

        $displayName = $name ?? $email ?? 'User';

        return User::create([
            'name' => $displayName,
            'email' => $email ?? $providerId . '@' . $provider . '.user',
            'password' => bcrypt(Str::random(32)),
            'avatar' => $avatar,
            'provider' => $provider,
            'provider_id' => $providerId,
            'email_verified_at' => now(),
            'role' => 'customer',
        ]);
    }

    private function base64UrlDecode(string $data): string
    {
        $remainder = strlen($data) % 4;
        if ($remainder > 0) {
            $data .= str_repeat('=', 4 - $remainder);
        }

        return base64_decode(strtr($data, '-_', '+/'));
    }
}
