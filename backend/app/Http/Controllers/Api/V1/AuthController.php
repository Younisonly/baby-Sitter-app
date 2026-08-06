<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\ForgotPasswordRequest;
use App\Http\Requests\LoginRequest;
use App\Http\Requests\RegisterRequest;
use App\Http\Requests\RequestLoginOtpRequest;
use App\Http\Requests\ResetPasswordRequest;
use App\Http\Requests\UpdateProfileRequest;
use App\Http\Requests\VerifyLoginOtpRequest;
use App\Http\Resources\UserResource;
use App\Models\Booking;
use App\Models\ParentProfile;
use App\Models\User;
use App\Services\OtpService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function __construct(private OtpService $otpService)
    {
    }

    public function register(RegisterRequest $request): JsonResponse
    {
        $role = $request->input('role', 'customer');
        $channel = $request->input('channel', 'email');

        $user = User::create([
            'name' => strip_tags($request->string('name')->toString()),
            'email' => $request->string('email')->lower()->toString(),
            'phone' => $request->input('phone'),
            'password' => $request->string('password')->toString(),
            'role' => $role,
            'national_id' => $request->input('national_id'),
            'preferred_language' => $request->input('preferred_language', 'en'),
        ]);

        $this->ensureRoleProfile($user, $role);

        try {
            $otp = $this->otpService->send($user->id, $channel);
        } catch (\Throwable $e) {
            Log::error('Failed to send registration OTP', [
                'user_id' => $user->id,
                'error' => $e->getMessage(),
            ]);

            $user->delete();

            return response()->json([
                'status' => 'error',
                'message' => __('messages.failed_send_verification'),
            ], 500);
        }

        return response()->json([
            'status' => 'success',
            'message' => app()->isProduction()
                ? 'Verification code sent to your '.$channel.'.'
                : 'Use OTP 111111 in local development.',
            'data' => [
                'otpToken' => $otp['otp_token'],
                'channel' => $otp['channel'],
                'role' => $role,
            ],
        ], 201);
    }

    public function verifyOtp(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'otp_token' => ['required', 'string'],
            'otp' => ['required', 'digits:6'],
            'device_name' => ['nullable', 'string', 'max:80'],
        ]);

        try {
            $verified = $this->otpService->verify($validated['otp_token'], $validated['otp']);
        } catch (\RuntimeException $e) {
            return response()->json([
                'status' => 'error',
                'message' => $e->getMessage(),
            ], 422);
        }

        $user = User::findOrFail($verified['user_id']);
        $user->forceFill([
            'email_verified_at' => $verified['channel'] === 'email'
                ? now()
                : $user->email_verified_at,
            'phone_verified_at' => $verified['channel'] === 'phone'
                ? now()
                : $user->phone_verified_at,
            'verification_status' => 'verified',
        ])->save();

        return $this->tokenResponse($user, $validated['device_name'] ?? 'mobile_app');
    }

    public function forgotPassword(ForgotPasswordRequest $request): JsonResponse
    {
        $user = User::where('email', $request->input('email'))
            ->orWhere('phone', $request->input('phone'))
            ->firstOrFail();

        $channel = $request->filled('email') ? 'email' : 'phone';

        try {
            $otp = $this->otpService->send($user->id, $channel);
        } catch (\RuntimeException $e) {
            return response()->json([
                'status' => 'error',
                'message' => __('messages.failed_send_verification'),
            ], 500);
        }

        return response()->json([
            'status' => 'success',
            'message' => app()->isProduction()
                ? 'Verification code sent to your '.$channel.'.'
                : 'Use OTP 111111 in local development.',
            'data' => [
                'otpToken' => $otp['otp_token'],
                'channel' => $otp['channel'],
            ],
        ]);
    }

    public function resetPassword(ResetPasswordRequest $request): JsonResponse
    {
        try {
            $verified = $this->otpService->verify($request->input('otp_token'), $request->input('otp'));
        } catch (\RuntimeException $e) {
            return response()->json([
                'status' => 'error',
                'message' => $e->getMessage(),
            ], 422);
        }

        $user = User::findOrFail($verified['user_id']);
        $user->update([
            'password' => $request->string('password')->toString(),
        ]);

        $user->tokens()->delete();

        return response()->json([
            'status' => 'success',
            'message' => __('messages.password_reset_successfully'),
        ]);
    }

    public function requestLoginOtp(RequestLoginOtpRequest $request): JsonResponse
    {
        $user = User::where('email', $request->input('email'))
            ->orWhere('phone', $request->input('phone'))
            ->firstOrFail();

        if ($user->is_suspended) {
            return response()->json([
                'status' => 'error',
                'message' => __('messages.account_suspended'),
            ], 403);
        }

        $channel = $request->input('channel') ?? ($request->filled('email') ? 'email' : 'phone');

        try {
            $otp = $this->otpService->send($user->id, $channel);
        } catch (\RuntimeException $e) {
            return response()->json([
                'status' => 'error',
                'message' => __('messages.failed_send_verification'),
            ], 500);
        }

        return response()->json([
            'status' => 'success',
            'message' => app()->isProduction()
                ? 'Verification code sent to your '.$channel.'.'
                : 'Use OTP 111111 in local development.',
            'data' => [
                'otpToken' => $otp['otp_token'],
                'channel' => $otp['channel'],
            ],
        ]);
    }

    public function verifyLoginOtp(VerifyLoginOtpRequest $request): JsonResponse
    {
        try {
            $verified = $this->otpService->verify($request->input('otp_token'), $request->input('otp'));
        } catch (\RuntimeException $e) {
            return response()->json([
                'status' => 'error',
                'message' => $e->getMessage(),
            ], 422);
        }

        $user = User::findOrFail($verified['user_id']);

        if ($user->is_suspended) {
            return response()->json([
                'status' => 'error',
                'message' => __('messages.account_suspended'),
            ], 403);
        }

        if ($verified['channel'] === 'phone') {
            $user->forceFill(['phone_verified_at' => now()])->save();
        }

        return $this->tokenResponse($user, $request->input('device_name', 'mobile_app'));
    }

    public function login(LoginRequest $request): JsonResponse
    {
        $email = $request->string('email')->lower()->toString();
        $user = User::where('email', $email)->first();

        if (! $user || ! Hash::check($request->string('password')->toString(), $user->password)) {
            Log::warning('Failed login attempt', ['email' => $email, 'ip' => $request->ip()]);

            throw ValidationException::withMessages([
                'email' => ['The provided credentials are incorrect.'],
            ]);
        }

        if ($user->is_suspended) {
            Log::warning('Suspended user login attempt', ['user_id' => $user->id, 'email' => $email, 'ip' => $request->ip()]);

            return response()->json([
                'status' => 'error',
                'message' => __('messages.account_suspended'),
            ], 403);
        }

        return $this->tokenResponse($user, $request->input('device_name', 'mobile_app'));
    }

    public function deleteAccount(Request $request): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'password' => ['required', 'string'],
        ]);

        if (! Hash::check($validated['password'], $user->password)) {
            return response()->json([
                'status' => 'error',
                'message' => __('messages.password_incorrect'),
            ], 422);
        }

        $activeBookings = Booking::query()
            ->where(function ($q) use ($user): void {
                $q->where('customer_id', $user->id)->orWhere('sitter_id', $user->id);
            })
            ->whereIn('status', ['pending', 'confirmed', 'in_progress'])
            ->exists();

        if ($activeBookings) {
            return response()->json([
                'status' => 'error',
                'message' => __('messages.cannot_delete_account_active_bookings'),
            ], 422);
        }

        if ($user->role === 'babysitter' && $user->babysitterProfile) {
            $hasPendingEarnings = Booking::query()
                ->where('sitter_id', $user->id)
                ->where('status', 'completed')
                ->exists();

            if ($hasPendingEarnings) {
                return response()->json([
                    'status' => 'error',
                    'message' => __('messages.cannot_delete_account_pending_earnings'),
                ], 422);
            }
        }

        $user->tokens()->delete();
        $user->delete();

        return response()->json([
            'status' => 'success',
            'message' => __('messages.account_deleted'),
        ]);
    }

    public function me(Request $request): UserResource
    {
        return UserResource::make(
            $request->user()->load('babysitterProfile', 'parentProfile')
        );
    }

    public function updateProfile(UpdateProfileRequest $request): JsonResponse
    {
        $user = $request->user();

        $updates = [];
        if ($request->filled('name')) {
            $updates['name'] = strip_tags($request->string('name')->toString());
        }
        if ($request->filled('location')) {
            $updates['location'] = $request->string('location')->toString();
        }
        if ($request->filled('avatar')) {
            $updates['avatar'] = $request->string('avatar')->toString();
        }
        if ($request->filled('national_id')) {
            $updates['national_id'] = $request->string('national_id')->toString();
        }
        if ($request->filled('latitude')) {
            $updates['latitude'] = (float) $request->string('latitude')->toString();
        }
        if ($request->filled('longitude')) {
            $updates['longitude'] = (float) $request->string('longitude')->toString();
        }
        if ($request->filled('preferred_language')) {
            $updates['preferred_language'] = $request->string('preferred_language')->toString();
        }

        if (!empty($updates)) {
            $user->update($updates);
        }

        return response()->json([
            'status' => 'success',
            'message' => __('messages.profile_updated'),
            'data' => UserResource::make($user->refresh()->load('babysitterProfile', 'parentProfile')),
        ]);
    }

    public function availableRoles(Request $request): JsonResponse
    {
        $user = $request->user();

        return response()->json([
            'status' => 'success',
            'data' => [
                'roles' => $user->availableRoles(),
                'hasParentProfile' => $user->canActAsParent(),
                'hasSitterProfile' => $user->canActAsSitter(),
                'activeRole' => $user->role === 'babysitter' ? 'sitter' : 'parent',
            ],
        ]);
    }

    public function becomeSitter(Request $request): JsonResponse
    {
        $user = $request->user();

        if ($user->canActAsSitter()) {
            return response()->json([
                'status' => 'error',
                'message' => __('messages.already_have_sitter_profile'),
            ], 422);
        }

        $validated = $request->validate([
            'national_id' => ['required', 'string', 'min:10', 'unique:users,national_id,'.$user->id],
        ]);

        $user->update([
            'national_id' => $validated['national_id'],
            'role' => 'babysitter',
        ]);

        $user->babysitterProfile()->create([
            'user_id' => $user->id,
            'hourly_rate' => 0,
            'is_available' => true,
        ]);

        $user->update([
            'has_sitter_profile' => true,
            'became_sitter_at' => now(),
        ]);

        return response()->json([
            'status' => 'success',
            'message' => __('messages.sitter_profile_created'),
            'data' => [
                'user' => UserResource::make($user->load('babysitterProfile', 'parentProfile')),
            ],
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()?->delete();

        return response()->json([
            'status' => 'success',
            'message' => __('messages.logged_out'),
        ]);
    }

    public function sendUpdateOtp(Request $request): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'email' => ['nullable', 'email:rfc', 'max:255', Rule::unique('users', 'email')->ignore($user->id)],
            'phone' => ['nullable', 'string', 'max:20', Rule::unique('users', 'phone')->ignore($user->id)],
        ]);

        try {
            $otp = $this->otpService->send($user->id, 'email', [
                'pending_email' => $validated['email'] ?? null,
                'pending_phone' => $validated['phone'] ?? null,
            ]);
        } catch (\RuntimeException $e) {
            Log::error('Failed to cache update OTP', [
                'user_id' => $user->id,
                'error' => $e->getMessage(),
            ]);

            return response()->json([
                'status' => 'error',
                'message' => __('messages.failed_send_verification'),
            ], 500);
        }

        return response()->json([
            'status' => 'success',
            'message' => app()->isProduction()
                ? 'Verification code sent to your email.'
                : 'Use OTP 111111 in local development.',
            'data' => [
                'otpToken' => $otp['otp_token'],
            ],
        ]);
    }

    public function verifyUpdateOtp(Request $request): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'otp_token' => ['required', 'string'],
            'otp' => ['required', 'digits:6'],
        ]);

        try {
            $verified = $this->otpService->verify($validated['otp_token'], $validated['otp']);
        } catch (\RuntimeException $e) {
            Log::error('Update OTP verification failed', [
                'user_id' => $user->id,
                'error' => $e->getMessage(),
            ]);

            return response()->json([
                'status' => 'error',
                'message' => __('messages.invalid_expired_verification_code'),
            ], 422);
        }

        if ((int) $verified['user_id'] !== $user->id) {
            return response()->json([
                'status' => 'error',
                'message' => __('messages.invalid_expired_verification_code'),
            ], 422);
        }

        $updates = [];
        if (! empty($verified['context']['pending_email'])) {
            $updates['email'] = $verified['context']['pending_email'];
        }
        if (! empty($verified['context']['pending_phone'])) {
            $updates['phone'] = $verified['context']['pending_phone'];
        }

        if (! empty($updates)) {
            $user->update($updates);
        }

        return response()->json([
            'status' => 'success',
            'message' => __('messages.profile_updated'),
            'data' => UserResource::make($user->refresh()->load('babysitterProfile', 'parentProfile')),
        ]);
    }

    private function tokenResponse(User $user, string $deviceName): JsonResponse
    {
        $user->tokens()->where('name', $deviceName)->delete();

        return response()->json([
            'status' => 'success',
            'data' => [
                'token' => $user->createToken($deviceName, ['*'], now()->addDays(30))->plainTextToken,
                'user' => UserResource::make($user->load('babysitterProfile', 'parentProfile')),
            ],
        ]);
    }

    private function ensureRoleProfile(User $user, string $role): void
    {
        if ($role === 'customer') {
            if (! $user->has_parent_profile) {
                $user->parentProfile()->create(['user_id' => $user->id]);
                $user->update([
                    'has_parent_profile' => true,
                    'became_parent_at' => now(),
                ]);
            }
        } elseif ($role === 'babysitter') {
            if (! $user->has_parent_profile) {
                $user->parentProfile()->create(['user_id' => $user->id]);
                $user->update([
                    'has_parent_profile' => true,
                    'became_parent_at' => now(),
                ]);
            }
            if (! $user->has_sitter_profile) {
                $user->babysitterProfile()->create([
                    'user_id' => $user->id,
                    'hourly_rate' => 0,
                    'is_available' => true,
                ]);
                $user->update([
                    'has_sitter_profile' => true,
                    'became_sitter_at' => now(),
                ]);
            }
        }
    }
}
