<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\RescheduleRequestResource;
use App\Models\Booking;
use App\Models\RescheduleRequest;
use App\Services\BookingService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class RescheduleRequestController extends Controller
{
    use ApiResponse;

    public function __construct(
        private readonly BookingService $bookingService,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $requests = RescheduleRequest::query()
            ->with('requester:id,name,avatar')
            ->whereHas('booking', fn($q) => $q->where('customer_id', $user->id)->orWhere('sitter_id', $user->id))
            ->orderByDesc('created_at')
            ->paginate($request->integer('per_page', 20));

        return response()->json([
            'status' => 'success',
            'data' => RescheduleRequestResource::collection($requests),
            'meta' => [
                'current_page' => $requests->currentPage(),
                'last_page' => $requests->lastPage(),
                'per_page' => $requests->perPage(),
                'total' => $requests->total(),
                'has_more' => $requests->hasMorePages(),
            ],
        ]);
    }

    public function store(Request $request, Booking $booking): JsonResponse
    {
        $user = $request->user();
        $canRequest = $user->id === $booking->customer_id || $user->id === $booking->sitter_id;

        if (!$canRequest) {
            return response()->json(['status' => 'error', 'message' => __('messages.unauthorized')], 403);
        }

        if (!in_array($booking->status, ['pending', 'confirmed'], true)) {
            return response()->json(['status' => 'error', 'message' => __('messages.only_pending_confirmed_rescheduled')], 422);
        }

        $existing = RescheduleRequest::query()
            ->where('booking_id', $booking->id)
            ->whereIn('status', ['pending', 'countered'])
            ->exists();

        if ($existing) {
            return response()->json(['status' => 'error', 'message' => __('messages.active_reschedule_request_exists')], 422);
        }

        $validated = $request->validate([
            'proposed_date' => ['required', 'date', 'after_or_equal:today'],
            'proposed_start_time' => ['required', 'date_format:H:i'],
            'proposed_end_time' => ['required', 'date_format:H:i', 'after:proposed_start_time'],
            'reason' => ['nullable', 'string', 'max:500'],
        ]);

        $error = $this->bookingService->validateAvailabilityForSitter(
            $booking->sitter_id,
            $validated['proposed_date'],
            $validated['proposed_start_time'],
            $validated['proposed_end_time'],
            $booking->id,
            childrenCount: $booking->children_count ?? 1,
        );
        if ($error) {
            return $this->error($error, 422);
        }

        $reschedule = RescheduleRequest::create([
            'booking_id' => $booking->id,
            'requested_by_id' => $user->id,
            'status' => 'pending',
            'proposed_date' => $validated['proposed_date'],
            'proposed_start_time' => $validated['proposed_start_time'],
            'proposed_end_time' => $validated['proposed_end_time'],
            'reason' => $validated['reason'] ?? null,
        ]);

        return response()->json([
            'status' => 'success',
            'message' => __('messages.reschedule_request_submitted'),
            'data' => new RescheduleRequestResource($reschedule->load('requester:id,name,avatar')),
        ], 201);
    }

    public function show(RescheduleRequest $rescheduleRequest): JsonResponse
    {
        $user = request()->user();
        $booking = $rescheduleRequest->booking;

        if ($user->id !== $booking->customer_id && $user->id !== $booking->sitter_id) {
            return response()->json(['status' => 'error', 'message' => __('messages.unauthorized')], 403);
        }

        return response()->json([
            'status' => 'success',
            'data' => new RescheduleRequestResource($rescheduleRequest->load('requester:id,name,avatar')),
        ]);
    }

    public function accept(RescheduleRequest $rescheduleRequest): JsonResponse
    {
        $user = request()->user();
        $booking = $rescheduleRequest->booking;

        if ($user->id !== $booking->customer_id && $user->id !== $booking->sitter_id) {
            return response()->json(['status' => 'error', 'message' => __('messages.unauthorized')], 403);
        }

        if ($user->id === $rescheduleRequest->requested_by_id) {
            return response()->json(['status' => 'error', 'message' => __('messages.cannot_accept_own_request')], 422);
        }

        if (!$rescheduleRequest->isOpen()) {
            return response()->json(['status' => 'error', 'message' => __('messages.request_no_longer_open')], 422);
        }

        $effectiveDate = $rescheduleRequest->counter_date ?? $rescheduleRequest->proposed_date;
        $effectiveStart = $rescheduleRequest->counter_start_time ?? $rescheduleRequest->proposed_start_time;
        $effectiveEnd = $rescheduleRequest->counter_end_time ?? $rescheduleRequest->proposed_end_time;

        $error = $this->bookingService->validateAvailabilityForSitter(
            $booking->sitter_id,
            $effectiveDate?->toDateString(),
            $effectiveStart,
            $effectiveEnd,
            $booking->id,
            childrenCount: $booking->children_count ?? 1,
        );
        if ($error) {
            return $this->error($error, 422);
        }

        DB::transaction(function () use ($rescheduleRequest, $booking, $effectiveDate, $effectiveStart, $effectiveEnd, $user): void {
            $rescheduleRequest->update([
                'status' => 'accepted',
                'responded_at' => now(),
            ]);

            $booking->update([
                'date' => $effectiveDate,
                'start_time' => $effectiveStart,
                'end_time' => $effectiveEnd,
            ]);

            if ($booking->status === 'pending') {
                $history = (array) ($booking->status_history ?? []);
                $history[] = [
                    'from' => $booking->status,
                    'to' => $booking->status,
                    'timestamp' => now()->toISOString(),
                    'reason' => 'Rescheduled via request #' . $rescheduleRequest->id,
                ];
                $booking->updateQuietly(['status_history' => $history]);
            }
        });

        return response()->json([
            'status' => 'success',
            'message' => __('messages.reschedule_request_accepted'),
            'data' => new RescheduleRequestResource($rescheduleRequest->fresh()->load('requester:id,name,avatar')),
        ]);
    }

    public function reject(Request $request, RescheduleRequest $rescheduleRequest): JsonResponse
    {
        $user = $request->user();
        $booking = $rescheduleRequest->booking;

        if ($user->id !== $booking->customer_id && $user->id !== $booking->sitter_id) {
            return response()->json(['status' => 'error', 'message' => __('messages.unauthorized')], 403);
        }

        if ($user->id === $rescheduleRequest->requested_by_id) {
            return response()->json(['status' => 'error', 'message' => __('messages.cannot_reject_own_request')], 422);
        }

        if (!$rescheduleRequest->isOpen()) {
            return response()->json(['status' => 'error', 'message' => __('messages.request_no_longer_open')], 422);
        }

        $validated = $request->validate([
            'reason' => ['nullable', 'string', 'max:500'],
        ]);

        $rescheduleRequest->update([
            'status' => 'rejected',
            'responded_at' => now(),
        ]);

        return response()->json([
            'status' => 'success',
            'message' => __('messages.reschedule_request_rejected'),
            'data' => new RescheduleRequestResource($rescheduleRequest->fresh()->load('requester:id,name,avatar')),
        ]);
    }

    public function counter(Request $request, RescheduleRequest $rescheduleRequest): JsonResponse
    {
        $user = $request->user();
        $booking = $rescheduleRequest->booking;

        if ($user->id !== $booking->customer_id && $user->id !== $booking->sitter_id) {
            return response()->json(['status' => 'error', 'message' => __('messages.unauthorized')], 403);
        }

        if ($user->id === $rescheduleRequest->requested_by_id) {
            return response()->json(['status' => 'error', 'message' => __('messages.cannot_counter_own_request')], 422);
        }

        if (!$rescheduleRequest->isOpen()) {
            return response()->json(['status' => 'error', 'message' => __('messages.request_no_longer_open')], 422);
        }

        $validated = $request->validate([
            'counter_date' => ['required', 'date', 'after_or_equal:today'],
            'counter_start_time' => ['required', 'date_format:H:i'],
            'counter_end_time' => ['required', 'date_format:H:i', 'after:counter_start_time'],
            'counter_reason' => ['nullable', 'string', 'max:500'],
        ]);

        $error = $this->bookingService->validateAvailabilityForSitter(
            $booking->sitter_id,
            $validated['counter_date'],
            $validated['counter_start_time'],
            $validated['counter_end_time'],
            $booking->id,
            childrenCount: $booking->children_count ?? 1,
        );
        if ($error) {
            return $this->error($error, 422);
        }

        $rescheduleRequest->update([
            'status' => 'countered',
            'counter_date' => $validated['counter_date'],
            'counter_start_time' => $validated['counter_start_time'],
            'counter_end_time' => $validated['counter_end_time'],
            'counter_reason' => $validated['counter_reason'] ?? null,
        ]);

        return response()->json([
            'status' => 'success',
            'message' => __('messages.counter_proposal_submitted'),
            'data' => new RescheduleRequestResource($rescheduleRequest->fresh()->load('requester:id,name,avatar')),
        ]);
    }

    public function cancel(RescheduleRequest $rescheduleRequest): JsonResponse
    {
        $user = request()->user();

        if ($user->id !== $rescheduleRequest->requested_by_id) {
            return response()->json(['status' => 'error', 'message' => __('messages.only_requester_can_cancel')], 403);
        }

        if (!$rescheduleRequest->isOpen()) {
            return response()->json(['status' => 'error', 'message' => __('messages.request_no_longer_open')], 422);
        }

        $rescheduleRequest->update(['status' => 'cancelled']);

        return response()->json([
            'status' => 'success',
            'message' => __('messages.reschedule_request_cancelled'),
        ]);
    }
}
