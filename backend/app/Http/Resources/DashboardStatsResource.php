<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DashboardStatsResource extends JsonResource
{
    public function __construct(
        mixed $resource,
        private readonly mixed $earningsAggregates = null,
    ) {
        parent::__construct($resource);
    }

    public function toArray(Request $request): array
    {
        return [
            'totalBookings' => (int) ($this->total_bookings ?? 0),
            'completedBookings' => (int) ($this->completed_bookings ?? 0),
            'cancelledBookings' => (int) ($this->cancelled_bookings ?? 0),
            'totalEarnings' => (int) ($this->babysitterProfile?->total_earnings ?? 0),
            'baseEarnings' => (int) ($this->earningsAggregates?->base_earnings ?? 0),
            'extraEarnings' => (int) ($this->earningsAggregates?->extra_earnings ?? 0),
            'specialNeedsEarnings' => (int) ($this->earningsAggregates?->special_needs_earnings ?? 0),
            'rating' => (float) ($this->babysitterProfile?->rating ?? 0),
            'reviewCount' => (int) ($this->babysitterProfile?->review_count ?? 0),
            'isAvailable' => (bool) ($this->babysitterProfile?->is_available ?? false),
            'pendingRequests' => (int) ($this->pending_requests ?? 0),
        ];
    }
}
