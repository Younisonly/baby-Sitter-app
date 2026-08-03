<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\BabysitterProfile;
use App\Models\Booking;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\ValidationException;

class SitterRegistrationController extends Controller
{
    public function status(Request $request): JsonResponse
    {
        $user = $request->user()->load('babysitterProfile');

        return response()->json([
            'status' => 'success',
            'data' => [
                'user' => new UserResource($user),
                'registrationStatus' => $user->registration_status,
                'completedSteps' => $this->getCompletedSteps($user),
                'currentStep' => $this->getCurrentStep($user),
            ],
        ]);
    }

    public function startDraft(Request $request): JsonResponse
    {
        $user = $request->user();

        if ($user->is_suspended) {
            return response()->json(['status' => 'error', 'message' => 'Your account is suspended. You cannot register as a babysitter.'], 403);
        }

        if ($user->role === 'babysitter' && $user->registration_status !== 'none') {
            return response()->json([
                'status' => 'error',
                'message' => __('You have already started the registration process.'),
            ], 400);
        }

        DB::beginTransaction();
        try {
            $user->forceFill([
                'role' => 'babysitter',
                'registration_status' => 'draft',
            ])->save();

            BabysitterProfile::updateOrCreate(
                ['user_id' => $user->id],
                [
                    'hourly_rate' => 0,
                    'is_available' => false,
                    'included_children' => 1,
                    'extra_child_fee' => 0,
                    'special_needs_rate' => 0,
                ]
            );

            DB::commit();

            return response()->json([
                'status' => 'success',
                'message' => __('Registration draft created.'),
                'data' => [
                    'user' => new UserResource($user->fresh()->load('babysitterProfile')),
                    'registrationStatus' => 'draft',
                    'completedSteps' => [],
                    'currentStep' => 1,
                ],
            ], 201);
        } catch (\Throwable $e) {
            DB::rollBack();
            Log::error('Failed to start sitter registration', [
                'user_id' => $user->id,
                'error' => $e->getMessage(),
            ]);

            return response()->json([
                'status' => 'error',
                'message' => __('Failed to start registration. Please try again.'),
            ], 500);
        }
    }

    public function discardDraft(Request $request): JsonResponse
    {
        $user = $request->user()->load('babysitterProfile');

        if ($user->registration_status !== 'draft') {
            return response()->json([
                'status' => 'error',
                'message' => __('No draft registration found.'),
            ], 400);
        }

        DB::beginTransaction();
        try {
            $user->forceFill([
                'registration_status' => 'none',
                'role' => 'user',
                'verification_status' => 'unverified',
            ])->save();

            $profile = $user->babysitterProfile;
            if ($profile) {
                $profile->delete();
            }

            DB::commit();

            return response()->json([
                'status' => 'success',
                'message' => __('Registration draft discarded.'),
                'data' => [
                    'user' => new UserResource($user->fresh()),
                    'registrationStatus' => 'none',
                ],
            ]);
        } catch (\Throwable $e) {
            DB::rollBack();
            Log::error('Failed to discard registration draft', [
                'user_id' => $user->id,
                'error' => $e->getMessage(),
            ]);

            return response()->json([
                'status' => 'error',
                'message' => __('Failed to discard draft. Please try again.'),
            ], 500);
        }
    }

    public function saveStep(Request $request, int $step): JsonResponse
    {
        $user = $request->user()->load('babysitterProfile');

        if ($user->registration_status !== 'draft') {
            return response()->json([
                'status' => 'error',
                'message' => __('Registration can only be edited in draft status.'),
            ], 400);
        }

        $profile = $user->babysitterProfile;
        if (! $profile) {
            return response()->json([
                'status' => 'error',
                'message' => __('Profile not found. Please start registration again.'),
            ], 404);
        }

        $validated = $this->validateStepData($request, $step);
        if ($validated instanceof JsonResponse) {
            return $validated;
        }

        DB::beginTransaction();
        try {
            $this->updateStepData($user, $profile, $step, $validated);
            $profile->save();
            $user->save();
            DB::commit();

            return response()->json([
                'status' => 'success',
                'message' => __('Step :step saved.', ['step' => $step]),
                'data' => [
                    'user' => new UserResource($user->fresh()->load('babysitterProfile')),
                    'completedSteps' => $this->getCompletedSteps($user->fresh()),
                    'currentStep' => min($step + 1, 6),
                ],
            ]);
        } catch (\Throwable $e) {
            DB::rollBack();
            Log::error('Failed to save registration step', [
                'user_id' => $user->id,
                'step' => $step,
                'error' => $e->getMessage(),
            ]);

            return response()->json([
                'status' => 'error',
                'message' => __('Failed to save. Please try again.'),
            ], 500);
        }
    }

