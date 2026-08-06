<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\BookingResource;
use App\Models\Booking;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class SitterReviewController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        if ($request->user()->role !== 'babysitter') {
            return response()->json(['status' => 'error', 'message' => __('messages.unauthorized')], 403);
        }

        $reviews = Booking::query()
            ->with('customer')
            ->where('sitter_id', $request->user()->id)
            ->whereNotNull('rating')
            ->where('status', 'completed')
            ->orderByDesc('updated_at')
            ->paginate(perPage: $request->integer('per_page', 20));

        return response()->json([
            'status' => 'success',
            'data' => BookingResource::collection($reviews),
            'meta' => [
                'current_page' => $reviews->currentPage(),
                'last_page' => $reviews->lastPage(),
                'per_page' => $reviews->perPage(),
                'total' => $reviews->total(),
                'has_more' => $reviews->hasMorePages(),
            ],
        ]);
    }

    public function reply(Request $request, Booking $booking): JsonResponse
    {
        if ($request->user()->role !== 'babysitter' || $booking->sitter_id !== $request->user()->id) {
            return response()->json(['status' => 'error', 'message' => __('messages.unauthorized')], 403);
        }

        if ($booking->rating === null || $booking->review === null) {
            return response()->json(['status' => 'error', 'message' => __('messages.booking_no_review_reply')], 422);
        }

        $validated = $request->validate([
            'reply' => ['required', 'string', 'max:2000'],
        ]);

        $sanitized = strip_tags(htmlspecialchars($validated['reply'], ENT_QUOTES, 'UTF-8'));

        $booking->update([
            'reply' => $sanitized,
            'replied_at' => now(),
        ]);

        return response()->json([
            'status' => 'success',
            'message' => __('messages.reply_submitted'),
            'data' => BookingResource::make($booking->fresh()->load('customer')),
        ]);
    }

    public function report(Request $request, Booking $booking): JsonResponse
    {
        if ($booking->rating === null) {
            return response()->json(['status' => 'error', 'message' => __('messages.no_review_to_report')], 422);
        }

        $user = $request->user();
        if ($booking->customer_id !== $user->id && $booking->sitter_id !== $user->id) {
            return response()->json(['status' => 'error', 'message' => __('messages.unauthorized')], 403);
        }

        $request->validate([
            'reason' => ['required', 'string', 'max:500'],
        ]);

        $booking->update([
            'reported_at' => now(),
        ]);

        return response()->json([
            'status' => 'success',
            'message' => __('messages.review_reported'),
        ]);
    }

    public function markHelpful(Request $request, Booking $booking): JsonResponse
    {
        if ($booking->rating === null) {
            return response()->json(['status' => 'error', 'message' => __('messages.no_review_found')], 404);
        }

        $existing = DB::table('review_helpful')
            ->where('booking_id', $booking->id)
            ->where('user_id', $request->user()->id)
            ->first();

        if ($existing) {
            return response()->json(['status' => 'error', 'message' => __('messages.already_marked_helpful')], 409);
        }

        DB::table('review_helpful')->insert([
            'booking_id' => $booking->id,
            'user_id' => $request->user()->id,
            'created_at' => now(),
        ]);

        $booking->increment('helpful_count');

        return response()->json([
            'status' => 'success',
            'message' => __('messages.marked_helpful'),
            'data' => ['helpful_count' => $booking->fresh()->helpful_count],
        ]);
    }
}
