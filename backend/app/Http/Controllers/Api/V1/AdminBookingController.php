<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\BookingResource;
use App\Models\Booking;
use App\Services\BookingService;
use App\Services\TimelineService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminBookingController extends Controller
{
    use ApiResponse;

    public function __construct(
        private readonly BookingService $bookingService,
        private readonly TimelineService $timelineService,
    ) {
        $this->middleware('admin');
    }

    public function index(Request $request): JsonResponse
    {
        $query = Booking::query()
            ->with(['customer:id,name', 'sitter:id,name'])
            ->latest();

        $status = $request->input('status');
        if ($status) {
            $query->where('status', $status);
        }

        $sitterId = $request->input('sitter_id');
        if ($sitterId) {
            $query->where('sitter_id', $sitterId);
        }

        $customerId = $request->input('customer_id');
        if ($customerId) {
            $query->where('customer_id', $customerId);
        }

        $dateFrom = $request->input('date_from');
        if ($dateFrom) {
            $query->whereDate('date', '>=', $dateFrom);
        }

        $dateTo = $request->input('date_to');
        if ($dateTo) {
            $query->whereDate('date', '<=', $dateTo);
        }

        $bookings = $query->paginate($request->integer('per_page', 50));

        return $this->success(
            BookingResource::collection($bookings),
            'All bookings retrieved',
        );
    }

    public function forceConfirm(Request $request, Booking $booking): JsonResponse
    {
        if (!in_array($booking->status, ['pending'])) {
            return $this->error('Only pending bookings can be confirmed.', 422);
        }

        $this->bookingService->transitionStatus(
            $booking,
            'confirmed',
            $request->user(),
            $request->input('reason', 'Admin force confirm'),
        );

        $this->timelineService->recordAdminAction(
            $booking, 'force_confirm', $request->user()->id, $request->input('reason'),
        );

        return $this->success(
            BookingResource::make($booking->fresh()->load(['customer', 'sitter.babysitterProfile'])),
            'Booking force-confirmed',
        );
    }

    public function forceComplete(Request $request, Booking $booking): JsonResponse
    {
        if (!in_array($booking->status, ['confirmed', 'in_progress'])) {
            return $this->error('Only confirmed or in-progress bookings can be completed.', 422);
        }

        $this->bookingService->transitionStatus(
            $booking,
            'completed',
            $request->user(),
            $request->input('reason', 'Admin force complete'),
        );

        $this->timelineService->recordAdminAction(
            $booking, 'force_complete', $request->user()->id, $request->input('reason'),
        );

        return $this->success(
            BookingResource::make($booking->fresh()->load(['customer', 'sitter.babysitterProfile'])),
            'Booking force-completed',
        );
    }

    public function forceCancel(Request $request, Booking $booking): JsonResponse
    {
        if (in_array($booking->status, ['completed', 'cancelled', 'rejected', 'expired'])) {
            return $this->error('Booking cannot be cancelled in its current state.', 422);
        }

        $this->bookingService->transitionStatus(
            $booking,
            'cancelled',
            $request->user(),
            $request->input('reason', 'Admin force cancel'),
        );

        $this->timelineService->recordAdminAction(
            $booking, 'force_cancel', $request->user()->id, $request->input('reason'),
        );

        return $this->success(
            BookingResource::make($booking->fresh()->load(['customer', 'sitter.babysitterProfile'])),
            'Booking force-cancelled',
        );
    }

    public function forceRebook(Request $request, Booking $booking): JsonResponse
    {
        $request->validate([
            'date' => ['required', 'date', 'after_or_equal:today'],
            'start_time' => ['required', 'date_format:H:i'],
            'end_time' => ['required', 'date_format:H:i', 'after:start_time'],
            'duration' => ['required', 'integer', 'min:1', 'max:24'],
        ]);

        if (in_array($booking->status, ['completed', 'cancelled'])) {
            return $this->error('Booking is already in a final state.', 422);
        }

        $this->bookingService->transitionStatus(
            $booking,
            'cancelled',
            $request->user(),
            $request->input('reason', 'Admin force rebook'),
        );

        $this->timelineService->recordAdminAction(
            $booking, 'force_rebook', $request->user()->id, $request->input('reason'),
        );

        return $this->success(
            BookingResource::make($booking->fresh()->load(['customer', 'sitter.babysitterProfile'])),
            'Booking force-rebooked',
        );
    }

    public function timeline(Booking $booking): JsonResponse
    {
        $events = $booking->timelineEvents()
            ->latest()
            ->with('actor:id,name')
            ->get();

        return $this->success(
            TimelineEventResource::collection($events),
            'Booking timeline retrieved',
        );
    }
}