    public function submit(Request $request): JsonResponse
    {
        $user = $request->user()->load('babysitterProfile');

        if ($user->registration_status !== 'draft') {
            return response()->json([
                'status' => 'error',
                'message' => __('Only draft registrations can be submitted.'),
            ], 400);
        }

        $profile = $user->babysitterProfile;
        if (! $profile) {
            return response()->json([
                'status' => 'error',
                'message' => __('Profile not found. Please start registration again.'),
            ], 404);
        }

        $missingSteps = $this->getMissingRequiredSteps($user, $profile);
        if (! empty($missingSteps)) {
            return response()->json([
                'status' => 'error',
                'message' => __('Please complete all required steps before submitting.'),
                'errors' => ['steps' => $missingSteps],
            ], 422);
        }

        DB::beginTransaction();
        try {
            $user->forceFill([
                'registration_status' => 'submitted',
                'verification_status' => 'under_review',
            ])->save();
            DB::commit();

            return response()->json([
                'status' => 'success',
                'message' => __('Registration submitted for review.'),
                'data' => [
                    'user' => new UserResource($user->fresh()->load('babysitterProfile')),
                    'registrationStatus' => 'submitted',
                ],
            ]);
        } catch (\Throwable $e) {
            DB::rollBack();
            Log::error('Failed to submit registration', [
                'user_id' => $user->id,
                'error' => $e->getMessage(),
            ]);

            return response()->json([
                'status' => 'error',
                'message' => __('Failed to submit registration. Please try again.'),
            ], 500);
        }
    }

    public function removeSitterAccount(Request $request): JsonResponse
    {
        $user = $request->user()->load('babysitterProfile');

        if ($user->role !== 'babysitter') {
            return response()->json([
                'status' => 'error',
                'message' => __('You are not registered as a babysitter.'),
            ], 400);
        }

        $validated = $request->validate([
            'password' => ['required', 'string'],
        ]);

        if (! Hash::check($validated['password'], $user->password)) {
            return response()->json([
                'status' => 'error',
                'message' => __('Password is incorrect.'),
            ], 422);
        }

        $activeBookings = Booking::query()
            ->where('sitter_id', $user->id)
            ->whereIn('status', ['pending', 'confirmed', 'in_progress'])
            ->exists();

        if ($activeBookings) {
            return response()->json([
                'status' => 'error',
                'message' => __('Cannot remove sitter account while you have active bookings. Please cancel or complete them first.'),
            ], 422);
        }

        $hasPendingEarnings = Booking::query()
            ->where('sitter_id', $user->id)
            ->where('status', 'completed')
            ->exists();

        if ($hasPendingEarnings) {
            return response()->json([
                'status' => 'error',
                'message' => __('Cannot remove sitter account while you have pending earnings. Please contact support to process your payouts first.'),
            ], 422);
        }

        DB::beginTransaction();
        try {
            $profile = $user->babysitterProfile;
            if ($profile) {
                $profile->delete();
            }

            $user->forceFill([
                'role' => 'customer',
                'registration_status' => 'none',
                'verification_status' => 'unverified',
            ])->save();

            DB::commit();

            return response()->json([
                'status' => 'success',
                'message' => __('Babysitter account removed. You are now a customer.'),
            ]);
        } catch (\Throwable $e) {
            DB::rollBack();
            Log::error('Failed to remove sitter account', [
                'user_id' => $user->id,
                'error' => $e->getMessage(),
            ]);

            return response()->json([
                'status' => 'error',
                'message' => __('Failed to remove sitter account. Please try again.'),
            ], 500);
        }
    }

