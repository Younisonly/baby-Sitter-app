<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminSitterVerificationController extends Controller
{
    public function __construct()
    {
        $this->middleware('admin');
    }

    public function pendingSitters(): JsonResponse
    {
        $sitters = User::where('role', 'babysitter')
            ->where('verification_status', 'under_review')
            ->with('babysitterProfile')
            ->orderBy('created_at')
            ->paginate(perPage: request()->integer('per_page', 20));

        return response()->json([
            'status' => 'success',
            'data' => $sitters->through(fn($user) => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'created_at' => $user->created_at,
                'profile' => $user->babysitterProfile ? [
                    'hourly_rate' => $user->babysitterProfile->hourly_rate,
                    'years_experience' => $user->babysitterProfile->years_experience,
                    'description' => $user->babysitterProfile->description,
                    'categories' => $user->babysitterProfile->categories,
                ] : null,
            ]),
            'meta' => [
                'current_page' => $sitters->currentPage(),
                'last_page' => $sitters->lastPage(),
                'per_page' => $sitters->perPage(),
                'total' => $sitters->total(),
                'has_more' => $sitters->hasMorePages(),
            ],
        ]);
    }

    public function approve(User $user): JsonResponse
    {
        if ($user->role !== 'babysitter') {
            return response()->json(['status' => 'error', 'message' => __('messages.user_not_babysitter')], 422);
        }
        if ($user->verification_status !== 'under_review') {
            return response()->json(['status' => 'error', 'message' => __('messages.sitter_not_in_review')], 422);
        }

        $user->forceFill([
            'verification_status' => 'verified',
            'registration_status' => 'complete',
        ])->save();

        if ($user->babysitterProfile) {
            $user->babysitterProfile->update(['is_available' => true]);
        }

        return response()->json([
            'status' => 'success',
            'message' => __('messages.sitter_approved'),
        ]);
    }

    public function reject(Request $request, User $user): JsonResponse
    {
        if ($user->role !== 'babysitter') {
            return response()->json(['status' => 'error', 'message' => __('messages.user_not_babysitter')], 422);
        }
        if ($user->verification_status !== 'under_review') {
            return response()->json(['status' => 'error', 'message' => __('messages.sitter_not_in_review')], 422);
        }

        $validated = $request->validate([
            'reason' => ['required', 'string', 'max:1000'],
        ]);

        $user->forceFill([
            'verification_status' => 'rejected',
            'registration_status' => 'rejected',
        ])->save();

        return response()->json([
            'status' => 'success',
            'message' => __('messages.sitter_rejected'),
        ]);
    }
}
