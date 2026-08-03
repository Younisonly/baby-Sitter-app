<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class BookingResource extends JsonResource
{
    private function computeIsOutOfSchedule(): bool
    {
        if (!$this->date || !$this->start_time || !$this->end_time) {
            return false;
        }
        $now = now();
        $bookingDate = $this->date instanceof \Carbon\Carbon ? $this->date : \Carbon\Carbon::parse($this->date);
        return !$now->isSameDay($bookingDate) || $now->lt($this->start_time) || $now->gt($this->end_time);
    }

    public function toArray(Request $request): array
    {
        return [
            'id' => (string) $this->id,
            'bookingGroupId' => $this->booking_group_id,
            'bookingNumber' => $this->booking_number,
            'customerId' => (string) $this->customer_id,
            'sitterId' => (string) $this->sitter_id,
            'date' => $this->date?->toDateString(),
            'startTime' => substr((string) $this->start_time, 0, 5),
            'endTime' => substr((string) $this->end_time, 0, 5),
            'duration' => (int) $this->duration,
            'totalAmount' => (float) $this->total_amount,
            'baseAmount' => (float) ($this->base_amount ?? 0),
            'extraAmount' => (float) ($this->extra_amount ?? 0),
            'specialNeedsAmount' => (float) ($this->special_needs_amount ?? 0),
            'status' => $this->status,
            'customer' => $this->whenLoaded('customer', fn() => $this->customer ? new UserResource($this->customer) : null),
            'sitter' => $this->whenLoaded('sitter', fn() => $this->sitter ? new UserResource($this->sitter) : null),
            'notes' => $this->notes,
            'address' => $this->address,
            'childrenCount' => $this->children_count,
            'specialNeedsCount' => $this->special_needs_count ?? 0,
            'childrenAges' => $this->children_ages,
            'childrenNames' => $this->children_names ?? [],
            'specialInstructions' => $this->special_instructions,
            'scheduleEvents' => $this->schedule_events ?? [],
            'cancellationReason' => $this->cancellation_reason,
            'rejectionReason' => $this->rejection_reason,
            'confirmedAt' => $this->confirmed_at?->toJSON(),
            'inProgressAt' => $this->in_progress_at?->toJSON(),
            'rejectedAt' => $this->rejected_at?->toJSON(),
            'expiredAt' => $this->expired_at?->toJSON(),
            'confirmationDeadline' => $this->confirmation_deadline?->toJSON(),
            'rescheduledFromId' => $this->rescheduled_from_id ? (string) $this->rescheduled_from_id : null,
            'createdAt' => $this->created_at?->toJSON(),
            'updatedAt' => $this->updated_at?->toJSON(),
            'completedAt' => $this->completed_at?->toJSON(),
            'cancelledAt' => $this->cancelled_at?->toJSON(),
            'rating' => $this->rating === null ? null : (float) $this->rating,
            'review' => $this->review,
            'reply' => $this->reply,
            'repliedAt' => $this->replied_at?->toJSON(),
            'helpfulCount' => (int) ($this->helpful_count ?? 0),
            'statusHistory' => $this->whenLoaded('statusHistories', fn() => BookingStatusHistoryResource::collection($this->statusHistories)),
            'timelineEvents' => $this->whenLoaded('timelineEvents', fn() => TimelineEventResource::collection($this->timelineEvents)),
            'rescheduledFrom' => $this->whenLoaded('rescheduledFrom', fn() => new BookingResource($this->rescheduledFrom)),
            'sessionStatus' => $this->session_status ?? 'pending',
            'isDayCompleted' => (bool) ($this->is_day_completed ?? false),
            'dayCompletedAt' => $this->day_completed_at?->toJSON(),
            'sessionStartedAt' => $this->session_started_at?->toJSON(),
            'sessionEndedAt' => $this->session_ended_at?->toJSON(),
            'gpsStartedAt' => $this->gps_started_at?->toJSON(),
            'gpsEndedAt' => $this->gps_ended_at?->toJSON(),
            'overtimeMinutes' => (int) ($this->overtime_minutes ?? 0),
            'overtimeCost' => (float) ($this->overtime_cost ?? 0),
            'waitingMinutes' => (int) ($this->waiting_minutes ?? 0),
            'waitingCost' => (float) ($this->waiting_cost ?? 0),
            'expectedHours' => (float) ($this->expected_hours ?? 0),
            'actualHours' => (float) ($this->actual_hours ?? 0),
            'sessionNotes' => $this->session_notes,
            'isOutOfSchedule' => $this->computeIsOutOfSchedule(),
            'latestLocation' => $this->whenLoaded('latestTracking', fn() => $this->latestTracking ? [
                'latitude' => (float) $this->latestTracking->latitude,
                'longitude' => (float) $this->latestTracking->longitude,
                'address' => $this->latestTracking->address,
                'speed' => $this->latestTracking->speed ? (float) $this->latestTracking->speed : null,
                'battery' => $this->latestTracking->battery ? (int) $this->latestTracking->battery : null,
                'recordedAt' => $this->latestTracking->recorded_at?->toJSON(),
            ] : null),
        ];
    }
}