    private function validateStepData(Request $request, int $step): array|JsonResponse
    {
        $rules = match ($step) {
            1 => [
                'age' => ['nullable', 'integer', 'min:18', 'max:100'],
                'gender' => ['nullable', 'string', 'in:male,female'],
                'languages' => ['nullable', 'array'],
                'languages.*' => ['string', 'max:50'],
                'bio' => ['nullable', 'string', 'max:1000'],
                'location' => ['nullable', 'string', 'max:120'],
                'latitude' => ['nullable', 'numeric', 'between:-90,90'],
                'longitude' => ['nullable', 'numeric', 'between:-180,180'],
                'years_experience' => ['nullable', 'integer', 'min:0', 'max:70'],
                'categories' => ['nullable', 'array'],
                'categories.*' => ['string', 'max:50'],
            ],
            2 => [
                'certificates' => ['nullable', 'array'],
                'certificates.*.name' => ['required', 'string', 'max:255'],
                'certificates.*.notes' => ['nullable', 'string', 'max:1000'],
                'description' => ['nullable', 'string', 'max:2000'],
            ],
            3 => [
                'hourly_rate' => ['required', 'numeric', 'min:0', 'max:9999'],
                'included_children' => ['required', 'integer', 'min:1', 'max:20'],
                'extra_child_fee' => ['required', 'numeric', 'min:0', 'max:9999'],
                'absolute_max_children' => ['nullable', 'integer', 'min:1', 'max:30'],
                'special_needs_rate' => ['required', 'numeric', 'min:0', 'max:9999'],
            ],
            4 => [
                'availability' => ['nullable', 'array'],
                'availability.*.day_of_week' => ['required', 'integer', 'between:0,6'],
                'availability.*.start_time' => ['required', 'date_format:H:i'],
                'availability.*.end_time' => ['required', 'date_format:H:i', 'after:availability.*.start_time'],
            ],
            5 => [
                'bank_account' => ['nullable', 'array'],
                'bank_account.account_holder' => ['required_with:bank_account', 'string', 'max:100'],
                'bank_account.bank_name' => ['required_with:bank_account', 'string', 'max:100'],
                'bank_account.iban' => ['required_with:bank_account', 'string', 'max:34'],
                'bank_account.swift_code' => ['nullable', 'string', 'max:11'],
            ],
            default => throw ValidationException::withMessages([
                'step' => ['Invalid step number.'],
            ]),
        };

        return $request->validate($rules);
    }

    private function updateStepData(User $user, BabysitterProfile $profile, int $step, array $data): void
    {
        switch ($step) {
            case 1:
                $user->age = $data['age'] ?? $user->age;
                $user->gender = $data['gender'] ?? $user->gender;
                $user->languages = $data['languages'] ?? $user->languages;
                $user->bio = $data['bio'] ?? $user->bio;
                $user->location = $data['location'] ?? $user->location;
                $user->latitude = $data['latitude'] ?? $user->latitude;
                $user->longitude = $data['longitude'] ?? $user->longitude;
                $profile->years_experience = $data['years_experience'] ?? $profile->years_experience;
                $profile->categories = $data['categories'] ?? $profile->categories;
                break;
            case 2:
                $profile->certificates = $data['certificates'] ?? $profile->certificates;
                $profile->description = $data['description'] ?? $profile->description;
                break;
            case 3:
                $profile->hourly_rate = $data['hourly_rate'];
                $profile->included_children = $data['included_children'];
                $profile->extra_child_fee = $data['extra_child_fee'];
                $profile->absolute_max_children = $data['absolute_max_children'] ?? $profile->absolute_max_children;
                $profile->special_needs_rate = $data['special_needs_rate'];
                break;
            case 4:
                $profile->availability = $data['availability'] ?? $profile->availability;
                break;
            case 5:
                $profile->bank_account = ! empty($data['bank_account']) ? encrypt(json_encode($data['bank_account'])) : null;
                break;
        }
    }

    private function getCompletedSteps(User $user): array
    {
        $profile = $user->babysitterProfile;
        if (! $profile) {
            return [];
        }

        $steps = [];
        if ($user->age || $user->gender || $user->languages || $user->bio || $user->location) {
            $steps[] = 1;
        }
        if ($profile->certificates || $profile->description) {
            $certs = $profile->certificates;
            if (is_array($certs)) {
                $hasNamed = false;
                foreach ($certs as $c) {
                    if (is_string($c)) {
                        $hasNamed = true;
                        break;
                    }
                    if (is_array($c) && ! empty($c['name'])) {
                        $hasNamed = true;
                        break;
                    }
                }
                if ($hasNamed) {
                    $steps[] = 2;
                }
            } elseif (! empty($profile->description)) {
                $steps[] = 2;
            }
        }
        if ($profile->hourly_rate > 0) {
            $steps[] = 3;
        }
        if (! empty($profile->availability)) {
            $steps[] = 4;
        }
        if ($profile->bank_account) {
            $bank = is_string($profile->bank_account) ? json_decode($profile->bank_account, true) : $profile->bank_account;
            if (! empty($bank['account_holder']) || ! empty($bank['iban'])) {
                $steps[] = 5;
            }
        }

        return $steps;
    }

    private function getCurrentStep(User $user): int
    {
        $completed = $this->getCompletedSteps($user);
        if (empty($completed)) {
            return 1;
        }
        $next = max($completed) + 1;

        return min($next, 6);
    }

    private function getMissingRequiredSteps(User $user, BabysitterProfile $profile): array
    {
        $missing = [];

        // Step 3 (rates) is always required
        if ($profile->hourly_rate <= 0) {
            $missing[] = 3;
        }

        // Step 4 (schedule) is required
        if (empty($profile->availability)) {
            $missing[] = 4;
        }

        return $missing;
    }
}
