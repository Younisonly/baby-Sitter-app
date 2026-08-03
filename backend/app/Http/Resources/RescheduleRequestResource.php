<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class RescheduleRequestResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'bookingId' => $this->booking_id,
            'requestedById' => $this->requested_by_id,
            'requester' => $this->whenLoaded('requester', fn() => [
                'id' => $this->requester->id,
                'name' => $this->requester->name,
                'avatar' => $this->requester->avatar,
            ]),
            'status' => $this->status,
            'proposedDate' => $this->proposed_date?->toDateString(),
            'proposedStartTime' => $this->proposed_start_time,
            'proposedEndTime' => $this->proposed_end_time,
            'reason' => $this->reason,
            'counterDate' => $this->counter_date?->toDateString(),
            'counterStartTime' => $this->counter_start_time,
            'counterEndTime' => $this->counter_end_time,
            'counterReason' => $this->counter_reason,
            'respondedAt' => $this->responded_at?->toISOString(),
            'createdAt' => $this->created_at?->toISOString(),
            'updatedAt' => $this->updated_at?->toISOString(),
        ];
    }
}
